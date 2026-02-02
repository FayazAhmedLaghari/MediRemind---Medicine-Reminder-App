import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import 'database_helper.dart';

/// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  String? _fcmToken;

  // Notification channel IDs
  static const String _channelId = 'medicine_reminders';
  static const String _channelName = 'Medicine Reminders';
  static const String _channelDescription =
      'Notifications for medicine reminders';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Skip notification initialization on web platform
      if (kIsWeb) {
        debugPrint('⚠️ Notifications not supported on web platform');
        _isInitialized = true;
        return;
      }

      // Initialize timezone
      tz.initializeTimeZones();
      // Use device's local timezone - tz.local will use system timezone
      // For scheduling, we'll parse dates in local timezone

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Cloud Messaging
      await _initializeFCM();

      // Request permissions
      await requestPermissions();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      // Use default notification sound
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Skip FCM on web due to service worker issues
    if (kIsWeb) {
      debugPrint('⚠️ FCM initialization skipped on web platform');
      return;
    }

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

    // Check if app was opened from notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpenedApp(initialMessage);
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      debugPrint('🔔 [PERMISSION] Requesting notification permissions...');

      // Request local notification permissions
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('🔔 [PERMISSION] Android notification permission: $granted');
        if (granted != true) {
          debugPrint(
              '🔔 [PERMISSION] ⚠️ Android notification permission denied');
        }

        // Request exact alarm permission (Android 13+)
        try {
          final exactAlarmPermission =
              await androidPlugin.requestExactAlarmsPermission();
          debugPrint(
              '🔔 [PERMISSION] Exact alarm permission: $exactAlarmPermission');
        } catch (e) {
          debugPrint(
              '🔔 [PERMISSION] Note: Exact alarm permission request not available or already granted');
        }
      }

      // Request FCM permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
          '🔔 [PERMISSION] FCM Permission status: ${settings.authorizationStatus}');
      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isAuthorized) {
        debugPrint('🔔 [PERMISSION] ✅ Notification permissions granted');
      } else {
        debugPrint('🔔 [PERMISSION] ❌ Notification permissions denied');
      }

      return isAuthorized;
    } catch (e) {
      debugPrint('🔔 [PERMISSION] ❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if notification permissions are granted
  Future<bool> _checkNotificationPermissions() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('🔔 [PERMISSION] Error checking permissions: $e');
      return false;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Medicine Reminder',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tapped (foreground)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    _handleNotificationAction(response);
  }

  /// Handle notification tapped (background)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
    // Handle background notification action
    // Note: This is a static method because it's called from native code
    // For now, we'll handle actions in the foreground handler
  }

  /// Handle notification action
  void _handleNotificationAction(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == 'take_medicine' && payload != null) {
      // Mark reminder as completed
      _markReminderAsCompleted(int.parse(payload));
    } else if (actionId == 'snooze' && payload != null) {
      // Snooze reminder for 10 minutes
      _snoozeReminder(int.parse(payload), Duration(minutes: 10));
    } else if (payload != null) {
      // Regular tap - navigate to reminder details
      debugPrint('Navigate to reminder: $payload');
    }
  }

  /// Mark reminder as completed
  Future<void> _markReminderAsCompleted(int reminderId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final db = DatabaseHelper.instance;
      final reminders = await db.getReminders(userId);
      final reminder = reminders.firstWhere((r) => r.id == reminderId);

      final updatedReminder = reminder.copyWith(status: 'completed');
      await db.updateReminder(updatedReminder);

      // Cancel the notification
      await cancelReminderNotification(reminderId);

      debugPrint('Reminder $reminderId marked as completed');
    } catch (e) {
      debugPrint('Error marking reminder as completed: $e');
    }
  }

  /// Snooze reminder
  Future<void> _snoozeReminder(int reminderId, Duration duration) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final db = DatabaseHelper.instance;
      final reminders = await db.getReminders(userId);
      final reminder = reminders.firstWhere((r) => r.id == reminderId);

      // Cancel existing notification
      await cancelReminderNotification(reminderId);

      // Calculate new time
      final currentDateTime = DateTime.parse(
          '${reminder.reminderDate} ${reminder.reminderTime}:00');
      final newDateTime = currentDateTime.add(duration);

      // Create new reminder with updated time
      final snoozedReminder = reminder.copyWith(
        reminderDate:
            '${newDateTime.year}-${newDateTime.month.toString().padLeft(2, '0')}-${newDateTime.day.toString().padLeft(2, '0')}',
        reminderTime:
            '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}',
      );

      await db.updateReminder(snoozedReminder);
      await scheduleReminderNotification(snoozedReminder);

      debugPrint(
          'Reminder $reminderId snoozed for ${duration.inMinutes} minutes');
    } catch (e) {
      debugPrint('Error snoozing reminder: $e');
    }
  }

  /// Handle notification opened app
  void _handleNotificationOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');
    // Handle navigation when app is opened from notification
  }

  /// Schedule a notification for a reminder
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    try {
      if (reminder.id == null) {
        debugPrint('🔔 [NOTIFICATION] Cannot schedule: reminder ID is null');
        return;
      }

      // Ensure notification service is initialized
      if (!_isInitialized) {
        debugPrint(
            '🔔 [NOTIFICATION] Service not initialized, initializing now...');
        await initialize();
      }

      // Check and request permissions if needed
      final hasPermission = await _checkNotificationPermissions();
      if (!hasPermission) {
        debugPrint(
            '🔔 [NOTIFICATION] ⚠️ Notification permission not granted, requesting...');
        final granted = await requestPermissions();
        if (!granted) {
          debugPrint('🔔 [NOTIFICATION] ❌ User denied notification permission');
          return;
        }
      }

      debugPrint(
          '🔔 [NOTIFICATION] Starting notification schedule for reminder ${reminder.id}');
      debugPrint(
          '🔔 [NOTIFICATION] Medicine: ${reminder.medicineName}, Date: ${reminder.reminderDate}, Time: ${reminder.reminderTime}');

      // Parse reminder date and time
      final dateParts = reminder.reminderDate.split('-');
      final timeParts = reminder.reminderTime.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) {
        debugPrint(
            '🔔 [NOTIFICATION] Invalid date/time format: date=$dateParts, time=$timeParts');
        return;
      }

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      debugPrint(
          '🔔 [NOTIFICATION] Parsed time: $year-$month-$day $hour:$minute');

      // Create scheduled time using local timezone
      final scheduledDate = tz.TZDateTime(
        tz.local,
        year,
        month,
        day,
        hour,
        minute,
      );

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('🔔 [NOTIFICATION] Scheduled: $scheduledDate, Now: $now');
      debugPrint(
          '🔔 [NOTIFICATION] Time difference: ${scheduledDate.difference(now).inSeconds} seconds');

      // Allow scheduling if time is at least 1 minute in the future
      if (scheduledDate.isBefore(now.add(const Duration(seconds: 1)))) {
        debugPrint(
            '🔔 [NOTIFICATION] ⚠️ SKIPPED: Scheduled time is in the past or less than 1 second away');
        return;
      }

      debugPrint('🔔 [NOTIFICATION] ✅ Time validation passed');

      // Schedule local notification
      debugPrint(
          '🔔 [NOTIFICATION] Attempting to schedule local notification...');
      await _localNotifications.zonedSchedule(
        reminder.id!,
        'Medicine Reminder',
        'Time to take ${reminder.medicineName} - ${reminder.dosage}',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            // Use default notification sound
            // sound: const RawResourceAndroidNotificationSound('notification_sound'),
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              'Time to take ${reminder.medicineName}\nDosage: ${reminder.dosage}${reminder.notes.isNotEmpty ? '\nNotes: ${reminder.notes}' : ''}',
            ),
            actions: [
              const AndroidNotificationAction(
                'take_medicine',
                'Taken',
                showsUserInterface: false,
              ),
              const AndroidNotificationAction(
                'snooze',
                'Snooze 10 min',
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            // Use default notification sound
            // sound: 'notification_sound.wav',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id.toString(),
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      debugPrint(
          '🔔 [NOTIFICATION] ✅ Successfully scheduled notification for reminder ${reminder.id} at $scheduledDate');

      // Verify the notification was scheduled
      final pendingNotifications =
          await _localNotifications.pendingNotificationRequests();
      final scheduled =
          pendingNotifications.where((n) => n.id == reminder.id).toList();

      // Calculate time until notification
      final difference = scheduledDate.difference(now);
      final minutesUntil = difference.inMinutes;
      final secondsUntil = difference.inSeconds % 60;
      if (scheduled.isNotEmpty) {
        debugPrint(
            '🔔 [NOTIFICATION] ✅ Verified: Notification ${reminder.id} is in pending list');
        debugPrint('🔔 [NOTIFICATION] ⏰ Current time: ${now.toString()}');
        debugPrint(
            '🔔 [NOTIFICATION] 📅 Scheduled for: ${scheduledDate.toString()}');
        debugPrint(
            '🔔 [NOTIFICATION] ⏱️  Will fire in: $minutesUntil min $secondsUntil sec');
      } else {
        debugPrint(
            '🔔 [NOTIFICATION] ❌ ERROR: Notification ${reminder.id} NOT found in pending list!');
      }
      debugPrint(
          '🔔 [NOTIFICATION] Total pending notifications: ${pendingNotifications.length}');
    } catch (e, st) {
      debugPrint('🔔 [NOTIFICATION] ❌ Error scheduling notification: $e\n$st');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminderNotification(int reminderId) async {
    try {
      if (kIsWeb) return;
      await _localNotifications.cancel(reminderId);
      debugPrint('Cancelled notification for reminder $reminderId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      if (kIsWeb) return;
      if (!_isInitialized) {
        debugPrint(
            '⚠️ Notification service not initialized, skipping cancel all');
        return;
      }
      await _localNotifications.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Show immediate local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      // Use default notification sound
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Use default notification sound
      // sound: 'notification_sound.wav',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show a test notification immediately
  Future<void> showTestNotification() async {
    try {
      if (kIsWeb) {
        debugPrint('🔔 [TEST] ⚠️ Notifications not supported on web platform');
        return;
      }

      if (!_isInitialized) {
        await initialize();
      }

      // Request permissions if needed
      await requestPermissions();

      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Test Notification',
        body: 'If you can see this, notifications are working! 🎉',
        payload: 'test',
      );

      debugPrint('🔔 [TEST] ✅ Test notification shown');
    } catch (e) {
      debugPrint('🔔 [TEST] ❌ Error showing test notification: $e');
    }
  }

  /// Reschedule all pending reminders
  Future<void> rescheduleAllReminders() async {
    try {
      if (kIsWeb) {
        debugPrint('⚠️ Reschedule skipped on web platform');
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('No user logged in, skipping reschedule');
        return;
      }

      final db = DatabaseHelper.instance;
      final reminders = await db.getReminders(userId);

      // Cancel all existing notifications
      await cancelAllNotifications();

      // Schedule notifications for pending reminders
      final now = DateTime.now();
      for (final reminder in reminders) {
        if (reminder.status == 'pending') {
          final reminderDateTime = DateTime.parse(
            '${reminder.reminderDate} ${reminder.reminderTime}:00',
          );
          if (reminderDateTime.isAfter(now)) {
            await scheduleReminderNotification(reminder);
          }
        }
      }

      debugPrint('Rescheduled all pending reminders');
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }

  /// Debug method to list all pending notifications
  Future<void> debugPendingNotifications() async {
    if (kIsWeb) {
      debugPrint('⚠️ Web platform - local notifications not available');
      return;
    }

    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      debugPrint('');
      debugPrint('📋 ========== PENDING NOTIFICATIONS ==========');
      debugPrint('Total pending: ${pending.length}');

      if (pending.isEmpty) {
        debugPrint('   ℹ️ No pending notifications');
      } else {
        for (var notification in pending) {
          debugPrint('   • ID: ${notification.id}');
          debugPrint('     Title: ${notification.title}');
          debugPrint('     Body: ${notification.body}');
        }
      }
      debugPrint('============================================');
      debugPrint('');
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
    }
  }

  /// Test scheduled notification - schedules a notification 1 minute from now
  Future<void> testScheduledNotification() async {
    if (kIsWeb) {
      debugPrint('⚠️ Web platform - scheduled notifications not supported');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(minutes: 1));

      debugPrint('');
      debugPrint('🧪 ========== TEST SCHEDULED NOTIFICATION ==========');
      debugPrint('Current time: ${now.toString()}');
      debugPrint('Will schedule for: ${scheduledTime.toString()}');
      debugPrint('(1 minute from now)');
      debugPrint('==================================================');
      debugPrint('');

      await _localNotifications.zonedSchedule(
        999999, // Test notification ID
        '🧪 Test Scheduled Notification',
        'This notification was scheduled 1 minute ago at ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Verify it was scheduled
      final pending = await _localNotifications.pendingNotificationRequests();
      final testNotif = pending.where((n) => n.id == 999999).toList();

      if (testNotif.isNotEmpty) {
        debugPrint('✅ Test notification successfully scheduled!');
        debugPrint('   Wait 1 minute to see if it fires...');
      } else {
        debugPrint('❌ Test notification NOT found in pending list!');
      }
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
