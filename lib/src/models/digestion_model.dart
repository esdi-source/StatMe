import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Art des Toilettengangs
enum ToiletType {
  stool('Stuhlgang', '💩'),
  urination('Wasserlassen', '🚽'),
  both('Beides', '🚻');

  final String label;
  final String emoji;
  const ToiletType(this.label, this.emoji);
}

/// Stuhl-Konsistenz nach vereinfachter Bristol-Skala
enum StoolConsistency {
  hard('Hart (Verstopfung)', 1, '🔴'),
  lumpy('Klumpig', 2, '🟠'),
  normal('Normal (Ideal)', 3, '🟢'),
  soft('Weich', 4, '🟡'),
  loose('Locker', 5, '🟠'),
  watery('Wässrig (Durchfall)', 6, '🔴');

  final String label;
  final int value;
  final String indicator;
  const StoolConsistency(this.label, this.value, this.indicator);
  
  /// Ist die Konsistenz im Normalbereich?
  bool get isHealthy => value >= 2 && value <= 4;
}

/// Menge
enum StoolAmount {
  small('Klein', '🔹'),
  medium('Mittel', '🔷'),
  large('Groß', '💎');

  final String label;
  final String emoji;
  const StoolAmount(this.label, this.emoji);
}

/// Gefühl danach
enum PostFeeling {
  relieved('Erleichtert', '😌'),
  neutral('Neutral', '😐'),
  uncomfortable('Unangenehm', '😣'),
  painful('Schmerzhaft', '😖');

  final String label;
  final String emoji;
  const PostFeeling(this.label, this.emoji);
}

// ============================================================================
// TOILETTENGANG MODEL
// ============================================================================

/// Ein Toilettengang-Eintrag
class DigestionEntry extends Equatable {
  final String id;
  final String oderId;
  final DateTime timestamp;
  final ToiletType type;
  
  // Stuhlgang-spezifische Daten (null wenn nur Wasserlassen)
  final StoolConsistency? consistency;
  final StoolAmount? amount;
  
  // Gefühl und Symptome
  final PostFeeling feeling;
  final bool hasPain;
  final bool hasBloating;
  final bool hasUrgency; // Dringlichkeit
  
  // Optionale Notiz
  final String? note;
  
