import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Kategorie einer Haushaltsaufgabe
enum HouseholdCategory {
  cleaning('Reinigung', '🧹', 0xFF4CAF50),
  laundry('Wäsche', '👕', 0xFF2196F3),
  tidying('Ordnung', '🏠', 0xFFFF9800),
  organization('Organisation', '🧠', 0xFF9C27B0),
  other('Sonstiges', '🔧', 0xFF607D8B);

  final String label;
  final String emoji;
  final int colorValue;
  const HouseholdCategory(this.label, this.emoji, this.colorValue);
}

/// Häufigkeit einer Aufgabe
enum TaskFrequency {
  daily('Täglich', 1),
  everyXDays('Alle X Tage', 0), // X wird separat gespeichert
  weekly('Wöchentlich', 7),
  biweekly('Alle 2 Wochen', 14),
  monthly('Monatlich', 30),
  irregular('Unregelmäßig', 0);

  final String label;
  final int defaultDays;
  const TaskFrequency(this.label, this.defaultDays);
}

/// Energieaufwand
enum EnergyLevel {
  low('Niedrig', '💚', 1),
  medium('Mittel', '💛', 2),
  high('Hoch', '🔴', 3);

  final String label;
  final String emoji;
  final int value;
  const EnergyLevel(this.label, this.emoji, this.value);
}

/// Raum im Haushalt
enum HouseholdRoom {
  kitchen('Küche', '🍳'),
  bathroom('Bad', '🚿'),
  bedroom('Schlafzimmer', '🛏️'),
  livingRoom('Wohnzimmer', '🛋️'),
  office('Büro', '💼'),
  hallway('Flur', '🚪'),
  balcony('Balkon', '🌿'),
  garage('Garage', '🚗'),
  garden('Garten', '🌳'),
  laundryRoom('Waschraum', '🧺'),
  basement('Keller', '📦'),
  attic('Dachboden', '🏠'),
  everywhere('Überall', '🏡'),
  other('Sonstiges', '📍');

  final String label;
  final String emoji;
  const HouseholdRoom(this.label, this.emoji);
}

// ============================================================================
// TASK TEMPLATE (Vorschläge)
// ============================================================================

class HouseholdTaskTemplate {
  final String name;
  final HouseholdCategory category;
  final int? suggestedMinutes;
  final EnergyLevel? suggestedEnergy;
  final TaskFrequency suggestedFrequency;
  final HouseholdRoom? suggestedRoom;

  const HouseholdTaskTemplate({
    required this.name,
    required this.category,
    this.suggestedMinutes,
    this.suggestedEnergy,
    required this.suggestedFrequency,
    this.suggestedRoom,
  });

