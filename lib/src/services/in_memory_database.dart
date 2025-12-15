/// In-Memory Database for Demo Mode
/// Stores all data locally without any external connections

import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'demo_data_service.dart';

class InMemoryDatabase {
  static final InMemoryDatabase _instance = InMemoryDatabase._internal();
  factory InMemoryDatabase() => _instance;
  InMemoryDatabase._internal();

  static const _uuid = Uuid();
  
  bool _initialized = false;
  
  // Data stores
  UserModel? _currentUser;
  SettingsModel? _settings;
  final List<TodoModel> _todos = [];
  final List<TodoOccurrence> _occurrences = [];
  final List<ProductModel> _products = [];
  final List<FoodLogModel> _foodLogs = [];
  final List<WaterLogModel> _waterLogs = [];
  final List<StepsLogModel> _stepsLogs = [];
  final List<SleepLogModel> _sleepLogs = [];
  final List<MoodLogModel> _moodLogs = [];

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Load demo data
    _currentUser = DemoDataService.getDemoUser();
    _settings = DemoDataService.getDemoSettings();
    _todos.addAll(DemoDataService.getDemoTodos());
    _occurrences.addAll(DemoDataService.getDemoOccurrences(_todos));
    _products.addAll(DemoDataService.getDemoProducts());
    _foodLogs.addAll(DemoDataService.getDemoFoodLogs());
    _waterLogs.addAll(DemoDataService.getDemoWaterLogs());
    _stepsLogs.addAll(DemoDataService.getDemoStepsLogs());
    _sleepLogs.addAll(DemoDataService.getDemoSleepLogs());
    _moodLogs.addAll(DemoDataService.getDemoMoodLogs());
    
