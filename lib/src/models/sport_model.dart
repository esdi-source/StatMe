import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Intensität einer Sporteinheit
enum SportIntensity {
  low('Leicht', 0.6),
  medium('Mittel', 1.0),
  high('Intensiv', 1.4),
  extreme('Sehr intensiv', 1.8);

  final String label;
  final double calorieMultiplier;
  const SportIntensity(this.label, this.calorieMultiplier);
  
  /// Numerical value (1-4) for calculations
  int get value => index + 1;
}

// ============================================================================
// SPORTART (Sport Type)
// ============================================================================

/// Eine benutzerdefinierte Sportart
class SportType extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? icon; // Optional: Icon-Name
  final int caloriesPerHour; // Geschätzter Kalorienverbrauch pro Stunde (Basis)
  final int? colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SportType({
    required this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.caloriesPerHour = 300,
    this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  SportType copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    int? caloriesPerHour,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SportType(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      caloriesPerHour: caloriesPerHour ?? this.caloriesPerHour,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SportType.fromJson(Map<String, dynamic> json) {
    return SportType(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      caloriesPerHour: json['calories_per_hour'] as int? ?? 300,
      colorValue: json['color_value'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'calories_per_hour': caloriesPerHour,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, name, icon, caloriesPerHour, colorValue, createdAt, updatedAt];
}

// ============================================================================
// SPORTEINHEIT (Workout Session)
// ============================================================================

/// Eine einzelne Sporteinheit/Training
class WorkoutSession extends Equatable {
  final String id;
  final String userId;
  final String sportTypeId;
  final String? sportTypeName; // Fallback wenn SportType gelöscht wurde
  final DateTime date;
  final int durationMinutes;
  final SportIntensity intensity;
  final int caloriesBurned; // Berechnete verbrannte Kalorien
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.sportTypeId,
    this.sportTypeName,
    required this.date,
    required this.durationMinutes,
    this.intensity = SportIntensity.medium,
    required this.caloriesBurned,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? sportTypeId,
    String? sportTypeName,
    DateTime? date,
    int? durationMinutes,
    SportIntensity? intensity,
    int? caloriesBurned,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sportTypeId: sportTypeId ?? this.sportTypeId,
      sportTypeName: sportTypeName ?? this.sportTypeName,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formatierte Dauer
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }
    return '${minutes}min';
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sportTypeId: json['sport_type_id'] as String,
      sportTypeName: json['sport_type_name'] as String?,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['duration_minutes'] as int,
      intensity: SportIntensity.values.firstWhere(
        (i) => i.name == json['intensity'],
        orElse: () => SportIntensity.medium,
      ),
      caloriesBurned: json['calories_burned'] as int? ?? 0,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sport_type_id': sportTypeId,
      'sport_type_name': sportTypeName,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'intensity': intensity.name,
      'calories_burned': caloriesBurned,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, sportTypeId, sportTypeName, date, durationMinutes, intensity, caloriesBurned, note, createdAt, updatedAt];
}

// ============================================================================
// GEWICHTSEINTRAG (Weight Entry)
// ============================================================================

/// Ein Gewichtseintrag
class WeightEntry extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final double weightKg;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeightEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.weightKg,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  WeightEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weightKg,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weight_kg'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'weight_kg': weightKg,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, date, weightKg, note, createdAt, updatedAt];
}

// ============================================================================
// SPORT STATISTIKEN (Aggregierte Daten)
// ============================================================================

/// Statistiken für eine Sportart
class SportTypeStats {
  final SportType sportType;
  final int totalSessions;
  final int totalMinutes;
  final int totalCalories;
  
  const SportTypeStats({
    required this.sportType,
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalCalories,
  });

  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}

/// Tägliche Sport-Zusammenfassung
class DailySportSummary {
  final DateTime date;
  final List<WorkoutSession> sessions;
  final int totalCaloriesBurned;
  final int totalMinutes;

  const DailySportSummary({
    required this.date,
    required this.sessions,
    required this.totalCaloriesBurned,
    required this.totalMinutes,
  });

  bool get hasSport => sessions.isNotEmpty;
}

/// Streak-Daten für Kontinuität
class SportStreak {
  final int currentStreak;
  final int longestStreak;
  final int totalDaysWithSport;
  final int totalDays;
  final DateTime? lastActivityDate;

  const SportStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.totalDaysWithSport = 0,
    this.totalDays = 0,
    this.lastActivityDate,
  });

  double get consistency => totalDays > 0 ? totalDaysWithSport / totalDays : 0;
}

// ============================================================================
// SIMPLIFIED SPORT SESSION (für einfache Tracking-Fälle)
// ============================================================================

/// Vereinfachte Sporteinheit - direkt mit Sportart-String statt ID-Referenz
class SportSession extends Equatable {
  final String id;
  final String userId;
  final String sportType; // Direkter Name der Sportart
  final Duration duration;
  final SportIntensity intensity;
  final int? caloriesBurned;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  const SportSession({
    required this.id,
    required this.userId,
    required this.sportType,
    required this.duration,
    required this.intensity,
    this.caloriesBurned,
    this.notes,
    required this.date,
    required this.createdAt,
  });

