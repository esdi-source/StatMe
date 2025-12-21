/// Supabase Repository Implementations
/// Used when DEMO_MODE=false for production with real Supabase backend

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_data_service.dart';
import 'repository_interfaces.dart';

/// Helper-Klasse für Event-Logging
class _EventLogger {
  static final SupabaseDataService _dataService = SupabaseDataService.instance;
  
  static Future<void> log(String widgetName, String eventType, Map<String, dynamic> payload) async {
    try {
      await _dataService.logEvent(
        widgetName: widgetName,
        eventType: eventType,
        payload: payload,
      );
    } catch (e) {
      // Silently fail - don't break the app if logging fails
    }
  }
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  
  SupabaseAuthRepository(this._client);
  
  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] as String?,
      createdAt: DateTime.parse(user.createdAt),
      lastLoginAt: user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null,
    );
  }
  
  @override
  Future<UserModel> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    final user = response.user!;
    return UserModel(
      id: user.id,
      email: user.email ?? email,
      displayName: user.userMetadata?['display_name'] as String?,
      createdAt: DateTime.parse(user.createdAt),
      lastLoginAt: DateTime.now(),
    );
  }
  
  @override
  Future<UserModel> signUp(String email, String password, String? displayName) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
    
    final user = response.user!;
    return UserModel(
      id: user.id,
      email: user.email ?? email,
      displayName: displayName,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }
  
  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  @override
  Stream<UserModel?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] as String?,
        createdAt: DateTime.parse(user.createdAt),
        lastLoginAt: user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null,
      );
    });
  }
}

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseClient _client;
  
  SupabaseSettingsRepository(this._client);
  
  @override
  Future<SettingsModel?> getSettings(String userId) async {
    final response = await _client
        .from('settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return SettingsModel.fromJson(response);
  }
  
  @override
  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    final response = await _client
        .from('settings')
        .upsert(settings.toJson())
        .select()
        .single();
    
    return SettingsModel.fromJson(response);
  }
}

class SupabaseTodoRepository implements TodoRepository {
  final SupabaseClient _client;
  
  SupabaseTodoRepository(this._client);
  
  @override
  Future<List<TodoModel>> getTodos(String userId) async {
    final response = await _client
        .from('todos')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => TodoModel.fromJson(json)).toList();
  }
  
  @override
  Future<TodoModel> createTodo(TodoModel todo) async {
    final response = await _client
        .from('todos')
        .insert(todo.toJson())
        .select()
        .single();
    
    final created = TodoModel.fromJson(response);
    await _EventLogger.log('todos', 'created', {
      'id': created.id,
      'title': created.title,
      'priority': created.priority.name,
    });
    return created;
  }
  
  @override
  Future<TodoModel> updateTodo(TodoModel todo) async {
    final response = await _client
        .from('todos')
        .update(todo.toJson())
        .eq('id', todo.id)
        .select()
        .single();
    
    final updated = TodoModel.fromJson(response);
    await _EventLogger.log('todos', 'updated', {
      'id': updated.id,
      'title': updated.title,
      'active': updated.active,
    });
    return updated;
  }
  
  @override
  Future<void> deleteTodo(String todoId) async {
    await _client.from('todos').delete().eq('id', todoId);
    await _EventLogger.log('todos', 'deleted', {'id': todoId});
  }
  
  @override
  Future<List<TodoOccurrence>> getOccurrences(String todoId) async {
    final response = await _client
        .from('todo_occurrences')
        .select()
        .eq('todo_id', todoId)
        .order('due_at', ascending: true);
    
    return (response as List).map((json) => TodoOccurrence.fromJson(json)).toList();
  }
  
  @override
  Future<List<TodoOccurrence>> getOccurrencesForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final response = await _client
        .from('todo_occurrences')
        .select()
        .eq('user_id', userId)
        .gte('due_at', startOfDay.toIso8601String())
        .lt('due_at', endOfDay.toIso8601String());
    
    return (response as List).map((json) => TodoOccurrence.fromJson(json)).toList();
  }
  
  @override
  Future<TodoOccurrence> toggleOccurrence(String occurrenceId, bool done) async {
    final response = await _client
        .from('todo_occurrences')
        .update({'done': done})
        .eq('id', occurrenceId)
        .select()
        .single();
    
    final occurrence = TodoOccurrence.fromJson(response);
    await _EventLogger.log('todos', done ? 'completed' : 'uncompleted', {
      'occurrence_id': occurrenceId,
      'done': done,
    });
    return occurrence;
  }
}

class SupabaseFoodRepository implements FoodRepository {
  final SupabaseClient _client;
  
