/// Verdauung / Toilette Screen
/// Dokumentiert Stuhlgang und Toilettengänge mit Verknüpfungen zu Essen, Trinken und Stimmung

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../ui/theme/design_tokens.dart';

class DigestionScreen extends ConsumerStatefulWidget {
  const DigestionScreen({super.key});

  @override
  ConsumerState<DigestionScreen> createState() => _DigestionScreenState();
}

class _DigestionScreenState extends ConsumerState<DigestionScreen> {
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    await ref.read(digestionEntriesProvider(user.id).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final tokens = ref.watch(designTokensProvider);
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final entries = ref.watch(digestionEntriesProvider(user.id));
    final todayEntries = entries.where((e) =>
      e.timestamp.year == _selectedDate.year &&
      e.timestamp.month == _selectedDate.month &&
      e.timestamp.day == _selectedDate.day
    ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verdauung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Statistiken',
            onPressed: () => _showStatistics(context, entries, tokens),
          ),
        ],
      ),
      body: Column(
        children: [
          // Datumsauswahl
          _buildDateSelector(tokens),
          
          // Tagesübersicht
          _buildDaySummary(todayEntries, tokens),
          
          // Einträge-Liste
          Expanded(
            child: todayEntries.isEmpty
                ? _buildEmptyState(tokens)
                : _buildEntriesList(todayEntries, user.id, tokens),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context, user.id, tokens),
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
        backgroundColor: tokens.primary,
      ),
    );
  }

  Widget _buildDateSelector(DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Text(
                _formatDate(_selectedDate),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                ? () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummary(List<DigestionEntry> entries, DesignTokens tokens) {
    final stoolCount = entries.where((e) => 
      e.type == ToiletType.stool || e.type == ToiletType.both
    ).length;
    final urinationCount = entries.where((e) => 
      e.type == ToiletType.urination || e.type == ToiletType.both
    ).length;
    
    // Durchschnittliche Konsistenz
    final stoolEntries = entries.where((e) => e.consistency != null).toList();
    final avgConsistency = stoolEntries.isEmpty ? null :
        stoolEntries.map((e) => e.consistency!.value).reduce((a, b) => a + b) / stoolEntries.length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        boxShadow: tokens.shadowSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            '💩',
            stoolCount.toString(),
            'Stuhlgang',
            tokens,
          ),
          Container(width: 1, height: 40, color: tokens.divider),
          _buildSummaryItem(
            '🚽',
            urinationCount.toString(),
            'Wasserlassen',
            tokens,
          ),
          Container(width: 1, height: 40, color: tokens.divider),
          _buildSummaryItem(
            avgConsistency != null ? _getConsistencyIndicator(avgConsistency) : '❓',
            avgConsistency?.toStringAsFixed(1) ?? '-',
            'Konsistenz',
            tokens,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label, DesignTokens tokens) {
    return Column(
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
            fontSize: 12,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getConsistencyIndicator(double avg) {
    if (avg <= 1.5) return '🔴';
    if (avg <= 2.5) return '🟠';
    if (avg <= 4.5) return '🟢';
    if (avg <= 5.5) return '🟠';
    return '🔴';
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 64,
            color: tokens.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Einträge für diesen Tag',
            style: TextStyle(
              fontSize: 16,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf + um einen Eintrag hinzuzufügen',
            style: TextStyle(
              fontSize: 14,
              color: tokens.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<DigestionEntry> entries, String userId, DesignTokens tokens) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryCard(entry, userId, tokens);
      },
    );
  }

  Widget _buildEntryCard(DigestionEntry entry, String userId, DesignTokens tokens) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEntryDetails(entry, tokens),
        onLongPress: () => _showEntryOptions(entry, userId, tokens),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(tokens.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    entry.mainEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.type.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          entry.timeString,
                          style: TextStyle(
                            fontSize: 14,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (entry.consistency != null) ...[
                          _buildTag(entry.consistency!.label, entry.consistency!.indicator, tokens),
                          const SizedBox(width: 8),
                        ],
                        if (entry.amount != null)
                          _buildTag(entry.amount!.label, entry.amount!.emoji, tokens),
                        if (entry.hasPain) ...[
                          const SizedBox(width: 8),
                          _buildTag('Schmerzen', '😣', tokens),
                        ],
                        if (entry.hasBloating) ...[
                          const SizedBox(width: 8),
                          _buildTag('Blähungen', '💨', tokens),
                        ],
                      ],
                    ),
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.note!,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, String emoji, DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, String userId, DesignTokens tokens) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddDigestionEntrySheet(
        userId: userId,
        selectedDate: _selectedDate,
        onSave: (entry) {
          ref.read(digestionEntriesProvider(userId).notifier).add(entry);
          Navigator.pop(context);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showEntryDetails(DigestionEntry entry, DesignTokens tokens) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.mainEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.type.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(entry.timestamp),
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (entry.consistency != null)
              _buildDetailRow('Konsistenz', entry.consistency!.label, entry.consistency!.indicator, tokens),
            if (entry.amount != null)
              _buildDetailRow('Menge', entry.amount!.label, entry.amount!.emoji, tokens),
            _buildDetailRow('Gefühl', entry.feeling.label, entry.feeling.emoji, tokens),
            if (entry.hasPain)
              _buildDetailRow('Schmerzen', 'Ja', '😣', tokens),
            if (entry.hasBloating)
              _buildDetailRow('Blähungen', 'Ja', '💨', tokens),
            if (entry.hasUrgency)
              _buildDetailRow('Dringlichkeit', 'Hoch', '⚡', tokens),
            if (entry.waterIntakeLast24h != null)
              _buildDetailRow('Wasser (24h)', '${entry.waterIntakeLast24h} ml', '💧', tokens),
            if (entry.stressLevel != null)
              _buildDetailRow('Stress-Level', '${entry.stressLevel}/10', '😰', tokens),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notiz',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.note!,
                style: TextStyle(
                  fontSize: 15,
                  color: tokens.textPrimary,
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, String emoji, DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryOptions(DigestionEntry entry, String userId, DesignTokens tokens) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Löschen', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(digestionEntriesProvider(userId).notifier).delete(entry.id);
                HapticFeedback.lightImpact();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics(BuildContext context, List<DigestionEntry> entries, DesignTokens tokens) {
    // Berechne Statistiken der letzten 7 Tage
    final now = DateTime.now();
    final week = entries.where((e) => 
      e.timestamp.isAfter(now.subtract(const Duration(days: 7)))
    ).toList();
    
    final avgPerDay = week.length / 7;
    final stoolEntries = week.where((e) => e.consistency != null).toList();
    final avgConsistency = stoolEntries.isEmpty ? null :
        stoolEntries.map((e) => e.consistency!.value).reduce((a, b) => a + b) / stoolEntries.length;
    
    // Häufigste Probleme
    final painCount = week.where((e) => e.hasPain).length;
    final bloatingCount = week.where((e) => e.hasBloating).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Wochenstatistik',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Letzte 7 Tage',
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(height: 24),
              
              // Statistik-Karten
              Row(
                children: [
                  Expanded(child: _buildStatCard('📊', '${avgPerDay.toStringAsFixed(1)}', 'Ø pro Tag', tokens)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('🎯', avgConsistency?.toStringAsFixed(1) ?? '-', 'Ø Konsistenz', tokens)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('😣', '$painCount', 'Mit Schmerzen', tokens)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('💨', '$bloatingCount', 'Mit Blähungen', tokens)),
                ],
              ),
              
              const SizedBox(height: 24),
              Text(
                'Konsistenz-Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildConsistencyLegend(tokens),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        boxShadow: tokens.shadowSmall,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyLegend(DesignTokens tokens) {
    return Column(
      children: StoolConsistency.values.map((c) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(c.indicator, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Text(
                '${c.value}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                c.label,
                style: TextStyle(color: tokens.textSecondary),
              ),
              if (c.isHealthy) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Normal',
                    style: TextStyle(
                      fontSize: 10,
                      color: tokens.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    
    if (selected == today) return 'Heute';
    if (selected == today.subtract(const Duration(days: 1))) return 'Gestern';
    
    return DateFormat('EEEE, d. MMMM', 'de').format(date);
  }
}

// ============================================================================
// ADD ENTRY SHEET
// ============================================================================

class _AddDigestionEntrySheet extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;
  final Function(DigestionEntry) onSave;

  const _AddDigestionEntrySheet({
    required this.userId,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<_AddDigestionEntrySheet> createState() => _AddDigestionEntrySheetState();
}

class _AddDigestionEntrySheetState extends State<_AddDigestionEntrySheet> {
  ToiletType _type = ToiletType.stool;
  StoolConsistency _consistency = StoolConsistency.normal;
  StoolAmount _amount = StoolAmount.medium;
  PostFeeling _feeling = PostFeeling.neutral;
  bool _hasPain = false;
  bool _hasBloating = false;
  bool _hasUrgency = false;
  TimeOfDay _time = TimeOfDay.now();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final tokens = ref.watch(designTokensProvider);
        
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'Neuer Eintrag',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Zeit
                _buildSection('Uhrzeit', tokens),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (time != null) {
                      setState(() => _time = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.background,
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 12),
                        Text(
                          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Art
                _buildSection('Art', tokens),
                _buildTypeSelector(tokens),
                const SizedBox(height: 20),
                
                // Konsistenz (nur bei Stuhlgang)
                if (_type != ToiletType.urination) ...[
                  _buildSection('Konsistenz', tokens),
                  _buildConsistencySelector(tokens),
                  const SizedBox(height: 20),
                  
                  // Menge
                  _buildSection('Menge', tokens),
                  _buildAmountSelector(tokens),
                  const SizedBox(height: 20),
                ],
                
                // Gefühl
                _buildSection('Gefühl danach', tokens),
                _buildFeelingSelector(tokens),
                const SizedBox(height: 20),
                
                // Symptome
                _buildSection('Symptome', tokens),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSymptomChip('Schmerzen', '😣', _hasPain, 
                        (v) => setState(() => _hasPain = v), tokens),
                    _buildSymptomChip('Blähungen', '💨', _hasBloating, 
                        (v) => setState(() => _hasBloating = v), tokens),
                    _buildSymptomChip('Dringlichkeit', '⚡', _hasUrgency, 
                        (v) => setState(() => _hasUrgency = v), tokens),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Notiz
                _buildSection('Notiz (optional)', tokens),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Auffälligkeiten, Zusammenhänge...',
                    filled: true,
                    fillColor: tokens.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                
                // Speichern
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMedium),
                      ),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tokens.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTypeSelector(DesignTokens tokens) {
    return Row(
      children: ToiletType.values.map((type) {
        final isSelected = _type == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? tokens.primary : tokens.background,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Column(
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : tokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsistencySelector(DesignTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StoolConsistency.values.map((c) {
          final isSelected = _consistency == c;
          return GestureDetector(
            onTap: () => setState(() => _consistency = c),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? tokens.primary : tokens.background,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                border: Border.all(
                  color: isSelected ? tokens.primary : tokens.divider,
                ),
              ),
              child: Row(
                children: [
                  Text(c.indicator),
                  const SizedBox(width: 6),
                  Text(
                    '${c.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : tokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmountSelector(DesignTokens tokens) {
    return Row(
      children: StoolAmount.values.map((a) {
        final isSelected = _amount == a;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _amount = a),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? tokens.primary : tokens.background,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Column(
                children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    a.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeelingSelector(DesignTokens tokens) {
    return Row(
      children: PostFeeling.values.map((f) {
        final isSelected = _feeling == f;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _feeling = f),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? tokens.primary : tokens.background,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Column(
                children: [
                  Text(f.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : tokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymptomChip(String label, String emoji, bool selected, 
      Function(bool) onChanged, DesignTokens tokens) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.warning.withOpacity(0.2) : tokens.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? tokens.warning : tokens.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? tokens.warning : tokens.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final now = DateTime.now();
    final timestamp = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _time.hour,
      _time.minute,
    );
    
    final entry = DigestionEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      oderId: widget.userId,
      timestamp: timestamp,
      type: _type,
      consistency: _type != ToiletType.urination ? _consistency : null,
      amount: _type != ToiletType.urination ? _amount : null,
      feeling: _feeling,
      hasPain: _hasPain,
      hasBloating: _hasBloating,
      hasUrgency: _hasUrgency,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      createdAt: now,
      updatedAt: now,
    );
    
    widget.onSave(entry);
  }
}
