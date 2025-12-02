import 'package:flutter/material.dart';
import '../models/timer_style.dart';

/// Сервис для генерации CSS стилей OBS оверлея таймера.
class StyleGeneratorService {
  /// Converts a Flutter Color to a CSS hex string.
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Converts a Flutter Color to a CSS rgba string.
  static String colorToRgba(Color color) {
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${(color.alpha / 255).toStringAsFixed(2)})';
  }

  /// Gets Google Fonts import URL for the font family.
  static String getFontImportUrl(String fontFamily) {
    // Map font names to Google Fonts URL format
    final fontName = fontFamily.replaceAll(' ', '+');
    return "https://fonts.googleapis.com/css2?family=$fontName:wght@400;700&display=swap";
  }

  /// Generates CSS for the timer based on the provided style.
  static String generateCSS(TimerStyle style) {
    final buffer = StringBuffer();

    // Google Fonts import
    buffer.writeln("@import url('${getFontImportUrl(style.fontFamily)}');");
    buffer.writeln();

    // Body styles for OBS (transparent background)
    buffer.writeln('body {');
    buffer.writeln('  margin: 0;');
    buffer.writeln('  padding: 0;');
    buffer.writeln('  background-color: transparent;');
    buffer.writeln('}');
    buffer.writeln();

    // Timer container (outer wrapper)
    buffer.writeln('#timer-container {');
    buffer.writeln('  display: flex;');
    buffer.writeln('  justify-content: center;');
    buffer.writeln('  align-items: center;');
    buffer.writeln('  width: ${style.width.toInt()}px;');
    buffer.writeln('  height: ${style.height.toInt()}px;');
    buffer.writeln('  padding: ${style.paddingTop.toInt()}px ${style.paddingRight.toInt()}px ${style.paddingBottom.toInt()}px ${style.paddingLeft.toInt()}px;');
    buffer.writeln('  box-sizing: border-box;');
    buffer.writeln('  margin: ${style.marginTop.toInt()}px ${style.marginRight.toInt()}px ${style.marginBottom.toInt()}px ${style.marginLeft.toInt()}px;');

    // Background
    if (style.showBackground) {
      buffer.writeln('  background-color: ${colorToHex(style.backgroundColor)};');
    } else {
      buffer.writeln('  background-color: transparent;');
    }

    // Border
    if (style.showBorder) {
      buffer.writeln('  border: ${style.borderWidth.toInt()}px solid ${colorToHex(style.borderColor)};');
      buffer.writeln('  border-radius: ${style.borderRadius.toInt()}px;');
    }

    buffer.writeln('}');
    buffer.writeln();

    // Timer text (inner element with font styles and animation)
    buffer.writeln('#timer {');
    buffer.writeln('  display: flex;');
    buffer.writeln('  justify-content: center;');
    buffer.writeln('  align-items: center;');
    buffer.writeln('  font-family: "${style.fontFamily}", monospace;');
    buffer.writeln('  font-size: ${style.fontSize.toInt()}px;');
    buffer.writeln('  color: ${colorToHex(style.textColor)};');
    buffer.writeln('  font-weight: bold;');
    buffer.writeln('  letter-spacing: ${style.letterSpacing.toInt()}px;');

    // Text shadow
    if (style.showTextShadow) {
      buffer.writeln('  text-shadow: ${style.textShadowOffsetX.toInt()}px ${style.textShadowOffsetY.toInt()}px ${style.textShadowBlur.toInt()}px ${colorToHex(style.textShadowColor)};');
    }

    // Animation on text
    if (style.animationType != 'none') {
      buffer.writeln('  animation: ${style.animationType} ${style.animationDuration.toStringAsFixed(1)}s ${style.animationTimingFunction} infinite;');
    }

    buffer.writeln('}');
    buffer.writeln();

    // Hours color
    buffer.writeln('#hours {');
    if (style.hoursColor != null) {
      buffer.writeln('  color: ${colorToHex(style.hoursColor!)};');
    }
    buffer.writeln('}');
    buffer.writeln();

    // Minutes color
    buffer.writeln('#minutes {');
    if (style.minutesColor != null) {
      buffer.writeln('  color: ${colorToHex(style.minutesColor!)};');
    }
    buffer.writeln('}');
    buffer.writeln();

    // Seconds color
    buffer.writeln('#seconds {');
    if (style.secondsColor != null) {
      buffer.writeln('  color: ${colorToHex(style.secondsColor!)};');
    }
    buffer.writeln('}');
    buffer.writeln();

    // Separator styles
    buffer.writeln('.separator {');
    if (style.separatorColor != null) {
      buffer.writeln('  color: ${colorToHex(style.separatorColor!)};');
    }
    if (style.separatorAnimation != 'none') {
      buffer.writeln('  animation: ${style.separatorAnimation} ${style.separatorAnimationDuration.toStringAsFixed(1)}s ${style.animationTimingFunction} infinite;');
    }
    buffer.writeln('}');

    // Animation keyframes
    final animations = <String>{};
    if (style.animationType != 'none') {
      animations.add(style.animationType);
    }
    if (style.separatorAnimation != 'none') {
      animations.add(style.separatorAnimation);
    }
    
    for (final anim in animations) {
      buffer.writeln();
      buffer.writeln(_getAnimationKeyframes(anim));
    }

    return buffer.toString();
  }

  /// Generates a complete HTML page with the timer and custom CSS.
  static String generateHTMLPreview(TimerStyle style, {String timerValue = '00:00:00'}) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background-color: transparent;
    }
