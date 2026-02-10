# 💊 MediRemind - Medicine Reminder App
A comprehensive Flutter mobile application for managing medications, tracking reminders, and maintaining medical records.
---
## 📋 Project Overview
**MediRemind** is a fully-featured medicine reminder application built with Flutter that helps patients:
- Register and authenticate securely with Firebase
- Manage their medication database
- Scan prescriptions using OCR (Optical Character Recognition)
- Set and track medication reminders with an interactive calendar
- View their medical profile and patient information
- Receive password recovery through email

**Development Timeline:** January 17-19, 2026
**Status:** ✅ Fully Functional with All Core Features

---

## 🎯 Features Implemented

### 1. **Authentication System** ✅
- **User Registration** - Create new patient accounts with validation
- **User Login** - Secure authentication via Firebase
- **Forgot Password** - Email-based password recovery
- **Logout** - Secure logout with confirmation dialog
- **Password Update** - Users can reset passwords via email recovery link

**Files:**
- `lib/service/auth_service.dart` - Authentication logic
- `lib/viewmodels/auth_viewmodel.dart` - Auth state management
- `lib/Views/login_view.dart` - Login interface
- `lib/Views/register_view.dart` - Registration interface
- `lib/Views/forgot_password_view.dart` - Password recovery

---

### 2. **Dashboard & Navigation** ✅
- **Patient Info Card** - Display current patient details
- **Quick Access Tiles** - Navigate to medicines, scanner, reminders, profile
- **Drawer Menu** - Sidebar navigation with all features
- **Patient Data Loading** - Automatic patient info retrieval from Firestore

**Files:**
- `lib/Views/dashboard_view.dart` - Main dashboard
- `lib/viewmodels/dashboard_viewmodel.dart` - Dashboard state management

---

### 3. **Medicine Management** ✅
- **Medicine List View** - Display all medicines with modern UI
- **Add Medicine** - Add new medications with dosage and frequency
- **Edit Medicine** - Update existing medicine details
- **Delete Medicine** - Remove medicines from the list
- **Modern Animations** - Staggered card animations and transitions
- **SQLite Database** - Local persistence of medicine data

**Features:**
- Medicine name, dosage, frequency, time, notes
- Delete confirmation dialog
- Real-time list updates
- Professional card-based UI with gradients

**Files:**
- `lib/Views/Medicine/medicine_list_view.dart` - Medicine list display
- `lib/Views/Medicine/add_edit_medicine_view.dart` - Add/Edit dialog
- `lib/viewmodels/medicine_viewmodel.dart` - Medicine state management
- `lib/models/medicine_model.dart` - Medicine data model
- `lib/service/database_helper.dart` - SQLite operations

---

### 4. **OCR Prescription Scanner** ✅
- **Camera Integration** - Take photos of prescriptions directly
- **Gallery Access** - Select images from device storage
- **Text Recognition** - Extract text from prescriptions using Google ML Kit
- **Medicine Auto-Fill** - Parse medicine names and details from OCR text
- **Direct Save** - Quick save button to add medicines without manual editing
- **Auto-Data Parameter** - Intelligent data pre-population in add medicine dialog
- **Permission Handling** - Camera and storage permissions for Android

**Workflow:**
1. User opens Scanner from dashboard
2. Captures prescription photo or selects from gallery
3. ML Kit recognizes and extracts text
4. System parses medicine information
5. User can auto-fill or manually edit details
6. Medicine saved directly to database

**Technical Stack:**
- `google_mlkit_text_recognition: ^0.15.0` - OCR engine
- `image_picker: ^1.1.2` - Camera and gallery access
- Permission handling for Android

**Files:**
- `lib/Views/ocr/scan_prescription_view.dart` - Scanner interface
- `lib/viewmodels/ocr_viewmodel.dart` - OCR state management
- `android/app/src/main/AndroidManifest.xml` - Permissions

---

