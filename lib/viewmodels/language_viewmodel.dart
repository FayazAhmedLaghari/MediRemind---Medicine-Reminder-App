import 'package:flutter/material.dart';

class LanguageViewModel extends ChangeNotifier {
  Locale _selectedLocale = const Locale('en', 'US');

  Locale get selectedLocale => _selectedLocale;

  void changeLanguage(Locale locale) {
    _selectedLocale = locale;
    notifyListeners();
  }

  List<Locale> get supportedLocales => const [
        Locale('en', 'US'), // English
        Locale('es', 'ES'), // Spanish
        Locale('fr', 'FR'), // French
        Locale('ur', 'PK'), // Urdu
        Locale('sd', 'PK'), // Sindhi
      ];

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'ur':
        return 'اردو';
      case 'sd':
        return 'سنڌي';
      default:
        return 'English';
    }
  }
}
