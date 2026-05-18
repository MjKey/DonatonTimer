import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

enum AppButtonType { normal, primary, success, warning, error }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final NesIconData? icon;

  const AppButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.type = AppButtonType.normal,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isPixel = themeProvider.isPixelStyle;

    if (isPixel) {
      final nesType = _mapToNesType(type);
      if (icon != null) {
        return NesButton.icon(
          type: nesType,
          icon: icon!,
          onPressed: onPressed,
        );
      }
      return NesButton.text(
        type: nesType,
        text: text,
        onPressed: onPressed,
      );
    } else {
      final color = _getMaterialColor(context, type);
      final child = icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapNesIconToMaterial(icon!),
                if (text.isNotEmpty) const SizedBox(width: 8),
                if (text.isNotEmpty) Text(text),
              ],
            )
          : Text(text);

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color != null ? Colors.white : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: onPressed,
        child: child,
      );
    }
  }

  NesButtonType _mapToNesType(AppButtonType appType) {
    switch (appType) {
      case AppButtonType.primary:
        return NesButtonType.primary;
      case AppButtonType.success:
        return NesButtonType.success;
      case AppButtonType.warning:
        return NesButtonType.warning;
      case AppButtonType.error:
        return NesButtonType.error;
      case AppButtonType.normal:
      default:
        return NesButtonType.normal;
    }
  }

  Color? _getMaterialColor(BuildContext context, AppButtonType appType) {
    switch (appType) {
      case AppButtonType.primary:
        return Theme.of(context).colorScheme.primary;
      case AppButtonType.success:
        return Colors.green;
      case AppButtonType.warning:
        return Colors.orange;
      case AppButtonType.error:
        return Theme.of(context).colorScheme.error;
      case AppButtonType.normal:
      default:
        return null; // default button color
    }
  }

  Widget _mapNesIconToMaterial(NesIconData icon) {
    IconData materialIcon = Icons.star;
    if (icon == NesIcons.leftArrowIndicator) {
      materialIcon = Icons.arrow_back;
    } else if (icon == NesIcons.rightArrowIndicator) {
      materialIcon = Icons.arrow_forward;
    } else if (icon == NesIcons.add) {
      materialIcon = Icons.add;
    } else if (icon == NesIcons.remove) {
      materialIcon = Icons.remove;
    } else if (icon == NesIcons.check) {
      materialIcon = Icons.check;
    } else if (icon == NesIcons.exclamationMarkBlock) {
      materialIcon = Icons.error_outline;
    }
    // Add more mappings as needed
    return Icon(materialIcon);
  }
}
