/// Data Migration Service
/// 
/// Migriert bestehende SharedPreferences-Daten nach Supabase.
/// Wird beim App-Start für angemeldete User automatisch ausgeführt.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Migration Status
enum MigrationStatus {
  notStarted,
  inProgress,
  completed,
  failed,
}

/// Migration Result
class MigrationResult {
  final MigrationStatus status;
  final int migratedItems;
  final List<String> errors;
  final DateTime? completedAt;

  MigrationResult({
    required this.status,
    this.migratedItems = 0,
    this.errors = const [],
    this.completedAt,
  });
}

/// Data Migration Service - Migriert lokale Daten zu Supabase
class DataMigrationService {
  final SupabaseClient _client;
  final SharedPreferences _prefs;
  
  static const _migrationCompletedKey = 'data_migration_completed';
  static const _migrationVersionKey = 'data_migration_version';
  static const _currentMigrationVersion = 1;

  DataMigrationService(this._client, this._prefs);

  /// Prüft, ob Migration nötig ist
  bool needsMigration(String userId) {
    final completedKey = '${_migrationCompletedKey}_$userId';
    final versionKey = '${_migrationVersionKey}_$userId';
    
    final isCompleted = _prefs.getBool(completedKey) ?? false;
    final currentVersion = _prefs.getInt(versionKey) ?? 0;
    
    return !isCompleted || currentVersion < _currentMigrationVersion;
  }

