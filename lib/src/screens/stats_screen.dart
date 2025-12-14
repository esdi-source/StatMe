/// Stats Screen - Statistics and charts

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../services/in_memory_database.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'week';
  String _selectedMetric = 'calories';
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Einzeln'),
            Tab(icon: Icon(Icons.dashboard), text: 'Übersicht'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Einzelne Metriken (wie vorher)
          _buildSingleMetricView(),
          // Tab 2: Alle Metriken gleichzeitig
          _buildAllMetricsView(),
        ],
      ),
    );
  }
  
  /// Einzelne Metrik-Ansicht (wie vorher)
  Widget _buildSingleMetricView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            children: [
              Text(
                'Zeitraum:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('Woche')),
                  ButtonSegment(value: 'month', label: Text('Monat')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (selected) {
                  setState(() => _selectedPeriod = selected.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metric Selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Kalorien',
                icon: Icons.restaurant,
                color: Colors.orange,
                selected: _selectedMetric == 'calories',
                onTap: () => setState(() => _selectedMetric = 'calories'),
              ),
              _MetricChip(
                label: 'Wasser',
                icon: Icons.water_drop,
                color: Colors.blue,
                selected: _selectedMetric == 'water',
                onTap: () => setState(() => _selectedMetric = 'water'),
              ),
              _MetricChip(
                label: 'Schritte',
                icon: Icons.directions_walk,
                color: Colors.green,
                selected: _selectedMetric == 'steps',
                onTap: () => setState(() => _selectedMetric = 'steps'),
              ),
              _MetricChip(
                label: 'Schlaf',
                icon: Icons.bedtime,
                color: Colors.purple,
                selected: _selectedMetric == 'sleep',
                onTap: () => setState(() => _selectedMetric = 'sleep'),
              ),
              _MetricChip(
                label: 'Stimmung',
                icon: Icons.mood,
                color: Colors.amber,
                selected: _selectedMetric == 'mood',
                onTap: () => setState(() => _selectedMetric = 'mood'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getChartTitle(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: _buildChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Summary Cards
          Text(
            'Zusammenfassung',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _SummaryCard(
                title: 'Durchschnitt',
                value: _getAverageValue(),
                icon: Icons.analytics,
                color: _getMetricColor(),
              ),
              _SummaryCard(
                title: 'Maximum',
                value: _getMaxValue(),
                icon: Icons.arrow_upward,
                color: Colors.green,
              ),
              _SummaryCard(
                title: 'Minimum',
                value: _getMinValue(),
                icon: Icons.arrow_downward,
                color: Colors.red,
              ),
              _SummaryCard(
                title: 'Trend',
                value: _getTrendValue(),
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Insights
          Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green.shade900
                : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_getInsight()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Alle Metriken gleichzeitig anzeigen
  Widget _buildAllMetricsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeitraum-Auswahl
          Row(
            children: [
              Text(
                'Zeitraum:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('Woche')),
                  ButtonSegment(value: 'month', label: Text('Monat')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (selected) {
                  setState(() => _selectedPeriod = selected.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Alle Statistiken im Überblick',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'So kannst du Parallelen zwischen deinen Aktivitäten erkennen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Kombiniertes Line-Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trends im Vergleich',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildLegend(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildCombinedLineChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Kleine Charts für jede Metrik
          Text(
            'Einzelne Metriken',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          _buildMiniChartCard('Kalorien', Icons.restaurant, Colors.orange, 'calories'),
          const SizedBox(height: 12),
          _buildMiniChartCard('Wasser', Icons.water_drop, Colors.blue, 'water'),
          const SizedBox(height: 12),
          _buildMiniChartCard('Schritte', Icons.directions_walk, Colors.green, 'steps'),
          const SizedBox(height: 12),
          _buildMiniChartCard('Schlaf', Icons.bedtime, Colors.purple, 'sleep'),
          const SizedBox(height: 12),
          _buildMiniChartCard('Stimmung', Icons.mood, Colors.amber, 'mood'),
          const SizedBox(height: 24),
          
          // Korrelations-Insights
          Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blue.shade900
                : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Erkannte Muster',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPatternItem(Icons.bedtime, 'Besserer Schlaf → Bessere Stimmung am nächsten Tag'),
                  _buildPatternItem(Icons.directions_walk, 'Mehr Schritte → Tieferer Schlaf'),
                  _buildPatternItem(Icons.water_drop, 'Mehr Wasser → Höhere Energie'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(color: Colors.orange, label: 'Kalorien'),
        _LegendItem(color: Colors.blue, label: 'Wasser'),
        _LegendItem(color: Colors.green, label: 'Schritte'),
        _LegendItem(color: Colors.purple, label: 'Schlaf'),
        _LegendItem(color: Colors.amber, label: 'Stimmung'),
      ],
    );
  }
  
  Widget _buildCombinedLineChart() {
    final days = _selectedPeriod == 'week' ? 7 : 30;
    
    // Normalisierte Daten für alle Metriken (0-100%)
    List<double> normalizeData(List<double> data) {
      final max = data.reduce((a, b) => a > b ? a : b);
      final min = data.reduce((a, b) => a < b ? a : b);
      if (max == min) return data.map((d) => 50.0).toList();
      return data.map((d) => ((d - min) / (max - min)) * 100).toList();
    }
    
    final caloriesData = normalizeData(_getDemoDataFor('calories', days));
    final waterData = normalizeData(_getDemoDataFor('water', days));
    final stepsData = normalizeData(_getDemoDataFor('steps', days));
    final sleepData = normalizeData(_getDemoDataFor('sleep', days));
    final moodData = normalizeData(_getDemoDataFor('mood', days));
    
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineBarsData: [
          _createLineData(caloriesData, Colors.orange),
          _createLineData(waterData, Colors.blue),
          _createLineData(stepsData, Colors.green),
          _createLineData(sleepData, Colors.purple),
          _createLineData(moodData, Colors.amber),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: _selectedPeriod == 'week',
              getTitlesWidget: (value, meta) {
                final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor param removed for compatibility
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)}%',
                  TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  
  LineChartBarData _createLineData(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
  
  List<double> _getDemoDataFor(String metric, int days) {
    switch (metric) {
      case 'calories':
        return List.generate(days, (i) => 1500 + (i * 47 % 700).toDouble());
      case 'water':
        return List.generate(days, (i) => 1800 + (i * 123 % 900).toDouble());
      case 'steps':
        return List.generate(days, (i) => 6000 + (i * 789 % 6000).toDouble());
      case 'sleep':
        return List.generate(days, (i) => 5.5 + (i * 0.3 % 3.5));
      case 'mood':
        return List.generate(days, (i) => 4 + (i * 0.7 % 5));
      default:
        return List.generate(days, (i) => i.toDouble());
    }
  }
  
  Widget _buildMiniChartCard(String title, IconData icon, Color color, String metric) {
    final days = _selectedPeriod == 'week' ? 7 : 30;
    final data = _getDemoDataFor(metric, days);
    final avg = data.reduce((a, b) => a + b) / data.length;
    
    String formattedAvg;
    switch (metric) {
      case 'calories':
        formattedAvg = '${avg.toStringAsFixed(0)} kcal';
        break;
      case 'water':
        formattedAvg = '${avg.toStringAsFixed(0)} ml';
        break;
      case 'steps':
        formattedAvg = avg.toStringAsFixed(0);
        break;
      case 'sleep':
        formattedAvg = '${avg.toStringAsFixed(1)}h';
        break;
      case 'mood':
        formattedAvg = '${avg.toStringAsFixed(1)}/10';
        break;
      default:
        formattedAvg = avg.toStringAsFixed(1);
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    'Ø $formattedAvg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              height: 40,
              child: LineChart(
                LineChartData(
                  minY: data.reduce((a, b) => a < b ? a : b) * 0.9,
                  maxY: data.reduce((a, b) => a > b ? a : b) * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                    ),
                  ],
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPatternItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedMetric) {
      case 'calories':
        return 'Kalorien pro Tag';
      case 'water':
        return 'Wasser pro Tag (ml)';
      case 'steps':
        return 'Schritte pro Tag';
      case 'sleep':
        return 'Schlaf pro Nacht (Stunden)';
      case 'mood':
        return 'Stimmung pro Tag';
      default:
        return 'Statistik';
    }
  }

  Color _getMetricColor() {
    switch (_selectedMetric) {
      case 'calories':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'steps':
        return Colors.green;
      case 'sleep':
        return Colors.purple;
      case 'mood':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  List<double> _getDemoData() {
    final days = _selectedPeriod == 'week' ? 7 : 30;
    
    switch (_selectedMetric) {
      case 'calories':
        return List.generate(days, (i) => 1500 + (i * 47 % 700).toDouble());
      case 'water':
        return List.generate(days, (i) => 1800 + (i * 123 % 900).toDouble());
      case 'steps':
        return List.generate(days, (i) => 6000 + (i * 789 % 6000).toDouble());
      case 'sleep':
        return List.generate(days, (i) => 5.5 + (i * 0.3 % 3.5));
      case 'mood':
        return List.generate(days, (i) => 4 + (i * 0.7 % 5));
      default:
        return List.generate(days, (i) => i.toDouble());
    }
  }

  Widget _buildChart() {
    final data = _getDemoData();
    final color = _getMetricColor();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.reduce((a, b) => a > b ? a : b) * 1.2,
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: color,
                width: _selectedPeriod == 'week' ? 30 : 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: _selectedPeriod == 'week',
              getTitlesWidget: (value, meta) {
                final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
                if (value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  String _getAverageValue() {
    final data = _getDemoData();
    final avg = data.reduce((a, b) => a + b) / data.length;
    
    switch (_selectedMetric) {
      case 'calories':
        return '${avg.toStringAsFixed(0)} kcal';
      case 'water':
        return '${avg.toStringAsFixed(0)} ml';
      case 'steps':
        return avg.toStringAsFixed(0);
      case 'sleep':
        return '${avg.toStringAsFixed(1)}h';
      case 'mood':
        return '${avg.toStringAsFixed(1)}/10';
      default:
        return avg.toStringAsFixed(1);
    }
  }

  String _getMaxValue() {
    final data = _getDemoData();
    final max = data.reduce((a, b) => a > b ? a : b);
    
    switch (_selectedMetric) {
      case 'calories':
        return '${max.toStringAsFixed(0)} kcal';
      case 'water':
        return '${max.toStringAsFixed(0)} ml';
      case 'steps':
        return max.toStringAsFixed(0);
      case 'sleep':
        return '${max.toStringAsFixed(1)}h';
      case 'mood':
        return '${max.toStringAsFixed(0)}/10';
      default:
        return max.toStringAsFixed(1);
    }
  }

  String _getMinValue() {
    final data = _getDemoData();
    final min = data.reduce((a, b) => a < b ? a : b);
    
    switch (_selectedMetric) {
      case 'calories':
        return '${min.toStringAsFixed(0)} kcal';
      case 'water':
        return '${min.toStringAsFixed(0)} ml';
      case 'steps':
        return min.toStringAsFixed(0);
      case 'sleep':
        return '${min.toStringAsFixed(1)}h';
      case 'mood':
        return '${min.toStringAsFixed(0)}/10';
      default:
        return min.toStringAsFixed(1);
    }
  }

  String _getTrendValue() {
    // Simplified trend calculation
    return '+5%';
  }

  String _getInsight() {
    switch (_selectedMetric) {
      case 'calories':
        return 'Deine durchschnittliche Kalorienaufnahme liegt im gesunden Bereich. Achte weiterhin auf eine ausgewogene Ernährung.';
      case 'water':
        return 'Du trinkst regelmäßig Wasser. Versuche, an heißen Tagen oder bei Sport noch mehr zu trinken.';
      case 'steps':
        return 'Deine Schrittzahl variiert. Versuche, täglich mindestens 8.000 Schritte zu gehen.';
      case 'sleep':
        return 'Dein Schlafrhythmus ist relativ konstant. Guter Schlaf ist wichtig für deine Gesundheit!';
      case 'mood':
        return 'Deine Stimmung ist überwiegend positiv. Weiter so!';
      default:
        return 'Analysiere deine Daten für wertvolle Einblicke.';
    }
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _MetricChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
