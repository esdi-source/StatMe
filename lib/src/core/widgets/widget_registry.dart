/// Widget Registry - Zentrale Registrierung aller App-Widgets
/// 
/// Die Registry verwaltet alle verfügbaren Widgets und ermöglicht:
/// - Dynamisches Hinzufügen neuer Widgets
/// - Suche nach Widgets mit bestimmten Capabilities
/// - Integration mit Timer, Statistiken, Einstellungen etc.
/// 
/// VERWENDUNG:
/// 1. Widget-Definition erstellen (extends AppWidgetDefinition)
/// 2. In der Registry registrieren: WidgetRegistry.register(myWidget)
/// 3. Widget ist automatisch überall verfügbar

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_definition.dart';
import 'widget_capability.dart';

/// Zentrale Widget-Registry
class WidgetRegistry {
  WidgetRegistry._();
  
  /// Singleton-Instanz
  static final WidgetRegistry instance = WidgetRegistry._();
  
  /// Alle registrierten Widgets
  final Map<String, AppWidgetDefinition> _widgets = {};
  
  /// Listener für Änderungen
  final List<void Function()> _listeners = [];
  
  // ============================================
  // REGISTRATION
  // ============================================
  
  /// Registriert ein neues Widget
  void register(AppWidgetDefinition widget) {
    if (_widgets.containsKey(widget.id)) {
      throw ArgumentError('Widget with id "${widget.id}" already registered');
    }
    _widgets[widget.id] = widget;
    _notifyListeners();
  }
  
  /// Registriert mehrere Widgets auf einmal
  void registerAll(List<AppWidgetDefinition> widgets) {
    for (final widget in widgets) {
      register(widget);
    }
  }
  
  /// Entfernt ein Widget (für dynamische Plugins)
  void unregister(String widgetId) {
    if (_widgets.remove(widgetId) != null) {
      _notifyListeners();
    }
  }
  
  // ============================================
  // QUERIES
  // ============================================
  
  /// Gibt alle registrierten Widgets zurück
  List<AppWidgetDefinition> get all => _widgets.values.toList();
  
  /// Gibt alle Widget-IDs zurück
  List<String> get allIds => _widgets.keys.toList();
  
  /// Holt ein Widget anhand der ID
  AppWidgetDefinition? get(String id) => _widgets[id];
  
  /// Prüft ob ein Widget existiert
  bool exists(String id) => _widgets.containsKey(id);
  
  /// Anzahl der registrierten Widgets
  int get count => _widgets.length;
  
  // ============================================
  // CAPABILITY-BASED QUERIES
  // ============================================
  
  /// Gibt alle Widgets mit einer bestimmten Capability zurück
  List<AppWidgetDefinition> withCapability(WidgetCapability capability) {
    return _widgets.values
        .where((w) => w.hasCapability(capability))
        .toList();
  }
  
  /// Gibt alle Widgets mit allen angegebenen Capabilities zurück
  List<AppWidgetDefinition> withAllCapabilities(Set<WidgetCapability> capabilities) {
    return _widgets.values
        .where((w) => capabilities.every((c) => w.hasCapability(c)))
        .toList();
  }
  
  /// Gibt alle Widgets mit mindestens einer der angegebenen Capabilities zurück
  List<AppWidgetDefinition> withAnyCapability(Set<WidgetCapability> capabilities) {
    return _widgets.values
        .where((w) => capabilities.any((c) => w.hasCapability(c)))
        .toList();
  }
  
  // ============================================
  // SPECIFIC QUERIES
  // ============================================
  
  /// Alle Widgets die Timer-Integration unterstützen
  List<AppWidgetDefinition> get timerIntegratedWidgets {
    return withCapability(WidgetCapability.timerIntegration);
  }
  
  /// Alle Widgets die ein Dashboard-Widget haben
  List<AppWidgetDefinition> get dashboardWidgets {
    return withCapability(WidgetCapability.hasDashboardWidget);
  }
  
  /// Alle Widgets die tägliche Ziele haben
  List<AppWidgetDefinition> get dailyGoalWidgets {
    return withCapability(WidgetCapability.hasDailyGoal);
  }
  
  /// Alle Widgets die in Statistiken erscheinen
  List<AppWidgetDefinition> get statsWidgets {
    return withCapability(WidgetCapability.appearsInStats);
  }
  
  /// Alle Widgets die Einstellungen haben
  List<AppWidgetDefinition> get settingsWidgets {
    return withCapability(WidgetCapability.hasSettings);
  }
  
  /// Alle Widgets nach Kategorie gruppiert
  Map<WidgetCategory, List<AppWidgetDefinition>> get byCategory {
    final result = <WidgetCategory, List<AppWidgetDefinition>>{};
    for (final widget in _widgets.values) {
      result.putIfAbsent(widget.category, () => []).add(widget);
    }
    return result;
  }
  
  /// Widget für eine Timer-Aktivitäts-ID finden
  AppWidgetDefinition? forTimerActivity(String activityId) {
    return _widgets.values.firstWhere(
      (w) => w.timerActivityId == activityId,
      orElse: () => throw StateError('No widget found for timer activity: $activityId'),
    );
  }
  
  /// Widget für eine Timer-Aktivitäts-ID finden (nullable)
  AppWidgetDefinition? tryForTimerActivity(String activityId) {
    try {
      return _widgets.values.firstWhere(
        (w) => w.timerActivityId == activityId,
      );
    } catch (_) {
      return null;
    }
  }
  
  // ============================================
  // LISTENERS
  // ============================================
  
  /// Fügt einen Listener hinzu
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }
  
  /// Entfernt einen Listener
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }
  
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider für die Widget-Registry
final widgetRegistryProvider = Provider<WidgetRegistry>((ref) {
  return WidgetRegistry.instance;
});

/// Provider für alle registrierten Widgets
final allWidgetsProvider = Provider<List<AppWidgetDefinition>>((ref) {
  final registry = ref.watch(widgetRegistryProvider);
  return registry.all;
});

/// Provider für Widgets mit einer bestimmten Capability
final widgetsWithCapabilityProvider = Provider.family<List<AppWidgetDefinition>, WidgetCapability>((ref, capability) {
  final registry = ref.watch(widgetRegistryProvider);
  return registry.withCapability(capability);
});

/// Provider für Timer-integrierte Widgets
final timerIntegratedWidgetsProvider = Provider<List<AppWidgetDefinition>>((ref) {
  final registry = ref.watch(widgetRegistryProvider);
  return registry.timerIntegratedWidgets;
});

/// Provider für Dashboard-Widgets
final dashboardWidgetsProvider = Provider<List<AppWidgetDefinition>>((ref) {
  final registry = ref.watch(widgetRegistryProvider);
  return registry.dashboardWidgets;
});

/// Provider für ein einzelnes Widget
final widgetDefinitionProvider = Provider.family<AppWidgetDefinition?, String>((ref, id) {
  final registry = ref.watch(widgetRegistryProvider);
  return registry.get(id);
});
