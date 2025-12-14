/// Riverpod Providers
/// Provides dependency injection and state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/in_memory_database.dart';

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

final productSearchProvider = FutureProvider.family<List<ProductModel>, String>((ref, query) async {
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
// IN-MEMORY DATABASE PROVIDER (Demo Mode)
// ============================================

final inMemoryDatabaseProvider = Provider<InMemoryDatabase>((ref) {
  return InMemoryDatabase();
});
