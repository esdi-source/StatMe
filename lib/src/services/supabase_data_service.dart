/// Supabase Data Service
/// 
/// Zentraler Service für alle Widget-Daten auf Supabase.
/// Ersetzt SharedPreferences-basierte Speicherung durch persistente Cloud-Speicherung.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Zentraler Supabase Data Service
class SupabaseDataService {
  static SupabaseDataService? _instance;
  final SupabaseClient _client;

  SupabaseDataService._(this._client);

  static SupabaseDataService get instance {
    _instance ??= SupabaseDataService._(Supabase.instance.client);
    return _instance!;
  }

  /// Aktueller User
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Prüft ob User eingeloggt ist
  bool get isAuthenticated => currentUserId != null;

  // ============================================
  // GENERISCHE CRUD-OPERATIONEN
  // ============================================

  /// Generische Abfrage mit User-Filter
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? orderBy,
    bool ascending = false,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    if (!isAuthenticated) return [];
    
    var query = _client
        .from(table)
        .select()
        .eq('user_id', currentUserId!);
    
    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    final orderedQuery = orderBy != null 
        ? query.order(orderBy, ascending: ascending)
        : query;
    
    final limitedQuery = limit != null 
        ? orderedQuery.limit(limit)
        : orderedQuery;
    
    final response = await limitedQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Einzelnen Eintrag abrufen
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    if (!isAuthenticated) return null;
    
    final response = await _client
        .from(table)
        .select()
        .eq('id', id)
        .eq('user_id', currentUserId!)
        .maybeSingle();
    
