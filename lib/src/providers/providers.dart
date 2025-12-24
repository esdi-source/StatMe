/// Riverpod Providers
/// Provides dependency injection and state management
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/in_memory_database.dart';
import '../services/exercise_db_service.dart';
import '../services/data_migration_service.dart';
import '../services/supabase_data_service.dart';

import 'auth_provider.dart';

// Re-export Theme Provider für einfacheren Zugriff
export '../ui/theme/theme_provider.dart';
export '../ui/theme/design_tokens.dart' show ThemePreset, ShapeStyle, DesignTokens;

// Feature Providers
export 'provider_utils.dart';
export 'auth_provider.dart';
export 'settings_provider.dart';
export 'todo_provider.dart';
export 'mood_provider.dart';
export 'food_provider.dart';
export 'water_provider.dart';
export 'steps_provider.dart';
export 'sleep_provider.dart';
export 'digestion_provider.dart';
export 'supplements_provider.dart';
export 'book_provider.dart';
export 'school_provider.dart';
export 'hair_provider.dart';
export 'household_provider.dart';
export 'media_provider.dart';
export 'recipe_provider.dart';

/// Zentrale Event-Logging Funktion für alle Provider
Future<void> _logWidgetEvent(String widgetName, String eventType, Map<String, dynamic> payload) async {
  if (AppConfig.isDemoMode) return;
  try {
    await SupabaseDataService.instance.logEvent(
      widgetName: widgetName,
      eventType: eventType,
      payload: payload,
    );
  } catch (e) {
    // Silently fail - Event-Logging soll App nicht crashen
  }
}

// ============================================
// REPOSITORY PROVIDERS
// ============================================

// Repository Providers moved to respective feature providers

// ============================================
// OPENFOODFACTS PROVIDER
// ============================================

// OpenFoodFacts Provider moved to food_provider.dart

// ============================================
// GOOGLE BOOKS PROVIDER - Moved to book_provider.dart
// ============================================

// ============================================
// BOOK PROVIDERS - Moved to book_provider.dart
// ============================================

// Auth Providers moved to auth_provider.dart

// ============================================
// SETTINGS PROVIDERS
// ============================================

// Settings Providers moved to settings_provider.dart

// ============================================
// TODO PROVIDERS
// ============================================

// Todo Providers moved to todo_provider.dart

// ============================================
// FOOD PROVIDERS - Moved to food_provider.dart
// ============================================

// ============================================
// WATER PROVIDERS - Moved to water_provider.dart
// ============================================

// ============================================
// STEPS PROVIDERS - Moved to steps_provider.dart
// ============================================

// ============================================
// SLEEP PROVIDERS - Moved to sleep_provider.dart
// ============================================


// ============================================
// MOOD PROVIDERS
// ============================================

// Mood Providers moved to mood_provider.dart



// ============================================
// HOMESCREEN CONFIG PROVIDER
// ============================================

/// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Homescreen-Konfiguration Notifier
class HomeScreenConfigNotifier extends StateNotifier<HomeScreenConfig?> {
  final String _oderId;
  SharedPreferences? _prefs;
  
  HomeScreenConfigNotifier(this._oderId) : super(null);
  
  static const _storageKey = 'homescreen_config';
  
