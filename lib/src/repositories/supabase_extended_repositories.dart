/// Extended Supabase Repository Implementations
/// 
/// Diese Datei enthält Supabase-Implementierungen für alle Widget-Repositories,
/// die bisher nur Demo-Implementierungen hatten.
/// 
/// Alle Daten werden benutzerspezifisch auf Supabase gespeichert.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'repository_interfaces.dart';
import '../services/supabase_data_service.dart';

// ============================================================================
// BOOK REPOSITORY - SUPABASE
// ============================================================================

class SupabaseBookRepository implements BookRepository {
  final SupabaseClient _client;
  final SupabaseDataService _dataService = SupabaseDataService.instance;

  SupabaseBookRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<List<BookModel>> getBooks(String userId) async {
    final response = await _client
        .from('books')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    
    return (response as List).map((json) => BookModel.fromJson(_mapBookFromDb(json))).toList();
  }

  @override
  Future<List<BookModel>> getBooksByStatus(String userId, BookStatus status) async {
    final response = await _client
        .from('books')
        .select()
        .eq('user_id', userId)
        .eq('status', status.name)
        .order('updated_at', ascending: false);
    
    return (response as List).map((json) => BookModel.fromJson(_mapBookFromDb(json))).toList();
  }

  @override
  Future<BookModel> addBook(BookModel book) async {
    final response = await _client
        .from('books')
        .insert(_mapBookToDb(book))
        .select()
        .single();
    
    await _dataService.logEvent(
      widgetName: 'books',
      eventType: 'created',
      payload: response,
      referenceId: response['id'],
    );
    
    return BookModel.fromJson(_mapBookFromDb(response));
  }

  @override
  Future<BookModel> updateBook(BookModel book) async {
    final response = await _client
        .from('books')
        .update(_mapBookToDb(book))
        .eq('id', book.id)
        .eq('user_id', _userId!)
        .select()
        .single();
    
    await _dataService.logEvent(
      widgetName: 'books',
      eventType: 'updated',
      payload: response,
      referenceId: response['id'],
    );
    
    return BookModel.fromJson(_mapBookFromDb(response));
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _client
        .from('books')
        .delete()
        .eq('id', bookId)
        .eq('user_id', _userId!);
    
    await _dataService.logEvent(
      widgetName: 'books',
      eventType: 'deleted',
      payload: {'id': bookId},
      referenceId: bookId,
    );
  }

  @override
  Future<ReadingGoalModel?> getReadingGoal(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    
    final response = await _client
        .from('reading_goals')
        .select()
        .eq('user_id', userId)
        .eq('week_start_date', weekStartStr)
        .maybeSingle();
    
    if (response == null) return null;
    return ReadingGoalModel.fromJson(_mapReadingGoalFromDb(response));
  }

  @override
  Future<ReadingGoalModel> upsertReadingGoal(ReadingGoalModel goal) async {
    final response = await _client
        .from('reading_goals')
        .upsert(_mapReadingGoalToDb(goal), onConflict: 'user_id,week_start_date')
        .select()
        .single();
    
    return ReadingGoalModel.fromJson(_mapReadingGoalFromDb(response));
  }

  @override
  Future<void> addReadingSession(String userId, ReadingSession session) async {
    await _client.from('reading_sessions').insert({
      'user_id': userId,
      'book_id': session.bookId,
      'duration_minutes': session.durationMinutes,
      'date': session.date.toIso8601String().split('T')[0],
    });
    
    // Update reading goal
    final goal = await getReadingGoal(userId);
    if (goal != null) {
      final updatedGoal = goal.copyWith(
        readMinutesThisWeek: goal.readMinutesThisWeek + session.durationMinutes,
      );
      await upsertReadingGoal(updatedGoal);
    }
    
    await _dataService.logEvent(
      widgetName: 'books',
      eventType: 'reading_session',
      payload: session.toJson(),
      referenceId: session.bookId,
    );
  }

