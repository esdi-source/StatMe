/// Riverpod Providers
/// Provides dependency injection and state management

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../models/home_widget_model.dart';
import '../models/micro_widget_model.dart';
import '../models/timer_widget_model.dart';
import '../repositories/repositories.dart';
import '../services/in_memory_database.dart';
import '../services/openfoodfacts_service.dart';
import '../services/google_books_service.dart';

// Re-export Theme Provider für einfacheren Zugriff
export '../ui/theme/theme_provider.dart';
export '../ui/theme/design_tokens.dart' show ThemePreset, ShapeStyle, DesignTokens;

// ============================================
// REPOSITORY PROVIDERS
// ============================================

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoAuthRepository();
  }
  return SupabaseAuthRepository(Supabase.instance.client);
});

/// Settings Repository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSettingsRepository();
  }
  return SupabaseSettingsRepository(Supabase.instance.client);
});

/// Todo Repository Provider
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoTodoRepository();
  }
  return SupabaseTodoRepository(Supabase.instance.client);
});

/// Food Repository Provider
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoFoodRepository();
  }
  return SupabaseFoodRepository(Supabase.instance.client);
});

/// Water Repository Provider
final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoWaterRepository();
  }
  return SupabaseWaterRepository(Supabase.instance.client);
});

/// Steps Repository Provider
final stepsRepositoryProvider = Provider<StepsRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoStepsRepository();
  }
  return SupabaseStepsRepository(Supabase.instance.client);
});

/// Sleep Repository Provider
final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSleepRepository();
  }
  return SupabaseSleepRepository(Supabase.instance.client);
});

/// Mood Repository Provider
final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoMoodRepository();
  }
  return SupabaseMoodRepository(Supabase.instance.client);
});

// ============================================
// OPENFOODFACTS PROVIDER
// ============================================

/// OpenFoodFacts Service Provider
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoOpenFoodFactsService();
  }
  return OpenFoodFactsService();
});

/// Provider für Produkt-Suche per Barcode
final productByBarcodeProvider = FutureProvider.family<OpenFoodFactsProduct, String>((ref, barcode) async {
  final service = ref.watch(openFoodFactsServiceProvider);
  return service.getProductByBarcode(barcode);
});

/// Provider für Produkt-Suche per Name
final productSearchProvider = FutureProvider.family<List<OpenFoodFactsProduct>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.watch(openFoodFactsServiceProvider);
  return service.searchProducts(query);
});

// ============================================
// GOOGLE BOOKS PROVIDER
// ============================================

/// Google Books Service Provider
final googleBooksServiceProvider = Provider<GoogleBooksService>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoGoogleBooksService();
  }
  return GoogleBooksService();
});

/// Book Repository Provider
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoBookRepository();
  }
  // TODO: Implement SupabaseBookRepository when needed
  return DemoBookRepository();
});

// ============================================
// AUTH STATE PROVIDERS
// ============================================

/// Current User Provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

/// Auth State Notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;
  
  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _init();
  }
  
  Future<void> _init() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  
  Future<void> signUp(String email, String password, String? displayName) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUp(email, password, displayName);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// ============================================
// SETTINGS PROVIDERS
// ============================================

final settingsProvider = FutureProvider.family<SettingsModel?, String>((ref, userId) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings(userId);
});

class SettingsNotifier extends StateNotifier<SettingsModel?> {
  final SettingsRepository _repository;
  
  SettingsNotifier(this._repository) : super(null);
  
  Future<void> load(String userId) async {
    state = await _repository.getSettings(userId);
  }
  
  Future<void> update(SettingsModel settings) async {
    state = await _repository.updateSettings(settings);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsModel?>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

// ============================================
// THEME COLOR PROVIDER
// ============================================

/// Provider für die aktuelle Theme-Farbe
final themeColorProvider = StateProvider<Color>((ref) {
  // Default Sage (Salbei) - passend zu den neuen Pastell-Farben
  return const Color(0xFFB2C9AD);
});

/// Provider der die Theme-Farbe aus den Settings synchronisiert
final themeColorFromSettingsProvider = Provider<Color>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  if (settings != null && settings.themeColorValue != 0) {
    return Color(settings.themeColorValue);
  }
  return const Color(0xFFB2C9AD);
});

// ============================================
// TODO PROVIDERS
// ============================================

final todosProvider = FutureProvider.family<List<TodoModel>, String>((ref, userId) async {
  final repo = ref.watch(todoRepositoryProvider);
  return await repo.getTodos(userId);
});

final todayOccurrencesProvider = FutureProvider.family<List<TodoOccurrence>, String>((ref, userId) async {
  final repo = ref.watch(todoRepositoryProvider);
  return await repo.getOccurrencesForDate(userId, DateTime.now());
});

class TodoNotifier extends StateNotifier<List<TodoModel>> {
  final TodoRepository _repository;
  
  TodoNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    state = await _repository.getTodos(userId);
  }
  
  Future<void> create(TodoModel todo) async {
    final created = await _repository.createTodo(todo);
    state = [...state, created];
  }
  
  Future<void> update(TodoModel todo) async {
    final updated = await _repository.updateTodo(todo);
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
  }
  
  Future<void> delete(String todoId) async {
    await _repository.deleteTodo(todoId);
    state = state.where((t) => t.id != todoId).toList();
  }
}

final todoNotifierProvider = StateNotifierProvider<TodoNotifier, List<TodoModel>>((ref) {
  return TodoNotifier(ref.watch(todoRepositoryProvider));
});

// ============================================
// FOOD PROVIDERS
// ============================================

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final foodLogsProvider = FutureProvider.family<List<FoodLogModel>, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(foodRepositoryProvider);
  return await repo.getFoodLogs(params.userId, params.date);
});

final localProductSearchProvider = FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(foodRepositoryProvider);
  return await repo.searchProducts(query);
});

class FoodLogNotifier extends StateNotifier<List<FoodLogModel>> {
  final FoodRepository _repository;
  
