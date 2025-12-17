/// Dashboard Screen - iOS-Style Home Screen mit Edit-Mode
/// Long-Press aktiviert Bearbeitungsmodus, Drag & Drop, Widget-Anpassung

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../models/home_widget_model.dart';
import '../core/config/app_config.dart';
import '../ui/widgets/color_picker_dialog.dart';
import '../ui/widgets/unified_stat_widget.dart';
import 'screens.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isEditMode = false;
  String? _draggedWidgetId;
  Offset _dragOffset = Offset.zero;
  String? _resizingWidgetId;
  Offset _resizeOffset = Offset.zero;
  HomeWidgetSize? _previewSize; // Live-Preview für Resize
  
  // Animation für Wackeln im Edit-Mode
  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;

  // Grid-Konfiguration
  static const int gridColumns = 4;
  static const double cellPadding = 8.0;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _wiggleAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() => _isEditMode = true);
    _wiggleController.repeat(reverse: true);
    HapticFeedback.mediumImpact();
  }

  void _exitEditMode() {
    setState(() => _isEditMode = false);
    _wiggleController.stop();
    _wiggleController.reset();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final today = DateTime.now();
    await Future.wait([
      ref.read(foodLogNotifierProvider.notifier).load(user.id, today),
      ref.read(waterLogNotifierProvider.notifier).load(user.id, today),
      ref.read(stepsNotifierProvider.notifier).load(user.id, today),
      ref.read(sleepNotifierProvider.notifier).load(user.id, today),
      ref.read(moodNotifierProvider.notifier).load(user.id, today),
      ref.read(todoNotifierProvider.notifier).load(user.id),
      ref.read(settingsNotifierProvider.notifier).load(user.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final tokens = ref.watch(designTokensProvider);
    final backgroundImagePath = ref.watch(backgroundImagePathProvider);
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final config = ref.watch(homeScreenConfigProvider(user.id));

    return GestureDetector(
      // Tap auf freien Bereich beendet Edit-Mode
      onTap: _isEditMode ? _exitEditMode : null,
      // Long Press auf Hintergrund aktiviert Edit-Mode
      onLongPress: _isEditMode ? null : _enterEditMode,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.analytics_outlined, color: tokens.primary),
              const SizedBox(width: 8),
              const Text('StatMe'),
              const Spacer(),
              if (AppConfig.isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          actions: [
            if (_isEditMode) ...[
              TextButton.icon(
                onPressed: _exitEditMode,
                icon: const Icon(Icons.check),
                label: const Text('Fertig'),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.insights),
                tooltip: 'Statistik',
                onPressed: () => _navigateTo(const StatisticsScreen()),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Einstellungen',
                onPressed: () => _navigateTo(const SettingsScreen()),
              ),
            ],
          ],
        ),
        body: Stack(
          children: [
            // Hintergrundbild wenn gesetzt
            if (backgroundImagePath != null)
              Positioned.fill(
                child: Image.network(
                  backgroundImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            
            // Haupt-Content
            RefreshIndicator(
              onRefresh: _loadData,
              child: config == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildWidgetGrid(config, user.id, tokens),
            ),
            
            // Edit-Mode Bottom Bar
            if (_isEditMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildEditModeBar(user.id, tokens),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetGrid(HomeScreenConfig config, String userId, DesignTokens tokens) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32; // Padding
        final cellWidth = (availableWidth - (gridColumns - 1) * cellPadding) / gridColumns;
        final cellHeight = cellWidth * 1.2; // Etwas höher als breit

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Grid mit Widgets
              _buildResponsiveGrid(config, cellWidth, cellHeight, userId, tokens),
              
              // Extra Padding für Edit-Mode Bar
              if (_isEditMode) const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveGrid(
    HomeScreenConfig config,
    double cellWidth,
    double cellHeight,
    String userId,
    DesignTokens tokens,
  ) {
    final widgets = config.visibleWidgets;
    
    // Berechne Zeilen
    int maxRow = 0;
    for (final widget in widgets) {
      final endRow = widget.gridY + widget.size.gridHeight;
      if (endRow > maxRow) maxRow = endRow;
    }

    return SizedBox(
      height: maxRow * (cellHeight + cellPadding),
      child: Stack(
        children: widgets.map((widget) {
          final left = widget.gridX * (cellWidth + cellPadding);
          final top = widget.gridY * (cellHeight + cellPadding);
          final width = widget.size.gridWidth * cellWidth + 
                       (widget.size.gridWidth - 1) * cellPadding;
          final height = widget.size.gridHeight * cellHeight + 
                        (widget.size.gridHeight - 1) * cellPadding;

          return AnimatedPositioned(
            duration: _draggedWidgetId == widget.id 
                ? Duration.zero 
                : const Duration(milliseconds: 200),
            left: _draggedWidgetId == widget.id ? left + _dragOffset.dx : left,
            top: _draggedWidgetId == widget.id ? top + _dragOffset.dy : top,
            width: width,
            height: height,
            child: _buildDashboardWidget(
              widget, 
              userId, 
              tokens,
              cellWidth,
              cellHeight,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboardWidget(
    HomeWidget widget,
    String userId,
    DesignTokens tokens,
    double cellWidth,
    double cellHeight,
  ) {
    final widgetTransparency = ref.watch(widgetTransparencyProvider);
    
    // Widget-spezifische Farbe ermitteln - wird direkt an Content weitergegeben
    final customColor = widget.customColorValue != null 
        ? Color(widget.customColorValue!) 
        : null;
    
    final content = _buildWidgetContent(widget, tokens, customColor);
    
    // Transparenz anwenden wenn gesetzt
    Widget styledContent = content;
    if (widgetTransparency > 0) {
      styledContent = Opacity(
        opacity: 1 - (widgetTransparency * 0.5), // Max 50% transparent
        child: content,
      );
    }

    if (_isEditMode) {
      // Berechne Preview-Größe während Resize
      final isResizing = _resizingWidgetId == widget.id;
      final displaySize = isResizing && _previewSize != null ? _previewSize! : widget.size;
      
      return AnimatedBuilder(
        animation: _wiggleAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: isResizing ? 0 : _wiggleAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Sofortiges Dragging ohne Verzögerung
          onPanStart: (details) {
            setState(() {
              _draggedWidgetId = widget.id;
              _dragOffset = Offset.zero;
            });
            HapticFeedback.selectionClick();
          },
          onPanUpdate: (details) {
            if (_draggedWidgetId == widget.id) {
              setState(() {
                _dragOffset += details.delta;
              });
            }
          },
          onPanEnd: (details) {
            if (_draggedWidgetId == widget.id) {
              _handleDragEnd(widget, userId, cellWidth, cellHeight);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Widget mit Edit-Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  border: Border.all(
                    color: isResizing ? Colors.blue : tokens.primary.withOpacity(0.5),
                    width: isResizing ? 3 : 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  child: styledContent,
                ),
              ),
              
              // Größen-Anzeige während Resize
              if (isResizing)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: tokens.shadowMedium,
                      ),
                      child: Text(
                        '${displaySize.gridWidth}×${displaySize.gridHeight}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Delete Button - oben links
              Positioned(
                top: -6,
                left: -6,
                child: GestureDetector(
                  onTap: () => _deleteWidget(widget.id, userId),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                      boxShadow: tokens.shadowSmall,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),
              
              // Farb-Button - Mitte (Pinsel für Farbauswahl)
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showColorPicker(widget, userId, tokens),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (widget.customColorValue != null 
                            ? Color(widget.customColorValue!) 
                            : tokens.primary).withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: tokens.shadowMedium,
                      ),
                      child: const Icon(Icons.brush, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              
              // Resize Handles - alle 4 Ecken (klein und proportional)
              // Oben rechts
              _buildResizeHandle(
                widget: widget,
                userId: userId,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                tokens: tokens,
                alignment: Alignment.topRight,
                top: -5,
                right: -5,
              ),
              // Unten links
              _buildResizeHandle(
                widget: widget,
                userId: userId,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                tokens: tokens,
                alignment: Alignment.bottomLeft,
                bottom: -5,
                left: -5,
              ),
              // Unten rechts (Hauptgriff)
              _buildResizeHandle(
                widget: widget,
                userId: userId,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                tokens: tokens,
                alignment: Alignment.bottomRight,
                bottom: -5,
                right: -5,
                isPrimary: true,
              ),
            ],
          ),
        ),
      );
    }

    // Normal Mode - Long Press aktiviert Edit Mode
    return GestureDetector(
      onLongPress: _enterEditMode,
      child: styledContent,
    );
  }
  
  /// Berechnet die Vorschau-Größe während des Resize
  HomeWidgetSize _calculatePreviewSize(HomeWidget widget, double cellWidth, double cellHeight) {
    final deltaWidth = (_resizeOffset.dx / (cellWidth + cellPadding)).round();
    final deltaHeight = (_resizeOffset.dy / (cellHeight + cellPadding)).round();
    
    final newWidth = (widget.size.gridWidth + deltaWidth).clamp(1, 4);
    final newHeight = (widget.size.gridHeight + deltaHeight).clamp(1, 3);
    
    // Finde passende Größe
    for (final size in HomeWidgetSize.values) {
      if (size.gridWidth == newWidth && size.gridHeight == newHeight) {
        return size;
      }
    }
    
    // Fallback: Finde nächstbeste Größe
    return _findBestSize(newWidth, newHeight);
  }
  
  HomeWidgetSize _findBestSize(int width, int height) {
    if (width >= 3 && height >= 3) return HomeWidgetSize.full;
    if (width >= 3 && height >= 2) return HomeWidgetSize.extraLarge;
    if (width >= 4 && height >= 2) return HomeWidgetSize.fullWide;
    if (width >= 4) return HomeWidgetSize.wide;
    if (width >= 3) return HomeWidgetSize.wideHalf;
    if (width >= 2 && height >= 3) return HomeWidgetSize.largeTall;
    if (width >= 2 && height >= 2) return HomeWidgetSize.large;
    if (height >= 3) return HomeWidgetSize.tallMedium;
    if (height >= 2) return HomeWidgetSize.tall;
    if (width >= 2) return HomeWidgetSize.medium;
    return HomeWidgetSize.small;
  }
  
  /// Baut einen einzelnen Resize-Handle für eine Ecke
  Widget _buildResizeHandle({
    required HomeWidget widget,
    required String userId,
    required double cellWidth,
    required double cellHeight,
    required DesignTokens tokens,
    required Alignment alignment,
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool isPrimary = false,
  }) {
    // Handle-Größe proportional zur Widget-Größe, aber mit Grenzen
    final handleSize = isPrimary ? 16.0 : 12.0;
    
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _resizingWidgetId = widget.id;
            _resizeOffset = Offset.zero;
            _previewSize = widget.size;
          });
          HapticFeedback.selectionClick();
        },
        onPanUpdate: (details) {
          if (_resizingWidgetId == widget.id) {
            setState(() {
              _resizeOffset += details.delta;
              _previewSize = _calculatePreviewSize(widget, cellWidth, cellHeight);
            });
          }
        },
        onPanEnd: (details) {
          if (_resizingWidgetId == widget.id) {
            _handleResizeEnd(widget, userId, cellWidth, cellHeight);
          }
        },
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: isPrimary ? Colors.blue : Colors.blue.withOpacity(0.7),
            borderRadius: BorderRadius.circular(isPrimary ? 4 : 3),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: tokens.shadowSmall,
          ),
          child: isPrimary 
              ? const Icon(Icons.open_in_full, color: Colors.white, size: 10)
              : null,
        ),
      ),
    );
  }
  
  void _handleResizeEnd(HomeWidget widget, String userId, double cellWidth, double cellHeight) {
    if (_resizingWidgetId != widget.id) return;
    
    // Berechne neue Größe basierend auf Resize-Offset
    final deltaWidth = (_resizeOffset.dx / (cellWidth + cellPadding)).round();
    final deltaHeight = (_resizeOffset.dy / (cellHeight + cellPadding)).round();
    
    // Bestimme neue Größe
    final currentWidth = widget.size.gridWidth;
    final currentHeight = widget.size.gridHeight;
    final newWidth = (currentWidth + deltaWidth).clamp(1, 4);
    final newHeight = (currentHeight + deltaHeight).clamp(1, 3);
    
    // Finde passende Größe
    HomeWidgetSize? newSize;
    for (final size in HomeWidgetSize.values) {
      if (size.gridWidth == newWidth && size.gridHeight == newHeight) {
        newSize = size;
        break;
      }
    }
    
    // Falls keine exakte Übereinstimmung, finde nächstbeste
    if (newSize == null) {
      if (newWidth >= 3 && newHeight >= 2) {
        newSize = HomeWidgetSize.extraLarge;
      } else if (newWidth >= 4) {
        newSize = HomeWidgetSize.wide;
      } else if (newWidth >= 2 && newHeight >= 2) {
        newSize = HomeWidgetSize.large;
      } else if (newHeight >= 2) {
        newSize = HomeWidgetSize.tall;
      } else if (newWidth >= 2) {
        newSize = HomeWidgetSize.medium;
      } else {
        newSize = HomeWidgetSize.small;
      }
    }
    
    if (newSize != widget.size) {
      ref.read(homeScreenConfigProvider(userId).notifier).resizeWidget(widget.id, newSize);
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _resizingWidgetId = null;
      _resizeOffset = Offset.zero;
      _previewSize = null;
    });
  }
  
  void _showColorPicker(HomeWidget widget, String userId, DesignTokens tokens) async {
    final color = await ColorPickerDialog.show(
      context,
      initialColor: widget.customColorValue != null 
          ? Color(widget.customColorValue!)
          : null,
    );
    
    ref.read(homeScreenConfigProvider(userId).notifier)
        .updateWidgetColor(widget.id, color?.value);
    HapticFeedback.selectionClick();
  }

  void _handleDragEnd(HomeWidget widget, String userId, double cellWidth, double cellHeight) {
    // Berechne neue Grid-Position
    final newX = (widget.gridX + (_dragOffset.dx / (cellWidth + cellPadding)).round())
        .clamp(0, gridColumns - widget.size.gridWidth);
    final newY = (widget.gridY + (_dragOffset.dy / (cellHeight + cellPadding)).round())
        .clamp(0, 20);

    if (newX != widget.gridX || newY != widget.gridY) {
      ref.read(homeScreenConfigProvider(userId).notifier).moveWidget(
        widget.id,
        newX,
        newY,
      );
    }

    setState(() {
      _draggedWidgetId = null;
      _dragOffset = Offset.zero;
    });
  }

  Widget _buildWidgetContent(HomeWidget widget, DesignTokens tokens, Color? customColor) {
    switch (widget.type) {
      case HomeWidgetType.greeting:
        return _GreetingWidget(size: widget.size, customColor: customColor);
      case HomeWidgetType.calories:
        return _CaloriesWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const FoodScreen()));
      case HomeWidgetType.water:
        return _WaterWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const WaterScreen()));
      case HomeWidgetType.steps:
        return _StepsWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const StepsScreen()));
      case HomeWidgetType.sleep:
        return _SleepWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const SleepScreen()));
      case HomeWidgetType.mood:
        return _MoodWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const MoodScreen()));
      case HomeWidgetType.todos:
        return _TodosWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const TodosScreen()));
      case HomeWidgetType.books:
        return _BooksWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const BooksScreen()));
      case HomeWidgetType.timer:
        return _TimerWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const TimerWidgetScreen()));
      case HomeWidgetType.school:
        return _SchoolWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const SchoolScreen()));
      case HomeWidgetType.sport:
        return _SportWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const SportScreen()));
      case HomeWidgetType.skin:
        return _SkinWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const SkinScreen()));
      case HomeWidgetType.hair:
        return _HairWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const HairScreen()));
      case HomeWidgetType.digestion:
        return _DigestionWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const DigestionScreen()));
      case HomeWidgetType.supplements:
        return _SupplementsWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const SupplementScreen()));
      case HomeWidgetType.media:
        return _MediaWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const MediaScreen()));
      case HomeWidgetType.household:
        return _HouseholdWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const HouseholdScreen()));
      case HomeWidgetType.statistics:
        return _StatisticsWidget(size: widget.size, customColor: customColor, onTap: _isEditMode ? null : () => _navigateTo(const StatisticsScreen()));
    }
  }

  Widget _buildEditModeBar(String userId, DesignTokens tokens) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _EditModeButton(
            icon: Icons.add_circle,
            label: 'Widget hinzufügen',
            onTap: () => _showAddWidgetDialog(userId, tokens),
          ),
          _EditModeButton(
            icon: Icons.restore,
            label: 'Zurücksetzen',
            onTap: () => _resetLayout(userId),
          ),
        ],
      ),
    );
  }

  void _showAddWidgetDialog(String userId, DesignTokens tokens) {
    final config = ref.read(homeScreenConfigProvider(userId));
    final existingTypes = config?.widgets.map((w) => w.type).toSet() ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Widget hinzufügen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: HomeWidgetType.values.map((type) {
                  final alreadyExists = existingTypes.contains(type);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: alreadyExists 
                          ? Colors.grey.shade200 
                          : tokens.primary.withOpacity(0.1),
                      child: Icon(
                        _getWidgetIcon(type),
                        color: alreadyExists ? Colors.grey : tokens.primary,
                      ),
                    ),
                    title: Text(
                      type.label,
                      style: TextStyle(
                        color: alreadyExists ? Colors.grey : null,
                      ),
                    ),
                    subtitle: alreadyExists 
                        ? const Text('Bereits vorhanden') 
                        : null,
                    trailing: alreadyExists 
                        ? null 
                        : Icon(Icons.add_circle, color: tokens.primary),
                    onTap: alreadyExists ? null : () {
                      Navigator.pop(context);
                      ref.read(homeScreenConfigProvider(userId).notifier).addWidget(type);
                      HapticFeedback.lightImpact();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWidgetIcon(HomeWidgetType type) {
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
      case HomeWidgetType.greeting:
        return Icons.waving_hand;
      case HomeWidgetType.books:
        return Icons.menu_book;
      case HomeWidgetType.timer:
        return Icons.timer;
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
      case HomeWidgetType.statistics:
        return Icons.insights;
    }
  }

  void _deleteWidget(String widgetId, String userId) {
    ref.read(homeScreenConfigProvider(userId).notifier).removeWidget(widgetId);
    HapticFeedback.lightImpact();
  }

  void _resetLayout(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Layout zurücksetzen?'),
        content: const Text('Alle Widgets werden auf die Standardpositionen zurückgesetzt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(homeScreenConfigProvider(userId).notifier).resetToDefault();
              HapticFeedback.mediumImpact();
            },
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

// ============================================
// EDIT MODE BUTTON
// ============================================

class _EditModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EditModeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// WIDGET IMPLEMENTATIONS - EINHEITLICHES DESIGN
// ============================================

class _GreetingWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;

  const _GreetingWidget({required this.size, this.customColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final color = customColor ?? const Color(0xFF6366F1);
    
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Guten Morgen';
    } else if (hour < 18) {
      greeting = 'Guten Tag';
    } else {
      greeting = 'Guten Abend';
    }

    return _UnifiedWidgetContainer(
      color: color,
      child: Row(
        children: [
          CircleAvatar(
            radius: size.isSmall ? 18 : 24,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              user?.displayName?.isNotEmpty == true
                  ? user!.displayName![0].toUpperCase()
                  : user?.email[0].toUpperCase() ?? 'D',
              style: TextStyle(
                fontSize: size.isSmall ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting!',
                  style: TextStyle(
                    fontSize: size.isSmall ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!size.isSmall)
                  Text(
                    DateFormat('EEEE, d. MMMM', 'de_DE').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _CaloriesWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodLogs = ref.watch(foodLogNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    
    final total = foodLogs.fold<double>(0, (sum, log) => sum + log.calories);
    final goal = settings?.dailyCalorieGoal ?? 2000;
    final progress = (total / goal).clamp(0.0, 1.0);

    return UnifiedStatWidget(
      size: size,
      title: 'Kalorien',
      value: total.toStringAsFixed(0),
      unit: 'kcal',
      subtitle: 'von $goal kcal',
      icon: Icons.restaurant,
      color: customColor ?? Colors.orange,
      progress: progress,
      onTap: onTap,
    );
  }
}

class _WaterWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _WaterWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterLogs = ref.watch(waterLogNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    
    final total = waterLogs.fold<int>(0, (sum, log) => sum + log.ml);
    final goal = settings?.dailyWaterGoalMl ?? 2500;
    final progress = (total / goal).clamp(0.0, 1.0);

    return UnifiedStatWidget(
      size: size,
      title: 'Wasser',
      value: '$total',
      unit: 'ml',
      subtitle: 'von $goal ml',
      icon: Icons.water_drop,
      color: customColor ?? Colors.blue,
      progress: progress,
      onTap: onTap,
    );
  }
}

class _StepsWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _StepsWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepsNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    
    final current = steps?.steps ?? 0;
    final goal = settings?.dailyStepsGoal ?? 10000;
    final progress = (current / goal).clamp(0.0, 1.0);

    return UnifiedStatWidget(
      size: size,
      title: 'Schritte',
      value: '$current',
      unit: '',
      subtitle: 'von ${(goal / 1000).toStringAsFixed(0)}k Schritte',
      icon: Icons.directions_walk,
      color: customColor ?? Colors.green,
      progress: progress,
      onTap: onTap,
    );
  }
}

class _SleepWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _SleepWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepNotifierProvider);
    
    final duration = sleep?.formattedDuration ?? '--';
    final minutes = sleep?.durationMinutes ?? 0;
    final progress = (minutes / 480).clamp(0.0, 1.0);

    return UnifiedStatWidget(
      size: size,
      title: 'Schlaf',
      value: duration,
      unit: '',
      subtitle: 'Ziel: 8 Stunden',
      icon: Icons.bedtime,
      color: customColor ?? Colors.purple,
      progress: progress,
      onTap: onTap,
    );
  }
}

class _MoodWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _MoodWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodNotifierProvider);
    final color = customColor ?? const Color(0xFFEC4899);

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(mood, color),
    );
  }

  Widget _buildContent(MoodLogModel? mood, Color color) {
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: mood != null
                ? Text(mood.moodEmoji, style: const TextStyle(fontSize: 18))
                : Icon(Icons.mood, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Stimmung',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.mood, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'Stimmung',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (mood != null) ...[
          Text(mood.moodEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            mood.moodLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
          ),
        ] else ...[
          Icon(Icons.add_reaction, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'Tippen zum Eintragen',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}

class _TodosWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _TodosWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoNotifierProvider);
    final color = customColor ?? Colors.green;
    
    final today = DateTime.now();
    final todayTodos = todos.where((t) => 
      t.active && 
      t.startDate.year == today.year && 
      t.startDate.month == today.month && 
      t.startDate.day == today.day
    ).toList();

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(todayTodos, color),
    );
  }

  Widget _buildContent(List<dynamic> todayTodos, Color color) {
    // Dynamische Anzahl der angezeigten Items je nach Größe
    int maxItems = 0;
    if (size == HomeWidgetSize.small) maxItems = 0;
    else if (size == HomeWidgetSize.medium || size == HomeWidgetSize.tall) maxItems = 2;
    else if (size == HomeWidgetSize.large) maxItems = 4;
    else if (size.isLarge) maxItems = 6;
    else maxItems = 3;

    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            '${todayTodos.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'ToDos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              '${todayTodos.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        if (maxItems > 0) ...[
          const SizedBox(height: 8),
          Expanded(
            child: todayTodos.isEmpty
                ? Center(
                    child: Text(
                      '✓ Alles erledigt!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: math.min(todayTodos.length, maxItems),
                    itemBuilder: (context, index) {
                      final todo = todayTodos[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.circle_outlined, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                todo.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _BooksWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _BooksWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = customColor ?? Colors.brown;

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(color),
    );
  }

  Widget _buildContent(Color color) {
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu_book, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Bücher',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.menu_book, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'Bücher',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'Leseliste',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          'Tippen zum Öffnen',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _TimerWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _TimerWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerSessions = ref.watch(timerSessionsProvider);
    final color = customColor ?? Colors.deepPurple;
    
    final today = DateTime.now();
    final todaySessions = timerSessions.where((s) => 
      s.startTime.year == today.year &&
      s.startTime.month == today.month &&
      s.startTime.day == today.day
    ).toList();
    
    final totalMinutesToday = todaySessions.fold<int>(
      0, (sum, s) => sum + s.durationMinutes
    );

    return UnifiedStatWidget(
      size: size,
      title: 'Timer',
      value: '$totalMinutesToday',
      unit: 'min',
      subtitle: 'heute fokussiert',
      icon: Icons.timer,
      color: color,
      progress: (totalMinutesToday / 120).clamp(0.0, 1.0),
      onTap: onTap,
    );
  }
}

class _SchoolWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _SchoolWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(homeworkNotifierProvider);
    final color = customColor ?? Colors.indigo;
    
    final pendingHomework = homework.where((h) => h.status != HomeworkStatus.done).length;

    return UnifiedStatWidget(
      size: size,
      title: 'Schule',
      value: '$pendingHomework',
      unit: '',
      subtitle: 'offene Aufgaben',
      icon: Icons.school,
      color: color,
      progress: pendingHomework > 0 ? 0.5 : 1.0,
      onTap: onTap,
    );
  }
}

class _SportWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _SportWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sportSessionsNotifierProvider);
    final streak = ref.watch(sportStreakProvider);
    final color = customColor ?? Colors.green;
    
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekSessions = sessions.where((s) => s.date.isAfter(startOfWeek)).length;

    return UnifiedStatWidget(
      size: size,
      title: 'Sport',
      value: '${streak.currentStreak}',
      unit: 'Tage',
      subtitle: '$weekSessions Einheiten diese Woche',
      icon: Icons.fitness_center,
      color: color,
      progress: (weekSessions / 5).clamp(0.0, 1.0),
      onTap: onTap,
    );
  }
}

