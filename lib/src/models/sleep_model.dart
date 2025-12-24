import 'package:equatable/equatable.dart';

class SleepLogModel extends Equatable {
  final String id;
  final String userId;
  final DateTime startTs;
  final DateTime endTs;
  final int durationMinutes;
  final int quality; // 1-5

  const SleepLogModel({
    required this.id,
    required this.userId,
    required this.startTs,
    required this.endTs,
    required this.durationMinutes,
    this.quality = 3,
  });

  factory SleepLogModel.fromJson(Map<String, dynamic> json) {
    // Support both old and new column names
    final startTs = DateTime.parse((json['bedtime'] ?? json['sleep_start'] ?? json['start_ts']) as String);
    final endTs = DateTime.parse((json['wake_time'] ?? json['sleep_end'] ?? json['end_ts']) as String);
    return SleepLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTs: startTs,
      endTs: endTs,
      durationMinutes: json['duration_minutes'] as int? ?? endTs.difference(startTs).inMinutes,
      quality: (json['quality'] as num?)?.toInt() ?? 3,
    );
  }

  factory SleepLogModel.calculate({
    required String id,
    required String userId,
    required DateTime startTs,
    required DateTime endTs,
    int quality = 3,
  }) {
    final duration = endTs.difference(startTs).inMinutes;
    return SleepLogModel(
      id: id,
      userId: userId,
      startTs: startTs,
      endTs: endTs,
      durationMinutes: duration > 0 ? duration : 0,
      quality: quality,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': endTs.toIso8601String().split('T')[0],
      'bedtime': startTs.toIso8601String(),
      'wake_time': endTs.toIso8601String(),
      'quality': quality,
    };
  }
  
  double get durationHours => durationMinutes / 60.0;

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
    int? quality,
  }) {
    return SleepLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quality: quality ?? this.quality,
    );
  }

  @override
  List<Object?> get props => [id, userId, startTs, endTs, durationMinutes, quality];
}
