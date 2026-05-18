import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Style of the application interface.
enum AppStyle { pixel, material }

/// Провайдер для управления темой приложения (светлая/тёмная) и стилем (Pixel/Material).
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _styleKey = 'app_style';
  
  ThemeMode _themeMode = ThemeMode.system;
  AppStyle _appStyle = AppStyle.pixel;
  SharedPreferences? _prefs;
  
  /// Current theme mode.
  ThemeMode get themeMode => _themeMode;
  
  /// Current app style.
  AppStyle get appStyle => _appStyle;
  
  /// Whether dark mode is currently active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Whether light mode is currently active.
  bool get isLightMode => _themeMode == ThemeMode.light;
  
  /// Whether system theme is being used.
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  /// Whether pixel style is being used.
  bool get isPixelStyle => _appStyle == AppStyle.pixel;
  
  /// Whether material style is being used.
  bool get isMaterialStyle => _appStyle == AppStyle.material;
  
  /// Initializes the provider by loading saved theme preference.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    final savedTheme = _prefs?.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = _themeModeFromString(savedTheme);
    }
    
    final savedStyle = _prefs?.getString(_styleKey);
    if (savedStyle != null) {
      _appStyle = _appStyleFromString(savedStyle);
    }
    
    if (savedTheme != null || savedStyle != null) {
      notifyListeners();
    }
  }
  
  /// Sets the theme mode and saves to persistent storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _prefs?.setString(_themeKey, _themeModeToString(mode));
    notifyListeners();
  }
  
  /// Sets the app style and saves to persistent storage.
  Future<void> setAppStyle(AppStyle style) async {
    if (_appStyle == style) return;
    
    _appStyle = style;
    await _prefs?.setString(_styleKey, _appStyleToString(style));
    notifyListeners();
  }
  
  /// Toggles between light and dark themes.
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }
  
  /// Cycles through all theme modes: system -> light -> dark -> system.
  Future<void> cycleThemeMode() async {
    ThemeMode newMode;
    switch (_themeMode) {
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
    }
    await setThemeMode(newMode);
  }
  
  /// Gets the display name for the current theme mode.
  String getThemeModeName() {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
  
  /// Converts ThemeMode to string for storage.
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }
  
  /// Converts string to ThemeMode.
  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  /// Converts AppStyle to string for storage.
  String _appStyleToString(AppStyle style) {
    switch (style) {
      case AppStyle.pixel:
        return 'pixel';
      case AppStyle.material:
        return 'material';
    }
  }
  
  /// Converts string to AppStyle.
  AppStyle _appStyleFromString(String value) {
    switch (value) {
      case 'material':
        return AppStyle.material;
      case 'pixel':
      default:
        return AppStyle.pixel;
    }
  }
}
