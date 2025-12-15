/// Homescreen Editor Screen - iPhone-style widget layout editor
/// Allows free positioning and scaling of dashboard widgets

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/home_widget_model.dart';

class HomescreenEditorScreen extends ConsumerStatefulWidget {
  const HomescreenEditorScreen({super.key});

  @override
  ConsumerState<HomescreenEditorScreen> createState() => _HomescreenEditorScreenState();
}

class _HomescreenEditorScreenState extends ConsumerState<HomescreenEditorScreen> {
  HomeWidget? _selectedWidget;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  
  // Grid configuration
  static const int gridColumns = 4;
  static const int gridRows = 8;
  static const double cellPadding = 4.0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final config = ref.watch(homeScreenConfigProvider(user.id));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startbildschirm bearbeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Widget hinzufügen',
            onPressed: () => _showAddWidgetDialog(context, user.id),
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Zurücksetzen',
            onPressed: () => _resetToDefault(context, user.id),
          ),
        ],
      ),
      body: config == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tippe auf ein Widget um es auszuwählen. Ziehe es an eine neue Position oder ändere die Größe.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Simulated Dashboard Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellWidth = (constraints.maxWidth - (gridColumns - 1) * cellPadding) / gridColumns;
                        final cellHeight = (constraints.maxHeight - (gridRows - 1) * cellPadding) / gridRows;
                        
                        return Stack(
                          children: [
                            // Grid Background
                            _buildGridBackground(cellWidth, cellHeight),
                            
                            // Widgets
                            ...config.visibleWidgets.map((widget) {
                              return _buildDraggableWidget(
                                widget,
                                cellWidth,
                                cellHeight,
                                user.id,
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                
                // Selected Widget Actions
                if (_selectedWidget != null)
                  _buildSelectedWidgetActions(user.id),
              ],
            ),
    );
  }

  Widget _buildGridBackground(double cellWidth, double cellHeight) {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(
        columns: gridColumns,
        rows: gridRows,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        cellPadding: cellPadding,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
    );
  }

  Widget _buildDraggableWidget(
    HomeWidget widget,
    double cellWidth,
    double cellHeight,
    String userId,
  ) {
    final isSelected = _selectedWidget?.id == widget.id;
    final left = widget.gridX * (cellWidth + cellPadding);
    final top = widget.gridY * (cellHeight + cellPadding);
    final width = widget.size.gridWidth * cellWidth + (widget.size.gridWidth - 1) * cellPadding;
    final height = widget.size.gridHeight * cellHeight + (widget.size.gridHeight - 1) * cellPadding;

    return Positioned(
      left: _isDragging && isSelected ? left + _dragOffset.dx : left,
      top: _isDragging && isSelected ? top + _dragOffset.dy : top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedWidget = isSelected ? null : widget;
          });
        },
        onPanStart: (details) {
          setState(() {
            _selectedWidget = widget;
            _isDragging = true;
            _dragOffset = Offset.zero;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
          });
        },
        onPanEnd: (details) {
          _handleDragEnd(widget, cellWidth, cellHeight, userId);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _getWidgetColor(widget.type).withOpacity(isSelected ? 1.0 : 0.9),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Widget Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getWidgetIcon(widget.type),
                          color: _getContrastColor(_getWidgetColor(widget.type)),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.type.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getContrastColor(_getWidgetColor(widget.type)),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.size.gridHeight > 1) ...[
                      const Spacer(),
                      Text(
                        _getWidgetSubtitle(widget.type),
                        style: TextStyle(
                          color: _getContrastColor(_getWidgetColor(widget.type)).withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Size indicator
              if (isSelected)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.size.label.split(' ').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDragEnd(HomeWidget widget, double cellWidth, double cellHeight, String userId) {
    // Calculate new grid position
    final newGridX = (widget.gridX + (_dragOffset.dx / (cellWidth + cellPadding))).round();
    final newGridY = (widget.gridY + (_dragOffset.dy / (cellHeight + cellPadding))).round();
    
    // Clamp to valid range
    final clampedX = newGridX.clamp(0, gridColumns - widget.size.gridWidth);
    final clampedY = newGridY.clamp(0, gridRows - widget.size.gridHeight);
    
    // Update widget position
    ref.read(homeScreenConfigProvider(userId).notifier).moveWidget(
      widget.id,
      clampedX,
      clampedY,
    );
    
    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });
  }

  Widget _buildSelectedWidgetActions(String userId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedWidget!.type.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          
          // Size Selection
          const Text('Größe auswählen:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HomeWidgetSize.values.map((size) {
              final isSelected = _selectedWidget!.size == size;
              return ChoiceChip(
                label: Text(size.label),
                selected: isSelected,
                onSelected: (_) => _changeWidgetSize(userId, size),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          
          // Delete Button
          TextButton.icon(
            onPressed: () => _deleteWidget(userId, _selectedWidget!),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Widget entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeWidgetSize(String userId, HomeWidgetSize newSize) {
    if (_selectedWidget == null) return;
    
    ref.read(homeScreenConfigProvider(userId).notifier).resizeWidget(
      _selectedWidget!.id,
      newSize,
    );
    
    // Update local selection
    setState(() {
      _selectedWidget = _selectedWidget!.copyWith(size: newSize);
    });
  }

  void _deleteWidget(String userId, HomeWidget widget) {
    ref.read(homeScreenConfigProvider(userId).notifier).removeWidget(widget.id);
    setState(() {
      _selectedWidget = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.type.label} entfernt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            ref.read(homeScreenConfigProvider(userId).notifier).addWidget(
              widget.type,
              size: widget.size,
            );
          },
        ),
      ),
    );
  }

  void _showAddWidgetDialog(BuildContext context, String userId) {
    final config = ref.read(homeScreenConfigProvider(userId));
    if (config == null) return;
    
    final existingTypes = config.widgets.map((w) => w.type).toSet();
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Widget hinzufügen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HomeWidgetType.values.map((type) {
                  final exists = existingTypes.contains(type);
                  return FilterChip(
                    avatar: Icon(
                      _getWidgetIcon(type),
                      size: 18,
                      color: exists ? Colors.grey : null,
                    ),
                    label: Text(type.label),
                    selected: false,
                    onSelected: exists
                        ? null
                        : (_) {
                            ref.read(homeScreenConfigProvider(userId).notifier).addWidget(type);
                            Navigator.pop(context);
                          },
                    backgroundColor: exists ? Colors.grey.shade200 : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _resetToDefault(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Layout zurücksetzen?'),
        content: const Text('Dies setzt alle Widgets auf die Standardpositionen zurück.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              ref.read(homeScreenConfigProvider(userId).notifier).resetToDefault();
              setState(() {
                _selectedWidget = null;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Layout zurückgesetzt')),
              );
            },
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }

  Color _getWidgetColor(HomeWidgetType type) {
    switch (type) {
      case HomeWidgetType.calories:
        return Colors.orange;
      case HomeWidgetType.water:
        return Colors.blue;
      case HomeWidgetType.steps:
        return Colors.green;
      case HomeWidgetType.sleep:
        return Colors.purple;
      case HomeWidgetType.mood:
        return Colors.pink;
      case HomeWidgetType.todos:
        return Colors.teal;
      case HomeWidgetType.greeting:
        return Colors.indigo;
      case HomeWidgetType.quickAdd:
        return Colors.amber;
      case HomeWidgetType.books:
        return Colors.brown;
    }
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
        return Icons.sentiment_satisfied;
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

  String _getWidgetSubtitle(HomeWidgetType type) {
    switch (type) {
      case HomeWidgetType.calories:
        return 'Tägliche Kalorien';
      case HomeWidgetType.water:
        return 'Tägliches Trinken';
      case HomeWidgetType.steps:
        return 'Tägliche Schritte';
      case HomeWidgetType.sleep:
        return 'Schlafqualität';
      case HomeWidgetType.mood:
        return 'Aktuelle Stimmung';
      case HomeWidgetType.todos:
        return 'Heutige Aufgaben';
      case HomeWidgetType.greeting:
        return 'Willkommen zurück!';
      case HomeWidgetType.quickAdd:
        return 'Schnelleingabe';
      case HomeWidgetType.books:
        return 'Lesefortschritt';
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

// Custom painter for the grid background
class GridPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double cellWidth;
  final double cellHeight;
  final double cellPadding;
  final Color color;

  GridPainter({
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
    required this.cellPadding,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            col * (cellWidth + cellPadding),
            row * (cellHeight + cellPadding),
            cellWidth,
            cellHeight,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
