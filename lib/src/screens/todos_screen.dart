/// Todos Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'todo_edit_screen.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(todoNotifierProvider.notifier).load(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(authNotifierProvider).valueOrNull;
    final todos = ref.watch(todoNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodos,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: todos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Keine ToDos vorhanden',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Erstelle dein erstes ToDo'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTodos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return _TodoCard(
                    todo: todo,
                    onTap: () => _openTodoEdit(todo),
                    onDelete: () => _deleteTodo(todo),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTodoEdit(null),
        icon: const Icon(Icons.add),
        label: const Text('Neues ToDo'),
      ),
    );
  }

  void _openTodoEdit(TodoModel? todo) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final result = await Navigator.of(context).push<TodoModel>(
      MaterialPageRoute(
        builder: (_) => TodoEditScreen(todo: todo, userId: user.id),
      ),
    );

    if (result != null) {
      _loadTodos();
    }
  }

  Future<void> _deleteTodo(TodoModel todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ToDo löschen'),
        content: Text('Möchtest du "${todo.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(todoNotifierProvider.notifier).delete(todo.id);
    }
  }
}

class _TodoCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _priorityColor(todo.priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (todo.description != null && todo.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          todo.description!,
                          style: TextStyle(color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _RecurrenceBadge(recurrenceType: todo.recurrenceType),
                        const SizedBox(width: 8),
                        _PriorityBadge(priority: todo.priority),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: todo.active,
                    onChanged: null, // Read-only toggle display
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: Colors.red.shade300,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.urgent:
        return Colors.red;
      case TodoPriority.high:
        return Colors.orange;
      case TodoPriority.medium:
        return Colors.blue;
      case TodoPriority.low:
        return Colors.grey;
    }
  }
}

class _RecurrenceBadge extends StatelessWidget {
  final RecurrenceType recurrenceType;

  const _RecurrenceBadge({required this.recurrenceType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _recurrenceLabel,
        style: TextStyle(
          fontSize: 12,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  String get _recurrenceLabel {
    switch (recurrenceType) {
      case RecurrenceType.once:
        return 'Einmalig';
      case RecurrenceType.daily:
        return 'Täglich';
      case RecurrenceType.weekly:
        return 'Wöchentlich';
      case RecurrenceType.monthly:
        return 'Monatlich';
      case RecurrenceType.yearly:
        return 'Jährlich';
      case RecurrenceType.custom:
        return 'Benutzerdefiniert';
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final TodoPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _priorityLabel,
        style: TextStyle(
          fontSize: 12,
          color: _priorityColor,
        ),
      ),
    );
  }

  Color get _priorityColor {
    switch (priority) {
      case TodoPriority.urgent:
        return Colors.red;
      case TodoPriority.high:
        return Colors.orange;
      case TodoPriority.medium:
        return Colors.blue;
      case TodoPriority.low:
        return Colors.grey;
    }
  }

  String get _priorityLabel {
    switch (priority) {
      case TodoPriority.urgent:
        return 'Dringend';
      case TodoPriority.high:
        return 'Hoch';
      case TodoPriority.medium:
        return 'Mittel';
      case TodoPriority.low:
        return 'Niedrig';
    }
  }
}