  String get _userKey => '${_storageKey}_$_oderId';
  
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await load();
  }
  
  Future<void> load() async {
    if (_prefs == null) return;
    
    // Wenn state bereits gesetzt ist (z.B. durch Onboarding), nicht überschreiben
    if (state != null) return;
    
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = HomeScreenConfig.fromJson(json);
      } catch (e) {
        state = HomeScreenConfig.defaultLayout(_oderId);
      }
    } else {
      state = HomeScreenConfig.defaultLayout(_oderId);
      await _save();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null || state == null) return;
    await _prefs!.setString(_userKey, jsonEncode(state!.toJson()));
  }
  
  /// Widget hinzufügen
  Future<void> addWidget(HomeWidgetType type, {HomeWidgetSize size = HomeWidgetSize.small}) async {
    if (state == null) return;
    
    final newId = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Finde freie Position
    final maxY = state!.widgets.isEmpty 
        ? 0 
        : state!.widgets.map((w) => w.gridY + w.size.gridHeight).reduce((a, b) => a > b ? a : b);
    
    final newWidget = HomeWidget(
      id: newId,
      type: type,
      size: size,
      gridX: 0,
      gridY: maxY,
    );
    
    state = state!.copyWith(widgets: [...state!.widgets, newWidget]);
    await _save();
  }
  
  /// Widget entfernen
  Future<void> removeWidget(String widgetId) async {
    if (state == null) return;
    
    final widgets = state!.widgets.where((w) => w.id != widgetId).toList();
    state = state!.copyWith(widgets: widgets);
    await _save();
  }
  
  /// Widget aktualisieren (Position, Größe, etc.)
  Future<void> updateWidget(HomeWidget widget) async {
    if (state == null) return;
    
    final widgets = state!.widgets.map((w) {
      return w.id == widget.id ? widget : w;
    }).toList();
    
    state = state!.copyWith(widgets: widgets);
    await _save();
  }
  
  /// Widget-Position ändern mit Kollisionserkennung
  Future<void> moveWidget(String widgetId, int newGridX, int newGridY) async {
    if (state == null) return;
    
    final gridColumns = state!.gridColumns;
    var widgets = List<HomeWidget>.from(state!.widgets);
    
    final widgetIndex = widgets.indexWhere((w) => w.id == widgetId);
    if (widgetIndex == -1) return;
    
    var widget = widgets[widgetIndex];
    
    // Stelle sicher, dass das Widget nicht über den Rand hinausgeht
    final clampedX = newGridX.clamp(0, gridColumns - widget.size.gridWidth);
    final clampedY = newGridY.clamp(0, 99);
    
    widget = widget.copyWith(
      gridX: clampedX,
      gridY: clampedY,
    );
    widgets[widgetIndex] = widget;
    
    // Finde alle Kollisionen und verschiebe andere Widgets nach unten
    widgets = _resolveCollisions(widgets, widgetId, gridColumns);
    
    state = state!.copyWith(widgets: widgets);
    await _save();
  }
  
  /// Widget-Größe ändern mit Kollisionserkennung
  Future<void> resizeWidget(String widgetId, HomeWidgetSize newSize) async {
    if (state == null) return;
    
    final gridColumns = state!.gridColumns;
    var widgets = List<HomeWidget>.from(state!.widgets);
    
    final widgetIndex = widgets.indexWhere((w) => w.id == widgetId);
    if (widgetIndex == -1) return;
    
    var widget = widgets[widgetIndex];
    
    // Stelle sicher, dass das Widget nicht über den Rand hinausgeht
    final maxX = gridColumns - newSize.gridWidth;
    var newX = widget.gridX.clamp(0, maxX.clamp(0, gridColumns - 1));
    var newY = widget.gridY;
    
    // Aktualisiere das Widget mit der neuen Größe
    widget = widget.copyWith(
      size: newSize,
      gridX: newX,
      gridY: newY,
    );
    widgets[widgetIndex] = widget;
    
    // Finde alle Kollisionen und verschiebe andere Widgets nach unten
    widgets = _resolveCollisions(widgets, widgetId, gridColumns);
    
    state = state!.copyWith(widgets: widgets);
    await _save();
  }
  
  /// Kollisionen auflösen - verschiebt überlappende Widgets nach unten
  List<HomeWidget> _resolveCollisions(List<HomeWidget> widgets, String movedWidgetId, int gridColumns) {
    var result = List<HomeWidget>.from(widgets);
    var changed = true;
    var iterations = 0;
    const maxIterations = 50; // Schutz vor Endlosschleifen
    
    while (changed && iterations < maxIterations) {
      changed = false;
      iterations++;
      
      final movedWidget = result.firstWhere((w) => w.id == movedWidgetId);
      
      for (var i = 0; i < result.length; i++) {
        final otherWidget = result[i];
        if (otherWidget.id == movedWidgetId) continue;
        
        if (_widgetsOverlap(movedWidget, otherWidget)) {
          // Verschiebe das andere Widget unter das bewegte Widget
          final newY = movedWidget.gridY + movedWidget.size.gridHeight;
          result[i] = otherWidget.copyWith(gridY: newY);
          changed = true;
        }
      }
    }
    
    // Sortiere nach Y-Position und räume Lücken auf
    result.sort((a, b) => a.gridY.compareTo(b.gridY));
    
    return result;
  }
  
  /// Prüft, ob zwei Widgets sich überlappen
  bool _widgetsOverlap(HomeWidget a, HomeWidget b) {
    // Berechne die Grenzen von Widget A
    final aLeft = a.gridX;
    final aRight = a.gridX + a.size.gridWidth;
    final aTop = a.gridY;
    final aBottom = a.gridY + a.size.gridHeight;
    
    // Berechne die Grenzen von Widget B
    final bLeft = b.gridX;
    final bRight = b.gridX + b.size.gridWidth;
    final bTop = b.gridY;
    final bBottom = b.gridY + b.size.gridHeight;
    
    // Prüfe auf Überlappung (keine Überlappung wenn getrennt)
    final horizontalOverlap = aLeft < bRight && aRight > bLeft;
    final verticalOverlap = aTop < bBottom && aBottom > bTop;
    
    return horizontalOverlap && verticalOverlap;
  }
  
  /// Widget-Farbe ändern
  Future<void> updateWidgetColor(String widgetId, int? colorValue) async {
    if (state == null) return;
    
    final widgets = state!.widgets.map((w) {
      if (w.id == widgetId) {
        return w.copyWith(
          customColorValue: colorValue,
          clearCustomColor: colorValue == null,
        );
      }
      return w;
    }).toList();
    
    state = state!.copyWith(widgets: widgets);
    await _save();
  }
  
  /// Komplettes Layout ersetzen
  Future<void> setWidgets(List<HomeWidget> widgets) async {
    // Initialisiere prefs falls noch nicht geschehen
    _prefs ??= await SharedPreferences.getInstance();
    
    // Erstelle neuen State (auch wenn aktuell null)
    state = HomeScreenConfig(
      oderId: _oderId,
      widgets: widgets,
      gridColumns: 4,
      updatedAt: DateTime.now(),
    );
    await _save();
  }
  
  /// Auf Standard zurücksetzen
  Future<void> resetToDefault() async {
    state = HomeScreenConfig.defaultLayout(_oderId);
    await _save();
  }
}