  FoodLogNotifier(this._repository) : super([]);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getFoodLogs(userId, date);
  }
  
  Future<void> add(FoodLogModel log) async {
    final added = await _repository.addFoodLog(log);
    state = [...state, added];
  }
  
  Future<void> delete(String logId) async {
    await _repository.deleteFoodLog(logId);
    state = state.where((f) => f.id != logId).toList();
  }
  
  double get totalCalories => state.fold(0, (sum, log) => sum + log.calories);
}

final foodLogNotifierProvider = StateNotifierProvider<FoodLogNotifier, List<FoodLogModel>>((ref) {
  return FoodLogNotifier(ref.watch(foodRepositoryProvider));
});

// ============================================
// WATER PROVIDERS
// ============================================

final waterLogsProvider = FutureProvider.family<List<WaterLogModel>, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(waterRepositoryProvider);
  return await repo.getWaterLogs(params.userId, params.date);
});

final totalWaterProvider = FutureProvider.family<int, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(waterRepositoryProvider);
  return await repo.getTotalWater(params.userId, params.date);
});

class WaterLogNotifier extends StateNotifier<List<WaterLogModel>> {
  final WaterRepository _repository;
  
  WaterLogNotifier(this._repository) : super([]);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getWaterLogs(userId, date);
  }
  
  Future<void> add(WaterLogModel log) async {
    final added = await _repository.addWaterLog(log);
    state = [...state, added];
  }
  
  Future<void> delete(String logId) async {
    await _repository.deleteWaterLog(logId);
    state = state.where((w) => w.id != logId).toList();
  }
  
  int get totalMl => state.fold(0, (sum, log) => sum + log.ml);
}

final waterLogNotifierProvider = StateNotifierProvider<WaterLogNotifier, List<WaterLogModel>>((ref) {
  return WaterLogNotifier(ref.watch(waterRepositoryProvider));
});

// ============================================
// STEPS PROVIDERS
// ============================================

final stepsProvider = FutureProvider.family<StepsLogModel?, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(stepsRepositoryProvider);
  return await repo.getSteps(params.userId, params.date);
});

final stepsRangeProvider = FutureProvider.family<List<StepsLogModel>, ({String userId, DateTime start, DateTime end})>((ref, params) async {
  final repo = ref.watch(stepsRepositoryProvider);
  return await repo.getStepsRange(params.userId, params.start, params.end);
});

class StepsNotifier extends StateNotifier<StepsLogModel?> {
  final StepsRepository _repository;
  
  StepsNotifier(this._repository) : super(null);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getSteps(userId, date);
  }
  
  Future<void> upsert(StepsLogModel log) async {
    state = await _repository.upsertSteps(log);
  }
}

final stepsNotifierProvider = StateNotifierProvider<StepsNotifier, StepsLogModel?>((ref) {
  return StepsNotifier(ref.watch(stepsRepositoryProvider));
});

// ============================================
// SLEEP PROVIDERS
// ============================================

final sleepProvider = FutureProvider.family<SleepLogModel?, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return await repo.getSleep(params.userId, params.date);
});

final sleepRangeProvider = FutureProvider.family<List<SleepLogModel>, ({String userId, DateTime start, DateTime end})>((ref, params) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return await repo.getSleepRange(params.userId, params.start, params.end);
});

class SleepNotifier extends StateNotifier<SleepLogModel?> {
  final SleepRepository _repository;
  
  SleepNotifier(this._repository) : super(null);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getSleep(userId, date);
  }
  
  Future<void> add(SleepLogModel log) async {
    state = await _repository.addSleep(log);
  }
  
  Future<void> delete(String logId) async {
    await _repository.deleteSleep(logId);
    state = null;
  }
}

final sleepNotifierProvider = StateNotifierProvider<SleepNotifier, SleepLogModel?>((ref) {
  return SleepNotifier(ref.watch(sleepRepositoryProvider));
});

// ============================================
// MOOD PROVIDERS
// ============================================

final moodProvider = FutureProvider.family<MoodLogModel?, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(moodRepositoryProvider);
  return await repo.getMood(params.userId, params.date);
});

final moodRangeProvider = FutureProvider.family<List<MoodLogModel>, ({String userId, DateTime start, DateTime end})>((ref, params) async {
  final repo = ref.watch(moodRepositoryProvider);
  return await repo.getMoodRange(params.userId, params.start, params.end);
});

class MoodNotifier extends StateNotifier<MoodLogModel?> {
  final MoodRepository _repository;
  
  MoodNotifier(this._repository) : super(null);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getMood(userId, date);
  }
  
  Future<void> upsert(MoodLogModel log) async {
    state = await _repository.upsertMood(log);
  }
}

final moodNotifierProvider = StateNotifierProvider<MoodNotifier, MoodLogModel?>((ref) {
  return MoodNotifier(ref.watch(moodRepositoryProvider));
});

/// Mood History Notifier for statistics
class MoodHistoryNotifier extends StateNotifier<List<MoodLogModel>> {
  final MoodRepository _repository;
  
  MoodHistoryNotifier(this._repository) : super([]);
  
  Future<void> loadRange(String userId, DateTime start, DateTime end) async {
    state = await _repository.getMoodRange(userId, start, end);
  }
}

final moodHistoryProvider = StateNotifierProvider<MoodHistoryNotifier, List<MoodLogModel>>((ref) {
  return MoodHistoryNotifier(ref.watch(moodRepositoryProvider));
});

// ============================================
// BOOK PROVIDERS
// ============================================

/// Book Notifier for managing user's book library
class BookNotifier extends StateNotifier<List<BookModel>> {
  final BookRepository _repository;
  
  BookNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    state = await _repository.getBooks(userId);
  }
  
  Future<void> addBook(BookModel book) async {
    final newBook = await _repository.addBook(book);
    state = [...state, newBook];
  }
  
  Future<void> updateBook(BookModel book) async {
    final updated = await _repository.updateBook(book);
    state = state.map((b) => b.id == book.id ? updated : b).toList();
  }
  
  Future<void> deleteBook(String bookId) async {
    await _repository.deleteBook(bookId);
    state = state.where((b) => b.id != bookId).toList();
  }
}

final bookNotifierProvider = StateNotifierProvider<BookNotifier, List<BookModel>>((ref) {
  return BookNotifier(ref.watch(bookRepositoryProvider));
});

