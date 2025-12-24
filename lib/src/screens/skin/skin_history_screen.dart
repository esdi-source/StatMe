/// Skin History Screen - Verlauf der Hauteinträge
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'skin_entry_screen.dart';

class SkinHistoryScreen extends ConsumerWidget {
  const SkinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final entries = ref.watch(skinEntriesNotifierProvider);
    
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    
    // Calculate stats
    final avgCondition = entries.isNotEmpty
        ? entries.map((e) => e.overallCondition.value).reduce((a, b) => a + b) / entries.length
        : null;
    
    // Most common attributes
    final Map<SkinAttribute, int> attrCount = {};
    for (final entry in entries) {
      for (final attr in entry.attributes) {
        attrCount[attr] = (attrCount[attr] ?? 0) + 1;
      }
    }
    final sortedAttrs = attrCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verlauf'),
      ),
      body: entries.isEmpty
          ? _buildEmptyState(tokens)
          : CustomScrollView(
              slivers: [
                // Stats header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatsCard(tokens, entries.length, avgCondition, sortedAttrs),
                  ),
                ),
                
                // Simple chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSimpleChart(tokens, sorted.take(14).toList().reversed.toList()),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Entries list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = sorted[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEntryCard(context, ref, tokens, entry),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: tokens.textDisabled.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Noch kein Verlauf',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    DesignTokens tokens,
    int totalEntries,
    double? avgCondition,
    List<MapEntry<SkinAttribute, int>> topAttrs,
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$totalEntries',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Einträge',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      if (avgCondition != null)
                        Text(
                          SkinCondition.values[(avgCondition.round() - 1).clamp(0, 4)].label,
                          style: const TextStyle(fontSize: 28),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        avgCondition?.toStringAsFixed(1) ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '⌀ Zustand',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (topAttrs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Häufigste Attribute',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: topAttrs.take(3).map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.key.label} ${entry.key.label} (${entry.value}x)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleChart(DesignTokens tokens, List<SkinEntry> entries) {
    if (entries.length < 2) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zustand (letzte 14 Tage)',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final value = entry.overallCondition.value;
                final height = (value / 5) * 80;
                
                return Tooltip(
                  message: '${DateFormat('dd.MM').format(entry.date)}: ${entry.overallCondition.label}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        entry.overallCondition.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: height,
                        decoration: BoxDecoration(
                          color: _getConditionColor(tokens, entry.overallCondition),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    DesignTokens tokens,
    SkinEntry entry,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SkinEntryScreen(date: entry.date, existingEntry: entry),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Row(
          children: [
            Text(
              entry.overallCondition.label,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd.MM.yyyy', 'de_DE').format(entry.date),
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (entry.attributes.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: entry.attributes.take(3).map((attr) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${attr.label} ${attr.label}',
                            style: TextStyle(
                              color: tokens.primary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (entry.note != null && entry.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.note!,
                        style: TextStyle(
                          color: tokens.textDisabled,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: tokens.textDisabled),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(DesignTokens tokens, SkinCondition condition) {
    switch (condition) {
      case SkinCondition.veryBad:
        return tokens.error;
      case SkinCondition.bad:
        return Colors.orange;
      case SkinCondition.neutral:
        return tokens.warning;
      case SkinCondition.good:
        return tokens.success;
      case SkinCondition.veryGood:
        return tokens.primary;
    }
  }
}