### 5. **Reminders System with Calendar** ✅
- **Interactive Calendar Widget** - Visual month navigation
- **Date Selection** - Click any date to view reminders
- **Add Reminders** - Create medication reminders with date and time
- **Medicine Dropdown** - Select from existing medicines
- **Time Picker** - Set exact reminder times
- **Reminder List** - View all reminders for selected date
- **Mark as Done** - Mark reminders as completed
- **Delete Reminders** - Remove reminders with confirmation
- **SQLite Persistence** - Reminders saved to local database
- **Month Navigation** - Browse between months with arrow buttons

**Calendar Features:**
- Current date highlighted with blue border
- Selected date shown with blue background
- Empty state handling for days without reminders
- Today's date always indicated
- Smooth month transitions

**Reminder Details:**
- Medicine name (from dropdown)
- Reminder date (yyyy-MM-dd format)
- Reminder time (HH:mm format)
- Dosage information
- Status tracking (pending, completed, missed)
- Notes field
- Auto timestamp tracking

**Database Integration:**
- Version 2 SQLite database with migration support
- Reminders table with complete CRUD operations
- Query by date, medicine, or status
- Full async/await implementation

**Files:**
- `lib/Views/Reminders/reminders_view.dart` - Calendar and reminder UI
- `lib/viewmodels/reminder_viewmodel.dart` - Reminder state management
- `lib/models/reminder_model.dart` - Reminder data model
- `lib/service/database_helper.dart` - Database operations

---

### 6. **Patient Profile** ✅
- **Profile Header** - Display patient avatar and name
- **Personal Information** - Age, gender, email in info cards
- **Medical History** - Full medical history display
- **Account Management** - Logout and delete account options
- **Gradient UI** - Modern blue gradient design
- **Responsive Layout** - Works on all screen sizes
- **Real-time Data** - Loads patient data from Firestore

**Profile Sections:**
- Avatar with person icon
- Patient name and email
- Age, gender, email info cards
- Medical history in detail card
- Logout button with confirmation
- Delete account placeholder

**Files:**
- `lib/Views/profile_view.dart` - Profile interface
- `lib/viewmodels/dashboard_viewmodel.dart` - Data loading

---

## 🔧 Technical Stack

### **Frontend Framework**
- **Flutter 3.x** - Modern UI framework
- **Dart 3.x** - Null-safe programming language

### **State Management**
- **Provider 6.1.5+1** - Reactive state management with ChangeNotifier

### **Backend Services**
- **Firebase Core** - Firebase initialization
- **Firebase Authentication** - User authentication and account management
- **Cloud Firestore** - Cloud database for patient and medical data

### **Local Database**
- **SQLite (sqflite 2.3.3+1)** - Local persistence for medicines and reminders

### **AI & Machine Learning**
- **Google ML Kit (Text Recognition 0.15.0)** - OCR for prescription scanning

### **Utilities**
- **Image Picker 1.1.2** - Camera and gallery access
- **intl 0.19.0** - Date formatting and localization

### **Architecture**
- **MVVM Pattern** - Model-View-ViewModel architecture
- **Separation of Concerns** - Views, ViewModels, Services, Models organized separately
- **Reactive Programming** - Provider for state management and UI reactivity

---

## 🐛 Bug Fixes & Solutions

### **Issue 1: Keyboard Overflow on Login**
**Problem:** When opening keyboard on mobile, TextField content would overflow
**Solution:** 
- Wrapped login form in `SingleChildScrollView`
- Set `resizeToAvoidBottomInset: true` in Scaffold
- Added proper padding and margins

**Status:** ✅ Fixed

---

### **Issue 2: RenderFlex Overflow (22 pixels on right)**
**Problem:** Calendar widget day labels were overflowing the right edge
**Root Cause:** 
- Day labels Row used `spaceAround` with fixed 50px SizedBoxes
- 7 days × 50px = 350px minimum width exceeded available space
- IconButtons in month header had default padding causing asymmetry

