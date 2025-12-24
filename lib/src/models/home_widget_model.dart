import 'package:equatable/equatable.dart';

/// Verfügbare Widget-Typen für den Homescreen
enum HomeWidgetType {
  calories('Kalorien', 'restaurant'),
  water('Wasser', 'water_drop'),
  steps('Schritte', 'directions_walk'),
  sleep('Schlaf', 'bedtime'),
  mood('Stimmung', 'mood'),
  todos('ToDos', 'check_circle'),
  greeting('Begrüßung', 'waving_hand'),
  books('Bücher', 'menu_book'),
  school('Schule', 'school'),
  sport('Sport', 'fitness_center'),
  skin('Gesichtshaut', 'face_retouching_natural'),
  hair('Haarpflege', 'content_cut'),
  digestion('Verdauung', 'science'),
  supplements('Supplements', 'medication'),
  media('Filme & Serien', 'movie'),
  household('Haushalt', 'cleaning_services'),
  recipes('Rezepte', 'restaurant_menu'),
  statistics('Statistik', 'insights');

  final String label;
  final String iconName;

  const HomeWidgetType(this.label, this.iconName);
}

/// Widget-Größe im Grid - erweitert für flexible Layouts
enum HomeWidgetSize {
  // Basis-Größen
  small(1, 1, 'Klein (1×1)'),
  medium(2, 1, 'Mittel (2×1)'),
  large(2, 2, 'Groß (2×2)'),
  
  // Erweiterte Größen
  wide(4, 1, 'Breit (4×1)'),
  tall(1, 2, 'Hoch (1×2)'),
  wideHalf(3, 1, 'Breit-Halb (3×1)'),
  tallMedium(1, 3, 'Hoch-Mittel (1×3)'),
  largeTall(2, 3, 'Groß-Hoch (2×3)'),
  extraLarge(3, 2, 'Extra-Groß (3×2)'),
  full(3, 3, 'Voll (3×3)'),
  fullWide(4, 2, 'Voll-Breit (4×2)');

  final int gridWidth;
  final int gridHeight;
  final String label;

  const HomeWidgetSize(this.gridWidth, this.gridHeight, this.label);
  
  /// Gesamtfläche in Grid-Zellen
  int get area => gridWidth * gridHeight;
  
  /// Ist dies eine kleine Größe? (1-2 Zellen)
  bool get isSmall => area <= 2;
  
  /// Ist dies eine mittlere Größe? (3-4 Zellen)
  bool get isMedium => area >= 3 && area <= 4;
  
  /// Ist dies eine große Größe? (5+ Zellen)
  bool get isLarge => area >= 5;
}

/// Ein einzelnes Widget auf dem Homescreen
class HomeWidget extends Equatable {
  final String id;
  final HomeWidgetType type;
  final HomeWidgetSize size;
  final int gridX; // Position im Grid (0-3 für 4-Spalten-Grid)
  final int gridY; // Zeile im Grid
  final bool visible;
  final int? customColorValue; // Individuelle Widget-Farbe (null = Standard)

  const HomeWidget({
    required this.id,
    required this.type,
    this.size = HomeWidgetSize.small,
    this.gridX = 0,
    this.gridY = 0,
    this.visible = true,
    this.customColorValue,
  });

  HomeWidget copyWith({
    String? id,
    HomeWidgetType? type,
    HomeWidgetSize? size,
    int? gridX,
    int? gridY,
    bool? visible,
    int? customColorValue,
    bool clearCustomColor = false,
  }) {
    return HomeWidget(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      visible: visible ?? this.visible,
      customColorValue: clearCustomColor ? null : (customColorValue ?? this.customColorValue),
    );
  }