/// Provider für Homescreen-Konfiguration
final homeScreenConfigProvider = StateNotifierProvider.family<HomeScreenConfigNotifier, HomeScreenConfig?, String>((ref, oderId) {
  final notifier = HomeScreenConfigNotifier(oderId);
  
  ref.watch(sharedPreferencesProvider).whenData((prefs) {
    notifier.init(prefs);
  });
  
  return notifier;
});

// ============================================
// IN-MEMORY DATABASE PROVIDER (Demo Mode)
// ============================================

final inMemoryDatabaseProvider = Provider<InMemoryDatabase>((ref) {
  return InMemoryDatabase();
});

// ============================================
// MICRO WIDGETS PROVIDER
// ============================================

/// MicroWidgets Notifier - Verwaltet kleine abhakbare Gewohnheits-Widgets in Supabase
class MicroWidgetsNotifier extends StateNotifier<List<MicroWidgetModel>> {
  final String _userId;
  final SupabaseClient? _client;
  
  MicroWidgetsNotifier(this._userId, this._client) : super([]);
  
  Future<void> _logWidgetEvent(String widgetName, String eventType, Map<String, dynamic> payload) async {
    try {
      await SupabaseDataService.instance.logEvent(
        widgetName: widgetName,
        eventType: eventType,
        payload: payload,
      );
    } catch (e) {
      print('Error logging widget event: $e');
    }
  }
  
  Future<void> load() async {
    if (_client == null || _userId == 'demo') {
      state = [];
      return;
    }
    
    try {
      final response = await _client
          .from('micro_widgets')
          .select()
          .eq('user_id', _userId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      
      state = await Future.wait((response as List).map((json) async {
        // Lade auch die Completions
        final completionsResponse = await _client
            .from('micro_widget_completions')
            .select()
            .eq('widget_id', json['id'])
            .order('date', ascending: false)
            .limit(30);
        
        final completedDates = (completionsResponse as List)
            .map((d) => DateTime.parse(d['date'] as String))
            .toList();
        
        return MicroWidgetModel(
          id: json['id'] as String,
          userId: _userId,
          type: MicroWidgetType.values.firstWhere(
            (t) => t.name == (json['type'] as String? ?? 'custom'),
            orElse: () => MicroWidgetType.custom,
          ),
          title: json['title'] as String? ?? 'Habit',
          targetCount: json['target_count'] as int? ?? 1,
          frequency: GoalFrequency.values.firstWhere(
            (f) => f.name == (json['frequency'] as String? ?? 'weekly'),
            orElse: () => GoalFrequency.weekly,
          ),
          currentCount: completedDates.where((d) {
            final now = DateTime.now();
            return d.year == now.year && d.month == now.month && d.day >= now.day - 7;
          }).length,
          completedDates: completedDates,
          periodStart: DateTime.tryParse(json['period_start'] as String? ?? '') ?? DateTime.now(),
          isActive: json['is_active'] as bool? ?? true,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }));
      
      // Check for period resets
      _checkAndResetPeriods();
    } catch (e) {
      print('Error loading micro widgets: $e');
      state = [];
    }
  }
  
  void _checkAndResetPeriods() {
    state = state.map((widget) {
      if (widget.needsReset()) {
        return widget.resetForNewPeriod();
      }
      return widget;
    }).toList();
  }
  
  Future<void> addWidget(MicroWidgetModel widget) async {
    state = [...state, widget];
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client.from('micro_widgets').insert({
          'id': widget.id,
          'user_id': _userId,
          'type': widget.type.name,
          'title': widget.title,
          'target_count': widget.targetCount,
          'frequency': widget.frequency.name,
          'period_start': widget.periodStart.toIso8601String(),
          'is_active': widget.isActive,
          'sort_order': state.length,
        });
        await _logWidgetEvent('micro_widgets', 'created', {
          'id': widget.id,
          'type': widget.type.name,
          'title': widget.title,
          'targetCount': widget.targetCount,
        });
      } catch (e) {
        print('Error saving micro widget: $e');
      }
    }
  }
  