  SupabaseFoodRepository(this._client);
  
  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final response = await _client
        .from('products_cache')
        .select()
        .ilike('product_name', '%$query%')
        .limit(20);
    
    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }
  
  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final response = await _client
        .from('products_cache')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
    
    if (response == null) return null;
    return ProductModel.fromJson(response);
  }
  
  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    final response = await _client
        .from('products_cache')
        .upsert(product.toJson())
        .select()
        .single();
    
    return ProductModel.fromJson(response);
  }
  
  @override
  Future<List<FoodLogModel>> getFoodLogs(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('food_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at', ascending: true);
    
    return (response as List).map((json) => FoodLogModel.fromJson(json)).toList();
  }
  
  @override
  Future<List<FoodLogModel>> getFoodLogsRange(String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('food_logs')
        .select()
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0]);
    
    return (response as List).map((json) => FoodLogModel.fromJson(json)).toList();
  }
  
  @override
  Future<FoodLogModel> addFoodLog(FoodLogModel log) async {
    final response = await _client
        .from('food_logs')
        .insert(log.toJson())
        .select()
        .single();
    
    final added = FoodLogModel.fromJson(response);
    await _EventLogger.log('food', 'created', {
      'id': added.id,
      'productName': added.productName,
      'calories': added.calories,
      'grams': added.grams,
      'date': added.date.toIso8601String(),
    });
    return added;
  }
  
  @override
  Future<void> deleteFoodLog(String logId) async {
    await _client.from('food_logs').delete().eq('id', logId);
    await _EventLogger.log('food', 'deleted', {'id': logId});
  }
}

class SupabaseWaterRepository implements WaterRepository {
  final SupabaseClient _client;
  
  SupabaseWaterRepository(this._client);
  
  @override
  Future<List<WaterLogModel>> getWaterLogs(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('water_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at', ascending: true);
    
    return (response as List).map((json) => WaterLogModel.fromJson(json)).toList();
  }
  
  @override
  Future<int> getTotalWater(String userId, DateTime date) async {
    final logs = await getWaterLogs(userId, date);
    return logs.fold<int>(0, (sum, log) => sum + log.ml);
  }
  
  @override
  Future<WaterLogModel> addWaterLog(WaterLogModel log) async {
    final response = await _client
        .from('water_logs')
        .insert(log.toJson())
        .select()
        .single();
    
    final added = WaterLogModel.fromJson(response);
    await _EventLogger.log('water', 'created', {
      'id': added.id,
      'ml': added.ml,
      'date': added.date.toIso8601String(),
    });
    return added;
  }
  
  @override
  Future<void> deleteWaterLog(String logId) async {
    await _client.from('water_logs').delete().eq('id', logId);
    await _EventLogger.log('water', 'deleted', {'id': logId});
  }
}

class SupabaseStepsRepository implements StepsRepository {
  final SupabaseClient _client;
  
  SupabaseStepsRepository(this._client);
  
  @override
  Future<StepsLogModel?> getSteps(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('steps_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();
    
    if (response == null) return null;
    return StepsLogModel.fromJson(response);
  }
  
  @override
  Future<List<StepsLogModel>> getStepsRange(String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('steps_logs')
        .select()
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0]);
    
    return (response as List).map((json) => StepsLogModel.fromJson(json)).toList();
  }
  
  @override
  Future<StepsLogModel> upsertSteps(StepsLogModel log) async {
    final response = await _client
        .from('steps_logs')
        .upsert(log.toJson())
        .select()
        .single();
    
    final updated = StepsLogModel.fromJson(response);
    await _EventLogger.log('steps', 'updated', {
      'id': updated.id,
      'steps': updated.steps,
      'date': updated.date.toIso8601String(),
    });
    return updated;
  }
}

class SupabaseSleepRepository implements SleepRepository {
  final SupabaseClient _client;
  
  SupabaseSleepRepository(this._client);
  
  @override
  Future<SleepLogModel?> getSleep(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final response = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId)
        .gte('end_ts', startOfDay.toIso8601String())
        .lt('end_ts', endOfDay.toIso8601String())
        .maybeSingle();
    
    if (response == null) return null;
    return SleepLogModel.fromJson(response);
  }
  
  @override
  Future<List<SleepLogModel>> getSleepRange(String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId)
        .gte('end_ts', start.toIso8601String())
        .lte('end_ts', end.toIso8601String());
    
    return (response as List).map((json) => SleepLogModel.fromJson(json)).toList();
  }
  
  @override
  Future<SleepLogModel> addSleep(SleepLogModel log) async {
    final response = await _client
        .from('sleep_logs')
        .insert(log.toJson())
        .select()
        .single();
    
    final added = SleepLogModel.fromJson(response);
    await _EventLogger.log('sleep', 'created', {
      'id': added.id,
      'durationMinutes': added.durationMinutes,
      'startTs': added.startTs.toIso8601String(),
      'endTs': added.endTs.toIso8601String(),
    });
    return added;
  }
  
  @override
  Future<void> deleteSleep(String logId) async {
    await _client.from('sleep_logs').delete().eq('id', logId);
    await _EventLogger.log('sleep', 'deleted', {'id': logId});
  }
}

class SupabaseMoodRepository implements MoodRepository {
  final SupabaseClient _client;
  
  SupabaseMoodRepository(this._client);
  
  @override
  Future<MoodLogModel?> getMood(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('mood_logs')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();
    
    if (response == null) return null;
    return MoodLogModel.fromJson(response);
  }
  
  @override
  Future<List<MoodLogModel>> getMoodRange(String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('mood_logs')
        .select()
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0]);
    
    return (response as List).map((json) => MoodLogModel.fromJson(json)).toList();
  }
  
  @override
  Future<MoodLogModel> upsertMood(MoodLogModel log) async {
    final response = await _client
        .from('mood_logs')
        .upsert(log.toJson())
        .select()
        .single();
    
    final updated = MoodLogModel.fromJson(response);
    await _EventLogger.log('mood', 'updated', {
      'id': updated.id,
      'mood': updated.mood,
      'note': updated.note,
      'date': updated.date.toIso8601String(),
    });
    return updated;
  }
}
