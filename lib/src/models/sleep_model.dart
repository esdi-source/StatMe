import 'package:equatable/equatable.dart';

class SleepLogModel extends Equatable {
  final String id;
  final String userId;
  final DateTime startTs;
  final DateTime endTs;
  final int durationMinutes;

  const SleepLogModel({
    required this.id,
    required this.userId,
    required this.startTs,
    required this.endTs,
    required this.durationMinutes,
  });

  factory SleepLogModel.fromJson(Map<String, dynamic> json) {
    return SleepLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTs: DateTime.parse(json['start_ts'] as String),
      endTs: DateTime.parse(json['end_ts'] as String),
      durationMinutes: json['duration_minutes'] as int,
    );
  }

  factory SleepLogModel.calculate({
    required String id,
    required String userId,
    required DateTime startTs,
    required DateTime endTs,
  }) {
    final duration = endTs.difference(startTs).inMinutes;
    return SleepLogModel(
      id: id,
      userId: userId,
      startTs: startTs,
      endTs: endTs,
      durationMinutes: duration > 0 ? duration : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_ts': startTs.toIso8601String(),
      'end_ts': endTs.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  SleepLogModel copyWith({
    String? id,
    String? userId,
    DateTime? startTs,
    DateTime? endTs,
    int? durationMinutes,
  }) {
    return SleepLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  List<Object?> get props => [id, userId, startTs, endTs, durationMinutes];
}
