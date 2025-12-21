/// Statistik Widget Screen - Zentrale Auswertung
/// 
/// Zeigt:
/// - Stimmungsverlauf über Zeit
/// - Erkannte Zusammenhänge (Korrelationen)
/// - Abweichungs-Übersicht
/// - Langfristige Veränderungen
/// 
/// WICHTIG: Keine Diagnosen, keine Empfehlungen, nur neutrale Beobachtungen

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
  String _selectedPeriod = 'month'; // 'week', 'month', 'quarter'
  bool _isLoading = true;
  
  // Daten
  List<MoodLogModel> _moodData = [];
  List<Correlation> _correlations = [];
  List<Insight> _insights = [];
  StatisticsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    // Lade Stimmungsdaten
    await ref.read(moodHistoryProvider.notifier).loadRange(user.id, start, now);
    _moodData = ref.read(moodHistoryProvider);

    // Erstelle Event-basierten DataCollector für automatische Widget-Erkennung
    final supabaseClient = Supabase.instance.client;
    final eventLogService = EventLogStatisticsService(supabaseClient);
    final eventLogProvider = EventLogStatisticsProvider(eventLogService);
    
    // Lade alle Widget-Daten automatisch aus Event-Log und direkten Tabellen
    final dataCollector = await eventLogProvider.createFullDataCollector(user.id, start, now);
    
    final statsService = StatisticsService(dataCollector: dataCollector);
    
    _correlations = statsService.calculateAllCorrelations(user.id, _moodData, start, now);
    final deviations = statsService.findMoodDeviations(user.id, _moodData, start, now);
    _insights = statsService.generateInsights(user.id, _moodData, _correlations, deviations);
    _summary = statsService.createSummary(user.id, _moodData, start, now);

    setState(() => _isLoading = false);
  }

  // _registerDataSources entfernt - wird jetzt automatisch durch EventLogStatisticsProvider erledigt

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
          tabs: const [
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
                  _buildMoodChartTab(tokens),
                  _buildCorrelationsTab(tokens),
                  _buildTrendsTab(tokens),
                ],
              ),
            ),
    );
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
          // Zusammenfassung
          if (_summary != null) _buildSummaryCard(tokens),
          const SizedBox(height: 16),
          
          // Stimmungsverlauf
          _buildMoodChart(tokens),
          const SizedBox(height: 24),
          
          // Stress & Energie (wenn vorhanden)
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
            style: TextStyle(
              color: tokens.textDisabled,
              fontSize: 12,
            ),
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
        Text(
          label,
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: tokens.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: tokens.textDisabled,
                          fontSize: 10,
                        ),
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
                          style: TextStyle(
                            color: tokens.textDisabled,
                            fontSize: 10,
                          ),
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
                        FlDotCirclePainter(
                          radius: 4,
                          color: tokens.primary,
                          strokeWidth: 0,
                        ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: tokens.primary.withOpacity(0.1),
                    ),
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
          Text(
            'Stress & Energie',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasStress) ...[
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Stress', style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                const SizedBox(width: 16),
              ],
              if (hasEnergy) ...[
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: tokens.divider,
                    strokeWidth: 1,
                  ),
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
                      spots: sortedData.asMap().entries
                          .where((e) => e.value.stressLevel != null)
                          .map((e) => FlSpot(e.key.toDouble(), e.value.stressLevel!.toDouble()))
                          .toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  if (hasEnergy)
                    LineChartBarData(
                      spots: sortedData.asMap().entries
                          .where((e) => e.value.energyLevel != null)
                          .map((e) => FlSpot(e.key.toDouble(), e.value.energyLevel!.toDouble()))
                          .toList(),
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
  // TAB 2: ZUSAMMENHÄNGE (KORRELATIONEN)
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
        // Info-Banner
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
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Insights
        if (_insights.isNotEmpty) ...[
          Text(
            'Beobachtungen',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._insights.map((insight) => _buildInsightCard(tokens, insight)),
          const SizedBox(height: 24),
        ],

        // Korrelationen
        if (significantCorrelations.isNotEmpty) ...[
          Text(
            'Erkannte Muster',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      case InsightType.correlation:
        icon = Icons.link;
        color = Colors.blue;
        break;
      case InsightType.pattern:
        icon = Icons.pattern;
        color = Colors.purple;
        break;
      case InsightType.trend:
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case InsightType.deviation:
        icon = Icons.warning_amber;
        color = Colors.orange;
        break;
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (insight.confidenceScore >= 70) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.verified, size: 14, color: tokens.success),
                      const SizedBox(width: 4),
                      Text(
                        'Hohe Zuverlässigkeit',
                        style: TextStyle(
                          color: tokens.success,
                          fontSize: 11,
                        ),
                      ),
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
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stärke-Visualisierung
          Row(
            children: [
              Text(
                'Zusammenhang:',
                style: TextStyle(color: tokens.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    backgroundColor: tokens.divider,
                    valueColor: AlwaysStoppedAnimation(
                      isPositive ? tokens.success : Colors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                corr.strengthLabel,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (corr.dayOffset != 0) ...[
            const SizedBox(height: 8),
            Text(
              corr.dayOffset == -1 ? 'Verzögerter Effekt (Vortag)' : 'Verzögerter Effekt',
              style: TextStyle(
                color: tokens.textDisabled,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: ENTWICKLUNG (TRENDS)
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
        // Wochen-Verlauf
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
              Text(
                'Wöchentliche Entwicklung',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                            BarChartRodData(
                              toY: trends[e.value]!,
                              color: tokens.primary,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
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
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= sortedWeeks.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'W${index + 1}',
                                  style: TextStyle(color: tokens.textDisabled, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: tokens.divider,
                          strokeWidth: 1,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Text(
                    'Mehr Daten benötigt',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Langzeit-Hinweis
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
                  Text(
                    'Langfristig denken',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Einzelne Tage sagen wenig aus. Schau auf Wochen und Monate, um echte Veränderungen zu erkennen.',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 14,
                ),
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

  Widget _buildEmptyState(DesignTokens tokens, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: tokens.textDisabled.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: tokens.textDisabled,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
}
