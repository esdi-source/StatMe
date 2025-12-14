import 'package:flutter_test/flutter_test.dart';
import 'package:stat_me/src/services/in_memory_database.dart';
import 'package:stat_me/src/services/demo_data_service.dart';
import 'package:stat_me/src/models/todo_model.dart';
import 'package:stat_me/src/models/food_model.dart';
import 'package:stat_me/src/models/water_model.dart';
import 'package:stat_me/src/models/steps_model.dart';
import 'package:stat_me/src/models/sleep_model.dart';
import 'package:stat_me/src/models/mood_model.dart';

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
          isRecurring: false,
          priority: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.createTodo(todo);
        final retrieved = await db.getTodo('todo-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('Test Todo'));
        expect(retrieved.description, equals('Test description'));
      });

      test('should update todo', () async {
        final todo = TodoModel(
          id: 'todo-2',
          userId: testUserId,
          title: 'Original Title',
          isRecurring: false,
          priority: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.createTodo(todo);
        
        final updated = todo.copyWith(title: 'Updated Title');
        await db.updateTodo(updated);

        final retrieved = await db.getTodo('todo-2');
        expect(retrieved!.title, equals('Updated Title'));
      });

      test('should delete todo', () async {
        final todo = TodoModel(
          id: 'todo-3',
          userId: testUserId,
          title: 'To Delete',
          isRecurring: false,
          priority: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.createTodo(todo);
        await db.deleteTodo('todo-3');

        final retrieved = await db.getTodo('todo-3');
        expect(retrieved, isNull);
      });

      test('should get todos by user', () async {
        await db.createTodo(TodoModel(
          id: 'todo-a',
          userId: testUserId,
          title: 'User Todo 1',
          isRecurring: false,
          priority: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        await db.createTodo(TodoModel(
          id: 'todo-b',
          userId: testUserId,
          title: 'User Todo 2',
          isRecurring: false,
          priority: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        await db.createTodo(TodoModel(
          id: 'todo-c',
          userId: 'other-user',
          title: 'Other User Todo',
          isRecurring: false,
          priority: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final userTodos = await db.getTodosByUser(testUserId);
        expect(userTodos.length, equals(2));
      });
    });

    group('Food Logs', () {
      test('should create and retrieve food log', () async {
        final foodLog = FoodLogModel(
          id: 'food-1',
          userId: testUserId,
          date: DateTime.now(),
          mealType: 'breakfast',
          servingSizeG: 100,
          calories: 250,
          protein: 10,
          carbs: 30,
          fat: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.createFoodLog(foodLog);
        final retrieved = await db.getFoodLog('food-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.calories, equals(250));
        expect(retrieved.mealType, equals('breakfast'));
      });

      test('should get food logs by date', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        await db.createFoodLog(FoodLogModel(
          id: 'food-today',
          userId: testUserId,
          date: today,
          mealType: 'lunch',
          servingSizeG: 200,
          calories: 500,
          protein: 20,
          carbs: 50,
          fat: 15,
          createdAt: today,
          updatedAt: today,
        ));

        await db.createFoodLog(FoodLogModel(
          id: 'food-yesterday',
          userId: testUserId,
          date: yesterday,
          mealType: 'dinner',
          servingSizeG: 300,
          calories: 700,
          protein: 30,
          carbs: 60,
          fat: 25,
          createdAt: yesterday,
          updatedAt: yesterday,
        ));

        final todayLogs = await db.getFoodLogsByDate(testUserId, today);
        expect(todayLogs.length, equals(1));
        expect(todayLogs.first.id, equals('food-today'));
      });
    });

    group('Water Logs', () {
      test('should create water log and calculate daily total', () async {
        final today = DateTime.now();

        await db.createWaterLog(WaterLogModel(
          id: 'water-1',
          userId: testUserId,
          date: today,
          amountMl: 250,
          loggedAt: today,
          createdAt: today,
        ));

        await db.createWaterLog(WaterLogModel(
          id: 'water-2',
          userId: testUserId,
          date: today,
          amountMl: 500,
          loggedAt: today,
          createdAt: today,
        ));

        final logs = await db.getWaterLogsByDate(testUserId, today);
        final total = logs.fold<int>(0, (sum, log) => sum + log.amountMl);

        expect(logs.length, equals(2));
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
          createdAt: today,
          updatedAt: today,
        );

        await db.createStepsLog(stepsLog);
        
        final updated = stepsLog.copyWith(steps: 8000);
        await db.updateStepsLog(updated);

        final retrieved = await db.getStepsLog('steps-1');
        expect(retrieved!.steps, equals(8000));
      });
    });

    group('Sleep Logs', () {
      test('should calculate sleep duration correctly', () async {
        final today = DateTime.now();
        final bedtime = DateTime(today.year, today.month, today.day - 1, 23, 0);
        final wakeTime = DateTime(today.year, today.month, today.day, 7, 0);

        final sleepLog = SleepLogModel(
          id: 'sleep-1',
          userId: testUserId,
          date: today,
          bedtime: bedtime,
          wakeTime: wakeTime,
          quality: 4,
          createdAt: today,
          updatedAt: today,
        );

        expect(sleepLog.durationHours, equals(8.0));
      });
    });

    group('Mood Logs', () {
      test('should create mood log with tags', () async {
        final today = DateTime.now();

        final moodLog = MoodLogModel(
          id: 'mood-1',
          userId: testUserId,
          date: today,
          moodScore: 8,
          energyLevel: 7,
          stressLevel: 3,
          notes: 'Feeling great!',
          tags: ['happy', 'productive'],
          loggedAt: today,
          createdAt: today,
        );

        await db.createMoodLog(moodLog);
        final retrieved = await db.getMoodLog('mood-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.moodScore, equals(8));
        expect(retrieved.tags, contains('happy'));
        expect(retrieved.tags, contains('productive'));
      });
    });
  });

  group('DemoDataService', () {
    test('should generate demo user', () {
      final user = DemoDataService.generateDemoUser();
      expect(user.id, equals('demo-user-id'));
      expect(user.email, equals('demo@statme.app'));
    });

    test('should generate demo todos', () {
      final todos = DemoDataService.generateDemoTodos();
      expect(todos, isNotEmpty);
      expect(todos.every((t) => t.userId == 'demo-user-id'), isTrue);
    });

    test('should generate demo food logs', () {
      final foodLogs = DemoDataService.generateDemoFoodLogs();
      expect(foodLogs, isNotEmpty);
      
      // Should have entries for multiple days
      final uniqueDates = foodLogs.map((f) => 
        DateTime(f.date.year, f.date.month, f.date.day)
      ).toSet();
      expect(uniqueDates.length, greaterThan(1));
    });

    test('should generate demo water logs', () {
      final waterLogs = DemoDataService.generateDemoWaterLogs();
      expect(waterLogs, isNotEmpty);
    });

    test('should generate demo steps logs', () {
      final stepsLogs = DemoDataService.generateDemoStepsLogs();
      expect(stepsLogs, isNotEmpty);
      
      // Steps should be reasonable values
      for (final log in stepsLogs) {
        expect(log.steps, greaterThan(0));
        expect(log.steps, lessThan(50000));
      }
    });

    test('should generate demo sleep logs', () {
      final sleepLogs = DemoDataService.generateDemoSleepLogs();
      expect(sleepLogs, isNotEmpty);
      
      // Sleep duration should be reasonable
      for (final log in sleepLogs) {
        expect(log.durationHours, greaterThan(4));
        expect(log.durationHours, lessThan(14));
      }
    });

    test('should generate demo mood logs', () {
      final moodLogs = DemoDataService.generateDemoMoodLogs();
      expect(moodLogs, isNotEmpty);
      
      // Mood scores should be in valid range
      for (final log in moodLogs) {
        expect(log.moodScore, greaterThanOrEqualTo(1));
        expect(log.moodScore, lessThanOrEqualTo(10));
      }
    });

    test('should generate demo settings', () {
      final settings = DemoDataService.generateDemoSettings();
      expect(settings.userId, equals('demo-user-id'));
      expect(settings.dailyCalorieGoal, greaterThan(0));
      expect(settings.dailyWaterGoalMl, greaterThan(0));
      expect(settings.dailyStepsGoal, greaterThan(0));
    });
  });
}
