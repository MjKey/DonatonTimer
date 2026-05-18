import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppContainer extends StatelessWidget {
  final Widget child;
  final String? label;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppContainer({
    super.key,
    required this.child,
    this.label,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isPixel = themeProvider.isPixelStyle;

    if (isPixel) {
      return NesContainer(
        width: width,
        height: height,
        label: label,
        padding: padding is EdgeInsets ? padding as EdgeInsets : null,
        backgroundColor: backgroundColor,
        child: child,
      );
    } else {
      return Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            Flexible(child: child),
          ],
        ),
      );
    }
  }
}
