/// Gesichtshaut (Skin) Haupt-Screen - Container für alle Skin Sub-Widgets
/// 
/// Übersicht über:
/// - Heutiger Hautzustand
/// - Pflegeroutine-Status
/// - Letzte Einträge
/// - Verlauf
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'skin_entry_screen.dart';
import 'skin_routine_screen.dart';
import 'skin_products_screen.dart';
import 'skin_history_screen.dart';
import 'skin_photos_screen.dart';

class SkinScreen extends ConsumerStatefulWidget {
  const SkinScreen({super.key});

  @override
  ConsumerState<SkinScreen> createState() => _SkinScreenState();
}

class _SkinScreenState extends ConsumerState<SkinScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    await Future.wait([
      ref.read(skinEntriesNotifierProvider.notifier).load(user.id),
      ref.read(skinCareStepsNotifierProvider.notifier).load(user.id),
      ref.read(skinProductsNotifierProvider.notifier).load(user.id),
      ref.read(skinNotesNotifierProvider.notifier).load(user.id),
      ref.read(skinPhotosNotifierProvider.notifier).load(user.id),
      ref.read(skinCareCompletionsNotifierProvider.notifier).loadForDate(user.id, DateTime.now()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final entries = ref.watch(skinEntriesNotifierProvider);
    final steps = ref.watch(skinCareStepsNotifierProvider);
    final notes = ref.watch(skinNotesNotifierProvider);
    final completions = ref.watch(skinCareCompletionsNotifierProvider);
    
    final todayEntry = ref.read(skinEntriesNotifierProvider.notifier).getForDate(DateTime.now());
    final avgCondition = ref.read(skinEntriesNotifierProvider.notifier).getAverageCondition(7);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.face_retouching_natural, color: tokens.primary),
            const SizedBox(width: 8),
            const Text('Gesichtshaut'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _navigateToSubScreen(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'products', child: Text('Produkte')),
              const PopupMenuItem(value: 'photos', child: Text('Fotos')),
              const PopupMenuItem(value: 'history', child: Text('Verlauf')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: entries.isEmpty && steps.isEmpty
            ? _buildEmptyState(tokens)
            : _buildContent(tokens, todayEntry, avgCondition, steps, entries, notes, completions),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateTo(SkinEntryScreen(date: DateTime.now())),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToSubScreen(String value) {
    switch (value) {
      case 'products':
        _navigateTo(const SkinProductsScreen());
        break;
      case 'photos':
        _navigateTo(const SkinPhotosScreen());
        break;
      case 'history':
        _navigateTo(const SkinHistoryScreen());
        break;
    }
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural,
              size: 80,
              color: tokens.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Starte mit deiner Hautpflege',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dokumentiere deinen Hautzustand und verfolge deinen Fortschritt über Zeit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateTo(SkinEntryScreen(date: DateTime.now())),
              icon: const Icon(Icons.add),
              label: const Text('Ersten Eintrag erstellen'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _navigateTo(const SkinRoutineScreen()),
              icon: const Icon(Icons.spa),
              label: const Text('Pflegeroutine einrichten'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    DesignTokens tokens,
    SkinEntry? todayEntry,
    double? avgCondition,
    List<SkinCareStep> steps,
    List<SkinEntry> entries,
    List<SkinNote> notes,
    List<SkinCareCompletion> completions,
  ) {
    final dailySteps = steps.where((s) => s.isDaily).toList();
    final completedToday = completions.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today's condition
        _buildTodayCondition(tokens, todayEntry, avgCondition),
        const SizedBox(height: 16),
        
        // Routine progress
        if (dailySteps.isNotEmpty) ...[
          _buildRoutineProgress(tokens, dailySteps, completedToday),
          const SizedBox(height: 16),
        ],
        
        // Quick actions
        _buildQuickActions(tokens),
        const SizedBox(height: 16),
        
        // Recent entries
        if (entries.isNotEmpty) ...[
          _buildRecentEntries(tokens, entries),
          const SizedBox(height: 16),
        ],
        
        // Recent notes
        if (notes.isNotEmpty) ...[
          _buildRecentNotes(tokens, notes),
        ],
        
        const SizedBox(height: 80), // FAB spacing
      ],
    );
  }

  Widget _buildTodayCondition(DesignTokens tokens, SkinEntry? todayEntry, double? avgCondition) {
    final hasEntry = todayEntry != null;
    
    return GestureDetector(
      onTap: () => _navigateTo(SkinEntryScreen(date: DateTime.now(), existingEntry: todayEntry)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasEntry
                ? [tokens.primary.withOpacity(0.8), tokens.primary]
                : [tokens.surface, tokens.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          border: hasEntry ? null : Border.all(color: tokens.divider),
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
                      'Heute',
                      style: TextStyle(
                        color: hasEntry ? Colors.white.withOpacity(0.8) : tokens.textDisabled,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasEntry) ...[
                      Row(
                        children: [
                          Text(
                            todayEntry.overallCondition.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            todayEntry.overallCondition.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Noch kein Eintrag',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!hasEntry)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, color: tokens.primary),
                  ),
              ],
            ),
            if (avgCondition != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasEntry ? Colors.white.withOpacity(0.2) : tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⌀ 7 Tage: ${avgCondition.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: hasEntry ? Colors.white : tokens.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (hasEntry && todayEntry.attributes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: todayEntry.attributes.take(3).map((attr) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attr.label,
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
      ),
    );
  }

  Widget _buildRoutineProgress(DesignTokens tokens, List<SkinCareStep> dailySteps, int completedToday) {
    final progress = completedToday / dailySteps.length;
    
    return GestureDetector(
      onTap: () => _navigateTo(const SkinRoutineScreen()),
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa, color: tokens.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Pflegeroutine',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$completedToday/${dailySteps.length}',
                  style: TextStyle(
                    color: completedToday == dailySteps.length ? tokens.success : tokens.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: tokens.divider,
                valueColor: AlwaysStoppedAnimation(
                  completedToday == dailySteps.length ? tokens.success : tokens.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dailySteps.map((step) {
                // TODO: Implement via SkinCareCompletion provider
                final isCompleted = false;
                return GestureDetector(
                  onTap: () {
                    // TODO: Toggle completion via SkinCareCompletion
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? tokens.success.withOpacity(0.1)
                          : tokens.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted ? tokens.success : tokens.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          size: 16,
                          color: isCompleted ? tokens.success : tokens.textDisabled,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          step.name,
                          style: TextStyle(
                            color: isCompleted ? tokens.success : tokens.textPrimary,
                            fontSize: 12,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(DesignTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            tokens,
            Icons.spa,
            'Routine',
            'Bearbeiten',
            () => _navigateTo(const SkinRoutineScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            tokens,
            Icons.inventory_2,
            'Produkte',
            'Verwalten',
            () => _navigateTo(const SkinProductsScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            tokens,
            Icons.timeline,
            'Verlauf',
            'Ansehen',
            () => _navigateTo(const SkinHistoryScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    DesignTokens tokens,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: tokens.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: tokens.textDisabled,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(DesignTokens tokens, List<SkinEntry> entries) {
    final recent = ([...entries]..sort((a, b) => b.date.compareTo(a.date))).take(5).toList();
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Letzte Einträge',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => _navigateTo(const SkinHistoryScreen()),
                child: const Text('Alle'),
              ),
            ],
          ),
          const Divider(),
          ...recent.map((entry) => _buildEntryTile(tokens, entry)),
        ],
      ),
    );
  }

  Widget _buildEntryTile(DesignTokens tokens, SkinEntry entry) {
    return GestureDetector(
      onTap: () => _navigateTo(SkinEntryScreen(date: entry.date, existingEntry: entry)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              entry.overallCondition.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd.MM.', 'de_DE').format(entry.date),
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.attributes.isNotEmpty)
                    Text(
                      entry.attributes.map((a) => a.label).join(', '),
                      style: TextStyle(
                        color: tokens.textDisabled,
                        fontSize: 12,
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
    );
  }

  Widget _buildRecentNotes(DesignTokens tokens, List<SkinNote> notes) {
    final recent = ref.read(skinNotesNotifierProvider.notifier).getRecent(3);
    
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
            'Notizen',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          ...recent.map((note) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, color: tokens.textDisabled, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.content,
                        style: TextStyle(color: tokens.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy').format(note.date),
                        style: TextStyle(
                          color: tokens.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
