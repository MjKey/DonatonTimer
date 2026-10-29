import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_ui_style.dart';

/// Провайдер для управления темой приложения (светлая/тёмная).
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _styleKey = 'app_ui_style';

  ThemeMode _themeMode = ThemeMode.system;
  AppUiStyle _uiStyle = AppUiStyle.retro;
  SharedPreferences? _prefs;

  /// Current theme mode.
  ThemeMode get themeMode => _themeMode;

  AppUiStyle get uiStyle => _uiStyle;
  bool get isClassic => _uiStyle == AppUiStyle.classic;

  /// Whether dark mode is currently active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Whether light mode is currently active.
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Whether system theme is being used.
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Initializes the provider by loading saved theme preference.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = _themeModeFromString(savedTheme);
    }
    _uiStyle = _prefs?.getString(_styleKey) == AppUiStyle.classic.name
        ? AppUiStyle.classic
        : AppUiStyle.retro;
    notifyListeners();
  }

  /// Changes only the app's presentation, preserving the active theme and data.
  Future<void> setUiStyle(AppUiStyle style) async {
    if (_uiStyle == style) return;
    _uiStyle = style;
    await _prefs?.setString(_styleKey, style.name);
    notifyListeners();
  }

  /// Sets the theme mode and saves to persistent storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _prefs?.setString(_themeKey, _themeModeToString(mode));
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
}
