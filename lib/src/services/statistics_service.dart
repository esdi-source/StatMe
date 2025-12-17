/// ============================================================================
/// STATISTIK SERVICE - Zentrale Auswertungslogik
/// ============================================================================
/// 
/// Dieses Service sammelt Daten von allen Widgets und berechnet:
/// - Persönliche Baseline-Werte (Normalzustand)
/// - Abweichungen von der Norm
/// - Zeitliche Korrelationen mit der Stimmung
/// - Muster und Trends
/// 
/// WICHTIG: Keine Diagnosen, keine Empfehlungen, nur neutrale Beobachtungen

import 'dart:math' as math;
import '../models/models.dart';

/// Widget-agnostische Datensammlung für Statistik-Auswertung
class WidgetDataCollector {
  /// Registrierte Datenquellen
  final Map<String, List<DataPoint> Function(DateTime start, DateTime end)> _dataSources = {};

  /// Registriert eine Datenquelle für ein Widget
  void registerDataSource(
    String widgetType,
    List<DataPoint> Function(DateTime start, DateTime end) dataProvider,
  ) {
    _dataSources[widgetType] = dataProvider;
  }

  /// Sammelt alle Daten für einen Zeitraum
  Map<String, List<DataPoint>> collectAllData(DateTime start, DateTime end) {
    final result = <String, List<DataPoint>>{};
    for (final entry in _dataSources.entries) {
      result[entry.key] = entry.value(start, end);
    }
    return result;
  }

  /// Liste aller registrierten Widget-Typen
  List<String> get registeredWidgets => _dataSources.keys.toList();
}

/// Hauptservice für Statistik-Berechnungen
class StatisticsService {
  final WidgetDataCollector dataCollector;
  
  /// Cache für Baseline-Werte
  final Map<String, MetricBaseline> _baselineCache = {};
  
  /// Cache für Korrelationen
  final List<Correlation> _correlationCache = [];

  StatisticsService({required this.dataCollector});

  // ============================================================================
  // BASELINE BERECHNUNG
  // ============================================================================

  /// Berechnet den Baseline-Wert für eine Metrik
  MetricBaseline calculateBaseline(
    String userId,
    String widgetType,
    String metricName,
    List<DataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) {
      return MetricBaseline(
        id: '${widgetType}_${metricName}_baseline',
        userId: userId,
        widgetType: widgetType,
        metricName: metricName,
        baselineValue: 0,
        standardDeviation: 0,
        sampleCount: 0,
        lastUpdated: DateTime.now(),
      );
    }

    final values = dataPoints.map((d) => d.value).toList();
    final mean = _calculateMean(values);
    final stdDev = _calculateStandardDeviation(values, mean);

    final baseline = MetricBaseline(
      id: '${widgetType}_${metricName}_baseline',
      userId: userId,
      widgetType: widgetType,
      metricName: metricName,
      baselineValue: mean,
      standardDeviation: stdDev,
      sampleCount: values.length,
      lastUpdated: DateTime.now(),
    );

    // Cache aktualisieren
    _baselineCache['${widgetType}_$metricName'] = baseline;

