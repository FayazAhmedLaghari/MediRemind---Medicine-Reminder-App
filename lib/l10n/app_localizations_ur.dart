// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';
// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'MediRemind';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get login => 'لاگ ان';

  @override
  String get email => 'اپنا ای میل درج کریں';

  @override
  String get password => 'اپنا پاسورڈ درج کریں';

  @override
  String get forgotPassword => 'پاسورڈ بھول گئے؟';

  @override
  String get createAccount => 'اکاؤنٹ بنائیں';

  @override
  String get dashboardTitle => 'مریض ڈیش بورڈ';

  @override
  String get myMedicines => 'میری دوائیں';

  @override
  String get scanPrescription => 'نسخہ اسکین کریں';

  @override
  String get reminders => 'یاد دہانیاں';

  @override
  String get profile => 'پروفائل';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get confirmLogout => 'لاگ آؤٹ کی تصدیق';

  @override
  String get logoutConfirmation => 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get delete => 'خارج کریں';

  @override
  String get addReminder => 'یاد دہانی شامل کریں';

  @override
  String get medicineName => 'دوا کا نام';

  @override
  String get dosage => 'خوراک';

  @override
  String get frequency => 'تعدد';

  @override
  String get time => 'وقت';

  @override
  String get notes => 'نوٹس';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get edit => 'ترمیم کریں';

  @override
  String get deleteMedicine => 'دوا حذف کریں؟';

  @override
  String deleteConfirmation(Object medicineName) {
    return 'کیا آپ واقعی $medicineName کو حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get darkMode => 'ڈارک موڈ';

  @override
  String get lightMode => 'لائٹ موڈ';

  @override
  String get medicineInteraction => 'ممکنہ تعامل دوسری دوا کے ساتھ';

  @override
  String get refillReminder => 'ری فل یاددہانی: مقدار چیک کریں';

  @override
  String get noMedicines => 'کوئی دوائیں نہیں';

  @override
  String get addFirstMedicine => 'شروع کرنے کے لیے اپنی پہلی دوا شامل کریں';

  @override
  String get noReminders => 'اس دن کے لیے کوئی یاددہانی نہیں';

  @override
  String get markDone => 'مکمل نشان کریں';

  @override
  String get calendar => 'کلینڈر';

  @override
  String get today => 'آج';

  @override
  String get todaysMedicines => 'آج کی دوائیں';

  @override
  String get personalNotes => 'ذاتی نوٹس';

  @override
  String get doctorInstructions => 'ڈاکٹر کی ہدایات';

  @override
  String get noNotes => 'کوئی نوٹس نہیں';

  @override
  String get saveNotes => 'نوٹس محفوظ کریں';

  @override
  String get language => 'زبان';

  @override
  String get selectLanguage => 'زبان منتخب کریں';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get sindhi => 'سنڌي';

  @override
  String get medicineAdded => 'دوا کامیابی سے شامل ہو گئی';

  @override
  String get reminderAdded => 'یاد دہانی کامیابی سے شامل ہو گئی';

  @override
  String get markedCompleted => 'مکمل کے طور پر نشان لگا دیا گیا';

  @override
  String get medicineDeleted => 'دوا حذف ہو گئی';

  @override
  String get loggedOut => 'کامیابی کے ساتھ لاگ آؤٹ ہوگیا';

  @override
  String get loginFailed => 'لاگ ان ناکام';

  @override
  String get register => 'رجسٹر';

  @override
  String get name => 'نام';

  @override
  String get age => 'عمر';

  @override
  String get gender => 'صنف';

  @override
  String get medicalHistory => 'طبی تاریخ';

  @override
  String get repeatPassword => 'پاسورڈ دوبارہ درج کریں';

  @override
  String get alreadyHaveAccount => 'کیا آپ کا پہلے سے اکاؤنٹ ہے؟';

  @override
  String get signIn => 'سائن ان';

  @override
  String get signUp => 'سائن اپ';

  @override
  String get selectMedicine => 'دوا منتخب کریں';

  @override
  String get reminderTime => 'یاد دہانی کا وقت';

  @override
  String get selectTime => 'وقت منتخب کریں';

  @override
  String get medicineInteractionsTitle => 'دوا کے تعاملات';

  @override
  String get refillRemindersTitle => 'ری فل یاد دہانیاں';

  @override
  String interactionsFound(Object count) {
    return 'تعلقات ملے: $count';
  }

  @override
  String refillsNeeded(Object count) {
    return 'درکار ری فل: $count';
  }
}
