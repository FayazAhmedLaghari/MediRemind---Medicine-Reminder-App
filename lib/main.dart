import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'Views/login_view.dart';
import 'core/theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'firebase_options.dart';
import 'viewmodels/medicine_viewmodel.dart';
import 'viewmodels/ocr_viewmodel.dart';
import 'viewmodels/reminder_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/language_viewmodel.dart';
import 'service/notification_service.dart';
// 🔥 IMPORTANT
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  // Reschedule all pending reminders
  await notificationService.rescheduleAllReminders();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => MedicineViewModel()),
        ChangeNotifierProvider(create: (_) => OCRViewModel()),
        ChangeNotifierProvider(create: (_) => ReminderViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'MediRemind',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVM.themeMode,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [
              Locale('en', 'US'), // English
              Locale('es', 'ES'), // Spanish
              Locale('fr', 'FR'), // French
              Locale('de', 'DE'), // German
              Locale('hi', 'IN'), // Hindi
            ],
            locale: Provider.of<LanguageViewModel>(context).selectedLocale,
            home: LoginView(),
          );
        },
      ),
    );
  }
}
