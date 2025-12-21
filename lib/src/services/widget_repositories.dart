/// Widget Repositories
/// 
/// Konkrete Supabase Repositories für alle Widgets.
/// Alle Repositories erben von EventCaptureRepository für automatisches Event-Logging.
library;

import 'event_capture_mixin.dart';
import 'supabase_data_service.dart';
import '../models/models.dart';

// ============================================================================
// BOOKS REPOSITORY
// ============================================================================

class BooksRepository extends EventCaptureRepository {
  BooksRepository() : super(widgetName: 'books', tableName: 'books');

  Future<List<BookModel>> getAllBooks() async {
    final data = await getAll(orderBy: 'updated_at');
    return data.map((json) => BookModel.fromJson(json)).toList();
  }

  Future<List<BookModel>> getBooksByStatus(BookStatus status) async {
    final data = await getAll(
      orderBy: 'updated_at',
      filters: {'status': status.name},
    );
    return data.map((json) => BookModel.fromJson(json)).toList();
  }

  Future<BookModel?> saveBook(BookModel book) async {
    final result = await save(book.toJson());
    if (result != null) {
      return BookModel.fromJson(result);
    }
    return null;
  }
}

// ============================================================================
// SCHOOL REPOSITORY
// ============================================================================

class SchoolRepository extends EventCaptureRepository {
  SchoolRepository() : super(widgetName: 'school', tableName: 'subjects');

  // --- SUBJECTS ---
  Future<List<Subject>> getSubjects() async {
    final data = await getAll(orderBy: 'name', ascending: true);
    return data.map((json) => Subject.fromJson(json)).toList();
  }

  Future<Subject?> saveSubject(Subject subject) async {
    final result = await save(subject.toJson());
    if (result != null) {
      return Subject.fromJson(result);
    }
    return null;
  }

  // --- GRADES ---
  Future<List<Grade>> getGrades({String? subjectId}) async {
    final data = await dataService.getAll(
      'grades',
      orderBy: 'date',
      filters: subjectId != null ? {'subject_id': subjectId} : null,
    );
    return data.map((json) => Grade.fromJson(json)).toList();
  }

