/// Demo Repository Implementations
/// Uses InMemoryDatabase for demo mode - no external connections required

import 'dart:async';
import '../models/models.dart';
import '../services/in_memory_database.dart';
import 'repository_interfaces.dart';

class DemoAuthRepository implements AuthRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  final _authController = StreamController<UserModel?>.broadcast();
  
  @override
  Future<UserModel?> getCurrentUser() async {
    return _db.currentUser;
  }
  
  @override
  Future<UserModel> signIn(String email, String password) async {
    final user = await _db.signIn(email, password);
    _authController.add(user);
    return user;
  }
  
  @override
  Future<UserModel> signUp(String email, String password, String? displayName) async {
    final user = await _db.signUp(email, password, displayName);
    _authController.add(user);
    return user;
  }
  
  @override
  Future<void> signOut() async {
    await _db.signOut();
    _authController.add(null);
  }
  
  @override
  Stream<UserModel?> authStateChanges() {
    // Emit current user immediately
    Future.microtask(() => _authController.add(_db.currentUser));
    return _authController.stream;
  }
}

class DemoSettingsRepository implements SettingsRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<SettingsModel?> getSettings(String userId) async {
    return _db.settings;
  }
  
  @override
  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    return await _db.updateSettings(settings);
  }
}

class DemoTodoRepository implements TodoRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<TodoModel>> getTodos(String userId) async {
    return _db.getTodosForUser(userId);
  }
  
  @override
  Future<TodoModel> createTodo(TodoModel todo) async {
    return await _db.createTodo(todo);
  }
  
  @override
  Future<TodoModel> updateTodo(TodoModel todo) async {
    return await _db.updateTodo(todo);
  }
  
  @override
  Future<void> deleteTodo(String todoId) async {
    await _db.deleteTodo(todoId);
  }
  
  @override
  Future<List<TodoOccurrence>> getOccurrences(String todoId) async {
    return _db.getOccurrencesForTodo(todoId);
  }
  
  @override
  Future<List<TodoOccurrence>> getOccurrencesForDate(String userId, DateTime date) async {
    return _db.getOccurrencesForDate(userId, date);
  }
  
  @override
  Future<TodoOccurrence> toggleOccurrence(String occurrenceId, bool done) async {
    return await _db.toggleOccurrence(occurrenceId, done);
  }
}

class DemoFoodRepository implements FoodRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate search
    return _db.searchProducts(query);
  }
  
  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _db.findProductByBarcode(barcode);
  }
  
  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    return await _db.addProduct(product);
  }
  
  @override
  Future<List<FoodLogModel>> getFoodLogs(String userId, DateTime date) async {
    return _db.getFoodLogsForDate(userId, date);
  }
  
  @override
  Future<List<FoodLogModel>> getFoodLogsRange(String userId, DateTime start, DateTime end) async {
    return _db.getFoodLogsForRange(userId, start, end);
  }
  
  @override
  Future<FoodLogModel> addFoodLog(FoodLogModel log) async {
    return await _db.addFoodLog(log);
  }
  
  @override
  Future<void> deleteFoodLog(String logId) async {
    await _db.deleteFoodLog(logId);
  }
}

class DemoWaterRepository implements WaterRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<WaterLogModel>> getWaterLogs(String userId, DateTime date) async {
    return _db.getWaterLogsForDate(userId, date);
  }
  
  @override
  Future<int> getTotalWater(String userId, DateTime date) async {
    return _db.getTotalWaterForDate(userId, date);
  }
  
  @override
  Future<WaterLogModel> addWaterLog(WaterLogModel log) async {
    return await _db.addWaterLog(log);
  }
  
  @override
  Future<void> deleteWaterLog(String logId) async {
    await _db.deleteWaterLog(logId);
  }
}

class DemoStepsRepository implements StepsRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<StepsLogModel?> getSteps(String userId, DateTime date) async {
    return _db.getStepsForDate(userId, date);
  }
  
  @override
  Future<List<StepsLogModel>> getStepsRange(String userId, DateTime start, DateTime end) async {
    return _db.getStepsForRange(userId, start, end);
  }
  
  @override
  Future<StepsLogModel> upsertSteps(StepsLogModel log) async {
    return await _db.upsertStepsLog(log);
  }
}

class DemoSleepRepository implements SleepRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<SleepLogModel?> getSleep(String userId, DateTime date) async {
    return _db.getSleepForDate(userId, date);
  }
  
  @override
  Future<List<SleepLogModel>> getSleepRange(String userId, DateTime start, DateTime end) async {
    return _db.getSleepForRange(userId, start, end);
  }
  
  @override
  Future<SleepLogModel> addSleep(SleepLogModel log) async {
    return await _db.addSleepLog(log);
  }
  
  @override
  Future<void> deleteSleep(String logId) async {
    await _db.deleteSleepLog(logId);
  }
}

class DemoMoodRepository implements MoodRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<MoodLogModel?> getMood(String userId, DateTime date) async {
    return _db.getMoodForDate(userId, date);
  }
  
  @override
  Future<List<MoodLogModel>> getMoodRange(String userId, DateTime start, DateTime end) async {
    return _db.getMoodForRange(userId, start, end);
  }
  
  @override
  Future<MoodLogModel> upsertMood(MoodLogModel log) async {
    return await _db.upsertMoodLog(log);
  }
}

class DemoBookRepository implements BookRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<BookModel>> getBooks(String userId) async {
    return _db.getBooksForUser(userId);
  }
  
  @override
  Future<List<BookModel>> getBooksByStatus(String userId, BookStatus status) async {
    return _db.getBooksByStatus(userId, status);
  }
  
  @override
  Future<BookModel> addBook(BookModel book) async {
    return await _db.addBook(book);
  }
  
  @override
  Future<BookModel> updateBook(BookModel book) async {
    return await _db.updateBook(book);
  }
  
  @override
  Future<void> deleteBook(String bookId) async {
    await _db.deleteBook(bookId);
  }
  
  @override
  Future<ReadingGoalModel?> getReadingGoal(String userId) async {
    return _db.getReadingGoal(userId);
  }
  
  @override
  Future<ReadingGoalModel> upsertReadingGoal(ReadingGoalModel goal) async {
    return await _db.upsertReadingGoal(goal);
  }
  
  @override
  Future<void> addReadingSession(String oderId, ReadingSession session) async {
    await _db.addReadingSession(oderId, session);
  }
}