/// Reading Goal Notifier
class ReadingGoalNotifier extends StateNotifier<ReadingGoalModel?> {
  final BookRepository _repository;
  
  ReadingGoalNotifier(this._repository) : super(null);
  
  Future<void> load(String userId) async {
    state = await _repository.getReadingGoal(userId);
    
    // Create default goal if none exists
    if (state == null) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      state = ReadingGoalModel(
        id: userId,
        oderId: userId,
        weeklyGoalMinutes: 240, // 4 hours default
        readMinutesThisWeek: 0,
        weekStartDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      );
      await _repository.upsertReadingGoal(state!);
    }
  }
  
  Future<void> updateGoal(ReadingGoalModel goal) async {
    state = await _repository.upsertReadingGoal(goal);
  }
  
  Future<void> addReadingSession(String oderId, ReadingSession session) async {
    await _repository.addReadingSession(oderId, session);
    // Reload to get updated state
    await load(oderId);
  }
}

final readingGoalNotifierProvider = StateNotifierProvider<ReadingGoalNotifier, ReadingGoalModel?>((ref) {
  return ReadingGoalNotifier(ref.watch(bookRepositoryProvider));
});

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
// TIMER SESSIONS PROVIDER
// ============================================

/// Timer Sessions Notifier - Verwaltet Timer-Sessions für alle Aktivitäten
class TimerSessionsNotifier extends StateNotifier<List<TimerSessionModel>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  TimerSessionsNotifier(this._userId) : super([]);
  
  static const _storageKey = 'timer_sessions';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await load();
  }
  
  Future<void> load() async {
    if (_prefs == null) return;
    
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        state = jsonList
            .map((j) => TimerSessionModel.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (e) {
        state = [];
      }
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) return;
    final jsonList = state.map((s) => s.toJson()).toList();
    await _prefs!.setString(_userKey, jsonEncode(jsonList));
  }
  
  Future<void> addSession(TimerSessionModel session) async {
    state = [session, ...state];
    await _save();
  }
  
  Future<void> deleteSession(String sessionId) async {
    state = state.where((s) => s.id != sessionId).toList();
    await _save();
  }
  
  /// Alle Sessions für eine Aktivität
  List<TimerSessionModel> getSessionsForActivity(TimerActivityType type) {
    return state.where((s) => s.activityType == type).toList();
  }
  
  /// Sessions für einen Zeitraum
  List<TimerSessionModel> getSessionsInRange(DateTime start, DateTime end) {
    return state.where((s) => 
        s.startTime.isAfter(start) && s.startTime.isBefore(end)
    ).toList();
  }
}

/// Timer Sessions Provider
final timerSessionsProvider = StateNotifierProvider<TimerSessionsNotifier, List<TimerSessionModel>>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  final userId = user?.id ?? 'demo';
  final notifier = TimerSessionsNotifier(userId);
  
  ref.watch(sharedPreferencesProvider).whenData((prefs) {
    notifier.init(prefs);
  });
  
  return notifier;
});

// ============================================
// MICRO WIDGETS PROVIDER
// ============================================

/// MicroWidgets Notifier - Verwaltet kleine abhakbare Gewohnheits-Widgets
class MicroWidgetsNotifier extends StateNotifier<List<MicroWidgetModel>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  MicroWidgetsNotifier(this._userId) : super([]);
  
  static const _storageKey = 'micro_widgets';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await load();
  }
  
  Future<void> load() async {
    if (_prefs == null) return;
    
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        state = jsonList
            .map((j) => MicroWidgetModel.fromJson(j as Map<String, dynamic>))
            .toList();
        
        // Check for period resets
        _checkAndResetPeriods();
      } catch (e) {
        state = [];
      }
    }
  }
  
  void _checkAndResetPeriods() {
    bool needsSave = false;
    state = state.map((widget) {
      if (widget.needsReset()) {
        needsSave = true;
        return widget.resetForNewPeriod();
      }
      return widget;
    }).toList();
    
    if (needsSave) _save();
  }
  
  Future<void> _save() async {
    if (_prefs == null) return;
    final jsonList = state.map((w) => w.toJson()).toList();
    await _prefs!.setString(_userKey, jsonEncode(jsonList));
  }
  
  Future<void> addWidget(MicroWidgetModel widget) async {
    state = [...state, widget];
    await _save();
  }
  
  Future<void> updateWidget(MicroWidgetModel widget) async {
    state = state.map((w) => w.id == widget.id ? widget : w).toList();
    await _save();
  }
  
  Future<void> deleteWidget(String widgetId) async {
    state = state.where((w) => w.id != widgetId).toList();
    await _save();
  }
  
  /// Widget abhaken (für heute)
  Future<void> checkOff(String widgetId) async {
    state = state.map((w) {
      if (w.id == widgetId) {
        return w.checkOff();
      }
      return w;
    }).toList();
    await _save();
  }
}

/// MicroWidgets Provider
final microWidgetsProvider = StateNotifierProvider<MicroWidgetsNotifier, List<MicroWidgetModel>>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  final userId = user?.id ?? 'demo';
  final notifier = MicroWidgetsNotifier(userId);
  
  ref.watch(sharedPreferencesProvider).whenData((prefs) {
    notifier.init(prefs);
  });
  
  return notifier;
});

// ============================================================================
// SCHOOL PROVIDERS
// ============================================================================

/// School Repository Provider
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return DemoSchoolRepository();
});

/// Fächer (Subjects) Notifier
class SubjectsNotifier extends StateNotifier<List<Subject>> {
  final SchoolRepository _repository;
  String? _userId;
  
  SubjectsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSubjects(userId);
  }
  
  Future<Subject> add(Subject subject) async {
    final created = await _repository.addSubject(subject);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(Subject subject) async {
    await _repository.updateSubject(subject);
    state = state.map((s) => s.id == subject.id ? subject : s).toList();
  }
  
  Future<void> delete(String subjectId) async {
    await _repository.deleteSubject(subjectId);
    state = state.where((s) => s.id != subjectId).toList();
  }
}

final subjectsNotifierProvider = StateNotifierProvider<SubjectsNotifier, List<Subject>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SubjectsNotifier(repository);
});

