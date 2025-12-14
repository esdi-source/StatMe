import 'package:equatable/equatable.dart';

class WaterLogModel extends Equatable {
  final String id;
  final String userId;
  final int ml;
  final DateTime date;
  final DateTime createdAt;

  const WaterLogModel({
    required this.id,
    required this.userId,
    required this.ml,
    required this.date,
    required this.createdAt,
  });

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    return WaterLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ml: json['ml'] as int,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ml': ml,
      'date': date.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  WaterLogModel copyWith({
    String? id,
    String? userId,
    int? ml,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return WaterLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ml: ml ?? this.ml,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, ml, date, createdAt];
}