  // Mapping Helpers
  Map<String, dynamic> _mapBookFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'oderId': db['user_id'], // Model uses oderId
      'title': db['title'],
      'author': db['author'],
      'coverUrl': db['cover_url'],
      'googleBooksId': db['google_books_id'],
      'isbn': db['isbn'],
      'pageCount': db['page_count'],
      'status': db['status'],
      'rating': db['rating_overall'] != null ? {
        'overall': db['rating_overall'],
        'story': db['rating_story'],
        'characters': db['rating_characters'],
        'writing': db['rating_writing'],
        'pacing': db['rating_pacing'],
        'emotional_impact': db['rating_emotional_impact'],
        'note': db['rating_note'],
      } : null,
      'addedAt': db['added_at'],
      'finishedAt': db['finished_at'],
    };
  }

  Map<String, dynamic> _mapBookToDb(BookModel book) {
    return {
      if (book.id.isNotEmpty) 'id': book.id,
      'user_id': book.oderId,
      'title': book.title,
      'author': book.author,
      'cover_url': book.coverUrl,
      'google_books_id': book.googleBooksId,
      'isbn': book.isbn,
      'page_count': book.pageCount,
      'status': book.status.name,
      'rating_overall': book.rating?.overall,
      'rating_story': book.rating?.story,
      'rating_characters': book.rating?.characters,
      'rating_writing': book.rating?.writing,
      'rating_pacing': book.rating?.pacing,
      'rating_emotional_impact': book.rating?.emotionalImpact,
      'rating_note': book.rating?.note,
      'added_at': book.addedAt.toIso8601String(),
      'finished_at': book.finishedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapReadingGoalFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'oderId': db['user_id'],
      'weeklyGoalMinutes': db['weekly_goal_minutes'],
      'readMinutesThisWeek': db['read_minutes_this_week'],
      'weekStartDate': db['week_start_date'],
    };
  }

  Map<String, dynamic> _mapReadingGoalToDb(ReadingGoalModel goal) {
    return {
      if (goal.id.isNotEmpty) 'id': goal.id,
      'user_id': goal.oderId,
      'weekly_goal_minutes': goal.weeklyGoalMinutes,
      'read_minutes_this_week': goal.readMinutesThisWeek,
      'week_start_date': '${goal.weekStartDate.year}-${goal.weekStartDate.month.toString().padLeft(2, '0')}-${goal.weekStartDate.day.toString().padLeft(2, '0')}',
    };
  }
}

// ============================================================================
// SCHOOL REPOSITORY - SUPABASE
// ============================================================================

class SupabaseSchoolRepository implements SchoolRepository {
  final SupabaseClient _client;
  final SupabaseDataService _dataService = SupabaseDataService.instance;

  SupabaseSchoolRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // --- SUBJECTS ---
  
  @override
  Future<List<Subject>> getSubjects(String userId) async {
    final response = await _client
        .from('subjects')
        .select()
        .eq('user_id', userId)
        .order('name');
    
    return (response as List).map((json) => Subject.fromJson(_mapSubjectFromDb(json))).toList();
  }

  @override
  Future<Subject> addSubject(Subject subject) async {
    final response = await _client
        .from('subjects')
        .insert(_mapSubjectToDb(subject))
        .select()
        .single();
    
    await _logEvent('school', 'subject_created', response);
    return Subject.fromJson(_mapSubjectFromDb(response));
  }

  @override
  Future<Subject> updateSubject(Subject subject) async {
    final response = await _client
        .from('subjects')
        .update(_mapSubjectToDb(subject))
        .eq('id', subject.id)
        .select()
        .single();
    
    return Subject.fromJson(_mapSubjectFromDb(response));
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    await _client.from('subjects').delete().eq('id', subjectId);
    await _logEvent('school', 'subject_deleted', {'id': subjectId});
  }

  // --- TIMETABLE ---
  
  @override
  Future<List<TimetableEntry>> getTimetable(String userId) async {
    final response = await _client
        .from('timetable_entries')
        .select()
        .eq('user_id', userId)
        .order('weekday')
        .order('lesson_number');
    
    return (response as List).map((json) => TimetableEntry.fromJson(_mapTimetableFromDb(json))).toList();
  }

  @override
  Future<List<TimetableEntry>> getTimetableForDay(String userId, Weekday weekday) async {
    final response = await _client
        .from('timetable_entries')
        .select()
        .eq('user_id', userId)
        .eq('weekday', weekday.index + 1)
        .order('lesson_number');
    
    return (response as List).map((json) => TimetableEntry.fromJson(_mapTimetableFromDb(json))).toList();
  }

