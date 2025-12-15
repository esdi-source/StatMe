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
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final config = ref.watch(homeScreenConfigProvider(user.id));

    return GestureDetector(
      // Tap auf freien Bereich beendet Edit-Mode
      onTap: _isEditMode ? _exitEditMode : null,
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
                icon: const Icon(Icons.bar_chart),
                tooltip: 'Statistiken',
                onPressed: () => _navigateTo(const StatsScreen()),
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
    final content = _buildWidgetContent(widget, tokens);

    if (_isEditMode) {
      return AnimatedBuilder(
        animation: _wiggleAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _wiggleAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onLongPress: () => _showWidgetOptions(widget, userId, tokens),
          onPanStart: (_) {
            setState(() {
              _draggedWidgetId = widget.id;
              _dragOffset = Offset.zero;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _dragOffset += details.delta;
            });
          },
          onPanEnd: (details) {
            _handleDragEnd(widget, userId, cellWidth, cellHeight);
          },
          child: Stack(
            children: [
              // Widget mit Edit-Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  border: Border.all(
                    color: tokens.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  child: content,
                ),
              ),
              // Delete Button
              Positioned(
                top: -8,
                left: -8,
                child: GestureDetector(
                  onTap: () => _deleteWidget(widget.id, userId),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.remove, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal Mode - Long Press aktiviert Edit Mode
    return GestureDetector(
      onLongPress: _enterEditMode,
      child: content,
    );
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

  Widget _buildWidgetContent(HomeWidget widget, DesignTokens tokens) {
    switch (widget.type) {
      case HomeWidgetType.greeting:
        return _GreetingWidget(size: widget.size);
      case HomeWidgetType.calories:
        return _CaloriesWidget(size: widget.size, onTap: _isEditMode ? null : () => _navigateTo(const FoodScreen()));
      case HomeWidgetType.water:
        return _WaterWidget(size: widget.size, onTap: _isEditMode ? null : () => _navigateTo(const WaterScreen()));
      case HomeWidgetType.steps:
        return _StepsWidget(size: widget.size, onTap: _isEditMode ? null : () => _navigateTo(const StepsScreen()));
      case HomeWidgetType.sleep:
        return _SleepWidget(size: widget.size, onTap: _isEditMode ? null : () => _navigateTo(const SleepScreen()));
      case HomeWidgetType.mood:
        return _MoodWidget(size: widget.size, onTap: _isEditMode ? null : () => _navigateTo(const MoodScreen()));
      case HomeWidgetType.todos:
        return _TodosWidget(size: widget.size, onTap: _isEditMode ? null : () => _navigateTo(const TodosScreen()));
      case HomeWidgetType.quickAdd:
        return _QuickAddWidget(size: widget.size, isEditMode: _isEditMode);
      case HomeWidgetType.books:
        return _BooksWidget(size: widget.size, onTap: _isEditMode ? null : () => _navigateTo(const BooksScreen()));
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

  void _showWidgetOptions(HomeWidget widget, String userId, DesignTokens tokens) {
    HapticFeedback.selectionClick();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.type.label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            
            // Größe ändern
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: const Text('Größe ändern'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showSizeDialog(widget, userId, tokens);
              },
            ),
            
            // Widget löschen
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Widget entfernen', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteWidget(widget.id, userId);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSizeDialog(HomeWidget widget, String userId, DesignTokens tokens) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                'Größe wählen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            
            ...HomeWidgetSize.values.map((size) => ListTile(
              leading: Icon(
                _getSizeIcon(size),
                color: widget.size == size ? tokens.primary : null,
              ),
              title: Text(size.label),
              subtitle: Text('${size.gridWidth}×${size.gridHeight} Felder'),
              trailing: widget.size == size 
                  ? Icon(Icons.check, color: tokens.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                ref.read(homeScreenConfigProvider(userId).notifier).resizeWidget(
                  widget.id,
                  size,
                );
              },
            )),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getSizeIcon(HomeWidgetSize size) {
    switch (size) {
      case HomeWidgetSize.small:
        return Icons.crop_square;
      case HomeWidgetSize.medium:
        return Icons.crop_16_9;
      case HomeWidgetSize.large:
        return Icons.crop_din;
      case HomeWidgetSize.wide:
        return Icons.panorama_wide_angle;
      case HomeWidgetSize.tall:
        return Icons.crop_portrait;
    }
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
      case HomeWidgetType.quickAdd:
        return Icons.add_circle;
      case HomeWidgetType.books:
        return Icons.menu_book;
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
// WIDGET IMPLEMENTATIONS
// ============================================

class _GreetingWidget extends ConsumerWidget {
  final HomeWidgetSize size;

  const _GreetingWidget({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final tokens = ref.watch(designTokensProvider);
    
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Guten Morgen';
    } else if (hour < 18) {
      greeting = 'Guten Tag';
    } else {
      greeting = 'Guten Abend';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: size == HomeWidgetSize.small ? 20 : 28,
              backgroundColor: tokens.primary.withOpacity(0.1),
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : user?.email[0].toUpperCase() ?? 'D',
                style: TextStyle(
                  fontSize: size == HomeWidgetSize.small ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting!',
                    style: TextStyle(
                      fontSize: size == HomeWidgetSize.small ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (size != HomeWidgetSize.small)
                    Text(
                      DateFormat('EEEE, d. MMMM', 'de_DE').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
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
}

class _CaloriesWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _CaloriesWidget({required this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodLogs = ref.watch(foodLogNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final tokens = ref.watch(designTokensProvider);
    
    final total = foodLogs.fold<double>(0, (sum, log) => sum + log.calories);
    final goal = settings?.dailyCalorieGoal ?? 2000;
    final progress = (total / goal).clamp(0.0, 1.0);

    return _StatWidgetCard(
      title: 'Kalorien',
      value: total.toStringAsFixed(0),
      unit: 'kcal',
      icon: Icons.restaurant,
      color: Colors.orange,
      progress: progress,
      subtitle: 'von $goal kcal',
      size: size,
      onTap: onTap,
    );
  }
}

class _WaterWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _WaterWidget({required this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterLogs = ref.watch(waterLogNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    
    final total = waterLogs.fold<int>(0, (sum, log) => sum + log.ml);
    final goal = settings?.dailyWaterGoalMl ?? 2500;
    final progress = (total / goal).clamp(0.0, 1.0);

    return _StatWidgetCard(
      title: 'Wasser',
      value: '$total',
      unit: 'ml',
      icon: Icons.water_drop,
      color: Colors.blue,
      progress: progress,
      subtitle: 'von $goal ml',
      size: size,
      onTap: onTap,
    );
  }
}

class _StepsWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _StepsWidget({required this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepsNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    
    final current = steps?.steps ?? 0;
    final goal = settings?.dailyStepsGoal ?? 10000;
    final progress = (current / goal).clamp(0.0, 1.0);

    return _StatWidgetCard(
      title: 'Schritte',
      value: '$current',
      unit: '',
      icon: Icons.directions_walk,
      color: Colors.green,
      progress: progress,
      subtitle: 'von ${(goal / 1000).toStringAsFixed(0)}k',
      size: size,
      onTap: onTap,
    );
  }
}

class _SleepWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _SleepWidget({required this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepNotifierProvider);
    
    final duration = sleep?.formattedDuration ?? '--';
    final minutes = sleep?.durationMinutes ?? 0;
    final progress = (minutes / 480).clamp(0.0, 1.0); // 8h Ziel

    return _StatWidgetCard(
      title: 'Schlaf',
      value: duration,
      unit: '',
      icon: Icons.bedtime,
      color: Colors.purple,
      progress: progress,
      subtitle: 'Ziel: 8h',
      size: size,
      onTap: onTap,
    );
  }
}

class _MoodWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _MoodWidget({required this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodNotifierProvider);
    final tokens = ref.watch(designTokensProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (mood != null) ...[
                Text(mood.moodEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(
                  mood.moodLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
              ] else ...[
                Icon(Icons.add_reaction, size: 32, color: tokens.textSecondary),
                const SizedBox(height: 4),
                Text(
                  'Stimmung',
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TodosWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _TodosWidget({required this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoNotifierProvider);
    final tokens = ref.watch(designTokensProvider);
    
    final today = DateTime.now();
    final todayTodos = todos.where((t) => 
      t.active && 
      t.startDate.year == today.year && 
      t.startDate.month == today.month && 
      t.startDate.day == today.day
    ).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ToDos (${todayTodos.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: todayTodos.isEmpty
                    ? Center(
                        child: Text(
                          'Alles erledigt! 🎉',
                          style: TextStyle(color: tokens.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: math.min(todayTodos.length, 4),
                        itemBuilder: (context, index) {
                          final todo = todayTodos[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle_outlined,
                                  size: 16,
                                  color: tokens.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    todo.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final bool isEditMode;

  const _QuickAddWidget({required this.size, required this.isEditMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Schnell hinzufügen',
              style: TextStyle(
                fontSize: 11,
                color: tokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickAddButton(
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  onTap: isEditMode ? null : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FoodScreen()),
                  ),
                ),
                _QuickAddButton(
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  onTap: isEditMode ? null : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WaterScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAddButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _BooksWidget extends ConsumerWidget {
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _BooksWidget({required this.size, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 28, color: Colors.brown),
              const SizedBox(height: 4),
              Text(
                'Bücher',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatWidgetCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double progress;
  final String subtitle;
  final HomeWidgetSize size;
  final VoidCallback? onTap;

  const _StatWidgetCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.progress,
    required this.subtitle,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 3),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