/// Stundenplan Notifier
class TimetableNotifier extends StateNotifier<List<TimetableEntry>> {
  final SchoolRepository _repository;
  String? _userId;
  
  TimetableNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getTimetable(userId);
  }
  
  List<TimetableEntry> getForDay(Weekday weekday) {
    return state.where((t) => t.weekday == weekday).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }
  
  Future<TimetableEntry> add(TimetableEntry entry) async {
    final created = await _repository.addTimetableEntry(entry);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(TimetableEntry entry) async {
    await _repository.updateTimetableEntry(entry);
    state = state.map((t) => t.id == entry.id ? entry : t).toList();
  }
  
  Future<void> delete(String entryId) async {
    await _repository.deleteTimetableEntry(entryId);
    state = state.where((t) => t.id != entryId).toList();
  }
}

final timetableNotifierProvider = StateNotifierProvider<TimetableNotifier, List<TimetableEntry>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return TimetableNotifier(repository);
});

/// Noten Notifier
class GradesNotifier extends StateNotifier<List<Grade>> {
  final SchoolRepository _repository;
  String? _userId;
  
  GradesNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getGrades(userId);
  }
  
  List<Grade> getForSubject(String subjectId) {
    return state.where((g) => g.subjectId == subjectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  /// Durchschnitt für ein Fach berechnen
  double getAverageForSubject(String subjectId) {
    final grades = getForSubject(subjectId);
    if (grades.isEmpty) return 0;
    double weightedSum = 0;
    double totalWeight = 0;
    for (final grade in grades) {
      weightedSum += grade.points * grade.weight;
      totalWeight += grade.weight;
    }
    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }
  
  /// Gesamtdurchschnitt
  double get overallAverage {
    if (state.isEmpty) return 0;
    double weightedSum = 0;
    double totalWeight = 0;
    for (final grade in state) {
      weightedSum += grade.points * grade.weight;
      totalWeight += grade.weight;
    }
    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }
  
  Future<Grade> add(Grade grade) async {
    final created = await _repository.addGrade(grade);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(Grade grade) async {
    await _repository.updateGrade(grade);
    state = state.map((g) => g.id == grade.id ? grade : g).toList();
  }
  
  Future<void> delete(String gradeId) async {
    await _repository.deleteGrade(gradeId);
    state = state.where((g) => g.id != gradeId).toList();
  }
}

final gradesNotifierProvider = StateNotifierProvider<GradesNotifier, List<Grade>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return GradesNotifier(repository);
});

/// Lernzeit Notifier
class StudySessionsNotifier extends StateNotifier<List<StudySession>> {
  final SchoolRepository _repository;
  String? _userId;
  
  StudySessionsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getStudySessions(userId);
  }
  
  List<StudySession> getForSubject(String subjectId) {
    return state.where((s) => s.subjectId == subjectId).toList();
  }
  
  /// Gesamtlernzeit für ein Fach in Minuten
  int getTotalMinutesForSubject(String subjectId) {
    return getForSubject(subjectId).fold(0, (sum, s) => sum + s.durationMinutes);
  }
  
  /// Lernzeit dieser Woche
  int get weeklyMinutes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return state
        .where((s) => s.startTime.isAfter(start))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }
  
  Future<StudySession> add(StudySession session) async {
    final created = await _repository.addStudySession(session);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(StudySession session) async {
    await _repository.updateStudySession(session);
    state = state.map((s) => s.id == session.id ? session : s).toList();
  }
  
  Future<void> delete(String sessionId) async {
    await _repository.deleteStudySession(sessionId);
    state = state.where((s) => s.id != sessionId).toList();
  }
}

final studySessionsNotifierProvider = StateNotifierProvider<StudySessionsNotifier, List<StudySession>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return StudySessionsNotifier(repository);
});

/// Schultermine Notifier
class SchoolEventsNotifier extends StateNotifier<List<SchoolEvent>> {
  final SchoolRepository _repository;
  String? _userId;
  
  SchoolEventsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSchoolEvents(userId);
  }
  
  List<SchoolEvent> get upcoming {
    final now = DateTime.now();
    return state
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  List<SchoolEvent> getForSubject(String subjectId) {
    return state.where((e) => e.subjectId == subjectId).toList();
  }
  
  Future<SchoolEvent> add(SchoolEvent event) async {
    final created = await _repository.addSchoolEvent(event);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SchoolEvent event) async {
    await _repository.updateSchoolEvent(event);
    state = state.map((e) => e.id == event.id ? event : e).toList();
  }
  
  Future<void> delete(String eventId) async {
    await _repository.deleteSchoolEvent(eventId);
    state = state.where((e) => e.id != eventId).toList();
  }
}

final schoolEventsNotifierProvider = StateNotifierProvider<SchoolEventsNotifier, List<SchoolEvent>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SchoolEventsNotifier(repository);
});

/// Hausaufgaben Notifier
class HomeworkNotifier extends StateNotifier<List<Homework>> {
  final SchoolRepository _repository;
  String? _userId;
  
  HomeworkNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getHomework(userId);
  }
  
  List<Homework> get pending {
    return state.where((h) => h.status != HomeworkStatus.done).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  
  List<Homework> getForSubject(String subjectId) {
    return state.where((h) => h.subjectId == subjectId).toList();
  }
  
  Future<Homework> add(Homework homework) async {
    final created = await _repository.addHomework(homework);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(Homework homework) async {
    await _repository.updateHomework(homework);
    state = state.map((h) => h.id == homework.id ? homework : h).toList();
  }
  
  Future<void> updateStatus(String homeworkId, HomeworkStatus newStatus) async {
    final homework = state.firstWhere((h) => h.id == homeworkId);
    final updated = homework.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await update(updated);
  }
  
  Future<void> toggleStatus(String homeworkId) async {
    final homework = state.firstWhere((h) => h.id == homeworkId);
    final newStatus = homework.status == HomeworkStatus.done 
        ? HomeworkStatus.pending 
        : HomeworkStatus.done;
    await updateStatus(homeworkId, newStatus);
  }
  
  Future<void> delete(String homeworkId) async {
    await _repository.deleteHomework(homeworkId);
    state = state.where((h) => h.id != homeworkId).toList();
  }
}

final homeworkNotifierProvider = StateNotifierProvider<HomeworkNotifier, List<Homework>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return HomeworkNotifier(repository);
});