  @override
  Future<TimetableEntry> addTimetableEntry(TimetableEntry entry) async {
    final response = await _client
        .from('timetable_entries')
        .insert(_mapTimetableToDb(entry))
        .select()
        .single();
    
    return TimetableEntry.fromJson(_mapTimetableFromDb(response));
  }

  @override
  Future<TimetableEntry> updateTimetableEntry(TimetableEntry entry) async {
    final response = await _client
        .from('timetable_entries')
        .update(_mapTimetableToDb(entry))
        .eq('id', entry.id)
        .select()
        .single();
    
    return TimetableEntry.fromJson(_mapTimetableFromDb(response));
  }

  @override
  Future<void> deleteTimetableEntry(String entryId) async {
    await _client.from('timetable_entries').delete().eq('id', entryId);
  }

  // --- GRADES ---
  
  @override
  Future<List<Grade>> getGrades(String userId) async {
    final response = await _client
        .from('grades')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    
    return (response as List).map((json) => Grade.fromJson(_mapGradeFromDb(json))).toList();
  }

  @override
  Future<List<Grade>> getGradesForSubject(String userId, String subjectId) async {
    final response = await _client
        .from('grades')
        .select()
        .eq('user_id', userId)
        .eq('subject_id', subjectId)
        .order('date', ascending: false);
    
    return (response as List).map((json) => Grade.fromJson(_mapGradeFromDb(json))).toList();
  }

  @override
  Future<Grade> addGrade(Grade grade) async {
    final response = await _client
        .from('grades')
        .insert(_mapGradeToDb(grade))
        .select()
        .single();
    
    await _logEvent('school', 'grade_created', response);
    return Grade.fromJson(_mapGradeFromDb(response));
  }

  @override
  Future<Grade> updateGrade(Grade grade) async {
    final response = await _client
        .from('grades')
        .update(_mapGradeToDb(grade))
        .eq('id', grade.id)
        .select()
        .single();
    
    return Grade.fromJson(_mapGradeFromDb(response));
  }

  @override
  Future<void> deleteGrade(String gradeId) async {
    await _client.from('grades').delete().eq('id', gradeId);
    await _logEvent('school', 'grade_deleted', {'id': gradeId});
  }

  // --- STUDY SESSIONS ---
  
  @override
  Future<List<StudySession>> getStudySessions(String userId) async {
    final response = await _client
        .from('study_sessions')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);
    
