/// Timer Widget Model - Universal Timer für verschiedene Aktivitäten
/// Kann für Lesen, Meditation, Sport etc. verwendet werden

import 'package:equatable/equatable.dart';

/// Verfügbare Timer-Aktivitäten
enum TimerActivityType {
  reading('Lesen', 'menu_book'),
  meditation('Meditation', 'self_improvement'),
  sport('Sport', 'fitness_center'),
  work('Arbeiten', 'work'),
  study('Lernen', 'school'),
  custom('Sonstiges', 'timer');

  final String label;
  final String iconName;

  const TimerActivityType(this.label, this.iconName);
}

/// Eine einzelne Timer-Session
class TimerSessionModel extends Equatable {
  final String id;
  final String oderId;
  final TimerActivityType activityType;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds; // Gesamtdauer in Sekunden
  final String? note; // Optional: Notiz zur Session
  final String? linkedItemId; // Optional: Verknüpftes Element (z.B. Buch-ID)

  const TimerSessionModel({
    required this.id,
    required this.oderId,
    required this.activityType,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.note,
    this.linkedItemId,
  });

  /// Session läuft gerade
  bool get isActive => endTime == null;

  /// Dauer in Minuten
  int get durationMinutes => durationSeconds ~/ 60;

  /// Formatierte Dauer (HH:MM:SS)
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Kurze Dauer-Anzeige
  String get shortDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else if (minutes > 0) {
      return '${minutes}min';
    } else {
      return '< 1min';
    }
  }

  factory TimerSessionModel.fromJson(Map<String, dynamic> json) {
    return TimerSessionModel(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      activityType: TimerActivityType.values.firstWhere(
        (t) => t.name == json['activity_type'],
        orElse: () => TimerActivityType.custom,
      ),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      note: json['note'] as String?,
      linkedItemId: json['linked_item_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'activity_type': activityType.name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'note': note,
      'linked_item_id': linkedItemId,
    };
  }

  TimerSessionModel copyWith({
    String? id,
    String? oderId,
    TimerActivityType? activityType,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    String? note,
    String? linkedItemId,
  }) {
    return TimerSessionModel(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      note: note ?? this.note,
      linkedItemId: linkedItemId ?? this.linkedItemId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        oderId,
        activityType,
        startTime,
        endTime,
        durationSeconds,
        note,
        linkedItemId,
      ];
}

/// Aggregierte Statistiken für einen Zeitraum
class TimerStatsModel extends Equatable {
  final TimerActivityType activityType;
  final int totalSeconds;
  final int sessionCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  const TimerStatsModel({
    required this.activityType,
    required this.totalSeconds,
    required this.sessionCount,
    required this.periodStart,
    required this.periodEnd,
  });

  /// Durchschnittliche Session-Dauer in Minuten
  double get averageMinutes =>
      sessionCount > 0 ? (totalSeconds / 60) / sessionCount : 0;

  /// Gesamtzeit in Stunden
  double get totalHours => totalSeconds / 3600;

  /// Formatierte Gesamtzeit
  String get formattedTotal {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  factory TimerStatsModel.fromSessions({
    required TimerActivityType activityType,
    required List<TimerSessionModel> sessions,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final filteredSessions = sessions.where((s) =>
        s.activityType == activityType &&
        s.startTime.isAfter(periodStart) &&
        s.startTime.isBefore(periodEnd));

    return TimerStatsModel(
      activityType: activityType,
      totalSeconds: filteredSessions.fold(0, (sum, s) => sum + s.durationSeconds),
      sessionCount: filteredSessions.length,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  @override
  List<Object?> get props => [
        activityType,
        totalSeconds,
        sessionCount,
        periodStart,
        periodEnd,
      ];
}

/// Timer-Ziel für eine Aktivität
class TimerGoalModel extends Equatable {
  final String id;
  final String oderId;
  final TimerActivityType activityType;
  final int targetMinutesPerWeek; // Wochenziel in Minuten
  final int targetMinutesPerMonth; // Monatsziel in Minuten (optional)
  final bool isActive;

  const TimerGoalModel({
    required this.id,
    required this.oderId,
    required this.activityType,
    this.targetMinutesPerWeek = 0,
    this.targetMinutesPerMonth = 0,
    this.isActive = true,
  });

  factory TimerGoalModel.fromJson(Map<String, dynamic> json) {
    return TimerGoalModel(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      activityType: TimerActivityType.values.firstWhere(
        (t) => t.name == json['activity_type'],
        orElse: () => TimerActivityType.custom,
      ),
      targetMinutesPerWeek: json['target_minutes_per_week'] as int? ?? 0,
      targetMinutesPerMonth: json['target_minutes_per_month'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'activity_type': activityType.name,
      'target_minutes_per_week': targetMinutesPerWeek,
      'target_minutes_per_month': targetMinutesPerMonth,
      'is_active': isActive,
    };
  }

  TimerGoalModel copyWith({
    String? id,
    String? oderId,
    TimerActivityType? activityType,
    int? targetMinutesPerWeek,
    int? targetMinutesPerMonth,
    bool? isActive,
  }) {
    return TimerGoalModel(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      activityType: activityType ?? this.activityType,
      targetMinutesPerWeek: targetMinutesPerWeek ?? this.targetMinutesPerWeek,
      targetMinutesPerMonth: targetMinutesPerMonth ?? this.targetMinutesPerMonth,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        oderId,
        activityType,
        targetMinutesPerWeek,
        targetMinutesPerMonth,
        isActive,
      ];
}
