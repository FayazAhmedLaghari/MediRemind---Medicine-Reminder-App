# 🔔 Notification Quick Debug Card

## ⚡ Quick Test (30 seconds)

1. Open **Reminders** screen
2. Tap **🔔 bell icon** (top-right)
3. Check notification panel

**Result:**
- ✅ See "Test Notification" → **WORKING!**
- ❌ Nothing appears → **Permission issue** (see below)

## 🚨 If Test Fails

### Step 1: Check App Permissions
```
Settings → Apps → MediRemind → Notifications
✅ Must be ON
```

### Step 2: Check Alarm Permission (Android 13+)
```
Settings → Apps → MediRemind → 
  Special app access → Alarms & reminders
✅ Must be ALLOWED
```

### Step 3: Re-grant Permissions
```
1. Uninstall app
2. Reinstall app
3. Tap test notification button
4. Grant permission when prompted
```

## 📱 Create Test Reminder

```
1. Add Reminder button
2. Select any medicine
3. Set time: CURRENT_TIME + 2 minutes
4. Save
5. Wait 2 minutes
6. ✅ Notification should appear
```

## 🔍 Console Log Checklist

**Look for these in order:**
```
✅ 🎯 [VIEW] Creating reminder
✅ 📝 [REMINDER] Adding reminder
✅ 📝 [REMINDER] ✅ Inserted into DB with ID
✅ 📝 [REMINDER] Scheduling notification
✅ 🔔 [NOTIFICATION] Starting notification schedule
✅ 🔔 [PERMISSION] ✅ Notification permissions granted
✅ 🔔 [NOTIFICATION] ✅ Successfully scheduled notification
```

**Bad signs:**
```
❌ User denied notification permission
❌ Scheduled time is in the past
❌ Error scheduling notification
```

## 🎯 Common Fixes

| Problem | Fix |
|---------|-----|
| No test notification | Check Settings → Notifications |
| Permission dialog won't show | Reinstall app |
| Time "in the past" error | Set time in future (not now) |
| Notification doesn't fire | Check battery optimization |
| Works once then stops | Check if permission got revoked |

## ✨ Success Indicators

- [x] Test notification appears instantly
- [x] Console says "Successfully scheduled"
- [x] Reminder notification fires at exact time
- [x] No error messages

## 📞 Emergency Reset

```bash
# Complete fresh start:
1. Uninstall app completely
2. Settings → Apps → Show system → 
   Find MediRemind → Clear data
3. flutter clean
4. flutter pub get
5. flutter run
6. Test notification → Grant permission
```

## 🔧 Debug Commands

```bash
# Check if notification service initialized
Look for: "Notification service initialized successfully"

# Check if permissions granted  
Look for: "🔔 [PERMISSION] ✅ Notification permissions granted"

# Check scheduled notifications (Android)
adb shell dumpsys notification
```

---

## 💡 Pro Tip

**Always test with the test notification button FIRST!**
- If test works → Reminder scheduling works
- If test fails → Fix permissions FIRST

---

**Quick Help:** See `NOTIFICATION_TROUBLESHOOTING_GUIDE.md` for complete guide