  SportSession copyWith({
    String? id,
    String? userId,
    String? sportType,
    Duration? duration,
    SportIntensity? intensity,
    int? caloriesBurned,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return SportSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sportType: sportType ?? this.sportType,
      duration: duration ?? this.duration,
      intensity: intensity ?? this.intensity,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SportSession.fromJson(Map<String, dynamic> json) {
    return SportSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sportType: json['sport_type'] as String,
      duration: Duration(minutes: json['duration_minutes'] as int),
      intensity: SportIntensity.values.firstWhere(
        (i) => i.name == json['intensity'],
        orElse: () => SportIntensity.medium,
      ),
      caloriesBurned: json['calories_burned'] as int?,
      notes: json['notes'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sport_type': sportType,
      'duration_minutes': duration.inMinutes,
      'intensity': intensity.name,
      'calories_burned': caloriesBurned,
      'notes': notes,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, sportType, duration, intensity, caloriesBurned, notes, date, createdAt];
}

// ============================================================================
// SPORT STATS (Aggregierte Statistiken)
// ============================================================================

/// Aggregierte Sport-Statistiken pro Sportart
class SportStats {
  final String sportType;
  final Duration totalDuration;
  final int totalCalories;
  final int sessionCount;
  final double averageIntensity;

  const SportStats({
    required this.sportType,
    required this.totalDuration,
    required this.totalCalories,
    required this.sessionCount,
    required this.averageIntensity,
  });
}

// ============================================================================
// TRAININGSPLAN (Workout Plan)
// ============================================================================

/// Ein Trainingsplan
class WorkoutPlan extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final WorkoutPlanType type;
  final List<PlannedExercise> exercises;
  final int? restBetweenExercisesSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.type = WorkoutPlanType.custom,
    required this.exercises,
    this.restBetweenExercisesSeconds = 60,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Geschätzte Gesamtdauer in Minuten
  int get estimatedDurationMinutes {
    int total = 0;
    for (final ex in exercises) {
      // Sets * (Zeit pro Set + Pause)
      total += ex.sets * (ex.durationSeconds ?? 45);
      total += (ex.sets - 1) * (ex.restSeconds ?? 60);
    }
    // Plus Pausen zwischen Übungen
    total += (exercises.length - 1) * (restBetweenExercisesSeconds ?? 60);
    return (total / 60).ceil();
  }

  /// Alle primären Muskelgruppen
  Set<String> get primaryMuscles {
    return exercises.map((e) => e.primaryMuscle).whereType<String>().toSet();
  }

  /// Alle sekundären Muskelgruppen
  Set<String> get secondaryMuscles {
    return exercises.expand((e) => e.secondaryMuscles).toSet();
  }

  /// Alle Muskelgruppen (primär + sekundär)
  Set<String> get allMuscles => primaryMuscles.union(secondaryMuscles);

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    WorkoutPlanType? type,
    List<PlannedExercise>? exercises,
    int? restBetweenExercisesSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      exercises: exercises ?? this.exercises,
      restBetweenExercisesSeconds: restBetweenExercisesSeconds ?? this.restBetweenExercisesSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: WorkoutPlanType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => WorkoutPlanType.custom,
      ),
      exercises: (json['exercises'] as List)
          .map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      restBetweenExercisesSeconds: json['rest_between_exercises'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'type': type.name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'rest_between_exercises': restBetweenExercisesSeconds,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, name, exercises, updatedAt];
}

/// Trainingsplan-Typ
enum WorkoutPlanType {
  push('Push', '💪'),
  pull('Pull', '🔙'),
  legs('Legs', '🦵'),
  fullBody('Ganzkörper', '🏋️'),
  upperBody('Oberkörper', '💪'),
  lowerBody('Unterkörper', '🦵'),
  core('Core', '🎯'),
  cardio('Cardio', '❤️'),
  hiit('HIIT', '⚡'),
  stretch('Stretching', '🧘'),
  home('Home Workout', '🏠'),
  gym('Studio', '🏢'),
  custom('Eigener Plan', '⚙️');

  final String label;
  final String emoji;
  const WorkoutPlanType(this.label, this.emoji);
}

/// Eine geplante Übung im Trainingsplan
class PlannedExercise extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final String? primaryMuscle;
  final List<String> secondaryMuscles;
  final int sets;
  final int? reps; // Wiederholungen ODER
  final int? durationSeconds; // Zeit (z.B. für Planks)
  final double? weightKg;
  final int? restSeconds;
  final String? notes;