**Solution Implemented:**
```dart
// BEFORE (Problematic):
Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: ['Sun', 'Mon', ...].map((day) => 
    SizedBox(width: 50, child: Center(child: Text(day)))
  ).toList(),
)

// AFTER (Fixed):
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: ['Sun', 'Mon', ...].map((day) => 
    Expanded(
      child: Center(child: Text(day))
    )
  ).toList(),
)
```

**Key Changes:**
1. Changed `spaceAround` to `spaceEvenly` for uniform spacing
2. Replaced fixed `SizedBox(width: 50)` with `Expanded` children
3. Wrapped navigation buttons in explicit `SizedBox(width: 48, height: 48)`
4. Moved container margins to GridView `spacing` property
5. Ensured all children properly fit within available width

**Result:** ✅ Calendar displays perfectly without overflow on all screen sizes

---

### **Issue 3: Reminders Not Displaying After Save**
**Problem:** Added reminders weren't showing in the "Reminders for this day" list after saving
**Root Cause:** Async timing issue - UI updated before database write completed

**Solution:**
- Added `await` to `initState` microtask for loading reminders
- Used explicit `setState()` in `_loadDayReminders()`
- Implemented 300ms delay in add dialog before reload
- Added full reload cycle: `addReminder` → `loadReminders` → `getRemindersByDate`
- Added context mounting checks to prevent crashes

**Code Pattern:**
```dart
Future<void> addReminder(Reminder reminder) async {
  await _reminders.add(reminder.toMap());
  await loadReminders(); // Reload all reminders
}

// In UI:
setState(() {
  _dayReminders = reminders; // Force UI rebuild
});
```

**Status:** ✅ Fixed

---

## 📱 UI/UX Improvements

### **Keyboard Management**
- Proper `resizeToAvoidBottomInset` handling
- ScrollView wrappers for overflow prevention
- Focused bottom padding for keyboard avoidance

### **Modern Design**
- Gradient backgrounds (primary blue colors)
- Rounded corners (BorderRadius: 12-20px)
- Card-based layouts with elevation shadows
- Smooth animations and transitions
- Staggered animation effects on lists

### **Interactive Elements**
- Tap feedback on buttons and cards
- Dialog confirmations for destructive actions
- Toast notifications for user feedback
- Loading states with spinners
- Empty state handling

### **Responsive Layout**
- Flexible and Expanded widgets for responsive sizing
- Proper padding and margins for all screen sizes
- ScrollView wrappers where needed
- Constraint handling for different devices

---

## 📊 Database Schema

### **SQLite Database (Version 2)**

#### **Medicines Table**
```sql
CREATE TABLE medicines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  time TEXT NOT NULL,
  notes TEXT,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

#### **Reminders Table**
```sql
CREATE TABLE reminders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicineId INTEGER NOT NULL,
  medicineName TEXT NOT NULL,
  reminderDate TEXT NOT NULL,     -- yyyy-MM-dd format
  reminderTime TEXT NOT NULL,      -- HH:mm format
  dosage TEXT NOT NULL,
  status TEXT DEFAULT 'pending',   -- pending, completed, missed
  notes TEXT,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

### **Firebase Firestore Collections**

#### **Users Collection**
- uid (document ID)
- email
- name
- createdAt

#### **Patients Collection**
- uid (user reference)
- name
- age
- gender
- history (medical history)
- email
- createdAt

---

## 🏗️ Architecture Overview

