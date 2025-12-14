/// Abstract Repository Interfaces
/// These define the contract for data access, implemented by both
/// demo (in-memory) and production (Supabase) implementations

import '../models/models.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String? displayName);
  Future<void> signOut();
  Stream<UserModel?> authStateChanges();
}

abstract class SettingsRepository {
  Future<SettingsModel?> getSettings(String userId);
  Future<SettingsModel> updateSettings(SettingsModel settings);
}

abstract class TodoRepository {
  Future<List<TodoModel>> getTodos(String userId);
  Future<TodoModel> createTodo(TodoModel todo);
  Future<TodoModel> updateTodo(TodoModel todo);
  Future<void> deleteTodo(String todoId);
  Future<List<TodoOccurrence>> getOccurrences(String todoId);
  Future<List<TodoOccurrence>> getOccurrencesForDate(String userId, DateTime date);
  Future<TodoOccurrence> toggleOccurrence(String occurrenceId, bool done);
}

abstract class FoodRepository {
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> getProductByBarcode(String barcode);
  Future<ProductModel> addProduct(ProductModel product);
  Future<List<FoodLogModel>> getFoodLogs(String userId, DateTime date);
  Future<List<FoodLogModel>> getFoodLogsRange(String userId, DateTime start, DateTime end);
  Future<FoodLogModel> addFoodLog(FoodLogModel log);
  Future<void> deleteFoodLog(String logId);
}

abstract class WaterRepository {
  Future<List<WaterLogModel>> getWaterLogs(String userId, DateTime date);
  Future<int> getTotalWater(String userId, DateTime date);
  Future<WaterLogModel> addWaterLog(WaterLogModel log);
  Future<void> deleteWaterLog(String logId);
}

abstract class StepsRepository {
  Future<StepsLogModel?> getSteps(String userId, DateTime date);
  Future<List<StepsLogModel>> getStepsRange(String userId, DateTime start, DateTime end);
  Future<StepsLogModel> upsertSteps(StepsLogModel log);
}

abstract class SleepRepository {
  Future<SleepLogModel?> getSleep(String userId, DateTime date);
  Future<List<SleepLogModel>> getSleepRange(String userId, DateTime start, DateTime end);
  Future<SleepLogModel> addSleep(SleepLogModel log);
  Future<void> deleteSleep(String logId);
}

abstract class MoodRepository {
  Future<MoodLogModel?> getMood(String userId, DateTime date);
  Future<List<MoodLogModel>> getMoodRange(String userId, DateTime start, DateTime end);
  Future<MoodLogModel> upsertMood(MoodLogModel log);
}
