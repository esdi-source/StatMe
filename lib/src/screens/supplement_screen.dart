/// Supplement Screen - Nahrungsergänzungsmittel verwalten
/// Mit Kamera-Scan, Einnahme-Tracking und Wirkstoff-Statistiken

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class SupplementScreen extends ConsumerStatefulWidget {
  const SupplementScreen({super.key});

  @override
  ConsumerState<SupplementScreen> createState() => _SupplementScreenState();
}

class _SupplementScreenState extends ConsumerState<SupplementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Heute'),
            Tab(icon: Icon(Icons.medication), text: 'Meine'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistik'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSupplementDialog(context),
            tooltip: 'Supplement hinzufügen',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Bitte anmelden'))
          : TabBarView(
              controller: _tabController,
              children: [
                _TodayTab(
                  userId: user.id,
                  selectedDate: _selectedDate,
                  onDateChanged: (date) => setState(() => _selectedDate = date),
                ),
                _SupplementsTab(userId: user.id),
                _StatsTab(userId: user.id),
              ],
            ),
    );
  }

  void _showAddSupplementDialog(BuildContext context) {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSupplementSheet(userId: user.id),
    );
  }
}

// ============================================================================
// HEUTE TAB
// ============================================================================

class _TodayTab extends ConsumerWidget {
  final String userId;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _TodayTab({
    required this.userId,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplements = ref.watch(supplementsProvider(userId));
    final intakes = ref.watch(supplementIntakesProvider(userId));
    final activeSupplements = supplements.where((s) => !s.isPaused).toList();

    // Einnahmen für gewählten Tag
    final dayIntakes = intakes.where((i) {
      return i.timestamp.year == selectedDate.year &&
             i.timestamp.month == selectedDate.month &&
             i.timestamp.day == selectedDate.day;
    }).toList();

    return Column(
      children: [
        // Datum-Auswahl
        _DateSelector(
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),
        
        // Quick-Intake für heute
        if (_isToday(selectedDate)) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Schnelle Einnahme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox(
            height: 100,
            child: activeSupplements.isEmpty
                ? Center(
                    child: Text(
                      'Keine aktiven Supplements',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: activeSupplements.length,
                    itemBuilder: (context, index) {
                      final supp = activeSupplements[index];
                      final takenToday = dayIntakes.any((i) => i.supplementId == supp.id);
                      return _QuickIntakeCard(
                        supplement: supp,
                        takenToday: takenToday,
                        onTake: () => _takeNow(context, ref, supp),
                      );
                    },
                  ),
          ),
          const Divider(),
        ],

        // Einnahmen des Tages
        Expanded(
          child: dayIntakes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Einnahmen',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isToday(selectedDate)
                            ? 'Tippe auf ein Supplement oben'
                            : DateFormat('dd.MM.yyyy').format(selectedDate),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayIntakes.length,
                  itemBuilder: (context, index) {
                    final intake = dayIntakes[index];
                    final supplement = supplements.cast<Supplement?>().firstWhere(
                      (s) => s?.id == intake.supplementId,
                      orElse: () => null,
                    );
                    return _IntakeCard(
                      intake: intake,
                      supplement: supplement,
                      onDelete: () => _deleteIntake(context, ref, intake),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _takeNow(BuildContext context, WidgetRef ref, Supplement supplement) {
    final intake = SupplementIntake(
      id: const Uuid().v4(),
      oderId: userId,
      supplementId: supplement.id,
      timestamp: DateTime.now(),
      dosage: supplement.defaultDosage,
      createdAt: DateTime.now(),
    );
    ref.read(supplementIntakesProvider(userId).notifier).add(intake);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${supplement.name} eingenommen ✓'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteIntake(BuildContext context, WidgetRef ref, SupplementIntake intake) {
    ref.read(supplementIntakesProvider(userId).notifier).delete(intake.id);
  }
}

// ============================================================================
// DATUM-AUSWAHL
// ============================================================================

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) onDateChanged(date);
            },
            child: Column(
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEEE', 'de').format(selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                ? () => onDateChanged(selectedDate.add(const Duration(days: 1)))
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Heute';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Gestern';
    }
    return DateFormat('dd. MMMM', 'de').format(date);
  }
}

// ============================================================================
// QUICK INTAKE CARD
// ============================================================================

class _QuickIntakeCard extends StatelessWidget {
  final Supplement supplement;
  final bool takenToday;
  final VoidCallback onTake;

  const _QuickIntakeCard({
    required this.supplement,
    required this.takenToday,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(supplement.category.colorValue);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: takenToday ? Colors.green : color.withOpacity(0.3),
          width: takenToday ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTake,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Text(supplement.form.emoji, style: const TextStyle(fontSize: 28)),
                  if (takenToday)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                supplement.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: takenToday ? Colors.green.shade700 : Colors.grey.shade800,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// INTAKE CARD
// ============================================================================

class _IntakeCard extends StatelessWidget {
  final SupplementIntake intake;
  final Supplement? supplement;
  final VoidCallback onDelete;

  const _IntakeCard({
    required this.intake,
    this.supplement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = supplement != null 
        ? Color(supplement!.category.colorValue) 
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              supplement?.form.emoji ?? '💊',
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(supplement?.name ?? 'Unbekannt'),
        subtitle: Text(
          '${intake.dosage.toStringAsFixed(intake.dosage.truncateToDouble() == intake.dosage ? 0 : 1)} ${supplement?.dosageUnit ?? 'Einheit(en)'} • ${DateFormat('HH:mm').format(intake.timestamp)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Einnahme löschen?'),
                content: const Text('Diese Einnahme wird unwiderruflich gelöscht.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Löschen'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// SUPPLEMENTS TAB (Meine Supplements)
// ============================================================================

class _SupplementsTab extends ConsumerWidget {
  final String userId;

  const _SupplementsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplements = ref.watch(supplementsProvider(userId));
    
    if (supplements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Keine Supplements',
              style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Supplement hinzufügen'),
            ),
          ],
        ),
      );
    }

    // Gruppiert nach Kategorie
    final grouped = <SupplementCategory, List<Supplement>>{};
    for (final s in supplements) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final items = grouped[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ...items.map((s) => _SupplementCard(
              supplement: s,
              onEdit: () => _showEditDialog(context, s),
              onDelete: () => _deleteSupplement(context, ref, s),
              onTogglePause: () => _togglePause(ref, s),
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSupplementSheet(userId: userId),
    );
  }

  void _showEditDialog(BuildContext context, Supplement supplement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSupplementSheet(
        userId: userId,
        editSupplement: supplement,
      ),
    );
  }

  void _deleteSupplement(BuildContext context, WidgetRef ref, Supplement supplement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supplement löschen?'),
        content: Text('${supplement.name} und alle Einnahmen werden gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(supplementsProvider(userId).notifier).delete(supplement.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _togglePause(WidgetRef ref, Supplement supplement) {
    ref.read(supplementsProvider(userId).notifier).update(
      supplement.copyWith(
        isPaused: !supplement.isPaused,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

// ============================================================================
// SUPPLEMENT CARD
// ============================================================================

class _SupplementCard extends StatelessWidget {
  final Supplement supplement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePause;

  const _SupplementCard({
    required this.supplement,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(supplement.category.colorValue);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: supplement.isPaused ? Colors.grey.shade300 : color.withOpacity(0.3),
        ),
      ),
      child: Opacity(
        opacity: supplement.isPaused ? 0.6 : 1.0,
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(supplement.form.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  supplement.name,
                  style: TextStyle(
                    decoration: supplement.isPaused ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (supplement.isPaused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Pausiert',
                    style: TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (supplement.brand != null)
                Text(supplement.brand!, style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '${supplement.defaultDosage.toStringAsFixed(supplement.defaultDosage.truncateToDouble() == supplement.defaultDosage ? 0 : 1)} ${supplement.dosageUnit}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              if (supplement.ingredients.isNotEmpty)
                Text(
                  supplement.ingredients.take(3).map((i) => '${i.name}: ${i.formattedAmount}').join(', '),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          isThreeLine: true,
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Bearbeiten'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onTogglePause,
                child: Row(
                  children: [
                    Icon(supplement.isPaused ? Icons.play_arrow : Icons.pause),
                    const SizedBox(width: 8),
                    Text(supplement.isPaused ? 'Fortsetzen' : 'Pausieren'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onDelete,
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Löschen', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STATS TAB
// ============================================================================

class _StatsTab extends ConsumerWidget {
  final String userId;

  const _StatsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplements = ref.watch(supplementsProvider(userId));
    final intakes = ref.watch(supplementIntakesProvider(userId));
    final stats = SupplementStatistics.calculate(
      supplements: supplements,
      intakes: intakes,
      days: 7,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Übersicht
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Übersicht',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Aktiv',
                      value: '${stats.activeSupplements}',
                      icon: Icons.medication,
                      color: Colors.green,
                    ),
                    _StatItem(
                      label: 'Pausiert',
                      value: '${stats.pausedSupplements}',
                      icon: Icons.pause_circle,
                      color: Colors.orange,
                    ),
                    _StatItem(
                      label: 'Heute',
                      value: '${stats.todayIntakes}',
                      icon: Icons.today,
                      color: Colors.blue,
                    ),
                    _StatItem(
                      label: 'Woche',
                      value: '${stats.weekIntakes}',
                      icon: Icons.calendar_view_week,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // Wirkstoff-Statistik
        if (stats.ingredientStats.isNotEmpty) ...[
          const Text(
            'Wirkstoffe (7 Tage)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...stats.ingredientStats.entries.map((entry) {
            final ing = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('💊', style: TextStyle(fontSize: 20))),
                ),
                title: Text(ing.name),
                subtitle: Text('Ø ${ing.avgPerDay.toStringAsFixed(1)} ${ing.unit}/Tag'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ing.formattedTotal,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${ing.intakeCount}x',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        
        const SizedBox(height: 16),

        // Nach Kategorie
        if (stats.byCategory.isNotEmpty) ...[
          const Text(
            'Nach Kategorie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats.byCategory.entries.map((entry) {
              return Chip(
                avatar: Text(entry.key.emoji),
                label: Text('${entry.key.label}: ${entry.value}'),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ============================================================================
// ADD SUPPLEMENT SHEET
// ============================================================================

class _AddSupplementSheet extends ConsumerStatefulWidget {
  final String userId;
  final Supplement? editSupplement;

  const _AddSupplementSheet({
    required this.userId,
    this.editSupplement,
  });

  @override
  ConsumerState<_AddSupplementSheet> createState() => _AddSupplementSheetState();
}

class _AddSupplementSheetState extends ConsumerState<_AddSupplementSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _dosageController;
  late TextEditingController _dosageUnitController;
  late TextEditingController _notesController;
  
  SupplementCategory _category = SupplementCategory.vitamin;
  SupplementForm _form = SupplementForm.capsule;
  List<Ingredient> _ingredients = [];
  List<IntakeTime> _recommendedTimes = [];
  
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.editSupplement;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _brandController = TextEditingController(text: edit?.brand ?? '');
    _dosageController = TextEditingController(text: edit?.defaultDosage.toString() ?? '1');
    _dosageUnitController = TextEditingController(text: edit?.dosageUnit ?? 'Kapsel(n)');
    _notesController = TextEditingController(text: edit?.notes ?? '');
    
    if (edit != null) {
      _category = edit.category;
      _form = edit.form;
      _ingredients = List.from(edit.ingredients);
      _recommendedTimes = List.from(edit.recommendedTimes);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _dosageController.dispose();
    _dosageUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                Text(
                  widget.editSupplement != null ? 'Bearbeiten' : 'Neues Supplement',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Kamera-Scan Button
          if (widget.editSupplement == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _scanWithCamera,
                icon: _isScanning 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_isScanning ? 'Scanne...' : 'Mit Kamera scannen'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      hintText: 'z.B. Vitamin D3',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Bitte Namen eingeben' : null,
                  ),
                  const SizedBox(height: 16),

                  // Marke
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Marke (optional)',
                      hintText: 'z.B. Nature Made',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kategorie
                  DropdownButtonFormField<SupplementCategory>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Kategorie',
                      border: OutlineInputBorder(),
                    ),
                    items: SupplementCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Text(c.emoji),
                            const SizedBox(width: 8),
                            Text(c.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 16),

                  // Form
                  DropdownButtonFormField<SupplementForm>(
                    value: _form,
                    decoration: const InputDecoration(
                      labelText: 'Einnahmeform',
                      border: OutlineInputBorder(),
                    ),
                    items: SupplementForm.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Row(
                          children: [
                            Text(f.emoji),
                            const SizedBox(width: 8),
                            Text(f.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _form = v!),
                  ),
                  const SizedBox(height: 16),

                  // Dosierung
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Standard-Dosis',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _dosageUnitController,
                          decoration: const InputDecoration(
                            labelText: 'Einheit',
                            hintText: 'Kapsel(n)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Wirkstoffe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Wirkstoffe',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Hinzufügen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_ingredients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Keine Wirkstoffe angegeben',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._ingredients.asMap().entries.map((entry) {
                      final ing = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text(ing.name),
                          subtitle: Text(ing.formattedAmount),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() => _ingredients.removeAt(entry.key));
                            },
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Empfohlene Zeiten
                  const Text(
                    'Empfohlene Einnahmezeit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: IntakeTime.values.map((time) {
                      final selected = _recommendedTimes.contains(time);
                      return FilterChip(
                        label: Text('${time.emoji} ${time.label}'),
                        selected: selected,
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _recommendedTimes.add(time);
                            } else {
                              _recommendedTimes.remove(time);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Notizen
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notizen (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _AddIngredientDialog(
        onAdd: (ingredient) {
          setState(() => _ingredients.add(ingredient));
        },
      ),
    );
  }

  void _scanWithCamera() async {
    setState(() => _isScanning = true);
    
    // TODO: Implementiere Kamera-Scan mit OCR
    // Für jetzt zeigen wir einen Platzhalter-Dialog
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() => _isScanning = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kamera-Scan: OCR-Integration folgt'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final supplement = Supplement(
      id: widget.editSupplement?.id ?? const Uuid().v4(),
      userId: widget.userId,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      category: _category,
      form: _form,
      ingredients: _ingredients,
      defaultDosage: double.tryParse(_dosageController.text) ?? 1.0,
      dosageUnit: _dosageUnitController.text.trim(),
      recommendedTimes: _recommendedTimes,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isPaused: widget.editSupplement?.isPaused ?? false,
      createdAt: widget.editSupplement?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.editSupplement != null) {
      ref.read(supplementsProvider(widget.userId).notifier).update(supplement);
    } else {
      ref.read(supplementsProvider(widget.userId).notifier).add(supplement);
    }

    Navigator.pop(context);
  }
}

// ============================================================================
// ADD INGREDIENT DIALOG
// ============================================================================

class _AddIngredientDialog extends StatefulWidget {
  final ValueChanged<Ingredient> onAdd;

  const _AddIngredientDialog({required this.onAdd});

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _unit = 'mg';

  static const _units = ['mg', 'g', 'mcg', 'IU', 'ml', '%'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wirkstoff hinzufügen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'z.B. Vitamin D3',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Menge',
                    hintText: '1000',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Einheit',
                  ),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;
            widget.onAdd(Ingredient(
              id: const Uuid().v4(),
              name: _nameController.text.trim(),
              amountPerUnit: double.tryParse(_amountController.text) ?? 0,
              unit: _unit,
            ));
            Navigator.pop(context);
          },
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
