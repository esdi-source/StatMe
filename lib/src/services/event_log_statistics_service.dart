/// Event Log Statistics Service
/// 
/// Liest automatisch alle Widget-Daten aus dem zentralen Event-Log
/// und konvertiert sie in DataPoints für die Statistik-Analyse.
/// 
/// WICHTIG: Neue Widgets werden automatisch erkannt - keine Anpassung nötig!

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'statistics_service.dart';

/// Konfiguration für Event-zu-DataPoint Konvertierung
class EventMetricConfig {
  final String metricName;
  final String payloadField;
  final double Function(dynamic)? valueExtractor;
  final String? displayLabel;

  const EventMetricConfig({
    required this.metricName,
    required this.payloadField,
    this.valueExtractor,
    this.displayLabel,
  });
}

/// Automatische Event-Log Statistik-Integration
class EventLogStatisticsService {
  final SupabaseClient _client;
  
  /// Widget-spezifische Metriken-Konfiguration
  /// Neue Widgets werden automatisch erkannt, hier können spezielle Extraktoren definiert werden
  static final Map<String, List<EventMetricConfig>> _widgetMetricConfigs = {
    // Sport Widget
    'sport': [
      EventMetricConfig(
        metricName: 'duration_minutes',
        payloadField: 'durationMinutes',
        displayLabel: 'Trainingsdauer',
      ),
      EventMetricConfig(
        metricName: 'calories_burned',
        payloadField: 'caloriesBurned',
        displayLabel: 'Verbrannte Kalorien',
      ),
      EventMetricConfig(
        metricName: 'intensity',
        payloadField: 'intensity',
        displayLabel: 'Intensität',
        valueExtractor: (v) => _intensityToValue(v),
      ),
    ],
    
    // Books Widget
    'books': [
      EventMetricConfig(
        metricName: 'pages_read',
        payloadField: 'pagesRead',
        displayLabel: 'Gelesene Seiten',
      ),
      EventMetricConfig(
        metricName: 'reading_minutes',
        payloadField: 'durationMinutes',
        displayLabel: 'Lesezeit',
      ),
      EventMetricConfig(
        metricName: 'current_page',
        payloadField: 'currentPage',
        displayLabel: 'Aktuelle Seite',
      ),
    ],
    
    // School Widget
    'school': [
      EventMetricConfig(
        metricName: 'grade_value',
        payloadField: 'value',
        displayLabel: 'Note',
      ),
      EventMetricConfig(
        metricName: 'study_minutes',
        payloadField: 'durationMinutes',
        displayLabel: 'Lernzeit',
      ),
    ],
    
    // Skin Widget
    'skin': [
      EventMetricConfig(
        metricName: 'condition',
        payloadField: 'overallCondition',
        displayLabel: 'Hautzustand',
      ),
      EventMetricConfig(
        metricName: 'oiliness',
        payloadField: 'oiliness',
        displayLabel: 'Fettigkeit',
      ),
      EventMetricConfig(
        metricName: 'hydration',
        payloadField: 'hydration',
        displayLabel: 'Feuchtigkeit',
      ),
    ],
    
    // Kalorien Widget
    'calories': [
      EventMetricConfig(
        metricName: 'total_calories',
        payloadField: 'calories',
        displayLabel: 'Kalorien',
      ),
    ],
    
    // Wasser Widget
    'water': [
      EventMetricConfig(
        metricName: 'total_ml',
        payloadField: 'amountMl',
        displayLabel: 'Wasser (ml)',
      ),
    ],
    
    // Schritte Widget
    'steps': [
      EventMetricConfig(
        metricName: 'step_count',
        payloadField: 'steps',
        displayLabel: 'Schritte',
      ),
    ],
    
    // Schlaf Widget
    'sleep': [
      EventMetricConfig(
        metricName: 'duration_hours',
        payloadField: 'durationHours',
        displayLabel: 'Schlafdauer',
      ),
      EventMetricConfig(
        metricName: 'quality',
        payloadField: 'quality',
        displayLabel: 'Schlafqualität',
      ),
    ],
    
    // Gewicht Widget
    'weight': [
      EventMetricConfig(
        metricName: 'weight_kg',
        payloadField: 'weight',
        displayLabel: 'Gewicht (kg)',
      ),
    ],
    
    // Supplements Widget
    'supplements': [
      EventMetricConfig(
        metricName: 'taken_count',
        payloadField: 'count',
        displayLabel: 'Eingenommen',
        valueExtractor: (v) => v != null ? (v as num).toDouble() : 1.0,
      ),
      EventMetricConfig(
        metricName: 'dosage',
        payloadField: 'dosage',
        displayLabel: 'Dosierung',
      ),
    ],
    
    // Verdauung Widget
    'digestion': [
      EventMetricConfig(
        metricName: 'entry_count',
        payloadField: 'count',
        displayLabel: 'Anzahl Toilettengänge',
        valueExtractor: (v) => v != null ? (v as num).toDouble() : 1.0,
      ),
      EventMetricConfig(
        metricName: 'toilet_type',
        payloadField: 'type',
        displayLabel: 'Toilettengang-Art',
        valueExtractor: (v) {
          // 1=Stuhlgang, 2=Wasserlassen, 3=Beides
          if (v == 'stool' || v == 'Stuhlgang') return 1.0;
          if (v == 'urination' || v == 'Wasserlassen') return 2.0;
          if (v == 'both' || v == 'Beides') return 3.0;
          return 1.0;
        },
      ),
      EventMetricConfig(
        metricName: 'consistency',
        payloadField: 'consistency',
        displayLabel: 'Konsistenz',
        valueExtractor: (v) {
          // Bristol-Skala: 1=Hart, 2=Klumpig, 3=Normal, 4=Weich, 5=Locker, 6=Wässrig
          if (v == 'hard') return 1.0;
          if (v == 'lumpy') return 2.0;
          if (v == 'normal') return 3.0;
          if (v == 'soft') return 4.0;
          if (v == 'loose') return 5.0;
          if (v == 'watery') return 6.0;
          if (v is num) return v.toDouble();
          return 3.0; // Default: Normal
        },
      ),
      EventMetricConfig(
        metricName: 'feeling',
        payloadField: 'feeling',
        displayLabel: 'Gefühl danach',
        valueExtractor: (v) {
          // 1=Erleichtert, 2=Neutral, 3=Unangenehm, 4=Schmerzhaft
          if (v == 'relieved') return 1.0;
          if (v == 'neutral') return 2.0;
          if (v == 'uncomfortable') return 3.0;
          if (v == 'painful') return 4.0;
          return 2.0;
        },
      ),
      EventMetricConfig(
        metricName: 'has_pain',
        payloadField: 'hasPain',
        displayLabel: 'Mit Schmerzen',
        valueExtractor: (v) => v == true ? 1.0 : 0.0,
      ),
      EventMetricConfig(
        metricName: 'has_bloating',
        payloadField: 'hasBloating',
        displayLabel: 'Mit Blähungen',
        valueExtractor: (v) => v == true ? 1.0 : 0.0,
      ),
      EventMetricConfig(
        metricName: 'has_urgency',
        payloadField: 'hasUrgency',
        displayLabel: 'Dringend',
        valueExtractor: (v) => v == true ? 1.0 : 0.0,
      ),
    ],
    
    // Haushalts Widget
    'household': [
      EventMetricConfig(
        metricName: 'completed',
        payloadField: 'completed',
        valueExtractor: (v) => v == true ? 1.0 : 0.0,
        displayLabel: 'Erledigt',
      ),
    ],
    
    // Todo Widget
    'todos': [
      EventMetricConfig(
        metricName: 'completed',
        payloadField: 'completed',
        valueExtractor: (v) => v == true ? 1.0 : 0.0,
        displayLabel: 'Erledigt',
      ),
    ],
  };
  