/// Schulnotizen Notifier
class SchoolNotesNotifier extends StateNotifier<List<SchoolNote>> {
  final SchoolRepository _repository;
  String? _userId;
  
  SchoolNotesNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getNotes(userId);
  }
  
  List<SchoolNote> getForSubject(String subjectId) {
    return state.where((n) => n.subjectId == subjectId).toList();
  }
  
  List<SchoolNote> get generalNotes {
    return state.where((n) => n.subjectId == null).toList();
  }
  
  Future<SchoolNote> add(SchoolNote note) async {
    final created = await _repository.addNote(note);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SchoolNote note) async {
    await _repository.updateNote(note);
    state = state.map((n) => n.id == note.id ? note : n).toList();
  }
  
  Future<void> togglePin(String noteId) async {
    final note = state.firstWhere((n) => n.id == noteId);
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await update(updated);
  }
  
  Future<void> updateColor(String noteId, String? color) async {
    final note = state.firstWhere((n) => n.id == noteId);
    final updated = SchoolNote(
      id: note.id,
      userId: note.userId,
      subjectId: note.subjectId,
      title: note.title,
      content: note.content,
      isPinned: note.isPinned,
      color: color,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
    );
    await update(updated);
  }
  
  Future<void> delete(String noteId) async {
    await _repository.deleteNote(noteId);
    state = state.where((n) => n.id != noteId).toList();
  }
}

final schoolNotesNotifierProvider = StateNotifierProvider<SchoolNotesNotifier, List<SchoolNote>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SchoolNotesNotifier(repository);
});

// ============================================
// SPORT PROVIDERS
// ============================================

/// Sport Repository Provider
final sportRepositoryProvider = Provider<SportRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSportRepository();
  }
  // TODO: Implement SupabaseSportRepository when needed
  return DemoSportRepository();
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
    return SportStreak(currentStreak: 0, longestStreak: 0);
  }
  
  // Get unique dates with sport
  final dates = sessions.map((s) {
    return DateTime(s.date.year, s.date.month, s.date.day);
  }).toSet().toList()..sort((a, b) => b.compareTo(a));
  
  if (dates.isEmpty) {
    return SportStreak(currentStreak: 0, longestStreak: 0);
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
    byType.putIfAbsent(session.sportType, () => []).add(session);
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
// SKIN (GESICHTSHAUT) PROVIDERS
// ============================================

/// Skin Repository Provider
final skinRepositoryProvider = Provider<SkinRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSkinRepository();
  }
  // TODO: Implement SupabaseSkinRepository when needed
  return DemoSkinRepository();
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
  
  int get completedCount => state.length;
}

final skinCareCompletionsNotifierProvider = StateNotifierProvider<SkinCareCompletionsNotifier, List<SkinCareCompletion>>((ref) {
  final repository = ref.watch(skinRepositoryProvider);
  return SkinCareCompletionsNotifier(repository);
});

// ============================================
// HAIR CARE PROVIDERS
// ============================================

/// Hair Care Entries Notifier - Tägliche Haarpflege
class HairCareEntriesNotifier extends StateNotifier<List<HairCareEntry>> {
  SharedPreferences? _prefs;
  final String _oderId;
  
  HairCareEntriesNotifier(this._oderId) : super([]);
  
  static const _storageKey = 'hair_care_entries';
  
  String get _userKey => '${_storageKey}_$_oderId';
  
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => HairCareEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) return;
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  HairCareEntry? getForDate(DateTime date) {
    return state.cast<HairCareEntry?>().firstWhere(
      (e) => e != null && 
             e.date.year == date.year &&
             e.date.month == date.month &&
             e.date.day == date.day,
      orElse: () => null,
    );
  }
  
  List<HairCareEntry> getForRange(DateTime start, DateTime end) {
    return state.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
             e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
  
  Future<HairCareEntry> addOrUpdate(HairCareEntry entry) async {
    final existing = getForDate(entry.date);
    if (existing != null) {
      final updated = entry.copyWith(id: existing.id, createdAt: existing.createdAt);
      state = state.map((e) => e.id == existing.id ? updated : e).toList();
      await _save();
      return updated;
    } else {
      state = [...state, entry];
      await _save();
      return entry;
    }
  }
  
  Future<void> delete(String entryId) async {
    state = state.where((e) => e.id != entryId).toList();
    await _save();
  }
  
  /// Statistik für die letzten n Tage
  int getWashDaysInRange(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    return getForRange(start, now).where((e) => 
      e.careTypes.contains(HairCareType.washed) || 
      e.careTypes.contains(HairCareType.shampoo) ||
      e.careTypes.contains(HairCareType.waterOnly)
    ).length;
  }
}

final hairCareEntriesProvider = StateNotifierProvider.family<HairCareEntriesNotifier, List<HairCareEntry>, String>((ref, oderId) {
  final notifier = HairCareEntriesNotifier(oderId);
  
  ref.watch(sharedPreferencesProvider).whenData((prefs) {
    notifier.init(prefs);
  });
  
  return notifier;
});

/// Hair Events Notifier - Besondere Ereignisse (Haarschnitt, Färben etc.)
class HairEventsNotifier extends StateNotifier<List<HairEvent>> {
  SharedPreferences? _prefs;
  final String _oderId;
  
  HairEventsNotifier(this._oderId) : super([]);
  
  static const _storageKey = 'hair_events';
  
  String get _userKey => '${_storageKey}_$_oderId';
  
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => HairEvent.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) return;
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  List<HairEvent> getRecent(int count) {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }
  
  HairEvent? getLastOfType(HairEventType type) {
    final filtered = state.where((e) => e.eventType == type).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered.first;
  }
  
  int daysSinceLastHaircut() {
    final last = getLastOfType(HairEventType.haircut);
    if (last == null) return -1;
    return DateTime.now().difference(last.date).inDays;
  }
  
  Future<HairEvent> add(HairEvent event) async {
    state = [...state, event];
    await _save();
    return event;
  }
  
  Future<void> update(HairEvent event) async {
    state = state.map((e) => e.id == event.id ? event : e).toList();
    await _save();
  }
  
  Future<void> delete(String eventId) async {
    state = state.where((e) => e.id != eventId).toList();
    await _save();
  }
}

