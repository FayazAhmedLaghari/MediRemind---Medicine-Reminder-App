import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
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
  static const String _channelDescription = 'Notifications for medicine reminders';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
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
    // Request local notification permissions
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted == true) {
        debugPrint('Android notification permission granted');
      }
    }

    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM Permission status: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
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
      final db = DatabaseHelper.instance;
      final reminders = await db.getReminders();
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
      final db = DatabaseHelper.instance;
      final reminders = await db.getReminders();
      final reminder = reminders.firstWhere((r) => r.id == reminderId);
      
      // Cancel existing notification
      await cancelReminderNotification(reminderId);
      
      // Calculate new time
      final currentDateTime = DateTime.parse('${reminder.reminderDate} ${reminder.reminderTime}:00');
      final newDateTime = currentDateTime.add(duration);
      
      // Create new reminder with updated time
      final snoozedReminder = reminder.copyWith(
        reminderDate: '${newDateTime.year}-${newDateTime.month.toString().padLeft(2, '0')}-${newDateTime.day.toString().padLeft(2, '0')}',
        reminderTime: '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}',
      );
      
      await db.updateReminder(snoozedReminder);
      await scheduleReminderNotification(snoozedReminder);
      
      debugPrint('Reminder $reminderId snoozed for ${duration.inMinutes} minutes');
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
        debugPrint('Cannot schedule notification: reminder ID is null');
        return;
      }

      // Parse reminder date and time
      final dateParts = reminder.reminderDate.split('-');
      final timeParts = reminder.reminderTime.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) {
        debugPrint('Invalid date or time format');
        return;
      }

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Create scheduled time
      final scheduledDate = tz.TZDateTime(
        tz.local,
        year,
        month,
        day,
        hour,
        minute,
      );

      // Don't schedule if the time has already passed
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('Cannot schedule notification: time has already passed');
        return;
      }

      // Schedule local notification
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
          'Scheduled notification for reminder ${reminder.id} at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminderNotification(int reminderId) async {
    try {
      await _localNotifications.cancel(reminderId);
      debugPrint('Cancelled notification for reminder $reminderId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
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
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

  /// Reschedule all pending reminders
  Future<void> rescheduleAllReminders() async {
    try {
      final db = DatabaseHelper.instance;
      final reminders = await db.getReminders();

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

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

