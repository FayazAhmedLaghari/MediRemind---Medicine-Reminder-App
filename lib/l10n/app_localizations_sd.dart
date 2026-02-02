// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';
// ignore_for_file: type=lint

/// The translations for Sindhi (`sd`).
class AppLocalizationsSd extends AppLocalizations {
  AppLocalizationsSd([String locale = 'sd']) : super(locale);

  @override
  String get appName => 'MediRemind';

  @override
  String get welcomeBack => 'ڀلي ڪري آيا';

  @override
  String get login => 'لاگ ان';

  @override
  String get email => 'پنھنجو اي ميل داخل ڪريو';

  @override
  String get password => 'پنھنجو پاسورڊ داخل ڪريو';

  @override
  String get forgotPassword => 'پاسورڊ وسري ويو؟';

  @override
  String get createAccount => 'اڪائونٽ ٺاهيو';

  @override
  String get dashboardTitle => 'مريض ڊيش بورڊ';

  @override
  String get myMedicines => 'منهنجون دوائون';

  @override
  String get scanPrescription => 'نسخو اسڪين ڪريو';

  @override
  String get reminders => 'ياد ڏياريندڙ';

  @override
  String get profile => 'پروفائل';

  @override
  String get logout => 'لاگ آئوٽ';

  @override
  String get confirmLogout => 'لاگ آئوٽ جي تصديق';

  @override
  String get logoutConfirmation => 'ڇا توھان واقعي لاگ آئوٽ ڪرڻ چاھيو ٿا؟';

  @override
  String get cancel => 'منسوخ';

  @override
  String get delete => 'حذف ڪريو';

  @override
  String get addReminder => 'ياد ڏياريندڙ شامل ڪريو';

  @override
  String get medicineName => 'دوائون جو نالو';

  @override
  String get dosage => 'ڊوز';

  @override
  String get frequency => 'تعدد';

  @override
  String get time => 'وقت';

  @override
  String get notes => 'نوٽس';

  @override
  String get save => 'محفوظ ڪريو';

  @override
  String get edit => 'ترميم';

  @override
  String get deleteMedicine => 'دوائون حذف ڪريو؟';

  @override
  String deleteConfirmation(Object medicineName) {
    return 'ڇا توھان واقعي $medicineName کي حذف ڪرڻ چاھيو ٿا؟';
  }

  @override
  String get darkMode => 'ڊارڪ موڊ';

  @override
  String get lightMode => 'لائيٽ موڊ';

  @override
  String get medicineInteraction => 'ٻي دوا سان ممڪن تعامل';

  @override
  String get refillReminder => 'ریفِل یاددهي: مقدار چيڪ ڪريو';

  @override
  String get noMedicines => 'ڪو به دوا ناهي';

  @override
  String get addFirstMedicine => 'شروع ڪرڻ لاءِ پهريون دوا شامل ڪريو';

  @override
  String get noReminders => 'هن ڏينهن لاءِ ڪو ياد ڏياريندڙ نه آهي';

  @override
  String get markDone => 'مڪمل طور نشان لڳايو';

  @override
  String get calendar => 'ڪلينڊر';

  @override
  String get today => 'اڄ';

  @override
  String get todaysMedicines => 'اڄ جون دوائون';

  @override
  String get personalNotes => 'ذاتي نوٽس';

  @override
  String get doctorInstructions => 'ڊاڪٽر جون هدايتون';

  @override
  String get noNotes => 'ڪو به نوٽس ناهي';

  @override
  String get saveNotes => 'نوٽس محفوظ ڪريو';

  @override
  String get language => 'ٻولي';

  @override
  String get selectLanguage => 'ٻولي چونڊيو';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get sindhi => 'سنڌي';

  @override
  String get medicineAdded => 'دوائون ڪاميابي سان شامل ڪيو ويو';

  @override
  String get reminderAdded => 'ياد ڏياريندڙ ڪاميابي سان شامل ڪيو ويو';

  @override
  String get markedCompleted => 'مڪمل طور نشان لڳايو ويو';

  @override
  String get medicineDeleted => 'دوائون حذف ٿي ويون';

  @override
  String get loggedOut => 'ڪاميابي سان لاگ آئوٽ ٿيو';

  @override
  String get loginFailed => 'لاگ ان ناڪام';

  @override
  String get register => 'رجسٽر';

  @override
  String get name => 'نالو';

  @override
  String get age => 'عمر';

  @override
  String get gender => 'صنف';

  @override
  String get medicalHistory => 'طبي تاريخ';

  @override
  String get repeatPassword => 'پاسورڊ ٻيھر داخل ڪريو';

  @override
  String get alreadyHaveAccount => 'ڇا توهان وٽ اڳ ۾ ئي اڪائونٽ آهي؟';

  @override
  String get signIn => 'سائن ان';

  @override
  String get signUp => 'سائن اپ';

  @override
  String get selectMedicine => 'دوائون چونڊيو';

  @override
  String get reminderTime => 'ياد ڏياريندڙ وقت';

  @override
  String get selectTime => 'وقت چونڊيو';

  @override
  String get medicineInteractionsTitle => 'دوائن جا تعامل';

  @override
  String get refillRemindersTitle => 'ری فل يادن';

  @override
  String interactionsFound(Object count) {
    return 'تعلقات مليا: $count';
  }

  @override
  String refillsNeeded(Object count) {
    return 'ري فل گهربل: $count';
  }
}
