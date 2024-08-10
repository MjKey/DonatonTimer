// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class StyleGeneratorScreen extends StatefulWidget {
  const StyleGeneratorScreen({super.key});

  @override
  _StyleGeneratorScreenState createState() => _StyleGeneratorScreenState();
}

class _StyleGeneratorScreenState extends State<StyleGeneratorScreen> {
  double _fontSize = 40;
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  Color _textShadowColor = Colors.black;
  double _textShadowOffsetX = 2.0;
  double _textShadowOffsetY = 2.0;
  double _borderRadius = 5.0;
  double _borderWidth = 1.0;
  Color _borderColor = Colors.black;
  String _fontFamily = 'Roboto';
  double _widthBlock = 190.0;
  double _heightBlock = 75.0;
  String _fontPath = '';

  bool _showBackground = true;
  bool _showTextShadow = true;
  bool _showBorder = true;

  TextStyle _buildTextStyle() {
    return GoogleFonts.getFont(
      _fontFamily,
      fontSize: _fontSize,
      color: _textColor,
      shadows: _showTextShadow
          ? [
              Shadow(
                offset: Offset(_textShadowOffsetX, _textShadowOffsetY),
                color: _textShadowColor,
              ),
            ]
          : [],
    );
  }

  String getCSS() {
    String fontFace = _fontPath.isNotEmpty
        ? '''
@font-face {
  font-family: 'CustomFont';
  src: url('file://${Uri.encodeComponent(_fontPath)}');
}
          '''
        : '''
@import url('https://fonts.googleapis.com/css2?family=${Uri.encodeComponent(_fontFamily)}&display=swap');
          ''';

    return '''
$fontFace

body {
  background-color: #fff0;
  margin: 0 auto;
  overflow: hidden;
  display: flex;
  justify-content: center;
  font-family: ${_fontPath.isNotEmpty ? 'CustomFont' : _fontFamily};
}
      
#timer {
  color: ${_colorToHex(_textColor)};
  font-size: ${_fontSize}px;
  ${_showBackground ? 'background-color: ${_colorToHex(_backgroundColor)};' : ''}
  ${_showTextShadow ? 'text-shadow: ${_textShadowOffsetX}px ${_textShadowOffsetY}px ${_colorToHex(_textShadowColor)};' : ''}
  ${_showBorder ? 'border-radius: ${_borderRadius}px;' : ''}
  ${_showBorder ? 'border: ${_borderWidth}px solid ${_colorToHex(_borderColor)};' : ''}
  width: ${_widthBlock}px;
  height: ${_heightBlock}px;
  display: flex;
  flex-wrap: nowrap;
  align-items: center;
  justify-content: center;
  font-family: ${_fontPath.isNotEmpty ? 'CustomFont' : _fontFamily};
}
    ''';
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _pickColor(Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              context.read<LocalizationProvider>().translate('pick_color')),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text(
                  context.read<LocalizationProvider>().translate('select')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _copyCSS() {
    Clipboard.setData(ClipboardData(text: getCSS()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              context.read<LocalizationProvider>().translate('css_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('css_generator_title')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Center(
                        child: Container(
                          width: _widthBlock,
                          height: _heightBlock,
                          decoration: BoxDecoration(
                            color: _showBackground
                                ? _backgroundColor
                                : Colors.transparent,
                            borderRadius: _showBorder
                                ? BorderRadius.circular(_borderRadius)
                                : null,
                            border: _showBorder
                                ? Border.all(
                                    color: _borderColor, width: _borderWidth)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '00:00:00',
                              style: _buildTextStyle(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildToggleRow(
                        loc.translate('background'), _showBackground, (val) {
                      setState(() {
                        _showBackground = val;
                      });
                    }),
                    _buildToggleRow(
                        loc.translate('text_shadow'), _showTextShadow, (val) {
                      setState(() {
                        _showTextShadow = val;
                      });
                    }),
                    _buildToggleRow(loc.translate('border'), _showBorder,
                        (val) {
                      setState(() {
                        _showBorder = val;
                      });
                    }),
                    const SizedBox(height: 20),
                    _buildSliderRow(
                        loc.translate('font_size'), _fontSize, 10, 100, (val) {
                      setState(() {
                        _fontSize = val;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildSliderRow(
                        loc.translate('width_block'), _widthBlock, 10, 800,
                        (val) {
                      setState(() {
                        _widthBlock = val;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildSliderRow(
                        loc.translate('height_block'), _heightBlock, 10, 800,
                        (val) {
                      setState(() {
                        _heightBlock = val;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildColorPickerRow(
                        loc.translate('text_color'), _textColor, (color) {
                      setState(() {
                        _textColor = color;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildFontPickerRow(
                        loc.translate('font_family'), _fontFamily, (font) {
                      setState(() {
                        if (font != null) {
                          _fontFamily = font;
                        }
                      });
                    }),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: loc.translate('custom_font'),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _fontPath = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_showBackground)
                      _buildColorPickerRow(
                          loc.translate('background_color'), _backgroundColor,
                          (color) {
                        setState(() {
                          _backgroundColor = color;
                        });
                      }),
                    const SizedBox(height: 10),
                    if (_showTextShadow) ...[
                      _buildColorPickerRow(
                          loc.translate('text_shadow_color'), _textShadowColor,
                          (color) {
                        setState(() {
                          _textShadowColor = color;
                        });
                      }),
                      const SizedBox(height: 10),
                      _buildSliderRow(loc.translate('text_shadow_offset_x'),
                          _textShadowOffsetX, -10, 10, (val) {
                        setState(() {
                          _textShadowOffsetX = val;
                        });
                      }),
                      const SizedBox(height: 10),
                      _buildSliderRow(loc.translate('text_shadow_offset_y'),
                          _textShadowOffsetY, -10, 10, (val) {
                        setState(() {
                          _textShadowOffsetY = val;
                        });
                      }),
                    ],
                    const SizedBox(height: 10),
                    if (_showBorder) ...[
                      _buildSliderRow(
                          loc.translate('border_width'), _borderWidth, 0, 10,
                          (val) {
                        setState(() {
                          _borderWidth = val;
                        });
                      }),
                      const SizedBox(height: 10),
                      _buildSliderRow(
                          loc.translate('border_radius'), _borderRadius, 0, 50,
                          (val) {
                        setState(() {
                          _borderRadius = val;
                        });
                      }),
                      const SizedBox(height: 10),
                      _buildColorPickerRow(
                          loc.translate('border_color'), _borderColor, (color) {
                        setState(() {
                          _borderColor = color;
                        });
                      }),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _copyCSS,
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(loc.translate('copy_css')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildToggleRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorPickerRow(
      String label, Color currentColor, ValueChanged<Color> onColorChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        ElevatedButton(
          onPressed: () => _pickColor(currentColor, onColorChanged),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(context.read<LocalizationProvider>().translate('pick'),
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildFontPickerRow(
      String label, String currentFont, ValueChanged<String?> onFontChanged) {
    final fontNames = GoogleFonts.asMap().keys.toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: currentFont,
          items: fontNames.map((String font) {
            return DropdownMenuItem<String>(
              value: font,
              child: Text(font, style: TextStyle(fontFamily: font)),
            );
          }).toList(),
          onChanged: onFontChanged,
        ),
      ],
    );
  }
}
