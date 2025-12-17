import 'package:equatable/equatable.dart';

/// ============================================================================
/// STATISTIK MODELLE - Zentrale Auswertungslogik
/// ============================================================================
/// 
/// Grundidee:
/// - Stimmung pro Tag ist der zentrale Referenzwert
/// - Alle anderen Widgets liefern Kontext-Daten
/// - Auswertung basiert auf Abweichungen vom persönlichen Normalzustand
/// - Keine Bewertungen, keine Diagnosen, keine Empfehlungen

// ============================================================================
// DATENPUNKT für widget-agnostische Datenerfassung
// ============================================================================

/// Ein einzelner Datenpunkt von irgendeinem Widget
class DataPoint extends Equatable {
  final String widgetType; // z.B. 'calories', 'steps', 'sleep', 'sport'
  final String metricName; // z.B. 'total_calories', 'duration_minutes'
  final double value;
  final DateTime date;
  final Map<String, dynamic>? metadata; // Zusätzliche Infos

  const DataPoint({
    required this.widgetType,
    required this.metricName,
    required this.value,
    required this.date,
    this.metadata,
  });

  @override
  List<Object?> get props => [widgetType, metricName, value, date, metadata];
}

// ============================================================================
// BASELINE (Persönlicher Normalzustand)
// ============================================================================

/// Der persönliche Baseline-Wert für eine Metrik
class MetricBaseline extends Equatable {
  final String id;
  final String userId;
  final String widgetType;
  final String metricName;
  final double baselineValue; // Typischer Wert (Durchschnitt)
  final double standardDeviation; // Wie stark variiert der Wert normalerweise
  final int sampleCount; // Auf wie vielen Datenpunkten basiert das
  final DateTime lastUpdated;

  const MetricBaseline({
    required this.id,
    required this.userId,
    required this.widgetType,
    required this.metricName,
    required this.baselineValue,
    required this.standardDeviation,
    required this.sampleCount,
    required this.lastUpdated,
  });

  /// Prüft ob ein Wert signifikant vom Normalwert abweicht
  /// Returns: -1 (deutlich niedriger), 0 (normal), 1 (deutlich höher)
  int checkDeviation(double value, {double threshold = 1.0}) {
    if (standardDeviation == 0) return 0;
    final zScore = (value - baselineValue) / standardDeviation;
    if (zScore > threshold) return 1; // Deutlich höher
    if (zScore < -threshold) return -1; // Deutlich niedriger
    return 0; // Normal
  }
  
  /// Gibt die Abweichung als Z-Score zurück
  double getZScore(double value) {
    if (standardDeviation == 0) return 0;
    return (value - baselineValue) / standardDeviation;
  }
  
  /// Beschreibung der Abweichung
  String describeDeviation(double value) {
    final deviation = checkDeviation(value);
    if (deviation > 0) return 'mehr als sonst';
    if (deviation < 0) return 'weniger als sonst';
    return 'wie üblich';
  }

