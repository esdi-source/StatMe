/// Widget Initializer - Registriert alle Standard-Widgets beim App-Start
/// 
/// WICHTIG: Wenn du ein neues Widget hinzufügst:
/// 1. Erstelle eine Klasse die AppWidgetDefinition implementiert
/// 2. Füge sie hier zur _registerBuiltInWidgets() Methode hinzu
/// 3. Das Widget erscheint automatisch überall in der App

import 'package:flutter/foundation.dart';
import 'widgets.dart';

/// Initialisiert das Widget-System
class WidgetSystemInitializer {
  static bool _initialized = false;
  
  /// Initialisiert das Widget-System (nur einmal aufrufen!)
  static void initialize() {
    if (_initialized) return;
    
    if (kDebugMode) {
      print('[WidgetSystem] Initializing...');
    }
    
    _registerBuiltInWidgets();
    _setupEventHandlers();
    
    _initialized = true;
    
    if (kDebugMode) {
      print('[WidgetSystem] Registered ${WidgetRegistry.instance.count} widgets');
    }
  }
  
  /// Registriert alle eingebauten Widgets
  static void _registerBuiltInWidgets() {
    // Die eigentlichen Widget-Definitionen werden später erstellt
    // Hier ist der Ort, wo sie registriert werden:
    
    // Beispiel (wird später implementiert):
    // WidgetRegistry.instance.registerAll([
    //   CaloriesWidgetDefinition(),
    //   WaterWidgetDefinition(),
    //   StepsWidgetDefinition(),
    //   SleepWidgetDefinition(),
    //   MoodWidgetDefinition(),
    //   TodosWidgetDefinition(),
    //   BooksWidgetDefinition(),
    //   TimerWidgetDefinition(),
    //   SportWidgetDefinition(), // Zukünftig
    //   MeditationWidgetDefinition(), // Zukünftig
    // ]);
    
    // Vorläufig: Wir registrieren die Widget-IDs als Platzhalter
    // Die tatsächliche Migration erfolgt schrittweise
  }
  
  /// Richtet globale Event-Handler ein
  static void _setupEventHandlers() {
    final bus = WidgetEventBus.instance;
    
    // Timer-Session-Completed Handler
    // Findet das zugehörige Widget und ruft onTimerSessionCompleted auf
    bus.on<TimerSessionCompletedEvent>((event) async {
      final registry = WidgetRegistry.instance;
      final widget = registry.tryForTimerActivity(event.activityTypeId);
      
      if (widget != null) {
        if (kDebugMode) {
          print('[WidgetSystem] Timer session completed for ${widget.id}');
          print('  Duration: ${event.durationMinutes} minutes');
        }
        
        // Das Widget kann jetzt seine eigene Logik ausführen
        // z.B. Sport-Widget: Zeit zum Wochenziel addieren
        // z.B. Lese-Widget: Lesezeit zum Buch hinzufügen
      }
    });
    
    // Daily Goal Reached Handler
    bus.on<DailyGoalReachedEvent>((event) {
      if (kDebugMode) {
        print('[WidgetSystem] Daily goal reached for ${event.sourceWidgetId}');
        print('  ${event.achievedValue} / ${event.goalValue}');
      }
      
      // Hier können Benachrichtigungen getriggert werden
      // oder Erfolge freigeschaltet werden
    });
  }
}

// ============================================================================
// WIDGET DEFINITION TEMPLATES
// ============================================================================

/// Einfache Widget-Definition für numerisches Tracking
/// Verwende diese als Basis für Widgets wie Kalorien, Wasser, Schritte
abstract class NumericTrackingWidgetDefinition extends AppWidgetDefinition {
  @override
  Set<WidgetCapability> get capabilities => {
    WidgetCapability.tracksNumericValue,
    WidgetCapability.hasDailyGoal,
    WidgetCapability.hasDashboardWidget,
    WidgetCapability.hasDetailScreen,
    WidgetCapability.hasSettings,
    WidgetCapability.appearsInStats,
    WidgetCapability.supportsQuickAdd,
  };
  
  @override
  WidgetCategory get category => WidgetCategory.health;
}

/// Widget-Definition für Timer-basiertes Tracking
/// Verwende diese als Basis für Sport, Meditation, Lesen
abstract class TimerTrackingWidgetDefinition extends AppWidgetDefinition {
  @override
  Set<WidgetCapability> get capabilities => {
    WidgetCapability.supportsTimerTracking,
    WidgetCapability.timerIntegration,
    WidgetCapability.hasWeeklyGoal,
    WidgetCapability.hasDashboardWidget,
    WidgetCapability.hasDetailScreen,
    WidgetCapability.hasStatistics,
    WidgetCapability.appearsInStats,
  };
  
  @override
  WidgetCategory get category => WidgetCategory.fitness;
}

/// Widget-Definition für Ja/Nein-Tracking
/// Verwende diese als Basis für Gewohnheiten, Checklisten
abstract class CompletionTrackingWidgetDefinition extends AppWidgetDefinition {
  @override
  Set<WidgetCapability> get capabilities => {
    WidgetCapability.tracksCompletion,
    WidgetCapability.hasDailyGoal,
    WidgetCapability.hasDashboardWidget,
    WidgetCapability.hasDetailScreen,
    WidgetCapability.appearsInStats,
  };
  
  @override
  WidgetCategory get category => WidgetCategory.productivity;
}
