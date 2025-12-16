/// Demo Repository Implementations
/// Uses InMemoryDatabase for demo mode - no external connections required

import 'dart:async';
import '../models/models.dart';
import '../services/in_memory_database.dart';
import 'repository_interfaces.dart';

class DemoAuthRepository implements AuthRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  final _authController = StreamController<UserModel?>.broadcast();
  
  @override
  Future<UserModel?> getCurrentUser() async {
    return _db.currentUser;
  }
  
  @override
  Future<UserModel> signIn(String email, String password) async {
    final user = await _db.signIn(email, password);
    _authController.add(user);
    return user;
  }
  
  @override
  Future<UserModel> signUp(String email, String password, String? displayName) async {
    final user = await _db.signUp(email, password, displayName);
    _authController.add(user);
    return user;
  }
  
  @override
  Future<void> signOut() async {
    await _db.signOut();
    _authController.add(null);
  }
  
  @override
  Stream<UserModel?> authStateChanges() {
    // Emit current user immediately
    Future.microtask(() => _authController.add(_db.currentUser));
    return _authController.stream;
  }
}

class DemoSettingsRepository implements SettingsRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<SettingsModel?> getSettings(String userId) async {
    return _db.settings;
  }
  
  @override
  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    return await _db.updateSettings(settings);
  }
}

class DemoTodoRepository implements TodoRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<TodoModel>> getTodos(String userId) async {
    return _db.getTodosForUser(userId);
  }
  
  @override
  Future<TodoModel> createTodo(TodoModel todo) async {
    return await _db.createTodo(todo);
  }
  
  @override
  Future<TodoModel> updateTodo(TodoModel todo) async {
    return await _db.updateTodo(todo);
  }
  
  @override
  Future<void> deleteTodo(String todoId) async {
    await _db.deleteTodo(todoId);
  }
  
  @override
  Future<List<TodoOccurrence>> getOccurrences(String todoId) async {
    return _db.getOccurrencesForTodo(todoId);
  }
  
  @override
  Future<List<TodoOccurrence>> getOccurrencesForDate(String userId, DateTime date) async {
    return _db.getOccurrencesForDate(userId, date);
  }
  
  @override
  Future<TodoOccurrence> toggleOccurrence(String occurrenceId, bool done) async {
    return await _db.toggleOccurrence(occurrenceId, done);
  }
}

class DemoFoodRepository implements FoodRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate search
    return _db.searchProducts(query);
  }
  
  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _db.findProductByBarcode(barcode);
  }
  
  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    return await _db.addProduct(product);
  }
  
  @override
  Future<List<FoodLogModel>> getFoodLogs(String userId, DateTime date) async {
    return _db.getFoodLogsForDate(userId, date);
  }
  
  @override
  Future<List<FoodLogModel>> getFoodLogsRange(String userId, DateTime start, DateTime end) async {
    return _db.getFoodLogsForRange(userId, start, end);
  }
  
  @override
  Future<FoodLogModel> addFoodLog(FoodLogModel log) async {
    return await _db.addFoodLog(log);
  }
  
  @override
  Future<void> deleteFoodLog(String logId) async {
    await _db.deleteFoodLog(logId);
  }
}

class DemoWaterRepository implements WaterRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<WaterLogModel>> getWaterLogs(String userId, DateTime date) async {
    return _db.getWaterLogsForDate(userId, date);
  }
  
  @override
  Future<int> getTotalWater(String userId, DateTime date) async {
    return _db.getTotalWaterForDate(userId, date);
  }
  
  @override
  Future<WaterLogModel> addWaterLog(WaterLogModel log) async {
    return await _db.addWaterLog(log);
  }
  
  @override
  Future<void> deleteWaterLog(String logId) async {
    await _db.deleteWaterLog(logId);
  }
}

class DemoStepsRepository implements StepsRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<StepsLogModel?> getSteps(String userId, DateTime date) async {
    return _db.getStepsForDate(userId, date);
  }
  
  @override
  Future<List<StepsLogModel>> getStepsRange(String userId, DateTime start, DateTime end) async {
    return _db.getStepsForRange(userId, start, end);
  }
  
  @override
  Future<StepsLogModel> upsertSteps(StepsLogModel log) async {
    return await _db.upsertStepsLog(log);
  }
}

class DemoSleepRepository implements SleepRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<SleepLogModel?> getSleep(String userId, DateTime date) async {
    return _db.getSleepForDate(userId, date);
  }
  
  @override
  Future<List<SleepLogModel>> getSleepRange(String userId, DateTime start, DateTime end) async {
    return _db.getSleepForRange(userId, start, end);
  }
  
  @override
  Future<SleepLogModel> addSleep(SleepLogModel log) async {
    return await _db.addSleepLog(log);
  }
  
  @override
  Future<void> deleteSleep(String logId) async {
    await _db.deleteSleepLog(logId);
  }
}

