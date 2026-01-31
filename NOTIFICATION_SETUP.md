# Notification Feature Implementation Guide

## Overview
This document describes the complete notification system implementation for the MediRemind app, including Firebase Cloud Messaging (FCM) and local notifications.

## Features Implemented

### ✅ Core Features
1. **Medicine Reminder Scheduling** - Automatically schedules notifications when reminders are created
2. **Local Notifications** - Works offline and when app is closed
3. **Firebase Cloud Messaging** - Cloud-based notifications for online scenarios
4. **Sound & Vibration Alerts** - Default system sounds with vibration enabled
5. **Works When App is Closed** - Notifications work in background and terminated states
6. **Offline Notification Handling** - Local notifications ensure reminders work without internet

### ✅ Additional Features
- Notification actions (Mark as Taken, Snooze 10 minutes)
- Automatic rescheduling on app startup
- Notification cancellation when reminders are deleted/updated
- Support for foreground, background, and terminated app states

## Setup Instructions

### 1. Install Dependencies

Run the following command to install all required packages:

```bash
flutter pub get
```

### 2. Android Configuration

The Android configuration has been updated in `android/app/src/main/AndroidManifest.xml`:
- ✅ Notification permissions added
- ✅ Background service permissions added
- ✅ Boot receiver for rescheduling after device restart
- ✅ Firebase Messaging service configured

**Note:** For Android 13+ (API 33+), notification permissions are requested at runtime.

### 3. iOS Configuration

The iOS configuration has been updated in `ios/Runner/Info.plist`:
- ✅ Background modes enabled (remote-notification, fetch)
- ✅ Firebase AppDelegate proxy disabled (handled by Flutter)

**Additional iOS Setup Required:**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to **Signing & Capabilities**
3. Enable **Push Notifications** capability
4. Enable **Background Modes** and check:
   - Remote notifications
   - Background fetch

### 4. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `smart-medicine-reminder-c6bfa`
3. Go to **Cloud Messaging**
4. Configure notification settings:
   - Set default notification channel (Android): `medicine_reminders`
   - Configure APNs certificates (iOS) if needed

### 5. Testing Notifications

#### Test Local Notifications (Offline)
1. Create a reminder in the app
2. Set the time to 1-2 minutes in the future
3. Close the app completely
4. Wait for the notification

#### Test FCM Notifications (Online)
1. Get the FCM token from app logs (check debug console)
2. Use Firebase Console to send a test notification
3. Or use the FCM API to send notifications

## Architecture

### Notification Service (`lib/service/notification_service.dart`)

The `NotificationService` class handles all notification operations:

- **Initialization**: Sets up FCM and local notifications
- **Scheduling**: Creates scheduled notifications for reminders
- **Cancellation**: Removes notifications when reminders are deleted
- **Action Handling**: Processes notification actions (Taken, Snooze)

### Integration Points

#### ReminderViewModel (`lib/viewmodels/reminder_viewmodel.dart`)
- Automatically schedules notifications when reminders are added
- Cancels notifications when reminders are updated/deleted
- Reschedules all pending reminders on app startup

#### Main App (`lib/main.dart`)
- Initializes notification service on app startup
- Reschedules all pending reminders

## Notification Flow

### When a Reminder is Created:
1. User creates a reminder in the app
2. `ReminderViewModel.addReminder()` is called
3. Reminder is saved to database
4. `NotificationService.scheduleReminderNotification()` is called
5. Local notification is scheduled for the reminder time

### When Notification Fires:
1. System displays notification (even if app is closed)
2. User can:
   - Tap notification → Opens app
   - Tap "Taken" → Marks reminder as completed
   - Tap "Snooze" → Reschedules for 10 minutes later

### When App Starts:
1. `NotificationService.initialize()` is called
2. All pending reminders are loaded from database
3. Notifications are rescheduled for future reminders

## Notification Details

### Android Notification Channel
- **Channel ID**: `medicine_reminders`
- **Channel Name**: Medicine Reminders
- **Importance**: High
- **Sound**: Default system sound
- **Vibration**: Enabled

### Notification Content
- **Title**: "Medicine Reminder"
- **Body**: "Time to take [Medicine Name] - [Dosage]"
- **Expanded Text**: Includes notes if available
- **Actions**: "Taken" and "Snooze 10 min"

## Troubleshooting

### Notifications Not Appearing

1. **Check Permissions**:
   - Android: Settings → Apps → MediRemind → Notifications (should be enabled)
   - iOS: Settings → Notifications → MediRemind (should be enabled)

2. **Check Logs**:
   - Look for "Scheduled notification for reminder X" in debug console
   - Check for any error messages

3. **Verify Time**:
   - Ensure reminder time is in the future
   - Check device timezone settings

4. **Battery Optimization**:
   - Android: Disable battery optimization for the app
   - iOS: Ensure Background App Refresh is enabled

### FCM Token Not Received

1. Check Firebase configuration files are present
2. Verify internet connection
3. Check Firebase Console for project settings
4. Review debug logs for FCM initialization errors

### Notifications Not Working After App Restart

- The app automatically reschedules notifications on startup
- If issues persist, check database for pending reminders
- Verify notification service initialization in logs

## Code Structure

```
lib/
├── service/
│   ├── notification_service.dart    # Main notification service
│   └── database_helper.dart         # Database operations
├── viewmodels/
│   └── reminder_viewmodel.dart      # Reminder state management
├── models/
│   └── reminder_model.dart          # Reminder data model
└── main.dart                         # App initialization
```

## Future Enhancements

Potential improvements:
- Custom notification sounds
- Recurring reminder notifications
- Notification grouping
- Rich notifications with images
- Notification history
- Custom snooze durations

## Support

For issues or questions:
1. Check debug logs for error messages
2. Verify all dependencies are installed
3. Ensure Firebase is properly configured
4. Test with a simple reminder first

## Notes

- Notifications use the device's local timezone
- Notifications are stored locally and persist across app restarts
- FCM is used for cloud notifications but local notifications work offline
- The system automatically handles timezone changes and daylight saving time

