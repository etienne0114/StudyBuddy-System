import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_scheduler/constants/app_constants.dart';

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  /// Initialize theme mode from shared preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(AppConstants.prefDarkMode) ?? false;
      
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      print('Error initializing theme mode: $e');
    }
  }
  
  /// Toggle between light and dark mode
  Future<void> toggleThemeMode() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    
    notifyListeners();
    
    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        AppConstants.prefDarkMode,
        _themeMode == ThemeMode.dark,
      );
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        AppConstants.prefDarkMode,
        _themeMode == ThemeMode.dark,
      );
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  /// Check if dark mode is enabled
  bool get isDarkMode => _themeMode == ThemeMode.dark;
}