  EventLogStatisticsService(this._client);
  
  /// Lädt alle Events eines Users für einen Zeitraum
  Future<List<Map<String, dynamic>>> loadEvents(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('event_log')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.toIso8601String())
          .order('timestamp', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }
  
  /// Ermittelt alle Widget-Typen aus den Events
  Future<Set<String>> discoverWidgetTypes(String userId) async {
    try {
      final response = await _client
          .from('event_log')
          .select('widget_name')
          .eq('user_id', userId);
      
      final types = <String>{};
      for (final row in response) {
        if (row['widget_name'] != null) {
          types.add(row['widget_name'] as String);
        }
      }
      return types;
    } catch (e) {
      print('Error discovering widget types: $e');
      return {};
    }
  }
  
  /// Konvertiert Events zu DataPoints für die Statistik
  List<DataPoint> eventsToDataPoints(List<Map<String, dynamic>> events) {
    final dataPoints = <DataPoint>[];
    
    for (final event in events) {
      final widgetName = event['widget_name'] as String?;
      final eventType = event['event_type'] as String?;
      final timestamp = DateTime.parse(event['timestamp'] as String);
      final payload = event['payload'] as Map<String, dynamic>?;
      
      if (widgetName == null || payload == null) continue;
      
      // Hole Konfiguration für dieses Widget
      final configs = _widgetMetricConfigs[widgetName];
      
      if (configs != null) {
        // Bekanntes Widget - nutze spezifische Konfiguration
        for (final config in configs) {
          final rawValue = payload[config.payloadField];
          if (rawValue != null) {
            double? value;
            if (config.valueExtractor != null) {
              value = config.valueExtractor!(rawValue);
            } else if (rawValue is num) {
              value = rawValue.toDouble();
            }
            
            if (value != null) {
              dataPoints.add(DataPoint(
                widgetType: widgetName,
                metricName: config.metricName,
                value: value,
                date: timestamp,
                metadata: {
                  'event_type': eventType,
                  'display_label': config.displayLabel,
                  ...payload,
                },
              ));
            }
          }
        }
      } else {
        // Unbekanntes Widget - extrahiere automatisch alle numerischen Werte
        final autoPoints = _autoExtractMetrics(widgetName, timestamp, eventType, payload);
        dataPoints.addAll(autoPoints);
      }
    }
    
    return dataPoints;
  }
  