  const PlannedExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
    this.restSeconds = 60,
    this.notes,
  });

  /// Formatierte Set-Anzeige
  String get formattedSets {
    if (reps != null) {
      return '$sets × $reps';
    } else if (durationSeconds != null) {
      final secs = durationSeconds!;
      if (secs >= 60) {
        return '$sets × ${secs ~/ 60}min';
      }
      return '$sets × ${secs}s';
    }
    return '$sets Sets';
  }

  PlannedExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    int? sets,
    int? reps,
    int? durationSeconds,
    double? weightKg,
    int? restSeconds,
    String? notes,
  }) {
    return PlannedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }

  factory PlannedExercise.fromJson(Map<String, dynamic> json) {
    return PlannedExercise(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      primaryMuscle: json['primary_muscle'] as String?,
      secondaryMuscles: (json['secondary_muscles'] as List?)?.cast<String>() ?? [],
      sets: json['sets'] as int,
      reps: json['reps'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'exercise_name': exerciseName,
    'primary_muscle': primaryMuscle,
    'secondary_muscles': secondaryMuscles,
    'sets': sets,
    'reps': reps,
    'duration_seconds': durationSeconds,
    'weight_kg': weightKg,
    'rest_seconds': restSeconds,
    'notes': notes,
  };

  @override
  List<Object?> get props => [exerciseId, sets, reps, durationSeconds, weightKg];
}

// ============================================================================
// MUSKELGRUPPEN-ANALYSE (Muscle Balance)
// ============================================================================

/// Muskelgruppen-Analyse basierend auf Trainingsplänen
class MuscleAnalysis {
  final Map<String, MuscleTrainingData> muscleData;
  final List<String> undertrained;
  final List<String> overtrained;
  final List<String> balanced;

  const MuscleAnalysis({
    required this.muscleData,
    required this.undertrained,
    required this.overtrained,
    required this.balanced,
  });

  factory MuscleAnalysis.empty() {
    return const MuscleAnalysis(
      muscleData: {},
      undertrained: [],
      overtrained: [],
      balanced: [],
    );
  }

  /// Berechnet Muskelanalyse aus Trainingsplänen und Sessions
  factory MuscleAnalysis.calculate(
    List<WorkoutPlan> plans, 
    List<SportSession> recentSessions, {
    int daysToAnalyze = 14,
  }) {
    final muscleData = <String, MuscleTrainingData>{};
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: daysToAnalyze));
    
    // Zähle Muskelgruppen aus Plänen
    for (final plan in plans) {
      for (final exercise in plan.exercises) {
        // Primäre Muskelgruppe
        if (exercise.primaryMuscle != null) {
          muscleData.putIfAbsent(
            exercise.primaryMuscle!,
            () => MuscleTrainingData(muscleId: exercise.primaryMuscle!),
          );
          muscleData[exercise.primaryMuscle!] = muscleData[exercise.primaryMuscle!]!.addPrimary(
            exercise.sets,
            exercise.reps ?? 10,
          );
        }
        
        // Sekundäre Muskelgruppen
        for (final secondary in exercise.secondaryMuscles) {
          muscleData.putIfAbsent(
            secondary,
            () => MuscleTrainingData(muscleId: secondary),
          );
          muscleData[secondary] = muscleData[secondary]!.addSecondary(
            exercise.sets,
            exercise.reps ?? 10,
          );
        }
      }
    }
    
    // Klassifiziere Muskeln
    final allMuscleIds = [
      'chest', 'shoulders', 'triceps', 'back', 'lats', 'biceps', 
      'quads', 'hamstrings', 'glutes', 'calves', 'abs', 'obliques'
    ];
    
    final undertrained = <String>[];
    final overtrained = <String>[];
    final balanced = <String>[];
    
    // Durchschnittliche Belastung berechnen
    final scores = muscleData.values.map((d) => d.totalScore).toList();
    final avgScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    
    for (final muscleId in allMuscleIds) {
      final data = muscleData[muscleId];
      if (data == null || data.totalScore < avgScore * 0.3) {
        undertrained.add(muscleId);
      } else if (data.totalScore > avgScore * 1.7) {
        overtrained.add(muscleId);
      } else {
        balanced.add(muscleId);
      }
    }
    
    return MuscleAnalysis(
      muscleData: muscleData,
      undertrained: undertrained,
      overtrained: overtrained,
      balanced: balanced,
    );
  }
}

/// Trainingsbelastung für eine Muskelgruppe
class MuscleTrainingData {
  final String muscleId;
  final int primarySets;
  final int primaryReps;
  final int secondarySets;
  final int secondaryReps;

  const MuscleTrainingData({
    required this.muscleId,
    this.primarySets = 0,
    this.primaryReps = 0,
    this.secondarySets = 0,
    this.secondaryReps = 0,
  });

  /// Gesamt-Score (primär zählt mehr)
  double get totalScore => (primarySets * 1.0) + (secondarySets * 0.5);

  /// Volumen (Sets × Reps)
  int get totalVolume => (primarySets * primaryReps) + (secondarySets * secondaryReps);

  MuscleTrainingData addPrimary(int sets, int reps) {
    return MuscleTrainingData(
      muscleId: muscleId,
      primarySets: primarySets + sets,
      primaryReps: primaryReps + reps,
      secondarySets: secondarySets,
      secondaryReps: secondaryReps,
    );
  }

  MuscleTrainingData addSecondary(int sets, int reps) {
    return MuscleTrainingData(
      muscleId: muscleId,
      primarySets: primarySets,
      primaryReps: primaryReps,
      secondarySets: secondarySets + sets,
      secondaryReps: secondaryReps + reps,
    );
  }
}

