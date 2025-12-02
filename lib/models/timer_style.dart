import 'package:flutter/material.dart';

/// Представляет стиль таймера (пресет или кастомный).
class TimerStyle {
  final String name;
  final String? previewImage;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final bool showBackground;
  final bool showTextShadow;
  final Color textShadowColor;
  final double textShadowOffsetX;
  final double textShadowOffsetY;
  final double textShadowBlur;
  final bool showBorder;
  final double borderWidth;
  final double borderRadius;
  final Color borderColor;
  final String fontFamily;
  final double width;
  final double height;
  // Inner padding (container)
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  // Outer margin (page position)
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final String animationType;
  final double animationDuration;
  final String animationTimingFunction;
  final double letterSpacing;
  final Color? hoursColor;
  final Color? minutesColor;
  final Color? secondsColor;
  final Color? separatorColor;
  final String separatorAnimation;
  final double separatorAnimationDuration;

  const TimerStyle({
    required this.name,
    this.previewImage,
    this.fontSize = 72,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.showBackground = true,
    this.showTextShadow = true,
    this.textShadowColor = Colors.black,
    this.textShadowOffsetX = 2,
    this.textShadowOffsetY = 2,
    this.textShadowBlur = 4,
    this.showBorder = false,
    this.borderWidth = 2,
    this.borderRadius = 8,
    this.borderColor = Colors.white,
    this.fontFamily = 'Roboto Mono',
    this.width = 400,
    this.height = 100,
    this.paddingTop = 10,
    this.paddingBottom = 10,
    this.paddingLeft = 20,
    this.paddingRight = 20,
    this.marginTop = 0,
    this.marginBottom = 0,
    this.marginLeft = 0,
    this.marginRight = 0,
    this.animationType = 'none',
    this.animationDuration = 2.0,
    this.animationTimingFunction = 'ease-in-out',
    this.letterSpacing = 2,
    this.hoursColor,
    this.minutesColor,
    this.secondsColor,
    this.separatorColor,
    this.separatorAnimation = 'none',
    this.separatorAnimationDuration = 1.0,
  });

  /// Creates a copy with updated values.
  TimerStyle copyWith({
    String? name,
    String? previewImage,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    bool? showBackground,
    bool? showTextShadow,
    Color? textShadowColor,
    double? textShadowOffsetX,
    double? textShadowOffsetY,
    double? textShadowBlur,
    bool? showBorder,
    double? borderWidth,
    double? borderRadius,
    Color? borderColor,
    String? fontFamily,
    double? width,
    double? height,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    String? animationType,
    double? animationDuration,
    String? animationTimingFunction,
    double? letterSpacing,
    Color? hoursColor,
    Color? minutesColor,
    Color? secondsColor,
    Color? separatorColor,
    String? separatorAnimation,
    double? separatorAnimationDuration,
  }) {
    return TimerStyle(
      name: name ?? this.name,
      previewImage: previewImage ?? this.previewImage,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showBackground: showBackground ?? this.showBackground,
      showTextShadow: showTextShadow ?? this.showTextShadow,
      textShadowColor: textShadowColor ?? this.textShadowColor,
      textShadowOffsetX: textShadowOffsetX ?? this.textShadowOffsetX,
      textShadowOffsetY: textShadowOffsetY ?? this.textShadowOffsetY,
      textShadowBlur: textShadowBlur ?? this.textShadowBlur,
      showBorder: showBorder ?? this.showBorder,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      fontFamily: fontFamily ?? this.fontFamily,
      width: width ?? this.width,
      height: height ?? this.height,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      animationType: animationType ?? this.animationType,
      animationDuration: animationDuration ?? this.animationDuration,
      animationTimingFunction: animationTimingFunction ?? this.animationTimingFunction,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      hoursColor: hoursColor ?? this.hoursColor,
      minutesColor: minutesColor ?? this.minutesColor,
      secondsColor: secondsColor ?? this.secondsColor,
      separatorColor: separatorColor ?? this.separatorColor,
      separatorAnimation: separatorAnimation ?? this.separatorAnimation,
      separatorAnimationDuration: separatorAnimationDuration ?? this.separatorAnimationDuration,
    );
  }

