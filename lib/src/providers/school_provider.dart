import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/school_model.dart';
import '../repositories/repositories.dart';

/// School Repository Provider
final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSchoolRepository();
  }
  return SupabaseSchoolRepository(Supabase.instance.client);
});

/// Fächer (Subjects) Notifier
class SubjectsNotifier extends StateNotifier<List<Subject>> {
  final SchoolRepository _repository;
  String? _userId;
  
  SubjectsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSubjects(userId);
  }
  
  Future<Subject> add(Subject subject) async {
    final created = await _repository.addSubject(subject);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(Subject subject) async {
    await _repository.updateSubject(subject);
    state = state.map((s) => s.id == subject.id ? subject : s).toList();
  }
  
  Future<void> delete(String subjectId) async {
    await _repository.deleteSubject(subjectId);
    state = state.where((s) => s.id != subjectId).toList();
  }
}

final subjectsNotifierProvider = StateNotifierProvider<SubjectsNotifier, List<Subject>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SubjectsNotifier(repository);
});

/// Stundenplan Notifier
class TimetableNotifier extends StateNotifier<List<TimetableEntry>> {
  final SchoolRepository _repository;
  String? _userId;
  
  TimetableNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getTimetable(userId);
  }
  
  List<TimetableEntry> getForDay(Weekday weekday) {
    return state.where((t) => t.weekday == weekday).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }
  
  Future<TimetableEntry> add(TimetableEntry entry) async {
    final created = await _repository.addTimetableEntry(entry);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(TimetableEntry entry) async {
    await _repository.updateTimetableEntry(entry);
    state = state.map((t) => t.id == entry.id ? entry : t).toList();
  }
  
  Future<void> delete(String entryId) async {
    await _repository.deleteTimetableEntry(entryId);
    state = state.where((t) => t.id != entryId).toList();
  }
}

final timetableNotifierProvider = StateNotifierProvider<TimetableNotifier, List<TimetableEntry>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return TimetableNotifier(repository);
});

/// Noten Notifier
class GradesNotifier extends StateNotifier<List<Grade>> {
  final SchoolRepository _repository;
  String? _userId;
  
  GradesNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getGrades(userId);
  }
  
  List<Grade> getForSubject(String subjectId) {
    return state.where((g) => g.subjectId == subjectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  /// Durchschnitt für ein Fach berechnen
  double getAverageForSubject(String subjectId) {
    final grades = getForSubject(subjectId);
    if (grades.isEmpty) return 0;
    double weightedSum = 0;
    double totalWeight = 0;
    for (final grade in grades) {
      weightedSum += grade.points * grade.weight;
      totalWeight += grade.weight;
    }
    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }
  
  /// Gesamtdurchschnitt
  double get overallAverage {
    if (state.isEmpty) return 0;
    double weightedSum = 0;
    double totalWeight = 0;
    for (final grade in state) {
      weightedSum += grade.points * grade.weight;
      totalWeight += grade.weight;
    }
    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }
  
  Future<Grade> add(Grade grade) async {
    final created = await _repository.addGrade(grade);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(Grade grade) async {
    await _repository.updateGrade(grade);
    state = state.map((g) => g.id == grade.id ? grade : g).toList();
  }
  
  Future<void> delete(String gradeId) async {
    await _repository.deleteGrade(gradeId);
    state = state.where((g) => g.id != gradeId).toList();
  }
}

final gradesNotifierProvider = StateNotifierProvider<GradesNotifier, List<Grade>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return GradesNotifier(repository);
});

/// Lernzeit Notifier
class StudySessionsNotifier extends StateNotifier<List<StudySession>> {
  final SchoolRepository _repository;
  String? _userId;
  
  StudySessionsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getStudySessions(userId);
  }
  
  List<StudySession> getForSubject(String subjectId) {
    return state.where((s) => s.subjectId == subjectId).toList();
  }
  
  /// Gesamtlernzeit für ein Fach in Minuten
  int getTotalMinutesForSubject(String subjectId) {
    return getForSubject(subjectId).fold(0, (sum, s) => sum + s.durationMinutes);
  }
  
  /// Lernzeit dieser Woche
  int get weeklyMinutes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return state
        .where((s) => s.startTime.isAfter(start))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }
  
  Future<StudySession> add(StudySession session) async {
    final created = await _repository.addStudySession(session);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(StudySession session) async {
    await _repository.updateStudySession(session);
    state = state.map((s) => s.id == session.id ? session : s).toList();
  }
  
  Future<void> delete(String sessionId) async {
    await _repository.deleteStudySession(sessionId);
    state = state.where((s) => s.id != sessionId).toList();
  }
}

