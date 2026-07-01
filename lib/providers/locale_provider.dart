import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  
  // Method to set locale during initialization
  void setInitialLocale(Locale locale) {
    _locale = locale;
  }

  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  LocaleProvider() {
    // Don't load locale here - it will be set via setInitialLocale
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'ar';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  // Static method to load locale synchronously for initialization
  static Future<Locale> loadInitialLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'ar';
    return Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final newLocale = _locale.languageCode == 'ar' 
        ? const Locale('en') 
        : const Locale('ar');
    await setLocale(newLocale);
  }
}


