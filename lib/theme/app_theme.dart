import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

import '../models/app_ui_style.dart';

/// Builds either the v3 pixel theme or the standard Material theme used in v2.
ThemeData buildAppTheme(AppUiStyle style, Brightness brightness) {
  if (style == AppUiStyle.classic) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff6b7280),
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );
    return ThemeData(
      colorScheme: scheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
  return flutterNesTheme(
    brightness: brightness,
    nesTheme: const NesTheme(pixelSize: 4),
    primaryColor: brightness == Brightness.light
        ? const Color(0xffb4b6f6)
        : const Color(0xff8b8dca),
  );
}
