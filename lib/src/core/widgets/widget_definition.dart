/// Widget Definition - Basis-Interface für alle App-Widgets
/// 
/// Jedes Widget in der App (Kalorien, Wasser, Sport, Bücher, etc.)
/// implementiert dieses Interface, um:
/// - Im Dashboard erscheinen zu können
/// - In Statistiken integriert zu werden
/// - Mit anderen Widgets zu interagieren
/// - In Einstellungen konfiguriert zu werden
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_capability.dart';

/// Basis-Definition für ein App-Widget
abstract class AppWidgetDefinition {
  // ============================================
  // IDENTIFIKATION
  // ============================================
  
  /// Eindeutige ID des Widgets (z.B. 'calories', 'water', 'sport')
  String get id;
  
  /// Anzeigename des Widgets
  String get displayName;
  
  /// Beschreibung des Widgets
  String get description;
  
  /// Icon für das Widget
  IconData get icon;
  
  /// Primärfarbe des Widgets
  Color get primaryColor;
  
  /// Kategorie des Widgets (für Gruppierung)
  WidgetCategory get category;
  
  // ============================================
  // CAPABILITIES
  // ============================================
  
  /// Liste aller Fähigkeiten dieses Widgets
  Set<WidgetCapability> get capabilities;
  
  /// Timer-Konfiguration (wenn timerIntegration aktiviert)
  TimerCapabilityConfig? get timerConfig => null;
  
  /// Numerisches Tracking (wenn tracksNumericValue aktiviert)
  NumericTrackingConfig? get numericConfig => null;
  
  /// Goal-Tracking Konfiguration
  GoalTrackingConfig? get goalConfig => null;
  
  // ============================================
  // CAPABILITY CHECKS
  // ============================================
  
  /// Prüft ob Widget eine bestimmte Fähigkeit hat
  bool hasCapability(WidgetCapability capability) {
    return capabilities.contains(capability);
  }
  
  /// Prüft ob Widget Timer-Integration unterstützt
  bool get supportsTimer => hasCapability(WidgetCapability.timerIntegration);
  
  /// Prüft ob Widget tägliche Ziele hat
  bool get hasDailyGoal => hasCapability(WidgetCapability.hasDailyGoal);
  
  /// Prüft ob Widget ein Dashboard-Widget hat
  bool get hasDashboard => hasCapability(WidgetCapability.hasDashboardWidget);
  
  // ============================================
  // UI BUILDERS
  // ============================================
  
  /// Erstellt das Dashboard-Widget
  Widget buildDashboardWidget({
    required WidgetRef ref,
    required Size size,
    VoidCallback? onTap,
    bool isEditMode = false,
  });
  
  /// Erstellt den Detail-Screen (optional)
  Widget? buildDetailScreen(WidgetRef ref) => null;
  
  /// Erstellt die Einstellungs-Sektion (optional)
  Widget? buildSettingsSection(WidgetRef ref) => null;
  
  /// Erstellt die Statistik-Kachel (optional)
  Widget? buildStatsTile(WidgetRef ref) => null;
  
  // ============================================
  // DATA ACCESS
  // ============================================
  
  /// Gibt den aktuellen Wert zurück (für numerische Widgets)
  dynamic getCurrentValue(WidgetRef ref) => null;
  
  /// Gibt das aktuelle Ziel zurück (für Widgets mit Zielen)
  dynamic getCurrentGoal(WidgetRef ref) => null;
  
  /// Gibt den Fortschritt zurück (0.0 - 1.0)
  double getProgress(WidgetRef ref) => 0.0;
  
  /// Gibt eine Zusammenfassung für heute zurück
  String getTodaySummary(WidgetRef ref) => '';
  
  // ============================================
  // TIMER INTEGRATION
  // ============================================
  
  /// Wird aufgerufen wenn eine Timer-Session für dieses Widget beendet wird
  Future<void> onTimerSessionCompleted({
    required WidgetRef ref,
    required String sessionId,
    required int durationSeconds,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Standard: nichts tun
    // Subklassen können das überschreiben
  }
  
  /// Gibt die Timer-Aktivitäts-ID zurück (für Timer-Integration)
  String? get timerActivityId => timerConfig?.activityTypeId;
  
  // ============================================
  // QUICK ADD
  // ============================================
  
  /// Quick-Add Aktionen für dieses Widget
  List<QuickAddAction> getQuickAddActions(WidgetRef ref) => [];
  
  // ============================================
  // NOTIFICATIONS
  // ============================================
  
  /// Gibt Erinnerungs-Texte zurück (für Benachrichtigungen)
  List<String> getReminderTexts() => [];
}

/// Kategorien für Widget-Gruppierung
enum WidgetCategory {
  health('Gesundheit', Icons.favorite),
  fitness('Fitness', Icons.fitness_center),
  productivity('Produktivität', Icons.task_alt),
  leisure('Freizeit', Icons.sports_esports),
  mindfulness('Achtsamkeit', Icons.self_improvement),
  tracking('Tracking', Icons.timeline),
  other('Sonstiges', Icons.widgets);
  
  final String label;
  final IconData icon;
  const WidgetCategory(this.label, this.icon);
}

/// Eine Quick-Add Aktion
class QuickAddAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onExecute;
  
  const QuickAddAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onExecute,
  });
}

/// Datenklasse für Widget-Statistiken
class WidgetStatistics {
  final String widgetId;
  final String title;
  final double todayValue;
  final double todayGoal;
  final double weekValue;
  final double weekGoal;
  final double monthValue;
  final double monthGoal;
  final String unit;
  final List<DailyDataPoint> history;
  
  const WidgetStatistics({
    required this.widgetId,
    required this.title,
    this.todayValue = 0,
    this.todayGoal = 0,
    this.weekValue = 0,
    this.weekGoal = 0,
    this.monthValue = 0,
    this.monthGoal = 0,
    this.unit = '',
    this.history = const [],
  });
  
  double get todayProgress => todayGoal > 0 ? (todayValue / todayGoal).clamp(0.0, 1.0) : 0.0;
  double get weekProgress => weekGoal > 0 ? (weekValue / weekGoal).clamp(0.0, 1.0) : 0.0;
  double get monthProgress => monthGoal > 0 ? (monthValue / monthGoal).clamp(0.0, 1.0) : 0.0;
}

/// Ein Datenpunkt für Verlaufsdiagramme
class DailyDataPoint {
  final DateTime date;
  final double value;
  final double goal;
  
  const DailyDataPoint({
    required this.date,
    required this.value,
    this.goal = 0,
  });
  
  bool get goalReached => goal > 0 && value >= goal;
}
