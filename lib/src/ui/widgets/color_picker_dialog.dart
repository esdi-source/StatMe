/// Freier Farbwähler für Widgets
/// Schöne, intuitive Farbauswahl ohne Tabs
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog für freie Farbauswahl - intuitiv und stylisch
class ColorPickerDialog extends StatefulWidget {
  final Color? initialColor;
  final Function(Color?) onColorSelected;

  const ColorPickerDialog({
    super.key,
    this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();

  /// Zeigt den Farbwähler Dialog an
  static Future<Color?> show(BuildContext context, {Color? initialColor}) async {
    return showModalBottomSheet<Color?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColorPickerDialog(
        initialColor: initialColor,
        onColorSelected: (color) => Navigator.pop(context, color),
      ),
    );
  }
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  late double _hue;
  late double _saturation;
  late double _brightness;
  
  // Schnellfarben - schöne Palette
  static const List<Color> _quickColors = [
    Color(0xFFFF6B6B), // Koralle
    Color(0xFFFF8C42), // Orange
    Color(0xFFFFC75F), // Gold
    Color(0xFFA8E6CF), // Mint
    Color(0xFF4ECDC4), // Türkis
    Color(0xFF45B7D1), // Himmelblau
    Color(0xFF6C5CE7), // Violett
    Color(0xFFA29BFE), // Lavendel
    Color(0xFFFF85A1), // Rosa
    Color(0xFFFF5252), // Rot
    Color(0xFFFFAB40), // Bernstein
    Color(0xFFFFEE58), // Gelb
    Color(0xFF69F0AE), // Hellgrün
    Color(0xFF40C4FF), // Hellblau
    Color(0xFF7C4DFF), // Dunkelviolett
    Color(0xFFFF4081), // Pink
  ];

  // Graustufen
  static const List<Color> _grayScale = [
    Colors.white,
    Color(0xFFF5F5F5),
    Color(0xFFE0E0E0),
    Color(0xFFBDBDBD),
    Color(0xFF9E9E9E),
    Color(0xFF757575),
    Color(0xFF616161),
    Color(0xFF424242),
    Color(0xFF212121),
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? const Color(0xFF6C5CE7);
    _updateHSBFromColor(_selectedColor);
  }

  void _updateHSBFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
  }

  Color _colorFromHSB() {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
      _updateHSBFromColor(color);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Titel + große Vorschau
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Vorschau-Kreis mit Schatten
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Widget-Farbe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            
            // Schnellfarben-Palette
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beliebte Farben',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickColors.map((color) {
                      final isSelected = _selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () => _selectColor(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: color.computeLuminance() > 0.5 
                                      ? Colors.black87 
                                      : Colors.white,
                                  size: 22,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Graustufen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Neutral',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _grayScale.map((color) {
                      final isSelected = _selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () => _selectColor(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: color.computeLuminance() > 0.5 
                                      ? Colors.black87 
                                      : Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Farbton-Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feinabstimmung',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Farbton (Hue)
                  _buildHueSlider(),
                  const SizedBox(height: 12),
                  
                  // Sättigung + Helligkeit
                  Row(
                    children: [
                      Expanded(child: _buildSaturationSlider()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBrightnessSlider()),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Row(
                children: [
                  // Zurücksetzen Button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onColorSelected(null);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Standard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Übernehmen Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onColorSelected(_selectedColor);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: _selectedColor.computeLuminance() > 0.5 
                            ? Colors.black 
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: _selectedColor.withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text('Übernehmen', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHueSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Farbton', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackShape: _HueTrackShape(),
          ),
          child: Slider(
            value: _hue,
            min: 0,
            max: 360,
            onChanged: (value) {
              setState(() {
                _hue = value;
                _selectedColor = _colorFromHSB();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaturationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sättigung', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: _selectedColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: _selectedColor,
          ),
          child: Slider(
            value: _saturation,
            min: 0,
            max: 1,
            onChanged: (value) {
              setState(() {
                _saturation = value;
                _selectedColor = _colorFromHSB();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrightnessSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Helligkeit', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: Colors.grey.shade800,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: _selectedColor,
          ),
          child: Slider(
            value: _brightness,
            min: 0,
            max: 1,
            onChanged: (value) {
              setState(() {
                _brightness = value;
                _selectedColor = _colorFromHSB();
              });
            },
          ),
        ),
      ],
    );
  }
}

/// Custom Track Shape für den Farbton-Slider (Regenbogen)
class _HueTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 12;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, parentBox.size.width, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    
    final gradient = LinearGradient(
      colors: List.generate(
        7,
        (i) => HSVColor.fromAHSV(1.0, i * 60.0, 1.0, 1.0).toColor(),
      ),
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect);
    
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    context.canvas.drawRRect(rrect, paint);
  }
}
