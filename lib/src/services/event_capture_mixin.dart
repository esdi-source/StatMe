/// Event Capture Mixin
/// 
/// Dieses Mixin wird von Repositories verwendet, um automatisch
/// alle Datenänderungen im Event-Log zu erfassen.

import 'package:flutter/foundation.dart';
import 'supabase_data_service.dart';

/// Event-Typen für das Event-Log
enum EventType {
  created,
  updated,
  deleted,
  completed,
  uncompleted,
  started,
  stopped,
  paused,
  resumed,
  skipped,
  imported,
  exported,
}

extension EventTypeExtension on EventType {
  String get name => toString().split('.').last;
}

/// Mixin für automatische Event-Erfassung
mixin EventCaptureMixin {
  /// Widget-Name für Event-Logging (muss überschrieben werden)
  String get widgetName;
  
  /// Supabase Data Service
  SupabaseDataService get dataService => SupabaseDataService.instance;

  /// Loggt ein Event
  Future<void> logEvent({
    required EventType eventType,
    required Map<String, dynamic> payload,
    String? referenceId,
  }) async {
    try {
      await dataService.logEvent(
        widgetName: widgetName,
        eventType: eventType.name,
        payload: payload,
        referenceId: referenceId,
      );
    } catch (e) {
      debugPrint('Event logging failed: $e');
    }
  }

  /// Loggt ein Create-Event
  Future<void> logCreated(Map<String, dynamic> item, {String? id}) async {
    await logEvent(
      eventType: EventType.created,
      payload: item,
      referenceId: id ?? item['id']?.toString(),
    );
  }

  /// Loggt ein Update-Event
  Future<void> logUpdated(Map<String, dynamic> item, {String? id}) async {
    await logEvent(
      eventType: EventType.updated,
      payload: item,
      referenceId: id ?? item['id']?.toString(),
    );
  }

  /// Loggt ein Delete-Event
  Future<void> logDeleted(String id, {Map<String, dynamic>? metadata}) async {
    await logEvent(
      eventType: EventType.deleted,
      payload: metadata ?? {'deleted_id': id},
      referenceId: id,
    );
  }

  /// Loggt ein Completed-Event
  Future<void> logCompleted(String id, {Map<String, dynamic>? metadata}) async {
    await logEvent(
      eventType: EventType.completed,
      payload: metadata ?? {'completed_id': id},
      referenceId: id,
    );
  }
}

/// Abstract Base Repository mit Event-Capture
abstract class EventCaptureRepository with EventCaptureMixin {
  @override
  final String widgetName;
  
  final String tableName;
  
  EventCaptureRepository({
    required this.widgetName,
    required this.tableName,
  });

  /// Alle Einträge abrufen
  Future<List<Map<String, dynamic>>> getAll({
    String? orderBy,
    bool ascending = false,
    Map<String, dynamic>? filters,
  }) async {
    return dataService.getAll(
      tableName,
      orderBy: orderBy,
      ascending: ascending,
      filters: filters,
    );
  }

  /// Einen Eintrag abrufen
  Future<Map<String, dynamic>?> getById(String id) async {
    return dataService.getById(tableName, id);
  }

  /// Eintrag erstellen (mit Event-Logging)
  Future<Map<String, dynamic>?> create(Map<String, dynamic> data) async {
    final result = await dataService.insert(tableName, data);
    if (result != null) {
      await logCreated(result);
    }
    return result;
  }

  /// Eintrag aktualisieren (mit Event-Logging)
  Future<Map<String, dynamic>?> update(String id, Map<String, dynamic> data) async {
    final result = await dataService.update(tableName, id, data);
    if (result != null) {
      await logUpdated(result);
    }
    return result;
  }

  /// Eintrag erstellen oder aktualisieren (mit Event-Logging)
  Future<Map<String, dynamic>?> save(Map<String, dynamic> data) async {
    final id = data['id']?.toString();
    if (id != null && id.isNotEmpty) {
      return update(id, data);
    }
    return create(data);
  }

  /// Eintrag löschen (mit Event-Logging)
  Future<bool> delete(String id) async {
    final result = await dataService.delete(tableName, id);
    if (result) {
      await logDeleted(id);
    }
    return result;
  }
}
