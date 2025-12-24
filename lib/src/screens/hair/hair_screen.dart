/// Haarpflege (Hair Care) Haupt-Screen
/// 
/// Übersicht über:
/// - Heutige Pflege
/// - Wochenstatistik
/// - Letzte Ereignisse
/// - Produkte
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/hair_model.dart';
import 'hair_entry_screen.dart';
import 'hair_event_screen.dart';
import 'hair_products_screen.dart';
import 'hair_history_screen.dart';

class HairScreen extends ConsumerWidget {
  const HairScreen({super.key});

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
    final events = ref.watch(hairEventsProvider(user.id));
    final stats = ref.watch(hairCareStatisticsProvider(user.id));
    final todayEntry = ref.read(hairCareEntriesProvider(user.id).notifier).getForDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.content_cut, color: tokens.primary),
            const SizedBox(width: 8),
            const Text('Haarpflege'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _navigateToSubScreen(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'products', child: Text('Produkte')),
              const PopupMenuItem(value: 'events', child: Text('Ereignisse')),
              const PopupMenuItem(value: 'history', child: Text('Verlauf')),
            ],
          ),
        ],
      ),
      body: entries.isEmpty && events.isEmpty
          ? _buildEmptyState(context, tokens)
          : _buildContent(context, ref, tokens, todayEntry, stats, entries, events),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HairEntryScreen(date: DateTime.now())),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToSubScreen(BuildContext context, String value) {
    Widget screen;
    switch (value) {
      case 'products':
        screen = const HairProductsScreen();
        break;
      case 'events':
        screen = const HairEventScreen();
        break;
      case 'history':
        screen = const HairHistoryScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildEmptyState(BuildContext context, DesignTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_cut,
              size: 80,
              color: tokens.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Starte mit deiner Haarpflege',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dokumentiere deine Haarpflege-Routine und verfolge besondere Ereignisse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HairEntryScreen(date: DateTime.now())),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Ersten Eintrag erstellen'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HairEventScreen(addNew: true)),
              ),
              icon: const Icon(Icons.event),
              label: const Text('Ereignis hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DesignTokens tokens,
    HairCareEntry? todayEntry,
    HairCareStatistics stats,
    List<HairCareEntry> entries,
    List<HairEvent> events,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Heute Card
        _buildTodayCard(context, tokens, todayEntry),
        const SizedBox(height: 16),
        
        // Wochenstatistik
        _buildWeekStats(tokens, stats),
        const SizedBox(height: 16),
        
        // Letzte Ereignisse
        if (events.isNotEmpty) ...[
          _buildRecentEvents(context, tokens, events),
          const SizedBox(height: 16),
        ],
        
        // Letzte Einträge
        _buildRecentEntries(context, tokens, entries),
      ],
    );
  }

  Widget _buildTodayCard(BuildContext context, DesignTokens tokens, HairCareEntry? todayEntry) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HairEntryScreen(date: DateTime.now())),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.today, color: tokens.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Heute',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (todayEntry != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Eingetragen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(Icons.add_circle_outline, color: tokens.primary),
                ],
              ),
              const SizedBox(height: 12),
              if (todayEntry != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: todayEntry.careTypes.map((type) => Chip(
                    avatar: Text(type.emoji),
                    label: Text(type.label),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                if (todayEntry.customProducts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: todayEntry.customProducts.map((p) => Chip(
                      label: Text(p),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: tokens.primary.withOpacity(0.1),
                    )).toList(),
                  ),
                ],
              ] else
                Text(
                  'Tippen um Pflege einzutragen',
                  style: TextStyle(color: tokens.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekStats(DesignTokens tokens, HairCareStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: tokens.primary),
                const SizedBox(width: 8),
                Text(
                  'Letzte 7 Tage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(tokens, '🚿', '${stats.totalWashDays}', 'Gewaschen'),
                _buildStatItem(tokens, '🧴', '${stats.shampooDays}', 'Shampoo'),
                _buildStatItem(tokens, '💆', '${stats.conditionerDays}', 'Conditioner'),
                _buildStatItem(tokens, '💧', '${stats.waterOnlyDays}', 'Nur Wasser'),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.daysSinceLastWash >= 0) ...[
              _buildInfoRow(tokens, 'Letzte Wäsche', 
                stats.daysSinceLastWash == 0 ? 'Heute' : 'vor ${stats.daysSinceLastWash} Tagen'),
            ],
            if (stats.daysSinceLastHaircut >= 0)
              _buildInfoRow(tokens, 'Letzter Haarschnitt', 
                stats.daysSinceLastHaircut == 0 ? 'Heute' : 'vor ${stats.daysSinceLastHaircut} Tagen'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(DesignTokens tokens, String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: tokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(DesignTokens tokens, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: tokens.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: tokens.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildRecentEvents(BuildContext context, DesignTokens tokens, List<HairEvent> events) {
    final recentEvents = events.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayEvents = recentEvents.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: tokens.primary),
                const SizedBox(width: 8),
                Text(
                  'Letzte Ereignisse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HairEventScreen()),
                  ),
                  child: const Text('Alle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...displayEvents.map((event) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(event.eventType.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(event.title ?? event.eventType.label),
              subtitle: Text(DateFormat('dd.MM.yyyy', 'de_DE').format(event.date)),
              trailing: event.cost != null
                  ? Text('${event.cost!.toStringAsFixed(2)} €', 
                      style: TextStyle(color: tokens.textSecondary))
                  : null,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(BuildContext context, DesignTokens tokens, List<HairCareEntry> entries) {
    final recentEntries = entries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayEntries = recentEntries.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: tokens.primary),
                const SizedBox(width: 8),
                Text(
                  'Letzte Einträge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HairHistoryScreen()),
                  ),
                  child: const Text('Alle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (displayEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Noch keine Einträge',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ),
              )
            else
              ...displayEntries.map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tokens.primary.withOpacity(0.1),
                  child: Text(
                    entry.careTypes.isNotEmpty ? entry.careTypes.first.emoji : '📝',
                  ),
                ),
                title: Text(
                  entry.careTypes.map((t) => t.label).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(DateFormat('EEEE, dd.MM.', 'de_DE').format(entry.date)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HairEntryScreen(date: entry.date)),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
