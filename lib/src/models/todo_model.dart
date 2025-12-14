import 'package:equatable/equatable.dart';

enum RecurrenceType {
  once,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

enum TodoPriority {
  low,
  medium,
  high,
  urgent,
}

class TodoModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? rruleText;
  final String timezone;
  final bool active;
  final TodoPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.rruleText,
    this.timezone = 'UTC',
    this.active = true,
    this.priority = TodoPriority.medium,
    required this.createdAt,
    required this.updatedAt,
  });

  RecurrenceType get recurrenceType {
    if (rruleText == null || rruleText!.isEmpty) return RecurrenceType.once;
    if (rruleText!.contains('FREQ=DAILY')) return RecurrenceType.daily;
    if (rruleText!.contains('FREQ=WEEKLY')) return RecurrenceType.weekly;
    if (rruleText!.contains('FREQ=MONTHLY')) return RecurrenceType.monthly;
    if (rruleText!.contains('FREQ=YEARLY')) return RecurrenceType.yearly;
    return RecurrenceType.custom;
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      rruleText: json['rrule_text'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      active: json['active'] as bool? ?? true,
      priority: TodoPriority.values.firstWhere(
        (e) => e.name == (json['priority'] as String? ?? 'medium'),
        orElse: () => TodoPriority.medium,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'rrule_text': rruleText,
      'timezone': timezone,
      'active': active,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TodoModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? rruleText,
    String? timezone,
    bool? active,
    TodoPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rruleText: rruleText ?? this.rruleText,
      timezone: timezone ?? this.timezone,
      active: active ?? this.active,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        startDate,
        endDate,
        rruleText,
        timezone,
        active,
        priority,
        createdAt,
        updatedAt,
      ];
}

class TodoOccurrence extends Equatable {
  final String id;
  final String todoId;
  final String userId;
  final DateTime dueAt;
  final bool done;
  final bool reminderSent;

  const TodoOccurrence({
    required this.id,
    required this.todoId,
    required this.userId,
    required this.dueAt,
    this.done = false,
    this.reminderSent = false,
  });

  factory TodoOccurrence.fromJson(Map<String, dynamic> json) {
    return TodoOccurrence(
      id: json['id'] as String,
      todoId: json['todo_id'] as String,
      userId: json['user_id'] as String,
      dueAt: DateTime.parse(json['due_at'] as String),
      done: json['done'] as bool? ?? false,
      reminderSent: json['reminder_sent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo_id': todoId,
      'user_id': userId,
      'due_at': dueAt.toIso8601String(),
      'done': done,
      'reminder_sent': reminderSent,
    };
  }

  TodoOccurrence copyWith({
    String? id,
    String? todoId,
    String? userId,
    DateTime? dueAt,
    bool? done,
    bool? reminderSent,
  }) {
    return TodoOccurrence(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      userId: userId ?? this.userId,
      dueAt: dueAt ?? this.dueAt,
      done: done ?? this.done,
      reminderSent: reminderSent ?? this.reminderSent,
    );
  }

  @override
  List<Object?> get props => [id, todoId, userId, dueAt, done, reminderSent];
}
