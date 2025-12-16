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
  
  /// Widget-Position ändern
  Future<void> moveWidget(String widgetId, int newGridX, int newGridY) async {
    if (state == null) return;
    
    final widgets = state!.widgets.map((w) {
      if (w.id == widgetId) {
        return w.copyWith(
          gridX: newGridX.clamp(0, state!.gridColumns - w.size.gridWidth),
          gridY: newGridY.clamp(0, 99),
        );
      }
      return w;
    }).toList();
    
    state = state!.copyWith(widgets: widgets);
    await _save();
  }
  
  /// Widget-Größe ändern
  Future<void> resizeWidget(String widgetId, HomeWidgetSize newSize) async {
    if (state == null) return;
    
    final widgets = state!.widgets.map((w) {
      if (w.id == widgetId) {
        // Stelle sicher, dass das Widget nicht über den Rand hinausgeht
        final maxX = state!.gridColumns - newSize.gridWidth;
        return w.copyWith(
          size: newSize,
          gridX: w.gridX.clamp(0, maxX),
        );
      }
      return w;
    }).toList();
    
    state = state!.copyWith(widgets: widgets);
    await _save();
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
    if (state == null) return;
    state = state!.copyWith(widgets: widgets);
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

