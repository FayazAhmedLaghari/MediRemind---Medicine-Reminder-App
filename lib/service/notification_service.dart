import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
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
  Timer? _foregroundReminderTimer;

  // Track which reminder IDs have already been handled in the foreground
  // to avoid playing sound/vibration multiple times for the same reminder
  final Set<int> _handledForegroundReminders = {};

  // ─── Notification channel IDs ──────────────────────────────────────────
  static const String _channelSoundVib = 'med_remind_sound_vib_v2';
  static const String _channelSoundOnly = 'med_remind_sound_only_v2';
  static const String _channelVibOnly = 'med_remind_vib_only_v2';
  static const String _channelSilent = 'med_remind_silent_v2';

  // ALL channel IDs to delete before fresh creation
  // (Android caches channel settings permanently — the ONLY way to update
  //  sound / vibration / importance is to delete & recreate the channel.)
  static const List<String> _allChannelIdsToDelete = [
    // v1 (legacy)
    'medicine_reminders',
    'medicine_reminders_sound_only',
    'medicine_reminders_vib_only',
    'medicine_reminders_silent',
    // v2 (current) — we delete these too so settings are always fresh
    _channelSoundVib,
    _channelSoundOnly,
    _channelVibOnly,
    _channelSilent,
  ];

  static const String _channelNameDefault = 'Medicine Reminders';
  static const String _channelDescription =
      'Notifications for medicine reminders';

  // Custom vibration pattern: wait 0ms → vibrate 500ms → pause 200ms →
  // vibrate 500ms → pause 200ms → vibrate 800ms  (strong pulse pattern)
  static const List<int> _vibrationPattern = [0, 500, 200, 500, 200, 800];

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        debugPrint('⚠️ Notifications not supported on web platform');
        _isInitialized = true;
        return;
      }

      // Initialize timezone data and set the local timezone
      tzData.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        debugPrint('🔔 [TIMEZONE] Device timezone: $timeZoneName');
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('🔔 [TIMEZONE] ✅ Local timezone set to: ${tz.local}');
      } catch (e) {
        debugPrint(
            '🔔 [TIMEZONE] ⚠️ Could not get device timezone: $e, falling back to UTC');
      }

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

      // Start foreground reminder checker
      // This timer checks every 15 seconds if a reminder is due and
      // plays sound + vibration programmatically as a reliable backup
      // (even if the notification channel sound is muted by Android).
      _startForegroundReminderChecker();

      _isInitialized = true;
      debugPrint('🔔 Notification service initialized successfully');
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

    // Delete ALL cached channels, then create them fresh
    // (Android never updates an existing channel — must delete first)
    await _deleteAllNotificationChannels();
    await _createNotificationChannels();
  }

  /// Delete ALL notification channels (old + current) so they are recreated
  /// with guaranteed-fresh sound / vibration / importance settings.
  Future<void> _deleteAllNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    for (final id in _allChannelIdsToDelete) {
      try {
        await androidPlugin.deleteNotificationChannel(id);
      } catch (_) {
        // Channel might not exist yet, that's fine
      }
    }
    debugPrint(
        '🔔 [CHANNELS] 🗑️ Deleted all old + current channels for fresh creation');
  }

  /// Create Android notification channels for each sound/vibration combination
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // 1️⃣ Sound + Vibration (default)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelSoundVib,
        '$_channelNameDefault (Sound & Vibration)',
        description: '$_channelDescription with sound and vibration',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(_vibrationPattern),
        sound: const RawResourceAndroidNotificationSound('alarm_tone'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    // 2️⃣ Sound only (no vibration)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelSoundOnly,
        '$_channelNameDefault (Sound Only)',
        description: '$_channelDescription with sound only',
        importance: Importance.max,
        playSound: true,
        enableVibration: false,
        sound: RawResourceAndroidNotificationSound('alarm_tone'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    // 3️⃣ Vibration only (no sound)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _channelVibOnly,
        '$_channelNameDefault (Vibration Only)',
        description: '$_channelDescription with vibration only',
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(_vibrationPattern),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    // 4️⃣ Silent (no sound, no vibration)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelSilent,
        '$_channelNameDefault (Silent)',
        description: '$_channelDescription without sound or vibration',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      ),
    );

    debugPrint(
        '🔔 [CHANNELS] ✅ Created 4 notification channels (sound+vib, sound-only, vib-only, silent)');

    // Verify channels were created by listing them
    try {
      final channels = await androidPlugin.getNotificationChannels();
      if (channels != null) {
        for (final ch in channels) {
          if (ch.id.startsWith('med_remind_')) {
            debugPrint(
                '🔔 [CHANNELS] 📋 Channel: ${ch.id} | sound=${ch.sound?.sound} | vibration=${ch.enableVibration} | importance=${ch.importance}');
          }
        }
      }
    } catch (e) {
      debugPrint('🔔 [CHANNELS] ⚠️ Could not verify channels: $e');
    }
  }

  /// Pick the right channel ID based on the reminder preferences
  static String _channelIdFor({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) {
    if (soundEnabled && vibrationEnabled) return _channelSoundVib;
    if (soundEnabled && !vibrationEnabled) return _channelSoundOnly;
    if (!soundEnabled && vibrationEnabled) return _channelVibOnly;
    return _channelSilent;
  }

  /// Pick the right channel name based on the reminder preferences
  static String _channelNameFor({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) {
    if (soundEnabled && vibrationEnabled) {
      return '$_channelNameDefault (Sound & Vibration)';
    }
    if (soundEnabled && !vibrationEnabled) {
      return '$_channelNameDefault (Sound Only)';
    }
    if (!soundEnabled && vibrationEnabled) {
      return '$_channelNameDefault (Vibration Only)';
    }
    return '$_channelNameDefault (Silent)';
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    if (kIsWeb) {
      debugPrint('⚠️ FCM initialization skipped on web platform');
      return;
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

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

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint(
            '🔔 [PERMISSION] Android notification permission: $granted');
        if (granted != true) {
          debugPrint(
              '🔔 [PERMISSION] ⚠️ Android notification permission denied');
        }

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
      // Check Android local notification permission first (most relevant)
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final areEnabled = await androidPlugin.areNotificationsEnabled();
        if (areEnabled == true) return true;
        // If areEnabled is false or null, fall through to FCM check
      }

      // Fallback: check via FCM
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('🔔 [PERMISSION] Error checking permissions: $e');
      // Return true to not block scheduling — the system will
      // prompt for permission when the notification actually fires
      return true;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

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
  }

  /// Handle notification action
  void _handleNotificationAction(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == 'take_medicine' && payload != null) {
      _markReminderAsCompleted(int.parse(payload));
    } else if (actionId == 'snooze' && payload != null) {
      _snoozeReminder(int.parse(payload), const Duration(minutes: 10));
    } else if (payload != null) {
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

      await cancelReminderNotification(reminderId);

      final currentDateTime = DateTime.parse(
          '${reminder.reminderDate} ${reminder.reminderTime}:00');
      final newDateTime = currentDateTime.add(duration);

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
  }

  // ─── Foreground reminder checker ─────────────────────────────────────
  //
  // Android may suppress notification sounds when the app is in the
  // foreground, or the channel settings might be stale.  This timer runs
  // every 15 seconds while the app is alive and plays sound + vibration
  // programmatically when a pending reminder's time arrives.

  void _startForegroundReminderChecker() {
    _foregroundReminderTimer?.cancel();
    _foregroundReminderTimer =
        Timer.periodic(const Duration(seconds: 15), (_) async {
      await _checkAndTriggerDueReminders();
    });
    debugPrint(
        '🔔 [FOREGROUND] ✅ Started foreground reminder checker (every 15s)');
  }

  /// Stop the foreground reminder checker (call when app is disposed)
  void stopForegroundReminderChecker() {
    _foregroundReminderTimer?.cancel();
    _foregroundReminderTimer = null;
    debugPrint('🔔 [FOREGROUND] 🛑 Stopped foreground reminder checker');
  }

  /// Check if any pending reminder is due right now and trigger sound/vibration
  Future<void> _checkAndTriggerDueReminders() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final reminders = await db.getRemindersByDate(todayStr, userId);

      for (final reminder in reminders) {
        if (reminder.status != 'pending' || reminder.id == null) continue;
        if (_handledForegroundReminders.contains(reminder.id)) continue;

        // Parse reminder time
        final timeParts = reminder.reminderTime.split(':');
        if (timeParts.length < 2) continue;
        final rHour = int.tryParse(timeParts[0]) ?? -1;
        final rMinute = int.tryParse(timeParts[1]) ?? -1;
        if (rHour < 0 || rMinute < 0) continue;

        // Check if the reminder is due (within a 60-second window)
        final reminderDateTime = DateTime(now.year, now.month, now.day, rHour, rMinute);
        final diff = now.difference(reminderDateTime).inSeconds;

        // Trigger if reminder time is between 0 and 60 seconds ago
        if (diff >= 0 && diff < 60) {
          _handledForegroundReminders.add(reminder.id!);
          debugPrint(
              '🔔 [FOREGROUND] ⏰ Reminder ${reminder.id} for ${reminder.medicineName} is DUE NOW!');

          // Trigger vibration if enabled
          if (reminder.vibrationEnabled) {
            debugPrint('🔔 [FOREGROUND] 📳 Triggering vibration...');
            await triggerVibration();
          }

          // Trigger sound if enabled — show an immediate local notification
          // as a backup (with sound channel) in case the scheduled one was silent
          if (reminder.soundEnabled || reminder.vibrationEnabled) {
            debugPrint(
                '🔔 [FOREGROUND] 🔊 Showing backup local notification with sound...');
            await _showLocalNotification(
              id: reminder.id! + 100000, // Different ID to avoid conflict
              title: '💊 Medicine Reminder',
              body:
                  'Time to take ${reminder.medicineName} - ${reminder.dosage}',
              payload: reminder.id.toString(),
              soundEnabled: reminder.soundEnabled,
              vibrationEnabled: reminder.vibrationEnabled,
            );
          }
        }
      }

      // Clean up old entries (reminders more than 5 minutes old)
      _handledForegroundReminders.removeWhere((id) {
        // Keep the set from growing indefinitely
        return _handledForegroundReminders.length > 100;
      });
    } catch (e) {
      // Silently ignore — this is a best-effort check
      debugPrint('🔔 [FOREGROUND] ⚠️ Error checking reminders: $e');
    }
  }

  // ─── Vibration helper ─────────────────────────────────────────────────

  /// Trigger device vibration programmatically (useful when app is in foreground)
  static Future<void> triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Strong pulsing pattern: vibrate 500ms, pause 200ms, vibrate 500ms, pause 200ms, vibrate 800ms
        final hasCustomVib =
            await Vibration.hasCustomVibrationsSupport();
        if (hasCustomVib == true) {
          await Vibration.vibrate(
            pattern: [0, 500, 200, 500, 200, 800],
            intensities: [0, 255, 0, 255, 0, 255],
          );
        } else {
          // Fallback: simple long vibration
          await Vibration.vibrate(duration: 1500);
        }
        debugPrint('📳 [VIBRATION] ✅ Device vibrated');
      } else {
        debugPrint('📳 [VIBRATION] ⚠️ Device has no vibrator');
      }
    } catch (e) {
      debugPrint('📳 [VIBRATION] ❌ Error triggering vibration: $e');
    }
  }

  /// Cancel ongoing vibration
  static Future<void> cancelVibration() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  // ─── Build notification details respecting sound / vibration prefs ─────

  /// Build Android notification details based on sound & vibration preferences
  AndroidNotificationDetails _buildAndroidDetails({
    required bool soundEnabled,
    required bool vibrationEnabled,
    required String body,
    required String medicineName,
    required String dosage,
    String notes = '',
  }) {
    final channelId = _channelIdFor(
        soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled);
    final channelName = _channelNameFor(
        soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled);

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      vibrationPattern:
          vibrationEnabled ? Int64List.fromList(_vibrationPattern) : null,
      sound: soundEnabled
          ? const RawResourceAndroidNotificationSound('alarm_tone')
          : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Time to take $medicineName\nDosage: $dosage${notes.isNotEmpty ? '\nNotes: $notes' : ''}',
      ),
      actions: [
        const AndroidNotificationAction(
          'take_medicine',
          'Taken ✔️',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'snooze',
          'Snooze 10 min',
          showsUserInterface: false,
        ),
      ],
    );
  }

  /// Build iOS notification details based on sound preference
  DarwinNotificationDetails _buildIOSDetails({required bool soundEnabled}) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );
  }

  /// Schedule a notification for a reminder
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    try {
      if (reminder.id == null) {
        debugPrint('🔔 [NOTIFICATION] Cannot schedule: reminder ID is null');
        return;
      }

      if (!_isInitialized) {
        debugPrint(
            '🔔 [NOTIFICATION] Service not initialized, initializing now...');
        await initialize();
      }

      final hasPermission = await _checkNotificationPermissions();
      if (!hasPermission) {
        debugPrint(
            '🔔 [NOTIFICATION] ⚠️ Notification permission not granted, requesting...');
        final granted = await requestPermissions();
        if (!granted) {
          debugPrint(
              '🔔 [NOTIFICATION] ❌ User denied notification permission');
          return;
        }
      }

      debugPrint(
          '🔔 [NOTIFICATION] Starting notification schedule for reminder ${reminder.id}');
      debugPrint(
          '🔔 [NOTIFICATION] Medicine: ${reminder.medicineName}, Date: ${reminder.reminderDate}, Time: ${reminder.reminderTime}');
      debugPrint(
          '🔔 [NOTIFICATION] 🔊 Sound: ${reminder.soundEnabled ? "ON" : "OFF"}, 📳 Vibration: ${reminder.vibrationEnabled ? "ON" : "OFF"}');

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
      debugPrint(
          '🔔 [NOTIFICATION] Using timezone: ${tz.local.name} (${tz.local})');

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
          '🔔 [NOTIFICATION] Timezone offset: ${scheduledDate.timeZoneOffset}');
      debugPrint(
          '🔔 [NOTIFICATION] Time difference: ${scheduledDate.difference(now).inSeconds} seconds');

      if (scheduledDate.isBefore(now.add(const Duration(seconds: 1)))) {
        debugPrint(
            '🔔 [NOTIFICATION] ⚠️ SKIPPED: Scheduled time is in the past or less than 1 second away');
        return;
      }

      debugPrint('🔔 [NOTIFICATION] ✅ Time validation passed');

      // Verify exact alarm permission before scheduling
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canScheduleExact =
            await androidPlugin.canScheduleExactNotifications();
        debugPrint(
            '🔔 [NOTIFICATION] Can schedule exact alarms: $canScheduleExact');
        if (canScheduleExact != true) {
          debugPrint(
              '🔔 [NOTIFICATION] ⚠️ Exact alarm permission not granted! Requesting...');
          await androidPlugin.requestExactAlarmsPermission();
          final canScheduleNow =
              await androidPlugin.canScheduleExactNotifications();
          debugPrint(
              '🔔 [NOTIFICATION] After request, can schedule: $canScheduleNow');
          if (canScheduleNow != true) {
            debugPrint(
                '🔔 [NOTIFICATION] ❌ Still no exact alarm permission.');
          }
        }
      }

      // Build notification details based on sound / vibration preferences
      final androidDetails = _buildAndroidDetails(
        soundEnabled: reminder.soundEnabled,
        vibrationEnabled: reminder.vibrationEnabled,
        body: 'Time to take ${reminder.medicineName} - ${reminder.dosage}',
        medicineName: reminder.medicineName,
        dosage: reminder.dosage,
        notes: reminder.notes,
      );

      final iosDetails =
          _buildIOSDetails(soundEnabled: reminder.soundEnabled);

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final channelUsed = _channelIdFor(
        soundEnabled: reminder.soundEnabled,
        vibrationEnabled: reminder.vibrationEnabled,
      );
      debugPrint(
          '🔔 [NOTIFICATION] Scheduling on channel: $channelUsed (alarmClock mode)...');

      await _localNotifications.zonedSchedule(
        reminder.id!,
        '💊 Medicine Reminder',
        'Time to take ${reminder.medicineName} - ${reminder.dosage}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id.toString(),
      );

      debugPrint(
          '🔔 [NOTIFICATION] ✅ Successfully scheduled notification for reminder ${reminder.id} at $scheduledDate');

      // Verify the notification was scheduled
      final pendingNotifications =
          await _localNotifications.pendingNotificationRequests();
      final scheduled =
          pendingNotifications.where((n) => n.id == reminder.id).toList();

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
        debugPrint(
            '🔔 [NOTIFICATION] 🔊 Sound: ${reminder.soundEnabled ? "ON" : "OFF"} | 📳 Vibration: ${reminder.vibrationEnabled ? "ON" : "OFF"}');
      } else {
        debugPrint(
            '🔔 [NOTIFICATION] ❌ ERROR: Notification ${reminder.id} NOT found in pending list!');
      }
      debugPrint(
          '🔔 [NOTIFICATION] Total pending notifications: ${pendingNotifications.length}');
    } catch (e, st) {
      debugPrint(
          '🔔 [NOTIFICATION] ❌ Error scheduling notification: $e\n$st');
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

  /// Show immediate local notification (default: sound + vibration)
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    final channelId = _channelIdFor(
        soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled);
    final channelName = _channelNameFor(
        soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      vibrationPattern:
          vibrationEnabled ? Int64List.fromList(_vibrationPattern) : null,
      sound: soundEnabled
          ? const RawResourceAndroidNotificationSound('alarm_tone')
          : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final notificationDetails = NotificationDetails(
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

    // Also trigger programmatic vibration for immediate feedback
    if (vibrationEnabled) {
      await triggerVibration();
    }
  }

  /// Show a test notification immediately (with sound & vibration)
  Future<void> showTestNotification({
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      if (kIsWeb) {
        debugPrint(
            '🔔 [TEST] ⚠️ Notifications not supported on web platform');
        return;
      }

      if (!_isInitialized) {
        await initialize();
      }

      await requestPermissions();

      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Test Notification 💊',
        body:
            'Sound: ${soundEnabled ? "ON 🔊" : "OFF 🔇"} | Vibration: ${vibrationEnabled ? "ON 📳" : "OFF"}\nNotifications are working! 🎉',
        payload: 'test',
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
      );

      debugPrint(
          '🔔 [TEST] ✅ Test notification shown (sound=$soundEnabled, vib=$vibrationEnabled)');
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

      await cancelAllNotifications();

      final now = tz.TZDateTime.now(tz.local);
      int rescheduledCount = 0;

      debugPrint('');
      debugPrint('🔄 ========== RESCHEDULING REMINDERS ==========');
      debugPrint('🔄 Current time: $now');
      debugPrint('🔄 Total reminders in DB: ${reminders.length}');

      for (final reminder in reminders) {
        if (reminder.status == 'pending') {
          final dateParts = reminder.reminderDate.split('-');
          final timeParts = reminder.reminderTime.split(':');

          if (dateParts.length == 3 && timeParts.length >= 2) {
            try {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);

              final reminderDateTime = tz.TZDateTime(
                tz.local,
                year,
                month,
                day,
                hour,
                minute,
              );

              if (reminderDateTime
                  .isAfter(now.add(const Duration(seconds: 1)))) {
                await scheduleReminderNotification(reminder);
                rescheduledCount++;
                debugPrint(
                    '🔄 ✅ Rescheduled reminder ${reminder.id}: ${reminder.medicineName} at ${reminder.reminderDate} ${reminder.reminderTime} '
                    '(🔊${reminder.soundEnabled ? "ON" : "OFF"} 📳${reminder.vibrationEnabled ? "ON" : "OFF"})');
              } else {
                debugPrint(
                    '🔄 ⏭️ Skipped reminder ${reminder.id}: time is in the past');
              }
            } catch (e) {
              debugPrint(
                  '🔄 ❌ Error parsing reminder ${reminder.id}: $e');
            }
          } else {
            debugPrint(
                '🔄 ❌ Invalid date/time format for reminder ${reminder.id}');
          }
        }
      }

      debugPrint('🔄 Total rescheduled: $rescheduledCount');
      debugPrint('🔄 ============================================');
      debugPrint('');
    } catch (e, st) {
      debugPrint('❌ Error rescheduling reminders: $e\n$st');
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
      debugPrint('Current time: ${tz.TZDateTime.now(tz.local)}');

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

  /// Test scheduled notification - schedules 1 minute from now
  Future<void> testScheduledNotification({
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    if (kIsWeb) {
      debugPrint(
          '⚠️ Web platform - scheduled notifications not supported');
      return;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(minutes: 1));

      debugPrint('');
      debugPrint(
          '🧪 ========== TEST SCHEDULED NOTIFICATION ==========');
      debugPrint('Current time: ${now.toString()}');
      debugPrint('Will schedule for: ${scheduledTime.toString()}');
      debugPrint('(1 minute from now)');
      debugPrint(
          'Sound: ${soundEnabled ? "ON" : "OFF"} | Vibration: ${vibrationEnabled ? "ON" : "OFF"}');
      debugPrint(
          '==================================================');
      debugPrint('');

      final channelId = _channelIdFor(
          soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled);
      final channelName = _channelNameFor(
          soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled);

      await _localNotifications.zonedSchedule(
        999999,
        '🧪 Test Scheduled Notification',
        'Scheduled 1 min ago at ${now.hour}:${now.minute.toString().padLeft(2, '0')} '
            '| Sound: ${soundEnabled ? "ON" : "OFF"} | Vib: ${vibrationEnabled ? "ON" : "OFF"}',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            playSound: soundEnabled,
            enableVibration: vibrationEnabled,
            vibrationPattern: vibrationEnabled
                ? Int64List.fromList(_vibrationPattern)
                : null,
            sound: soundEnabled
                ? const RawResourceAndroidNotificationSound('alarm_tone')
                : null,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: soundEnabled,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      final pending = await _localNotifications.pendingNotificationRequests();
      final testNotif = pending.where((n) => n.id == 999999).toList();

      if (testNotif.isNotEmpty) {
        debugPrint('✅ Test notification successfully scheduled!');
        debugPrint('   Wait 1 minute to see if it fires...');
      } else {
        debugPrint(
            '❌ Test notification NOT found in pending list!');
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
