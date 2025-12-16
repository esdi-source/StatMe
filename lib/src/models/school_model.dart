import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Notentyp für Bewertungen
enum GradeType {
  exam('Schulaufgabe'),
  shortTest('Kurzarbeit'),
  oralExam('Mündliche Note'),
  presentation('Referat'),
  homework('Hausaufgabe'),
  project('Projekt'),
  other('Sonstige');

  final String label;
  const GradeType(this.label);

  /// Standard-Gewichtung für jeden Notentyp
  double get defaultWeight {
    switch (this) {
      case GradeType.exam:
        return 2.0;
      case GradeType.shortTest:
        return 1.0;
      case GradeType.oralExam:
        return 1.0;
      case GradeType.presentation:
        return 1.0;
      case GradeType.homework:
        return 0.5;
      case GradeType.project:
        return 1.5;
      case GradeType.other:
        return 1.0;
    }
  }
}

/// Wochentage für Stundenplan
enum Weekday {
  monday('Montag', 'Mo'),
  tuesday('Dienstag', 'Di'),
  wednesday('Mittwoch', 'Mi'),
  thursday('Donnerstag', 'Do'),
  friday('Freitag', 'Fr'),
  saturday('Samstag', 'Sa'),
  sunday('Sonntag', 'So');

  final String label;
  final String short;
  const Weekday(this.label, this.short);
}

/// Typ für Schultermine
enum SchoolEventType {
  exam('Schulaufgabe'),
  shortTest('Kurzarbeit'),
  presentation('Referat'),
  deadline('Abgabe'),
  excursion('Ausflug'),
  other('Sonstiger Termin');

  final String label;
  const SchoolEventType(this.label);
}

/// Hausaufgaben-Status
enum HomeworkStatus {
  pending('Offen'),
  inProgress('In Bearbeitung'),
  done('Erledigt');

  final String label;
  const HomeworkStatus(this.label);
}

// ============================================================================
// FACH (Subject) - Zentrales Element
// ============================================================================

