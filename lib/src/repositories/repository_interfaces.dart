/// Abstract Repository Interfaces
/// These define the contract for data access, implemented by both
/// demo (in-memory) and production (Supabase) implementations

import '../models/models.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String? displayName);
  Future<void> signOut();
  Stream<UserModel?> authStateChanges();
}

abstract class SettingsRepository {
  Future<SettingsModel?> getSettings(String userId);
  Future<SettingsModel> updateSettings(SettingsModel settings);
}

abstract class TodoRepository {
  Future<List<TodoModel>> getTodos(String userId);
  Future<TodoModel> createTodo(TodoModel todo);
  Future<TodoModel> updateTodo(TodoModel todo);
  Future<void> deleteTodo(String todoId);
  Future<List<TodoOccurrence>> getOccurrences(String todoId);
  Future<List<TodoOccurrence>> getOccurrencesForDate(String userId, DateTime date);
  Future<TodoOccurrence> toggleOccurrence(String occurrenceId, bool done);
}

abstract class FoodRepository {
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> getProductByBarcode(String barcode);
  Future<ProductModel> addProduct(ProductModel product);
  Future<List<FoodLogModel>> getFoodLogs(String userId, DateTime date);
  Future<List<FoodLogModel>> getFoodLogsRange(String userId, DateTime start, DateTime end);
  Future<FoodLogModel> addFoodLog(FoodLogModel log);
  Future<void> deleteFoodLog(String logId);
}

abstract class WaterRepository {
  Future<List<WaterLogModel>> getWaterLogs(String userId, DateTime date);
  Future<int> getTotalWater(String userId, DateTime date);
  Future<WaterLogModel> addWaterLog(WaterLogModel log);
  Future<void> deleteWaterLog(String logId);
}

abstract class StepsRepository {
  Future<StepsLogModel?> getSteps(String userId, DateTime date);
  Future<List<StepsLogModel>> getStepsRange(String userId, DateTime start, DateTime end);
  Future<StepsLogModel> upsertSteps(StepsLogModel log);
}

abstract class SleepRepository {
  Future<SleepLogModel?> getSleep(String userId, DateTime date);
  Future<List<SleepLogModel>> getSleepRange(String userId, DateTime start, DateTime end);
  Future<SleepLogModel> addSleep(SleepLogModel log);
  Future<void> deleteSleep(String logId);
}

abstract class MoodRepository {
  Future<MoodLogModel?> getMood(String userId, DateTime date);
  Future<List<MoodLogModel>> getMoodRange(String userId, DateTime start, DateTime end);
  Future<MoodLogModel> upsertMood(MoodLogModel log);
}

abstract class BookRepository {
  Future<List<BookModel>> getBooks(String userId);
  Future<List<BookModel>> getBooksByStatus(String userId, BookStatus status);
  Future<BookModel> addBook(BookModel book);
  Future<BookModel> updateBook(BookModel book);
  Future<void> deleteBook(String bookId);
  Future<ReadingGoalModel?> getReadingGoal(String userId);
  Future<ReadingGoalModel> upsertReadingGoal(ReadingGoalModel goal);
  Future<void> addReadingSession(String oderId, ReadingSession session);
}

// ============================================================================
// SCHOOL REPOSITORY
// ============================================================================

abstract class SchoolRepository {
  // Fächer (Subjects)
  Future<List<Subject>> getSubjects(String userId);
  Future<Subject> addSubject(Subject subject);
  Future<Subject> updateSubject(Subject subject);
  Future<void> deleteSubject(String subjectId);
  
  // Stundenplan (Timetable)
  Future<List<TimetableEntry>> getTimetable(String userId);
  Future<List<TimetableEntry>> getTimetableForDay(String userId, Weekday weekday);
  Future<TimetableEntry> addTimetableEntry(TimetableEntry entry);
  Future<TimetableEntry> updateTimetableEntry(TimetableEntry entry);
  Future<void> deleteTimetableEntry(String entryId);
  
  // Noten (Grades)
  Future<List<Grade>> getGrades(String userId);
  Future<List<Grade>> getGradesForSubject(String userId, String subjectId);
  Future<Grade> addGrade(Grade grade);
  Future<Grade> updateGrade(Grade grade);
  Future<void> deleteGrade(String gradeId);
  
  // Lernzeit (Study Sessions)
  Future<List<StudySession>> getStudySessions(String userId);
  Future<List<StudySession>> getStudySessionsForSubject(String userId, String subjectId);
  Future<List<StudySession>> getStudySessionsRange(String userId, DateTime start, DateTime end);
  Future<StudySession> addStudySession(StudySession session);
  Future<StudySession> updateStudySession(StudySession session);
  Future<void> deleteStudySession(String sessionId);
  
