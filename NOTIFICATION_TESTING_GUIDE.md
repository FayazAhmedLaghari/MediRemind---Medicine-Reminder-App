# 🔔 Notification Testing & Debug Guide

## ✅ Issues Fixed

### Critical Issue #1: Time Validation Logic
**Problem**: The notification scheduling was rejecting reminders with times in the past, but the timezone handling had issues.

**Fix Applied**:
- Changed time validation from `isBefore(now)` to `isBefore(now.add(1 second))`
- This allows scheduling reminders that are 1+ seconds in the future
- Added comprehensive debug logging to trace the issue

### Critical Issue #2: Missing Debug Logging
**Problem**: No visibility into why notifications weren't being scheduled

**Fix Applied**:
- Added detailed debug logs with emoji prefixes for easy filtering:
  - 🔔 = Notification Service logs
  - 📝 = Reminder ViewModel logs
  - 🎯 = Reminders View logs

---

## 🧪 Complete Testing Procedure

### Step 1: Enable Console Logging
```bash
# In your terminal, run:
flutter logs
```

This will show all debug messages with 🔔, 📝, and 🎯 prefixes.

---

### Step 2: Create a Test Reminder

1. **Open the App**
   - Launch MediRemind on your device/emulator

2. **Navigate to Reminders Section**
   - Tap the "Medication Reminders" tab in bottom navigation
   - Or access from Dashboard

3. **Add a New Reminder**
   - Click the "➕ ADD REMINDER" button
   - Expected logs:
     ```
     🎯 [VIEW] Creating reminder: [Medicine Name] at [Time]
     ```

4. **Fill in the Details**
   - **Select Medicine**: Pick any medicine from dropdown
   - **Set Reminder Time**: Choose a time **1-2 minutes in the future**
     - For example, if it's 2:30 PM now, set reminder to 2:31 or 2:32 PM
   - **Add Notes** (optional): Any notes you want
   - Click **Add**

5. **Verify Console Logs**
   Watch for these log sequences in order:

   ```
   🎯 [VIEW] Creating reminder: [Medicine Name] at [Time]
   📝 [REMINDER] Adding reminder: [Medicine Name]
   📝 [REMINDER] Date: YYYY-MM-DD, Time: HH:MM
   📝 [REMINDER] ✅ Inserted into DB with ID: [number]
   📝 [REMINDER] Scheduling notification for reminder [number]...
   🔔 [NOTIFICATION] Starting notification schedule for reminder [number]
   🔔 [NOTIFICATION] Medicine: [Medicine Name], Date: YYYY-MM-DD, Time: HH:MM
   🔔 [NOTIFICATION] Parsed time: YYYY-M-D HH:MM
   🔔 [NOTIFICATION] Scheduled: [DateTime], Now: [DateTime]
   🔔 [NOTIFICATION] Time difference: [seconds] seconds
   🔔 [NOTIFICATION] ✅ Time validation passed
   🔔 [NOTIFICATION] Attempting to schedule local notification...
   🔔 [NOTIFICATION] ✅ Successfully scheduled notification for reminder [number] at [DateTime]
   📝 [REMINDER] ✅ Notification scheduled
   🎯 [VIEW] Reminder added successfully, reloading data...
   ```

---

### Step 3: Close the App

1. **Completely Close the App**
   - Use your device's recent apps menu
   - Swipe the app away to force close
   - Do NOT use back button - you must fully terminate the app process

2. **Wait for Notification**
   - Wait for the scheduled time to arrive
   - Your device should show a notification:
     ```
     Medicine Reminder
     Time to take [Medicine Name] - [Dosage]
     ```

---

### Step 4: Test Notification Actions

When the notification appears, you'll see:
- **Taken**: Mark this reminder as completed
- **Snooze 10 min**: Reschedule for 10 minutes later

1. **Tap "Taken"**
   - The reminder should be marked as completed
   - Check logs for:
     ```
     ✅ Reminder [number] marked as completed
     ```

2. **Tap "Snooze 10 min"**
   - The reminder should be rescheduled for 10 minutes later
   - Check logs for:
     ```
     ✅ Reminder [number] snoozed for 10 minutes
     ```