class _SkinWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _SkinWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(skinEntriesNotifierProvider);
    final color = customColor ?? Colors.pink;
    
    final now = DateTime.now();
    final todayEntry = entries.cast<SkinEntry?>().firstWhere(
      (e) => e != null && 
             e.date.year == now.year &&
             e.date.month == now.month &&
             e.date.day == now.day,
      orElse: () => null,
    );

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(todayEntry, color),
    );
  }

  Widget _buildContent(SkinEntry? todayEntry, Color color) {
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: todayEntry != null
                ? Text(todayEntry.overallCondition.emoji, style: const TextStyle(fontSize: 18))
                : Icon(Icons.face_retouching_natural, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Haut',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.face_retouching_natural, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'Haut',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (todayEntry != null) ...[
          Text(todayEntry.overallCondition.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            'Heute eingetragen',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ] else ...[
          Icon(Icons.add, size: 28, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'Eintrag hinzufügen',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}

class _HairWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _HairWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final color = customColor ?? Colors.brown;
    
    if (user == null) {
      return _UnifiedWidgetContainer(
        color: color,
        onTap: onTap,
        child: _buildEmptyContent(color),
      );
    }
    
    final entries = ref.watch(hairCareEntriesProvider(user.id));
    final events = ref.watch(hairEventsProvider(user.id));
    final stats = ref.watch(hairCareStatisticsProvider(user.id));
    
    final now = DateTime.now();
    final todayEntry = entries.cast<HairCareEntry?>().firstWhere(
      (e) => e != null && 
             e.date.year == now.year &&
             e.date.month == now.month &&
             e.date.day == now.day,
      orElse: () => null,
    );

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(todayEntry, stats, events, color),
    );
  }

  Widget _buildEmptyContent(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.content_cut, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          'Haarpflege',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildContent(HairCareEntry? todayEntry, HairCareStatistics stats, List<HairEvent> events, Color color) {
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: todayEntry != null && todayEntry.careTypes.isNotEmpty
                ? Text(todayEntry.careTypes.first.emoji, style: const TextStyle(fontSize: 18))
                : Icon(Icons.content_cut, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Haarpflege',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    // Mittlere und große Größen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.content_cut, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'Haarpflege',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (todayEntry != null) ...[
              const Spacer(),
              Icon(Icons.check_circle, size: 16, color: Colors.green),
            ],
          ],
        ),
        const Spacer(),
        if (todayEntry != null) ...[
          Wrap(
            spacing: 4,
            children: todayEntry.careTypes.take(3).map((t) => 
              Text(t.emoji, style: const TextStyle(fontSize: 16))
            ).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            todayEntry.careTypes.map((t) => t.label).take(2).join(', '),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ] else ...[
          // Zeige Statistik statt leerer Zustand
          if (stats.daysSinceLastWash >= 0)
            Text(
              stats.daysSinceLastWash == 0 
                  ? 'Heute gewaschen' 
                  : 'Vor ${stats.daysSinceLastWash}d gewaschen',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            )
          else
            Text(
              'Tippen zum Eintragen',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
        ],
        if (size.isLarge && stats.daysSinceLastHaircut >= 0) ...[
          const SizedBox(height: 4),
          Text(
            '✂️ Letzter Schnitt: vor ${stats.daysSinceLastHaircut} Tagen',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}

class _SupplementsWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _SupplementsWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final color = customColor ?? Colors.deepOrange;
    
    if (user == null) {
      return _UnifiedWidgetContainer(
        color: color,
        onTap: onTap,
        child: _buildEmptyContent(color),
      );
    }
    
    final supplements = ref.watch(supplementsProvider(user.id));
    final intakes = ref.watch(supplementIntakesProvider(user.id));
    
    final now = DateTime.now();
    final todayIntakes = intakes.where((i) => 
      i.timestamp.year == now.year &&
      i.timestamp.month == now.month &&
      i.timestamp.day == now.day
    ).toList();
    
    final activeSupplements = supplements.where((s) => !s.isPaused).toList();

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(activeSupplements, todayIntakes, supplements, color),
    );
  }

  Widget _buildEmptyContent(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.medication, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          'Supplements',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildContent(List<Supplement> active, List<SupplementIntake> todayIntakes, List<Supplement> all, Color color) {
    final takenToday = todayIntakes.map((i) => i.supplementId).toSet();
    final takenCount = active.where((s) => takenToday.contains(s.id)).length;
    
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: active.isNotEmpty
                ? Text('$takenCount/${active.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))
                : Icon(Icons.medication, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Supplements',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    // Mittlere und große Größen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.medication, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'Supplements',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (takenCount == active.length && active.isNotEmpty) ...[
              const Spacer(),
              Icon(Icons.check_circle, size: 16, color: Colors.green),
            ],
          ],
        ),
        const Spacer(),
        if (active.isNotEmpty) ...[
          Row(
            children: [
              Text('✓ $takenCount', style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              Text(' / ${active.length}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            takenCount == active.length 
                ? 'Alle eingenommen!'
                : '${active.length - takenCount} noch offen',
            style: TextStyle(
              fontSize: 11,
              color: takenCount == active.length ? Colors.green.shade600 : Colors.grey.shade600,
            ),
          ),
        ] else ...[
          Text(
            'Keine Supplements',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tippen zum Anlegen',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        if (size.isLarge && todayIntakes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '📊 Heute: ${todayIntakes.length} Einnahmen',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}

class _MediaWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _MediaWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final color = customColor ?? Colors.indigo;
    
    if (user == null) {
      return _UnifiedWidgetContainer(
        color: color,
        onTap: onTap,
        child: _buildEmptyContent(color),
      );
    }
    
    final entries = ref.watch(userMediaEntriesProvider(user.id));
    final watchlist = entries.where((e) => e.status == MediaStatus.watchlist).toList();
    final watched = entries.where((e) => e.status == MediaStatus.watched).toList();
    final watching = entries.where((e) => e.status == MediaStatus.watching).toList();
    
    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(watchlist, watched, watching, entries, color),
    );
  }

  Widget _buildEmptyContent(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.movie, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          'Filme & Serien',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildContent(List<UserMediaEntry> watchlist, List<UserMediaEntry> watched, List<UserMediaEntry> watching, List<UserMediaEntry> all, Color color) {
    // Berechne Durchschnittsbewertung
    final ratedEntries = watched.where((e) => e.rating != null).toList();
    final avgRating = ratedEntries.isNotEmpty
        ? ratedEntries.map((e) => e.rating!.overall).reduce((a, b) => a + b) / ratedEntries.length
        : 0.0;
    
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: all.isNotEmpty
                ? Text('${watched.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))
                : Icon(Icons.movie, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Filme',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    // Mittlere und große Größen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.movie, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Filme & Serien',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (all.isNotEmpty) ...[
          Row(
            children: [
              Text('🎬 ${watched.length}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(width: 8),
              Text('📋 ${watchlist.length}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (watching.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('▶️ ${watching.length}', style: TextStyle(fontSize: 12, color: color)),
              ],
            ],
          ),
          if (ratedEntries.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '⭐ ${avgRating.toStringAsFixed(1)} Durchschnitt',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ] else ...[
          Text(
            'Keine Einträge',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tippen zum Durchstöbern',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        if (size.isLarge && watched.isNotEmpty && watched.last.rating != null) ...[
          const SizedBox(height: 4),
          Text(
            '📺 Zuletzt: ${watched.last.media.title}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _HouseholdWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _HouseholdWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final color = customColor ?? Colors.teal;
    
    if (user == null) {
      return _UnifiedWidgetContainer(
        color: color,
        onTap: onTap,
        child: _buildEmptyContent(color),
      );
    }
    
    final tasks = ref.watch(householdTasksProvider(user.id));
    final completions = ref.watch(householdCompletionsProvider(user.id));
    
    // Berechne Status
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayCompleted = completions.where((c) {
      final d = c.completedAt;
      return d.year == today.year && d.month == today.month && d.day == today.day && !c.wasSkipped;
    }).length;
    
    // Überfällige und heute fällige
    int overdueCount = 0;
    int dueTodayCount = 0;
    TaskWithStatus? nextDue;
    
    for (final task in tasks.where((t) => !t.isPaused && t.isRecurring)) {
      final status = TaskWithStatus.calculate(task, completions);
      if (status.isOverdue) {
        overdueCount++;
        nextDue ??= status;
      } else if (status.isDueToday) {
        dueTodayCount++;
        nextDue ??= status;
      }
    }

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(tasks, todayCompleted, overdueCount, dueTodayCount, nextDue, color),
    );
  }

  Widget _buildEmptyContent(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cleaning_services, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          'Haushalt',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildContent(List<HouseholdTask> tasks, int todayCompleted, int overdueCount, int dueTodayCount, TaskWithStatus? nextDue, Color color) {
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: overdueCount > 0
                ? Text('$overdueCount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red))
                : todayCompleted > 0
                    ? Text('✓$todayCompleted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))
                    : Icon(Icons.cleaning_services, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Haushalt',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    // Mittlere und große Größen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cleaning_services, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Haushalt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (overdueCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$overdueCount',
                  style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const Spacer(),
        if (tasks.isNotEmpty) ...[
          Row(
            children: [
              Text('✓ $todayCompleted', style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              Text(' heute', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (overdueCount + dueTodayCount > 0) ...[
                const Spacer(),
                Text('${overdueCount + dueTodayCount} offen', style: TextStyle(fontSize: 12, color: overdueCount > 0 ? Colors.red.shade600 : Colors.orange.shade600)),
              ],
            ],
          ),
          if (nextDue != null && size.isLarge) ...[
            const SizedBox(height: 4),
            Text(
              '${nextDue.task.category.emoji} ${nextDue.task.name}',
              style: TextStyle(
                fontSize: 11,
                color: nextDue.isOverdue ? Colors.red.shade600 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ] else ...[
          Text(
            'Keine Aufgaben',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tippen zum Einrichten',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}

class _DigestionWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _DigestionWidget({required this.size, this.customColor, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final color = customColor ?? Colors.teal;
    
    if (user == null) {
      return _UnifiedWidgetContainer(
        color: color,
        onTap: onTap,
        child: _buildEmptyContent(color),
      );
    }
    
    final entries = ref.watch(digestionEntriesProvider(user.id));
    
    final now = DateTime.now();
    final todayEntries = entries.where((e) => 
      e.timestamp.year == now.year &&
      e.timestamp.month == now.month &&
      e.timestamp.day == now.day
    ).toList();

    return _UnifiedWidgetContainer(
      color: color,
      onTap: onTap,
      child: _buildContent(todayEntries, entries, color),
    );
  }

  Widget _buildEmptyContent(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.science, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          'Verdauung',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildContent(List<DigestionEntry> todayEntries, List<DigestionEntry> allEntries, Color color) {
    final bowelToday = todayEntries.where((e) => e.type == ToiletType.stool || e.type == ToiletType.both).length;
    final urineToday = todayEntries.where((e) => e.type == ToiletType.urination || e.type == ToiletType.both).length;
    
    if (size.isSmall) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: todayEntries.isNotEmpty
                ? Text('$bowelToday', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))
                : Icon(Icons.science, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Verdauung',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
          ),
        ],
      );
    }

    // Berechne Durchschnittskonsistenz der letzten 7 Tage
    final last7Days = allEntries.where((e) {
      final daysDiff = DateTime.now().difference(e.timestamp).inDays;
      return daysDiff <= 7 && (e.type == ToiletType.stool || e.type == ToiletType.both) && e.consistency != null;
    }).toList();
    
    double? avgConsistency;
    if (last7Days.isNotEmpty) {
      avgConsistency = last7Days.map((e) => e.consistency!.value).reduce((a, b) => a + b) / last7Days.length;
    }

    // Mittlere und große Größen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.science, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              'Verdauung',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (todayEntries.isNotEmpty) ...[
              const Spacer(),
              Icon(Icons.check_circle, size: 16, color: Colors.green),
            ],
          ],
        ),
        const Spacer(),
        if (todayEntries.isNotEmpty) ...[
          Row(
            children: [
              Text('🚽 $bowelToday', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              Text('💧 $urineToday', style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          if (avgConsistency != null)
            Text(
              'Ø Konsistenz: ${avgConsistency.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
        ] else ...[
          Text(
            'Heute noch keine Einträge',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tippen zum Eintragen',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        if (size.isLarge && avgConsistency != null) ...[
          const SizedBox(height: 4),
          Text(
            '📊 7-Tage Trend: ${_getConsistencyLabel(avgConsistency)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
  
  String _getConsistencyLabel(double avg) {
    if (avg < 2) return 'Zu fest';
    if (avg < 3) return 'Fest';
    if (avg < 5) return 'Normal ✓';
    if (avg < 6) return 'Weich';
    return 'Zu weich';
  }
}

class _StatisticsWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final Color? customColor;
  final VoidCallback? onTap;

  const _StatisticsWidget({
    required this.size,
    this.customColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodHistory = ref.watch(moodHistoryProvider);
    final color = customColor ?? Colors.deepPurple;
    
    double? avgMood;
    if (moodHistory.isNotEmpty) {
      final last7Days = moodHistory.where((m) {
        final daysDiff = DateTime.now().difference(m.date).inDays;
        return daysDiff <= 7;
      }).toList();
      if (last7Days.isNotEmpty) {
        avgMood = last7Days.map((m) => m.mood).reduce((a, b) => a + b) / last7Days.length;
      }
    }

    return UnifiedStatWidget(
      size: size,
      title: 'Statistik',
      value: avgMood != null ? 'Ø ${avgMood.toStringAsFixed(1)}' : '--',
      unit: '',
      subtitle: '7-Tage Stimmung',
      icon: Icons.insights,
      color: color,
      progress: avgMood != null ? avgMood / 10 : null,
      onTap: onTap,
    );
  }
}

// ============================================
// EINHEITLICHER WIDGET CONTAINER
// ============================================

class _UnifiedWidgetContainer extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  const _UnifiedWidgetContainer({
    required this.color,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.4), // Erhöht von 0.2
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.20), // Erhöht von 0.08
                color.withOpacity(0.08), // Erhöht von 0.03
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}