  /// Vordefinierte Vorschläge
  static const List<HouseholdTaskTemplate> suggestions = [
    // 🧹 Reinigung
    HouseholdTaskTemplate(name: 'Staubsaugen', category: HouseholdCategory.cleaning, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.everywhere),
    HouseholdTaskTemplate(name: 'Wischen', category: HouseholdCategory.cleaning, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.everywhere),
    HouseholdTaskTemplate(name: 'Bad putzen', category: HouseholdCategory.cleaning, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.bathroom),
    HouseholdTaskTemplate(name: 'Toilette reinigen', category: HouseholdCategory.cleaning, suggestedMinutes: 10, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.bathroom),
    HouseholdTaskTemplate(name: 'Küche reinigen', category: HouseholdCategory.cleaning, suggestedMinutes: 20, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Spülmaschine einräumen', category: HouseholdCategory.cleaning, suggestedMinutes: 5, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Spülmaschine ausräumen', category: HouseholdCategory.cleaning, suggestedMinutes: 5, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Müll rausbringen', category: HouseholdCategory.cleaning, suggestedMinutes: 5, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Kühlschrank reinigen', category: HouseholdCategory.cleaning, suggestedMinutes: 20, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Fenster putzen', category: HouseholdCategory.cleaning, suggestedMinutes: 60, suggestedEnergy: EnergyLevel.high, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.everywhere),
    HouseholdTaskTemplate(name: 'Staub wischen', category: HouseholdCategory.cleaning, suggestedMinutes: 20, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.everywhere),
    HouseholdTaskTemplate(name: 'Backofen reinigen', category: HouseholdCategory.cleaning, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Mikrowelle reinigen', category: HouseholdCategory.cleaning, suggestedMinutes: 10, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Spiegel putzen', category: HouseholdCategory.cleaning, suggestedMinutes: 10, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.bathroom),

    // 👕 Wäsche
    HouseholdTaskTemplate(name: 'Wäsche waschen', category: HouseholdCategory.laundry, suggestedMinutes: 10, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.laundryRoom),
    HouseholdTaskTemplate(name: 'Wäsche aufhängen', category: HouseholdCategory.laundry, suggestedMinutes: 15, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.laundryRoom),
    HouseholdTaskTemplate(name: 'Wäsche zusammenlegen', category: HouseholdCategory.laundry, suggestedMinutes: 20, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.bedroom),
    HouseholdTaskTemplate(name: 'Bügeln', category: HouseholdCategory.laundry, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.laundryRoom),
    HouseholdTaskTemplate(name: 'Bettwäsche wechseln', category: HouseholdCategory.laundry, suggestedMinutes: 15, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.biweekly, suggestedRoom: HouseholdRoom.bedroom),
    HouseholdTaskTemplate(name: 'Handtücher wechseln', category: HouseholdCategory.laundry, suggestedMinutes: 5, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.bathroom),
    HouseholdTaskTemplate(name: 'Trockner leeren', category: HouseholdCategory.laundry, suggestedMinutes: 5, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.laundryRoom),

    // 🏠 Ordnung
    HouseholdTaskTemplate(name: 'Zimmer aufräumen', category: HouseholdCategory.tidying, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.bedroom),
    HouseholdTaskTemplate(name: 'Schreibtisch aufräumen', category: HouseholdCategory.tidying, suggestedMinutes: 15, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.office),
    HouseholdTaskTemplate(name: 'Kleiderschrank ordnen', category: HouseholdCategory.tidying, suggestedMinutes: 45, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.bedroom),
    HouseholdTaskTemplate(name: 'Sachen aussortieren', category: HouseholdCategory.tidying, suggestedMinutes: 60, suggestedEnergy: EnergyLevel.high, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.everywhere),
    HouseholdTaskTemplate(name: 'Papierkram sortieren', category: HouseholdCategory.tidying, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.office),
    HouseholdTaskTemplate(name: 'Bett machen', category: HouseholdCategory.tidying, suggestedMinutes: 5, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.bedroom),
    HouseholdTaskTemplate(name: 'Geschirr wegräumen', category: HouseholdCategory.tidying, suggestedMinutes: 5, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.daily, suggestedRoom: HouseholdRoom.kitchen),

    // 🧠 Organisation
    HouseholdTaskTemplate(name: 'Einkaufen', category: HouseholdCategory.organization, suggestedMinutes: 60, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Einkaufsplanung', category: HouseholdCategory.organization, suggestedMinutes: 15, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Vorräte prüfen', category: HouseholdCategory.organization, suggestedMinutes: 10, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Rechnungen erledigen', category: HouseholdCategory.organization, suggestedMinutes: 20, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.office),
    HouseholdTaskTemplate(name: 'Termine planen', category: HouseholdCategory.organization, suggestedMinutes: 15, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Mülltrennung', category: HouseholdCategory.organization, suggestedMinutes: 10, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.kitchen),
    HouseholdTaskTemplate(name: 'Altpapier wegbringen', category: HouseholdCategory.organization, suggestedMinutes: 15, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.biweekly, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Pfandflaschen wegbringen', category: HouseholdCategory.organization, suggestedMinutes: 20, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: null),

    // 🔧 Sonstiges
    HouseholdTaskTemplate(name: 'Pflanzen gießen', category: HouseholdCategory.other, suggestedMinutes: 10, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.everywhere),
    HouseholdTaskTemplate(name: 'Haustierpflege', category: HouseholdCategory.other, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.daily, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Reparaturen', category: HouseholdCategory.other, suggestedMinutes: 60, suggestedEnergy: EnergyLevel.high, suggestedFrequency: TaskFrequency.irregular, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Große Putzaktion', category: HouseholdCategory.other, suggestedMinutes: 180, suggestedEnergy: EnergyLevel.high, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.everywhere),
    HouseholdTaskTemplate(name: 'Garage aufräumen', category: HouseholdCategory.other, suggestedMinutes: 90, suggestedEnergy: EnergyLevel.high, suggestedFrequency: TaskFrequency.monthly, suggestedRoom: HouseholdRoom.garage),
    HouseholdTaskTemplate(name: 'Auto waschen', category: HouseholdCategory.other, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.biweekly, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Briefkasten leeren', category: HouseholdCategory.other, suggestedMinutes: 2, suggestedEnergy: EnergyLevel.low, suggestedFrequency: TaskFrequency.daily, suggestedRoom: null),
    HouseholdTaskTemplate(name: 'Rasen mähen', category: HouseholdCategory.other, suggestedMinutes: 45, suggestedEnergy: EnergyLevel.high, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.garden),
    HouseholdTaskTemplate(name: 'Unkraut jäten', category: HouseholdCategory.other, suggestedMinutes: 30, suggestedEnergy: EnergyLevel.medium, suggestedFrequency: TaskFrequency.weekly, suggestedRoom: HouseholdRoom.garden),
  ];

  /// Vorschläge nach Kategorie gruppiert
  static Map<HouseholdCategory, List<HouseholdTaskTemplate>> get byCategory {
    final map = <HouseholdCategory, List<HouseholdTaskTemplate>>{};
    for (final cat in HouseholdCategory.values) {
      map[cat] = suggestions.where((t) => t.category == cat).toList();
    }
    return map;
  }
}

// ============================================================================
// HOUSEHOLD TASK (Benutzer-konfigurierte Aufgabe)
// ============================================================================

class HouseholdTask extends Equatable {
  final String id;
  final String userId;
  final String name;
  final HouseholdCategory category;
  final TaskFrequency frequency;
  final int? frequencyDays; // Für "alle X Tage"
  final int? estimatedMinutes;
  final EnergyLevel? energyLevel;
  final HouseholdRoom? room;
  final String? notes;
  final bool isPaused; // Für Urlaub/Krankheit
  final DateTime createdAt;
  final DateTime updatedAt;

  const HouseholdTask({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.frequency,
    this.frequencyDays,
    this.estimatedMinutes,
    this.energyLevel,
    this.room,
    this.notes,
    this.isPaused = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tage zwischen Wiederholungen
  int get repeatDays {
    if (frequency == TaskFrequency.everyXDays && frequencyDays != null) {
      return frequencyDays!;
    }
    return frequency.defaultDays;
  }

  /// Ist die Aufgabe regelmäßig?
  bool get isRecurring => frequency != TaskFrequency.irregular;

  HouseholdTask copyWith({
    String? id,
    String? userId,
    String? name,
    HouseholdCategory? category,
    TaskFrequency? frequency,
    int? frequencyDays,
    int? estimatedMinutes,
    EnergyLevel? energyLevel,
    HouseholdRoom? room,
    String? notes,
    bool? isPaused,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HouseholdTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      energyLevel: energyLevel ?? this.energyLevel,
      room: room ?? this.room,
      notes: notes ?? this.notes,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HouseholdTask.fromJson(Map<String, dynamic> json) {
    return HouseholdTask(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      category: HouseholdCategory.values.firstWhere((c) => c.name == json['category']),
      frequency: TaskFrequency.values.firstWhere((f) => f.name == json['frequency']),
      frequencyDays: json['frequencyDays'] as int?,
      estimatedMinutes: json['estimatedMinutes'] as int?,
      energyLevel: json['energyLevel'] != null
          ? EnergyLevel.values.firstWhere((e) => e.name == json['energyLevel'])
          : null,
      room: json['room'] != null
          ? HouseholdRoom.values.firstWhere((r) => r.name == json['room'])
          : null,
      notes: json['notes'] as String?,
      isPaused: json['isPaused'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category.name,
      'frequency': frequency.name,
      'frequencyDays': frequencyDays,
      'estimatedMinutes': estimatedMinutes,
      'energyLevel': energyLevel?.name,
      'room': room?.name,
      'notes': notes,
      'isPaused': isPaused,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, name, category, frequency, frequencyDays, estimatedMinutes, energyLevel, room, notes, isPaused, createdAt, updatedAt];
}

// ============================================================================
// TASK COMPLETION (Erledigter Eintrag)
// ============================================================================

class TaskCompletion extends Equatable {
  final String id;
  final String taskId;
  final String userId;
  final DateTime completedAt;
  final int? actualMinutes; // Tatsächliche Zeit
  final int? effortRating; // 1-5 Wie anstrengend war es?
  final bool wasSkipped; // Übersprungen statt erledigt
  final String? note;

  const TaskCompletion({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.completedAt,
    this.actualMinutes,
    this.effortRating,
    this.wasSkipped = false,
    this.note,
  });

  TaskCompletion copyWith({
    String? id,
    String? taskId,
    String? userId,
    DateTime? completedAt,
    int? actualMinutes,
    int? effortRating,
    bool? wasSkipped,
    String? note,
  }) {
    return TaskCompletion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      effortRating: effortRating ?? this.effortRating,
      wasSkipped: wasSkipped ?? this.wasSkipped,
      note: note ?? this.note,
    );
  }

  factory TaskCompletion.fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      actualMinutes: json['actualMinutes'] as int?,
      effortRating: json['effortRating'] as int?,
      wasSkipped: json['wasSkipped'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'completedAt': completedAt.toIso8601String(),
      'actualMinutes': actualMinutes,
      'effortRating': effortRating,
      'wasSkipped': wasSkipped,
      'note': note,
    };
  }

  @override
  List<Object?> get props => [id, taskId, userId, completedAt, actualMinutes, effortRating, wasSkipped, note];
}

// ============================================================================
// HOUSEHOLD STATISTICS
// ============================================================================

class HouseholdStatistics extends Equatable {
  final int totalTasks;
  final int completedToday;
  final int completedThisWeek;
  final int overdueCount;
  final int totalMinutesToday;
  final int totalMinutesThisWeek;
  final double routineScore; // 0-100% wie regelmäßig
  final double avgEffortRating;
  final Map<HouseholdCategory, int> completionsByCategory;
  final Map<String, int> completionsByDay; // Letzten 7 Tage

  const HouseholdStatistics({
    required this.totalTasks,
    required this.completedToday,
    required this.completedThisWeek,
    required this.overdueCount,
    required this.totalMinutesToday,
    required this.totalMinutesThisWeek,
    required this.routineScore,
    required this.avgEffortRating,
    required this.completionsByCategory,
    required this.completionsByDay,
  });

  factory HouseholdStatistics.empty() {
    return const HouseholdStatistics(
      totalTasks: 0,
      completedToday: 0,
      completedThisWeek: 0,
      overdueCount: 0,
      totalMinutesToday: 0,
      totalMinutesThisWeek: 0,
      routineScore: 0,
      avgEffortRating: 0,
      completionsByCategory: {},
      completionsByDay: {},
    );
  }

  factory HouseholdStatistics.calculate({
    required List<HouseholdTask> tasks,
    required List<TaskCompletion> completions,
  }) {
    if (tasks.isEmpty) return HouseholdStatistics.empty();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    // Heute & diese Woche
    final todayCompletions = completions.where((c) {
      final d = c.completedAt;
      return d.year == today.year && d.month == today.month && d.day == today.day && !c.wasSkipped;
    }).toList();

    final weekCompletions = completions.where((c) {
      return c.completedAt.isAfter(weekStart) && !c.wasSkipped;
    }).toList();

    // Zeit heute & Woche
    final minutesToday = todayCompletions.fold(0, (sum, c) => sum + (c.actualMinutes ?? 0));
    final minutesWeek = weekCompletions.fold(0, (sum, c) => sum + (c.actualMinutes ?? 0));

    // Überfällige Aufgaben
    int overdue = 0;
    for (final task in tasks.where((t) => !t.isPaused && t.isRecurring)) {
      final lastCompletion = completions
          .where((c) => c.taskId == task.id && !c.wasSkipped)
          .fold<DateTime?>(null, (latest, c) => latest == null || c.completedAt.isAfter(latest) ? c.completedAt : latest);

      if (lastCompletion == null) {
        // Noch nie erledigt
        if (task.createdAt.isBefore(today.subtract(Duration(days: task.repeatDays)))) {
          overdue++;
        }
      } else {
        final dueDate = lastCompletion.add(Duration(days: task.repeatDays));
        if (dueDate.isBefore(today)) {
          overdue++;
        }
      }
    }

    // Routine-Score (wie viele der fälligen Aufgaben wurden pünktlich erledigt)
    double routineScore = 0;
    int recurringTasks = tasks.where((t) => !t.isPaused && t.isRecurring).length;
    if (recurringTasks > 0) {
      routineScore = ((recurringTasks - overdue) / recurringTasks * 100).clamp(0, 100);
    }

    // Durchschnittliche Anstrengung
    final ratedCompletions = completions.where((c) => c.effortRating != null && !c.wasSkipped).toList();
    final avgEffort = ratedCompletions.isNotEmpty
        ? ratedCompletions.map((c) => c.effortRating!).reduce((a, b) => a + b) / ratedCompletions.length
        : 0.0;

    // Nach Kategorie
    final byCategory = <HouseholdCategory, int>{};
    for (final c in weekCompletions) {
      final task = tasks.firstWhere((t) => t.id == c.taskId, orElse: () => tasks.first);
      byCategory[task.category] = (byCategory[task.category] ?? 0) + 1;
    }

    // Nach Tag (letzte 7 Tage)
    final byDay = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayKey = '${day.day}.${day.month}';
      final count = completions.where((c) {
        final d = c.completedAt;
        return d.year == day.year && d.month == day.month && d.day == day.day && !c.wasSkipped;
      }).length;
      byDay[dayKey] = count;
    }

    return HouseholdStatistics(
      totalTasks: tasks.where((t) => !t.isPaused).length,
      completedToday: todayCompletions.length,
      completedThisWeek: weekCompletions.length,
      overdueCount: overdue,
      totalMinutesToday: minutesToday,
      totalMinutesThisWeek: minutesWeek,
      routineScore: routineScore,
      avgEffortRating: avgEffort,
      completionsByCategory: byCategory,
      completionsByDay: byDay,
    );
  }

  @override
  List<Object?> get props => [totalTasks, completedToday, completedThisWeek, overdueCount, totalMinutesToday, totalMinutesThisWeek, routineScore, avgEffortRating, completionsByCategory, completionsByDay];
}

// ============================================================================
// TASK WITH STATUS (Kombiniert Task + letzte Erledigung)
// ============================================================================

class TaskWithStatus {
  final HouseholdTask task;
  final TaskCompletion? lastCompletion;
  final bool isDueToday;
  final bool isOverdue;
  final int? daysUntilDue;
  final int? daysOverdue;

  const TaskWithStatus({
    required this.task,
    this.lastCompletion,
    required this.isDueToday,
    required this.isOverdue,
    this.daysUntilDue,
    this.daysOverdue,
  });

  factory TaskWithStatus.calculate(HouseholdTask task, List<TaskCompletion> allCompletions) {
    if (task.isPaused || !task.isRecurring) {
      return TaskWithStatus(
        task: task,
        lastCompletion: null,
        isDueToday: false,
        isOverdue: false,
      );
    }

    final completions = allCompletions.where((c) => c.taskId == task.id && !c.wasSkipped).toList();
    completions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final lastCompletion = completions.isNotEmpty ? completions.first : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime dueDate;
    if (lastCompletion == null) {
      dueDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
    } else {
      final lastDate = DateTime(lastCompletion.completedAt.year, lastCompletion.completedAt.month, lastCompletion.completedAt.day);
      dueDate = lastDate.add(Duration(days: task.repeatDays));
    }

    final daysDiff = dueDate.difference(today).inDays;

    return TaskWithStatus(
      task: task,
      lastCompletion: lastCompletion,
      isDueToday: daysDiff == 0,
      isOverdue: daysDiff < 0,
      daysUntilDue: daysDiff > 0 ? daysDiff : null,
      daysOverdue: daysDiff < 0 ? -daysDiff : null,
    );
  }
}
