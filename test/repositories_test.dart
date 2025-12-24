import 'package:flutter_test/flutter_test.dart';
import 'package:statme/src/repositories/demo_repositories.dart';
import 'package:statme/src/services/in_memory_database.dart';
import 'package:statme/src/models/todo_model.dart';
import 'package:statme/src/models/water_model.dart';

void main() {
  group('DemoTodoRepository', () {
    late DemoTodoRepository repository;
    const testUserId = 'test-user';

    setUp(() {
      InMemoryDatabase().reset();
      repository = DemoTodoRepository();
    });

    test('should create and get todo', () async {
      final todo = TodoModel(
        id: 'test-todo-1',
        userId: testUserId,
        title: 'Repository Test Todo',
        startDate: DateTime.now(),
        priority: TodoPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createTodo(todo);
      final todos = await repository.getTodos(testUserId);
      final retrieved = todos.firstWhere((t) => t.id == created.id);

      expect(retrieved.title, equals('Repository Test Todo'));
    });

    test('should get all todos for user', () async {
      await repository.createTodo(TodoModel(
        id: 'todo-1',
        userId: testUserId,
        title: 'Todo 1',
        startDate: DateTime.now(),
        priority: TodoPriority.low,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await repository.createTodo(TodoModel(
        id: 'todo-2',
        userId: testUserId,
        title: 'Todo 2',
        startDate: DateTime.now(),
        priority: TodoPriority.low,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final todos = await repository.getTodos(testUserId);
      expect(todos.length, greaterThanOrEqualTo(2));
    });

    test('should update todo', () async {
      final todo = TodoModel(
        id: 'update-test',
        userId: testUserId,
        title: 'Before Update',
        startDate: DateTime.now(),
        priority: TodoPriority.low,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createTodo(todo);
      await repository.updateTodo(created.copyWith(title: 'After Update'));

      final todos = await repository.getTodos(testUserId);
      final updated = todos.firstWhere((t) => t.id == created.id);
      expect(updated.title, equals('After Update'));
    });

    test('should delete todo', () async {
      final todo = TodoModel(
        id: 'delete-test',
        userId: testUserId,
        title: 'To Delete',
        startDate: DateTime.now(),
        priority: TodoPriority.low,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createTodo(todo);
      await repository.deleteTodo(created.id);

      final todos = await repository.getTodos(testUserId);
      expect(todos.any((t) => t.id == created.id), isFalse);
    });
  });

  group('DemoWaterRepository', () {
    late DemoWaterRepository repository;
    const testUserId = 'test-user';

    setUp(() {
      InMemoryDatabase().reset();
      repository = DemoWaterRepository();
    });

    test('should log water and get daily total', () async {
      final today = DateTime.now();

      await repository.addWaterLog(WaterLogModel(
        id: 'water-1',
        userId: testUserId,
        date: today,
        ml: 250,
        createdAt: today,
      ));

      await repository.addWaterLog(WaterLogModel(
        id: 'water-2',
        userId: testUserId,
        date: today,
        ml: 500,
        createdAt: today,
      ));

      final logs = await repository.getWaterLogs(testUserId, today);
      expect(logs.length, equals(2));

      final total = logs.fold<int>(0, (sum, log) => sum + log.ml);
      expect(total, equals(750));
    });

    test('should delete water log', () async {
      final today = DateTime.now();

      final created = await repository.addWaterLog(WaterLogModel(
        id: 'water-delete',
        userId: testUserId,
        date: today,
        ml: 300,
        createdAt: today,
      ));

      await repository.deleteWaterLog(created.id);

      final logs = await repository.getWaterLogs(testUserId, today);
      expect(logs.where((l) => l.id == created.id), isEmpty);
    });
  });

  group('Repository Integration', () {
    setUp(() {
      // Reset DB if possible
    });

    test('should work with multiple repositories on same database', () async {
      final todoRepo = DemoTodoRepository();
      final waterRepo = DemoWaterRepository();
      const userId = 'multi-repo-user';

      // Add data through both repositories
      final createdTodo = await todoRepo.createTodo(TodoModel(
        id: 'todo-multi',
        userId: userId,
        title: 'Multi-repo test',
        startDate: DateTime.now(),
        priority: TodoPriority.low,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final createdWater = await waterRepo.addWaterLog(WaterLogModel(
        id: 'water-multi',
        userId: userId,
        date: DateTime.now(),
        ml: 250,
        createdAt: DateTime.now(),
      ));

      // Verify both are accessible
      final todos = await todoRepo.getTodos(userId);
      final waterLogs = await waterRepo.getWaterLogs(userId, DateTime.now());

      expect(todos.any((t) => t.id == createdTodo.id), isTrue);
      expect(waterLogs.any((l) => l.id == createdWater.id), isTrue);
    });
  });
}