    return baseline;
  }

  /// Berechnet alle Baselines für einen Nutzer
  List<MetricBaseline> calculateAllBaselines(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    final allData = dataCollector.collectAllData(start, end);
    final baselines = <MetricBaseline>[];

    for (final entry in allData.entries) {
      final widgetType = entry.key;
      final dataPoints = entry.value;

      // Gruppiere nach Metrik
      final byMetric = <String, List<DataPoint>>{};
      for (final dp in dataPoints) {
        byMetric.putIfAbsent(dp.metricName, () => []).add(dp);
      }

      for (final metricEntry in byMetric.entries) {
        baselines.add(calculateBaseline(
          userId,
          widgetType,
          metricEntry.key,
          metricEntry.value,
        ));
      }
    }

    return baselines;
  }

  // ============================================================================
  // KORRELATIONS-BERECHNUNG
  // ============================================================================

  /// Berechnet die Korrelation zwischen Stimmung und einer anderen Metrik
  Correlation? calculateCorrelation(
    String userId,
    String widgetType,
    String metricName,
    List<MoodLogModel> moodData,
    List<DataPoint> metricData, {
    int dayOffset = 0, // 0 = gleicher Tag, -1 = Vortag
  }) {
    // Erstelle Map für schnellen Lookup
    final moodByDate = <String, int>{};
    for (final mood in moodData) {
      final dateKey = _dateKey(mood.date);
      moodByDate[dateKey] = mood.mood;
    }

    final metricByDate = <String, double>{};
    for (final dp in metricData) {
      final dateKey = _dateKey(dp.date.add(Duration(days: dayOffset)));
      metricByDate[dateKey] = dp.value;
    }

    // Finde gemeinsame Tage
    final commonDates = moodByDate.keys.where((d) => metricByDate.containsKey(d)).toList();

    if (commonDates.length < 7) {
      return null; // Zu wenig Daten
    }

    final moodValues = commonDates.map((d) => moodByDate[d]!.toDouble()).toList();
    final metricValues = commonDates.map((d) => metricByDate[d]!).toList();

    final correlation = _calculatePearsonCorrelation(moodValues, metricValues);

    if (correlation.isNaN || correlation.isInfinite) {
      return null;
    }

    // Generiere Insight-Text
    final insight = _generateCorrelationInsight(
      widgetType,
      metricName,
      correlation,
      dayOffset,
    );

    return Correlation(
      id: '${widgetType}_${metricName}_correlation',
      userId: userId,
      widgetType: widgetType,
      metricName: metricName,
      correlationCoefficient: correlation,
      sampleCount: commonDates.length,
      dayOffset: dayOffset,
      lastUpdated: DateTime.now(),
      generatedInsight: insight,
    );
  }

  /// Berechnet alle relevanten Korrelationen
  List<Correlation> calculateAllCorrelations(
    String userId,
    List<MoodLogModel> moodData,
    DateTime start,
    DateTime end,
  ) {
    final allData = dataCollector.collectAllData(start, end);
    final correlations = <Correlation>[];

    for (final entry in allData.entries) {
      final widgetType = entry.key;
      final dataPoints = entry.value;

      // Gruppiere nach Metrik
      final byMetric = <String, List<DataPoint>>{};
      for (final dp in dataPoints) {
        byMetric.putIfAbsent(dp.metricName, () => []).add(dp);
      }

      for (final metricEntry in byMetric.entries) {
        // Gleicher Tag
        final sameDay = calculateCorrelation(
          userId,
          widgetType,
          metricEntry.key,
          moodData,
          metricEntry.value,
          dayOffset: 0,
        );
        if (sameDay != null && sameDay.correlationCoefficient.abs() >= 0.2) {
          correlations.add(sameDay);
        }

        // Vortag (verzögerter Effekt)
        final previousDay = calculateCorrelation(
          userId,
          widgetType,
          metricEntry.key,
          moodData,
          metricEntry.value,
          dayOffset: -1,
        );
        if (previousDay != null && previousDay.correlationCoefficient.abs() >= 0.2) {
          correlations.add(previousDay);
        }
      }
    }

    // Sortiere nach Stärke
    correlations.sort((a, b) =>
        b.correlationCoefficient.abs().compareTo(a.correlationCoefficient.abs()));

    _correlationCache.clear();
    _correlationCache.addAll(correlations);

    return correlations;
  }

  // ============================================================================
  // ABWEICHUNGS-ERKENNUNG
  // ============================================================================

  /// Findet Tage an denen die Stimmung deutlich vom Normalwert abwich
  List<MoodDeviation> findMoodDeviations(
    String userId,
    List<MoodLogModel> moodData,
    DateTime start,
    DateTime end, {
    double threshold = 1.5, // Standard-Abweichungen
  }) {
    if (moodData.length < 7) return [];

    // Berechne Baseline für Stimmung
    final moodValues = moodData.map((m) => m.mood.toDouble()).toList();
    final moodMean = _calculateMean(moodValues);
    final moodStdDev = _calculateStandardDeviation(moodValues, moodMean);

    if (moodStdDev == 0) return [];

    final deviations = <MoodDeviation>[];
    final allData = dataCollector.collectAllData(start, end);

    for (final mood in moodData) {
      final zScore = (mood.mood - moodMean) / moodStdDev;

      if (zScore.abs() >= threshold) {
        // Dieser Tag ist auffällig
        final direction = zScore > 0 ? 1 : -1;
        final factors = _findDeviatingFactors(userId, mood.date, allData);

        deviations.add(MoodDeviation(
          id: 'deviation_${_dateKey(mood.date)}',
          userId: userId,
          date: mood.date,
          moodValue: mood.mood,
          deviationDirection: direction,
          deviatingFactors: factors,
        ));
      }
    }

    return deviations;
  }

  /// Findet Faktoren die an einem bestimmten Tag ebenfalls abwichen
  List<DeviatingFactor> _findDeviatingFactors(
    String userId,
    DateTime date,
    Map<String, List<DataPoint>> allData,
  ) {
    final factors = <DeviatingFactor>[];
    final dateKey = _dateKey(date);

    for (final entry in allData.entries) {
      final widgetType = entry.key;
      final dataPoints = entry.value;

      // Gruppiere nach Metrik
      final byMetric = <String, List<DataPoint>>{};
      for (final dp in dataPoints) {
        byMetric.putIfAbsent(dp.metricName, () => []).add(dp);
      }

      for (final metricEntry in byMetric.entries) {
        final metricName = metricEntry.key;
        final points = metricEntry.value;

        // Finde Wert für diesen Tag
        final todayPoints = points.where((p) => _dateKey(p.date) == dateKey);
        if (todayPoints.isEmpty) continue;

        final todayValue = todayPoints.first.value;

        // Hole oder berechne Baseline
        final cacheKey = '${widgetType}_$metricName';
        final baseline = _baselineCache[cacheKey] ??
            calculateBaseline(userId, widgetType, metricName, points);

        final deviation = baseline.checkDeviation(todayValue);
        if (deviation != 0) {
          factors.add(DeviatingFactor(
            widgetType: widgetType,
            metricName: metricName,
            actualValue: todayValue,
            baselineValue: baseline.baselineValue,
            deviationDirection: deviation,
            description: _generateFactorDescription(
              widgetType,
              metricName,
              deviation,
            ),
          ));
        }
      }
    }

    return factors;
  }

  // ============================================================================
  // INSIGHT GENERIERUNG
  // ============================================================================

  /// Generiert Insights basierend auf den Daten
  List<Insight> generateInsights(
    String userId,
    List<MoodLogModel> moodData,
    List<Correlation> correlations,
    List<MoodDeviation> deviations,
  ) {
    final insights = <Insight>[];

    // Insights aus signifikanten Korrelationen
    for (final corr in correlations.where((c) => c.isSignificant)) {
      insights.add(Insight(
        id: 'insight_corr_${corr.widgetType}_${corr.metricName}',
        userId: userId,
        type: InsightType.correlation,
        title: _getCorrelationTitle(corr),
        description: corr.generatedInsight ?? '',
        generatedAt: DateTime.now(),
        confidenceScore: _calculateConfidenceScore(corr.sampleCount, corr.correlationCoefficient.abs()),
        relatedData: {
          'widget_type': corr.widgetType,
          'metric_name': corr.metricName,
          'correlation': corr.correlationCoefficient,
        },
      ));
    }

    // Insights aus Trends (Stimmungsentwicklung)
    if (moodData.length >= 14) {
      final trend = _calculateMoodTrend(moodData);
      if (trend.abs() > 0.3) {
        insights.add(Insight(
          id: 'insight_trend_mood',
          userId: userId,
          type: InsightType.trend,
          title: trend > 0 ? 'Stimmung verbessert sich' : 'Stimmung verschlechtert sich',
          description: trend > 0
              ? 'Deine durchschnittliche Stimmung ist in den letzten Wochen gestiegen.'
              : 'Deine durchschnittliche Stimmung ist in den letzten Wochen gesunken.',
          generatedAt: DateTime.now(),
          confidenceScore: 70,
          relatedData: {'trend_value': trend},
        ));
      }
    }

    return insights;
  }

  // ============================================================================
  // ZUSAMMENFASSUNG
  // ============================================================================

  /// Erstellt eine Zusammenfassung für einen Zeitraum
  StatisticsSummary createSummary(
    String userId,
    List<MoodLogModel> moodData,
    DateTime start,
    DateTime end,
  ) {
    // Durchschnittswerte berechnen
    double? avgMood;
    double? avgStress;
    double? avgEnergy;

    if (moodData.isNotEmpty) {
      avgMood = _calculateMean(moodData.map((m) => m.mood.toDouble()).toList());

      final stressData = moodData.where((m) => m.stressLevel != null).toList();
      if (stressData.isNotEmpty) {
        avgStress = _calculateMean(stressData.map((m) => m.stressLevel!.toDouble()).toList());
      }

      final energyData = moodData.where((m) => m.energyLevel != null).toList();
      if (energyData.isNotEmpty) {
        avgEnergy = _calculateMean(energyData.map((m) => m.energyLevel!.toDouble()).toList());
      }
    }

    // Korrelationen und Insights
    final correlations = calculateAllCorrelations(userId, moodData, start, end);
    final deviations = findMoodDeviations(userId, moodData, start, end);
    final insights = generateInsights(userId, moodData, correlations, deviations);

    // Wochentrends
    final moodTrends = _calculateWeeklyMoodTrends(moodData);

    return StatisticsSummary(
      startDate: start,
      endDate: end,
      averageMood: avgMood,
      averageStress: avgStress,
      averageEnergy: avgEnergy,
      daysTracked: end.difference(start).inDays + 1,
      daysWithMood: moodData.length,
      significantCorrelations: correlations.where((c) => c.isSignificant).toList(),
      recentInsights: insights,
      moodTrends: moodTrends,
    );
  }

  // ============================================================================
  // HILFSFUNKTIONEN
  // ============================================================================

  String _dateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.length < 2) return 0;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / (values.length - 1);
    return math.sqrt(variance);
  }

  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0;

    final meanX = _calculateMean(x);
    final meanY = _calculateMean(y);

    double sumXY = 0;
    double sumX2 = 0;
    double sumY2 = 0;

    for (int i = 0; i < x.length; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      sumXY += dx * dy;
      sumX2 += dx * dx;
      sumY2 += dy * dy;
    }

    if (sumX2 == 0 || sumY2 == 0) return 0;
    return sumXY / (math.sqrt(sumX2) * math.sqrt(sumY2));
  }

  double _calculateMoodTrend(List<MoodLogModel> moodData) {
    if (moodData.length < 7) return 0;

    // Teile in zwei Hälften
    final sorted = [...moodData]..sort((a, b) => a.date.compareTo(b.date));
    final half = sorted.length ~/ 2;

    final firstHalf = sorted.sublist(0, half);
    final secondHalf = sorted.sublist(half);

    final avgFirst = _calculateMean(firstHalf.map((m) => m.mood.toDouble()).toList());
    final avgSecond = _calculateMean(secondHalf.map((m) => m.mood.toDouble()).toList());

    return avgSecond - avgFirst;
  }

  Map<String, double> _calculateWeeklyMoodTrends(List<MoodLogModel> moodData) {
    final weeklyAvg = <String, List<double>>{};

    for (final mood in moodData) {
      // Woche ermitteln (ISO-Woche)
      final weekStart = mood.date.subtract(Duration(days: mood.date.weekday - 1));
      final weekKey = _dateKey(weekStart);
      weeklyAvg.putIfAbsent(weekKey, () => []).add(mood.mood.toDouble());
    }

    return weeklyAvg.map((key, values) => MapEntry(key, _calculateMean(values)));
  }

  String _generateCorrelationInsight(
    String widgetType,
    String metricName,
    double correlation,
    int dayOffset,
  ) {
    final widgetLabel = _getWidgetLabel(widgetType);
    final metricLabel = _getMetricLabel(metricName);
    final timeLabel = dayOffset == 0 ? 'am gleichen Tag' : 'am Vortag';
    final direction = correlation > 0 ? 'höher' : 'niedriger';
    final inverseDirection = correlation > 0 ? 'mehr' : 'weniger';

    return 'An Tagen mit $inverseDirection $metricLabel ($widgetLabel) $timeLabel ist deine Stimmung häufig $direction.';
  }

  String _generateFactorDescription(
    String widgetType,
    String metricName,
    int direction,
  ) {
    final metricLabel = _getMetricLabel(metricName);
    final dirLabel = direction > 0 ? 'Mehr' : 'Weniger';
    return '$dirLabel $metricLabel als sonst';
  }

  String _getCorrelationTitle(Correlation corr) {
    final widget = _getWidgetLabel(corr.widgetType);
    return '$widget & Stimmung';
  }

  int _calculateConfidenceScore(int sampleCount, double correlationStrength) {
    // Basis: Sample-Größe
    int score = 30;
    if (sampleCount >= 14) score += 20;
    if (sampleCount >= 30) score += 20;

    // Korrelationsstärke
    if (correlationStrength >= 0.5) score += 20;
    if (correlationStrength >= 0.7) score += 10;

    return score.clamp(0, 100);
  }

  String _getWidgetLabel(String widgetType) {
    const labels = {
      'calories': 'Kalorien',
      'water': 'Wasser',
      'steps': 'Schritte',
      'sleep': 'Schlaf',
      'sport': 'Sport',
      'school': 'Schule',
      'books': 'Bücher',
      'skin': 'Haut',
      'todos': 'Aufgaben',
    };
    return labels[widgetType] ?? widgetType;
  }

  String _getMetricLabel(String metricName) {
    const labels = {
      'total_calories': 'Kalorien',
      'total_ml': 'Wasser',
      'step_count': 'Schritte',
      'duration_hours': 'Schlafdauer',
      'quality': 'Schlafqualität',
      'duration_minutes': 'Dauer',
      'intensity': 'Intensität',
      'study_minutes': 'Lernzeit',
      'pages_read': 'Gelesene Seiten',
      'condition': 'Hautzustand',
      'completed_count': 'Erledigte Aufgaben',
    };
    return labels[metricName] ?? metricName;
  }
}
