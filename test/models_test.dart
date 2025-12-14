import 'package:flutter_test/flutter_test.dart';
import 'package:stat_me/src/models/todo_model.dart';
import 'package:stat_me/src/models/food_model.dart';
import 'package:stat_me/src/models/water_model.dart';
import 'package:stat_me/src/models/steps_model.dart';
import 'package:stat_me/src/models/sleep_model.dart';
import 'package:stat_me/src/models/mood_model.dart';
import 'package:stat_me/src/models/settings_model.dart';
import 'package:stat_me/src/models/user_model.dart';

void main() {
  group('TodoModel', () {
    test('should create from JSON', () {
      final json = {
        'id': 'todo-1',
        'user_id': 'user-1',
        'title': 'Test Todo',
        'description': 'Test description',
        'is_recurring': true,
        'rrule': 'FREQ=DAILY',
        'due_date': '2024-01-15',
        'priority': 2,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final todo = TodoModel.fromJson(json);

      expect(todo.id, equals('todo-1'));
      expect(todo.userId, equals('user-1'));
      expect(todo.title, equals('Test Todo'));
      expect(todo.isRecurring, isTrue);
      expect(todo.rrule, equals('FREQ=DAILY'));
      expect(todo.priority, equals(2));
    });

    test('should convert to JSON', () {
      final todo = TodoModel(
        id: 'todo-1',
        userId: 'user-1',
        title: 'Test Todo',
        isRecurring: false,
        priority: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = todo.toJson();

      expect(json['id'], equals('todo-1'));
      expect(json['user_id'], equals('user-1'));
      expect(json['title'], equals('Test Todo'));
      expect(json['is_recurring'], isFalse);
      expect(json['priority'], equals(1));
    });

    test('copyWith should create modified copy', () {
      final original = TodoModel(
        id: 'todo-1',
        userId: 'user-1',
        title: 'Original',
        isRecurring: false,
        priority: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modified = original.copyWith(
        title: 'Modified',
        priority: 2,
      );

      expect(modified.id, equals('todo-1'));
      expect(modified.title, equals('Modified'));
      expect(modified.priority, equals(2));
      expect(original.title, equals('Original')); // Original unchanged
    });
  });

  group('TodoOccurrenceModel', () {
    test('should create from JSON', () {
      final json = {
        'id': 'occ-1',
        'todo_id': 'todo-1',
        'user_id': 'user-1',
        'occurrence_date': '2024-01-15',
        'is_completed': true,
        'completed_at': '2024-01-15T10:30:00.000Z',
        'notes': 'Done!',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-15T10:30:00.000Z',
      };

      final occurrence = TodoOccurrenceModel.fromJson(json);

      expect(occurrence.isCompleted, isTrue);
      expect(occurrence.completedAt, isNotNull);
      expect(occurrence.notes, equals('Done!'));
    });
  });

  group('FoodLogModel', () {
    test('should calculate calories from serving size', () {
      final product = ProductModel(
        id: 'prod-1',
        barcode: '1234567890',
        name: 'Test Food',
        caloriesPer100g: 200,
        proteinPer100g: 10,
        carbsPer100g: 25,
        fatPer100g: 8,
        fiberPer100g: 3,
        sugarPer100g: 5,
        sodiumPer100g: 100,
        servingSizeG: 100,
        source: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 150g serving of a 200 cal/100g food = 300 calories
      final log = FoodLogModel(
        id: 'log-1',
        userId: 'user-1',
        productId: product.id,
        date: DateTime.now(),
        mealType: 'lunch',
        servingSizeG: 150,
        calories: (product.caloriesPer100g * 150 / 100),
        protein: (product.proteinPer100g * 150 / 100),
        carbs: (product.carbsPer100g * 150 / 100),
        fat: (product.fatPer100g * 150 / 100),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(log.calories, equals(300));
      expect(log.protein, equals(15));
    });
  });

  group('SleepLogModel', () {
    test('should calculate duration correctly for same-day sleep', () {
      final today = DateTime(2024, 1, 15);
      final log = SleepLogModel(
        id: 'sleep-1',
        userId: 'user-1',
        date: today,
        bedtime: DateTime(2024, 1, 15, 10, 0), // 10:00 AM
        wakeTime: DateTime(2024, 1, 15, 12, 0), // 12:00 PM (nap)
        createdAt: today,
        updatedAt: today,
      );

      expect(log.durationHours, equals(2.0));
    });

    test('should calculate duration correctly for overnight sleep', () {
      final today = DateTime(2024, 1, 15);
      final log = SleepLogModel(
        id: 'sleep-1',
        userId: 'user-1',
        date: today,
        bedtime: DateTime(2024, 1, 14, 23, 0), // 11:00 PM previous day
        wakeTime: DateTime(2024, 1, 15, 7, 30), // 7:30 AM
        createdAt: today,
        updatedAt: today,
      );

      expect(log.durationHours, equals(8.5));
    });

    test('should handle decimal hours', () {
      final today = DateTime(2024, 1, 15);
      final log = SleepLogModel(
        id: 'sleep-1',
        userId: 'user-1',
        date: today,
        bedtime: DateTime(2024, 1, 14, 22, 45), // 10:45 PM
        wakeTime: DateTime(2024, 1, 15, 6, 15), // 6:15 AM
        createdAt: today,
        updatedAt: today,
      );

      expect(log.durationHours, equals(7.5));
    });
  });

  group('MoodLogModel', () {
    test('should handle empty tags', () {
      final json = {
        'id': 'mood-1',
        'user_id': 'user-1',
        'date': '2024-01-15',
        'mood_score': 7,
        'logged_at': '2024-01-15T10:00:00.000Z',
        'created_at': '2024-01-15T10:00:00.000Z',
      };

      final mood = MoodLogModel.fromJson(json);
      expect(mood.tags, isEmpty);
    });

    test('should parse tags from JSON', () {
      final json = {
        'id': 'mood-1',
        'user_id': 'user-1',
        'date': '2024-01-15',
        'mood_score': 7,
        'tags': ['happy', 'relaxed', 'productive'],
        'logged_at': '2024-01-15T10:00:00.000Z',
        'created_at': '2024-01-15T10:00:00.000Z',
      };

      final mood = MoodLogModel.fromJson(json);
      expect(mood.tags.length, equals(3));
      expect(mood.tags, contains('happy'));
    });
  });

  group('SettingsModel', () {
    test('should have correct default values', () {
      final settings = SettingsModel(
        id: 'settings-1',
        userId: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(settings.themeMode, equals('system'));
      expect(settings.locale, equals('en'));
      expect(settings.dailyCalorieGoal, equals(2000));
      expect(settings.dailyWaterGoalMl, equals(2000));
      expect(settings.dailyStepsGoal, equals(10000));
      expect(settings.sleepGoalHours, equals(8.0));
      expect(settings.notificationsEnabled, isTrue);
    });

    test('should copy with new values', () {
      final original = SettingsModel(
        id: 'settings-1',
        userId: 'user-1',
        dailyCalorieGoal: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modified = original.copyWith(
        dailyCalorieGoal: 2500,
        dailyStepsGoal: 12000,
      );

      expect(modified.dailyCalorieGoal, equals(2500));
      expect(modified.dailyStepsGoal, equals(12000));
      expect(modified.dailyWaterGoalMl, equals(2000)); // Unchanged
    });
  });

  group('UserModel', () {
    test('should create from JSON', () {
      final json = {
        'id': 'user-1',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'avatar_url': 'https://example.com/avatar.jpg',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('user-1'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
      expect(user.avatarUrl, equals('https://example.com/avatar.jpg'));
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 'user-1',
        'email': 'test@example.com',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
    });
  });
}
