/// Widget Event Bus - Kommunikation zwischen Widgets
/// 
/// Ermöglicht es Widgets, Events zu senden und zu empfangen,
/// ohne direkte Abhängigkeiten zueinander zu haben.
/// 
/// VERWENDUNG:
/// 
/// 1. Event senden:
///    WidgetEventBus.instance.emit(TimerSessionCompletedEvent(...));
/// 
/// 2. Events empfangen:
///    WidgetEventBus.instance.on<TimerSessionCompletedEvent>((event) {
///      // Handle event
///    });
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// BASE EVENT CLASS
// ============================================================================

/// Basis-Klasse für alle Widget-Events
abstract class WidgetEvent {
  /// Zeitstempel des Events
  final DateTime timestamp;
  
  /// Quelle des Events (Widget-ID)
  final String sourceWidgetId;
  
  WidgetEvent({
    required this.sourceWidgetId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ============================================================================
// TIMER EVENTS
// ============================================================================

/// Event: Timer-Session wurde gestartet
class TimerSessionStartedEvent extends WidgetEvent {
  final String sessionId;
  final String activityTypeId;
  
  TimerSessionStartedEvent({
    required this.sessionId,
    required this.activityTypeId,
    required super.sourceWidgetId,
  });
}

/// Event: Timer-Session wurde beendet
class TimerSessionCompletedEvent extends WidgetEvent {
  final String sessionId;
  final String activityTypeId;
  final int durationSeconds;
  final DateTime startTime;
  final DateTime endTime;
  final String? linkedItemId;
  
  TimerSessionCompletedEvent({
    required this.sessionId,
    required this.activityTypeId,
    required this.durationSeconds,
    required this.startTime,
    required this.endTime,
    this.linkedItemId,
    required super.sourceWidgetId,
  });
  
  /// Dauer in Minuten
  int get durationMinutes => durationSeconds ~/ 60;
}

// ============================================================================
// GOAL EVENTS
// ============================================================================

/// Event: Tagesziel wurde erreicht
class DailyGoalReachedEvent extends WidgetEvent {
  final String goalType; // z.B. 'water', 'steps', 'reading_time'
  final double achievedValue;
  final double goalValue;
  
  DailyGoalReachedEvent({
    required this.goalType,
    required this.achievedValue,
    required this.goalValue,
    required super.sourceWidgetId,
  });
}

/// Event: Wochenziel wurde erreicht
class WeeklyGoalReachedEvent extends WidgetEvent {
  final String goalType;
  final double achievedValue;
  final double goalValue;
  
  WeeklyGoalReachedEvent({
    required this.goalType,
    required this.achievedValue,
    required this.goalValue,
    required super.sourceWidgetId,
  });
}

// ============================================================================
// VALUE EVENTS
// ============================================================================

/// Event: Ein Wert wurde aktualisiert
class ValueUpdatedEvent extends WidgetEvent {
  final String valueType; // z.B. 'calories', 'water', 'steps'
  final double oldValue;
  final double newValue;
  final double? dailyGoal;
  
  ValueUpdatedEvent({
    required this.valueType,
    required this.oldValue,
    required this.newValue,
    this.dailyGoal,
    required super.sourceWidgetId,
  });
  
  double get change => newValue - oldValue;
  bool get reachedGoal => dailyGoal != null && newValue >= dailyGoal!;
}

/// Event: Ein Quick-Add wurde ausgeführt
class QuickAddExecutedEvent extends WidgetEvent {
  final String actionId;
  final dynamic value;
  
  QuickAddExecutedEvent({
    required this.actionId,
    required this.value,
    required super.sourceWidgetId,
  });
}

// ============================================================================
// COMPLETION EVENTS
// ============================================================================

/// Event: Eine Aktivität wurde als erledigt markiert
class ActivityCompletedEvent extends WidgetEvent {
  final String activityType;
  final DateTime completedAt;
  
  ActivityCompletedEvent({
    required this.activityType,
    required this.completedAt,
    required super.sourceWidgetId,
  });
}

// ============================================================================
// EVENT BUS
// ============================================================================

/// Zentraler Event-Bus für Widget-Kommunikation
class WidgetEventBus {
  WidgetEventBus._();
  
  /// Singleton-Instanz
  static final WidgetEventBus instance = WidgetEventBus._();
  
  /// StreamController für alle Events
  final _controller = StreamController<WidgetEvent>.broadcast();
  
  /// Stream aller Events
  Stream<WidgetEvent> get stream => _controller.stream;
  
  /// Sendet ein Event an alle Subscriber
  void emit(WidgetEvent event) {
    if (kDebugMode) {
      print('[WidgetEventBus] ${event.runtimeType} from ${event.sourceWidgetId}');
    }
    _controller.add(event);
  }
  
  /// Abonniert Events eines bestimmten Typs
  StreamSubscription<T> on<T extends WidgetEvent>(void Function(T event) handler) {
    return _controller.stream
        .where((event) => event is T)
        .cast<T>()
        .listen(handler);
  }
  
  /// Abonniert alle Events
  StreamSubscription<WidgetEvent> onAll(void Function(WidgetEvent event) handler) {
    return _controller.stream.listen(handler);
  }
  
  /// Schließt den Event-Bus
  void dispose() {
    _controller.close();
  }
}

// ============================================================================
// RIVERPOD INTEGRATION
// ============================================================================

/// Provider für den Event-Bus
final widgetEventBusProvider = Provider<WidgetEventBus>((ref) {
  return WidgetEventBus.instance;
});

/// Provider für den Event-Stream
final widgetEventsProvider = StreamProvider<WidgetEvent>((ref) {
  final bus = ref.watch(widgetEventBusProvider);
  return bus.stream;
});

/// Provider für spezifische Event-Typen
/// Verwendung: ref.watch(widgetEventProvider<TimerSessionCompletedEvent>())
StreamProvider<T> widgetEventProvider<T extends WidgetEvent>() {
  return StreamProvider<T>((ref) {
    final bus = ref.watch(widgetEventBusProvider);
    return bus.stream.where((e) => e is T).cast<T>();
  });
}

// ============================================================================
// HELPER EXTENSION
// ============================================================================

/// Extension für einfaches Event-Emitting
extension WidgetEventBusExtension on WidgetRef {
  /// Sendet ein Event
  void emitEvent(WidgetEvent event) {
    read(widgetEventBusProvider).emit(event);
  }
}