final hairEventsProvider = StateNotifierProvider.family<HairEventsNotifier, List<HairEvent>, String>((ref, oderId) {
  final notifier = HairEventsNotifier(oderId);
  
  ref.watch(sharedPreferencesProvider).whenData((prefs) {
    notifier.init(prefs);
  });
  
  return notifier;
});

/// Hair Products Notifier - Pflegeprodukte
class HairProductsNotifier extends StateNotifier<List<HairProduct>> {
  SharedPreferences? _prefs;
  final String _oderId;
  
  HairProductsNotifier(this._oderId) : super([]);
  
  static const _storageKey = 'hair_products';
  
  String get _userKey => '${_storageKey}_$_oderId';
  
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => HairProduct.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) return;
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  List<HairProduct> get activeProducts => state.where((p) => p.isActive).toList();
  
  List<HairProduct> getByCategory(HairProductCategory category) {
    return state.where((p) => p.category == category).toList();
  }
  
  Future<HairProduct> add(HairProduct product) async {
    state = [...state, product];
    await _save();
    return product;
  }
  
  Future<void> update(HairProduct product) async {
    state = state.map((p) => p.id == product.id ? product : p).toList();
    await _save();
  }
  
  Future<void> delete(String productId) async {
    state = state.where((p) => p.id != productId).toList();
    await _save();
  }
}

final hairProductsProvider = StateNotifierProvider.family<HairProductsNotifier, List<HairProduct>, String>((ref, oderId) {
  final notifier = HairProductsNotifier(oderId);
  
  ref.watch(sharedPreferencesProvider).whenData((prefs) {
    notifier.init(prefs);
  });
  
  return notifier;
});

/// Hair Care Statistics Provider
final hairCareStatisticsProvider = Provider.family<HairCareStatistics, String>((ref, oderId) {
  final entries = ref.watch(hairCareEntriesProvider(oderId));
  final events = ref.watch(hairEventsProvider(oderId));
  
  return HairCareStatistics.calculate(
    entries: entries,
    events: events,
    days: 7,
  );
});

// ============================================
// DIGESTION PROVIDERS (Verdauung/Toilette)
// ============================================

/// Digestion Entries Notifier - Toilettengänge
class DigestionEntriesNotifier extends StateNotifier<List<DigestionEntry>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  DigestionEntriesNotifier(this._userId) : super([]);
  
  static const _storageKey = 'digestion_entries';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => DigestionEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  /// Holt Einträge für einen bestimmten Tag
  List<DigestionEntry> getForDate(DateTime date) {
    return state.where((e) => 
      e.timestamp.year == date.year &&
      e.timestamp.month == date.month &&
      e.timestamp.day == date.day
    ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Holt Einträge für einen Zeitraum
  List<DigestionEntry> getForRange(DateTime start, DateTime end) {
    return state.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
             e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  
  /// Letzter Eintrag
  DigestionEntry? get lastEntry {
    if (state.isEmpty) return null;
    final sorted = [...state]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.first;
  }
  
  /// Einträge von heute
  List<DigestionEntry> get todayEntries {
    final now = DateTime.now();
    return getForDate(now);
  }
  
  /// Anzahl Stuhlgänge heute
  int get todayStoolCount {
    return todayEntries.where((e) => 
      e.type == ToiletType.stool || e.type == ToiletType.both
    ).length;
  }
  
  /// Durchschnittliche Konsistenz (letzte 7 Tage)
  double? get avgConsistencyLast7Days {
    final now = DateTime.now();
    final week = getForRange(now.subtract(const Duration(days: 7)), now);
    final stoolEntries = week.where((e) => e.consistency != null).toList();
    if (stoolEntries.isEmpty) return null;
    return stoolEntries.map((e) => e.consistency!.value).reduce((a, b) => a + b) 
           / stoolEntries.length;
  }
  
  /// Neuen Eintrag hinzufügen
  Future<DigestionEntry> add(DigestionEntry entry) async {
    state = [...state, entry];
    await _save();
    return entry;
  }
  
  /// Eintrag aktualisieren
  Future<void> update(DigestionEntry entry) async {
    state = state.map((e) => e.id == entry.id ? entry : e).toList();
    await _save();
  }
  
  /// Eintrag löschen
  Future<void> delete(String entryId) async {
    state = state.where((e) => e.id != entryId).toList();
    await _save();
  }
  
  /// Statistik: Einträge pro Tag (letzte n Tage)
  Map<DateTime, int> getEntriesPerDay(int days) {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    
    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[date] = getForDate(date).length;
    }
    
    return result;
  }
}

final digestionEntriesProvider = StateNotifierProvider.family<DigestionEntriesNotifier, List<DigestionEntry>, String>((ref, userId) {
  return DigestionEntriesNotifier(userId);
});

/// Provider für Tagesübersicht
final digestionDaySummaryProvider = Provider.family<DigestionDaySummary, ({String userId, DateTime date})>((ref, params) {
  final entries = ref.watch(digestionEntriesProvider(params.userId));
  final dayEntries = entries.where((e) => 
    e.timestamp.year == params.date.year &&
    e.timestamp.month == params.date.month &&
    e.timestamp.day == params.date.day
  ).toList();
  
  return DigestionDaySummary(
    date: params.date,
    entries: dayEntries,
  );
});

// ============================================
// SUPPLEMENT PROVIDERS
// ============================================

/// Supplements Notifier - Nahrungsergänzungsmittel
class SupplementsNotifier extends StateNotifier<List<Supplement>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  SupplementsNotifier(this._userId) : super([]);
  
  static const _storageKey = 'supplements';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => Supplement.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  /// Aktive (nicht pausierte) Supplements
  List<Supplement> get active => state.where((s) => !s.isPaused).toList();
  
  /// Supplement nach ID
  Supplement? getById(String id) {
    return state.cast<Supplement?>().firstWhere((s) => s?.id == id, orElse: () => null);
  }
  
  /// Supplements nach Kategorie
  List<Supplement> byCategory(SupplementCategory category) {
    return state.where((s) => s.category == category).toList();
  }
  
  /// Neues Supplement hinzufügen
  Future<Supplement> add(Supplement supplement) async {
    state = [...state, supplement];
    await _save();
    return supplement;
  }
  
  /// Supplement aktualisieren
  Future<void> update(Supplement supplement) async {
    state = state.map((s) => s.id == supplement.id ? supplement : s).toList();
    await _save();
  }
  
  /// Supplement löschen
  Future<void> delete(String supplementId) async {
    state = state.where((s) => s.id != supplementId).toList();
    await _save();
  }
}

