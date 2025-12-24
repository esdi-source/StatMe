/// Weight Screen - Gewichtsverlauf anzeigen und verwalten
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final weights = ref.watch(weightNotifierProvider);
    
    final sorted = [...weights]..sort((a, b) => b.date.compareTo(a.date));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gewicht'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWeightDialog(),
          ),
        ],
      ),
      body: weights.isEmpty
          ? _buildEmptyState(tokens)
          : _buildContent(tokens, sorted),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight,
            size: 64,
            color: tokens.textDisabled.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Gewichtseinträge',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddWeightDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Gewicht hinzufügen'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DesignTokens tokens, List<WeightEntry> weights) {
    final latest = weights.first;
    final oldest = weights.last;
    final totalChange = latest.weightKg - oldest.weightKg;
    
    // Calculate averages
    double? weekAvg;
    double? monthAvg;
    
    final now = DateTime.now();
    final weekEntries = weights.where((w) => 
      w.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final monthEntries = weights.where((w) => 
      w.date.isAfter(now.subtract(const Duration(days: 30)))).toList();
    
    if (weekEntries.isNotEmpty) {
      weekAvg = weekEntries.map((w) => w.weightKg).reduce((a, b) => a + b) / weekEntries.length;
    }
    if (monthEntries.isNotEmpty) {
      monthAvg = monthEntries.map((w) => w.weightKg).reduce((a, b) => a + b) / monthEntries.length;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats overview
        _buildStatsCard(tokens, latest, totalChange, weekAvg, monthAvg),
        const SizedBox(height: 16),
        
        // Simple chart visualization
        _buildSimpleChart(tokens, weights.take(14).toList().reversed.toList()),
        const SizedBox(height: 16),
        
        // Weight entries list
        _buildEntriesList(tokens, weights),
      ],
    );
  }

  Widget _buildStatsCard(
    DesignTokens tokens,
    WeightEntry latest,
    double totalChange,
    double? weekAvg,
    double? monthAvg,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tokens.primary.withOpacity(0.8),
            tokens.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktuell',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${latest.weightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      totalChange < 0 ? Icons.trending_down : 
                      totalChange > 0 ? Icons.trending_up : Icons.trending_flat,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (weekAvg != null)
                _buildStatItem('⌀ 7 Tage', '${weekAvg.toStringAsFixed(1)} kg'),
              if (weekAvg != null && monthAvg != null)
                const SizedBox(width: 24),
              if (monthAvg != null)
                _buildStatItem('⌀ 30 Tage', '${monthAvg.toStringAsFixed(1)} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleChart(DesignTokens tokens, List<WeightEntry> entries) {
    if (entries.length < 2) return const SizedBox.shrink();
    
    final minWeight = entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final maxWeight = entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final paddedRange = range == 0 ? 1.0 : range * 1.2;
    
    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verlauf (letzte 14 Einträge)',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _WeightChartPainter(
                entries: entries,
                minWeight: minWeight - paddedRange * 0.1,
                maxWeight: maxWeight + paddedRange * 0.1,
                lineColor: tokens.primary,
                pointColor: tokens.primary,
                gridColor: tokens.divider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(DesignTokens tokens, List<WeightEntry> entries) {
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
            'Einträge',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final weight = entry.value;
            double? change;
            if (index < entries.length - 1) {
              change = weight.weightKg - entries[index + 1].weightKg;
            }
            return _buildEntryTile(tokens, weight, change);
          }),
        ],
      ),
    );
  }

  Widget _buildEntryTile(DesignTokens tokens, WeightEntry entry, double? change) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: tokens.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(weightNotifierProvider.notifier).delete(entry.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.monitor_weight, color: tokens.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd.MM.yyyy').format(entry.date),
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty)
                    Text(
                      entry.note!,
                      style: TextStyle(
                        color: tokens.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.weightKg.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (change != null)
                  Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: change < 0 ? tokens.success : 
                             change > 0 ? tokens.error : tokens.textDisabled,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddWeightSheet(),
    );
  }
}

// ============================================
// ADD WEIGHT BOTTOM SHEET
// ============================================

class AddWeightSheet extends ConsumerStatefulWidget {
  const AddWeightSheet({super.key});

  @override
  ConsumerState<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<AddWeightSheet> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final latest = ref.read(weightNotifierProvider.notifier).latest;
    if (latest != null) {
      _weightController.text = latest.weightKg.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.textDisabled.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gewicht eintragen',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Weight input
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Gewicht (kg)',
              prefixIcon: const Icon(Icons.monitor_weight),
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          
          // Date picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today, color: tokens.primary),
            title: Text(DateFormat('dd.MM.yyyy').format(_date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _date = date);
              }
            },
          ),
          
          // Notes
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notizen (optional)',
              hintText: 'z.B. nach dem Frühstück...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gültiges Gewicht eingeben')),
      );
      return;
    }
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final now = DateTime.now();
    final entry = WeightEntry(
      id: now.millisecondsSinceEpoch.toString(),
      userId: user.id,
      weightKg: weight,
      date: _date,
      note: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: now,
      updatedAt: now,
    );
    
    await ref.read(weightNotifierProvider.notifier).add(entry);
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gewicht gespeichert!')),
      );
    }
  }
}

// ============================================
// SIMPLE WEIGHT CHART PAINTER
// ============================================

class _WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final double minWeight;
  final double maxWeight;
  final Color lineColor;
  final Color pointColor;
  final Color gridColor;

  _WeightChartPainter({
    required this.entries,
    required this.minWeight,
    required this.maxWeight,
    required this.lineColor,
    required this.pointColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;
    
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    
    final range = maxWeight - minWeight;
    
    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Calculate points
    final path = Path();
    final points = <Offset>[];
    
    for (int i = 0; i < entries.length; i++) {
      final x = i / (entries.length - 1) * size.width;
      final y = size.height - ((entries[i].weightKg - minWeight) / range) * size.height;
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    // Draw line
    canvas.drawPath(path, paint);
    
    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
