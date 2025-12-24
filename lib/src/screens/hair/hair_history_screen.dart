/// Haarpflege Verlauf Screen
/// Zeigt alle Haarpflege-Einträge als Kalender/Liste
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/hair_model.dart';
import 'hair_entry_screen.dart';

class HairHistoryScreen extends ConsumerWidget {
  const HairHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final entries = ref.watch(hairCareEntriesProvider(user.id));
    final sortedEntries = entries.toList()..sort((a, b) => b.date.compareTo(a.date));

    // Gruppiere nach Monat
    final Map<String, List<HairCareEntry>> groupedByMonth = {};
    for (final entry in sortedEntries) {
      final monthKey = DateFormat('MMMM yyyy', 'de_DE').format(entry.date);
      groupedByMonth.putIfAbsent(monthKey, () => []);
      groupedByMonth[monthKey]!.add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verlauf'),
      ),
      body: sortedEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: tokens.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Einträge',
                    style: TextStyle(
                      fontSize: 18,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedByMonth.length,
              itemBuilder: (context, index) {
                final monthKey = groupedByMonth.keys.elementAt(index);
                final monthEntries = groupedByMonth[monthKey]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const SizedBox(height: 24),
                    _buildMonthHeader(tokens, monthKey, monthEntries.length),
                    const SizedBox(height: 8),
                    ...monthEntries.map((entry) => _buildEntryCard(context, tokens, entry)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildMonthHeader(DesignTokens tokens, String month, int count) {
    return Row(
      children: [
        Text(
          month,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: tokens.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count Einträge',
            style: TextStyle(
              fontSize: 12,
              color: tokens.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(BuildContext context, DesignTokens tokens, HairCareEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HairEntryScreen(date: entry.date)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Datum
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('d').format(entry.date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tokens.primary,
                      ),
                    ),
                    Text(
                      DateFormat('E', 'de_DE').format(entry.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      children: entry.careTypes.map((t) => Text(t.emoji)).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.careTypes.map((t) => t.label).join(', '),
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.customProducts.isNotEmpty)
                      Text(
                        '+ ${entry.customProducts.join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.textDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              Icon(Icons.chevron_right, color: tokens.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
