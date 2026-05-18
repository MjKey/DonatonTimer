import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppCheckBox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChange;

  const AppCheckBox({
    super.key,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isPixel = themeProvider.isPixelStyle;

    if (isPixel) {
      return NesCheckBox(
        value: value,
        onChange: onChange != null ? (v) => onChange!(v ?? false) : null,
      );
    } else {
      return Checkbox(
        value: value,
        onChanged: onChange != null ? (v) => onChange!(v ?? false) : null,
      );
    }
  }
}
