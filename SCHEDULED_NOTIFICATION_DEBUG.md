# 🔍 Scheduled Notification Debugging Guide

## Problem Statement
- ✅ **Instant test notifications work** - appear immediately when clicked
- ❌ **Scheduled reminder notifications don't fire** - scheduled but don't appear at the set time

## New Testing Tools Added

### 1. **Three Test Buttons in Reminders Screen**
Located in AppBar:

1. **📋 List Icon** - Debug Pending Notifications
   - Shows all pending notifications in console
   - Displays notification IDs, titles, and bodies

2. **⏱️ Alarm Add Icon** - Test Scheduled (1 min)
   - Schedules a test notification exactly 1 minute from now
   - Uses same scheduling method as real reminders
   - Check console for verification logs

3. **🔔 Bell Icon** - Test Instant Notification
   - Shows immediate notification (already working)
   - Confirms notification system is functional

### 2. **Enhanced Logging**
When scheduling notifications, the console now shows:
```
🔔 [NOTIFICATION] ✅ Verified: Notification X is in pending list
🔔 [NOTIFICATION] ⏰ Current time: 2024-01-15 14:30:00.000
🔔 [NOTIFICATION] 📅 Scheduled for: 2024-01-15 16:45:00.000
🔔 [NOTIFICATION] ⏱️  Will fire in: 135 min 0 sec
🔔 [NOTIFICATION] Total pending notifications: 3
```

## Testing Procedure

### Step 1: Test Immediate Notification (Baseline)
1. Open Reminders screen
2. Tap the **🔔 Bell icon** (Test Instant Notification)
3. ✅ **Expected**: Notification appears immediately
4. **Result**: _____________

### Step 2: Test Scheduled Notification (1 Minute)
1. Make sure you're still on Reminders screen
2. Tap the **⏱️ Alarm Add icon** (Test Scheduled 1 min)
3. Check the console for logs showing:
   - Current time
   - Scheduled time (1 minute from now)
   - Verification that notification is in pending list
4. **Wait exactly 1 minute**
5. ✅ **Expected**: Notification appears after 1 minute
6. **Result**: _____________

### Step 3: View All Pending Notifications
1. Tap the **📋 List icon** (Debug Pending)
2. Check console for list of all pending notifications
3. Look for:
   - Test notification (ID: 999999)
   - Any reminder notifications you've created
4. **Count**: _____ pending notifications

### Step 4: Test Real Reminder (2-3 Minutes)
1. Add a new reminder:
   - Click **+ Add Reminder** button
   - Choose medicine
   - Set dosage and quantity
   - **Set time 2-3 minutes from current time**
   - Save
2. Check console immediately after saving for:
   ```
   🔔 [NOTIFICATION] ✅ Successfully scheduled notification for reminder X at [TIME]
   🔔 [NOTIFICATION] ⏱️  Will fire in: X min X sec
   ```
3. Tap **📋 List icon** to verify it's in pending list
4. **Wait for scheduled time**
5. ✅ **Expected**: Notification appears at scheduled time
6. **Result**: _____________

## Important System Checks

### Android 13+ Exact Alarm Permission
When you first request permissions, check console for:
```
🔔 [PERMISSION] Exact alarm permission: true/false
```

If **false** or showing error, you may need to:
1. Go to **Settings** → **Apps** → **MediRemind**
2. Look for **"Alarms & Reminders"** or **"Exact Alarm"** permission
3. Enable it manually

### Battery Optimization
Some Android devices kill scheduled alarms to save battery:
1. Go to **Settings** → **Battery** → **Battery Optimization**
2. Find **MediRemind** app
3. Set to **"Don't optimize"** or **"Unrestricted"**

### Timezone
The app uses your device's timezone. Verify:
- Your device timezone is correct
- App is using timezone package v0.9.4
- Console logs show correct current time

## Common Issues & Solutions

### Issue 1: "Notification NOT found in pending list"
**Symptoms**: Console shows ❌ error after scheduling
**Solutions**:
- Exact alarm permission not granted
- Android system restrictions
- Try enabling "Unrestricted battery usage"

### Issue 2: Notification scheduled but doesn't fire
**Symptoms**: ✅ in pending list, but no notification appears
**Solutions**:
- Check battery optimization settings
- Ensure exact alarm permission granted
- Test with longer delay (10+ minutes)
- Check if notification channel is enabled in system settings

### Issue 3: Test scheduled (1 min) works but real reminders don't
**Symptoms**: 1-minute test fires, but 2+ hour reminders don't
**Solutions**:
- System may be killing long-term scheduled notifications
- Device sleep mode interfering
- Check manufacturer-specific battery settings (Xiaomi, Huawei, etc.)

## Reporting Results

When reporting back, please provide:

1. **Device Info**:
   - Device model: ___________
   - Android version: ___________
   - Manufacturer: ___________

2. **Test Results**:
   - [ ] Instant notification works
   - [ ] 1-minute scheduled test works
   - [ ] Real reminder (2-3 min) works
   - [ ] Notifications appear in pending list

3. **Console Logs**:
   Copy and paste relevant sections showing:
   - Permission request logs
   - Scheduling logs with timestamps
   - Verification logs

4. **Settings**:
   - [ ] Exact alarm permission granted
   - [ ] Battery optimization disabled
   - [ ] Notification channel enabled

## Technical Details

### Scheduling Method Used
```dart
await _localNotifications.zonedSchedule(
  id,
  title,
  body,
  scheduledTime, // TZDateTime in local timezone
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ⚠️ Requires exact alarm permission
  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
);
```

### Permissions Required (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Next Steps Based on Results

**If 1-minute test works**:
→ Issue is likely with long-term scheduling or battery optimization

**If 1-minute test doesn't work**:
→ Issue is with exact alarm permissions or notification settings

**If nothing works**:
→ Check if device has manufacturer-specific restrictions (Xiaomi MIUI, Huawei EMUI, etc.)

## Manufacturer-Specific Issues

### Xiaomi (MIUI)
- Go to **Security** → **Permissions** → **Autostart**
- Enable autostart for MediRemind
- **Battery Saver** → Set MediRemind to "No restrictions"

### Huawei (EMUI)
- **Settings** → **Battery** → **App Launch**
- Set MediRemind to "Manual"
- Enable "Auto-launch", "Secondary launch", "Run in background"

### Samsung (One UI)
- **Settings** → **Apps** → **MediRemind** → **Battery**
- Set to "Unrestricted"
- **Settings** → **Device care** → **Battery** → **App power management**
- Add MediRemind to "Apps that won't be put to sleep"

### OnePlus (OxygenOS)
- **Settings** → **Battery** → **Battery Optimization**
- Find MediRemind and set to "Don't optimize"

---

**Created**: To debug scheduled notification timing issues
**Status**: Active debugging in progress
**Related Files**: 
- [notification_service.dart](lib/service/notification_service.dart)
- [reminders_view.dart](lib/Views/Reminders/reminders_view.dart)
