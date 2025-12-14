import 'package:flutter_test/flutter_test.dart';
import 'package:stat_me/src/repositories/demo_repositories.dart';
import 'package:stat_me/src/services/in_memory_database.dart';
import 'package:stat_me/src/models/todo_model.dart';
import 'package:stat_me/src/models/water_model.dart';

void main() {
  group('DemoTodoRepository', () {
    late InMemoryDatabase db;
    late DemoTodoRepository repository;
    const testUserId = 'test-user';

    setUp(() {
      db = InMemoryDatabase();
      db.initialize();
      repository = DemoTodoRepository(db);
    });

    test('should create and get todo', () async {
      final todo = TodoModel(
        id: 'test-todo-1',
        userId: testUserId,
        title: 'Repository Test Todo',
        isRecurring: false,
        priority: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createTodo(todo);
      final retrieved = await repository.getTodo('test-todo-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Repository Test Todo'));
    });

    test('should get all todos for user', () async {
      await repository.createTodo(TodoModel(
        id: 'todo-1',
        userId: testUserId,
        title: 'Todo 1',
        isRecurring: false,
        priority: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await repository.createTodo(TodoModel(
        id: 'todo-2',
        userId: testUserId,
        title: 'Todo 2',
        isRecurring: false,
        priority: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final todos = await repository.getTodosByUser(testUserId);
      expect(todos.length, equals(2));
    });

    test('should update todo', () async {
      final todo = TodoModel(
        id: 'update-test',
        userId: testUserId,
        title: 'Before Update',
        isRecurring: false,
        priority: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createTodo(todo);
      await repository.updateTodo(todo.copyWith(title: 'After Update'));

      final updated = await repository.getTodo('update-test');
      expect(updated!.title, equals('After Update'));
    });

    test('should delete todo', () async {
      final todo = TodoModel(
        id: 'delete-test',
        userId: testUserId,
        title: 'To Delete',
        isRecurring: false,
        priority: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createTodo(todo);
      await repository.deleteTodo('delete-test');

      final deleted = await repository.getTodo('delete-test');
      expect(deleted, isNull);
    });
  });

  group('DemoWaterRepository', () {
    late InMemoryDatabase db;
    late DemoWaterRepository repository;
    const testUserId = 'test-user';

    setUp(() {
      db = InMemoryDatabase();
      db.initialize();
      repository = DemoWaterRepository(db);
    });

    test('should log water and get daily total', () async {
      final today = DateTime.now();

      await repository.logWater(WaterLogModel(
        id: 'water-1',
        userId: testUserId,
        date: today,
        amountMl: 250,
        loggedAt: today,
        createdAt: today,
      ));

      await repository.logWater(WaterLogModel(
        id: 'water-2',
        userId: testUserId,
        date: today,
        amountMl: 500,
        loggedAt: today,
        createdAt: today,
      ));

      final logs = await repository.getWaterLogsByDate(testUserId, today);
      expect(logs.length, equals(2));

      final total = logs.fold<int>(0, (sum, log) => sum + log.amountMl);
      expect(total, equals(750));
    });

    test('should delete water log', () async {
      final today = DateTime.now();

      await repository.logWater(WaterLogModel(
        id: 'water-delete',
        userId: testUserId,
        date: today,
        amountMl: 300,
        loggedAt: today,
        createdAt: today,
      ));

      await repository.deleteWaterLog('water-delete');

      final logs = await repository.getWaterLogsByDate(testUserId, today);
      expect(logs.where((l) => l.id == 'water-delete'), isEmpty);
    });
  });

  group('Repository Integration', () {
    late InMemoryDatabase db;

    setUp(() {
      db = InMemoryDatabase();
      db.initialize();
    });

    test('should work with multiple repositories on same database', () async {
      final todoRepo = DemoTodoRepository(db);
      final waterRepo = DemoWaterRepository(db);
      const userId = 'multi-repo-user';

      // Add data through both repositories
      await todoRepo.createTodo(TodoModel(
        id: 'todo-multi',
        userId: userId,
        title: 'Multi-repo test',
        isRecurring: false,
        priority: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await waterRepo.logWater(WaterLogModel(
        id: 'water-multi',
        userId: userId,
        date: DateTime.now(),
        amountMl: 250,
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      // Verify both are accessible
      final todos = await todoRepo.getTodosByUser(userId);
      final waterLogs = await waterRepo.getWaterLogsByDate(userId, DateTime.now());

      expect(todos.length, equals(1));
      expect(waterLogs.length, equals(1));
    });
  });
}