/// Ein Schulfach mit allen zugehörigen Daten
class Subject extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? shortName; // z.B. "M" für Mathe
  final int? colorValue; // Individuelle Farbe
  final int funFactor; // Spaß-Faktor 1-5
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subject({
    required this.id,
    required this.userId,
    required this.name,
    this.shortName,
    this.colorValue,
    this.funFactor = 3,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Subject copyWith({
    String? id,
    String? userId,
    String? name,
    String? shortName,
    int? colorValue,
    int? funFactor,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      colorValue: colorValue ?? this.colorValue,
      funFactor: funFactor ?? this.funFactor,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
      colorValue: json['color_value'] as int?,
      funFactor: json['fun_factor'] as int? ?? 3,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'short_name': shortName,
      'color_value': colorValue,
      'fun_factor': funFactor,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, name, shortName, colorValue, funFactor, active, createdAt, updatedAt];
}

// ============================================================================
// STUNDENPLAN (Timetable)
// ============================================================================

/// Eine einzelne Unterrichtsstunde im Stundenplan
class TimetableEntry extends Equatable {
  final String id;
  final String userId;
  final String subjectId;
  final Weekday weekday;
  final int lessonNumber; // 1. Stunde, 2. Stunde, etc.
  final String? startTime; // z.B. "08:00"
  final String? endTime; // z.B. "08:45"
  final String? room;
  final String? teacher;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimetableEntry({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.weekday,
    required this.lessonNumber,
    this.startTime,
    this.endTime,
    this.room,
    this.teacher,
    required this.createdAt,
    required this.updatedAt,
  });

  TimetableEntry copyWith({
    String? id,
    String? userId,
    String? subjectId,
    Weekday? weekday,
    int? lessonNumber,
    String? startTime,
    String? endTime,
    String? room,
    String? teacher,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      weekday: weekday ?? this.weekday,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      weekday: Weekday.values.firstWhere(
        (w) => w.name == json['weekday'],
        orElse: () => Weekday.monday,
      ),
      lessonNumber: json['lesson_number'] as int,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      room: json['room'] as String?,
      teacher: json['teacher'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'weekday': weekday.name,
      'lesson_number': lessonNumber,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'teacher': teacher,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subjectId, weekday, lessonNumber, startTime, endTime, room, teacher, createdAt, updatedAt];
}

// ============================================================================
// NOTEN (Grades) - Punktesystem 1-15
// ============================================================================

/// Eine einzelne Note/Bewertung
class Grade extends Equatable {
  final String id;
  final String userId;
  final String subjectId;
  final int points; // 1-15 Punkte
  final GradeType type;
  final double weight; // Gewichtung (z.B. 1.0, 2.0)
  final DateTime date;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Grade({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.points,
    required this.type,
    this.weight = 1.0,
    required this.date,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Konvertiert Punkte zu traditioneller Note (1-6)
  double get asTraditionalGrade {
    if (points >= 15) return 1.0;
    if (points >= 13) return 1.0 + (15 - points) * 0.33;
    if (points >= 10) return 2.0 + (13 - points) * 0.33;
    if (points >= 7) return 3.0 + (10 - points) * 0.33;
    if (points >= 4) return 4.0 + (7 - points) * 0.33;
    if (points >= 1) return 5.0 + (4 - points) * 0.33;
    return 6.0;
  }

  Grade copyWith({
    String? id,
    String? userId,
    String? subjectId,
    int? points,
    GradeType? type,
    double? weight,
    DateTime? date,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Grade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      points: points ?? this.points,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      points: json['points'] as int,
      type: GradeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => GradeType.other,
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'points': points,
      'type': type.name,
      'weight': weight,
      'date': date.toIso8601String(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subjectId, points, type, weight, date, description, createdAt, updatedAt];
}

// ============================================================================
// LERNZEIT (Study Time)
// ============================================================================

/// Ein Lernzeit-Eintrag
class StudySession extends Equatable {
  final String id;
  final String userId;
  final String subjectId; // Pflichtfeld: Fachzuordnung
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes; // Entweder berechnet oder manuell
  final bool isTimerBased; // true = Timer, false = manuell
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudySession({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.isTimerBased = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatierte Dauer
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  StudySession copyWith({
    String? id,
    String? userId,
    String? subjectId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    bool? isTimerBased,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isTimerBased: isTimerBased ?? this.isTimerBased,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      durationMinutes: json['duration_minutes'] as int,
      isTimerBased: json['is_timer_based'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'is_timer_based': isTimerBased,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subjectId, startTime, endTime, durationMinutes, isTimerBased, notes, createdAt, updatedAt];
}

// ============================================================================
// SCHULTERMINE (School Events)
// ============================================================================

/// Ein Schultermin (Arbeit, Referat, Abgabe, etc.)
class SchoolEvent extends Equatable {
  final String id;
  final String userId;
  final String? subjectId; // Optional fachbezogen
  final String title;
  final String? description;
  final SchoolEventType type;
  final DateTime date;
  final String? time; // Optional: Uhrzeit
  final bool reminder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolEvent({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.title,
    this.description,
    required this.type,
    required this.date,
    this.time,
    this.reminder = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Ist der Termin heute?
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Tage bis zum Termin
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    return eventDay.difference(today).inDays;
  }

  SchoolEvent copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? description,
    SchoolEventType? type,
    DateTime? date,
    String? time,
    bool? reminder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      time: time ?? this.time,
      reminder: reminder ?? this.reminder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SchoolEvent.fromJson(Map<String, dynamic> json) {
    return SchoolEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: SchoolEventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SchoolEventType.other,
      ),
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String?,
      reminder: json['reminder'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'type': type.name,
      'date': date.toIso8601String(),
      'time': time,
      'reminder': reminder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subjectId, title, description, type, date, time, reminder, createdAt, updatedAt];
}

// ============================================================================
// HAUSAUFGABEN (Homework)
// ============================================================================

/// Eine Hausaufgabe
class Homework extends Equatable {
  final String id;
  final String userId;
  final String? subjectId; // Optional fachbezogen
  final String title;
  final String? description;
  final DateTime dueDate;
  final HomeworkStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Homework({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.title,
    this.description,
    required this.dueDate,
    this.status = HomeworkStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Ist überfällig?
  bool get isOverdue {
    if (status == HomeworkStatus.done) return false;
    return DateTime.now().isAfter(dueDate);
  }

  Homework copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? description,
    DateTime? dueDate,
    HomeworkStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Homework(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: HomeworkStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => HomeworkStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subjectId, title, description, dueDate, status, createdAt, updatedAt];
}

// ============================================================================
// NOTIZEN (Notes)
// ============================================================================

/// Eine Notiz (allgemein oder fachbezogen)
class SchoolNote extends Equatable {
  final String id;
  final String userId;
  final String? subjectId; // Optional fachbezogen
  final String title;
  final String content;
  final bool isPinned;
  final String? color; // Hex color wie '#FFECB3'
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolNote({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  SchoolNote copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? title,
    String? content,
    bool? isPinned,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SchoolNote.fromJson(Map<String, dynamic> json) {
    return SchoolNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subjectId, title, content, isPinned, color, createdAt, updatedAt];
}

// ============================================================================
// FACHPROFIL (Subject Profile) - Aggregierte Ansicht
// ============================================================================

/// Aggregiertes Fachprofil mit allen relevanten Daten
class SubjectProfile {
  final Subject subject;
  final List<Grade> grades;
  final List<StudySession> studySessions;
  final List<SchoolEvent> upcomingEvents;
  final List<Homework> pendingHomework;
  final List<SchoolNote> notes;

  const SubjectProfile({
    required this.subject,
    this.grades = const [],
    this.studySessions = const [],
    this.upcomingEvents = const [],
    this.pendingHomework = const [],
    this.notes = const [],
  });

  /// Durchschnittliche Punktzahl
  double get averagePoints {
    if (grades.isEmpty) return 0;
    double weightedSum = 0;
    double totalWeight = 0;
    for (final grade in grades) {
      weightedSum += grade.points * grade.weight;
      totalWeight += grade.weight;
    }
    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }

  /// Gesamte Lernzeit in Minuten
  int get totalStudyMinutes {
    return studySessions.fold(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Formatierte Gesamtlernzeit
  String get formattedTotalStudyTime {
    final hours = totalStudyMinutes ~/ 60;
    final minutes = totalStudyMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  /// Notentrend: +1 steigend, 0 stabil, -1 fallend
  int get gradeTrend {
    if (grades.length < 2) return 0;
    final sorted = List<Grade>.from(grades)..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.sublist((sorted.length - 3).clamp(0, sorted.length - 1));
    if (recent.length < 2) return 0;
    
    final firstAvg = recent.take(recent.length ~/ 2).map((g) => g.points).reduce((a, b) => a + b) / (recent.length ~/ 2);
    final secondAvg = recent.skip(recent.length ~/ 2).map((g) => g.points).reduce((a, b) => a + b) / (recent.length - recent.length ~/ 2);
    
    if (secondAvg > firstAvg + 1) return 1;
    if (secondAvg < firstAvg - 1) return -1;
    return 0;
  }

  /// Anzahl offener Hausaufgaben
  int get openHomeworkCount {
    return pendingHomework.where((h) => h.status != HomeworkStatus.done).length;
  }

  /// Nächster Termin
  SchoolEvent? get nextEvent {
    if (upcomingEvents.isEmpty) return null;
    final sorted = List<SchoolEvent>.from(upcomingEvents)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.firstWhere(
      (e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1))),
      orElse: () => sorted.first,
    );
  }
}

// ============================================================================
// NOTENRECHNER KONFIGURATION
// ============================================================================

/// Konfiguration für den Notenrechner (benutzerdefinierte Gewichtungen)
class GradeCalculatorConfig extends Equatable {
  final String id;
  final String userId;
  final String? subjectId; // null = globale Einstellung
  final Map<GradeType, double> typeWeights; // Gewichtung pro Notentyp
  final DateTime createdAt;
  final DateTime updatedAt;

  const GradeCalculatorConfig({
    required this.id,
    required this.userId,
    this.subjectId,
    this.typeWeights = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Standard-Gewichtung wenn nicht definiert
  double getWeight(GradeType type) {
    return typeWeights[type] ?? _defaultWeight(type);
  }

  static double _defaultWeight(GradeType type) {
    switch (type) {
      case GradeType.exam:
        return 2.0;
      case GradeType.shortTest:
        return 1.0;
      case GradeType.oralExam:
        return 1.0;
      case GradeType.presentation:
        return 1.0;
      case GradeType.homework:
        return 0.5;
      case GradeType.project:
        return 1.5;
      case GradeType.other:
        return 1.0;
    }
  }

  GradeCalculatorConfig copyWith({
    String? id,
    String? userId,
    String? subjectId,
    Map<GradeType, double>? typeWeights,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeCalculatorConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      typeWeights: typeWeights ?? this.typeWeights,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GradeCalculatorConfig.fromJson(Map<String, dynamic> json) {
    final weightsJson = json['type_weights'] as Map<String, dynamic>? ?? {};
    final weights = <GradeType, double>{};
    for (final entry in weightsJson.entries) {
      final type = GradeType.values.firstWhere(
        (t) => t.name == entry.key,
        orElse: () => GradeType.other,
      );
      weights[type] = (entry.value as num).toDouble();
    }

    return GradeCalculatorConfig(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      typeWeights: weights,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final weightsJson = <String, double>{};
    for (final entry in typeWeights.entries) {
      weightsJson[entry.key.name] = entry.value;
    }

    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'type_weights': weightsJson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subjectId, typeWeights, createdAt, updatedAt];
}