final studySessionsNotifierProvider = StateNotifierProvider<StudySessionsNotifier, List<StudySession>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return StudySessionsNotifier(repository);
});

/// Schultermine Notifier
class SchoolEventsNotifier extends StateNotifier<List<SchoolEvent>> {
  final SchoolRepository _repository;
  String? _userId;
  
  SchoolEventsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSchoolEvents(userId);
  }
  
  List<SchoolEvent> get upcoming {
    final now = DateTime.now();
    return state
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  List<SchoolEvent> getForSubject(String subjectId) {
    return state.where((e) => e.subjectId == subjectId).toList();
  }
  
  Future<SchoolEvent> add(SchoolEvent event) async {
    final created = await _repository.addSchoolEvent(event);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SchoolEvent event) async {
    await _repository.updateSchoolEvent(event);
    state = state.map((e) => e.id == event.id ? event : e).toList();
  }
  
  Future<void> delete(String eventId) async {
    await _repository.deleteSchoolEvent(eventId);
    state = state.where((e) => e.id != eventId).toList();
  }
}

final schoolEventsNotifierProvider = StateNotifierProvider<SchoolEventsNotifier, List<SchoolEvent>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SchoolEventsNotifier(repository);
});

/// Hausaufgaben Notifier
class HomeworkNotifier extends StateNotifier<List<Homework>> {
  final SchoolRepository _repository;
  String? _userId;
  
  HomeworkNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getHomework(userId);
  }
  
  List<Homework> get pending {
    return state.where((h) => h.status != HomeworkStatus.done).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  
  List<Homework> getForSubject(String subjectId) {
    return state.where((h) => h.subjectId == subjectId).toList();
  }
  
  Future<Homework> add(Homework homework) async {
    final created = await _repository.addHomework(homework);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(Homework homework) async {
    await _repository.updateHomework(homework);
    state = state.map((h) => h.id == homework.id ? homework : h).toList();
  }
  
  Future<void> updateStatus(String homeworkId, HomeworkStatus newStatus) async {
    final homework = state.firstWhere((h) => h.id == homeworkId);
    final updated = homework.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await update(updated);
  }
  
  Future<void> toggleStatus(String homeworkId) async {
    final homework = state.firstWhere((h) => h.id == homeworkId);
    final newStatus = homework.status == HomeworkStatus.done 
        ? HomeworkStatus.pending 
        : HomeworkStatus.done;
    await updateStatus(homeworkId, newStatus);
  }
  
  Future<void> delete(String homeworkId) async {
    await _repository.deleteHomework(homeworkId);
    state = state.where((h) => h.id != homeworkId).toList();
  }
}

final homeworkNotifierProvider = StateNotifierProvider<HomeworkNotifier, List<Homework>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return HomeworkNotifier(repository);
});

/// Schulnotizen Notifier
class SchoolNotesNotifier extends StateNotifier<List<SchoolNote>> {
  final SchoolRepository _repository;
  String? _userId;
  
  SchoolNotesNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getNotes(userId);
  }
  
  List<SchoolNote> getForSubject(String subjectId) {
    return state.where((n) => n.subjectId == subjectId).toList();
  }
  
  List<SchoolNote> get generalNotes {
    return state.where((n) => n.subjectId == null).toList();
  }
  
  Future<SchoolNote> add(SchoolNote note) async {
    final created = await _repository.addNote(note);
    state = [...state, created];
    return created;
  }
  
  Future<void> update(SchoolNote note) async {
    await _repository.updateNote(note);
    state = state.map((n) => n.id == note.id ? note : n).toList();
  }
  
  Future<void> togglePin(String noteId) async {
    final note = state.firstWhere((n) => n.id == noteId);
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await update(updated);
  }
  
  Future<void> updateColor(String noteId, String? color) async {
    final note = state.firstWhere((n) => n.id == noteId);
    final updated = SchoolNote(
      id: note.id,
      userId: note.userId,
      subjectId: note.subjectId,
      title: note.title,
      content: note.content,
      isPinned: note.isPinned,
      color: color,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
    );
    await update(updated);
  }
  
  Future<void> delete(String noteId) async {
    await _repository.deleteNote(noteId);
    state = state.where((n) => n.id != noteId).toList();
  }
}

final schoolNotesNotifierProvider = StateNotifierProvider<SchoolNotesNotifier, List<SchoolNote>>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SchoolNotesNotifier(repository);
});
