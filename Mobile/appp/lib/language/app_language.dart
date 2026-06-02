import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  french,
  arabic,
}

class AppLanguageController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;

  Locale get locale {
    switch (_language) {
      case AppLanguage.english:
        return const Locale("en");
      case AppLanguage.french:
        return const Locale("fr");
      case AppLanguage.arabic:
        return const Locale("ar");
    }
  }

  TextDirection get textDirection {
    return _language == AppLanguage.arabic
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  String get languageCode {
    switch (_language) {
      case AppLanguage.english:
        return "EN";
      case AppLanguage.french:
        return "FR";
      case AppLanguage.arabic:
        return "AR";
    }
  }

  void changeLanguage(AppLanguage newLanguage) {
    _language = newLanguage;
    notifyListeners();
  }
}

final appLanguageController = AppLanguageController();