  Future<void> updateWidget(MicroWidgetModel widget) async {
    state = state.map((w) => w.id == widget.id ? widget : w).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client.from('micro_widgets').update({
          'type': widget.type.name,
          'title': widget.title,
          'target_count': widget.targetCount,
          'frequency': widget.frequency.name,
        }).eq('id', widget.id);
        await _logWidgetEvent('micro_widgets', 'updated', {
          'id': widget.id,
          'title': widget.title,
        });
      } catch (e) {
        print('Error updating micro widget: $e');
      }
    }
  }
  
  Future<void> deleteWidget(String widgetId) async {
    state = state.where((w) => w.id != widgetId).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        // Lösche zuerst die Completions
        await _client.from('micro_widget_completions').delete().eq('widget_id', widgetId);
        // Dann das Widget selbst
        await _client.from('micro_widgets').delete().eq('id', widgetId);
        await _logWidgetEvent('micro_widgets', 'deleted', {'id': widgetId});
      } catch (e) {
        print('Error deleting micro widget: $e');
      }
    }
  }
  
  /// Widget abhaken (für heute)
  Future<void> checkOff(String widgetId) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final widget = state.firstWhere((w) => w.id == widgetId, orElse: () => state.first);
    
    state = state.map((w) {
      if (w.id == widgetId) {
        return w.checkOff();
      }
      return w;
    }).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client.from('micro_widget_completions').upsert({
          'user_id': _userId,
          'widget_id': widgetId,
          'date': todayDate.toIso8601String().split('T')[0],
        });
        await _logWidgetEvent('micro_widgets', 'checked_off', {
          'widget_id': widgetId,
          'title': widget.title,
          'type': widget.type.name,
          'date': todayDate.toIso8601String().split('T')[0],
        });
      } catch (e) {
        print('Error checking off micro widget: $e');
      }
    }
  }
}

/// MicroWidgets Provider - Supabase-basiert
final microWidgetsProvider = StateNotifierProvider<MicroWidgetsNotifier, List<MicroWidgetModel>>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  final userId = user?.id ?? 'demo';
  
  final client = AppConfig.isDemoMode ? null : Supabase.instance.client;
  final notifier = MicroWidgetsNotifier(userId, client);
  
  // Auto-load beim Erstellen
  if (user != null) {
    notifier.load();
  }
  
  return notifier;
});

// ============================================
// SCHOOL PROVIDERS - Moved to school_provider.dart
// ============================================




// ============================================
// SPORT PROVIDERS
// ============================================

/// Sport Repository Provider
final sportRepositoryProvider = Provider<SportRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSportRepository();
  }
  return SupabaseSportRepository(Supabase.instance.client);
});

/// Sport Types Notifier
class SportTypesNotifier extends StateNotifier<List<SportType>> {
  final SportRepository _repository;
  String? _userId;

  SportTypesNotifier(this._repository) : super([]);

  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSportTypes(userId);
  }

  Future<SportType> add(SportType type) async {
    final created = await _repository.addSportType(type);
    state = [...state, created];
    return created;
  }
}

final sportTypesNotifierProvider = StateNotifierProvider<SportTypesNotifier, List<SportType>>((ref) {
  final repository = ref.watch(sportRepositoryProvider);
  return SportTypesNotifier(repository);
});

