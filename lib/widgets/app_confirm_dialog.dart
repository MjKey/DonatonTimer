import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppConfirmDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    final themeProvider = context.read<ThemeProvider>();
    final isPixel = themeProvider.isPixelStyle;

    if (isPixel) {
      return NesConfirmDialog.show(
        context: context,
        message: message,
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel ?? 'Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel ?? 'ОК'),
            ),
          ],
        ),
      );
    }
  }
}