${generateCSS(style).split('\n').map((line) => '    $line').join('\n')}
  </style>
</head>
<body>
  <div class="timer-container">
    <span class="timer-text">$timerValue</span>
  </div>
</body>
</html>
''';
  }

  /// List of available Google Fonts for the timer.
  static const List<String> availableFonts = [
    'Roboto Mono',
    'Press Start 2P',
    'VT323',
    'Share Tech Mono',
    'Orbitron',
    'Digital-7',
    'Segment7',
    'DSEG7 Classic',
    'Courier New',
    'Consolas',
    'Source Code Pro',
    'Fira Code',
    'JetBrains Mono',
    'IBM Plex Mono',
    'Space Mono',
  ];

  /// Preset styles for quick selection.
  static List<TimerStyle> get presetStyles => [
        const TimerStyle(
          name: 'Default',
          fontSize: 72,
          textColor: Colors.white,
          backgroundColor: Colors.black,
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Colors.black,
          textShadowOffsetX: 2,
          textShadowOffsetY: 2,
          textShadowBlur: 4,
          fontFamily: 'Roboto Mono',
        ),
        const TimerStyle(
          name: 'Neon Blue',
          fontSize: 72,
          textColor: Color(0xFF00FFFF),
          backgroundColor: Color(0xFF0A0A0A),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFF00FFFF),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 20,
          fontFamily: 'Orbitron',
        ),
        const TimerStyle(
          name: 'Neon Pink',
          fontSize: 72,
          textColor: Color(0xFFFF00FF),
          backgroundColor: Color(0xFF0A0A0A),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFFFF00FF),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 20,
          fontFamily: 'Orbitron',
        ),
        const TimerStyle(
          name: 'Retro Green',
          fontSize: 64,
          textColor: Color(0xFF00FF00),
          backgroundColor: Color(0xFF001100),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFF00FF00),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 10,
          fontFamily: 'VT323',
        ),
        const TimerStyle(
          name: '8-bit',
          fontSize: 48,
          textColor: Colors.white,
          backgroundColor: Color(0xFF2C2C54),
          showBackground: true,
          showTextShadow: false,
          showBorder: true,
          borderWidth: 4,
          borderRadius: 0,
          borderColor: Colors.white,
          fontFamily: 'Press Start 2P',
        ),
        const TimerStyle(
          name: 'Minimal',
          fontSize: 72,
          textColor: Colors.white,
          showBackground: false,
          showTextShadow: true,
          textShadowColor: Colors.black,
          textShadowOffsetX: 2,
          textShadowOffsetY: 2,
          textShadowBlur: 4,
          fontFamily: 'Roboto Mono',
        ),
        const TimerStyle(
          name: 'Fire',
          fontSize: 72,
          textColor: Color(0xFFFF6B00),
          backgroundColor: Color(0xFF1A0000),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFFFF0000),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 15,
          fontFamily: 'Orbitron',
        ),
        const TimerStyle(
          name: 'Ice',
          fontSize: 72,
          textColor: Color(0xFFADD8E6),
          backgroundColor: Color(0xFF001020),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFF87CEEB),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 15,
          fontFamily: 'Share Tech Mono',
        ),
        // Cyberpunk - желтый на темном с розовым свечением
        const TimerStyle(
          name: 'Cyberpunk',
          fontSize: 68,
          textColor: Color(0xFFFCEE0A),
          backgroundColor: Color(0xFF0D0221),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFFFF2A6D),
          textShadowOffsetX: 3,
          textShadowOffsetY: 3,
          textShadowBlur: 15,
          showBorder: true,
          borderWidth: 2,
          borderRadius: 0,
          borderColor: Color(0xFFFF2A6D),
          fontFamily: 'Orbitron',
          separatorColor: Color(0xFFFF2A6D),
          separatorAnimation: 'blink',
          separatorAnimationDuration: 1.0,
        ),
        // Oldschool - зеленый терминал
        const TimerStyle(
          name: 'Oldschool',
          fontSize: 64,
          textColor: Color(0xFF33FF33),
          backgroundColor: Color(0xFF0A0A0A),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFF33FF33),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 8,
          showBorder: true,
          borderWidth: 3,
          borderRadius: 8,
          borderColor: Color(0xFF33FF33),
          fontFamily: 'VT323',
          letterSpacing: 4,
        ),
        // Minecraft - пиксельный стиль
        const TimerStyle(
          name: 'Minecraft',
          fontSize: 48,
          textColor: Color(0xFFFFFFFF),
          backgroundColor: Color(0xFF3C3C3C),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFF3F3F3F),
          textShadowOffsetX: 4,
          textShadowOffsetY: 4,
          textShadowBlur: 0,
          showBorder: true,
          borderWidth: 4,
          borderRadius: 0,
          borderColor: Color(0xFF000000),
          fontFamily: 'Press Start 2P',
          letterSpacing: 2,
        ),
        // Kawaii - милый розовый
        const TimerStyle(
          name: 'Kawaii',
          fontSize: 64,
          textColor: Color(0xFFFFFFFF),
          backgroundColor: Color(0xFFFF69B4),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFFFF1493),
          textShadowOffsetX: 2,
          textShadowOffsetY: 2,
          textShadowBlur: 6,
          showBorder: true,
          borderWidth: 4,
          borderRadius: 20,
          borderColor: Color(0xFFFFFFFF),
          fontFamily: 'Press Start 2P',
          separatorColor: Color(0xFFFFE4E1),
          animationType: 'pulse',
          animationDuration: 2.0,
        ),
        // Synthwave - ретро 80-х
        const TimerStyle(
          name: 'Synthwave',
          fontSize: 72,
          textColor: Color(0xFFFF6EC7),
          backgroundColor: Color(0xFF1A1A2E),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFF00D9FF),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 25,
          showBorder: true,
          borderWidth: 2,
          borderRadius: 4,
          borderColor: Color(0xFF00D9FF),
          fontFamily: 'Orbitron',
          hoursColor: Color(0xFFFF6EC7),
          minutesColor: Color(0xFFFF6EC7),
          secondsColor: Color(0xFFFF6EC7),
          separatorColor: Color(0xFF00D9FF),
          animationType: 'glow',
          animationDuration: 3.0,
        ),
        // Matrix - падающий код
        const TimerStyle(
          name: 'Matrix',
          fontSize: 72,
          textColor: Color(0xFF00FF41),
          backgroundColor: Color(0xFF000000),
          showBackground: true,
          showTextShadow: true,
          textShadowColor: Color(0xFF00FF41),
          textShadowOffsetX: 0,
          textShadowOffsetY: 0,
          textShadowBlur: 20,
          fontFamily: 'Share Tech Mono',
          letterSpacing: 6,
          separatorAnimation: 'fade',
          separatorAnimationDuration: 0.8,
          animationType: 'colorShift',
          animationDuration: 4.0,
        ),
      ];

  /// Gets CSS keyframes for the specified animation type.
  static String _getAnimationKeyframes(String animationType) {
    switch (animationType) {
      case 'pulse':
        return '''@keyframes pulse {
  0%, 100% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.05); opacity: 0.9; }
}''';
      case 'glow':
        return '''@keyframes glow {
  0%, 100% { filter: brightness(1); }
  50% { filter: brightness(1.3); }
}''';
      case 'bounce':
        return '''@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}''';
      case 'shake':
        return '''@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}''';
      case 'fade':
        return '''@keyframes fade {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}''';
      case 'rotate':
        return '''@keyframes rotate {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}''';
      case 'colorShift':
        return '''@keyframes colorShift {
  0%, 100% { filter: hue-rotate(0deg); }
  50% { filter: hue-rotate(30deg); }
}''';
      default:
        return '';
    }
  }

  /// List of available animations.
  static const List<String> availableAnimations = [
    'none',
    'pulse',
    'glow',
    'bounce',
    'shake',
    'fade',
    'colorShift',
  ];

  /// List of separator animations.
  static const List<String> separatorAnimations = [
    'none',
    'blink',
    'fade',
    'pulse',
  ];

  /// List of animation timing functions.
  static const List<String> animationTimingFunctions = [
    'ease',
    'ease-in',
    'ease-out',
    'ease-in-out',
    'linear',
  ];

  /// Gets CSS keyframes for separator animations.
  static String _getSeparatorAnimationKeyframes(String animationType) {
    switch (animationType) {
      case 'blink':
        return '''@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}''';
      case 'fade':
        return '''@keyframes fade {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}''';
      case 'pulse':
        return '''@keyframes pulse {
  0%, 100% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.2); opacity: 0.8; }
}''';
      default:
        return '';
    }
  }
}