    return (response as List).map((json) => StudySession.fromJson(_mapStudySessionFromDb(json))).toList();
  }

  @override
  Future<List<StudySession>> getStudySessionsForSubject(String userId, String subjectId) async {
    final response = await _client
        .from('study_sessions')
        .select()
        .eq('user_id', userId)
        .eq('subject_id', subjectId)
        .order('start_time', ascending: false);
    
    return (response as List).map((json) => StudySession.fromJson(_mapStudySessionFromDb(json))).toList();
  }

  @override
  Future<List<StudySession>> getStudySessionsRange(String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('study_sessions')
        .select()
        .eq('user_id', userId)
        .gte('start_time', start.toIso8601String())
        .lte('start_time', end.toIso8601String())
        .order('start_time');
    
    return (response as List).map((json) => StudySession.fromJson(_mapStudySessionFromDb(json))).toList();
  }

  @override
  Future<StudySession> addStudySession(StudySession session) async {
    final response = await _client
        .from('study_sessions')
        .insert(_mapStudySessionToDb(session))
        .select()
        .single();
    
    await _logEvent('school', 'study_session_created', response);
    return StudySession.fromJson(_mapStudySessionFromDb(response));
  }

  @override
  Future<StudySession> updateStudySession(StudySession session) async {
    final response = await _client
        .from('study_sessions')
        .update(_mapStudySessionToDb(session))
        .eq('id', session.id)
        .select()
        .single();
    
    return StudySession.fromJson(_mapStudySessionFromDb(response));
  }

  @override
  Future<void> deleteStudySession(String sessionId) async {
    await _client.from('study_sessions').delete().eq('id', sessionId);
  }

  // --- SCHOOL EVENTS ---
  
  @override
  Future<List<SchoolEvent>> getSchoolEvents(String userId) async {
    final response = await _client
        .from('school_events')
        .select()
        .eq('user_id', userId)
        .order('date');
    
    return (response as List).map((json) => SchoolEvent.fromJson(_mapSchoolEventFromDb(json))).toList();
  }

  @override
  Future<List<SchoolEvent>> getUpcomingEvents(String userId, {int days = 14}) async {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    
    final response = await _client
        .from('school_events')
        .select()
        .eq('user_id', userId)
        .gte('date', now.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0])
        .order('date');
    
    return (response as List).map((json) => SchoolEvent.fromJson(_mapSchoolEventFromDb(json))).toList();
  }

  @override
  Future<List<SchoolEvent>> getEventsForSubject(String userId, String subjectId) async {
    final response = await _client
        .from('school_events')
        .select()
        .eq('user_id', userId)
        .eq('subject_id', subjectId)
        .order('date');
    
    return (response as List).map((json) => SchoolEvent.fromJson(_mapSchoolEventFromDb(json))).toList();
  }

  @override
  Future<SchoolEvent> addSchoolEvent(SchoolEvent event) async {
    final response = await _client
        .from('school_events')
        .insert(_mapSchoolEventToDb(event))
        .select()
        .single();
    
    await _logEvent('school', 'event_created', response);
    return SchoolEvent.fromJson(_mapSchoolEventFromDb(response));
  }

  @override
  Future<SchoolEvent> updateSchoolEvent(SchoolEvent event) async {
    final response = await _client
        .from('school_events')
        .update(_mapSchoolEventToDb(event))
        .eq('id', event.id)
        .select()
        .single();
    
    return SchoolEvent.fromJson(_mapSchoolEventFromDb(response));
  }

  @override
  Future<void> deleteSchoolEvent(String eventId) async {
    await _client.from('school_events').delete().eq('id', eventId);
    await _logEvent('school', 'event_deleted', {'id': eventId});
  }

  // --- HOMEWORK ---
  
  @override
  Future<List<Homework>> getHomework(String userId) async {
    final response = await _client
        .from('homework')
        .select()
        .eq('user_id', userId)
        .order('due_date');
    
    return (response as List).map((json) => Homework.fromJson(_mapHomeworkFromDb(json))).toList();
  }

  @override
  Future<List<Homework>> getPendingHomework(String userId) async {
    final response = await _client
        .from('homework')
        .select()
        .eq('user_id', userId)
        .neq('status', 'done')
        .order('due_date');
    
    return (response as List).map((json) => Homework.fromJson(_mapHomeworkFromDb(json))).toList();
  }

  @override
  Future<List<Homework>> getHomeworkForSubject(String userId, String subjectId) async {
    final response = await _client
        .from('homework')
        .select()
        .eq('user_id', userId)
        .eq('subject_id', subjectId)
        .order('due_date');
    
    return (response as List).map((json) => Homework.fromJson(_mapHomeworkFromDb(json))).toList();
  }

  @override
  Future<Homework> addHomework(Homework homework) async {
    final response = await _client
        .from('homework')
        .insert(_mapHomeworkToDb(homework))
        .select()
        .single();
    
    await _logEvent('school', 'homework_created', response);
    return Homework.fromJson(_mapHomeworkFromDb(response));
  }

  @override
  Future<Homework> updateHomework(Homework homework) async {
    final response = await _client
        .from('homework')
        .update(_mapHomeworkToDb(homework))
        .eq('id', homework.id)
        .select()
        .single();
    
    if (homework.status == HomeworkStatus.done) {
      await _logEvent('school', 'homework_completed', response);
    }
    
    return Homework.fromJson(_mapHomeworkFromDb(response));
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    await _client.from('homework').delete().eq('id', homeworkId);
  }

  // --- NOTES ---
  
  @override
  Future<List<SchoolNote>> getNotes(String userId) async {
    final response = await _client
        .from('school_notes')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    
    return (response as List).map((json) => SchoolNote.fromJson(_mapNoteFromDb(json))).toList();
  }

  @override
  Future<List<SchoolNote>> getNotesForSubject(String userId, String subjectId) async {
    final response = await _client
        .from('school_notes')
        .select()
        .eq('user_id', userId)
        .eq('subject_id', subjectId)
        .order('updated_at', ascending: false);
    
    return (response as List).map((json) => SchoolNote.fromJson(_mapNoteFromDb(json))).toList();
  }

  @override
  Future<SchoolNote> addNote(SchoolNote note) async {
    final response = await _client
        .from('school_notes')
        .insert(_mapNoteToDb(note))
        .select()
        .single();
    
    return SchoolNote.fromJson(_mapNoteFromDb(response));
  }

  @override
  Future<SchoolNote> updateNote(SchoolNote note) async {
    final response = await _client
        .from('school_notes')
        .update(_mapNoteToDb(note))
        .eq('id', note.id)
        .select()
        .single();
    
    return SchoolNote.fromJson(_mapNoteFromDb(response));
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _client.from('school_notes').delete().eq('id', noteId);
  }

  // --- GRADE CALCULATOR CONFIG ---
  
  @override
  Future<GradeCalculatorConfig?> getGradeCalculatorConfig(String userId, {String? subjectId}) async {
    var query = _client
        .from('grade_calculator_config')
        .select()
        .eq('user_id', userId);
    
    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    } else {
      query = query.isFilter('subject_id', null);
    }
    
    final response = await query.maybeSingle();
    if (response == null) return null;
    
    return GradeCalculatorConfig.fromJson(response);
  }

  @override
  Future<GradeCalculatorConfig> upsertGradeCalculatorConfig(GradeCalculatorConfig config) async {
    final response = await _client
        .from('grade_calculator_config')
        .upsert(config.toJson())
        .select()
        .single();
    
    return GradeCalculatorConfig.fromJson(response);
  }

  // --- SUBJECT PROFILE ---
  
  @override
  Future<SubjectProfile> getSubjectProfile(String userId, String subjectId) async {
    // Fetch all related data
    final subjects = await getSubjects(userId);
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    
    final grades = await getGradesForSubject(userId, subjectId);
    final studySessions = await getStudySessionsForSubject(userId, subjectId);
    final events = await getEventsForSubject(userId, subjectId);
    final homework = await getHomeworkForSubject(userId, subjectId);
    final notes = await getNotesForSubject(userId, subjectId);
    
    return SubjectProfile(
      subject: subject,
      grades: grades,
      studySessions: studySessions,
      upcomingEvents: events,
      pendingHomework: homework,
      notes: notes,
    );
  }

  // Helper for event logging
  Future<void> _logEvent(String widget, String eventType, Map<String, dynamic> payload) async {
    await _dataService.logEvent(
      widgetName: widget,
      eventType: eventType,
      payload: payload,
      referenceId: payload['id']?.toString(),
    );
  }

  // Mapping helpers
  Map<String, dynamic> _mapSubjectFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'user_id': db['user_id'],
      'name': db['name'],
      'short_name': db['short_name'],
      'color_value': db['color_value'],
      'fun_factor': db['fun_factor'],
      'active': db['is_active'],
      'created_at': db['created_at'],
      'updated_at': db['updated_at'],
    };
  }

  Map<String, dynamic> _mapSubjectToDb(Subject subject) {
    return {
      if (subject.id.isNotEmpty) 'id': subject.id,
      'user_id': subject.userId,
      'name': subject.name,
      'short_name': subject.shortName,
      'color_value': subject.colorValue,
      'fun_factor': subject.funFactor,
      'is_active': subject.active,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapTimetableFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'user_id': db['user_id'],
      'subject_id': db['subject_id'],
      'weekday': Weekday.values[db['weekday'] - 1].name,
      'period': db['lesson_number'],
      'start_time': db['start_time'],
      'end_time': db['end_time'],
      'room': db['room'],
      'teacher': db['teacher'],
      'created_at': db['created_at'],
      'updated_at': db['updated_at'],
    };
  }

  Map<String, dynamic> _mapTimetableToDb(TimetableEntry entry) {
    return {
      if (entry.id.isNotEmpty) 'id': entry.id,
      'user_id': entry.userId,
      'subject_id': entry.subjectId,
      'weekday': entry.weekday.index + 1,
      'lesson_number': entry.lessonNumber,
      'start_time': entry.startTime,
      'end_time': entry.endTime,
      'room': entry.room,
      'teacher': entry.teacher,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapGradeFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'user_id': db['user_id'],
      'subject_id': db['subject_id'],
      'points': db['points'] as int? ?? (db['value'] as num?)?.toInt() ?? 0,
      'weight': (db['weight'] as num?)?.toDouble() ?? 1.0,
      'type': db['type'],
      'date': db['date'],
      'description': db['description'] ?? db['note'],
      'created_at': db['created_at'],
      'updated_at': db['updated_at'],
    };
  }

  Map<String, dynamic> _mapGradeToDb(Grade grade) {
    return {
      if (grade.id.isNotEmpty) 'id': grade.id,
      'user_id': grade.userId,
      'subject_id': grade.subjectId,
      'points': grade.points,
      'weight': grade.weight,
      'type': grade.type.name,
      'date': grade.date.toIso8601String().split('T')[0],
      'description': grade.description,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapStudySessionFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'user_id': db['user_id'],
      'subject_id': db['subject_id'],
      'start_time': db['start_time'],
      'end_time': db['end_time'],
      'duration_minutes': db['duration_minutes'],
      'is_timer_based': db['is_timer_based'],
      'notes': db['notes'],
      'created_at': db['created_at'],
      'updated_at': db['updated_at'],
    };
  }

  Map<String, dynamic> _mapStudySessionToDb(StudySession session) {
    return {
      if (session.id.isNotEmpty) 'id': session.id,
      'user_id': session.userId,
      'subject_id': session.subjectId,
      'start_time': session.startTime.toIso8601String(),
      'end_time': session.endTime?.toIso8601String(),
      'duration_minutes': session.durationMinutes,
      'is_timer_based': session.isTimerBased,
      'notes': session.notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapSchoolEventFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'user_id': db['user_id'],
      'subject_id': db['subject_id'],
      'title': db['title'],
      'type': db['type'],
      'date': db['date'],
      'time': db['time'],
      'description': db['description'],
      'reminder': db['reminder'],
      'created_at': db['created_at'],
      'updated_at': db['updated_at'],
    };
  }

  Map<String, dynamic> _mapSchoolEventToDb(SchoolEvent event) {
    return {
      if (event.id.isNotEmpty) 'id': event.id,
      'user_id': event.userId,
      'subject_id': event.subjectId,
      'title': event.title,
      'type': event.type.name,
      'date': event.date.toIso8601String().split('T')[0],
      'time': event.time,
      'description': event.description,
      'reminder': event.reminder,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapHomeworkFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'user_id': db['user_id'],
      'subject_id': db['subject_id'],
      'title': db['title'],
      'description': db['description'],
      'due_date': db['due_date'],
      'status': db['status'],
      'created_at': db['created_at'],
      'updated_at': db['updated_at'],
    };
  }

  Map<String, dynamic> _mapHomeworkToDb(Homework homework) {
    return {
      if (homework.id.isNotEmpty) 'id': homework.id,
      'user_id': homework.userId,
      'subject_id': homework.subjectId,
      'title': homework.title,
      'description': homework.description,
      'due_date': homework.dueDate.toIso8601String().split('T')[0],
      'status': homework.status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mapNoteFromDb(Map<String, dynamic> db) {
    return {
      'id': db['id'],
      'user_id': db['user_id'],
      'subject_id': db['subject_id'],
      'title': db['title'],
      'content': db['content'],
      'is_pinned': db['is_pinned'],
      'color': db['color'],
      'created_at': db['created_at'],
      'updated_at': db['updated_at'],
    };
  }

  Map<String, dynamic> _mapNoteToDb(SchoolNote note) {
    return {
      if (note.id.isNotEmpty) 'id': note.id,
      'user_id': note.userId,
      'subject_id': note.subjectId,
      'title': note.title,
      'content': note.content,
      'is_pinned': note.isPinned,
      'color': note.color,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// ============================================================================
// SPORT REPOSITORY - SUPABASE
// ============================================================================

class SupabaseSportRepository implements SportRepository {
  final SupabaseClient _client;
  final SupabaseDataService _dataService = SupabaseDataService.instance;

  SupabaseSportRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // --- SPORT TYPES ---
  
  @override
  Future<List<SportType>> getSportTypes(String userId) async {
    final response = await _client
        .from('sport_types')
        .select()
        .eq('user_id', userId)
        .order('name');
    
    return (response as List).map((json) => SportType.fromJson(json)).toList();
  }

  @override
  Future<SportType> addSportType(SportType type) async {
    final response = await _client
        .from('sport_types')
        .insert(type.toJson())
        .select()
        .single();
    
    return SportType.fromJson(response);
  }

  @override
  Future<SportType> updateSportType(SportType type) async {
    final response = await _client
        .from('sport_types')
        .update(type.toJson())
        .eq('id', type.id)
        .select()
        .single();
    
    return SportType.fromJson(response);
  }

  @override
  Future<void> deleteSportType(String typeId) async {
    await _client.from('sport_types').delete().eq('id', typeId);
  }

  // --- SPORT SESSIONS ---
  
  @override
  Future<List<SportSession>> getSportSessions(String userId) async {
    final response = await _client
        .from('sport_sessions')
        .select('*, sport_types(name)')
        .eq('user_id', userId)
        .order('date', ascending: false);
    
    return (response as List).map((json) => SportSession.fromJson(json)).toList();
  }

  @override
  Future<SportSession> addSportSession(SportSession session) async {
    final response = await _client
        .from('sport_sessions')
        .insert(session.toJson())
        .select('*, sport_types(name)')
        .single();
    
    await _dataService.logEvent(
      widgetName: 'sport',
      eventType: 'sport_session_completed',
      payload: response,
      referenceId: response['id'],
    );
    
    return SportSession.fromJson(response);
  }

  @override
  Future<SportSession> updateSportSession(SportSession session) async {
    final response = await _client
        .from('sport_sessions')
        .update(session.toJson())
        .eq('id', session.id)
        .select('*, sport_types(name)')
        .single();
    
    return SportSession.fromJson(response);
  }

  @override
  Future<void> deleteSportSession(String sessionId) async {
    await _client.from('sport_sessions').delete().eq('id', sessionId);
  }

  // --- WEIGHT ENTRIES ---
  
  @override
  Future<List<WeightEntry>> getWeightEntries(String userId) async {
    final response = await _client
        .from('weight_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    
    return (response as List).map((json) => WeightEntry.fromJson(json)).toList();
  }

  @override
  Future<WeightEntry?> getLatestWeight(String userId) async {
    final response = await _client
        .from('weight_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (response == null) return null;
    return WeightEntry.fromJson(response);
  }

  @override
  Future<WeightEntry> addWeightEntry(WeightEntry entry) async {
    final response = await _client
        .from('weight_entries')
        .insert(entry.toJson())
        .select()
        .single();
    
    await _dataService.logEvent(
      widgetName: 'sport',
      eventType: 'weight_logged',
      payload: response,
      referenceId: response['id'],
    );
    
    return WeightEntry.fromJson(response);
  }

  @override
  Future<WeightEntry> updateWeightEntry(WeightEntry entry) async {
    final response = await _client
        .from('weight_entries')
        .update(entry.toJson())
        .eq('id', entry.id)
        .select()
        .single();
    
    return WeightEntry.fromJson(response);
  }

  @override
  Future<void> deleteWeightEntry(String entryId) async {
    await _client.from('weight_entries').delete().eq('id', entryId);
  }
}

// ============================================================================
// SKIN REPOSITORY - SUPABASE
// ============================================================================

class SupabaseSkinRepository implements SkinRepository {
  final SupabaseClient _client;
  final SupabaseDataService _dataService = SupabaseDataService.instance;

  SupabaseSkinRepository(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // --- SKIN ENTRIES ---
  
  @override
  Future<List<SkinEntry>> getSkinEntries(String userId) async {
    final response = await _client
        .from('skin_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    
    return (response as List).map((json) => SkinEntry.fromJson(json)).toList();
  }

  @override
  Future<SkinEntry?> getSkinEntryForDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('skin_entries')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();
    
    if (response == null) return null;
    return SkinEntry.fromJson(response);
  }

  @override
  Future<SkinEntry> upsertSkinEntry(SkinEntry entry) async {
    final response = await _client
        .from('skin_entries')
        .upsert(entry.toJson(), onConflict: 'user_id,date')
        .select()
        .single();
    
    await _dataService.logEvent(
      widgetName: 'skin',
      eventType: 'skin_entry_logged',
      payload: response,
      referenceId: response['id'],
    );
    
    return SkinEntry.fromJson(response);
  }

  @override
  Future<void> deleteSkinEntry(String entryId) async {
    await _client.from('skin_entries').delete().eq('id', entryId);
  }

  // --- SKIN CARE STEPS ---
  
  @override
  Future<List<SkinCareStep>> getSkinCareSteps(String userId) async {
    final response = await _client
        .from('skin_care_steps')
        .select()
        .eq('user_id', userId)
        .order('sort_order');
    
    return (response as List).map((json) => SkinCareStep.fromJson(json)).toList();
  }

  @override
  Future<SkinCareStep> addSkinCareStep(SkinCareStep step) async {
    final response = await _client
        .from('skin_care_steps')
        .insert(step.toJson())
        .select()
        .single();
    
    return SkinCareStep.fromJson(response);
  }

  @override
  Future<SkinCareStep> updateSkinCareStep(SkinCareStep step) async {
    final response = await _client
        .from('skin_care_steps')
        .update(step.toJson())
        .eq('id', step.id)
        .select()
        .single();
    
    return SkinCareStep.fromJson(response);
  }

  @override
  Future<void> deleteSkinCareStep(String stepId) async {
    await _client.from('skin_care_steps').delete().eq('id', stepId);
  }

  // --- SKIN CARE COMPLETIONS ---
  
  @override
  Future<List<SkinCareCompletion>> getCompletionsForDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('skin_care_completions')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr);
    
    return (response as List).map((json) => SkinCareCompletion.fromJson(json)).toList();
  }

  @override
  Future<SkinCareCompletion> addCompletion(SkinCareCompletion completion) async {
    final response = await _client
        .from('skin_care_completions')
        .insert(completion.toJson())
        .select()
        .single();
    
    await _dataService.logEvent(
      widgetName: 'skin',
      eventType: 'skin_care_step_completed',
      payload: response,
      referenceId: completion.stepId,
    );
    
    return SkinCareCompletion.fromJson(response);
  }

  @override
  Future<void> deleteCompletion(String completionId) async {
    await _client.from('skin_care_completions').delete().eq('id', completionId);
  }

  // --- SKIN PRODUCTS ---
  
  @override
  Future<List<SkinProduct>> getSkinProducts(String userId) async {
    final response = await _client
        .from('skin_products')
        .select()
        .eq('user_id', userId)
        .order('name');
    
    return (response as List).map((json) => SkinProduct.fromJson(json)).toList();
  }

  @override
  Future<SkinProduct> addSkinProduct(SkinProduct product) async {
    final response = await _client
        .from('skin_products')
        .insert(product.toJson())
        .select()
        .single();
    
    return SkinProduct.fromJson(response);
  }

  @override
  Future<SkinProduct> updateSkinProduct(SkinProduct product) async {
    final response = await _client
        .from('skin_products')
        .update(product.toJson())
        .eq('id', product.id)
        .select()
        .single();
    
    return SkinProduct.fromJson(response);
  }

  @override
  Future<void> deleteSkinProduct(String productId) async {
    await _client.from('skin_products').delete().eq('id', productId);
  }

  // --- SKIN NOTES ---
  
  @override
  Future<List<SkinNote>> getSkinNotes(String userId) async {
    final response = await _client
        .from('skin_notes')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    
    return (response as List).map((json) => SkinNote.fromJson(json)).toList();
  }

  @override
  Future<SkinNote> addSkinNote(SkinNote note) async {
    final response = await _client
        .from('skin_notes')
        .insert(note.toJson())
        .select()
        .single();
    
    return SkinNote.fromJson(response);
  }

  @override
  Future<void> deleteSkinNote(String noteId) async {
    await _client.from('skin_notes').delete().eq('id', noteId);
  }

  // --- SKIN PHOTOS ---
  
  @override
  Future<List<SkinPhoto>> getSkinPhotos(String userId) async {
    final response = await _client
        .from('skin_photos')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    
    return (response as List).map((json) => SkinPhoto.fromJson(json)).toList();
  }

  @override
  Future<SkinPhoto> addSkinPhoto(SkinPhoto photo) async {
    final response = await _client
        .from('skin_photos')
        .insert(photo.toJson())
        .select()
        .single();
    
    return SkinPhoto.fromJson(response);
  }

  @override
  Future<void> deleteSkinPhoto(String photoId) async {
    await _client.from('skin_photos').delete().eq('id', photoId);
  }
}
