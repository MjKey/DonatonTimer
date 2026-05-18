import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

enum AppSnackbarType { normal, success, error, warning }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String text,
    AppSnackbarType type = AppSnackbarType.normal,
  }) {
    final themeProvider = context.read<ThemeProvider>();
    final isPixel = themeProvider.isPixelStyle;

    if (isPixel) {
      NesSnackbarType nesType;
      switch (type) {
        case AppSnackbarType.success:
          nesType = NesSnackbarType.success;
          break;
        case AppSnackbarType.error:
          nesType = NesSnackbarType.error;
          break;
        case AppSnackbarType.warning:
          nesType = NesSnackbarType.warning;
          break;
        case AppSnackbarType.normal:
        default:
          nesType = NesSnackbarType.normal;
          break;
      }
      NesSnackbar.show(context, text: text, type: nesType);
    } else {
      Color backgroundColor;
      switch (type) {
        case AppSnackbarType.success:
          backgroundColor = Colors.green;
          break;
        case AppSnackbarType.error:
          backgroundColor = Theme.of(context).colorScheme.error;
          break;
        case AppSnackbarType.warning:
          backgroundColor = Colors.orange;
          break;
        case AppSnackbarType.normal:
        default:
          backgroundColor = Theme.of(context).snackBarTheme.backgroundColor ?? Colors.grey[800]!;
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
