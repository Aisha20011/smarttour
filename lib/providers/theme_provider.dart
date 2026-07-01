import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  // Method to set theme during initialization
  void setInitialTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;
    
    _isDarkMode = isDark;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Static method to load theme synchronously for initialization
  static Future<bool> loadInitialTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('dark_mode') ?? false;
    } catch (e) {
      return false;
    }
  }
}

