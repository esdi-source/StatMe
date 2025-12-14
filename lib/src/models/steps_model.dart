import 'package:equatable/equatable.dart';

class StepsLogModel extends Equatable {
  final String id;
  final String userId;
  final int steps;
  final DateTime date;
  final String source; // manual, csv, google_fit, apple_health

  const StepsLogModel({
    required this.id,
    required this.userId,
    required this.steps,
    required this.date,
    this.source = 'manual',
  });

  factory StepsLogModel.fromJson(Map<String, dynamic> json) {
    return StepsLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      steps: json['steps'] as int,
      date: DateTime.parse(json['date'] as String),
      source: json['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'steps': steps,
      'date': date.toIso8601String().split('T')[0],
      'source': source,
    };
  }

  StepsLogModel copyWith({
    String? id,
    String? userId,
    int? steps,
    DateTime? date,
    String? source,
  }) {
    return StepsLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      steps: steps ?? this.steps,
      date: date ?? this.date,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [id, userId, steps, date, source];
}
