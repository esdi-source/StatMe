import 'package:equatable/equatable.dart';

class MoodLogModel extends Equatable {
  final String id;
  final String userId;
  final int mood; // 1-10
  final DateTime date;
  final String? note;

  const MoodLogModel({
    required this.id,
    required this.userId,
    required this.mood,
    required this.date,
    this.note,
  });

  factory MoodLogModel.fromJson(Map<String, dynamic> json) {
    return MoodLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mood: (json['mood_level'] ?? json['mood_1_10']) as int,
      date: DateTime.parse(json['date'] as String),
      note: (json['notes'] ?? json['note']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mood_level': mood,
      'date': date.toIso8601String().split('T')[0],
      'notes': note,
    };
  }

  String get moodEmoji {
    if (mood <= 2) return '😢';
    if (mood <= 4) return '😕';
    if (mood <= 6) return '😐';
    if (mood <= 8) return '🙂';
    return '😄';
  }

  String get moodLabel {
    if (mood <= 2) return 'Sehr schlecht';
    if (mood <= 4) return 'Schlecht';
    if (mood <= 6) return 'Okay';
    if (mood <= 8) return 'Gut';
    return 'Sehr gut';
  }

  MoodLogModel copyWith({
    String? id,
    String? userId,
    int? mood,
    DateTime? date,
    String? note,
  }) {
    return MoodLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, userId, mood, date, note];
}
