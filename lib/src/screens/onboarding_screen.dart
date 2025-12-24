/// Onboarding Screen - Erster App-Start Setup
/// Klarer Start ohne Überforderung, Nutzer wählt was relevant ist
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// Wichtigkeitsstufe für Widgets
enum WidgetImportance {
  low('Niedrig', 1),
  medium('Mittel', 2),
  high('Hoch', 3),
  veryHigh('Sehr hoch', 4);

  final String label;
  final int value;
  const WidgetImportance(this.label, this.value);

  /// Konvertiert Wichtigkeit zu Widget-Größe
  HomeWidgetSize toSize() {
    switch (this) {
      case WidgetImportance.veryHigh:
        return HomeWidgetSize.large; // 2x2
      case WidgetImportance.high:
        return HomeWidgetSize.medium; // 2x1
      case WidgetImportance.medium:
        return HomeWidgetSize.tall; // 1x2
      case WidgetImportance.low:
        return HomeWidgetSize.small; // 1x1
    }
  }
}

/// Widget-Auswahl für Onboarding
class OnboardingWidgetSelection {
  final HomeWidgetType type;
  bool isSelected;
  WidgetImportance importance;
  final bool isRecommended;
  final bool isMandatory;

  OnboardingWidgetSelection({
    required this.type,
    this.isSelected = false,
    this.importance = WidgetImportance.medium,
    this.isRecommended = false,
    this.isMandatory = false,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Widget-Auswahl
  late List<OnboardingWidgetSelection> _widgetSelections;

  // Theme-Auswahl
  ThemePreset _selectedPreset = ThemePreset.hell;
  ShapeStyle _selectedShape = ShapeStyle.round;
  Color _selectedColor = const Color(0xFFB2C9AD); // Sage
  double _intensity = 0.7;

  @override
  void initState() {
    super.initState();
    _initWidgetSelections();
  }

  void _initWidgetSelections() {
    _widgetSelections = [
      // Empfohlen & Pflicht
      OnboardingWidgetSelection(
        type: HomeWidgetType.mood,
        isSelected: true,
        importance: WidgetImportance.high,
        isRecommended: true,
        isMandatory: true,
      ),
      // Gesundheit
      OnboardingWidgetSelection(
        type: HomeWidgetType.sleep,
        isRecommended: true,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.water,
        isRecommended: true,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.calories,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.steps,
      ),
      // Produktivität
      OnboardingWidgetSelection(
        type: HomeWidgetType.todos,
        isRecommended: true,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.school,
      ),
      // Lifestyle
      OnboardingWidgetSelection(
        type: HomeWidgetType.sport,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.books,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.media,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.recipes,
      ),
      // Haushalt & Pflege
      OnboardingWidgetSelection(
        type: HomeWidgetType.household,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.skin,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.hair,
      ),
      // Gesundheit Extra
      OnboardingWidgetSelection(
        type: HomeWidgetType.digestion,
      ),
      OnboardingWidgetSelection(
        type: HomeWidgetType.supplements,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    // Standard-Layout mit empfohlenen Widgets
    for (final selection in _widgetSelections) {
      if (selection.isRecommended) {
        selection.isSelected = true;
      }
    }
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    // 1. Theme speichern
    final themeNotifier = ref.read(themeStateProvider.notifier);
    await themeNotifier.setPreset(_selectedPreset);
    await themeNotifier.setShape(_selectedShape);
    await themeNotifier.setIntensity(_intensity);
    await themeNotifier.setCustomColors(primary: _selectedColor);

    // 2. Dashboard-Widgets erstellen mit intelligenter Platzierung
    final selectedWidgets = _widgetSelections.where((w) => w.isSelected).toList();
    
    // Mische die Widgets für zufällige Anordnung
    selectedWidgets.shuffle(Random());

    // Erstelle Widget-Liste mit Positionen (keine Überschneidungen)
    final widgets = <HomeWidget>[];
    const maxCols = 4;
    
    // Grid-Belegung tracken (true = belegt)
    final grid = <int, Set<int>>{}; // Row -> Set of occupied columns
    
    // Funktion um freie Position zu finden
    (int, int) findFreePosition(int width, int height) {
      int row = 0;
      while (true) {
        for (int col = 0; col <= maxCols - width; col++) {
          bool fits = true;
          // Prüfe ob alle benötigten Zellen frei sind
          for (int r = row; r < row + height && fits; r++) {
            for (int c = col; c < col + width && fits; c++) {
              if (grid[r]?.contains(c) ?? false) {
                fits = false;
              }
            }
          }
          if (fits) {
            // Markiere Zellen als belegt
            for (int r = row; r < row + height; r++) {
              grid.putIfAbsent(r, () => <int>{});
              for (int c = col; c < col + width; c++) {
                grid[r]!.add(c);
              }
            }
            return (col, row);
          }
        }
        row++;
        if (row > 50) break; // Sicherheitslimit
      }
      return (0, row);
    }
    
    // Farbvarianten generieren basierend auf ausgewählter Farbe
    List<Color> generateColorVariants(Color baseColor, int count) {
      final hsl = HSLColor.fromColor(baseColor);
      final variants = <Color>[];
      
      for (int i = 0; i < count; i++) {
        // Variiere Hue leicht (-30 bis +30 Grad)
        final hueShift = (i * 25) % 60 - 30;
        final newHue = (hsl.hue + hueShift) % 360;
        
        // Variiere Saturation und Lightness leicht
        final satShift = ((i * 7) % 20 - 10) / 100;
        final lightShift = ((i * 11) % 16 - 8) / 100;
        
        final newSat = (hsl.saturation + satShift).clamp(0.3, 1.0);
        final newLight = (hsl.lightness + lightShift).clamp(0.3, 0.7);
        
        variants.add(HSLColor.fromAHSL(1.0, newHue, newSat, newLight).toColor());
      }
      
      return variants;
    }
    
    final colorVariants = generateColorVariants(_selectedColor, selectedWidgets.length + 2);
    int colorIndex = 0;
    
    // Zufällige Größen für Widgets (gewichtet)
    HomeWidgetSize getRandomSize() {
      final rand = Random();
      final roll = rand.nextInt(100);
      if (roll < 35) {
        return HomeWidgetSize.small; // 35% - 1x1
      } else if (roll < 60) {
        return HomeWidgetSize.medium; // 25% - 2x1
      } else if (roll < 80) {
        return HomeWidgetSize.tall; // 20% - 1x2
      } else {
        return HomeWidgetSize.large; // 20% - 2x2
      }
    }

    // Begrüßung immer oben (breit)
    final greetingPos = findFreePosition(4, 1);
    widgets.add(HomeWidget(
      id: 'greeting_${const Uuid().v4()}',
      type: HomeWidgetType.greeting,
      size: HomeWidgetSize.wide,
      gridX: greetingPos.$1,
      gridY: greetingPos.$2,
    ));

    // Widgets platzieren
    for (final selection in selectedWidgets) {
      final size = getRandomSize();
      final pos = findFreePosition(size.gridWidth, size.gridHeight);
      
      widgets.add(HomeWidget(
        id: '${selection.type.name}_${const Uuid().v4()}',
        type: selection.type,
        size: size,
        gridX: pos.$1,
        gridY: pos.$2,
        customColorValue: colorVariants[colorIndex % colorVariants.length].value,
      ));
      colorIndex++;
    }

    // Statistik-Widget am Ende
    final statsPos = findFreePosition(2, 1);
    widgets.add(HomeWidget(
      id: 'statistics_${const Uuid().v4()}',
      type: HomeWidgetType.statistics,
      size: HomeWidgetSize.medium,
      gridX: statsPos.$1,
      gridY: statsPos.$2,
    ));

    // 3. Speichere Konfiguration
    final config = HomeScreenConfig(
      oderId: user.id,
      widgets: widgets,
      gridColumns: 4,
      updatedAt: DateTime.now(),
    );

    await ref.read(homeScreenConfigProvider(user.id).notifier).setWidgets(widgets);

    // 4. Onboarding als abgeschlossen markieren (user-spezifisch)
    await ref.read(userOnboardingProvider(user.id).notifier).setComplete();

    // 5. Callback ausführen
    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? _selectedColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildWidgetSelectionPage(),
                  _buildThemePage(),
                ],
              ),
            ),
            // Navigation
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PAGE 1: WELCOME
  // ============================================================================

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo / Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insights,
              size: 64,
              color: _selectedColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Willkommen bei StatMe',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Diese App passt sich deinem Leben an.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle aus, was du tracken möchtest – alles ist später jederzeit änderbar.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Feature Highlights
          _buildFeatureRow(Icons.dashboard_customize, 'Persönliches Dashboard'),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.analytics, 'Intelligente Statistiken'),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.palette, 'Individuelles Design'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _selectedColor, size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // ============================================================================
  // PAGE 2: WIDGET SELECTION + IMPORTANCE
  // ============================================================================

  Widget _buildWidgetSelectionPage() {
    final selectedCount = _widgetSelections.where((w) => w.isSelected).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Was möchtest du tracken?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedCount ausgewählt',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryHeader('Empfohlen'),
              ..._widgetSelections
                  .where((w) => w.isRecommended)
                  .map(_buildWidgetTile),
              const SizedBox(height: 16),
              _buildCategoryHeader('Gesundheit'),
              ..._widgetSelections
                  .where((w) => [
                        HomeWidgetType.sleep,
                        HomeWidgetType.water,
                        HomeWidgetType.calories,
                        HomeWidgetType.steps,
                        HomeWidgetType.digestion,
                        HomeWidgetType.supplements,
                      ].contains(w.type) && !w.isRecommended)
                  .map(_buildWidgetTile),
              const SizedBox(height: 16),
              _buildCategoryHeader('Produktivität'),
              ..._widgetSelections
                  .where((w) => [
                        HomeWidgetType.todos,
                        HomeWidgetType.school,
                      ].contains(w.type) && !w.isRecommended)
                  .map(_buildWidgetTile),
              const SizedBox(height: 16),
              _buildCategoryHeader('Lifestyle'),
              ..._widgetSelections
                  .where((w) => [
                        HomeWidgetType.sport,
                        HomeWidgetType.books,
                        HomeWidgetType.media,
                        HomeWidgetType.recipes,
                        HomeWidgetType.household,
                        HomeWidgetType.skin,
                        HomeWidgetType.hair,
                      ].contains(w.type) && !w.isRecommended)
                  .map(_buildWidgetTile),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildWidgetTile(OnboardingWidgetSelection selection) {
    final icon = _getIconForType(selection.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selection.isSelected
                ? _selectedColor.withOpacity(0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: selection.isSelected ? _selectedColor : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                selection.type.label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: selection.isSelected ? null : Colors.grey.shade600,
                ),
              ),
            ),
            if (selection.isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Empfohlen',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
              ),
          ],
        ),
        trailing: Switch(
          value: selection.isSelected,
          onChanged: selection.isMandatory
              ? null
              : (value) {
                  setState(() => selection.isSelected = value);
                  HapticFeedback.selectionClick();
                },
          activeThumbColor: _selectedColor,
        ),
        children: [
          if (selection.isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wichtigkeit (beeinflusst Widget-Größe)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<WidgetImportance>(
                    segments: WidgetImportance.values
                        .map((i) => ButtonSegment(
                              value: i,
                              label: Text(i.label, style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                    selected: {selection.importance},
                    onSelectionChanged: (value) {
                      setState(() => selection.importance = value.first);
                      HapticFeedback.selectionClick();
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getImportanceDescription(selection.importance),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getImportanceDescription(WidgetImportance importance) {
    switch (importance) {
      case WidgetImportance.veryHigh:
        return '→ Großes Widget (2×2), hohe Gewichtung in Statistik';
      case WidgetImportance.high:
        return '→ Mittleres Widget (2×1), normale Gewichtung';
      case WidgetImportance.medium:
        return '→ Hohes Widget (1×2), moderate Gewichtung';
      case WidgetImportance.low:
        return '→ Kleines Widget (1×1), geringe Gewichtung';
    }
  }

  IconData _getIconForType(HomeWidgetType type) {
    switch (type) {
      case HomeWidgetType.calories:
        return Icons.restaurant;
      case HomeWidgetType.water:
        return Icons.water_drop;
      case HomeWidgetType.steps:
        return Icons.directions_walk;
      case HomeWidgetType.sleep:
        return Icons.bedtime;
      case HomeWidgetType.mood:
        return Icons.mood;
      case HomeWidgetType.todos:
        return Icons.check_circle;
      case HomeWidgetType.productCheck:
        return Icons.qr_code_scanner;
      case HomeWidgetType.greeting:
        return Icons.waving_hand;
      case HomeWidgetType.books:
        return Icons.menu_book;
      case HomeWidgetType.school:
        return Icons.school;
      case HomeWidgetType.sport:
        return Icons.fitness_center;
      case HomeWidgetType.skin:
        return Icons.face_retouching_natural;
      case HomeWidgetType.hair:
        return Icons.content_cut;
      case HomeWidgetType.digestion:
        return Icons.science;
      case HomeWidgetType.supplements:
        return Icons.medication;
      case HomeWidgetType.media:
        return Icons.movie;
      case HomeWidgetType.household:
        return Icons.cleaning_services;
      case HomeWidgetType.recipes:
        return Icons.restaurant_menu;
      case HomeWidgetType.statistics:
        return Icons.insights;
    }
  }

  // ============================================================================
  // PAGE 3: THEME SELECTION
  // ============================================================================

  Widget _buildThemePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Dein App-Design',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Wähle deinen persönlichen Look',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Preview Card
        _buildPreviewCard(),
        const SizedBox(height: 24),

        // Design Preset
        Text(
          'Design-Stil',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ThemePreset.values.map((preset) {
            final isSelected = _selectedPreset == preset;
            return ChoiceChip(
              label: Text(preset.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPreset = preset);
                HapticFeedback.selectionClick();
              },
              selectedColor: _selectedColor.withOpacity(0.3),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Shape
        Text(
          'Form',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ShapeStyle>(
          segments: ShapeStyle.values
              .map((s) => ButtonSegment(
                    value: s,
                    label: Text(s.label),
                    icon: Icon(s == ShapeStyle.round ? Icons.circle : Icons.square_outlined),
                  ))
              .toList(),
          selected: {_selectedShape},
          onSelectionChanged: (value) {
            setState(() => _selectedShape = value.first);
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 20),

        // Color Picker
        Text(
          'Grundfarbe',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        _buildColorPicker(),
        const SizedBox(height: 20),

        // Intensity
        Text(
          'Farbintensität: ${(_intensity * 100).round()}%',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _intensity,
          min: 0.3,
          max: 1.0,
          divisions: 7,
          activeColor: _selectedColor,
          onChanged: (value) {
            setState(() => _intensity = value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sanft', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            Text('Intensiv', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final radius = _selectedShape == ShapeStyle.round ? 16.0 : 8.0;
    final previewColor = Color.lerp(Colors.white, _selectedColor, _intensity * 0.3)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedPreset == ThemePreset.minimal ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Mini Widget Preview 1
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: previewColor,
                    borderRadius: BorderRadius.circular(radius / 2),
                  ),
                  child: Center(
                    child: Icon(Icons.mood, color: _selectedColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mini Widget Preview 2
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: previewColor,
                    borderRadius: BorderRadius.circular(radius / 2),
                  ),
                  child: Center(
                    child: Icon(Icons.water_drop, color: _selectedColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Wide Widget Preview
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(radius / 2),
            ),
            child: Center(
              child: Text(
                'Vorschau',
                style: TextStyle(
                  color: _selectedPreset == ThemePreset.minimal ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      const Color(0xFFB2C9AD), // Sage
      const Color(0xFF8ECAE6), // Sky Blue
      const Color(0xFFFFB703), // Amber
      const Color(0xFFE63946), // Red
      const Color(0xFFF72585), // Pink (Fotzig)
      const Color(0xFFFF6B35), // Orange (Fotzig)
      const Color(0xFF9B5DE5), // Purple
      const Color(0xFF00F5D4), // Turquoise
      const Color(0xFF2EC4B6), // Teal
      const Color(0xFF6C757D), // Gray
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = _selectedColor.value == color.value;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedColor = color);
            HapticFeedback.selectionClick();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================================
  // NAVIGATION BAR
  // ============================================================================

  Widget _buildNavigationBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Skip Button (nur auf erster Seite)
          if (_currentPage == 0)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Überspringen',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Zurück'),
            ),
          const Spacer(),
          // Next/Complete Button
          FilledButton(
            onPressed: _nextPage,
            style: FilledButton.styleFrom(
              backgroundColor: _selectedColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              _currentPage == 2 ? 'Fertig' : 'Weiter',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ONBOARDING COMPLETE PROVIDER (User-specific)
// ============================================================================

/// Provider um zu prüfen ob Onboarding für einen User abgeschlossen ist
class UserOnboardingNotifier extends StateNotifier<bool> {
  final String _userId;
  SharedPreferences? _prefs;
  
  UserOnboardingNotifier(this._userId) : super(false) {
    _load();
  }

  String get _key => 'onboarding_complete_$_userId';

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs!.getBool(_key) ?? false;
  }

  Future<void> setComplete() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_key, true);
    state = true;
  }

  Future<void> reset() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_key, false);
    state = false;
  }
}

/// User-spezifischer Onboarding Provider
final userOnboardingProvider =
    StateNotifierProvider.family<UserOnboardingNotifier, bool, String>((ref, userId) {
  return UserOnboardingNotifier(userId);
});

/// Legacy provider für Abwärtskompatibilität (Settings)
class OnboardingCompleteNotifier extends StateNotifier<bool> {
  OnboardingCompleteNotifier() : super(true); // Default true für bestehende User
  
  void setFromUser(bool value) {
    state = value;
  }
}

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingCompleteNotifier, bool>((ref) {
  return OnboardingCompleteNotifier();
});