class DemoMoodRepository implements MoodRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<MoodLogModel?> getMood(String userId, DateTime date) async {
    return _db.getMoodForDate(userId, date);
  }
  
  @override
  Future<List<MoodLogModel>> getMoodRange(String userId, DateTime start, DateTime end) async {
    return _db.getMoodForRange(userId, start, end);
  }
  
  @override
  Future<MoodLogModel> upsertMood(MoodLogModel log) async {
    return await _db.upsertMoodLog(log);
  }
}

class DemoBookRepository implements BookRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  @override
  Future<List<BookModel>> getBooks(String userId) async {
    return _db.getBooksForUser(userId);
  }
  
  @override
  Future<List<BookModel>> getBooksByStatus(String userId, BookStatus status) async {
    return _db.getBooksByStatus(userId, status);
  }
  
  @override
  Future<BookModel> addBook(BookModel book) async {
    return await _db.addBook(book);
  }
  
  @override
  Future<BookModel> updateBook(BookModel book) async {
    return await _db.updateBook(book);
  }
  
  @override
  Future<void> deleteBook(String bookId) async {
    await _db.deleteBook(bookId);
  }
  
  @override
  Future<ReadingGoalModel?> getReadingGoal(String userId) async {
    return _db.getReadingGoal(userId);
  }
  
  @override
  Future<ReadingGoalModel> upsertReadingGoal(ReadingGoalModel goal) async {
    return await _db.upsertReadingGoal(goal);
  }
  
  @override
  Future<void> addReadingSession(String oderId, ReadingSession session) async {
    await _db.addReadingSession(oderId, session);
  }
}

// ============================================================================
// SCHOOL REPOSITORY (Demo)
// ============================================================================

class DemoSchoolRepository implements SchoolRepository {
  final InMemoryDatabase _db = InMemoryDatabase();
  
  // In-Memory Storage für Schuldaten
  final List<Subject> _subjects = [];
  final List<TimetableEntry> _timetable = [];
  final List<Grade> _grades = [];
  final List<StudySession> _studySessions = [];
  final List<SchoolEvent> _events = [];
  final List<Homework> _homework = [];
  final List<SchoolNote> _notes = [];
  final List<GradeCalculatorConfig> _gradeConfigs = [];
  
  // ===================== SUBJECTS =====================
  
  @override
  Future<List<Subject>> getSubjects(String userId) async {
    return _subjects.where((s) => s.userId == userId && s.active).toList();
  }
  
  @override
  Future<Subject> addSubject(Subject subject) async {
    _subjects.add(subject);
    return subject;
  }
  
