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