  factory MetricBaseline.fromJson(Map<String, dynamic> json) {
    return MetricBaseline(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      widgetType: json['widget_type'] as String,
      metricName: json['metric_name'] as String,
      baselineValue: (json['baseline_value'] as num).toDouble(),
      standardDeviation: (json['standard_deviation'] as num).toDouble(),
      sampleCount: json['sample_count'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'widget_type': widgetType,
      'metric_name': metricName,
      'baseline_value': baselineValue,
      'standard_deviation': standardDeviation,
      'sample_count': sampleCount,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, widgetType, metricName, baselineValue, standardDeviation, sampleCount, lastUpdated];
}

// ============================================================================
// KORRELATION (Erkannte Zusammenhänge)
// ============================================================================

/// Ein erkannter Zusammenhang zwischen Stimmung und einer anderen Metrik
class Correlation extends Equatable {
  final String id;
  final String userId;
  final String widgetType; // z.B. 'sport', 'sleep'
  final String metricName; // z.B. 'duration_minutes'
  final double correlationCoefficient; // -1 bis 1
  final int sampleCount;
  final int dayOffset; // 0 = gleicher Tag, -1 = Vortag hat Effekt
  final DateTime lastUpdated;
  final String? generatedInsight; // Automatisch generierte Beschreibung

  const Correlation({
    required this.id,
    required this.userId,
    required this.widgetType,
    required this.metricName,
    required this.correlationCoefficient,
    required this.sampleCount,
    this.dayOffset = 0,
    required this.lastUpdated,
    this.generatedInsight,
  });

  /// Wie stark ist der Zusammenhang?
  String get strengthLabel {
    final abs = correlationCoefficient.abs();
    if (abs >= 0.7) return 'stark';
    if (abs >= 0.4) return 'mittel';
    if (abs >= 0.2) return 'schwach';
    return 'sehr schwach';
  }

  /// Ist es ein positiver oder negativer Zusammenhang?
  String get directionLabel {
    if (correlationCoefficient > 0) return 'positiv';
    if (correlationCoefficient < 0) return 'negativ';
    return 'neutral';
  }
  
  /// Ist die Korrelation statistisch relevant?
  bool get isSignificant => sampleCount >= 14 && correlationCoefficient.abs() >= 0.3;

  factory Correlation.fromJson(Map<String, dynamic> json) {
    return Correlation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      widgetType: json['widget_type'] as String,
      metricName: json['metric_name'] as String,
      correlationCoefficient: (json['correlation_coefficient'] as num).toDouble(),
      sampleCount: json['sample_count'] as int,
      dayOffset: json['day_offset'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      generatedInsight: json['generated_insight'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'widget_type': widgetType,
      'metric_name': metricName,
      'correlation_coefficient': correlationCoefficient,
      'sample_count': sampleCount,
      'day_offset': dayOffset,
      'last_updated': lastUpdated.toIso8601String(),
      'generated_insight': generatedInsight,
    };
  }

  @override
  List<Object?> get props => [id, userId, widgetType, metricName, correlationCoefficient, sampleCount, dayOffset, lastUpdated, generatedInsight];
}

// ============================================================================
// TAGES-ABWEICHUNG (Auffälliger Tag)
// ============================================================================

/// Ein Tag an dem die Stimmung deutlich vom Normalwert abwich
class MoodDeviation extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final int moodValue;
  final int deviationDirection; // -1 (schlechter), 1 (besser)
  final List<DeviatingFactor> deviatingFactors; // Was war an diesem Tag anders?

  const MoodDeviation({
    required this.id,
    required this.userId,
    required this.date,
    required this.moodValue,
    required this.deviationDirection,
    required this.deviatingFactors,
  });

  String get deviationLabel => deviationDirection > 0 ? 'Besser als sonst' : 'Schlechter als sonst';

  factory MoodDeviation.fromJson(Map<String, dynamic> json) {
    return MoodDeviation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      moodValue: json['mood_value'] as int,
      deviationDirection: json['deviation_direction'] as int,
      deviatingFactors: (json['deviating_factors'] as List<dynamic>?)
          ?.map((f) => DeviatingFactor.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'mood_value': moodValue,
      'deviation_direction': deviationDirection,
      'deviating_factors': deviatingFactors.map((f) => f.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, userId, date, moodValue, deviationDirection, deviatingFactors];
}

/// Ein Faktor der an einem auffälligen Tag ebenfalls abwich
class DeviatingFactor extends Equatable {
  final String widgetType;
  final String metricName;
  final double actualValue;
  final double baselineValue;
  final int deviationDirection; // -1 (niedriger), 1 (höher)
  final String description; // z.B. "Mehr Sport als sonst"

  const DeviatingFactor({
    required this.widgetType,
    required this.metricName,
    required this.actualValue,
    required this.baselineValue,
    required this.deviationDirection,
    required this.description,
  });

  factory DeviatingFactor.fromJson(Map<String, dynamic> json) {
    return DeviatingFactor(
      widgetType: json['widget_type'] as String,
      metricName: json['metric_name'] as String,
      actualValue: (json['actual_value'] as num).toDouble(),
      baselineValue: (json['baseline_value'] as num).toDouble(),
      deviationDirection: json['deviation_direction'] as int,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widget_type': widgetType,
      'metric_name': metricName,
      'actual_value': actualValue,
      'baseline_value': baselineValue,
      'deviation_direction': deviationDirection,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [widgetType, metricName, actualValue, baselineValue, deviationDirection, description];
}

// ============================================================================
// INSIGHT (Generierte Beobachtung)
// ============================================================================

/// Eine generierte, neutrale Beobachtung ohne Wertung
class Insight extends Equatable {
  final String id;
  final String userId;
  final InsightType type;
  final String title;
  final String description;
  final DateTime generatedAt;
  final int confidenceScore; // 0-100, wie sicher sind wir?
  final Map<String, dynamic>? relatedData;

  const Insight({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.generatedAt,
    required this.confidenceScore,
    this.relatedData,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: InsightType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => InsightType.pattern,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      confidenceScore: json['confidence_score'] as int,
      relatedData: json['related_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'generated_at': generatedAt.toIso8601String(),
      'confidence_score': confidenceScore,
      'related_data': relatedData,
    };
  }

  @override
  List<Object?> get props => [id, userId, type, title, description, generatedAt, confidenceScore, relatedData];
}

/// Arten von Beobachtungen
enum InsightType {
  correlation('Zusammenhang', 'link'),
  pattern('Muster', 'pattern'),
  trend('Entwicklung', 'trending_up'),
  deviation('Auffälligkeit', 'warning_amber');

  final String label;
  final String iconName;

  const InsightType(this.label, this.iconName);
}

// ============================================================================
// STATISTIK-ÜBERSICHT
// ============================================================================

/// Zusammenfassung für einen Zeitraum
class StatisticsSummary extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final double? averageMood;
  final double? averageStress;
  final double? averageEnergy;
  final int daysTracked;
  final int daysWithMood;
  final List<Correlation> significantCorrelations;
  final List<Insight> recentInsights;
  final Map<String, double> moodTrends; // Trends pro Woche

  const StatisticsSummary({
    required this.startDate,
    required this.endDate,
    this.averageMood,
    this.averageStress,
    this.averageEnergy,
    required this.daysTracked,
    required this.daysWithMood,
    required this.significantCorrelations,
    required this.recentInsights,
    required this.moodTrends,
  });

  @override
  List<Object?> get props => [
    startDate, endDate, averageMood, averageStress, averageEnergy,
    daysTracked, daysWithMood, significantCorrelations, recentInsights, moodTrends
  ];
}