/// Sport Sessions Notifier
class SportSessionsNotifier extends StateNotifier<List<SportSession>> {
  final SportRepository _repository;
  String? _userId;
  
  SportSessionsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSportSessions(userId);
  }
  
  List<SportSession> getForDate(DateTime date) {
    return state.where((s) {
      return s.date.year == date.year &&
             s.date.month == date.month &&
             s.date.day == date.day;
    }).toList();
  }
  
  List<SportSession> getForDateRange(DateTime start, DateTime end) {
    return state.where((s) {
      return s.date.isAfter(start.subtract(const Duration(days: 1))) &&
             s.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  Duration getTotalDurationForWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final sessions = getForDateRange(startOfWeek, now);
    return sessions.fold(Duration.zero, (sum, s) => sum + s.duration);
  }
  
  int getTotalCaloriesForWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final sessions = getForDateRange(startOfWeek, now);
    return sessions.fold(0, (sum, s) => sum + (s.caloriesBurned ?? 0));
  }
  
  Future<SportSession> add(SportSession session) async {
    final created = await _repository.addSportSession(session);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SportSession session) async {
    await _repository.updateSportSession(session);
    state = state.map((s) => s.id == session.id ? session : s).toList();
  }
  
  Future<void> delete(String sessionId) async {
    await _repository.deleteSportSession(sessionId);
    state = state.where((s) => s.id != sessionId).toList();
  }
}

final sportSessionsNotifierProvider = StateNotifierProvider<SportSessionsNotifier, List<SportSession>>((ref) {
  final repository = ref.watch(sportRepositoryProvider);
  return SportSessionsNotifier(repository);
});

/// Weight Entries Notifier
class WeightNotifier extends StateNotifier<List<WeightEntry>> {
  final SportRepository _repository;
  String? _userId;
  
  WeightNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getWeightEntries(userId);
  }
  
  WeightEntry? get latest {
    if (state.isEmpty) return null;
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }
  
  List<WeightEntry> getForRange(DateTime start, DateTime end) {
    return state.where((w) {
      return w.date.isAfter(start.subtract(const Duration(days: 1))) &&
             w.date.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
  
  double? getTrend() {
    if (state.length < 2) return null;
    final sorted = [...state]..sort((a, b) => a.date.compareTo(b.date));
    final latest = sorted.last.weightKg;
    final previous = sorted[sorted.length - 2].weightKg;
    return latest - previous;
  }
  
  Future<WeightEntry> add(WeightEntry entry) async {
    final created = await _repository.addWeightEntry(entry);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(WeightEntry entry) async {
    await _repository.updateWeightEntry(entry);
    state = state.map((w) => w.id == entry.id ? entry : w).toList();
  }
  
  Future<void> delete(String entryId) async {
    await _repository.deleteWeightEntry(entryId);
    state = state.where((w) => w.id != entryId).toList();
  }
}

final weightNotifierProvider = StateNotifierProvider<WeightNotifier, List<WeightEntry>>((ref) {
  final repository = ref.watch(sportRepositoryProvider);
  return WeightNotifier(repository);
});

/// Sport Streak Provider
final sportStreakProvider = Provider<SportStreak>((ref) {
  final sessions = ref.watch(sportSessionsNotifierProvider);
  return _calculateStreak(sessions);
});

SportStreak _calculateStreak(List<SportSession> sessions) {
  if (sessions.isEmpty) {
    return const SportStreak(currentStreak: 0, longestStreak: 0);
  }
  
  // Get unique dates with sport
  final dates = sessions.map((s) {
    return DateTime(s.date.year, s.date.month, s.date.day);
  }).toSet().toList()..sort((a, b) => b.compareTo(a));
  
  if (dates.isEmpty) {
    return const SportStreak(currentStreak: 0, longestStreak: 0);
  }
  
  // Calculate current streak
  int currentStreak = 0;
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  
  // Check if today or yesterday has a session
  final hasToday = dates.any((d) => d == todayDate);
  final hasYesterday = dates.any((d) => d == todayDate.subtract(const Duration(days: 1)));
  
  if (hasToday || hasYesterday) {
    DateTime checkDate = hasToday ? todayDate : todayDate.subtract(const Duration(days: 1));
    
    while (dates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
  }
  
  // Calculate longest streak
  int longestStreak = 0;
  int tempStreak = 1;
  
  for (int i = 0; i < dates.length - 1; i++) {
    final diff = dates[i].difference(dates[i + 1]).inDays;
    if (diff == 1) {
      tempStreak++;
    } else {
      longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
      tempStreak = 1;
    }
  }
  longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
  
  return SportStreak(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActivityDate: dates.isNotEmpty ? dates.first : null,
  );
}

/// Sport Stats Provider (aggregated by sport type)
final sportStatsProvider = Provider<List<SportStats>>((ref) {
  final sessions = ref.watch(sportSessionsNotifierProvider);
  return _calculateSportStats(sessions);
});

List<SportStats> _calculateSportStats(List<SportSession> sessions) {
  final Map<String, List<SportSession>> byType = {};
  
  for (final session in sessions) {
    final typeName = session.sportTypeName ?? 'Unbekannt';
    byType.putIfAbsent(typeName, () => []).add(session);
  }
  
  return byType.entries.map((entry) {
    final typeSessions = entry.value;
    final totalDuration = typeSessions.fold<Duration>(
      Duration.zero, (sum, s) => sum + s.duration);
    final totalCalories = typeSessions.fold<int>(
      0, (sum, s) => sum + (s.caloriesBurned ?? 0));
    
    return SportStats(
      sportType: entry.key,
      totalDuration: totalDuration,
      totalCalories: totalCalories,
      sessionCount: typeSessions.length,
      averageIntensity: typeSessions.isEmpty ? 0 : 
        typeSessions.map((s) => s.intensity.value).reduce((a, b) => a + b) / typeSessions.length,
    );
  }).toList()..sort((a, b) => b.totalDuration.compareTo(a.totalDuration));
}

// ============================================
// ÜBUNGSDATENBANK (EXERCISE DATABASE) PROVIDERS
// ============================================

/// Alle Übungen Provider
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  return ExerciseDbService.getAllExercises();
});

/// Übungs-Suche Provider
final exerciseSearchProvider = FutureProvider.family<List<Exercise>, String>((ref, query) async {
  if (query.isEmpty) return ExerciseDbService.getAllExercises();
  return ExerciseDbService.searchExercises(query);
});

/// Übungen nach Muskelgruppe Provider
final exercisesByMuscleProvider = FutureProvider.family<List<Exercise>, String>((ref, muscleId) async {
  return ExerciseDbService.getExercisesByMuscle(muscleId);
});

/// Übungen nach Kategorie Provider
final exercisesByCategoryProvider = FutureProvider.family<List<Exercise>, ExerciseCategory>((ref, category) async {
  return ExerciseDbService.getExercisesByCategory(category);
});

// ============================================
// TRAININGSPLÄNE (WORKOUT PLANS) PROVIDERS
// ============================================

/// Workout Plans Notifier - Verwaltet Trainingspläne
class WorkoutPlansNotifier extends StateNotifier<List<WorkoutPlan>> {
  final SharedPreferences _prefs;
  final String _userId;
  static const String _storageKey = 'workout_plans_';

  WorkoutPlansNotifier(this._prefs, this._userId) : super([]) {
    _load();
  }

  void _load() {
    final data = _prefs.getStringList('$_storageKey$_userId');
    if (data != null) {
      try {
        state = data
            .map((json) => WorkoutPlan.fromJson(jsonDecode(json)))
            .toList();
      } catch (e) {
        debugPrint('Fehler beim Laden der Trainingspläne: $e');
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final data = state.map((plan) => jsonEncode(plan.toJson())).toList();
    await _prefs.setStringList('$_storageKey$_userId', data);
  }

  /// Fügt neuen Trainingsplan hinzu
  Future<void> add(WorkoutPlan plan) async {
    state = [...state, plan];
    await _save();
  }

  /// Aktualisiert bestehenden Plan
  Future<void> update(WorkoutPlan plan) async {
    state = state.map((p) => p.id == plan.id ? plan : p).toList();
    await _save();
  }

  /// Löscht einen Plan
  Future<void> delete(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }

  /// Plan duplizieren
  Future<WorkoutPlan> duplicate(String id) async {
    final original = state.firstWhere((p) => p.id == id);
    final copy = original.copyWith(
      id: const Uuid().v4(),
      name: '${original.name} (Kopie)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await add(copy);
    return copy;
  }

  /// Alle Pläne eines bestimmten Typs
  List<WorkoutPlan> byType(WorkoutPlanType type) {
    return state.where((p) => p.type == type).toList();
  }
}

/// Workout Plans Provider
final workoutPlansNotifierProvider = StateNotifierProvider<WorkoutPlansNotifier, List<WorkoutPlan>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final user = ref.watch(authNotifierProvider).valueOrNull;
  final userId = user?.id ?? 'demo_user';
  return WorkoutPlansNotifier(prefs.value!, userId);
});

/// Muskel-Analyse Provider - berechnet trainierte Muskelgruppen
final muscleAnalysisProvider = Provider<MuscleAnalysis>((ref) {
  final plans = ref.watch(workoutPlansNotifierProvider);
  final sessions = ref.watch(sportSessionsNotifierProvider);
  return MuscleAnalysis.calculate(plans, sessions);
});

/// Provider für Trainingsplan nach ID
final workoutPlanByIdProvider = Provider.family<WorkoutPlan?, String>((ref, id) {
  final plans = ref.watch(workoutPlansNotifierProvider);
  try {
    return plans.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

/// Provider für Pläne nach Typ
final workoutPlansByTypeProvider = Provider.family<List<WorkoutPlan>, WorkoutPlanType>((ref, type) {
  final plans = ref.watch(workoutPlansNotifierProvider);
  return plans.where((p) => p.type == type).toList();
});

// ============================================
// SKIN (GESICHTSHAUT) PROVIDERS
// ============================================

/// Skin Repository Provider
final skinRepositoryProvider = Provider<SkinRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSkinRepository();
  }
  return SupabaseSkinRepository(Supabase.instance.client);
});

/// Skin Entries Notifier
class SkinEntriesNotifier extends StateNotifier<List<SkinEntry>> {
  final SkinRepository _repository;
  String? _userId;
  
  SkinEntriesNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSkinEntries(userId);
  }
  
  SkinEntry? getForDate(DateTime date) {
    return state.cast<SkinEntry?>().firstWhere(
      (e) => e != null && 
             e.date.year == date.year &&
             e.date.month == date.month &&
             e.date.day == date.day,
      orElse: () => null,
    );
  }
  
  List<SkinEntry> getForRange(DateTime start, DateTime end) {
    return state.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
             e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
  
  double? getAverageCondition(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final entries = getForRange(start, now);
    if (entries.isEmpty) return null;
    return entries.map((e) => e.overallCondition.value).reduce((a, b) => a + b) / entries.length;
  }
  
  Future<SkinEntry> add(SkinEntry entry) async {
    final created = await _repository.upsertSkinEntry(entry);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SkinEntry entry) async {
    await _repository.upsertSkinEntry(entry);
    state = state.map((e) => e.id == entry.id ? entry : e).toList();
  }
  
  Future<void> delete(String entryId) async {
    await _repository.deleteSkinEntry(entryId);
    state = state.where((e) => e.id != entryId).toList();
  }
}

final skinEntriesNotifierProvider = StateNotifierProvider<SkinEntriesNotifier, List<SkinEntry>>((ref) {
  final repository = ref.watch(skinRepositoryProvider);
  return SkinEntriesNotifier(repository);
});

/// Skin Care Steps Notifier (Pflegeroutine)
class SkinCareStepsNotifier extends StateNotifier<List<SkinCareStep>> {
  final SkinRepository _repository;
  String? _userId;
  
  SkinCareStepsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSkinCareSteps(userId);
  }
  
  List<SkinCareStep> get dailySteps => state.where((s) => s.isDaily).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  
  List<SkinCareStep> get occasionalSteps => state.where((s) => !s.isDaily).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  
  Future<SkinCareStep> add(SkinCareStep step) async {
    final created = await _repository.addSkinCareStep(step);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SkinCareStep step) async {
    await _repository.updateSkinCareStep(step);
    state = state.map((s) => s.id == step.id ? step : s).toList();
  }
  
  Future<void> reorder(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final step = state.firstWhere((s) => s.id == orderedIds[i]);
      if (step.order != i) {
        final updated = step.copyWith(order: i);
        await update(updated);
      }
    }
  }
  
  Future<void> delete(String stepId) async {
    await _repository.deleteSkinCareStep(stepId);
    state = state.where((s) => s.id != stepId).toList();
  }
}

final skinCareStepsNotifierProvider = StateNotifierProvider<SkinCareStepsNotifier, List<SkinCareStep>>((ref) {
  final repository = ref.watch(skinRepositoryProvider);
  return SkinCareStepsNotifier(repository);
});

/// Skin Products Notifier
class SkinProductsNotifier extends StateNotifier<List<SkinProduct>> {
  final SkinRepository _repository;
  String? _userId;
  
  SkinProductsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSkinProducts(userId);
  }
  
  List<SkinProduct> getByCategory(SkinProductCategory category) {
    return state.where((p) => p.category == category).toList();
  }
  
  Future<SkinProduct> add(SkinProduct product) async {
    final created = await _repository.addSkinProduct(product);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SkinProduct product) async {
    await _repository.updateSkinProduct(product);
    state = state.map((p) => p.id == product.id ? product : p).toList();
  }
  
  Future<void> delete(String productId) async {
    await _repository.deleteSkinProduct(productId);
    state = state.where((p) => p.id != productId).toList();
  }
}