  Future<Grade?> saveGrade(Grade grade) async {
    final exists = grade.id.isNotEmpty && await dataService.getById('grades', grade.id) != null;
    Map<String, dynamic>? result;
    if (exists) {
      result = await dataService.update('grades', grade.id, grade.toJson());
      if (result != null) await logUpdated(result);
    } else {
      result = await dataService.insert('grades', grade.toJson());
      if (result != null) await logCreated(result);
    }
    if (result != null) {
      return Grade.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteGrade(String id) async {
    final result = await dataService.delete('grades', id);
    if (result) await logDeleted(id, metadata: {'type': 'grade'});
    return result;
  }

  // --- TIMETABLE ---
  Future<List<TimetableEntry>> getTimetable() async {
    final data = await dataService.getAll(
      'timetable_entries',
      orderBy: 'period',
      ascending: true,
    );
    return data.map((json) => TimetableEntry.fromJson(json)).toList();
  }

  Future<TimetableEntry?> saveTimetableEntry(TimetableEntry entry) async {
    Map<String, dynamic>? result;
    final exists = entry.id.isNotEmpty && await dataService.getById('timetable_entries', entry.id) != null;
    if (exists) {
      result = await dataService.update('timetable_entries', entry.id, entry.toJson());
    } else {
      result = await dataService.insert('timetable_entries', entry.toJson());
    }
    if (result != null) {
      return TimetableEntry.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteTimetableEntry(String id) async {
    return dataService.delete('timetable_entries', id);
  }

  // --- HOMEWORK ---
  Future<List<Homework>> getHomework({HomeworkStatus? status}) async {
    final data = await dataService.getAll(
      'homework',
      orderBy: 'due_date',
      ascending: true,
      filters: status != null ? {'status': status.name} : null,
    );
    return data.map((json) => Homework.fromJson(json)).toList();
  }

  Future<Homework?> saveHomework(Homework homework) async {
    Map<String, dynamic>? result;
    final exists = homework.id.isNotEmpty && await dataService.getById('homework', homework.id) != null;
    if (exists) {
      result = await dataService.update('homework', homework.id, homework.toJson());
      if (result != null) await logUpdated(result);
    } else {
      result = await dataService.insert('homework', homework.toJson());
      if (result != null) await logCreated(result);
    }
    if (result != null) {
      return Homework.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteHomework(String id) async {
    final result = await dataService.delete('homework', id);
    if (result) await logDeleted(id, metadata: {'type': 'homework'});
    return result;
  }

  // --- STUDY SESSIONS ---
  Future<List<StudySession>> getStudySessions() async {
    final data = await dataService.getAll(
      'study_sessions',
      orderBy: 'start_time',
    );
    return data.map((json) => StudySession.fromJson(json)).toList();
  }

  Future<StudySession?> saveStudySession(StudySession session) async {
    Map<String, dynamic>? result;
    final exists = session.id.isNotEmpty && await dataService.getById('study_sessions', session.id) != null;
    if (exists) {
      result = await dataService.update('study_sessions', session.id, session.toJson());
    } else {
      result = await dataService.insert('study_sessions', session.toJson());
      if (result != null) await logCreated(result);
    }
    if (result != null) {
      return StudySession.fromJson(result);
    }
    return null;
  }

  // --- SCHOOL NOTES ---
  Future<List<SchoolNote>> getSchoolNotes() async {
    final data = await dataService.getAll(
      'school_notes',
      orderBy: 'updated_at',
    );
    return data.map((json) => SchoolNote.fromJson(json)).toList();
  }

  Future<SchoolNote?> saveSchoolNote(SchoolNote note) async {
    Map<String, dynamic>? result;
    final exists = note.id.isNotEmpty && await dataService.getById('school_notes', note.id) != null;
    if (exists) {
      result = await dataService.update('school_notes', note.id, note.toJson());
    } else {
      result = await dataService.insert('school_notes', note.toJson());
    }
    if (result != null) {
      return SchoolNote.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteSchoolNote(String id) async {
    return dataService.delete('school_notes', id);
  }

  // --- SCHOOL EVENTS ---
  Future<List<SchoolEvent>> getSchoolEvents() async {
    final data = await dataService.getAll(
      'school_events',
      orderBy: 'date',
      ascending: true,
    );
    return data.map((json) => SchoolEvent.fromJson(json)).toList();
  }

  Future<SchoolEvent?> saveSchoolEvent(SchoolEvent event) async {
    Map<String, dynamic>? result;
    final exists = event.id.isNotEmpty && await dataService.getById('school_events', event.id) != null;
    if (exists) {
      result = await dataService.update('school_events', event.id, event.toJson());
    } else {
      result = await dataService.insert('school_events', event.toJson());
      if (result != null) await logCreated(result);
    }
    if (result != null) {
      return SchoolEvent.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteSchoolEvent(String id) async {
    final result = await dataService.delete('school_events', id);
    if (result) await logDeleted(id, metadata: {'type': 'school_event'});
    return result;
  }
}

// ============================================================================
// SPORT REPOSITORY
// ============================================================================

class SportRepository extends EventCaptureRepository {
  SportRepository() : super(widgetName: 'sport', tableName: 'sport_types');

  // --- SPORT TYPES ---
  Future<List<SportType>> getSportTypes() async {
    final data = await getAll(orderBy: 'name', ascending: true);
    return data.map((json) => SportType.fromJson(json)).toList();
  }

  Future<SportType?> saveSportType(SportType sportType) async {
    final result = await save(sportType.toJson());
    if (result != null) {
      return SportType.fromJson(result);
    }
    return null;
  }

  // --- WORKOUT SESSIONS ---
  Future<List<WorkoutSession>> getWorkoutSessions() async {
    final data = await dataService.getAll(
      'workout_sessions',
      orderBy: 'date',
    );
    return data.map((json) => WorkoutSession.fromJson(json)).toList();
  }

  Future<WorkoutSession?> saveWorkoutSession(WorkoutSession session) async {
    Map<String, dynamic>? result;
    final exists = session.id.isNotEmpty && await dataService.getById('workout_sessions', session.id) != null;
    if (exists) {
      result = await dataService.update('workout_sessions', session.id, session.toJson());
      if (result != null) await logUpdated(result);
    } else {
      result = await dataService.insert('workout_sessions', session.toJson());
      if (result != null) await logCreated(result);
    }
    if (result != null) {
      return WorkoutSession.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteWorkoutSession(String id) async {
    final result = await dataService.delete('workout_sessions', id);
    if (result) await logDeleted(id, metadata: {'type': 'workout_session'});
    return result;
  }

  // --- WEIGHT ENTRIES ---
  Future<List<WeightEntry>> getWeightEntries() async {
    final data = await dataService.getAll(
      'weight_entries',
      orderBy: 'date',
    );
    return data.map((json) => WeightEntry.fromJson(json)).toList();
  }

  Future<WeightEntry?> saveWeightEntry(WeightEntry entry) async {
    Map<String, dynamic>? result;
    final exists = entry.id.isNotEmpty && await dataService.getById('weight_entries', entry.id) != null;
    if (exists) {
      result = await dataService.update('weight_entries', entry.id, entry.toJson());
    } else {
      result = await dataService.insert('weight_entries', entry.toJson());
      if (result != null) await logCreated(result);
    }
    if (result != null) {
      return WeightEntry.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteWeightEntry(String id) async {
    return dataService.delete('weight_entries', id);
  }
}

// ============================================================================
// SKIN REPOSITORY
// ============================================================================

class SkinRepository extends EventCaptureRepository {
  SkinRepository() : super(widgetName: 'skin', tableName: 'skin_entries');

  // --- SKIN ENTRIES ---
  Future<List<SkinEntry>> getSkinEntries() async {
    final data = await getAll(orderBy: 'date');
    return data.map((json) => SkinEntry.fromJson(json)).toList();
  }

  Future<SkinEntry?> saveSkinEntry(SkinEntry entry) async {
    final result = await save(entry.toJson());
    if (result != null) {
      return SkinEntry.fromJson(result);
    }
    return null;
  }

  // --- SKIN CARE STEPS ---
  Future<List<SkinCareStep>> getSkinCareSteps() async {
    final data = await dataService.getAll(
      'skin_care_steps',
      orderBy: 'sort_order',
      ascending: true,
    );
    return data.map((json) => SkinCareStep.fromJson(json)).toList();
  }

  Future<SkinCareStep?> saveSkinCareStep(SkinCareStep step) async {
    Map<String, dynamic>? result;
    final exists = step.id.isNotEmpty && await dataService.getById('skin_care_steps', step.id) != null;
    if (exists) {
      result = await dataService.update('skin_care_steps', step.id, step.toJson());
    } else {
      result = await dataService.insert('skin_care_steps', step.toJson());
    }
    if (result != null) {
      return SkinCareStep.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteSkinCareStep(String id) async {
    return dataService.delete('skin_care_steps', id);
  }

  // --- SKIN PRODUCTS ---
  Future<List<SkinProduct>> getSkinProducts() async {
    final data = await dataService.getAll(
      'skin_products',
      orderBy: 'name',
      ascending: true,
    );
    return data.map((json) => SkinProduct.fromJson(json)).toList();
  }

  Future<SkinProduct?> saveSkinProduct(SkinProduct product) async {
    Map<String, dynamic>? result;
    final exists = product.id.isNotEmpty && await dataService.getById('skin_products', product.id) != null;
    if (exists) {
      result = await dataService.update('skin_products', product.id, product.toJson());
    } else {
      result = await dataService.insert('skin_products', product.toJson());
    }
    if (result != null) {
      return SkinProduct.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteSkinProduct(String id) async {
    return dataService.delete('skin_products', id);
  }

  // --- SKIN NOTES ---
  Future<List<SkinNote>> getSkinNotes() async {
    final data = await dataService.getAll(
      'skin_notes',
      orderBy: 'date',
    );
    return data.map((json) => SkinNote.fromJson(json)).toList();
  }

  Future<SkinNote?> saveSkinNote(SkinNote note) async {
    Map<String, dynamic>? result;
    final exists = note.id.isNotEmpty && await dataService.getById('skin_notes', note.id) != null;
    if (exists) {
      result = await dataService.update('skin_notes', note.id, note.toJson());
    } else {
      result = await dataService.insert('skin_notes', note.toJson());
    }
    if (result != null) {
      return SkinNote.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteSkinNote(String id) async {
    return dataService.delete('skin_notes', id);
  }

  // --- SKIN CARE COMPLETIONS ---
  Future<List<Map<String, dynamic>>> getSkinCareCompletions({DateTime? date}) async {
    return dataService.getSkinCareCompletions(date: date);
  }

  Future<void> markStepCompleted(String stepId, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await dataService.insert('skin_care_completions', {
      'step_id': stepId,
      'date': dateStr,
      'completed_at': DateTime.now().toIso8601String(),
    });
    await logCompleted(stepId, metadata: {'date': dateStr, 'type': 'skin_care_step'});
  }
}

// ============================================================================
// HAIR REPOSITORY
// ============================================================================

class HairRepository extends EventCaptureRepository {
  HairRepository() : super(widgetName: 'hair', tableName: 'hair_care_entries');

  // --- HAIR CARE ENTRIES ---
  Future<List<HairCareEntry>> getHairCareEntries() async {
    final data = await getAll(orderBy: 'date');
    return data.map((json) => HairCareEntry.fromJson(json)).toList();
  }

  Future<HairCareEntry?> saveHairCareEntry(HairCareEntry entry) async {
    final result = await save(entry.toJson());
    if (result != null) {
      return HairCareEntry.fromJson(result);
    }
    return null;
  }

  // --- HAIR EVENTS ---
  Future<List<HairEvent>> getHairEvents() async {
    final data = await dataService.getAll(
      'hair_events',
      orderBy: 'date',
    );
    return data.map((json) => HairEvent.fromJson(json)).toList();
  }

  Future<HairEvent?> saveHairEvent(HairEvent event) async {
    Map<String, dynamic>? result;
    final exists = event.id.isNotEmpty && await dataService.getById('hair_events', event.id) != null;
    if (exists) {
      result = await dataService.update('hair_events', event.id, event.toJson());
    } else {
      result = await dataService.insert('hair_events', event.toJson());
      if (result != null) await logCreated(result);
    }
    if (result != null) {
      return HairEvent.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteHairEvent(String id) async {
    final result = await dataService.delete('hair_events', id);
    if (result) await logDeleted(id, metadata: {'type': 'hair_event'});
    return result;
  }

  // --- HAIR PRODUCTS ---
  Future<List<HairProduct>> getHairProducts() async {
    final data = await dataService.getAll(
      'hair_products',
      orderBy: 'name',
      ascending: true,
    );
    return data.map((json) => HairProduct.fromJson(json)).toList();
  }

  Future<HairProduct?> saveHairProduct(HairProduct product) async {
    Map<String, dynamic>? result;
    final exists = product.id.isNotEmpty && await dataService.getById('hair_products', product.id) != null;
    if (exists) {
      result = await dataService.update('hair_products', product.id, product.toJson());
    } else {
      result = await dataService.insert('hair_products', product.toJson());
    }
    if (result != null) {
      return HairProduct.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteHairProduct(String id) async {
    return dataService.delete('hair_products', id);
  }
}

// ============================================================================
// SUPPLEMENTS REPOSITORY
// ============================================================================

class SupplementsRepository extends EventCaptureRepository {
  SupplementsRepository() : super(widgetName: 'supplements', tableName: 'supplements');

  // --- SUPPLEMENTS ---
  Future<List<Supplement>> getSupplements() async {
    final data = await getAll(orderBy: 'name', ascending: true);
    return data.map((json) => Supplement.fromJson(json)).toList();
  }

  Future<Supplement?> saveSupplement(Supplement supplement) async {
    final result = await save(supplement.toJson());
    if (result != null) {
      return Supplement.fromJson(result);
    }
    return null;
  }

  // --- SUPPLEMENT INTAKES ---
  Future<List<SupplementIntake>> getSupplementIntakes({DateTime? date}) async {
    final data = await dataService.getSupplementIntakes(date: date);
    return data.map((json) => SupplementIntake.fromJson(json)).toList();
  }

  Future<SupplementIntake?> saveSupplementIntake(SupplementIntake intake) async {
    final result = await dataService.insert('supplement_intakes', intake.toJson());
    if (result != null) {
      await logCreated(result);
      return SupplementIntake.fromJson(result);
    }
    return null;
  }

  Future<bool> deleteSupplementIntake(String id) async {
    final result = await dataService.delete('supplement_intakes', id);
    if (result) await logDeleted(id, metadata: {'type': 'supplement_intake'});
    return result;
  }
}

// ============================================================================
// DIGESTION REPOSITORY
// ============================================================================

class DigestionRepository extends EventCaptureRepository {
  DigestionRepository() : super(widgetName: 'digestion', tableName: 'digestion_entries');

  Future<List<DigestionEntry>> getDigestionEntries() async {
    final data = await getAll(orderBy: 'timestamp');
    return data.map((json) => DigestionEntry.fromJson(json)).toList();
  }

  Future<DigestionEntry?> saveDigestionEntry(DigestionEntry entry) async {
    final result = await save(entry.toJson());
    if (result != null) {
      return DigestionEntry.fromJson(result);
    }
    return null;
  }
}

// ============================================================================
// MEDIA REPOSITORY
// ============================================================================

class MediaRepository extends EventCaptureRepository {
  MediaRepository() : super(widgetName: 'media', tableName: 'user_media');

  Future<List<UserMediaEntry>> getUserMedia({String? status}) async {
    final data = await getAll(
      orderBy: 'updated_at',
      filters: status != null ? {'status': status} : null,
    );
    return data.map((json) => UserMediaEntry.fromJson(json)).toList();
  }

  Future<UserMediaEntry?> saveUserMedia(UserMediaEntry entry) async {
    final result = await save(entry.toJson());
    if (result != null) {
      return UserMediaEntry.fromJson(result);
    }
    return null;
  }
}

// ============================================================================
// HOUSEHOLD REPOSITORY
// ============================================================================

class HouseholdRepository extends EventCaptureRepository {
  HouseholdRepository() : super(widgetName: 'household', tableName: 'household_tasks');

  // --- TASKS ---
  Future<List<HouseholdTask>> getHouseholdTasks() async {
    final data = await getAll(orderBy: 'name', ascending: true);
    return data.map((json) => HouseholdTask.fromJson(json)).toList();
  }

  Future<HouseholdTask?> saveHouseholdTask(HouseholdTask task) async {
    final result = await save(task.toJson());
    if (result != null) {
      return HouseholdTask.fromJson(result);
    }
    return null;
  }

  // --- COMPLETIONS ---
  Future<List<TaskCompletion>> getTaskCompletions({String? taskId}) async {
    final data = await dataService.getHouseholdCompletions(taskId: taskId);
    return data.map((json) => TaskCompletion.fromJson(json)).toList();
  }

  Future<TaskCompletion?> markTaskCompleted(String taskId) async {
    final result = await dataService.insert('household_completions', {
      'task_id': taskId,
      'completed_at': DateTime.now().toIso8601String(),
    });
    if (result != null) {
      await logCompleted(taskId, metadata: {'type': 'household_task'});
      return TaskCompletion.fromJson(result);
    }
    return null;
  }
}

// ============================================================================
// RECIPES REPOSITORY
// ============================================================================

class RecipesRepository extends EventCaptureRepository {
  RecipesRepository() : super(widgetName: 'recipes', tableName: 'recipes');

  // --- RECIPES ---
  Future<List<Recipe>> getRecipes({String? status}) async {
    final data = await getAll(
      orderBy: 'updated_at',
      filters: status != null ? {'status': status} : null,
    );
    return data.map((json) => Recipe.fromJson(json)).toList();
  }

  Future<Recipe?> saveRecipe(Recipe recipe) async {
    final result = await save(recipe.toJson());
    if (result != null) {
      return Recipe.fromJson(result);
    }
    return null;
  }

  // --- COOK LOGS ---
  Future<List<CookLog>> getCookLogs({String? recipeId}) async {
    final data = await dataService.getRecipeCookLogs(recipeId: recipeId);
    return data.map((json) => CookLog.fromJson(json)).toList();
  }

  Future<CookLog?> logRecipeCooked(String recipeId, {String? note, int? rating}) async {
    final result = await dataService.insert('recipe_cook_logs', {
      'recipe_id': recipeId,
      'cooked_at': DateTime.now().toIso8601String(),
      'note': note,
      'rating': rating,
    });
    if (result != null) {
      await logEvent(
        eventType: EventType.completed,
        payload: result,
        referenceId: recipeId,
      );
      return CookLog.fromJson(result);
    }
    return null;
  }
}

// ============================================================================
// MICRO WIDGETS REPOSITORY
// ============================================================================

class MicroWidgetsRepository extends EventCaptureRepository {
  MicroWidgetsRepository() : super(widgetName: 'micro_widgets', tableName: 'micro_widgets');

  // --- MICRO WIDGETS ---
  Future<List<MicroWidgetModel>> getMicroWidgets() async {
    final data = await getAll(orderBy: 'sort_order', ascending: true);
    return data.map((json) => MicroWidgetModel.fromJson(json)).toList();
  }

  Future<MicroWidgetModel?> saveMicroWidget(MicroWidgetModel widget) async {
    final result = await save(widget.toJson());
    if (result != null) {
      return MicroWidgetModel.fromJson(result);
    }
    return null;
  }

  // --- COMPLETIONS ---
  Future<List<Map<String, dynamic>>> getMicroWidgetCompletions({DateTime? date}) async {
    return dataService.getMicroWidgetCompletions(date: date);
  }

  Future<void> markMicroWidgetCompleted(String widgetId, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await dataService.insert('micro_widget_completions', {
      'widget_id': widgetId,
      'date': dateStr,
      'completed_at': DateTime.now().toIso8601String(),
    });
    await logCompleted(widgetId, metadata: {'date': dateStr, 'type': 'micro_widget'});
  }
}

// ============================================================================
// HOME SCREEN CONFIG REPOSITORY
// ============================================================================

class HomeScreenConfigRepository with EventCaptureMixin {
  @override
  String get widgetName => 'home_screen';

  Future<HomeScreenConfig?> getConfig() async {
    final data = await dataService.getHomeScreenConfig();
    if (data != null) {
      return HomeScreenConfig.fromJson(data);
    }
    return null;
  }

  Future<HomeScreenConfig?> saveConfig(HomeScreenConfig config) async {
    final result = await dataService.saveHomeScreenConfig(config.toJson());
    if (result != null) {
      await logUpdated(result);
      return HomeScreenConfig.fromJson(result);
    }
    return null;
  }
}

// ============================================================================
// DATA EXPORT SERVICE
// ============================================================================

class DataExportService {
  final SupabaseDataService _dataService = SupabaseDataService.instance;

  /// Exportiert alle Benutzerdaten als JSON
  Future<Map<String, dynamic>> exportAllData() async {
    return _dataService.exportAllUserData();
  }

  /// Exportiert Event-Log für Statistik
  Future<List<Map<String, dynamic>>> exportEventLog({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _dataService.exportEventLog(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Exportiert Daten einer bestimmten Kategorie
  Future<List<Map<String, dynamic>>> exportCategory(String tableName) async {
    return _dataService.getAll(tableName);
  }
}