  // Schultermine (School Events)
  Future<List<SchoolEvent>> getSchoolEvents(String userId);
  Future<List<SchoolEvent>> getUpcomingEvents(String userId, {int days = 14});
  Future<List<SchoolEvent>> getEventsForSubject(String userId, String subjectId);
  Future<SchoolEvent> addSchoolEvent(SchoolEvent event);
  Future<SchoolEvent> updateSchoolEvent(SchoolEvent event);
  Future<void> deleteSchoolEvent(String eventId);
  
  // Hausaufgaben (Homework)
  Future<List<Homework>> getHomework(String userId);
  Future<List<Homework>> getPendingHomework(String userId);
  Future<List<Homework>> getHomeworkForSubject(String userId, String subjectId);
  Future<Homework> addHomework(Homework homework);
  Future<Homework> updateHomework(Homework homework);
  Future<void> deleteHomework(String homeworkId);
  
  // Notizen (Notes)
  Future<List<SchoolNote>> getNotes(String userId);
  Future<List<SchoolNote>> getNotesForSubject(String userId, String subjectId);
  Future<SchoolNote> addNote(SchoolNote note);
  Future<SchoolNote> updateNote(SchoolNote note);
  Future<void> deleteNote(String noteId);
  
  // Notenrechner Konfiguration
  Future<GradeCalculatorConfig?> getGradeCalculatorConfig(String userId, {String? subjectId});
  Future<GradeCalculatorConfig> upsertGradeCalculatorConfig(GradeCalculatorConfig config);
  
  // Aggregierte Daten
  Future<SubjectProfile> getSubjectProfile(String userId, String subjectId);
}

// ============================================================================
// SPORT REPOSITORY
// ============================================================================

abstract class SportRepository {
  // Sportarten
  Future<List<SportType>> getSportTypes(String userId);
  Future<SportType> addSportType(SportType type);
  Future<SportType> updateSportType(SportType type);
  Future<void> deleteSportType(String typeId);
  
  // Workout Sessions (legacy - mit SportType ID Referenz)
  Future<List<WorkoutSession>> getWorkoutSessions(String userId);
  Future<List<WorkoutSession>> getWorkoutSessionsForDate(String userId, DateTime date);
  Future<List<WorkoutSession>> getWorkoutSessionsRange(String userId, DateTime start, DateTime end);
  Future<WorkoutSession> addWorkoutSession(WorkoutSession session);
  Future<WorkoutSession> updateWorkoutSession(WorkoutSession session);
  Future<void> deleteWorkoutSession(String sessionId);
  
  // Sport Sessions (simplified - mit direktem Sportart-String)
  Future<List<SportSession>> getSportSessions(String userId);
  Future<SportSession> addSportSession(SportSession session);
  Future<SportSession> updateSportSession(SportSession session);
  Future<void> deleteSportSession(String sessionId);
  
  // Gewicht
  Future<List<WeightEntry>> getWeightEntries(String userId);
  Future<WeightEntry?> getLatestWeight(String userId);
  Future<WeightEntry> addWeightEntry(WeightEntry entry);
  Future<WeightEntry> updateWeightEntry(WeightEntry entry);
  Future<void> deleteWeightEntry(String entryId);
}

// ============================================================================
// SKIN REPOSITORY
// ============================================================================

abstract class SkinRepository {
  // Tägliche Einträge
  Future<List<SkinEntry>> getSkinEntries(String userId);
  Future<SkinEntry?> getSkinEntryForDate(String userId, DateTime date);
  Future<SkinEntry> upsertSkinEntry(SkinEntry entry);
  Future<void> deleteSkinEntry(String entryId);
  
  // Pflegeroutine
  Future<List<SkinCareStep>> getSkinCareSteps(String userId);
  Future<SkinCareStep> addSkinCareStep(SkinCareStep step);
  Future<SkinCareStep> updateSkinCareStep(SkinCareStep step);
  Future<void> deleteSkinCareStep(String stepId);
  
  // Pflegeroutine Abhaken
  Future<List<SkinCareCompletion>> getCompletionsForDate(String userId, DateTime date);
  Future<SkinCareCompletion> addCompletion(SkinCareCompletion completion);
  Future<void> deleteCompletion(String completionId);
  
  // Produkte
  Future<List<SkinProduct>> getSkinProducts(String userId);
  Future<SkinProduct> addSkinProduct(SkinProduct product);
  Future<SkinProduct> updateSkinProduct(SkinProduct product);
  Future<void> deleteSkinProduct(String productId);
  
  // Notizen
  Future<List<SkinNote>> getSkinNotes(String userId);
  Future<SkinNote> addSkinNote(SkinNote note);
  Future<void> deleteSkinNote(String noteId);
  
  // Fotos
  Future<List<SkinPhoto>> getSkinPhotos(String userId);
  Future<SkinPhoto> addSkinPhoto(SkinPhoto photo);
  Future<void> deleteSkinPhoto(String photoId);
}
