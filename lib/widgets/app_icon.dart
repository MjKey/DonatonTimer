import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppIcon extends StatelessWidget {
  final NesIconData iconData;
  final Size? size;

  const AppIcon({
    super.key,
    required this.iconData,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isPixel = themeProvider.isPixelStyle;

    if (isPixel) {
      return NesIcon(iconData: iconData, size: size);
    } else {
      IconData materialIcon = Icons.star;
      
      // Map NesIconData to Material IconData
      if (iconData == NesIcons.leftArrowIndicator) {
        materialIcon = Icons.arrow_back;
      } else if (iconData == NesIcons.rightArrowIndicator) {
        materialIcon = Icons.arrow_forward;
      } else if (iconData == NesIcons.add) {
        materialIcon = Icons.add;
      } else if (iconData == NesIcons.remove) {
        materialIcon = Icons.remove;
      } else if (iconData == NesIcons.check) {
        materialIcon = Icons.check;
      } else if (iconData == NesIcons.exclamationMarkBlock) {
        materialIcon = Icons.error_outline;
      } else if (iconData == NesIcons.questionMark) {
        materialIcon = Icons.help_outline;
      } else if (iconData == NesIcons.close) {
        materialIcon = Icons.close;
      }

      final double iconSize = size?.width ?? 24.0;
      return Icon(materialIcon, size: iconSize);
    }
  }
}