  /// Führt die komplette Migration durch
  Future<MigrationResult> migrateAllData(String userId) async {
    final errors = <String>[];
    var migratedCount = 0;

    try {
      // 1. HomeScreen-Konfiguration migrieren
      final homeScreenResult = await _migrateHomeScreenConfig(userId);
      migratedCount += homeScreenResult;

      // 2. Timer-Sessions migrieren
      final timerResult = await _migrateTimerSessions(userId);
      migratedCount += timerResult;

      // 3. Micro-Widgets migrieren
      final microWidgetsResult = await _migrateMicroWidgets(userId);
      migratedCount += microWidgetsResult;

      // 4. Bücher und Reading-Sessions migrieren
      final booksResult = await _migrateBooks(userId);
      migratedCount += booksResult;

      // 5. Sport-Daten migrieren
      final sportResult = await _migrateSportData(userId);
      migratedCount += sportResult;

      // 6. Schul-Daten migrieren
      final schoolResult = await _migrateSchoolData(userId);
      migratedCount += schoolResult;

      // 7. Haut-Daten migrieren
      final skinResult = await _migrateSkinData(userId);
      migratedCount += skinResult;

      // Migration als abgeschlossen markieren
      await _prefs.setBool('${_migrationCompletedKey}_$userId', true);
      await _prefs.setInt('${_migrationVersionKey}_$userId', _currentMigrationVersion);

      return MigrationResult(
        status: MigrationStatus.completed,
        migratedItems: migratedCount,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      errors.add(e.toString());
      return MigrationResult(
        status: MigrationStatus.failed,
        migratedItems: migratedCount,
        errors: errors,
      );
    }
  }

  /// HomeScreen-Konfiguration migrieren
  Future<int> _migrateHomeScreenConfig(String userId) async {
    try {
      final key = 'homescreen_config_$userId';
      final jsonStr = _prefs.getString(key);
      
      if (jsonStr == null) return 0;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // In Supabase speichern
      await _client.from('home_screen_configs').upsert({
        'user_id': userId,
        'grid_columns': json['gridColumns'] ?? 4,
        'widgets': json['widgets'] ?? [],
        'updated_at': DateTime.now().toIso8601String(),
      });

      return 1;
    } catch (e) {
      print('HomeScreen config migration error: $e');
      return 0;
    }
  }

  /// Timer-Sessions migrieren
  Future<int> _migrateTimerSessions(String userId) async {
    try {
      final key = 'timer_sessions_$userId';
      final jsonStr = _prefs.getString(key);
      
      if (jsonStr == null) return 0;

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      var count = 0;

      for (final json in jsonList) {
        try {
          await _client.from('timer_sessions').upsert({
            'id': json['id'],
            'user_id': userId,
            'activity_type': json['activityType'],
            'activity_name': json['activityName'] ?? json['activityType'],
            'start_time': json['startTime'],
            'end_time': json['endTime'],
            'duration_seconds': json['durationSeconds'],
            'notes': json['notes'],
          });
          count++;
        } catch (e) {
          print('Timer session migration error for ${json['id']}: $e');
        }
      }

      return count;
    } catch (e) {
      print('Timer sessions migration error: $e');
      return 0;
    }
  }

  /// Micro-Widgets migrieren
  Future<int> _migrateMicroWidgets(String userId) async {
    try {
      final key = 'micro_widgets_$userId';
      final jsonStr = _prefs.getString(key);
      
      if (jsonStr == null) return 0;

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      var count = 0;

      for (final json in jsonList) {
        try {
          final widgetId = json['id'] ?? 'mw_${DateTime.now().millisecondsSinceEpoch}_$count';
          
          // Widget erstellen
          await _client.from('micro_widgets').upsert({
            'id': widgetId,
            'user_id': userId,
            'name': json['name'] ?? 'Mikro Widget',
            'unit': json['unit'] ?? '',
            'color': json['color'],
            'icon': json['icon'],
            'default_value': json['defaultValue'] ?? 0,
            'step_value': json['stepValue'] ?? 1,
          });

          // Widget-Daten migrieren falls vorhanden
          final dataList = json['data'] as List<dynamic>?;
          if (dataList != null) {
            for (final data in dataList) {
              await _client.from('micro_widget_data').upsert({
                'widget_id': widgetId,
                'date': data['date'],
                'value': data['value'],
              });
            }
          }

          count++;
        } catch (e) {
          print('Micro widget migration error: $e');
        }
      }

      return count;
    } catch (e) {
      print('Micro widgets migration error: $e');
      return 0;
    }
  }

  /// Bücher migrieren
  Future<int> _migrateBooks(String userId) async {
    try {
      final key = 'books_$userId';
      final jsonStr = _prefs.getString(key);
      
      if (jsonStr == null) return 0;

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      var count = 0;

      for (final json in jsonList) {
        try {
          await _client.from('books').upsert({
            'id': json['id'],
            'user_id': userId,
            'title': json['title'],
            'author': json['author'],
            'total_pages': json['totalPages'],
            'current_page': json['currentPage'] ?? 0,
            'cover_url': json['coverUrl'],
            'status': json['status'] ?? 'reading',
            'started_at': json['startedAt'],
            'finished_at': json['finishedAt'],
            'notes': json['notes'],
          });
          count++;
        } catch (e) {
          print('Book migration error: $e');
        }
      }

      // Reading-Sessions migrieren
      final sessionsKey = 'reading_sessions_$userId';
      final sessionsStr = _prefs.getString(sessionsKey);
      
      if (sessionsStr != null) {
        final List<dynamic> sessionsList = jsonDecode(sessionsStr);
        for (final session in sessionsList) {
          try {
            await _client.from('reading_sessions').upsert({
              'id': session['id'],
              'user_id': userId,
              'book_id': session['bookId'],
              'date': session['date'],
              'pages_read': session['pagesRead'],
              'duration_minutes': session['durationMinutes'],
            });
          } catch (e) {
            print('Reading session migration error: $e');
          }
        }
      }

      return count;
    } catch (e) {
      print('Books migration error: $e');
      return 0;
    }
  }

  /// Sport-Daten migrieren
  Future<int> _migrateSportData(String userId) async {
    try {
      var count = 0;

      // Sport-Typen migrieren
      final typesKey = 'sport_types_$userId';
      final typesStr = _prefs.getString(typesKey);
      
      if (typesStr != null) {
        final List<dynamic> typesList = jsonDecode(typesStr);
        for (final type in typesList) {
          try {
            await _client.from('sport_types').upsert({
              'id': type['id'],
              'user_id': userId,
              'name': type['name'],
              'icon': type['icon'],
              'calories_per_minute': type['caloriesPerMinute'],
              'is_custom': type['isCustom'] ?? true,
            });
          } catch (e) {
            print('Sport type migration error: $e');
          }
        }
      }

      // Sport-Sessions migrieren
      final sessionsKey = 'sport_sessions_$userId';
      final sessionsStr = _prefs.getString(sessionsKey);
      
      if (sessionsStr != null) {
        final List<dynamic> sessionsList = jsonDecode(sessionsStr);
        for (final session in sessionsList) {
          try {
            await _client.from('sport_sessions').upsert({
              'id': session['id'],
              'user_id': userId,
              'sport_type_id': session['sportTypeId'],
              'date': session['date'],
              'duration_minutes': session['durationMinutes'],
              'calories_burned': session['caloriesBurned'],
              'intensity': session['intensity'],
              'notes': session['notes'],
            });
            count++;
          } catch (e) {
            print('Sport session migration error: $e');
          }
        }
      }

      return count;
    } catch (e) {
      print('Sport data migration error: $e');
      return 0;
    }
  }

  /// Schul-Daten migrieren
  Future<int> _migrateSchoolData(String userId) async {
    try {
      var count = 0;

      // Fächer migrieren
      final subjectsKey = 'subjects_$userId';
      final subjectsStr = _prefs.getString(subjectsKey);
      
      if (subjectsStr != null) {
        final List<dynamic> subjectsList = jsonDecode(subjectsStr);
        for (final subject in subjectsList) {
          try {
            await _client.from('subjects').upsert({
              'id': subject['id'],
              'user_id': userId,
              'name': subject['name'],
              'short_name': subject['shortName'],
              'color': subject['color'],
              'teacher': subject['teacher'],
              'room': subject['room'],
            });
          } catch (e) {
            print('Subject migration error: $e');
          }
        }
      }

      // Noten migrieren
      final gradesKey = 'grades_$userId';
      final gradesStr = _prefs.getString(gradesKey);
      
      if (gradesStr != null) {
        final List<dynamic> gradesList = jsonDecode(gradesStr);
        for (final grade in gradesList) {
          try {
            await _client.from('grades').upsert({
              'id': grade['id'],
              'user_id': userId,
              'subject_id': grade['subjectId'],
              'value': grade['value'],
              'date': grade['date'],
              'type': grade['type'],
              'weight': grade['weight'] ?? 1.0,
              'note': grade['note'],
            });
            count++;
          } catch (e) {
            print('Grade migration error: $e');
          }
        }
      }

      // Hausaufgaben migrieren
      final homeworkKey = 'homework_$userId';
      final homeworkStr = _prefs.getString(homeworkKey);
      
      if (homeworkStr != null) {
        final List<dynamic> homeworkList = jsonDecode(homeworkStr);
        for (final hw in homeworkList) {
          try {
            await _client.from('homework').upsert({
              'id': hw['id'],
              'user_id': userId,
              'subject_id': hw['subjectId'],
              'title': hw['title'],
              'description': hw['description'],
              'due_date': hw['dueDate'],
              'is_done': hw['isDone'] ?? false,
            });
          } catch (e) {
            print('Homework migration error: $e');
          }
        }
      }

      return count;
    } catch (e) {
      print('School data migration error: $e');
      return 0;
    }
  }

  /// Haut-Daten migrieren
  Future<int> _migrateSkinData(String userId) async {
    try {
      var count = 0;

      // Skin-Entries migrieren
      final entriesKey = 'skin_entries_$userId';
      final entriesStr = _prefs.getString(entriesKey);
      
      if (entriesStr != null) {
        final List<dynamic> entriesList = jsonDecode(entriesStr);
        for (final entry in entriesList) {
          try {
            await _client.from('skin_entries').upsert({
              'id': entry['id'],
              'user_id': userId,
              'date': entry['date'],
              'overall_condition': entry['overallCondition'],
              'oiliness': entry['oiliness'],
              'hydration': entry['hydration'],
              'acne_count': entry['acneCount'],
              'notes': entry['notes'],
              'areas': entry['areas'],
            });
            count++;
          } catch (e) {
            print('Skin entry migration error: $e');
          }
        }
      }

      // Skin-Products migrieren
      final productsKey = 'skin_products_$userId';
      final productsStr = _prefs.getString(productsKey);
      
      if (productsStr != null) {
        final List<dynamic> productsList = jsonDecode(productsStr);
        for (final product in productsList) {
          try {
            await _client.from('skin_products').upsert({
              'id': product['id'],
              'user_id': userId,
              'name': product['name'],
              'brand': product['brand'],
              'category': product['category'],
              'notes': product['notes'],
              'is_active': product['isActive'] ?? true,
            });
          } catch (e) {
            print('Skin product migration error: $e');
          }
        }
      }

      return count;
    } catch (e) {
      print('Skin data migration error: $e');
      return 0;
    }
  }

  /// Löscht alle migrierten lokalen Daten (optional nach erfolgreicher Migration)
  Future<void> clearLocalData(String userId) async {
    final keysToDelete = [
      'homescreen_config_$userId',
      'timer_sessions_$userId',
      'micro_widgets_$userId',
      'books_$userId',
      'reading_sessions_$userId',
      'sport_types_$userId',
      'sport_sessions_$userId',
      'subjects_$userId',
      'grades_$userId',
      'homework_$userId',
      'skin_entries_$userId',
      'skin_products_$userId',
    ];

    for (final key in keysToDelete) {
      await _prefs.remove(key);
    }
  }
}