  /// Automatische Extraktion von Metriken aus unbekannten Widgets
  List<DataPoint> _autoExtractMetrics(
    String widgetName,
    DateTime timestamp,
    String? eventType,
    Map<String, dynamic> payload,
  ) {
    final dataPoints = <DataPoint>[];
    
    for (final entry in payload.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Überspringe Metadaten
      if (['id', 'user_id', 'userId', 'created_at', 'updated_at'].contains(key)) {
        continue;
      }
      
      double? numericValue;
      if (value is num) {
        numericValue = value.toDouble();
      } else if (value is bool) {
        numericValue = value ? 1.0 : 0.0;
      }
      
      if (numericValue != null) {
        dataPoints.add(DataPoint(
          widgetType: widgetName,
          metricName: _camelToSnake(key),
          value: numericValue,
          date: timestamp,
          metadata: {
            'event_type': eventType,
            'auto_extracted': true,
            'original_key': key,
          },
        ));
      }
    }
    
    return dataPoints;
  }
  
  /// Erstellt einen WidgetDataCollector mit Events aus der Datenbank
  Future<WidgetDataCollector> createDataCollector(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final collector = WidgetDataCollector();
    
    // Lade Events
    final events = await loadEvents(userId, start, end);
    final dataPoints = eventsToDataPoints(events);
    
    // Gruppiere nach Widget-Typ
    final byWidget = <String, List<DataPoint>>{};
    for (final dp in dataPoints) {
      byWidget.putIfAbsent(dp.widgetType, () => []).add(dp);
    }
    
    // Registriere als Data Sources
    for (final entry in byWidget.entries) {
      final widgetType = entry.key;
      final points = entry.value;
      
      collector.registerDataSource(
        widgetType,
        (s, e) => points.where((p) =>
            p.date.isAfter(s.subtract(const Duration(days: 1))) &&
            p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
      );
    }
    
    return collector;
  }
  
  /// Lädt auch direkte Widget-Daten (für Widgets die noch nicht event-basiert sind)
  Future<void> loadDirectWidgetData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // Sport-Sessions direkt laden
    await _loadSportSessions(collector, userId, start, end);
    
    // Bücher/Reading-Sessions direkt laden
    await _loadReadingSessions(collector, userId, start, end);
    
    // Schul-Daten direkt laden
    await _loadSchoolData(collector, userId, start, end);
    
    // Haut-Einträge direkt laden
    await _loadSkinData(collector, userId, start, end);
    
    // Gewicht direkt laden
    await _loadWeightData(collector, userId, start, end);
    
    // Wasser direkt laden
    await _loadWaterData(collector, userId, start, end);
    
    // Schlaf direkt laden
    await _loadSleepData(collector, userId, start, end);
    
    // Schritte direkt laden
    await _loadStepsData(collector, userId, start, end);
    
    // Kalorien/Food direkt laden
    await _loadFoodData(collector, userId, start, end);
    
    // Verdauung direkt laden
    await _loadDigestionData(collector, userId, start, end);
    
    // Supplements direkt laden
    await _loadSupplementsData(collector, userId, start, end);
  }
  