    _initialized = true;
    print('InMemoryDatabase initialized with demo data');
  }

  void reset() {
    _initialized = false;
    _currentUser = null;
    _settings = null;
    _todos.clear();
    _occurrences.clear();
    _products.clear();
    _foodLogs.clear();
    _waterLogs.clear();
    _stepsLogs.clear();
    _sleepLogs.clear();
    _moodLogs.clear();
  }

  // Auth
  UserModel? get currentUser => _currentUser;
  
  Future<UserModel> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network
    _currentUser = DemoDataService.getDemoUser().copyWith(
      email: email,
      lastLoginAt: DateTime.now(),
    );
    return _currentUser!;
  }
  
  Future<UserModel> signUp(String email, String password, String? displayName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(
      id: _uuid.v4(),
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _settings = SettingsModel(
      id: _uuid.v4(),
      userId: _currentUser!.id,
    );
    return _currentUser!;
  }
  
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Keep demo data but "log out"
  }

  // Settings
  SettingsModel? get settings => _settings;
  
  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = settings;
    return _settings!;
  }

  // Todos
  List<TodoModel> get todos => List.unmodifiable(_todos);
  
  List<TodoModel> getTodosForUser(String userId) {
    return _todos.where((t) => t.userId == userId).toList();
  }
  
  Future<TodoModel> createTodo(TodoModel todo) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newTodo = todo.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _todos.add(newTodo);
    return newTodo;
  }
  
  Future<TodoModel> updateTodo(TodoModel todo) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index >= 0) {
      final updated = todo.copyWith(updatedAt: DateTime.now());
      _todos[index] = updated;
      return updated;
    }
    throw Exception('Todo not found');
  }
  
  Future<void> deleteTodo(String todoId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _todos.removeWhere((t) => t.id == todoId);
    _occurrences.removeWhere((o) => o.todoId == todoId);
  }

  // Todo Occurrences
  List<TodoOccurrence> getOccurrencesForTodo(String todoId) {
    return _occurrences.where((o) => o.todoId == todoId).toList();
  }
  
  List<TodoOccurrence> getOccurrencesForDate(String userId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _occurrences.where((o) {
      final occDate = DateTime(o.dueAt.year, o.dueAt.month, o.dueAt.day);
      return o.userId == userId && occDate == dateOnly;
    }).toList();
  }
  
  Future<TodoOccurrence> toggleOccurrence(String occurrenceId, bool done) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index >= 0) {
      final updated = _occurrences[index].copyWith(done: done);
      _occurrences[index] = updated;
      return updated;
    }
    throw Exception('Occurrence not found');
  }

  // Products
  List<ProductModel> get products => List.unmodifiable(_products);
  
  ProductModel? findProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }
  
  List<ProductModel> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products
        .where((p) => p.productName.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
  
  Future<ProductModel> addProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newProduct = ProductModel(
      id: _uuid.v4(),
      barcode: product.barcode,
      productName: product.productName,
      kcalPer100g: product.kcalPer100g,
      proteinPer100g: product.proteinPer100g,
      carbsPer100g: product.carbsPer100g,
      fatPer100g: product.fatPer100g,
      fiberPer100g: product.fiberPer100g,
      rawApi: product.rawApi,
      lastChecked: DateTime.now(),
    );
    _products.add(newProduct);
    return newProduct;
  }

  // Food Logs
  List<FoodLogModel> getFoodLogsForDate(String userId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _foodLogs.where((f) {
      final logDate = DateTime(f.date.year, f.date.month, f.date.day);
      return f.userId == userId && logDate == dateOnly;
    }).toList();
  }
  
  List<FoodLogModel> getFoodLogsForRange(String userId, DateTime start, DateTime end) {
    return _foodLogs.where((f) {
      return f.userId == userId && 
             f.date.isAfter(start.subtract(const Duration(days: 1))) && 
             f.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  Future<FoodLogModel> addFoodLog(FoodLogModel log) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newLog = log.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _foodLogs.add(newLog);
    return newLog;
  }
  
  Future<void> deleteFoodLog(String logId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _foodLogs.removeWhere((f) => f.id == logId);
  }

  // Water Logs
  List<WaterLogModel> getWaterLogsForDate(String userId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _waterLogs.where((w) {
      final logDate = DateTime(w.date.year, w.date.month, w.date.day);
      return w.userId == userId && logDate == dateOnly;
    }).toList();
  }
  
  int getTotalWaterForDate(String userId, DateTime date) {
    return getWaterLogsForDate(userId, date).fold(0, (sum, w) => sum + w.ml);
  }
  
  Future<WaterLogModel> addWaterLog(WaterLogModel log) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newLog = log.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _waterLogs.add(newLog);
    return newLog;
  }
  
  Future<void> deleteWaterLog(String logId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _waterLogs.removeWhere((w) => w.id == logId);
  }

  // Steps Logs
  StepsLogModel? getStepsForDate(String userId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return _stepsLogs.firstWhere((s) {
        final logDate = DateTime(s.date.year, s.date.month, s.date.day);
        return s.userId == userId && logDate == dateOnly;
      });
    } catch (_) {
      return null;
    }
  }
  
  List<StepsLogModel> getStepsForRange(String userId, DateTime start, DateTime end) {
    return _stepsLogs.where((s) {
      return s.userId == userId && 
             s.date.isAfter(start.subtract(const Duration(days: 1))) && 
             s.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  Future<StepsLogModel> upsertStepsLog(StepsLogModel log) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final dateOnly = DateTime(log.date.year, log.date.month, log.date.day);
    final existingIndex = _stepsLogs.indexWhere((s) {
      final logDate = DateTime(s.date.year, s.date.month, s.date.day);
      return s.userId == log.userId && logDate == dateOnly;
    });
    
    if (existingIndex >= 0) {
      _stepsLogs[existingIndex] = log;
      return log;
    } else {
      final newLog = log.copyWith(id: _uuid.v4());
      _stepsLogs.add(newLog);
      return newLog;
    }
  }

  // Sleep Logs
  SleepLogModel? getSleepForDate(String userId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return _sleepLogs.firstWhere((s) {
        final logDate = DateTime(s.endTs.year, s.endTs.month, s.endTs.day);
        return s.userId == userId && logDate == dateOnly;
      });
    } catch (_) {
      return null;
    }
  }
  
  List<SleepLogModel> getSleepForRange(String userId, DateTime start, DateTime end) {
    return _sleepLogs.where((s) {
      return s.userId == userId && 
             s.endTs.isAfter(start.subtract(const Duration(days: 1))) && 
             s.endTs.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  Future<SleepLogModel> addSleepLog(SleepLogModel log) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newLog = log.copyWith(id: _uuid.v4());
    _sleepLogs.add(newLog);
    return newLog;
  }
  
  Future<void> deleteSleepLog(String logId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _sleepLogs.removeWhere((s) => s.id == logId);
  }

  // Mood Logs
  MoodLogModel? getMoodForDate(String userId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return _moodLogs.firstWhere((m) {
        final logDate = DateTime(m.date.year, m.date.month, m.date.day);
        return m.userId == userId && logDate == dateOnly;
      });
    } catch (_) {
      return null;
    }
  }
  
  List<MoodLogModel> getMoodForRange(String userId, DateTime start, DateTime end) {
    return _moodLogs.where((m) {
      return m.userId == userId && 
             m.date.isAfter(start.subtract(const Duration(days: 1))) && 
             m.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  Future<MoodLogModel> upsertMoodLog(MoodLogModel log) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final dateOnly = DateTime(log.date.year, log.date.month, log.date.day);
    final existingIndex = _moodLogs.indexWhere((m) {
      final logDate = DateTime(m.date.year, m.date.month, m.date.day);
      return m.userId == log.userId && logDate == dateOnly;
    });
    
    if (existingIndex >= 0) {
      _moodLogs[existingIndex] = log;
      return log;
    } else {
      final newLog = log.copyWith(id: _uuid.v4());
      _moodLogs.add(newLog);
      return newLog;
    }
  }

  // Books
  final List<BookModel> _books = [];
  final Map<String, ReadingGoalModel> _readingGoals = {};

  List<BookModel> getBooksForUser(String userId) {
    return _books.where((b) => b.oderId == userId).toList();
  }

  List<BookModel> getBooksByStatus(String userId, BookStatus status) {
    return _books.where((b) => b.oderId == userId && b.status == status).toList();
  }

  Future<BookModel> addBook(BookModel book) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newBook = book.copyWith(id: _uuid.v4());
    _books.add(newBook);
    return newBook;
  }

  Future<BookModel> updateBook(BookModel book) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index >= 0) {
      _books[index] = book;
    }
    return book;
  }

  Future<void> deleteBook(String bookId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _books.removeWhere((b) => b.id == bookId);
  }

  ReadingGoalModel? getReadingGoal(String userId) {
    return _readingGoals[userId];
  }

  Future<ReadingGoalModel> upsertReadingGoal(ReadingGoalModel goal) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _readingGoals[goal.oderId] = goal;
    return goal;
  }

  Future<void> addReadingSession(String oderId, ReadingSession session) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final goal = _readingGoals[oderId];
    if (goal != null) {
      final updatedSessions = [...goal.sessions, session];
      final updatedMinutes = goal.readMinutesThisWeek + session.durationMinutes;
      _readingGoals[oderId] = goal.copyWith(
        sessions: updatedSessions,
        readMinutesThisWeek: updatedMinutes,
      );
    }
  }
}
