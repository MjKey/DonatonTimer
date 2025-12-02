import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

import '../models/timer_style.dart';
import '../providers/localization_provider.dart';
import '../services/style_generator_service.dart';

/// Экран генератора CSS стилей для OBS оверлея таймера.
class StyleGeneratorScreen extends StatefulWidget {
  const StyleGeneratorScreen({super.key});

  @override
  State<StyleGeneratorScreen> createState() => _StyleGeneratorScreenState();
}

class _StyleGeneratorScreenState extends State<StyleGeneratorScreen> {
  TimerStyle _currentStyle = TimerStyle.defaultStyle;
  int _selectedPresetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(localization),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel - Settings
                  Expanded(
                    flex: 3,
                    child: _buildSettingsPanel(localization),
                  ),
                  const SizedBox(width: 16),

                  // Right panel - Preview & CSS
                  Expanded(
                    flex: 2,
                    child: _buildPreviewPanel(localization),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LocalizationProvider localization) {
    return Row(
      children: [
        NesButton.icon(
          type: NesButtonType.normal,
          icon: NesIcons.leftArrowIndicator,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 16),
        Text(
          localization.tr('css_generator'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }


  Widget _buildSettingsPanel(LocalizationProvider localization) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Presets
          _buildPresetsSection(localization),
          const SizedBox(height: 16),

          // Font settings
          _buildFontSection(localization),
          const SizedBox(height: 16),

          // Size settings
          _buildSizeSection(localization),
          const SizedBox(height: 16),

          // Background settings
          _buildBackgroundSection(localization),
          const SizedBox(height: 16),

          // Text shadow settings
          _buildTextShadowSection(localization),
          const SizedBox(height: 16),

          // Border settings
          _buildBorderSection(localization),
          const SizedBox(height: 16),

          // Padding/Margin settings
          _buildPaddingSection(localization),
          const SizedBox(height: 16),

          // Animation settings
          _buildAnimationSection(localization),
        ],
      ),
    );
  }

