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

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedPeriod = 'week';
  String _selectedMetric = 'calories';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
      ),
      body: SingleChildScrollView(
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
              color: Colors.green.shade50,
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