final skinProductsNotifierProvider = StateNotifierProvider<SkinProductsNotifier, List<SkinProduct>>((ref) {
  final repository = ref.watch(skinRepositoryProvider);
  return SkinProductsNotifier(repository);
});

/// Skin Notes Notifier
class SkinNotesNotifier extends StateNotifier<List<SkinNote>> {
  final SkinRepository _repository;
  String? _userId;
  
  SkinNotesNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSkinNotes(userId);
  }
  
  List<SkinNote> getRecent(int count) {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }
  
  Future<SkinNote> add(SkinNote note) async {
    final created = await _repository.addSkinNote(note);
    state = [...state, created];
    return created;
  }
  
  Future<void> delete(String noteId) async {
    await _repository.deleteSkinNote(noteId);
    state = state.where((n) => n.id != noteId).toList();
  }
}

final skinNotesNotifierProvider = StateNotifierProvider<SkinNotesNotifier, List<SkinNote>>((ref) {
  final repository = ref.watch(skinRepositoryProvider);
  return SkinNotesNotifier(repository);
});

/// Skin Photos Notifier
class SkinPhotosNotifier extends StateNotifier<List<SkinPhoto>> {
  final SkinRepository _repository;
  String? _userId;
  
  SkinPhotosNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSkinPhotos(userId);
  }
  
  List<SkinPhoto> getRecent(int count) {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }
  
  List<SkinPhoto> getForRange(DateTime start, DateTime end) {
    return state.where((p) {
      return p.date.isAfter(start.subtract(const Duration(days: 1))) &&
             p.date.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
  
  Future<SkinPhoto> add(SkinPhoto photo) async {
    final created = await _repository.addSkinPhoto(photo);
    state = [...state, created];
    return created;
  }
  
  Future<void> delete(String photoId) async {
    await _repository.deleteSkinPhoto(photoId);
    state = state.where((p) => p.id != photoId).toList();
  }
}

final skinPhotosNotifierProvider = StateNotifierProvider<SkinPhotosNotifier, List<SkinPhoto>>((ref) {
  final repository = ref.watch(skinRepositoryProvider);
  return SkinPhotosNotifier(repository);
});

/// Skin Care Completions Notifier (Abhaken der Pflegeroutine)
class SkinCareCompletionsNotifier extends StateNotifier<List<SkinCareCompletion>> {
  final SkinRepository _repository;
  String? _userId;
  DateTime _currentDate = DateTime.now();
  
  SkinCareCompletionsNotifier(this._repository) : super([]);
  
  Future<void> loadForDate(String userId, DateTime date) async {
    _userId = userId;
    _currentDate = DateTime(date.year, date.month, date.day);
    state = await _repository.getCompletionsForDate(userId, _currentDate);
  }
  
  bool isCompleted(String stepId) {
    return state.any((c) => c.stepId == stepId);
  }
  
  Future<void> toggle(String stepId) async {
    final userId = _userId;
    if (userId == null) return;
    
    final existing = state.where((c) => c.stepId == stepId).firstOrNull;
    
    if (existing != null) {
      // Remove completion
      await _repository.deleteCompletion(existing.id);
      state = state.where((c) => c.id != existing.id).toList();
    } else {
      // Add completion
      final completion = SkinCareCompletion(
        id: 'completion_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        stepId: stepId,
        date: _currentDate,
        completedAt: DateTime.now(),
      );
      final created = await _repository.addCompletion(completion);
      state = [...state, created];
    }
  }
}

final skinCareCompletionsNotifierProvider = StateNotifierProvider<SkinCareCompletionsNotifier, List<SkinCareCompletion>>((ref) {
  final repository = ref.watch(skinRepositoryProvider);
  return SkinCareCompletionsNotifier(repository);
});

/// Auto Migration Provider
final autoMigrationProvider = FutureProvider.family<void, String>((ref, userId) async {
  if (AppConfig.isDemoMode) return;
  
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final service = DataMigrationService(Supabase.instance.client, prefs);
  
  if (service.needsMigration(userId)) {
    await service.migrateAllData(userId);
  }
});




