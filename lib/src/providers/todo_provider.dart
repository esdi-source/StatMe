import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

// ============================================
// TODO PROVIDERS
// ============================================

/// Todo Repository Provider
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoTodoRepository();
  }
  return SupabaseTodoRepository(Supabase.instance.client);
});

final todosProvider = FutureProvider.family<List<TodoModel>, String>((ref, userId) async {
  final repo = ref.watch(todoRepositoryProvider);
  return await repo.getTodos(userId);
});

final todayOccurrencesProvider = FutureProvider.family<List<TodoOccurrence>, String>((ref, userId) async {
  final repo = ref.watch(todoRepositoryProvider);
  return await repo.getOccurrencesForDate(userId, DateTime.now());
});

class TodoNotifier extends StateNotifier<List<TodoModel>> {
  final TodoRepository _repository;
  
  TodoNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    state = await _repository.getTodos(userId);
  }
  
  Future<void> create(TodoModel todo) async {
    final created = await _repository.createTodo(todo);
    state = [...state, created];
  }
  
  Future<void> update(TodoModel todo) async {
    final updated = await _repository.updateTodo(todo);
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
  }
  
  Future<void> delete(String todoId) async {
    await _repository.deleteTodo(todoId);
    state = state.where((t) => t.id != todoId).toList();
  }
}

final todoNotifierProvider = StateNotifierProvider<TodoNotifier, List<TodoModel>>((ref) {
  return TodoNotifier(ref.watch(todoRepositoryProvider));
});
