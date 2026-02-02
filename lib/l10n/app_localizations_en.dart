// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';
// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MediRemind';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get login => 'Log In';

  @override
  String get email => 'Enter your Email';

  @override
  String get password => 'Enter your Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get dashboardTitle => 'Patient Dashboard';

  @override
  String get myMedicines => 'My Medicines';

  @override
  String get scanPrescription => 'Scan Prescription';

  @override
  String get reminders => 'Reminders';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get medicineName => 'Medicine Name';

  @override
  String get dosage => 'Dosage';

  @override
  String get frequency => 'Frequency';

  @override
  String get time => 'Time';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get deleteMedicine => 'Delete Medicine?';

  @override
  String deleteConfirmation(Object medicineName) {
    return 'Are you sure you want to delete $medicineName?';
  }

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get medicineInteraction =>
      'Potential interaction with another medicine';

  @override
  String get refillReminder => 'Refill reminder: Check supply level';

  @override
  String get noMedicines => 'No Medicines Yet';

  @override
  String get addFirstMedicine => 'Add your first medicine to get started';

  @override
  String get noReminders => 'No reminders for this day';

  @override
  String get markDone => 'Mark Done';

  @override
  String get calendar => 'Calendar';

  @override
  String get today => 'Today';

  @override
  String get todaysMedicines => "Today's Medicines";

  @override
  String get personalNotes => 'Personal Notes';

  @override
  String get doctorInstructions => 'Doctor Instructions';

  @override
  String get noNotes => 'No notes yet';

  @override
  String get saveNotes => 'Save Notes';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get sindhi => 'سنڌي';

  @override
  String get medicineAdded => 'Medicine added successfully';

  @override
  String get reminderAdded => 'Reminder added successfully';

  @override
  String get markedCompleted => 'Marked as completed';

  @override
  String get medicineDeleted => 'Medicine deleted';

  @override
  String get loggedOut => 'Logged out successfully';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get register => 'Register';

  @override
  String get name => 'Name';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get medicalHistory => 'Medical History';

  @override
  String get repeatPassword => 'Repeat Password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get selectMedicine => 'Select Medicine';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get selectTime => 'Select time';

  @override
  String get medicineInteractionsTitle => 'Medicine Interactions';

  @override
  String get refillRemindersTitle => 'Refill Reminders';

  @override
  String interactionsFound(Object count) {
    return 'Interactions found: $count';
  }

  @override
  String refillsNeeded(Object count) {
    return 'Refills needed: $count';
  }
}
