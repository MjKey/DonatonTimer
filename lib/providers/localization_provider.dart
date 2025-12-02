import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Провайдер для управления локализацией приложения.
class LocalizationProvider extends ChangeNotifier {
  static const String _defaultLanguage = 'ru';
  static const List<String> supportedLanguages = ['ru', 'en'];
  
  static LocalizationProvider? _instance;

  String _currentLanguage = _defaultLanguage;
  Map<String, String> _localizedStrings = {};
  bool _isLoaded = false;

  String get currentLanguage => _currentLanguage;
  bool get isLoaded => _isLoaded;

  /// Gets the locale for the current language.
  Locale get locale => Locale(_currentLanguage);

  /// Initializes the provider with the specified language.
  Future<void> init([String? language]) async {
    _instance = this;
    await setLanguage(language ?? _defaultLanguage);
  }

  /// Sets the current language and loads the corresponding strings.
  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) {
      languageCode = _defaultLanguage;
    }

    try {
      final jsonString = await rootBundle.loadString('lang/$languageCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      _localizedStrings = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      _currentLanguage = languageCode;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading language file: $e');
      // Try to load default language if current fails
      if (languageCode != _defaultLanguage) {
        await setLanguage(_defaultLanguage);
      }
    }
  }

  /// Gets a localized string by key.
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// Shorthand for translate.
  String tr(String key) => translate(key);

  /// Gets the language name for display.
  String getLanguageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  /// Toggles between supported languages.
  Future<void> toggleLanguage() async {
    final currentIndex = supportedLanguages.indexOf(_currentLanguage);
    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    await setLanguage(supportedLanguages[nextIndex]);
  }

  /// Gets the singleton instance.
  static LocalizationProvider? get instance => _instance;
}
