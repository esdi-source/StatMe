import 'package:equatable/equatable.dart';

/// Erweitertes Stimmungs-Model mit zusätzlichen Dimensionen
class MoodLogModel extends Equatable {
  final String id;
  final String userId;
  final int mood; // 1-10 Hauptstimmung (Pflichtbasis)
  final DateTime date;
  final String? note; // Kontext-Notiz "Warum heute so?"
  
  // Zusätzliche Stimmungs-Dimensionen (alle optional)
  final int? stressLevel; // 1-10
  final int? energyLevel; // 1-10
  final int? motivation; // 1-10
  final int? innerCalm; // 1-10 (innere Ruhe, 10 = sehr ruhig)

  const MoodLogModel({
    required this.id,
    required this.userId,
    required this.mood,
    required this.date,
    this.note,
    this.stressLevel,
    this.energyLevel,
    this.motivation,
    this.innerCalm,
  });

  factory MoodLogModel.fromJson(Map<String, dynamic> json) {
    return MoodLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mood: (json['mood_level'] ?? json['mood_1_10'] ?? json['mood']) as int,
      date: DateTime.parse(json['date'] as String),
      note: (json['notes'] ?? json['note']) as String?,
      stressLevel: json['stress_level'] as int?,
      energyLevel: json['energy_level'] as int?,
      motivation: json['motivation'] as int?,
      innerCalm: json['inner_calm'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mood_level': mood,
      'date': date.toIso8601String().split('T')[0],
      'notes': note,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
      'motivation': motivation,
      'inner_calm': innerCalm,
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
  
  String get stressEmoji {
    if (stressLevel == null) return '❓';
    if (stressLevel! <= 2) return '😌';
    if (stressLevel! <= 4) return '🙂';
    if (stressLevel! <= 6) return '😐';
    if (stressLevel! <= 8) return '😰';
    return '🤯';
  }
  
  String get energyEmoji {
    if (energyLevel == null) return '❓';
    if (energyLevel! <= 2) return '😴';
    if (energyLevel! <= 4) return '🥱';
    if (energyLevel! <= 6) return '😐';
    if (energyLevel! <= 8) return '⚡';
    return '🔥';
  }
  
  String get motivationEmoji {
    if (motivation == null) return '❓';
    if (motivation! <= 2) return '😔';
    if (motivation! <= 4) return '😕';
    if (motivation! <= 6) return '😐';
    if (motivation! <= 8) return '💪';
    return '🚀';
  }
  
  String get calmEmoji {
    if (innerCalm == null) return '❓';
    if (innerCalm! <= 2) return '😵';
    if (innerCalm! <= 4) return '😣';
    if (innerCalm! <= 6) return '😐';
    if (innerCalm! <= 8) return '😊';
    return '🧘';
  }

  MoodLogModel copyWith({
    String? id,
    String? userId,
    int? mood,
    DateTime? date,
    String? note,
    int? stressLevel,
    int? energyLevel,
    int? motivation,
    int? innerCalm,
    bool clearStress = false,
    bool clearEnergy = false,
    bool clearMotivation = false,
    bool clearCalm = false,
  }) {
    return MoodLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      note: note ?? this.note,
      stressLevel: clearStress ? null : (stressLevel ?? this.stressLevel),
      energyLevel: clearEnergy ? null : (energyLevel ?? this.energyLevel),
      motivation: clearMotivation ? null : (motivation ?? this.motivation),
      innerCalm: clearCalm ? null : (innerCalm ?? this.innerCalm),
    );
  }

  @override
  List<Object?> get props => [id, userId, mood, date, note, stressLevel, energyLevel, motivation, innerCalm];
}