  factory HomeWidget.fromJson(Map<String, dynamic> json) {
    return HomeWidget(
      id: json['id'] as String,
      type: HomeWidgetType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => HomeWidgetType.calories,
      ),
      size: HomeWidgetSize.values.firstWhere(
        (s) => s.name == json['size'],
        orElse: () => HomeWidgetSize.small,
      ),
      gridX: json['grid_x'] as int? ?? 0,
      gridY: json['grid_y'] as int? ?? 0,
      visible: json['visible'] as bool? ?? true,
      customColorValue: json['custom_color'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'size': size.name,
      'grid_x': gridX,
      'grid_y': gridY,
      'visible': visible,
      if (customColorValue != null) 'custom_color': customColorValue,
    };
  }

  @override
  List<Object?> get props => [id, type, size, gridX, gridY, visible, customColorValue];
}

/// Die gesamte Homescreen-Konfiguration
class HomeScreenConfig extends Equatable {
  final String oderId;
  final List<HomeWidget> widgets;
  final int gridColumns; // Standard: 4 wie bei iOS
  final DateTime updatedAt;

  const HomeScreenConfig({
    required this.oderId,
    required this.widgets,
    this.gridColumns = 4,
    required this.updatedAt,
  });

  /// Standard-Layout erstellen
  factory HomeScreenConfig.defaultLayout(String oderId) {
    return HomeScreenConfig(
      oderId: oderId,
      gridColumns: 4,
      updatedAt: DateTime.now(),
      widgets: const [
        // Erste Reihe: Begrüßung (volle Breite)
        HomeWidget(
          id: 'greeting_1',
          type: HomeWidgetType.greeting,
          size: HomeWidgetSize.wide,
          gridX: 0,
          gridY: 0,
        ),
        // Zweite Reihe: 4 kleine Widgets
        HomeWidget(
          id: 'calories_1',
          type: HomeWidgetType.calories,
          size: HomeWidgetSize.small,
          gridX: 0,
          gridY: 1,
        ),
        HomeWidget(
          id: 'water_1',
          type: HomeWidgetType.water,
          size: HomeWidgetSize.small,
          gridX: 1,
          gridY: 1,
        ),
        HomeWidget(
          id: 'steps_1',
          type: HomeWidgetType.steps,
          size: HomeWidgetSize.small,
          gridX: 2,
          gridY: 1,
        ),
        HomeWidget(
          id: 'sleep_1',
          type: HomeWidgetType.sleep,
          size: HomeWidgetSize.small,
          gridX: 3,
          gridY: 1,
        ),
        // Dritte Reihe: Stimmung (mittel) + Bücher (mittel)
        HomeWidget(
          id: 'mood_1',
          type: HomeWidgetType.mood,
          size: HomeWidgetSize.medium,
          gridX: 0,
          gridY: 2,
        ),
        HomeWidget(
          id: 'books_1',
          type: HomeWidgetType.books,
          size: HomeWidgetSize.medium,
          gridX: 2,
          gridY: 2,
        ),
        // Vierte Reihe: ToDos (groß)
        HomeWidget(
          id: 'todos_1',
          type: HomeWidgetType.todos,
          size: HomeWidgetSize.large,
          gridX: 0,
          gridY: 3,
        ),
      ],
    );
  }

  factory HomeScreenConfig.fromJson(Map<String, dynamic> json) {
    return HomeScreenConfig(
      oderId: json['user_id'] as String,
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((w) => HomeWidget.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      gridColumns: json['grid_columns'] as int? ?? 4,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': oderId,
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'grid_columns': gridColumns,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HomeScreenConfig copyWith({
    String? oderId,
    List<HomeWidget>? widgets,
    int? gridColumns,
    DateTime? updatedAt,
  }) {
    return HomeScreenConfig(
      oderId: oderId ?? this.oderId,
      widgets: widgets ?? this.widgets,
      gridColumns: gridColumns ?? this.gridColumns,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Sichtbare Widgets sortiert nach Position
  List<HomeWidget> get visibleWidgets {
    return widgets.where((w) => w.visible).toList()
      ..sort((a, b) {
        if (a.gridY != b.gridY) return a.gridY.compareTo(b.gridY);
        return a.gridX.compareTo(b.gridX);
      });
  }

  @override
  List<Object?> get props => [oderId, widgets, gridColumns, updatedAt];
}