---

## 🐛 Troubleshooting

### Issue: Notification doesn't appear
**Check these logs**:

1. **Log contains**: `Time validation passed` ✅
   - Notification was scheduled successfully
   - Wait for the scheduled time

2. **Log contains**: `SKIPPED: Scheduled time is in the past`
   - ❌ You selected a time that already passed
   - Create a new reminder with time 1-2 minutes in the future

3. **Log contains**: `Invalid date/time format`
   - ❌ Date or time parsing failed
   - Check that you selected valid date and time

4. **Log missing entirely**
   - ❌ Reminder might not have been created
   - Check if "Reminder added successfully" appeared on screen

### Issue: Notification silently fails
**Debug steps**:

1. **Check Device Notification Settings**
   - Android: Settings → Apps → MediRemind → Notifications (enabled?)
   - Check notification channel is created

2. **Check Permissions**
   - The app should request notification permission on first run
   - If denied, enable in Settings

3. **Verify Time Format**
   - Reminder date must be: `YYYY-MM-DD` (e.g., `2026-02-01`)
   - Reminder time must be: `HH:MM` in 24-hour format (e.g., `14:30`)

4. **Check Database**
   - The reminder must exist in the local database
   - The reminder status must be `pending`

### Issue: Reminders don't persist after app restart
**Check**:
1. Reminder was saved to database (logs show "Inserted into DB with ID")
2. Device is restarted (forces reschedule on startup)
3. Check `rescheduleAllReminders()` logs in main.dart

---

## 📋 Screen Linkage Verification

### Screens that Display Reminders

1. **Reminders View** (`lib/Views/Reminders/reminders_view.dart`)
   - Calendar display
   - Daily reminder list
   - Add reminder dialog
   - Reminder status badges

2. **Dashboard View** (`lib/Views/dashboard_view.dart`)
   - Should show upcoming reminders
   - Should have link to Reminders section

3. **Medicine View** (`lib/Views/Medicine/...`)
   - Should show medicines
   - Each medicine can have reminders created

### Navigation Links
- ✅ Bottom navigation → Reminders tab → RemindersView
- ✅ Dashboard → "View All" reminders → RemindersView
- ✅ Medicine list → Select medicine → Can create reminder
- ✅ Notification tap → Should open relevant reminder (if implemented)

---

## 📊 Expected Behavior Summary

| Action | Expected Behavior | Logs |
|--------|------------------|------|
| Add reminder | Dialog closes, snackbar shows success | 🎯📝🔔 logs all in sequence |
| Wait for time | Notification appears on lock screen | No new logs |
| Tap notification | App opens (or comes to foreground) | Notification handler logs |
| Tap "Taken" | Reminder marked completed, notification gone | Completion logs |
| Tap "Snooze" | Notification rescheduled for +10min | Snooze logs |
| Close & reopen app | Pending reminders rescheduled | Reschedule all logs |

---

## 🔍 Log Filtering

To see only notification-related logs:
```bash
flutter logs | grep "NOTIFICATION\|REMINDER\|VIEW"
```

To see only errors:
```bash
flutter logs | grep "❌\|Error"
```

To see the full flow:
```bash
flutter logs | grep "🔔\|📝\|🎯"
```

---

## 💾 Database Check

To verify reminders are being saved, you can check the local database:
- Check `rescheduleAllReminders()` in main.dart
- It should log all pending reminders on app startup
- Each reminder should appear in logs

---

## ✅ Quick Checklist

- [ ] User can see Reminders view
- [ ] Calendar displays correctly
- [ ] "Add Reminder" button works
- [ ] Dialog opens with medicine/time pickers
- [ ] After adding, reminders list refreshes
- [ ] Logs show complete flow (🎯 → 📝 → 🔔)
- [ ] Scheduled time is 1-2 minutes in future
- [ ] Close app completely
- [ ] Notification appears at scheduled time
- [ ] "Taken" action works
- [ ] "Snooze" action works
- [ ] App restarts, reminders still pending show logs