  // Automatische Verknüpfungen (IDs von verknüpften Einträgen)
  final List<String>? linkedFoodIds; // Essen der letzten 24-48h
  final int? waterIntakeLast24h; // Wassermenge in ml
  final int? stressLevel; // Vom Mood-Log
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const DigestionEntry({
    required this.id,
    required this.oderId,
    required this.timestamp,
    required this.type,
    this.consistency,
    this.amount,
    this.feeling = PostFeeling.neutral,
    this.hasPain = false,
    this.hasBloating = false,
    this.hasUrgency = false,
    this.note,
    this.linkedFoodIds,
    this.waterIntakeLast24h,
    this.stressLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  DigestionEntry copyWith({
    String? id,
    String? oderId,
    DateTime? timestamp,
    ToiletType? type,
    StoolConsistency? consistency,
    StoolAmount? amount,
    PostFeeling? feeling,
    bool? hasPain,
    bool? hasBloating,
    bool? hasUrgency,
    String? note,
    List<String>? linkedFoodIds,
    int? waterIntakeLast24h,
    int? stressLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DigestionEntry(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      consistency: consistency ?? this.consistency,
      amount: amount ?? this.amount,
      feeling: feeling ?? this.feeling,
      hasPain: hasPain ?? this.hasPain,
      hasBloating: hasBloating ?? this.hasBloating,
      hasUrgency: hasUrgency ?? this.hasUrgency,
      note: note ?? this.note,
      linkedFoodIds: linkedFoodIds ?? this.linkedFoodIds,
      waterIntakeLast24h: waterIntakeLast24h ?? this.waterIntakeLast24h,
      stressLevel: stressLevel ?? this.stressLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DigestionEntry.fromJson(Map<String, dynamic> json) {
    return DigestionEntry(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ToiletType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ToiletType.stool,
      ),
      consistency: json['consistency'] != null
          ? StoolConsistency.values.firstWhere(
              (e) => e.name == json['consistency'],
              orElse: () => StoolConsistency.normal,
            )
          : null,
      amount: json['amount'] != null
          ? StoolAmount.values.firstWhere(
              (e) => e.name == json['amount'],
              orElse: () => StoolAmount.medium,
            )
          : null,
      feeling: PostFeeling.values.firstWhere(
        (e) => e.name == json['feeling'],
        orElse: () => PostFeeling.neutral,
      ),
      hasPain: json['has_pain'] as bool? ?? false,
      hasBloating: json['has_bloating'] as bool? ?? false,
      hasUrgency: json['has_urgency'] as bool? ?? false,
      note: json['note'] as String?,
      linkedFoodIds: (json['linked_food_ids'] as List<dynamic>?)?.cast<String>(),
      waterIntakeLast24h: json['water_intake_last_24h'] as int?,
      stressLevel: json['stress_level'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'consistency': consistency?.name,
      'amount': amount?.name,
      'feeling': feeling.name,
      'has_pain': hasPain,
      'has_bloating': hasBloating,
      'has_urgency': hasUrgency,
      'note': note,
      'linked_food_ids': linkedFoodIds,
      'water_intake_last_24h': waterIntakeLast24h,
      'stress_level': stressLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Kurze Beschreibung für Widget-Anzeige
  String get shortDescription {
    if (type == ToiletType.urination) {
      return 'Wasserlassen';
    }
    return '${consistency?.label ?? 'Stuhlgang'} • ${amount?.emoji ?? ''}';
  }
  
  /// Zeit als lesbare Zeichenkette
  String get timeString {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Haupt-Emoji für Anzeige
  String get mainEmoji {
    if (type == ToiletType.urination) return '🚽';
    return consistency?.indicator ?? '💩';
  }

  @override
  List<Object?> get props => [
    id, oderId, timestamp, type, consistency, amount, feeling,
    hasPain, hasBloating, hasUrgency, note, linkedFoodIds,
    waterIntakeLast24h, stressLevel, createdAt, updatedAt,
  ];
}

// ============================================================================
// TAGESÜBERSICHT MODEL
// ============================================================================

/// Tagesübersicht für Verdauung
class DigestionDaySummary {
  final DateTime date;
  final List<DigestionEntry> entries;
  final int totalStoolCount;
  final int totalUrinationCount;
  final double avgConsistency; // Durchschnittliche Konsistenz
  final int waterIntake;
  final int? avgStressLevel;

  DigestionDaySummary({
    required this.date,
    required this.entries,
  }) : totalStoolCount = entries.where((e) => 
         e.type == ToiletType.stool || e.type == ToiletType.both
       ).length,
       totalUrinationCount = entries.where((e) => 
         e.type == ToiletType.urination || e.type == ToiletType.both
       ).length,
       avgConsistency = _calculateAvgConsistency(entries),
       waterIntake = entries.isNotEmpty 
         ? (entries.first.waterIntakeLast24h ?? 0) 
         : 0,
       avgStressLevel = _calculateAvgStress(entries);

  static double _calculateAvgConsistency(List<DigestionEntry> entries) {
    final stoolEntries = entries.where((e) => e.consistency != null).toList();
    if (stoolEntries.isEmpty) return 3.0;
    return stoolEntries.map((e) => e.consistency!.value).reduce((a, b) => a + b) 
           / stoolEntries.length;
  }

  static int? _calculateAvgStress(List<DigestionEntry> entries) {
    final withStress = entries.where((e) => e.stressLevel != null).toList();
    if (withStress.isEmpty) return null;
    return (withStress.map((e) => e.stressLevel!).reduce((a, b) => a + b) 
           / withStress.length).round();
  }
  
  /// Trend-Bewertung basierend auf Konsistenz
  String get consistencyTrend {
    if (avgConsistency <= 1.5) return '🔴 Verstopfung';
    if (avgConsistency <= 2.5) return '🟠 Eher hart';
    if (avgConsistency <= 4.5) return '🟢 Normal';
    if (avgConsistency <= 5.5) return '🟠 Eher weich';
    return '🔴 Durchfall';
  }
}

// ============================================================================
// KORRELATIONS-ANALYSE MODEL
// ============================================================================

/// Korrelation zwischen Verdauung und anderen Faktoren
class DigestionCorrelation {
  final String factorName;
  final String factorType; // 'food', 'water', 'stress', 'time'
  final double correlationScore; // -1.0 bis 1.0
  final String description;
  final int sampleSize;

  const DigestionCorrelation({
    required this.factorName,
    required this.factorType,
    required this.correlationScore,
    required this.description,
    required this.sampleSize,
  });
  
  /// Stärke der Korrelation als Text
  String get strengthLabel {
    final abs = correlationScore.abs();
    if (abs < 0.2) return 'Schwach';
    if (abs < 0.5) return 'Moderat';
    if (abs < 0.7) return 'Stark';
    return 'Sehr stark';
  }
  
  /// Richtung der Korrelation
  String get direction {
    if (correlationScore > 0.1) return 'Positiv';
    if (correlationScore < -0.1) return 'Negativ';
    return 'Neutral';
  }
}