final supplementsProvider = StateNotifierProvider.family<SupplementsNotifier, List<Supplement>, String>((ref, userId) {
  return SupplementsNotifier(userId);
});

/// Supplement Intakes Notifier - Einnahmen
class SupplementIntakesNotifier extends StateNotifier<List<SupplementIntake>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  SupplementIntakesNotifier(this._userId) : super([]);
  
  static const _storageKey = 'supplement_intakes';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => SupplementIntake.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  /// Einnahmen für einen bestimmten Tag
  List<SupplementIntake> getForDate(DateTime date) {
    return state.where((e) => 
      e.timestamp.year == date.year &&
      e.timestamp.month == date.month &&
      e.timestamp.day == date.day
    ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Einnahmen für einen Zeitraum
  List<SupplementIntake> getForRange(DateTime start, DateTime end) {
    return state.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
             e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  
  /// Einnahmen heute
  List<SupplementIntake> get todayIntakes {
    final now = DateTime.now();
    return getForDate(now);
  }
  
  /// Einnahmen eines bestimmten Supplements heute
  List<SupplementIntake> todayIntakesFor(String supplementId) {
    return todayIntakes.where((i) => i.supplementId == supplementId).toList();
  }
  
  /// Neue Einnahme hinzufügen
  Future<SupplementIntake> add(SupplementIntake intake) async {
    state = [...state, intake];
    await _save();
    return intake;
  }
  
  /// Einnahme aktualisieren
  Future<void> update(SupplementIntake intake) async {
    state = state.map((i) => i.id == intake.id ? intake : i).toList();
    await _save();
  }
  
  /// Einnahme löschen
  Future<void> delete(String intakeId) async {
    state = state.where((i) => i.id != intakeId).toList();
    await _save();
  }
  
  /// Alle Einnahmen eines Supplements löschen
  Future<void> deleteForSupplement(String supplementId) async {
    state = state.where((i) => i.supplementId != supplementId).toList();
    await _save();
  }
}

final supplementIntakesProvider = StateNotifierProvider.family<SupplementIntakesNotifier, List<SupplementIntake>, String>((ref, userId) {
  return SupplementIntakesNotifier(userId);
});

/// Provider für Supplement-Statistiken
final supplementStatisticsProvider = Provider.family<SupplementStatistics, ({String userId, int days})>((ref, params) {
  final supplements = ref.watch(supplementsProvider(params.userId));
  final intakes = ref.watch(supplementIntakesProvider(params.userId));
  
  return SupplementStatistics.calculate(
    supplements: supplements,
    intakes: intakes,
    days: params.days,
  );
});

// ==============================
// Media (Filme & Serien) Provider
// ==============================

/// User Media Entries Notifier - verwaltet Filme & Serien
class UserMediaEntriesNotifier extends StateNotifier<List<UserMediaEntry>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  UserMediaEntriesNotifier(this._userId) : super([]);
  
  static const _storageKey = 'user_media_entries';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => UserMediaEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  /// Media-Eintrag hinzufügen
  Future<void> add(UserMediaEntry entry) async {
    // Prüfe ob bereits vorhanden (basierend auf tmdbId)
    final exists = state.any((e) => e.media.tmdbId == entry.media.tmdbId && e.media.type == entry.media.type);
    if (!exists) {
      state = [...state, entry];
      await _save();
    }
  }
  
  /// Media-Eintrag aktualisieren
  Future<void> update(UserMediaEntry entry) async {
    state = state.map((e) => e.id == entry.id ? entry : e).toList();
    await _save();
  }
  
  /// Media-Eintrag löschen
  Future<void> delete(String entryId) async {
    state = state.where((e) => e.id != entryId).toList();
    await _save();
  }
  
  /// Eintrag per TMDB-ID finden
  UserMediaEntry? findByTmdbId(int tmdbId, MediaType type) {
    try {
      return state.firstWhere((e) => e.media.tmdbId == tmdbId && e.media.type == type);
    } catch (_) {
      return null;
    }
  }
  
  /// Status eines Eintrags ändern
  Future<void> updateStatus(String entryId, MediaStatus status) async {
    final entry = state.firstWhere((e) => e.id == entryId);
    final updatedEntry = entry.copyWith(
      status: status,
      watchedDate: status == MediaStatus.watched ? DateTime.now() : entry.watchedDate,
      updatedAt: DateTime.now(),
    );
    await update(updatedEntry);
  }
  
  /// Bewertung hinzufügen/aktualisieren
  Future<void> addRating(String entryId, MediaRating rating) async {
    final entry = state.firstWhere((e) => e.id == entryId);
    final updatedEntry = entry.copyWith(
      rating: rating,
      status: MediaStatus.watched,
      watchedDate: entry.watchedDate ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await update(updatedEntry);
  }
  
  /// Episode als gesehen markieren
  Future<void> markEpisodeWatched(String entryId, int seasonNumber, int episodeNumber, bool watched) async {
    final entry = state.firstWhere((e) => e.id == entryId);
    final episodeCode = 'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';
    
    Set<String> newWatchedEpisodes;
    if (watched) {
      newWatchedEpisodes = {...entry.watchedEpisodes, episodeCode};
    } else {
      newWatchedEpisodes = entry.watchedEpisodes.where((e) => e != episodeCode).toSet();
    }
    
    await update(entry.copyWith(
      watchedEpisodes: newWatchedEpisodes,
      currentSeason: seasonNumber,
      currentEpisode: episodeNumber,
      updatedAt: DateTime.now(),
    ));
  }
  
  /// Ganze Staffel als gesehen markieren
  Future<void> markSeasonWatched(String entryId, int seasonNumber, bool watched, List<int> episodeNumbers) async {
    final entry = state.firstWhere((e) => e.id == entryId);
    
    Set<String> newWatchedEpisodes = {...entry.watchedEpisodes};
    for (final ep in episodeNumbers) {
      final code = 'S${seasonNumber.toString().padLeft(2, '0')}E${ep.toString().padLeft(2, '0')}';
      if (watched) {
        newWatchedEpisodes.add(code);
      } else {
        newWatchedEpisodes.remove(code);
      }
    }
    
    await update(entry.copyWith(
      watchedEpisodes: newWatchedEpisodes,
      updatedAt: DateTime.now(),
    ));
  }
  
  /// Einträge nach Status filtern
  List<UserMediaEntry> getByStatus(MediaStatus status) {
    return state.where((e) => e.status == status).toList();
  }
  
  /// Merkliste abrufen
  List<UserMediaEntry> get watchlist => getByStatus(MediaStatus.watchlist);
  
  /// Gesehene abrufen
  List<UserMediaEntry> get watched => getByStatus(MediaStatus.watched);
  
  /// Abgebrochene abrufen
  List<UserMediaEntry> get dropped => getByStatus(MediaStatus.dropped);
  
  /// Aktuell am schauen (Serien)
  List<UserMediaEntry> get watching => getByStatus(MediaStatus.watching);
}

final userMediaEntriesProvider = StateNotifierProvider.family<UserMediaEntriesNotifier, List<UserMediaEntry>, String>((ref, userId) {
  return UserMediaEntriesNotifier(userId);
});

/// Provider für Media-Statistiken
final mediaStatisticsProvider = Provider.family<MediaStatistics, String>((ref, userId) {
  final entries = ref.watch(userMediaEntriesProvider(userId));
  return MediaStatistics.calculate(entries);
});

// ==============================
// Household (Haushalt) Provider
// ==============================

/// Household Tasks Notifier - verwaltet Haushaltsaufgaben
class HouseholdTasksNotifier extends StateNotifier<List<HouseholdTask>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  HouseholdTasksNotifier(this._userId) : super([]);
  
  static const _storageKey = 'household_tasks';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => HouseholdTask.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  /// Aufgabe hinzufügen
  Future<void> add(HouseholdTask task) async {
    state = [...state, task];
    await _save();
  }
  
  /// Aufgabe aktualisieren
  Future<void> update(HouseholdTask task) async {
    state = state.map((t) => t.id == task.id ? task : t).toList();
    await _save();
  }
  
  /// Aufgabe löschen
  Future<void> delete(String taskId) async {
    state = state.where((t) => t.id != taskId).toList();
    await _save();
  }
  
  /// Aufgabe pausieren/fortsetzen
  Future<void> togglePause(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    await update(task.copyWith(isPaused: !task.isPaused, updatedAt: DateTime.now()));
  }
}

final householdTasksProvider = StateNotifierProvider.family<HouseholdTasksNotifier, List<HouseholdTask>, String>((ref, userId) {
  return HouseholdTasksNotifier(userId);
});

/// Household Completions Notifier - Erledigungen
class HouseholdCompletionsNotifier extends StateNotifier<List<TaskCompletion>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  HouseholdCompletionsNotifier(this._userId) : super([]);
  
  static const _storageKey = 'household_completions';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => TaskCompletion.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  /// Erledigung hinzufügen
  Future<void> add(TaskCompletion completion) async {
    state = [...state, completion];
    await _save();
  }
  
  /// Letzte Erledigung für eine Aufgabe
  TaskCompletion? lastCompletionFor(String taskId) {
    final taskCompletions = state.where((c) => c.taskId == taskId && !c.wasSkipped).toList();
    if (taskCompletions.isEmpty) return null;
    taskCompletions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return taskCompletions.first;
  }
}