  @override
  Future<Subject> updateSubject(Subject subject) async {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
    }
    return subject;
  }
  
  @override
  Future<void> deleteSubject(String subjectId) async {
    _subjects.removeWhere((s) => s.id == subjectId);
  }
  
  // ===================== TIMETABLE =====================
  
  @override
  Future<List<TimetableEntry>> getTimetable(String userId) async {
    return _timetable.where((t) => t.userId == userId).toList()
      ..sort((a, b) {
        final dayCompare = a.weekday.index.compareTo(b.weekday.index);
        if (dayCompare != 0) return dayCompare;
        return a.lessonNumber.compareTo(b.lessonNumber);
      });
  }
  
  @override
  Future<List<TimetableEntry>> getTimetableForDay(String userId, Weekday weekday) async {
    return _timetable
        .where((t) => t.userId == userId && t.weekday == weekday)
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }
  
  @override
  Future<TimetableEntry> addTimetableEntry(TimetableEntry entry) async {
    _timetable.add(entry);
    return entry;
  }
  
  @override
  Future<TimetableEntry> updateTimetableEntry(TimetableEntry entry) async {
    final index = _timetable.indexWhere((t) => t.id == entry.id);
    if (index != -1) {
      _timetable[index] = entry;
    }
    return entry;
  }
  
  @override
  Future<void> deleteTimetableEntry(String entryId) async {
    _timetable.removeWhere((t) => t.id == entryId);
  }
  
  // ===================== GRADES =====================
  
  @override
  Future<List<Grade>> getGrades(String userId) async {
    return _grades.where((g) => g.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  @override
  Future<List<Grade>> getGradesForSubject(String userId, String subjectId) async {
    return _grades
        .where((g) => g.userId == userId && g.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  @override
  Future<Grade> addGrade(Grade grade) async {
    _grades.add(grade);
    return grade;
  }
  
  @override
  Future<Grade> updateGrade(Grade grade) async {
    final index = _grades.indexWhere((g) => g.id == grade.id);
    if (index != -1) {
      _grades[index] = grade;
    }
    return grade;
  }
  
  @override
  Future<void> deleteGrade(String gradeId) async {
    _grades.removeWhere((g) => g.id == gradeId);
  }
  
  // ===================== STUDY SESSIONS =====================
  
  @override
  Future<List<StudySession>> getStudySessions(String userId) async {
    return _studySessions.where((s) => s.userId == userId).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }
  
  @override
  Future<List<StudySession>> getStudySessionsForSubject(String userId, String subjectId) async {
    return _studySessions
        .where((s) => s.userId == userId && s.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }
  
  @override
  Future<List<StudySession>> getStudySessionsRange(String userId, DateTime start, DateTime end) async {
    return _studySessions
        .where((s) => s.userId == userId && 
            s.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
            s.startTime.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }
  
  @override
  Future<StudySession> addStudySession(StudySession session) async {
    _studySessions.add(session);
    return session;
  }
  
  @override
  Future<StudySession> updateStudySession(StudySession session) async {
    final index = _studySessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _studySessions[index] = session;
    }
    return session;
  }
  
  @override
  Future<void> deleteStudySession(String sessionId) async {
    _studySessions.removeWhere((s) => s.id == sessionId);
  }
  
  // ===================== SCHOOL EVENTS =====================
  
  @override
  Future<List<SchoolEvent>> getSchoolEvents(String userId) async {
    return _events.where((e) => e.userId == userId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  @override
  Future<List<SchoolEvent>> getUpcomingEvents(String userId, {int days = 14}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    return _events
        .where((e) => e.userId == userId && 
            e.date.isAfter(now.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  @override
  Future<List<SchoolEvent>> getEventsForSubject(String userId, String subjectId) async {
    return _events
        .where((e) => e.userId == userId && e.subjectId == subjectId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  @override
  Future<SchoolEvent> addSchoolEvent(SchoolEvent event) async {
    _events.add(event);
    return event;
  }
  
  @override
  Future<SchoolEvent> updateSchoolEvent(SchoolEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
    return event;
  }
  
  @override
  Future<void> deleteSchoolEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
  }
  
  // ===================== HOMEWORK =====================
  
  @override
  Future<List<Homework>> getHomework(String userId) async {
    return _homework.where((h) => h.userId == userId).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  
  @override
  Future<List<Homework>> getPendingHomework(String userId) async {
    return _homework
        .where((h) => h.userId == userId && h.status != HomeworkStatus.done)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  
  @override
  Future<List<Homework>> getHomeworkForSubject(String userId, String subjectId) async {
    return _homework
        .where((h) => h.userId == userId && h.subjectId == subjectId)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
  
  @override
  Future<Homework> addHomework(Homework homework) async {
    _homework.add(homework);
    return homework;
  }
  
  @override
  Future<Homework> updateHomework(Homework homework) async {
    final index = _homework.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      _homework[index] = homework;
    }
    return homework;
  }
  
  @override
  Future<void> deleteHomework(String homeworkId) async {
    _homework.removeWhere((h) => h.id == homeworkId);
  }
  
  // ===================== NOTES =====================
  
  @override
  Future<List<SchoolNote>> getNotes(String userId) async {
    return _notes.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  @override
  Future<List<SchoolNote>> getNotesForSubject(String userId, String subjectId) async {
    return _notes
        .where((n) => n.userId == userId && n.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  @override
  Future<SchoolNote> addNote(SchoolNote note) async {
    _notes.add(note);
    return note;
  }
  
  @override
  Future<SchoolNote> updateNote(SchoolNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    }
    return note;
  }
  
  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
  }
  
  // ===================== GRADE CALCULATOR CONFIG =====================
  
  @override
  Future<GradeCalculatorConfig?> getGradeCalculatorConfig(String userId, {String? subjectId}) async {
    return _gradeConfigs.cast<GradeCalculatorConfig?>().firstWhere(
      (c) => c?.userId == userId && c?.subjectId == subjectId,
      orElse: () => null,
    );
  }
  
  @override
  Future<GradeCalculatorConfig> upsertGradeCalculatorConfig(GradeCalculatorConfig config) async {
    final index = _gradeConfigs.indexWhere(
      (c) => c.userId == config.userId && c.subjectId == config.subjectId,
    );
    if (index != -1) {
      _gradeConfigs[index] = config;
    } else {
      _gradeConfigs.add(config);
    }
    return config;
  }
  
  // ===================== SUBJECT PROFILE =====================
  
  @override
  Future<SubjectProfile> getSubjectProfile(String userId, String subjectId) async {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => throw Exception('Subject not found'),
    );
    
    final grades = await getGradesForSubject(userId, subjectId);
    final studySessions = await getStudySessionsForSubject(userId, subjectId);
    final events = await getEventsForSubject(userId, subjectId);
    final homework = await getHomeworkForSubject(userId, subjectId);
    final notes = await getNotesForSubject(userId, subjectId);
    
    return SubjectProfile(
      subject: subject,
      grades: grades,
      studySessions: studySessions,
      upcomingEvents: events.where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList(),
      pendingHomework: homework.where((h) => h.status != HomeworkStatus.done).toList(),
      notes: notes,
    );
  }
}