    return response;
  }

  /// Eintrag erstellen
  Future<Map<String, dynamic>?> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    if (!isAuthenticated) return null;
    
    final insertData = {
      ...data,
      'user_id': currentUserId!,
    };
    
    final response = await _client
        .from(table)
        .insert(insertData)
        .select()
        .single();
    
    return response;
  }

  /// Mehrere Einträge erstellen
  Future<List<Map<String, dynamic>>> insertMany(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    if (!isAuthenticated) return [];
    
    final insertData = dataList.map((data) => {
      ...data,
      'user_id': currentUserId!,
    }).toList();
    
    final response = await _client
        .from(table)
        .insert(insertData)
        .select();
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Eintrag aktualisieren
  Future<Map<String, dynamic>?> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    if (!isAuthenticated) return null;
    
    final response = await _client
        .from(table)
        .update(data)
        .eq('id', id)
        .eq('user_id', currentUserId!)
        .select()
        .single();
    
    return response;
  }

  /// Eintrag löschen
  Future<bool> delete(String table, String id) async {
    if (!isAuthenticated) return false;
    
    await _client
        .from(table)
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId!);
    
    return true;
  }

  /// Alle Einträge eines Typs löschen
  Future<bool> deleteAll(String table) async {
    if (!isAuthenticated) return false;
    
    await _client
        .from(table)
        .delete()
        .eq('user_id', currentUserId!);
    
    return true;
  }

  /// Upsert (Insert or Update)
  Future<Map<String, dynamic>?> upsert(
    String table,
    Map<String, dynamic> data, {
    String? conflictColumn,
  }) async {
    if (!isAuthenticated) return null;
    
    final upsertData = {
      ...data,
      'user_id': currentUserId!,
    };
    
    final response = await _client
        .from(table)
        .upsert(upsertData, onConflict: conflictColumn ?? 'id')
        .select()
        .single();
    
    return response;
  }

  // ============================================
  // SPEZIFISCHE WIDGET-METHODEN
  // ============================================

  // --- BOOKS ---
  
  Future<List<Map<String, dynamic>>> getBooks({String? status}) async {
    return getAll('books', 
      orderBy: 'updated_at',
      filters: status != null ? {'status': status} : null,
    );
  }

  Future<Map<String, dynamic>?> saveBook(Map<String, dynamic> book) async {
    if (book['id'] != null) {
      return update('books', book['id'], book);
    }
    return insert('books', book);
  }

  // --- SCHOOL ---

  Future<List<Map<String, dynamic>>> getSubjects() async {
    return getAll('subjects', orderBy: 'name', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getGrades({String? subjectId}) async {
    return getAll('grades',
      orderBy: 'date',
      filters: subjectId != null ? {'subject_id': subjectId} : null,
    );
  }

  Future<List<Map<String, dynamic>>> getTimetable() async {
    return getAll('timetable_entries', orderBy: 'weekday', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getHomework({String? status}) async {
    return getAll('homework',
      orderBy: 'due_date',
      ascending: true,
      filters: status != null ? {'status': status} : null,
    );
  }

  Future<List<Map<String, dynamic>>> getStudySessions() async {
    return getAll('study_sessions', orderBy: 'start_time');
  }

  Future<List<Map<String, dynamic>>> getSchoolNotes() async {
    return getAll('school_notes', orderBy: 'updated_at');
  }

  Future<List<Map<String, dynamic>>> getSchoolEvents() async {
    return getAll('school_events', orderBy: 'date', ascending: true);
  }

  // --- SPORT ---

  Future<List<Map<String, dynamic>>> getSportSessions() async {
    return getAll('sport_sessions', orderBy: 'date');
  }

  Future<List<Map<String, dynamic>>> getWeightEntries() async {
    return getAll('weight_entries', orderBy: 'date');
  }

  Future<List<Map<String, dynamic>>> getWorkoutPlans() async {
    return getAll('workout_plans', orderBy: 'updated_at');
  }

  // --- SKIN ---

  Future<List<Map<String, dynamic>>> getSkinEntries() async {
    return getAll('skin_entries', orderBy: 'date');
  }

  Future<List<Map<String, dynamic>>> getSkinCareSteps() async {
    return getAll('skin_care_steps', orderBy: 'step_order', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getSkinProducts() async {
    return getAll('skin_products', orderBy: 'name', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getSkinNotes() async {
    return getAll('skin_notes', orderBy: 'date');
  }

  Future<List<Map<String, dynamic>>> getSkinPhotos() async {
    return getAll('skin_photos', orderBy: 'date');
  }

  Future<List<Map<String, dynamic>>> getSkinCareCompletions({DateTime? date}) async {
    if (date == null) {
      return getAll('skin_care_completions', orderBy: 'completed_at');
    }
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return getAll('skin_care_completions', filters: {'date': dateStr});
  }

  // --- HAIR ---

  Future<List<Map<String, dynamic>>> getHairCareEntries() async {
    return getAll('hair_care_entries', orderBy: 'date');
  }

  Future<List<Map<String, dynamic>>> getHairEvents() async {
    return getAll('hair_events', orderBy: 'date');
  }

  Future<List<Map<String, dynamic>>> getHairProducts() async {
    return getAll('hair_products', orderBy: 'name', ascending: true);
  }

  // --- SUPPLEMENTS ---

  Future<List<Map<String, dynamic>>> getSupplements() async {
    return getAll('supplements', orderBy: 'name', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getSupplementIntakes({DateTime? date}) async {
    if (date == null) {
      return getAll('supplement_intakes', orderBy: 'timestamp');
    }
    // Filter by date range
    if (!isAuthenticated) return [];
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final response = await _client
        .from('supplement_intakes')
        .select()
        .eq('user_id', currentUserId!)
        .gte('timestamp', startOfDay.toIso8601String())
        .lt('timestamp', endOfDay.toIso8601String())
        .order('timestamp');
    
    return List<Map<String, dynamic>>.from(response);
  }

  // --- DIGESTION ---

  Future<List<Map<String, dynamic>>> getDigestionEntries() async {
    return getAll('digestion_entries', orderBy: 'timestamp');
  }

  // --- MEDIA ---

  Future<List<Map<String, dynamic>>> getUserMedia({String? status}) async {
    return getAll('user_media',
      orderBy: 'updated_at',
      filters: status != null ? {'status': status} : null,
    );
  }

  // --- HOUSEHOLD ---

  Future<List<Map<String, dynamic>>> getHouseholdTasks() async {
    return getAll('household_tasks', orderBy: 'name', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getHouseholdCompletions({String? taskId}) async {
    return getAll('household_completions',
      orderBy: 'completed_at',
      filters: taskId != null ? {'task_id': taskId} : null,
    );
  }

  // --- RECIPES ---

  Future<List<Map<String, dynamic>>> getRecipes({String? status}) async {
    return getAll('recipes',
      orderBy: 'updated_at',
      filters: status != null ? {'status': status} : null,
    );
  }

  Future<List<Map<String, dynamic>>> getRecipeCookLogs({String? recipeId}) async {
    return getAll('recipe_cook_logs',
      orderBy: 'cooked_at',
      filters: recipeId != null ? {'recipe_id': recipeId} : null,
    );
  }

  // --- TIMER ---

  Future<List<Map<String, dynamic>>> getTimerSessions() async {
    return getAll('timer_sessions', orderBy: 'started_at');
  }

  // --- MICRO WIDGETS ---

  Future<List<Map<String, dynamic>>> getMicroWidgets() async {
    return getAll('micro_widgets', orderBy: 'sort_order', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getMicroWidgetCompletions({DateTime? date}) async {
    if (date == null) {
      return getAll('micro_widget_completions', orderBy: 'completed_at');
    }
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return getAll('micro_widget_completions', filters: {'date': dateStr});
  }

  // --- HOME SCREEN CONFIG ---

  Future<Map<String, dynamic>?> getHomeScreenConfig() async {
    if (!isAuthenticated) return null;
    
    final response = await _client
        .from('home_screen_config')
        .select()
        .eq('user_id', currentUserId!)
        .maybeSingle();
    
    return response;
  }

  Future<Map<String, dynamic>?> saveHomeScreenConfig(Map<String, dynamic> config) async {
    return upsert('home_screen_config', config, conflictColumn: 'user_id');
  }

  // ============================================
  // EVENT LOGGING (für Statistik)
  // ============================================

  /// Loggt ein Event für Statistik-Zwecke
  Future<void> logEvent({
    required String widgetName,
    required String eventType,
    required Map<String, dynamic> payload,
    String? referenceId,
  }) async {
    if (!isAuthenticated) return;
    
    try {
      await _client.from('event_log').insert({
        'user_id': currentUserId!,
        'widget_name': widgetName,
        'event_type': eventType,
        'payload': payload,
        'reference_id': referenceId,
        'client_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Event logging failed: $e');
    }
  }

  // ============================================
  // EXPORT FUNKTIONEN
  // ============================================

  /// Exportiert alle Daten eines Benutzers
  Future<Map<String, dynamic>> exportAllUserData() async {
    if (!isAuthenticated) return {};
    
    final tables = [
      'books', 'reading_goals', 'reading_sessions',
      'subjects', 'timetable_entries', 'grades', 'study_sessions', 
      'homework', 'school_events', 'school_notes',
      'sport_sessions', 'weight_entries', 'workout_plans',
      'skin_entries', 'skin_care_steps', 'skin_care_completions', 
      'skin_products', 'skin_notes', 'skin_photos',
      'hair_care_entries', 'hair_events', 'hair_products',
      'supplements', 'supplement_intakes',
      'digestion_entries',
      'user_media',
      'household_tasks', 'household_completions',
      'recipes', 'recipe_cook_logs',
      'timer_sessions',
      'micro_widgets', 'micro_widget_completions',
      'home_screen_config',
      'todos', 'todo_occurrences',
      'food_logs', 'water_logs', 'steps_logs', 'sleep_logs', 'mood_logs',
      'settings',
    ];
    
    final export = <String, dynamic>{
      'exported_at': DateTime.now().toIso8601String(),
      'user_id': currentUserId,
      'data': <String, dynamic>{},
    };
    
    for (final table in tables) {
      try {
        final data = await getAll(table);
        export['data'][table] = data;
      } catch (e) {
        debugPrint('Export failed for $table: $e');
        export['data'][table] = [];
      }
    }
    
    return export;
  }

  /// Exportiert Event-Log für Statistik
  Future<List<Map<String, dynamic>>> exportEventLog({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAuthenticated) return [];
    
    var query = _client
        .from('event_log')
        .select()
        .eq('user_id', currentUserId!);
    
    if (startDate != null) {
      query = query.gte('timestamp', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('timestamp', endDate.toIso8601String());
    }
    
    final response = await query.order('timestamp');
    return List<Map<String, dynamic>>.from(response);
  }
}
