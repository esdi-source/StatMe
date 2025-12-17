/// Freier Farbwähler für Widgets
/// Unterstützt RGB, HEX und Palette

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog für freie Farbauswahl
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

class _ColorPickerDialogState extends State<ColorPickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _selectedColor;
  late TextEditingController _hexController;
  
  // RGB Werte
  double _red = 0;
  double _green = 0;
  double _blue = 0;
  double _opacity = 1.0;

  // Vordefinierte Palette
  static const List<Color> _paletteColors = [
    // Grautöne
    Color(0xFFF8FAFC),
    Color(0xFFE2E8F0),
    Color(0xFF94A3B8),
    Color(0xFF475569),
    Color(0xFF1E293B),
    
    // Rot-Töne
    Color(0xFFFEE2E2),
    Color(0xFFFCA5A5),
    Color(0xFFEF4444),
    Color(0xFFDC2626),
    Color(0xFF991B1B),
    
    // Orange-Töne
    Color(0xFFFFEDD5),
    Color(0xFFFDBA74),
    Color(0xFFF97316),
    Color(0xFFEA580C),
    Color(0xFF9A3412),
    
    // Gelb-Töne
    Color(0xFFFEF9C3),
    Color(0xFFFDE047),
    Color(0xFFEAB308),
    Color(0xFFCA8A04),
    Color(0xFF854D0E),
    
    // Grün-Töne
    Color(0xFFDCFCE7),
    Color(0xFF86EFAC),
    Color(0xFF22C55E),
    Color(0xFF16A34A),
    Color(0xFF166534),
    
    // Türkis-Töne
    Color(0xFFCCFBF1),
    Color(0xFF5EEAD4),
    Color(0xFF14B8A6),
    Color(0xFF0D9488),
    Color(0xFF115E59),
    
    // Blau-Töne
    Color(0xFFDBEAFE),
    Color(0xFF93C5FD),
    Color(0xFF3B82F6),
    Color(0xFF2563EB),
    Color(0xFF1E40AF),
    
    // Indigo-Töne
    Color(0xFFE0E7FF),
    Color(0xFFA5B4FC),
    Color(0xFF6366F1),
    Color(0xFF4F46E5),
    Color(0xFF3730A3),
    
    // Violett-Töne
    Color(0xFFF3E8FF),
    Color(0xFFD8B4FE),
    Color(0xFFA855F7),
    Color(0xFF9333EA),
    Color(0xFF6B21A8),
    
    // Pink-Töne
    Color(0xFFFCE7F3),
    Color(0xFFF9A8D4),
    Color(0xFFEC4899),
    Color(0xFFDB2777),
    Color(0xFF9D174D),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedColor = widget.initialColor ?? const Color(0xFF6366F1);
    _hexController = TextEditingController(text: _colorToHex(_selectedColor));
    _updateRGBFromColor(_selectedColor);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _updateRGBFromColor(Color color) {
    _red = color.red.toDouble();
    _green = color.green.toDouble();
    _blue = color.blue.toDouble();
    _opacity = color.opacity;
  }

  Color _colorFromRGB() {
    return Color.fromRGBO(
      _red.round(),
      _green.round(),
      _blue.round(),
      _opacity,
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2, 8).toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
      _updateRGBFromColor(color);
      _hexController.text = _colorToHex(color);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          
          // Titel + Vorschau
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Farbe wählen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Vorschau
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Palette'),
              Tab(text: 'RGB'),
              Tab(text: 'HEX'),
            ],
          ),
          
          // Tab Content
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaletteTab(),
                _buildRGBTab(),
                _buildHexTab(),
              ],
            ),
          ),
          
          // Buttons
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Row(
              children: [
                // Zurücksetzen Button
                OutlinedButton.icon(
                  onPressed: () {
                    widget.onColorSelected(null);
                  },
                  icon: const Icon(Icons.format_color_reset),
                  label: const Text('Standard'),
                ),
                const SizedBox(width: 12),
                // Übernehmen Button
                Expanded(
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
                    ),
                    child: const Text('Übernehmen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _paletteColors.length,
        itemBuilder: (context, index) {
          final color = _paletteColors[index];
          final isSelected = _selectedColor.value == color.value;
          
          return GestureDetector(
            onTap: () => _selectColor(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: color.computeLuminance() > 0.5 
                          ? Colors.black 
                          : Colors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRGBTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Rot
          _buildColorSlider(
            label: 'Rot',
            value: _red,
            color: Colors.red,
            onChanged: (v) {
              setState(() {
                _red = v;
                _selectedColor = _colorFromRGB();
                _hexController.text = _colorToHex(_selectedColor);
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Grün
          _buildColorSlider(
            label: 'Grün',
            value: _green,
            color: Colors.green,
            onChanged: (v) {
              setState(() {
                _green = v;
                _selectedColor = _colorFromRGB();
                _hexController.text = _colorToHex(_selectedColor);
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Blau
          _buildColorSlider(
            label: 'Blau',
            value: _blue,
            color: Colors.blue,
            onChanged: (v) {
              setState(() {
                _blue = v;
                _selectedColor = _colorFromRGB();
                _hexController.text = _colorToHex(_selectedColor);
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Transparenz
          _buildColorSlider(
            label: 'Deckkraft',
            value: _opacity * 255,
            color: Colors.grey,
            onChanged: (v) {
              setState(() {
                _opacity = v / 255;
                _selectedColor = _colorFromRGB();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
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
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildHexTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // HEX Input
          TextField(
            controller: _hexController,
            decoration: InputDecoration(
              labelText: 'HEX-Farbcode',
              hintText: '#6366F1',
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _hexController.text = data!.text!;
                    _onHexChanged(data.text!);
                  }
                },
              ),
            ),
            onChanged: _onHexChanged,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f#]')),
              LengthLimitingTextInputFormatter(7),
            ],
          ),
          const SizedBox(height: 24),
          
          // Schnelle HEX-Codes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickHexChip('#6366F1', 'Indigo'),
              _buildQuickHexChip('#3B82F6', 'Blau'),
              _buildQuickHexChip('#22C55E', 'Grün'),
              _buildQuickHexChip('#EAB308', 'Gelb'),
              _buildQuickHexChip('#F97316', 'Orange'),
              _buildQuickHexChip('#EF4444', 'Rot'),
              _buildQuickHexChip('#EC4899', 'Pink'),
              _buildQuickHexChip('#A855F7', 'Violett'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHexChip(String hex, String label) {
    final color = _hexToColor(hex);
    return ActionChip(
      avatar: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      label: Text(label),
      onPressed: () {
        _hexController.text = hex;
        _onHexChanged(hex);
      },
    );
  }

  void _onHexChanged(String hex) {
    final color = _hexToColor(hex);
    if (color != null) {
      setState(() {
        _selectedColor = color;
        _updateRGBFromColor(color);
      });
    }
  }
}