### **Project Structure**
```
lib/
├── main.dart                    # App entry point with MultiProvider setup
├── firebase_options.dart        # Firebase configuration
├── core/
│   ├── app_colors.dart         # Color constants
│   └── theme.dart              # App theme configuration
├── models/
│   ├── medicine_model.dart      # Medicine data model
│   ├── patient_model.dart       # Patient data model
│   └── reminder_model.dart      # Reminder data model
├── service/
│   ├── auth_service.dart        # Firebase auth logic
│   ├── database_helper.dart     # SQLite operations
│   ├── db_helper.dart           # Database initialization
│   └── firestore_service.dart   # Firestore operations
├── viewmodels/
│   ├── auth_viewmodel.dart      # Auth state & logic
│   ├── dashboard_viewmodel.dart # Dashboard state & logic
│   ├── medicine_viewmodel.dart  # Medicine state & logic
│   ├── ocr_viewmodel.dart       # OCR state & logic
│   └── reminder_viewmodel.dart  # Reminder state & logic
└── Views/
    ├── login_view.dart          # Login screen
    ├── register_view.dart       # Registration screen
    ├── forgot_password_view.dart # Password recovery
    ├── dashboard_view.dart      # Main dashboard
    ├── profile_view.dart        # Patient profile
    ├── Medicine/
    │   ├── medicine_list_view.dart
    │   └── add_edit_medicine_view.dart
    ├── Reminders/
    │   └── reminders_view.dart
    └── ocr/
        └── scan_prescription_view.dart
```

### **Data Flow**
```
User Input → View → ViewModel → Service/Database → Model
                ↓
            Consumer/StateBuilder (Reactive UI Update)
```

### **State Management Pattern**
- **ChangeNotifier** in ViewModels
- **Provider** for dependency injection and reactivity
- **Consumer/Builder** widgets for responsive UI updates
- **Async/Await** for database operations

---

## ✨ Key Implementation Details

### **Authentication Flow**
1. User registers with email and password
2. Firebase Authentication creates account
3. Patient document created in Firestore
4. User logs in and navigates to dashboard
5. Patient data loaded from Firestore
6. Medicines and reminders loaded from SQLite

### **OCR Prescription Processing**
1. User captures/selects prescription image
2. ML Kit analyzes image and extracts text
3. ViewModel parses medicine information
4. Auto-fill suggests medicine details
5. User confirms or edits details
6. Medicine saved directly to SQLite and UI updates

### **Reminder Management Flow**
1. User selects date on calendar
2. App loads reminders for that date from SQLite
3. User clicks "Add Reminder" button
4. Dialog opens with medicine dropdown and time picker
5. User selects medicine and time, adds notes
6. Reminder saved to SQLite database
7. UI automatically refreshes to show new reminder
8. User can mark as done or delete reminder

### **Calendar Navigation**
1. Calendar displays current month by default
2. Left arrow decrements month
3. Right arrow increments month
4. Calendar grid recalculates based on `_displayedDate`
5. Day selection loads reminders for that date
6. Today's date always highlighted with blue border

---

## 🚀 How to Run

### **Prerequisites**
- Flutter 3.x installed
- Dart 3.x installed
- Firebase project configured
- Android SDK or Xcode for mobile testing

### **Setup Steps**
1. **Clone/Open Project**
   ```bash
   cd d:\Flutter Project\FYP\mediremindapp
   ```

2. **Get Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run App**
   ```bash
   flutter run
   ```

4. **For Release Build**
   ```bash
   flutter build apk --release
   ```

---

## 📝 Testing Checklist

### **Authentication**
- ✅ Register new account
- ✅ Login with credentials
- ✅ Logout with confirmation
- ✅ Forgot password email recovery
- ✅ Password reset functionality

### **Medicines**
- ✅ View all medicines
- ✅ Add new medicine
- ✅ Edit medicine details
- ✅ Delete medicine with confirmation
- ✅ Data persists after app restart

### **OCR Scanner**
- ✅ Take photo from camera
- ✅ Select image from gallery
- ✅ Extract text from prescription
- ✅ Auto-fill medicine details
- ✅ Direct save to medicine list
- ✅ Permissions work properly

### **Reminders**
- ✅ View calendar for current month
- ✅ Navigate between months
- ✅ Add reminder for selected date
- ✅ Select medicine from dropdown
- ✅ Set reminder time
- ✅ Mark reminder as done
- ✅ Delete reminder with confirmation
- ✅ Reminders persist after app restart
- ✅ Multiple reminders display for same date

### **Profile**
- ✅ Display patient information
- ✅ Show medical history
- ✅ Logout button functionality
- ✅ Delete account placeholder

