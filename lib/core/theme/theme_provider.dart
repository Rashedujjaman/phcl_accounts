import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider to manage app theme state
/// 
/// Supports:
/// - System theme (default)
/// - Light theme
/// - Dark theme
/// - Persisting theme preference
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  /// Initialize theme from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeKey);
    
    if (themeModeIndex != null) {
      _themeMode = ThemeMode.values[themeModeIndex];
      notifyListeners();
    }
  }
  
  /// Toggle between light and dark theme
  /// If currently system, it will switch to the opposite of current system theme
  Future<void> toggleTheme(BuildContext context) async {
    final brightness = MediaQuery.of(context).platformBrightness;
    
    switch (_themeMode) {
      case ThemeMode.system:
        // If system is dark, switch to light; if light, switch to dark
        _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
    }
    
    await _saveThemeMode();
    notifyListeners();
  }
  
  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }
  
  /// Reset to system theme
  Future<void> resetToSystemTheme() async {
    _themeMode = ThemeMode.system;
    await _saveThemeMode();
    notifyListeners();
  }
  
  /// Check if current theme is dark based on context
  bool isDarkMode(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
    }
  }
  
  /// Get theme status text for UI
  String getThemeStatusText(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.system:
        final systemBrightness = MediaQuery.of(context).platformBrightness;
        return 'System (${systemBrightness == Brightness.dark ? 'Dark' : 'Light'})';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
  
  /// Save theme mode to shared preferences
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
  }
}
