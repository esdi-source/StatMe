import 'package:flutter_test/flutter_test.dart';
import 'package:statme/src/models/todo_model.dart';
import 'package:statme/src/models/food_model.dart';
import 'package:statme/src/models/sleep_model.dart';
import 'package:statme/src/models/mood_model.dart';
import 'package:statme/src/models/settings_model.dart';
import 'package:statme/src/models/user_model.dart';

void main() {
  group('TodoModel', () {
    test('should create from JSON', () {
      final json = {
        'id': 'todo-1',
        'user_id': 'user-1',
        'title': 'Test Todo',
        'description': 'Test description',
        'rrule_text': 'FREQ=DAILY',
        'start_date': '2024-01-15T00:00:00.000Z',
        'priority': 'medium',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final todo = TodoModel.fromJson(json);

      expect(todo.id, equals('todo-1'));
      expect(todo.userId, equals('user-1'));
      expect(todo.title, equals('Test Todo'));
      expect(todo.recurrenceType, equals(RecurrenceType.daily));
      expect(todo.rruleText, equals('FREQ=DAILY'));
      expect(todo.priority, equals(TodoPriority.medium));
    });

    test('should convert to JSON', () {
      final todo = TodoModel(
        id: 'todo-1',
        userId: 'user-1',
        title: 'Test Todo',
        startDate: DateTime(2024, 1, 15),
        priority: TodoPriority.low,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = todo.toJson();

      expect(json['id'], equals('todo-1'));
      expect(json['user_id'], equals('user-1'));
      expect(json['title'], equals('Test Todo'));
      expect(json['priority'], equals('low'));
    });
  });

  group('TodoOccurrence', () {
    test('should create from JSON', () {
      final json = {
        'id': 'occ-1',
        'todo_id': 'todo-1',
        'user_id': 'user-1',
        'due_at': '2024-01-15T10:30:00.000Z',
        'done': true,
        'reminder_sent': false,
      };

      final occurrence = TodoOccurrence.fromJson(json);

      expect(occurrence.done, isTrue);
      expect(occurrence.dueAt, isNotNull);
    });
  });

  group('FoodLogModel', () {
    test('should create with required fields', () {
      final product = ProductModel(
        id: 'prod-1',
        barcode: '1234567890',
        productName: 'Test Food',
        kcalPer100g: 200,
        proteinPer100g: 10,
        carbsPer100g: 25,
        fatPer100g: 8,
        fiberPer100g: 3,
        lastChecked: DateTime.now(),
      );

      final log = FoodLogModel(
        id: 'log-1',
        userId: 'user-1',
        productId: product.id!,
        productName: product.productName,
        date: DateTime.now(),
        grams: 150,
        calories: (product.kcalPer100g * 150 / 100),
        createdAt: DateTime.now(),
      );

      expect(log.calories, equals(300));
    });
  });

  group('SleepLogModel', () {
    test('should calculate duration correctly', () {
      final start = DateTime(2024, 1, 15, 22, 0); // 10:00 PM
      final end = DateTime(2024, 1, 16, 6, 0); // 6:00 AM
      
      final log = SleepLogModel.calculate(
        id: 'sleep-1',
        userId: 'user-1',
        startTs: start,
        endTs: end,
      );

      expect(log.durationMinutes, equals(480)); // 8 hours * 60 minutes
    });
  });

  group('MoodLogModel', () {
    test('should handle optional fields', () {
      final json = {
        'id': 'mood-1',
        'user_id': 'user-1',
        'date': '2024-01-15',
        'mood_level': 7,
        'stress_level': 3,
      };

      final mood = MoodLogModel.fromJson(json);
      expect(mood.mood, equals(7));
      expect(mood.stressLevel, equals(3));
      expect(mood.energyLevel, isNull);
    });
  });

  group('SettingsModel', () {
    test('should have correct default values', () {
      const settings = SettingsModel(
        id: 'settings-1',
        userId: 'user-1',
      );

      expect(settings.darkMode, isFalse);
      expect(settings.locale, equals('de_DE'));
      expect(settings.dailyCalorieGoal, equals(2000));
      expect(settings.dailyWaterGoalMl, equals(2500));
      expect(settings.dailyStepsGoal, equals(10000));
      expect(settings.notificationsEnabled, isTrue);
    });

    test('should copy with new values', () {
      const original = SettingsModel(
        id: 'settings-1',
        userId: 'user-1',
        dailyCalorieGoal: 2000,
      );

      final modified = original.copyWith(
        dailyCalorieGoal: 2500,
        dailyStepsGoal: 12000,
      );

      expect(modified.dailyCalorieGoal, equals(2500));
      expect(modified.dailyStepsGoal, equals(12000));
      expect(modified.dailyWaterGoalMl, equals(2500)); // Unchanged
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