---

## 🎨 UI/UX Highlights

### **Color Scheme**
- **Primary Blue:** `#0066CC` - Main accent color
- **Light Blue:** `#E0F0FF` - Light backgrounds
- **Text Colors:** Proper contrast ratios for accessibility

### **Component Design**
- **Cards:** Elevated with rounded corners and shadows
- **Buttons:** Large, touchable targets with clear feedback
- **Icons:** Material Design 2 icons with proper sizing
- **Typography:** Consistent font sizes and weights
- **Animations:** Staggered list animations, smooth transitions

### **Accessibility**
- Proper text contrast
- Large touch targets
- Clear button labels
- Loading indicators
- Error messages

---

## 🔐 Security Features

### **Authentication Security**
- Firebase Authentication handles password security
- Secure password reset via email
- Session management with logout
- User authentication state verification

### **Data Security**
- SQLite database for local sensitive data
- Firestore security rules (to be configured)
- No sensitive data in logs
- Proper error handling without exposing details

---

## 📈 Performance Optimizations

### **Database Operations**
- Async/await for non-blocking database calls
- Efficient SQLite queries with proper indexing
- Lazy loading of data
- Minimal data transfers

### **UI Rendering**
- Provider for efficient widget rebuilding
- Consumer widgets to rebuild only affected parts
- Const constructors where possible
- SingleChildScrollView for overflow prevention

### **Memory Management**
- Proper resource cleanup
- No memory leaks from streams or listeners
- Disposed ViewModels properly

---

## 📦 Dependencies Overview

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | Latest | UI framework |
| provider | 6.1.5+1 | State management |
| firebase_core | Latest | Firebase initialization |
| firebase_auth | Latest | Authentication |
| cloud_firestore | Latest | Cloud database |
| google_mlkit_text_recognition | 0.15.0 | OCR engine |
| image_picker | 1.1.2 | Camera/gallery access |
| sqflite | 2.3.3+1 | SQLite database |
| intl | 0.19.0 | Date/time formatting |

---

## 🎓 Learning Outcomes

### **Flutter Development**
- MVVM architecture in Flutter
- Provider pattern for state management
- Firebase integration (Auth, Firestore)
- SQLite database operations
- Camera and permission handling
- OCR/ML Kit integration
- Navigation and routing
- Responsive UI design

### **Best Practices Applied**
- Separation of concerns
- Async/await patterns
- Error handling
- User feedback (dialogs, snackbars)
- Code organization and structure
- Null safety in Dart
- Widget composition and reusability

---

## 🐛 Known Limitations & Future Enhancements

### **Current Limitations**
- Notification scheduling not yet implemented
- No push notifications
- Delete account feature placeholder only
- Profile picture upload not implemented
- Prescription image storage not in cloud

### **Future Enhancements**
- Push notifications for medication reminders
- Local notifications with alarm sounds
- Prescription history with image storage
- Medication interaction checking
- Refill reminders
- Export medication history to PDF
- Multi-language support
- Dark mode support
- Biometric authentication
- Medicine barcode scanning
- Integration with pharmacy APIs

---

## 📞 Support & Contact

For issues or questions regarding MediRemind development, please refer to the Flutter and Firebase documentation.

---

## 📄 License

This project is developed as a Final Year Project (FYP).

---

## 🎉 Summary

**MediRemind** is a fully-functional medicine reminder application with:
- ✅ Complete authentication system
- ✅ Medicine database management
- ✅ OCR-based prescription scanning
- ✅ Interactive reminder calendar
- ✅ Patient profile management
- ✅ Modern, responsive UI
- ✅ All major bugs fixed
- ✅ Proper error handling
- ✅ SQLite + Firebase integration

**Development Status:** COMPLETE ✅

All core features are implemented, tested, and working properly. The application is ready for further enhancement with additional features like notifications, analytics, and advanced filtering.

---

**Last Updated:** January 19, 2026
**Version:** 1.0.0