  /// Creates a TimerStyle from a JSON map.
  factory TimerStyle.fromJson(Map<String, dynamic> json) {
    return TimerStyle(
      name: json['name'] as String,
      previewImage: json['previewImage'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 72,
      textColor: _colorFromHex(json['textColor'] as String? ?? '#FFFFFF'),
      backgroundColor: _colorFromHex(json['backgroundColor'] as String? ?? '#000000'),
      showBackground: json['showBackground'] as bool? ?? true,
      showTextShadow: json['showTextShadow'] as bool? ?? true,
      textShadowColor: _colorFromHex(json['textShadowColor'] as String? ?? '#000000'),
      textShadowOffsetX: (json['textShadowOffsetX'] as num?)?.toDouble() ?? 2,
      textShadowOffsetY: (json['textShadowOffsetY'] as num?)?.toDouble() ?? 2,
      textShadowBlur: (json['textShadowBlur'] as num?)?.toDouble() ?? 4,
      showBorder: json['showBorder'] as bool? ?? false,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 2,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 8,
      borderColor: _colorFromHex(json['borderColor'] as String? ?? '#FFFFFF'),
      fontFamily: json['fontFamily'] as String? ?? 'Roboto Mono',
      width: (json['width'] as num?)?.toDouble() ?? 400,
      height: (json['height'] as num?)?.toDouble() ?? 100,
      paddingTop: (json['paddingTop'] as num?)?.toDouble() ?? 10,
      paddingBottom: (json['paddingBottom'] as num?)?.toDouble() ?? 10,
      paddingLeft: (json['paddingLeft'] as num?)?.toDouble() ?? 20,
      paddingRight: (json['paddingRight'] as num?)?.toDouble() ?? 20,
      marginTop: (json['marginTop'] as num?)?.toDouble() ?? 0,
      marginBottom: (json['marginBottom'] as num?)?.toDouble() ?? 0,
      marginLeft: (json['marginLeft'] as num?)?.toDouble() ?? 0,
      marginRight: (json['marginRight'] as num?)?.toDouble() ?? 0,
      animationType: json['animationType'] as String? ?? 'none',
      animationDuration: (json['animationDuration'] as num?)?.toDouble() ?? 2.0,
      animationTimingFunction: json['animationTimingFunction'] as String? ?? 'ease-in-out',
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 2,
      hoursColor: json['hoursColor'] != null ? _colorFromHex(json['hoursColor'] as String) : null,
      minutesColor: json['minutesColor'] != null ? _colorFromHex(json['minutesColor'] as String) : null,
      secondsColor: json['secondsColor'] != null ? _colorFromHex(json['secondsColor'] as String) : null,
      separatorColor: json['separatorColor'] != null ? _colorFromHex(json['separatorColor'] as String) : null,
      separatorAnimation: json['separatorAnimation'] as String? ?? 'none',
      separatorAnimationDuration: (json['separatorAnimationDuration'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Converts the TimerStyle to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'previewImage': previewImage,
      'fontSize': fontSize,
      'textColor': _colorToHex(textColor),
      'backgroundColor': _colorToHex(backgroundColor),
      'showBackground': showBackground,
      'showTextShadow': showTextShadow,
      'textShadowColor': _colorToHex(textShadowColor),
      'textShadowOffsetX': textShadowOffsetX,
      'textShadowOffsetY': textShadowOffsetY,
      'textShadowBlur': textShadowBlur,
      'showBorder': showBorder,
      'borderWidth': borderWidth,
      'borderRadius': borderRadius,
      'borderColor': _colorToHex(borderColor),
      'fontFamily': fontFamily,
      'width': width,
      'height': height,
      'paddingTop': paddingTop,
      'paddingBottom': paddingBottom,
      'paddingLeft': paddingLeft,
      'paddingRight': paddingRight,
      'marginTop': marginTop,
      'marginBottom': marginBottom,
      'marginLeft': marginLeft,
      'marginRight': marginRight,
      'animationType': animationType,
      'animationDuration': animationDuration,
      'animationTimingFunction': animationTimingFunction,
      'letterSpacing': letterSpacing,
      'hoursColor': hoursColor != null ? _colorToHex(hoursColor!) : null,
      'minutesColor': minutesColor != null ? _colorToHex(minutesColor!) : null,
      'secondsColor': secondsColor != null ? _colorToHex(secondsColor!) : null,
      'separatorColor': separatorColor != null ? _colorToHex(separatorColor!) : null,
      'separatorAnimation': separatorAnimation,
      'separatorAnimationDuration': separatorAnimationDuration,
    };
  }

  static Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Default style preset.
  static const TimerStyle defaultStyle = TimerStyle(name: 'Default');

  @override
  String toString() => 'TimerStyle(name: $name)';
}
