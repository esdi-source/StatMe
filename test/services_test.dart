import 'package:flutter_test/flutter_test.dart';
import 'package:statme/src/services/in_memory_database.dart';
import 'package:statme/src/services/demo_data_service.dart';
import 'package:statme/src/models/todo_model.dart';
import 'package:statme/src/models/food_model.dart';
import 'package:statme/src/models/water_model.dart';
import 'package:statme/src/models/steps_model.dart';
import 'package:statme/src/models/sleep_model.dart';
import 'package:statme/src/models/mood_model.dart';

void main() {
  group('InMemoryDatabase', () {
    late InMemoryDatabase db;
    const testUserId = 'test-user-123';

    setUp(() {
      db = InMemoryDatabase();
      db.initialize();
    });

    group('Todos', () {
      test('should create and retrieve todo', () async {
        final todo = TodoModel(
          id: 'todo-1',
          userId: testUserId,
          title: 'Test Todo',
          description: 'Test description',
          startDate: DateTime.now(),
          priority: TodoPriority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await db.createTodo(todo);
        final todos = db.getTodosForUser(testUserId);
        final retrieved = todos.firstWhere((t) => t.id == created.id);

        expect(retrieved.title, equals('Test Todo'));
        expect(retrieved.description, equals('Test description'));
      });

      test('should update todo', () async {
        final todo = TodoModel(
          id: 'todo-2',
          userId: testUserId,
          title: 'Original Title',
          startDate: DateTime.now(),
          priority: TodoPriority.low,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await db.createTodo(todo);
        
        final updated = created.copyWith(title: 'Updated Title');
        await db.updateTodo(updated);

        final todos = db.getTodosForUser(testUserId);
        final retrieved = todos.firstWhere((t) => t.id == created.id);
        expect(retrieved.title, equals('Updated Title'));
      });

      test('should delete todo', () async {
        final todo = TodoModel(
          id: 'todo-3',
          userId: testUserId,
          title: 'To Delete',
          startDate: DateTime.now(),
          priority: TodoPriority.low,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await db.createTodo(todo);
        await db.deleteTodo(created.id);

        final todos = db.getTodosForUser(testUserId);
        expect(todos.any((t) => t.id == created.id), isFalse);
      });

      test('should get todos by user', () async {
        await db.createTodo(TodoModel(
          id: 'todo-a',
          userId: testUserId,
          title: 'User Todo 1',
          startDate: DateTime.now(),
          priority: TodoPriority.low,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        await db.createTodo(TodoModel(
          id: 'todo-b',
          userId: testUserId,
          title: 'User Todo 2',
          startDate: DateTime.now(),
          priority: TodoPriority.low,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        await db.createTodo(TodoModel(
          id: 'todo-c',
          userId: 'other-user',
          title: 'Other User Todo',
          startDate: DateTime.now(),
          priority: TodoPriority.low,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final userTodos = db.getTodosForUser(testUserId);
        expect(userTodos.length, greaterThanOrEqualTo(2));
        expect(userTodos.any((t) => t.userId == 'other-user'), isFalse);
      });
    });

    group('Food Logs', () {
      test('should create and retrieve food log', () async {
        final foodLog = FoodLogModel(
          id: 'food-1',
          userId: testUserId,
          productId: 'prod-1',
          productName: 'Test Food',
          date: DateTime.now(),
          grams: 100,
          calories: 200,
          createdAt: DateTime.now(),
        );

        final created = await db.addFoodLog(foodLog);
        final logs = db.getFoodLogsForDate(testUserId, DateTime.now());
        final retrieved = logs.firstWhere((l) => l.id == created.id);

        expect(retrieved.productName, equals('Test Food'));
        expect(retrieved.calories, equals(200));
      });

      test('should delete food log', () async {
        final foodLog = FoodLogModel(
          id: 'food-2',
          userId: testUserId,
          productId: 'prod-2',
          productName: 'To Delete',
          date: DateTime.now(),
          grams: 100,
          calories: 200,
          createdAt: DateTime.now(),
        );

        final created = await db.addFoodLog(foodLog);
        await db.deleteFoodLog(created.id);

        final logs = db.getFoodLogsForDate(testUserId, DateTime.now());
        expect(logs.any((l) => l.id == created.id), isFalse);
      });
    });

    group('Water Logs', () {
      test('should create water log and calculate daily total', () async {
        final today = DateTime.now();

        await db.addWaterLog(WaterLogModel(
          id: 'water-1',
          userId: testUserId,
          date: today,
          ml: 250,
          createdAt: today,
        ));

        await db.addWaterLog(WaterLogModel(
          id: 'water-2',
          userId: testUserId,
          date: today,
          ml: 500,
          createdAt: today,
        ));

        final total = db.getTotalWaterForDate(testUserId, today);
        expect(total, equals(750));
      });
    });

    group('Steps Logs', () {
      test('should create and update steps log', () async {
        final today = DateTime.now();

        final stepsLog = StepsLogModel(
          id: 'steps-1',
          userId: testUserId,
          date: today,
          steps: 5000,
          source: 'manual',
        );

        await db.upsertStepsLog(stepsLog);
        
        final updated = stepsLog.copyWith(steps: 8000);
        await db.upsertStepsLog(updated);

        final retrieved = db.getStepsForDate(testUserId, today);
        expect(retrieved!.steps, equals(8000));
      });
    });

    group('Sleep Logs', () {
      test('should calculate sleep duration correctly', () async {
        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day - 1, 23, 0);
        final end = DateTime(today.year, today.month, today.day, 7, 0);

        final sleepLog = SleepLogModel.calculate(
          id: 'sleep-1',
          userId: testUserId,
          startTs: start,
          endTs: end,
          quality: 4,
        );

        expect(sleepLog.durationMinutes, equals(480));
      });
    });

    group('Mood Logs', () {
      test('should create mood log', () async {
        final today = DateTime.now();

        final moodLog = MoodLogModel(
          id: 'mood-1',
          userId: testUserId,
          date: today,
          mood: 8,
          stressLevel: 3,
          note: 'Feeling great!',
        );

        await db.upsertMoodLog(moodLog);
        final retrieved = db.getMoodForDate(testUserId, today);
        
        expect(retrieved, isNotNull);
        expect(retrieved!.mood, equals(8));
        expect(retrieved.note, equals('Feeling great!'));
      });
    });
  });

  group('DemoDataService', () {
    test('should generate demo user', () {
      final user = DemoDataService.getDemoUser();
      expect(user.id, equals('demo-user-001'));
      expect(user.email, equals('demo@statme.app'));
    });

    test('should generate demo todos', () {
      final todos = DemoDataService.getDemoTodos();
      expect(todos, isNotEmpty);
      expect(todos.every((t) => t.userId == 'demo-user-001'), isTrue);
    });

    test('should generate demo food logs', () {
      final foodLogs = DemoDataService.getDemoFoodLogs();
      expect(foodLogs, isNotEmpty);
      
      // Should have entries for multiple days
      final uniqueDates = foodLogs.map((f) => 
        DateTime(f.date.year, f.date.month, f.date.day)
      ).toSet();
      expect(uniqueDates.length, greaterThan(1));
    });

    test('should generate demo water logs', () {
      final waterLogs = DemoDataService.getDemoWaterLogs();
      expect(waterLogs, isNotEmpty);
    });

    test('should generate demo steps logs', () {
      final stepsLogs = DemoDataService.getDemoStepsLogs();
      expect(stepsLogs, isNotEmpty);
      
      // Steps should be reasonable values
      for (final log in stepsLogs) {
        expect(log.steps, greaterThan(0));
        expect(log.steps, lessThan(50000));
      }
    });

    test('should generate demo sleep logs', () {
      final sleepLogs = DemoDataService.getDemoSleepLogs();
      expect(sleepLogs, isNotEmpty);
      
      // Sleep duration should be reasonable
      for (final log in sleepLogs) {
        expect(log.durationMinutes, greaterThan(240)); // > 4 hours
        expect(log.durationMinutes, lessThan(840)); // < 14 hours
      }
    });

    test('should generate demo mood logs', () {
      final moodLogs = DemoDataService.getDemoMoodLogs();
      expect(moodLogs, isNotEmpty);
      
      // Mood scores should be in valid range
      for (final log in moodLogs) {
        expect(log.mood, greaterThanOrEqualTo(1));
        expect(log.mood, lessThanOrEqualTo(10));
      }
    });

    test('should generate demo settings', () {
      final settings = DemoDataService.getDemoSettings();
      expect(settings.userId, equals('demo-user-001'));
      expect(settings.dailyCalorieGoal, greaterThan(0));
      expect(settings.dailyWaterGoalMl, greaterThan(0));
      expect(settings.dailyStepsGoal, greaterThan(0));
    });
  });
}