final householdCompletionsProvider = StateNotifierProvider.family<HouseholdCompletionsNotifier, List<TaskCompletion>, String>((ref, userId) {
  return HouseholdCompletionsNotifier(userId);
});

/// Provider für Household-Statistiken
final householdStatisticsProvider = Provider.family<HouseholdStatistics, String>((ref, userId) {
  final tasks = ref.watch(householdTasksProvider(userId));
  final completions = ref.watch(householdCompletionsProvider(userId));
  return HouseholdStatistics.calculate(tasks: tasks, completions: completions);
});

// ============================================================================
// RECIPE PROVIDERS
// ============================================================================

/// Recipes Notifier - Rezepte verwalten
class RecipesNotifier extends StateNotifier<List<Recipe>> {
  SharedPreferences? _prefs;
  final String _userId;
  
  RecipesNotifier(this._userId) : super([]) {
    load();
  }
  
  static const _storageKey = 'recipes';
  
  String get _userKey => '${_storageKey}_$_userId';
  
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final jsonStr = _prefs!.getString(_userKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      state = list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    }
  }
  
  Future<void> _save() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs!.setString(_userKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
  
  /// Rezept hinzufügen
  Future<void> addRecipe(Recipe recipe) async {
    state = [...state, recipe];
    await _save();
  }
  
  /// Rezept aktualisieren
  Future<void> updateRecipe(Recipe recipe) async {
    state = state.map((r) => r.id == recipe.id ? recipe : r).toList();
    await _save();
  }
  
  /// Rezept löschen
  Future<void> removeRecipe(String recipeId) async {
    state = state.where((r) => r.id != recipeId).toList();
    await _save();
  }
}

final recipesProvider = StateNotifierProvider.family<RecipesNotifier, List<Recipe>, String>((ref, userId) {
  return RecipesNotifier(userId);
});

/// Provider für Rezept-Statistiken
final recipeStatisticsProvider = Provider.family<RecipeStatistics, String>((ref, userId) {
  final recipes = ref.watch(recipesProvider(userId));
  return RecipeStatistics.calculate(recipes);
});

