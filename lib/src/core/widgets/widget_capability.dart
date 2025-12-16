/// Widget Capability System
/// 
/// Definiert die Fähigkeiten, die ein Widget haben kann.
/// Widgets können sich über Capabilities gegenseitig finden und integrieren.
/// 
/// Beispiel: Timer-Widget sucht alle Widgets mit `supportsTimerTracking`
/// und kann deren Ziele beim Beenden einer Session aktualisieren.

import 'package:flutter/foundation.dart';

/// Basis-Enum für Widget-Fähigkeiten
enum WidgetCapability {
  // ============================================
  // TRACKING CAPABILITIES
  // ============================================
  
  /// Widget kann Zeit tracken (Timer, Meditation, Sport, Lesen)
  supportsTimerTracking,
  
  /// Widget hat tägliche Ziele
  hasDailyGoal,
  
  /// Widget hat wöchentliche Ziele
  hasWeeklyGoal,
  
  /// Widget hat monatliche Ziele
  hasMonthlyGoal,
  
  /// Widget trackt numerische Werte (Kalorien, Schritte, Wasser)
  tracksNumericValue,
  
  /// Widget trackt Ja/Nein-Werte (erledigt/nicht erledigt)
  tracksCompletion,
  
  /// Widget unterstützt Bewertungen (Bücher, Filme)
  supportsRating,
  
  // ============================================
  // DATA CAPABILITIES
  // ============================================
  
  /// Widget kann Daten exportieren
  canExportData,
  
  /// Widget hat Statistiken
  hasStatistics,
  
  /// Widget unterstützt Verlaufsansicht
  hasHistory,
  
  // ============================================
  // INTEGRATION CAPABILITIES
  // ============================================
  
  /// Widget kann mit Timer verknüpft werden
  timerIntegration,
  
  /// Widget kann Benachrichtigungen senden
  supportsNotifications,
  
  /// Widget kann Quick-Add nutzen
  supportsQuickAdd,
  
  // ============================================
  // DISPLAY CAPABILITIES
  // ============================================
  
  /// Widget hat ein Dashboard-Widget
  hasDashboardWidget,
  
  /// Widget hat einen Detail-Screen
  hasDetailScreen,
  
  /// Widget hat Einstellungen
  hasSettings,
  
  /// Widget erscheint in Statistiken
  appearsInStats,
}

/// Definiert die Timer-Aktivitätstypen, die ein Widget unterstützen kann
class TimerCapabilityConfig {
  /// Der Aktivitätstyp für den Timer
  final String activityTypeId;
  
  /// Ob die Zeit auf das Tagesziel einzahlt
  final bool countsTowardsDailyGoal;
  
  /// Ob die Zeit auf das Wochenziel einzahlt
  final bool countsTowardsWeeklyGoal;
  
  /// Ob eine Session den Tag als "erledigt" markiert
  final bool completesDayOnSession;
  
  /// Minimale Session-Dauer in Minuten für Ziel-Anrechnung
  final int minimumMinutesForGoal;
  
  const TimerCapabilityConfig({
    required this.activityTypeId,
    this.countsTowardsDailyGoal = true,
    this.countsTowardsWeeklyGoal = true,
    this.completesDayOnSession = false,
    this.minimumMinutesForGoal = 1,
  });
}

/// Konfiguration für numerische Tracking-Fähigkeit
class NumericTrackingConfig {
  /// Einheit für den Wert (ml, kcal, Schritte, etc.)
  final String unit;
  
  /// Standard-Tagesziel
  final int defaultDailyGoal;
  
  /// Minimal erlaubter Wert
  final int minValue;
  
  /// Maximal erlaubter Wert pro Eintrag
  final int maxValuePerEntry;
  
  /// Inkrement für Quick-Add
  final int quickAddIncrement;
  
  const NumericTrackingConfig({
    required this.unit,
    required this.defaultDailyGoal,
    this.minValue = 0,
    this.maxValuePerEntry = 10000,
    this.quickAddIncrement = 1,
  });
}

/// Konfiguration für Goal-Tracking
class GoalTrackingConfig {
  /// Tagesziel aktiviert
  final bool hasDailyGoal;
  
  /// Wochenziel aktiviert
  final bool hasWeeklyGoal;
  
  /// Monatsziel aktiviert
  final bool hasMonthlyGoal;
  
  /// Standard-Tagesziel (wenn numerisch)
  final int? defaultDailyTarget;
  
  /// Standard-Wochenziel (wenn numerisch)
  final int? defaultWeeklyTarget;
  
  const GoalTrackingConfig({
    this.hasDailyGoal = false,
    this.hasWeeklyGoal = false,
    this.hasMonthlyGoal = false,
    this.defaultDailyTarget,
    this.defaultWeeklyTarget,
  });
}
