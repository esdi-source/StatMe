/// MikroWidget Model - Kleine abhakbare Widgets für tägliche Gewohnheiten
/// z.B. "4x pro Woche lesen", "Täglich meditieren"

import 'package:equatable/equatable.dart';

/// Art des MikroWidgets
enum MicroWidgetType {
  reading('Lesen', 'menu_book'),
  meditation('Meditation', 'self_improvement'),
  sport('Sport', 'fitness_center'),
  water('Wasser trinken', 'water_drop'),
  custom('Eigenes Ziel', 'star');

  final String label;
  final String iconName;

  const MicroWidgetType(this.label, this.iconName);
}

/// Häufigkeit des Ziels
enum GoalFrequency {
  daily('Täglich'),
  weekly('Pro Woche'),
  monthly('Pro Monat');

  final String label;

  const GoalFrequency(this.label);
}

/// Ein MikroWidget - tägliches Abhaken für Gewohnheiten
class MicroWidgetModel extends Equatable {
  final String id;
  final String userId;
  final MicroWidgetType type;
  final String title; // z.B. "4x Lesen pro Woche"
  final int targetCount; // Wie oft pro Zeitraum (z.B. 4)
  final GoalFrequency frequency; // Täglich, wöchentlich, monatlich
  final int currentCount; // Aktueller Stand
  final List<DateTime> completedDates; // Wann abgehakt wurde
  final DateTime periodStart; // Start der aktuellen Periode
  final bool isActive;
  final DateTime createdAt;

  const MicroWidgetModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.targetCount,
    this.frequency = GoalFrequency.weekly,
    this.currentCount = 0,
    this.completedDates = const [],
    required this.periodStart,
    this.isActive = true,
    required this.createdAt,
  });

  /// Prüft ob das Ziel für heute schon abgehakt wurde
  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any((d) =>
        d.year == today.year && d.month == today.month && d.day == today.day);
  }

  /// Prüft ob das Ziel für die aktuelle Periode erreicht ist
  bool get isPeriodGoalReached => currentCount >= targetCount;

  /// Fortschritt in Prozent
  double get progressPercent =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  /// Verbleibende Abhakungen für diese Periode
  int get remainingCount => (targetCount - currentCount).clamp(0, targetCount);

  /// Formatierter Fortschritt
  String get progressText => '$currentCount / $targetCount';

  /// Prüft ob eine neue Periode begonnen hat und Reset nötig ist
  bool needsReset() {
    final now = DateTime.now();
    switch (frequency) {
      case GoalFrequency.daily:
        return now.day != periodStart.day ||
            now.month != periodStart.month ||
            now.year != periodStart.year;
      case GoalFrequency.weekly:
        final weekStart = _getWeekStart(now);
        return periodStart.isBefore(weekStart);
      case GoalFrequency.monthly:
        return now.month != periodStart.month || now.year != periodStart.year;
    }
  }

  DateTime _getWeekStart(DateTime date) {
    // Montag als Wochenstart
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  factory MicroWidgetModel.fromJson(Map<String, dynamic> json) {
    return MicroWidgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: MicroWidgetType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MicroWidgetType.custom,
      ),
      title: json['title'] as String,
      targetCount: json['target_count'] as int? ?? 1,
      frequency: GoalFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => GoalFrequency.weekly,
      ),
      currentCount: json['current_count'] as int? ?? 0,
      completedDates: (json['completed_dates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      periodStart: DateTime.parse(json['period_start'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'target_count': targetCount,
      'frequency': frequency.name,
      'current_count': currentCount,
      'completed_dates':
          completedDates.map((d) => d.toIso8601String()).toList(),
      'period_start': periodStart.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MicroWidgetModel copyWith({
    String? id,
    String? userId,
    MicroWidgetType? type,
    String? title,
    int? targetCount,
    GoalFrequency? frequency,
    int? currentCount,
    List<DateTime>? completedDates,
    DateTime? periodStart,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MicroWidgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      targetCount: targetCount ?? this.targetCount,
      frequency: frequency ?? this.frequency,
      currentCount: currentCount ?? this.currentCount,
      completedDates: completedDates ?? this.completedDates,
      periodStart: periodStart ?? this.periodStart,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Abhaken für heute
  MicroWidgetModel checkOff() {
    if (isCompletedToday || isPeriodGoalReached) {
      return this;
    }
    return copyWith(
      currentCount: currentCount + 1,
      completedDates: [...completedDates, DateTime.now()],
    );
  }

  /// Reset für neue Periode
  MicroWidgetModel resetForNewPeriod() {
    return copyWith(
      currentCount: 0,
      completedDates: [],
      periodStart: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        targetCount,
        frequency,
        currentCount,
        completedDates,
        periodStart,
        isActive,
        createdAt,
      ];
}
