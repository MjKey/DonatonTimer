import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Shared controls keep behavior identical while changing the app's visual style.
class AppButton extends StatelessWidget {
  const AppButton.text({
    super.key,
    required this.type,
    required this.text,
    this.onPressed,
  }) : icon = null;

  const AppButton.icon({
    super.key,
    required this.type,
    required this.icon,
    this.onPressed,
  }) : text = null;

  final NesButtonType type;
  final String? text;
  final NesIconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<ThemeProvider>().isClassic) {
      return icon != null
          ? NesButton.icon(type: type, icon: icon!, onPressed: onPressed)
          : NesButton.text(type: type, text: text!, onPressed: onPressed);
    }
    if (icon != null) {
      return IconButton(icon: Icon(_materialIcon(icon!)), onPressed: onPressed);
    }
    final scheme = Theme.of(context).colorScheme;
    if (type != NesButtonType.primary && type != NesButtonType.success) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: type == NesButtonType.error
              ? scheme.error
              : scheme.onSurfaceVariant,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Text(text!),
      );
    }
    return FilledButton.tonal(onPressed: onPressed, child: Text(text!));
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({super.key, this.label, required this.child});

  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<ThemeProvider>().isClassic) {
      return NesContainer(label: label, child: child);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  label!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            if (constraints.hasBoundedHeight) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

class AppCheckBox extends StatelessWidget {
  const AppCheckBox({super.key, required this.value, this.onChange});

  final bool value;
  final ValueChanged<bool>? onChange;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<ThemeProvider>().isClassic) {
      return NesCheckBox(value: value, onChange: onChange);
    }
    return Checkbox(
      value: value,
      onChanged: onChange == null ? null : (value) => onChange!(value!),
    );
  }
}

class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.iconData, this.size});

  final NesIconData iconData;
  final Size? size;

  @override
  Widget build(BuildContext context) {
    return context.watch<ThemeProvider>().isClassic
        ? Icon(_materialIcon(iconData), size: size?.width)
        : NesIcon(iconData: iconData, size: size);
  }
}

IconData _materialIcon(NesIconData icon) => {
  NesIcons.camera: Icons.qr_code,
  NesIcons.check: Icons.check,
  NesIcons.edit: Icons.palette_outlined,
  NesIcons.exclamationMarkBlock: Icons.warning_amber_rounded,
  NesIcons.gamepad: Icons.info_outline,
  NesIcons.leftArrowIndicator: Icons.arrow_back,
  NesIcons.moon: Icons.dark_mode_outlined,
  NesIcons.questionMark: Icons.info_outline,
  NesIcons.rename: Icons.language,
  NesIcons.sun: Icons.light_mode_outlined,
  NesIcons.tv: Icons.live_tv,
  NesIcons.wrench: Icons.settings_outlined,
}[icon]!;

class AppSelectionList extends StatelessWidget {
  const AppSelectionList({
    super.key,
    required this.onSelect,
    required this.children,
  });

  final ValueChanged<int> onSelect;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<ThemeProvider>().isClassic) {
      return NesSelectionList(onSelect: onSelect, children: children);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          ListTile(title: children[i], onTap: () => onSelect(i)),
      ],
    );
  }
}

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String text,
    NesSnackbarType type = NesSnackbarType.normal,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Builder(
          builder: (context) {
            if (!context.watch<ThemeProvider>().isClassic) {
              return NesSnackbar(text: text, type: type);
            }
            final scheme = Theme.of(context).colorScheme;
            final isError = type == NesSnackbarType.error;
            return Material(
              color: isError ? scheme.error : scheme.inverseSurface,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isError ? scheme.onError : scheme.onInverseSurface,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppConfirmDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) {
    if (!context.read<ThemeProvider>().isClassic) {
      return NesConfirmDialog.show(
        context: context,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      );
    }
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