  Widget _buildPaddingSection(LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('spacing'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inner padding (container)
            Text(localization.tr('inner_padding'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _buildCompactSlider('↑', _currentStyle.paddingTop, 50, (v) => _currentStyle.copyWith(paddingTop: v))),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider('↓', _currentStyle.paddingBottom, 50, (v) => _currentStyle.copyWith(paddingBottom: v))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildCompactSlider('←', _currentStyle.paddingLeft, 50, (v) => _currentStyle.copyWith(paddingLeft: v))),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider('→', _currentStyle.paddingRight, 50, (v) => _currentStyle.copyWith(paddingRight: v))),
              ],
            ),
            const SizedBox(height: 8),
            // Outer margin (page position)
            Text(localization.tr('outer_margin'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _buildCompactSlider('↑', _currentStyle.marginTop, 200, (v) => _currentStyle.copyWith(marginTop: v))),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider('↓', _currentStyle.marginBottom, 200, (v) => _currentStyle.copyWith(marginBottom: v))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildCompactSlider('←', _currentStyle.marginLeft, 200, (v) => _currentStyle.copyWith(marginLeft: v))),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider('→', _currentStyle.marginRight, 200, (v) => _currentStyle.copyWith(marginRight: v))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSlider(String label, double value, double max, TimerStyle Function(double) updater) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: max,
            divisions: max.toInt(),
            onChanged: (v) {
              setState(() {
                _currentStyle = updater(v);
                _selectedPresetIndex = -1;
              });
            },
          ),
        ),
        SizedBox(width: 28, child: Text('${value.toInt()}', style: const TextStyle(fontSize: 11))),
      ],
    );
  }

  Widget _buildAnimationSection(LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('animation'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text animation type dropdown
            Text('${localization.tr('text_animation')}:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _currentStyle.animationType,
              isExpanded: true,
              items: StyleGeneratorService.availableAnimations.map((anim) {
                return DropdownMenuItem(
                  value: anim,
                  child: Text(anim == 'none' ? localization.tr('none') : anim),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(animationType: value);
                    _selectedPresetIndex = -1;
                  });
                }
              },
            ),

            if (_currentStyle.animationType != 'none') ...[
              const SizedBox(height: 16),

              // Animation duration
              Text('${localization.tr('animation_duration')}: ${_currentStyle.animationDuration.toStringAsFixed(1)}s'),
              Slider(
                value: _currentStyle.animationDuration,
                min: 0.5,
                max: 5.0,
                divisions: 18,
                onChanged: (value) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(animationDuration: value);
                    _selectedPresetIndex = -1;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Timing function dropdown
              Text('${localization.tr('animation_timing')}:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _currentStyle.animationTimingFunction,
                isExpanded: true,
                items: StyleGeneratorService.animationTimingFunctions.map((func) {
                  return DropdownMenuItem(
                    value: func,
                    child: Text(func),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentStyle = _currentStyle.copyWith(animationTimingFunction: value);
                      _selectedPresetIndex = -1;
                    });
                  }
                },
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Separator animation
            Text('${localization.tr('separator_animation')}:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _currentStyle.separatorAnimation,
              isExpanded: true,
              items: StyleGeneratorService.separatorAnimations.map((anim) {
                return DropdownMenuItem(
                  value: anim,
                  child: Text(anim == 'none' ? localization.tr('none') : anim),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(separatorAnimation: value);
                    _selectedPresetIndex = -1;
                  });
                }
              },
            ),

            if (_currentStyle.separatorAnimation != 'none') ...[
              const SizedBox(height: 16),
              Text('${localization.tr('separator_animation_duration')}: ${_currentStyle.separatorAnimationDuration.toStringAsFixed(1)}s'),
              Slider(
                value: _currentStyle.separatorAnimationDuration,
                min: 0.5,
                max: 3.0,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(separatorAnimationDuration: value);
                    _selectedPresetIndex = -1;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection(LocalizationProvider localization) {
    final presets = StyleGeneratorService.presetStyles;

    return NesContainer(
      label: localization.tr('timer_styles'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(presets.length, (index) {
            final preset = presets[index];
            final isSelected = _selectedPresetIndex == index;

            return NesButton.text(
              type: isSelected ? NesButtonType.primary : NesButtonType.normal,
              text: preset.name,
              onPressed: () {
                setState(() {
                  _selectedPresetIndex = index;
                  _currentStyle = preset;
                });
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFontSection(LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('font_family'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font family dropdown
            DropdownButton<String>(
              value: _currentStyle.fontFamily,
              isExpanded: true,
              items: StyleGeneratorService.availableFonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(font),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(fontFamily: value);
                    _selectedPresetIndex = -1;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Font size slider
            Text('${localization.tr('font_size')}: ${_currentStyle.fontSize.toInt()}px'),
            Slider(
              value: _currentStyle.fontSize,
              min: 24,
              max: 200,
              divisions: 176,
              onChanged: (value) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(fontSize: value);
                  _selectedPresetIndex = -1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Letter spacing slider
            Text('${localization.tr('letter_spacing')}: ${_currentStyle.letterSpacing.toInt()}px'),
            Slider(
              value: _currentStyle.letterSpacing,
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(letterSpacing: value);
                  _selectedPresetIndex = -1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Text color (base)
            _buildColorRow(
              localization.tr('text_color'),
              _currentStyle.textColor,
              (color) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(textColor: color);
                  _selectedPresetIndex = -1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Hours color
            _buildColorRow(
              localization.tr('hours_color'),
              _currentStyle.hoursColor ?? _currentStyle.textColor,
              (color) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(hoursColor: color);
                  _selectedPresetIndex = -1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Minutes color
            _buildColorRow(
              localization.tr('minutes_color'),
              _currentStyle.minutesColor ?? _currentStyle.textColor,
              (color) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(minutesColor: color);
                  _selectedPresetIndex = -1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Seconds color
            _buildColorRow(
              localization.tr('seconds_color'),
              _currentStyle.secondsColor ?? _currentStyle.textColor,
              (color) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(secondsColor: color);
                  _selectedPresetIndex = -1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Separator color
            _buildColorRow(
              localization.tr('separator_color'),
              _currentStyle.separatorColor ?? _currentStyle.textColor,
              (color) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(separatorColor: color);
                  _selectedPresetIndex = -1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSection(LocalizationProvider localization) {
    return NesContainer(
      label: '${localization.tr('width')} / ${localization.tr('height')}',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Width slider
            Text('${localization.tr('width')}: ${_currentStyle.width.toInt()}px'),
            Slider(
              value: _currentStyle.width,
              min: 200,
              max: 800,
              divisions: 60,
              onChanged: (value) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(width: value);
                  _selectedPresetIndex = -1;
                });
              },
            ),
            const SizedBox(height: 8),

            // Height slider
            Text('${localization.tr('height')}: ${_currentStyle.height.toInt()}px'),
            Slider(
              value: _currentStyle.height,
              min: 50,
              max: 300,
              divisions: 50,
              onChanged: (value) {
                setState(() {
                  _currentStyle = _currentStyle.copyWith(height: value);
                  _selectedPresetIndex = -1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBackgroundSection(LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('background'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show background checkbox
            Row(
              children: [
                NesCheckBox(
                  value: _currentStyle.showBackground,
                  onChange: (value) {
                    setState(() {
                      _currentStyle = _currentStyle.copyWith(showBackground: value);
                      _selectedPresetIndex = -1;
                    });
                  },
                ),
                const SizedBox(width: 12),
                Text(localization.tr('background')),
              ],
            ),
            if (_currentStyle.showBackground) ...[
              const SizedBox(height: 12),
              _buildColorRow(
                localization.tr('background_color'),
                _currentStyle.backgroundColor,
                (color) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(backgroundColor: color);
                    _selectedPresetIndex = -1;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextShadowSection(LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('text_shadow'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show text shadow checkbox
            Row(
              children: [
                NesCheckBox(
                  value: _currentStyle.showTextShadow,
                  onChange: (value) {
                    setState(() {
                      _currentStyle = _currentStyle.copyWith(showTextShadow: value);
                      _selectedPresetIndex = -1;
                    });
                  },
                ),
                const SizedBox(width: 12),
                Text(localization.tr('text_shadow')),
              ],
            ),
            if (_currentStyle.showTextShadow) ...[
              const SizedBox(height: 12),
              _buildColorRow(
                localization.tr('shadow_color'),
                _currentStyle.textShadowColor,
                (color) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(textShadowColor: color);
                    _selectedPresetIndex = -1;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Shadow offset X
              Text('${localization.tr('shadow_offset_x')}: ${_currentStyle.textShadowOffsetX.toInt()}px'),
              Slider(
                value: _currentStyle.textShadowOffsetX,
                min: -20,
                max: 20,
                divisions: 40,
                onChanged: (value) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(textShadowOffsetX: value);
                    _selectedPresetIndex = -1;
                  });
                },
              ),

              // Shadow offset Y
              Text('${localization.tr('shadow_offset_y')}: ${_currentStyle.textShadowOffsetY.toInt()}px'),
              Slider(
                value: _currentStyle.textShadowOffsetY,
                min: -20,
                max: 20,
                divisions: 40,
                onChanged: (value) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(textShadowOffsetY: value);
                    _selectedPresetIndex = -1;
                  });
                },
              ),

              // Shadow blur
              Text('Blur: ${_currentStyle.textShadowBlur.toInt()}px'),
              Slider(
                value: _currentStyle.textShadowBlur,
                min: 0,
                max: 50,
                divisions: 50,
                onChanged: (value) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(textShadowBlur: value);
                    _selectedPresetIndex = -1;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBorderSection(LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('border'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show border checkbox
            Row(
              children: [
                NesCheckBox(
                  value: _currentStyle.showBorder,
                  onChange: (value) {
                    setState(() {
                      _currentStyle = _currentStyle.copyWith(showBorder: value);
                      _selectedPresetIndex = -1;
                    });
                  },
                ),
                const SizedBox(width: 12),
                Text(localization.tr('border')),
              ],
            ),
            if (_currentStyle.showBorder) ...[
              const SizedBox(height: 12),
              _buildColorRow(
                localization.tr('border_color'),
                _currentStyle.borderColor,
                (color) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(borderColor: color);
                    _selectedPresetIndex = -1;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Border width
              Text('${localization.tr('border_width')}: ${_currentStyle.borderWidth.toInt()}px'),
              Slider(
                value: _currentStyle.borderWidth,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(borderWidth: value);
                    _selectedPresetIndex = -1;
                  });
                },
              ),

              // Border radius
              Text('${localization.tr('border_radius')}: ${_currentStyle.borderRadius.toInt()}px'),
              Slider(
                value: _currentStyle.borderRadius,
                min: 0,
                max: 50,
                divisions: 50,
                onChanged: (value) {
                  setState(() {
                    _currentStyle = _currentStyle.copyWith(borderRadius: value);
                    _selectedPresetIndex = -1;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildPreviewPanel(LocalizationProvider localization) {
    final css = StyleGeneratorService.generateCSS(_currentStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview
        NesContainer(
          label: 'Preview',
          child: Container(
            height: 200,
            color: Colors.grey[900],
            child: Center(
              child: _buildTimerPreview(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // CSS output
        Expanded(
          child: NesContainer(
            label: 'CSS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      css,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: NesButton.text(
                    type: NesButtonType.success,
                    text: localization.tr('copy_css'),
                    onPressed: () => _copyCSS(css, localization),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerPreview() {
    final hoursColor = _currentStyle.hoursColor ?? _currentStyle.textColor;
    final minutesColor = _currentStyle.minutesColor ?? _currentStyle.textColor;
    final secondsColor = _currentStyle.secondsColor ?? _currentStyle.textColor;
    final separatorColor = _currentStyle.separatorColor ?? _currentStyle.textColor;

    final baseStyle = TextStyle(
      fontSize: _currentStyle.fontSize,
      color: _currentStyle.textColor,
      fontWeight: FontWeight.bold,
      letterSpacing: _currentStyle.letterSpacing,
      shadows: _currentStyle.showTextShadow
          ? [
              Shadow(
                color: _currentStyle.textShadowColor,
                offset: Offset(
                  _currentStyle.textShadowOffsetX,
                  _currentStyle.textShadowOffsetY,
                ),
                blurRadius: _currentStyle.textShadowBlur,
              ),
            ]
          : null,
    );
    
    final textStyle = _getGoogleFontStyle(_currentStyle.fontFamily, baseStyle);

    return ClipRRect(
      borderRadius: _currentStyle.showBorder
          ? BorderRadius.circular(_currentStyle.borderRadius)
          : BorderRadius.zero,
      child: Container(
        width: _currentStyle.width,
        height: _currentStyle.height,
        padding: EdgeInsets.only(
          top: _currentStyle.paddingTop,
          bottom: _currentStyle.paddingBottom,
          left: _currentStyle.paddingLeft,
          right: _currentStyle.paddingRight,
        ),
        decoration: BoxDecoration(
          color: _currentStyle.showBackground
              ? _currentStyle.backgroundColor
              : Colors.transparent,
          border: _currentStyle.showBorder
              ? Border.all(
                  color: _currentStyle.borderColor,
                  width: _currentStyle.borderWidth,
                )
              : null,
          borderRadius: _currentStyle.showBorder
              ? BorderRadius.circular(_currentStyle.borderRadius)
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('00', style: textStyle.copyWith(color: hoursColor)),
              Text(':', style: textStyle.copyWith(color: separatorColor)),
              Text('00', style: textStyle.copyWith(color: minutesColor)),
              Text(':', style: textStyle.copyWith(color: separatorColor)),
              Text('00', style: textStyle.copyWith(color: secondsColor)),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets TextStyle with Google Font applied
  TextStyle _getGoogleFontStyle(String fontFamily, TextStyle baseStyle) {
    try {
      switch (fontFamily) {
        case 'Roboto Mono':
          return GoogleFonts.robotoMono(textStyle: baseStyle);
        case 'Press Start 2P':
          return GoogleFonts.pressStart2p(textStyle: baseStyle);
        case 'VT323':
          return GoogleFonts.vt323(textStyle: baseStyle);
        case 'Share Tech Mono':
          return GoogleFonts.shareTechMono(textStyle: baseStyle);
        case 'Orbitron':
          return GoogleFonts.orbitron(textStyle: baseStyle);
        case 'Source Code Pro':
          return GoogleFonts.sourceCodePro(textStyle: baseStyle);
        case 'Fira Code':
          return GoogleFonts.firaCode(textStyle: baseStyle);
        case 'JetBrains Mono':
          return GoogleFonts.jetBrainsMono(textStyle: baseStyle);
        case 'IBM Plex Mono':
          return GoogleFonts.ibmPlexMono(textStyle: baseStyle);
        case 'Space Mono':
          return GoogleFonts.spaceMono(textStyle: baseStyle);
        case 'Courier New':
        case 'Consolas':
        default:
          return baseStyle.copyWith(fontFamily: fontFamily);
      }
    } catch (e) {
      return baseStyle.copyWith(fontFamily: fontFamily);
    }
  }

  Widget _buildColorRow(String label, Color color, ValueChanged<Color> onChanged) {
    return Row(
      children: [
        Text('$label: '),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showColorPicker(color, onChanged),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          StyleGeneratorService.colorToHex(color),
          style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
        ),
      ],
    );
  }

  void _showColorPicker(Color currentColor, ValueChanged<Color> onChanged) {
    showDialog(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColor: currentColor,
        onColorSelected: onChanged,
      ),
    );
  }

  void _copyCSS(String css, LocalizationProvider localization) {
    Clipboard.setData(ClipboardData(text: css));
    NesSnackbar.show(
      context,
      text: localization.tr('css_copied'),
      type: NesSnackbarType.success,
    );
  }
}

/// Диалог выбора цвета.
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _red;
  late double _green;
  late double _blue;

  @override
  void initState() {
    super.initState();
    _red = widget.initialColor.red.toDouble();
    _green = widget.initialColor.green.toDouble();
    _blue = widget.initialColor.blue.toDouble();
  }

  Color get _currentColor => Color.fromARGB(255, _red.toInt(), _green.toInt(), _blue.toInt());

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();

    return Dialog(
      child: NesContainer(
        label: localization.tr('pick_color'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color preview
              Container(
                width: 100,
                height: 60,
                decoration: BoxDecoration(
                  color: _currentColor,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                StyleGeneratorService.colorToHex(_currentColor),
                style: const TextStyle(fontFamily: 'Consolas'),
              ),
              const SizedBox(height: 16),

              // Red slider
              _buildColorSlider('R', _red, Colors.red, (v) => setState(() => _red = v)),
              _buildColorSlider('G', _green, Colors.green, (v) => setState(() => _green = v)),
              _buildColorSlider('B', _blue, Colors.blue, (v) => setState(() => _blue = v)),

              const SizedBox(height: 16),

              // Preset colors
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetColor(Colors.white),
                  _buildPresetColor(Colors.black),
                  _buildPresetColor(Colors.red),
                  _buildPresetColor(Colors.green),
                  _buildPresetColor(Colors.blue),
                  _buildPresetColor(Colors.yellow),
                  _buildPresetColor(Colors.cyan),
                  _buildPresetColor(Colors.pink),
                  _buildPresetColor(Colors.orange),
                  _buildPresetColor(Colors.purple),
                ],
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NesButton.text(
                    type: NesButtonType.normal,
                    text: localization.tr('cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  NesButton.text(
                    type: NesButtonType.primary,
                    text: localization.tr('select'),
                    onPressed: () {
                      widget.onColorSelected(_currentColor);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(value.toInt().toString()),
        ),
      ],
    );
  }

  Widget _buildPresetColor(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _red = color.red.toDouble();
          _green = color.green.toDouble();
          _blue = color.blue.toDouble();
        });
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