  Future<void> _loadSportSessions(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('sport_sessions')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      final dataPoints = <DataPoint>[];
      for (final row in response) {
        final date = DateTime.parse(row['date'] as String);
        
        if (row['duration_minutes'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'sport',
            metricName: 'duration_minutes',
            value: (row['duration_minutes'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
        
        if (row['calories_burned'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'sport',
            metricName: 'calories_burned',
            value: (row['calories_burned'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        // Merge mit existierenden Daten oder registriere neu
        final existing = collector.collectAllData(start, end)['sport'] ?? [];
        final merged = [...existing, ...dataPoints];
        
        collector.registerDataSource(
          'sport',
          (s, e) => merged.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      // Tabelle existiert möglicherweise noch nicht
      print('Could not load sport sessions: $e');
    }
  }
  
  Future<void> _loadReadingSessions(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('reading_sessions')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      final dataPoints = <DataPoint>[];
      for (final row in response) {
        final date = DateTime.parse(row['date'] as String);
        
        if (row['pages_read'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'books',
            metricName: 'pages_read',
            value: (row['pages_read'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
        
        if (row['duration_minutes'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'books',
            metricName: 'reading_minutes',
            value: (row['duration_minutes'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'books',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load reading sessions: $e');
    }
  }
  
  Future<void> _loadSchoolData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Noten laden
      final grades = await _client
          .from('grades')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      final dataPoints = <DataPoint>[];
      for (final row in grades) {
        final date = DateTime.parse(row['date'] as String);
        if (row['value'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'school',
            metricName: 'grade_value',
            value: (row['value'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct', 'subject_id': row['subject_id']},
          ));
        }
      }
      
      // Lernsessions laden
      final studySessions = await _client
          .from('study_sessions')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      for (final row in studySessions) {
        final date = DateTime.parse(row['date'] as String);
        if (row['duration_minutes'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'school',
            metricName: 'study_minutes',
            value: (row['duration_minutes'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'school',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load school data: $e');
    }
  }
  
  Future<void> _loadSkinData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('skin_entries')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      final dataPoints = <DataPoint>[];
      for (final row in response) {
        final date = DateTime.parse(row['date'] as String);
        
        if (row['overall_condition'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'skin',
            metricName: 'condition',
            value: (row['overall_condition'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'skin',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load skin data: $e');
    }
  }
  
  Future<void> _loadWeightData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('weight_entries')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      final dataPoints = <DataPoint>[];
      for (final row in response) {
        final date = DateTime.parse(row['date'] as String);
        
        if (row['weight'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'weight',
            metricName: 'weight_kg',
            value: (row['weight'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'weight',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load weight data: $e');
    }
  }
  
  Future<void> _loadWaterData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('water_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      // Gruppiere nach Tag
      final byDay = <String, int>{};
      for (final row in response) {
        final dateStr = row['date'] as String;
        final amount = row['amount_ml'] as int? ?? 0;
        byDay[dateStr] = (byDay[dateStr] ?? 0) + amount;
      }
      
      final dataPoints = <DataPoint>[];
      for (final entry in byDay.entries) {
        final date = DateTime.parse(entry.key);
        dataPoints.add(DataPoint(
          widgetType: 'water',
          metricName: 'total_ml',
          value: entry.value.toDouble(),
          date: date,
          metadata: {'source': 'direct'},
        ));
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'water',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load water data: $e');
    }
  }
  
  Future<void> _loadSleepData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('sleep_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      final dataPoints = <DataPoint>[];
      for (final row in response) {
        final date = DateTime.parse(row['date'] as String);
        
        // Berechne Schlafdauer in Stunden
        if (row['sleep_time'] != null && row['wake_time'] != null) {
          final sleepParts = (row['sleep_time'] as String).split(':');
          final wakeParts = (row['wake_time'] as String).split(':');
          
          final sleepMinutes = int.parse(sleepParts[0]) * 60 + int.parse(sleepParts[1]);
          final wakeMinutes = int.parse(wakeParts[0]) * 60 + int.parse(wakeParts[1]);
          
          var durationMinutes = wakeMinutes - sleepMinutes;
          if (durationMinutes < 0) durationMinutes += 24 * 60; // Über Mitternacht
          
          final durationHours = durationMinutes / 60.0;
          
          dataPoints.add(DataPoint(
            widgetType: 'sleep',
            metricName: 'duration_hours',
            value: durationHours,
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
        
        if (row['quality'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'sleep',
            metricName: 'quality',
            value: (row['quality'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'sleep',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load sleep data: $e');
    }
  }
  
  Future<void> _loadStepsData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('steps_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      final dataPoints = <DataPoint>[];
      for (final row in response) {
        final date = DateTime.parse(row['date'] as String);
        
        if (row['steps'] != null) {
          dataPoints.add(DataPoint(
            widgetType: 'steps',
            metricName: 'step_count',
            value: (row['steps'] as num).toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'steps',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load steps data: $e');
    }
  }
  
  Future<void> _loadFoodData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('food_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      
      // Gruppiere nach Tag
      final byDay = <String, double>{};
      for (final row in response) {
        final dateStr = row['date'] as String;
        final calories = (row['calories'] as num?)?.toDouble() ?? 0;
        byDay[dateStr] = (byDay[dateStr] ?? 0) + calories;
      }
      
      final dataPoints = <DataPoint>[];
      for (final entry in byDay.entries) {
        final date = DateTime.parse(entry.key);
        dataPoints.add(DataPoint(
          widgetType: 'calories',
          metricName: 'total_calories',
          value: entry.value,
          date: date,
          metadata: {'source': 'direct'},
        ));
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'calories',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load food data: $e');
    }
  }
  
  Future<void> _loadDigestionData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('digestion_entries')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.toIso8601String());
      
      // Gruppiere nach Tag für Zählung
      final byDay = <String, List<Map<String, dynamic>>>{};
      for (final row in response) {
        final timestamp = DateTime.parse(row['timestamp'] as String);
        final dateStr = DateFormat('yyyy-MM-dd').format(timestamp);
        byDay[dateStr] = [...(byDay[dateStr] ?? []), row];
      }
      
      final dataPoints = <DataPoint>[];
      for (final entry in byDay.entries) {
        final date = DateTime.parse(entry.key);
        final entries = entry.value;
        
        // Anzahl Toilettengänge pro Tag
        dataPoints.add(DataPoint(
          widgetType: 'digestion',
          metricName: 'entry_count',
          value: entries.length.toDouble(),
          date: date,
          metadata: {'source': 'direct'},
        ));
        
        // Durchschnittliche Konsistenz pro Tag (wenn vorhanden)
        final consistencies = entries
            .where((e) => e['consistency'] != null)
            .map((e) => (e['consistency'] as num).toDouble())
            .toList();
        if (consistencies.isNotEmpty) {
          dataPoints.add(DataPoint(
            widgetType: 'digestion',
            metricName: 'consistency',
            value: consistencies.reduce((a, b) => a + b) / consistencies.length,
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
        
        // Schmerzhafte Einträge zählen
        final painCount = entries.where((e) => e['has_pain'] == true).length;
        if (painCount > 0) {
          dataPoints.add(DataPoint(
            widgetType: 'digestion',
            metricName: 'has_pain',
            value: painCount.toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
        
        // Blähungen zählen
        final bloatingCount = entries.where((e) => e['has_bloating'] == true).length;
        if (bloatingCount > 0) {
          dataPoints.add(DataPoint(
            widgetType: 'digestion',
            metricName: 'has_bloating',
            value: bloatingCount.toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
        
        // Dringend zählen
        final urgencyCount = entries.where((e) => e['has_urgency'] == true).length;
        if (urgencyCount > 0) {
          dataPoints.add(DataPoint(
            widgetType: 'digestion',
            metricName: 'has_urgency',
            value: urgencyCount.toDouble(),
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'digestion',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load digestion data: $e');
    }
  }
  
  Future<void> _loadSupplementsData(
    WidgetDataCollector collector,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _client
          .from('supplement_intakes')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.toIso8601String());
      
      // Gruppiere nach Tag
      final byDay = <String, List<Map<String, dynamic>>>{};
      for (final row in response) {
        final timestamp = DateTime.parse(row['timestamp'] as String);
        final dateStr = DateFormat('yyyy-MM-dd').format(timestamp);
        byDay[dateStr] = [...(byDay[dateStr] ?? []), row];
      }
      
      final dataPoints = <DataPoint>[];
      for (final entry in byDay.entries) {
        final date = DateTime.parse(entry.key);
        final intakes = entry.value;
        
        // Anzahl Einnahmen pro Tag
        dataPoints.add(DataPoint(
          widgetType: 'supplements',
          metricName: 'taken_count',
          value: intakes.length.toDouble(),
          date: date,
          metadata: {'source': 'direct'},
        ));
        
        // Gesamtdosierung pro Tag
        final totalDosage = intakes
            .where((i) => i['dosage'] != null)
            .map((i) => (i['dosage'] as num).toDouble())
            .fold(0.0, (a, b) => a + b);
        if (totalDosage > 0) {
          dataPoints.add(DataPoint(
            widgetType: 'supplements',
            metricName: 'dosage',
            value: totalDosage,
            date: date,
            metadata: {'source': 'direct'},
          ));
        }
      }
      
      if (dataPoints.isNotEmpty) {
        collector.registerDataSource(
          'supplements',
          (s, e) => dataPoints.where((p) =>
              p.date.isAfter(s.subtract(const Duration(days: 1))) &&
              p.date.isBefore(e.add(const Duration(days: 1)))).toList(),
        );
      }
    } catch (e) {
      print('Could not load supplements data: $e');
    }
  }

  // ============================================================================
  // HILFSFUNKTIONEN
  // ============================================================================
  
  /// Konvertiert Intensität zu numerischem Wert
  static double _intensityToValue(dynamic intensity) {
    if (intensity is num) return intensity.toDouble();
    if (intensity is String) {
      switch (intensity.toLowerCase()) {
        case 'low':
        case 'niedrig':
          return 1.0;
        case 'medium':
        case 'mittel':
          return 2.0;
        case 'high':
        case 'hoch':
          return 3.0;
        default:
          return 2.0;
      }
    }
    return 2.0;
  }
  
  /// Konvertiert CamelCase zu snake_case
  String _camelToSnake(String input) {
    return input
        .replaceAllMapped(RegExp('([A-Z])'), (m) => '_${m[1]!.toLowerCase()}')
        .replaceFirst(RegExp('^_'), '');
  }
}

/// Provider für Event-basierte Statistik
class EventLogStatisticsProvider {
  final EventLogStatisticsService _service;
  
  EventLogStatisticsProvider(this._service);
  
  /// Erstellt kompletten DataCollector mit allen verfügbaren Daten
  Future<WidgetDataCollector> createFullDataCollector(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // Erst Events laden
    final collector = await _service.createDataCollector(userId, start, end);
    
    // Dann direkte Widget-Daten hinzufügen (für Widgets ohne Event-Logging)
    await _service.loadDirectWidgetData(collector, userId, start, end);
    
    return collector;
  }
  
  /// Gibt alle verfügbaren Widget-Typen zurück
  Future<Set<String>> getAvailableWidgets(String userId) async {
    final eventWidgets = await _service.discoverWidgetTypes(userId);
    
    // Füge bekannte Widget-Typen hinzu
    eventWidgets.addAll(['sport', 'books', 'school', 'skin', 'weight']);
    
    return eventWidgets;
  }
}
