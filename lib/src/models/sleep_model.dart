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
    final startTs = DateTime.parse((json['sleep_start'] ?? json['start_ts']) as String);
    final endTs = DateTime.parse((json['sleep_end'] ?? json['end_ts']) as String);
    return SleepLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTs: startTs,
      endTs: endTs,
      durationMinutes: json['duration_minutes'] as int? ?? endTs.difference(startTs).inMinutes,
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
      'date': endTs.toIso8601String().split('T')[0],
      'sleep_start': startTs.toIso8601String(),
      'sleep_end': endTs.toIso8601String(),
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
