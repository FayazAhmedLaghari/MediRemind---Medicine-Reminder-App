# ⚠️ Web Platform Limitations

## Current Status

This app is **primarily designed for mobile platforms** (Android/iOS). While it can run on web for testing UI, some features have limitations:

## ⚠️ Limited Features on Web

### 1. **Notifications** ❌
- Local scheduled notifications **NOT supported** on web
- Only mobile platforms (Android/iOS) support exact alarm scheduling
- Test notification button will show warning on web

### 2. **Database** ⚠️
- Uses **in-memory database** on web
- Data is **not persisted** after page refresh
- Full SQLite persistence only on mobile/desktop

### 3. **Firebase Cloud Messaging** ⚠️
- Service worker issues on web (MIME type errors)
- FCM initialization skipped on web platform
- Push notifications not available

### 4. **Image Picker** ⚠️
- Camera access limited on web browsers
- Gallery picker works but with browser limitations

## ✅ What Works on Web

- ✅ Authentication (Firebase Auth)
- ✅ UI Navigation & Design
- ✅ Medicine list (temporary storage)
- ✅ Reminder list (temporary storage)
- ✅ Profile management
- ✅ OCR text recognition (from uploaded images)
- ✅ Calendar UI

## 🎯 Recommended Platform

**For full functionality, run the app on:**
- ✅ **Android** (physical device or emulator)
- ✅ **iOS** (physical device or simulator)

### How to Run on Mobile:

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Check connected devices
flutter devices
```

## 🔧 Current Error Messages Explained

### Error: "failed-service-worker-registration"
**Cause:** Firebase Messaging requires service worker on web  
**Solution:** Ignored on web, app continues normally  
**Impact:** No FCM push notifications on web

### Error: "databaseFactory not initialized"
**Cause:** SQLite doesn't work on web like on mobile  
**Solution:** App uses in-memory database automatically  
**Impact:** Data lost on page refresh

### Error: "LateInitializationError: Field '_instance' has not been initialized"
**Cause:** Notification service trying to cancel notifications before initialization  
**Solution:** Fixed with web platform checks  
**Impact:** None - notifications skipped on web

## 🎉 These Errors Are Expected on Web!

The app is designed to:
1. ✅ Detect web platform automatically
2. ✅ Skip unsupported features gracefully
3. ✅ Continue working with available features
4. ✅ Show warnings in console for debugging

**All errors listed above are normal when running on web and won't affect the app's operation.**

## 🚀 Development Workflow

### For Testing UI/Layout:
```bash
flutter run -d chrome
# or
flutter run -d edge
```
**Note:** Expect warning messages about notifications/database

### For Testing Full Functionality:
```bash
# Connect Android device/emulator
flutter run -d android

# Or use iOS
flutter run -d ios
```

## 📱 Production Deployment

**Recommended deployment targets:**
- ✅ Google Play Store (Android)
- ✅ Apple App Store (iOS)
- ⚠️ Web (limited features - not recommended for production)

## ✨ Summary

- **Mobile:** All features work perfectly ✅
- **Web:** UI testing only, limited functionality ⚠️
- **Errors on web:** Expected and handled gracefully ✅

---

**To use all features (notifications, persistent storage, etc.), please run on Android or iOS device/emulator.**

**Status:** Web limitations documented & handled ✅  
**Last Updated:** February 2, 2026
