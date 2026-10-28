@Tags(['unit'])
library;

import 'package:donaton_timer/models/app_ui_style.dart';
import 'package:donaton_timer/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'existing installations keep the retro UI and their color theme',
    () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final provider = ThemeProvider();
      addTearDown(provider.dispose);
      await provider.init();

      expect(provider.uiStyle, AppUiStyle.retro);
      expect(provider.themeMode, ThemeMode.dark);
    },
  );

  test(
    'restores the selected UI style after restarting the provider',
    () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      addTearDown(provider.dispose);
      await provider.init();
      await provider.setThemeMode(ThemeMode.light);
      await provider.setUiStyle(AppUiStyle.classic);

      final restarted = ThemeProvider();
      addTearDown(restarted.dispose);
      await restarted.init();
      expect(restarted.isClassic, isTrue);
      expect(restarted.themeMode, ThemeMode.light);

      await restarted.setThemeMode(ThemeMode.dark);
      expect(restarted.isClassic, isTrue);
      await restarted.setUiStyle(AppUiStyle.retro);
      expect(restarted.themeMode, ThemeMode.dark);

      final restartedAgain = ThemeProvider();
      addTearDown(restartedAgain.dispose);
      await restartedAgain.init();
      expect(restartedAgain.uiStyle, AppUiStyle.retro);
      expect(restartedAgain.themeMode, ThemeMode.dark);
    },
  );

  test('falls back to retro for unknown saved styles', () async {
    SharedPreferences.setMockInitialValues({'app_ui_style': 'unknown-style'});
    final provider = ThemeProvider();
    addTearDown(provider.dispose);
    await provider.init();

    expect(provider.uiStyle, AppUiStyle.retro);
    expect(provider.themeMode, ThemeMode.system);
  });
}
