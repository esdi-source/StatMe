/// Statistik Widget Screen - Vollständige Datenauswertung
/// 
/// Zeigt ALLE Widget-Daten:
/// - Stimmungsverlauf
/// - Schlaf (Dauer, Qualität, Zeiten)
/// - Ernährung (Kalorien, Mahlzeiten)
/// - Wasser
/// - Sport
/// - Schritte
/// - Toilette/Verdauung
/// - Und alle anderen Widgets
/// 
/// WICHTIG: Keine Diagnosen, keine Empfehlungen, nur neutrale Beobachtungen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/statistics_service.dart';
import '../services/event_log_statistics_service.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';
  bool _isLoading = true;
  
  // Daten
  List<MoodLogModel> _moodData = [];
  List<Correlation> _correlations = [];
  List<Insight> _insights = [];
  StatisticsSummary? _summary;
  
  // NEUE: Alle Widget-Daten
  Map<String, List<DataPoint>> _allWidgetData = {};
  Map<String, _WidgetStats> _widgetStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 Tabs jetzt
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Zeitraum bestimmen
    final now = DateTime.now();
    final DateTime start;
    switch (_selectedPeriod) {
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'quarter':
        start = now.subtract(const Duration(days: 90));
        break;
      default: // month
        start = now.subtract(const Duration(days: 30));
    }

    final supabaseClient = Supabase.instance.client;
    
    // Lade Stimmungsdaten
    await ref.read(moodHistoryProvider.notifier).loadRange(user.id, start, now);
    _moodData = ref.read(moodHistoryProvider);

    // Erstelle Event-basierten DataCollector für automatische Widget-Erkennung
    final eventLogService = EventLogStatisticsService(supabaseClient);
    final eventLogProvider = EventLogStatisticsProvider(eventLogService);
    
    // Lade ALLE Widget-Daten aus Event-Log UND direkten Tabellen
    final dataCollector = await eventLogProvider.createFullDataCollector(user.id, start, now);
    
    // Speichere alle Daten
    _allWidgetData = dataCollector.collectAllData(start, now);
    
    // Berechne Statistiken für jedes Widget
    _widgetStats = _calculateWidgetStats(_allWidgetData, start, now);
    
    final statsService = StatisticsService(dataCollector: dataCollector);
    
    _correlations = statsService.calculateAllCorrelations(user.id, _moodData, start, now);
    final deviations = statsService.findMoodDeviations(user.id, _moodData, start, now);
    _insights = statsService.generateInsights(user.id, _moodData, _correlations, deviations);
    _summary = statsService.createSummary(user.id, _moodData, start, now);

    setState(() => _isLoading = false);
  }

  Map<String, _WidgetStats> _calculateWidgetStats(
    Map<String, List<DataPoint>> data, 
    DateTime start, 
    DateTime end,
  ) {
    final stats = <String, _WidgetStats>{};
    final dayCount = end.difference(start).inDays + 1;
    
    for (final entry in data.entries) {
      final widgetType = entry.key;
      final points = entry.value;
      
      if (points.isEmpty) continue;
      
      // Gruppiere nach Metrik
      final byMetric = <String, List<DataPoint>>{};
      for (final dp in points) {
        byMetric.putIfAbsent(dp.metricName, () => []).add(dp);
      }
      
      // Berechne Stats für jede Metrik
      final metricStats = <String, _MetricStats>{};
      for (final metricEntry in byMetric.entries) {
        final metricPoints = metricEntry.value;
        final values = metricPoints.map((p) => p.value).toList();
        
        // Gruppiere nach Tag für Tages-Summen/Durchschnitte
        final byDay = <String, List<double>>{};
        for (final p in metricPoints) {
          final dayKey = DateFormat('yyyy-MM-dd').format(p.date);
          byDay.putIfAbsent(dayKey, () => []).add(p.value);
        }
        
        // Tägliche Werte (Summe für Kalorien/Wasser/Schritte, Durchschnitt für andere)
        final dailyValues = <double>[];
        for (final dayEntry in byDay.entries) {
          final dayValues = dayEntry.value;
          if (_shouldSumDaily(widgetType, metricEntry.key)) {
            dailyValues.add(dayValues.reduce((a, b) => a + b));
          } else {
            dailyValues.add(dayValues.reduce((a, b) => a + b) / dayValues.length);
          }
        }
        
        metricStats[metricEntry.key] = _MetricStats(
          total: values.reduce((a, b) => a + b),
          average: values.reduce((a, b) => a + b) / values.length,
          min: values.reduce((a, b) => a < b ? a : b),
          max: values.reduce((a, b) => a > b ? a : b),
          count: values.length,
          daysWithData: byDay.length,
          dailyAverage: dailyValues.isEmpty ? 0 : dailyValues.reduce((a, b) => a + b) / dailyValues.length,
          dailyValues: byDay.map((k, v) => MapEntry(k, _shouldSumDaily(widgetType, metricEntry.key) 
              ? v.reduce((a, b) => a + b) 
              : v.reduce((a, b) => a + b) / v.length)),
        );
      }
      
      stats[widgetType] = _WidgetStats(
        widgetType: widgetType,
        daysTracked: byMetric.values.isEmpty ? 0 : 
            byMetric.values.first.map((p) => DateFormat('yyyy-MM-dd').format(p.date)).toSet().length,
        totalDays: dayCount,
        metrics: metricStats,
      );
    }
    
    return stats;
  }
  
  bool _shouldSumDaily(String widgetType, String metricName) {
    // Diese Metriken sollten pro Tag summiert werden
    return ['total_calories', 'total_ml', 'step_count', 'calories_burned', 'taken_count', 'rating'].contains(metricName) ||
           ['calories', 'water', 'steps', 'digestion'].contains(widgetType);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.insights, color: tokens.primary),
            const SizedBox(width: 8),
            const Text('Statistik'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Zeitraum',
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadData();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    if (_selectedPeriod == 'week') const Icon(Icons.check, size: 18),
                    if (_selectedPeriod == 'week') const SizedBox(width: 8),
                    const Text('Letzte 7 Tage'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    if (_selectedPeriod == 'month') const Icon(Icons.check, size: 18),
                    if (_selectedPeriod == 'month') const SizedBox(width: 8),
                    const Text('Letzte 30 Tage'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quarter',
                child: Row(
                  children: [
                    if (_selectedPeriod == 'quarter') const Icon(Icons.check, size: 18),
                    if (_selectedPeriod == 'quarter') const SizedBox(width: 8),
                    const Text('Letzte 90 Tage'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Übersicht'),
            Tab(icon: Icon(Icons.show_chart), text: 'Verlauf'),
            Tab(icon: Icon(Icons.link), text: 'Zusammenhänge'),
            Tab(icon: Icon(Icons.trending_up), text: 'Entwicklung'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(tokens),       // NEU: Alle Daten
                  _buildMoodChartTab(tokens),
                  _buildCorrelationsTab(tokens),
                  _buildTrendsTab(tokens),
                ],
              ),
            ),
    );
  }

  // ============================================================================
  // TAB 0: ÜBERSICHT ALLER DATEN (NEU!)
  // ============================================================================

  Widget _buildOverviewTab(DesignTokens tokens) {
    if (_widgetStats.isEmpty && _moodData.isEmpty) {
      return _buildEmptyState(
        tokens,
        icon: Icons.dashboard,
        title: 'Noch keine Daten',
        subtitle: 'Beginne mit dem Tracking, um hier Statistiken zu sehen.',
      );
    }

    // Sortiere Widgets nach Priorität
    final sortedWidgets = _getSortedWidgets();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Schnelle Zusammenfassung oben
        _buildQuickSummary(tokens),
        const SizedBox(height: 20),
        
        // Stimmung
        if (_moodData.isNotEmpty) ...[
          _buildWidgetSection(tokens, 'mood', 'Stimmung', Icons.mood, Colors.purple),
          const SizedBox(height: 16),
        ],
        
        // Alle anderen Widget-Daten
        ...sortedWidgets.map((widgetType) {
          final info = _getWidgetInfo(widgetType);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildWidgetSection(tokens, widgetType, info.label, info.icon, info.color),
          );
        }),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildQuickSummary(DesignTokens tokens) {
    final periodLabel = _selectedPeriod == 'week' ? '7 Tage' : 
                       _selectedPeriod == 'month' ? '30 Tage' : '90 Tage';
    
    // Zähle aktive Widgets
    final activeWidgets = _widgetStats.length + (_moodData.isNotEmpty ? 1 : 0);
    
    // Berechne Gesamttage mit Daten
    final daysWithAnyData = <String>{};
    for (final entry in _widgetStats.entries) {
      for (final metricEntry in entry.value.metrics.entries) {
        daysWithAnyData.addAll(metricEntry.value.dailyValues.keys);
      }
    }
    for (final mood in _moodData) {
      daysWithAnyData.add(DateFormat('yyyy-MM-dd').format(mood.date));
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tokens.primary, tokens.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Deine Statistik',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Letzte $periodLabel',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBadge(
                  tokens,
                  '${daysWithAnyData.length}',
                  'Tage erfasst',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryBadge(
                  tokens,
                  '$activeWidgets',
                  'Widgets aktiv',
                  Icons.widgets,
                ),
              ),
              if (_summary?.averageMood != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryBadge(
                    tokens,
                    _summary!.averageMood!.toStringAsFixed(1),
                    'Ø Stimmung',
                    Icons.mood,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryBadge(DesignTokens tokens, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetSection(DesignTokens tokens, String widgetType, String label, IconData icon, Color color) {
    if (widgetType == 'mood') {
      return _buildMoodSection(tokens, label, icon, color);
    }
    
    final stats = _widgetStats[widgetType];
    if (stats == null || stats.metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stats.daysTracked} von ${stats.totalDays} Tagen erfasst',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Metriken
          ...stats.metrics.entries.map((metricEntry) {
            final metric = metricEntry.value;
            final metricLabel = _getMetricLabel(metricEntry.key);
            final unit = _getMetricUnit(widgetType, metricEntry.key);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        metricLabel,
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Ø ${_formatValue(metric.dailyAverage, widgetType, metricEntry.key)}$unit/Tag',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mini-Chart
                  if (metric.dailyValues.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: _buildMiniChart(tokens, metric.dailyValues, color),
                    ),
                  const SizedBox(height: 8),
                  // Min/Max
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Min: ${_formatValue(metric.min, widgetType, metricEntry.key)}$unit',
                        style: TextStyle(color: tokens.textDisabled, fontSize: 11),
                      ),
                      Text(
                        'Gesamt: ${_formatValue(metric.total, widgetType, metricEntry.key)}$unit',
                        style: TextStyle(color: tokens.textDisabled, fontSize: 11),
                      ),
                      Text(
                        'Max: ${_formatValue(metric.max, widgetType, metricEntry.key)}$unit',
                        style: TextStyle(color: tokens.textDisabled, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildMoodSection(DesignTokens tokens, String label, IconData icon, Color color) {
    if (_moodData.isEmpty) return const SizedBox.shrink();
    
    // Gruppiere nach Tag
    final byDay = <String, List<int>>{};
    for (final mood in _moodData) {
      final dayKey = DateFormat('yyyy-MM-dd').format(mood.date);
      byDay.putIfAbsent(dayKey, () => []).add(mood.mood);
    }
    
    final dailyAvg = byDay.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final allMoods = _moodData.map((m) => m.mood).toList();
    final avg = allMoods.reduce((a, b) => a + b) / allMoods.length;
    final min = allMoods.reduce((a, b) => a < b ? a : b);
    final max = allMoods.reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${byDay.length} Tage erfasst',
                      style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'Ø ${avg.toStringAsFixed(1)}/10',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: _buildMiniChart(tokens, dailyAvg, color),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min: $min', style: TextStyle(color: tokens.textDisabled, fontSize: 11)),
              Text('Max: $max', style: TextStyle(color: tokens.textDisabled, fontSize: 11)),
            ],
          ),
          // Stress und Energie
          if (_hasAdditionalDimensions()) ...[
            const Divider(height: 24),
            Row(
              children: [
                if (_moodData.any((m) => m.stressLevel != null))
                  Expanded(
                    child: _buildSubMetric(
                      tokens,
                      'Stress',
                      _calculateAvg(_moodData.where((m) => m.stressLevel != null).map((m) => m.stressLevel!.toDouble()).toList()),
                      Icons.psychology,
                      Colors.orange,
                    ),
                  ),
                if (_moodData.any((m) => m.energyLevel != null))
                  Expanded(
                    child: _buildSubMetric(
                      tokens,
                      'Energie',
                      _calculateAvg(_moodData.where((m) => m.energyLevel != null).map((m) => m.energyLevel!.toDouble()).toList()),
                      Icons.bolt,
                      Colors.amber,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSubMetric(DesignTokens tokens, String label, double value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(color: tokens.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
  
  double _calculateAvg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Widget _buildMiniChart(DesignTokens tokens, Map<String, double> dailyValues, Color color) {
    final sortedDays = dailyValues.keys.toList()..sort();
    if (sortedDays.isEmpty) return const SizedBox();
    
    final values = sortedDays.map((d) => dailyValues[d]!).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: minVal * 0.9,
        maxY: maxVal * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: values.asMap().entries.map((e) =>
              FlSpot(e.key.toDouble(), e.value),
            ).toList(),
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: FlDotData(
              show: values.length <= 14,
              getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(radius: 2, color: color, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSortedWidgets() {
    final priority = ['sleep', 'calories', 'water', 'steps', 'sport', 'digestion', 'weight', 'books', 'school', 'skin'];
    final result = <String>[];
    
    for (final w in priority) {
      if (_widgetStats.containsKey(w)) {
        result.add(w);
      }
    }
    
    // Füge restliche hinzu
    for (final w in _widgetStats.keys) {
      if (!result.contains(w)) {
        result.add(w);
      }
    }
    
    return result;
  }

  _WidgetInfo _getWidgetInfo(String widgetType) {
    switch (widgetType) {
      case 'sleep':
        return _WidgetInfo('Schlaf', Icons.bedtime, Colors.indigo);
      case 'calories':
        return _WidgetInfo('Ernährung', Icons.restaurant, Colors.green);
      case 'water':
        return _WidgetInfo('Wasser', Icons.water_drop, Colors.blue);
      case 'steps':
        return _WidgetInfo('Schritte', Icons.directions_walk, Colors.teal);
      case 'sport':
        return _WidgetInfo('Sport', Icons.fitness_center, Colors.red);
      case 'digestion':
        return _WidgetInfo('Verdauung', Icons.wc, Colors.brown);
      case 'weight':
        return _WidgetInfo('Gewicht', Icons.monitor_weight, Colors.orange);
      case 'books':
        return _WidgetInfo('Lesen', Icons.menu_book, Colors.amber);
      case 'school':
        return _WidgetInfo('Schule', Icons.school, Colors.deepPurple);
      case 'skin':
        return _WidgetInfo('Haut', Icons.face, Colors.pink);
      case 'supplements':
        return _WidgetInfo('Nahrungsergänzung', Icons.medication, Colors.cyan);
      case 'todos':
        return _WidgetInfo('Aufgaben', Icons.check_circle, Colors.grey);
      case 'habits':
        return _WidgetInfo('Gewohnheiten', Icons.repeat, Colors.deepOrange);
      case 'household':
        return _WidgetInfo('Haushalt', Icons.home, Colors.blueGrey);
      default:
        return _WidgetInfo(widgetType, Icons.widgets, Colors.grey);
    }
  }

  String _getMetricLabel(String metricName) {
    switch (metricName) {
      case 'total_calories': return 'Kalorien';
      case 'total_ml': return 'Wassermenge';
      case 'step_count': return 'Schritte';
      case 'duration_hours': return 'Schlafdauer';
      case 'duration_minutes': return 'Dauer';
      case 'quality': return 'Qualität';
      case 'calories_burned': return 'Verbrannte Kalorien';
      case 'intensity': return 'Intensität';
      case 'weight_kg': return 'Gewicht';
      case 'pages_read': return 'Gelesene Seiten';
      case 'reading_minutes': return 'Lesezeit';
      case 'grade_value': return 'Notenpunkte';
      case 'study_minutes': return 'Lernzeit';
      case 'condition': return 'Hautzustand';
      case 'oiliness': return 'Fettigkeit';
      case 'hydration': return 'Feuchtigkeit';
      case 'rating': return 'Bewertung';
      case 'taken_count': return 'Einnahmen';
      // Verdauungs-Metriken
      case 'entry_count': return 'Toilettengänge';
      case 'toilet_type': return 'Art';
      case 'consistency': return 'Konsistenz';
      case 'feeling': return 'Gefühl';
      case 'has_pain': return 'Mit Schmerzen';
      case 'has_bloating': return 'Mit Blähungen';
      case 'has_urgency': return 'Dringend';
      default: return metricName.replaceAll('_', ' ');
    }
  }

  String _getMetricUnit(String widgetType, String metricName) {
    if (metricName.contains('calories')) return ' kcal';
    if (metricName.contains('ml')) return ' ml';
    if (metricName.contains('hours')) return ' h';
    if (metricName.contains('minutes')) return ' min';
    if (metricName.contains('weight') || metricName.contains('kg')) return ' kg';
    if (metricName.contains('km')) return ' km';
    if (metricName == 'entry_count') return 'x';
    if (widgetType == 'digestion' && metricName == 'consistency') return '';
    if (widgetType == 'steps' && metricName == 'step_count') return '';
    return '';
  }

  String _formatValue(double value, String widgetType, String metricName) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  // ============================================================================
  // TAB 1: STIMMUNGSVERLAUF
  // ============================================================================

  Widget _buildMoodChartTab(DesignTokens tokens) {
    if (_moodData.isEmpty) {
      return _buildEmptyState(
        tokens,
        icon: Icons.mood,
        title: 'Noch keine Stimmungsdaten',
        subtitle: 'Trage deine tägliche Stimmung ein, um Auswertungen zu sehen.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_summary != null) _buildSummaryCard(tokens),
          const SizedBox(height: 16),
          _buildMoodChart(tokens),
          const SizedBox(height: 24),
          if (_hasAdditionalDimensions()) ...[
            _buildAdditionalDimensionsChart(tokens),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DesignTokens tokens) {
    final summary = _summary!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Übersicht',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  tokens,
                  'Ø Stimmung',
                  summary.averageMood?.toStringAsFixed(1) ?? '-',
                  Icons.mood,
                  tokens.primary,
                ),
              ),
              if (summary.averageStress != null)
                Expanded(
                  child: _buildSummaryItem(
                    tokens,
                    'Ø Stress',
                    summary.averageStress!.toStringAsFixed(1),
                    Icons.psychology,
                    Colors.orange,
                  ),
                ),
              if (summary.averageEnergy != null)
                Expanded(
                  child: _buildSummaryItem(
                    tokens,
                    'Ø Energie',
                    summary.averageEnergy!.toStringAsFixed(1),
                    Icons.bolt,
                    Colors.amber,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.daysWithMood} von ${summary.daysTracked} Tagen erfasst',
            style: TextStyle(color: tokens.textDisabled, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(DesignTokens tokens, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildMoodChart(DesignTokens tokens) {
    final sortedData = [..._moodData]..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stimmungsverlauf',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(color: tokens.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(color: tokens.textDisabled, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (sortedData.length / 5).ceilToDouble().clamp(1, 10),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) return const SizedBox();
                        return Text(
                          DateFormat('d.M').format(sortedData[index].date),
                          style: TextStyle(color: tokens.textDisabled, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedData.asMap().entries.map((e) =>
                      FlSpot(e.key.toDouble(), e.value.mood.toDouble()),
                    ).toList(),
                    isCurved: true,
                    color: tokens.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(radius: 4, color: tokens.primary, strokeWidth: 0),
                    ),
                    belowBarData: BarAreaData(show: true, color: tokens.primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAdditionalDimensions() {
    return _moodData.any((m) => m.stressLevel != null || m.energyLevel != null);
  }

  Widget _buildAdditionalDimensionsChart(DesignTokens tokens) {
    final sortedData = [..._moodData]..sort((a, b) => a.date.compareTo(b.date));
    final hasStress = sortedData.any((m) => m.stressLevel != null);
    final hasEnergy = sortedData.any((m) => m.energyLevel != null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stress & Energie', style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasStress) ...[
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Stress', style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                const SizedBox(width: 16),
              ],
              if (hasEnergy) ...[
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Energie', style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(color: tokens.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: tokens.textDisabled, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  if (hasStress)
                    LineChartBarData(
                      spots: sortedData.asMap().entries.where((e) => e.value.stressLevel != null)
                          .map((e) => FlSpot(e.key.toDouble(), e.value.stressLevel!.toDouble())).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  if (hasEnergy)
                    LineChartBarData(
                      spots: sortedData.asMap().entries.where((e) => e.value.energyLevel != null)
                          .map((e) => FlSpot(e.key.toDouble(), e.value.energyLevel!.toDouble())).toList(),
                      isCurved: true,
                      color: Colors.amber,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: ZUSAMMENHÄNGE
  // ============================================================================

  Widget _buildCorrelationsTab(DesignTokens tokens) {
    final significantCorrelations = _correlations.where((c) => c.isSignificant).toList();

    if (significantCorrelations.isEmpty && _insights.isEmpty) {
      return _buildEmptyState(
        tokens,
        icon: Icons.link,
        title: 'Noch keine Zusammenhänge erkannt',
        subtitle: 'Tracke mehr Daten über einen längeren Zeitraum, um Muster zu entdecken.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: tokens.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diese Beobachtungen zeigen zeitliche Zusammenhänge – keine Ursache-Wirkung.',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_insights.isNotEmpty) ...[
          Text('Beobachtungen', style: TextStyle(color: tokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._insights.map((insight) => _buildInsightCard(tokens, insight)),
          const SizedBox(height: 24),
        ],
        if (significantCorrelations.isNotEmpty) ...[
          Text('Erkannte Muster', style: TextStyle(color: tokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...significantCorrelations.map((corr) => _buildCorrelationCard(tokens, corr)),
        ],
      ],
    );
  }

  Widget _buildInsightCard(DesignTokens tokens, Insight insight) {
    final IconData icon;
    final Color color;
    switch (insight.type) {
      case InsightType.correlation: icon = Icons.link; color = Colors.blue; break;
      case InsightType.pattern: icon = Icons.pattern; color = Colors.purple; break;
      case InsightType.trend: icon = Icons.trending_up; color = Colors.green; break;
      case InsightType.deviation: icon = Icons.warning_amber; color = Colors.orange; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(insight.description, style: TextStyle(color: tokens.textSecondary, fontSize: 14)),
                if (insight.confidenceScore >= 70) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.verified, size: 14, color: tokens.success),
                      const SizedBox(width: 4),
                      Text('Hohe Zuverlässigkeit', style: TextStyle(color: tokens.success, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationCard(DesignTokens tokens, Correlation corr) {
    final isPositive = corr.correlationCoefficient > 0;
    final strength = corr.correlationCoefficient.abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? tokens.success : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  corr.generatedInsight ?? '${_getWidgetLabel(corr.widgetType)} & Stimmung',
                  style: TextStyle(color: tokens.textPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Zusammenhang:', style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    backgroundColor: tokens.divider,
                    valueColor: AlwaysStoppedAnimation(isPositive ? tokens.success : Colors.orange),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(corr.strengthLabel, style: TextStyle(color: tokens.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          if (corr.dayOffset != 0) ...[
            const SizedBox(height: 8),
            Text(
              corr.dayOffset == -1 ? 'Verzögerter Effekt (Vortag)' : 'Verzögerter Effekt',
              style: TextStyle(color: tokens.textDisabled, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: ENTWICKLUNG
  // ============================================================================

  Widget _buildTrendsTab(DesignTokens tokens) {
    if (_summary == null || _summary!.moodTrends.isEmpty) {
      return _buildEmptyState(
        tokens,
        icon: Icons.trending_up,
        title: 'Noch keine Trends verfügbar',
        subtitle: 'Tracke mindestens 2 Wochen, um Entwicklungen zu sehen.',
      );
    }

    final trends = _summary!.moodTrends;
    final sortedWeeks = trends.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
            border: Border.all(color: tokens.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wöchentliche Entwicklung', style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (sortedWeeks.length >= 2)
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      barGroups: sortedWeeks.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(toY: trends[e.value]!, color: tokens.primary, width: 20, borderRadius: BorderRadius.circular(4)),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true, interval: 2, reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: tokens.textDisabled, fontSize: 10)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= sortedWeeks.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('W${index + 1}', style: TextStyle(color: tokens.textDisabled, fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true, drawVerticalLine: false, horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) => FlLine(color: tokens.divider, strokeWidth: 1),
                      ),
                    ),
                  ),
                )
              else
                Center(child: Text('Mehr Daten benötigt', style: TextStyle(color: tokens.textSecondary))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
            border: Border.all(color: tokens.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: tokens.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Langfristig denken', style: TextStyle(color: tokens.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Einzelne Tage sagen wenig aus. Schau auf Wochen und Monate, um echte Veränderungen zu erkennen.',
                style: TextStyle(color: tokens.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HILFSFUNKTIONEN
  // ============================================================================

  Widget _buildEmptyState(DesignTokens tokens, {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: tokens.textDisabled.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: tokens.textSecondary, fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: tokens.textDisabled, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _getWidgetLabel(String widgetType) {
    switch (widgetType) {
      case 'calories': return 'Kalorien';
      case 'water': return 'Wasser';
      case 'steps': return 'Schritte';
      case 'sleep': return 'Schlaf';
      case 'sport': return 'Sport';
      case 'school': return 'Schule';
      case 'books': return 'Bücher';
      case 'skin': return 'Haut';
      case 'todos': return 'Aufgaben';
      case 'digestion': return 'Verdauung';
      case 'weight': return 'Gewicht';
      default: return widgetType;
    }
  }
}

// Hilfsklassen für Statistiken
class _WidgetStats {
  final String widgetType;
  final int daysTracked;
  final int totalDays;
  final Map<String, _MetricStats> metrics;

  _WidgetStats({
    required this.widgetType,
    required this.daysTracked,
    required this.totalDays,
    required this.metrics,
  });
}

class _MetricStats {
  final double total;
  final double average;
  final double min;
  final double max;
  final int count;
  final int daysWithData;
  final double dailyAverage;
  final Map<String, double> dailyValues;

  _MetricStats({
    required this.total,
    required this.average,
    required this.min,
    required this.max,
    required this.count,
    required this.daysWithData,
    required this.dailyAverage,
    required this.dailyValues,
  });
}

class _WidgetInfo {
  final String label;
  final IconData icon;
  final Color color;

  _WidgetInfo(this.label, this.icon, this.color);
}
