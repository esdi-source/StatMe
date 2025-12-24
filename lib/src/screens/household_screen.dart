/// Household Screen - Haushaltsaufgaben verwalten
/// Mit flexiblen Aufgaben, Wiederkehr-Logik und Statistiken
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Haushalt'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Heute'),
            Tab(icon: Icon(Icons.list_alt), text: 'Aufgaben'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistik'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTaskSheet(context),
            tooltip: 'Aufgabe hinzufügen',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Bitte anmelden'))
          : TabBarView(
              controller: _tabController,
              children: [
                _TodayTab(userId: user.id),
                _AllTasksTab(userId: user.id),
                _StatsTab(userId: user.id),
              ],
            ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddTaskSheet(),
    );
  }
}

// ============================================================================
// TODAY TAB - Heute fällige Aufgaben
// ============================================================================

class _TodayTab extends ConsumerWidget {
  final String userId;

  const _TodayTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(householdTasksProvider(userId));
    final completions = ref.watch(householdCompletionsProvider(userId));

    // Berechne Status für jede Aufgabe
    final tasksWithStatus = tasks
        .where((t) => !t.isPaused)
        .map((t) => TaskWithStatus.calculate(t, completions))
        .toList();

    // Sortiere: Überfällig > Heute fällig > Bald fällig
    tasksWithStatus.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.isDueToday && !b.isDueToday) return -1;
      if (!a.isDueToday && b.isDueToday) return 1;
      return (a.daysUntilDue ?? 999).compareTo(b.daysUntilDue ?? 999);
    });

    final overdue = tasksWithStatus.where((t) => t.isOverdue).toList();
    final dueToday = tasksWithStatus.where((t) => t.isDueToday).toList();
    final upcoming = tasksWithStatus.where((t) => !t.isOverdue && !t.isDueToday && t.daysUntilDue != null && t.daysUntilDue! <= 3).toList();

    // Heute erledigte
    final now = DateTime.now();
    final todayCompleted = completions.where((c) {
      final d = c.completedAt;
      return d.year == now.year && d.month == now.month && d.day == now.day && !c.wasSkipped;
    }).length;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Noch keine Aufgaben',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf + um Aufgaben hinzuzufügen',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header mit Tagesfortschritt
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$todayCompleted',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Heute erledigt',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${overdue.length + dueToday.length} noch offen',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (overdue.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${overdue.length} überfällig',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Überfällige Aufgaben
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionHeader(title: '⚠️ Überfällig', color: Colors.red),
          ...overdue.map((t) => _TaskCard(taskStatus: t, userId: userId)),
        ],

        // Heute fällig
        if (dueToday.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionHeader(title: '📅 Heute fällig', color: Colors.orange),
          ...dueToday.map((t) => _TaskCard(taskStatus: t, userId: userId)),
        ],

        // Bald fällig
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionHeader(title: '📆 Bald fällig', color: Colors.blue),
          ...upcoming.map((t) => _TaskCard(taskStatus: t, userId: userId)),
        ],

        if (overdue.isEmpty && dueToday.isEmpty && upcoming.isEmpty) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
                const SizedBox(height: 16),
                Text(
                  'Alles erledigt! 🎉',
                  style: TextStyle(fontSize: 18, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keine offenen Aufgaben für heute',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskWithStatus taskStatus;
  final String userId;

  const _TaskCard({required this.taskStatus, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = taskStatus.task;
    final isOverdue = taskStatus.isOverdue;
    final categoryColor = Color(task.category.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue ? BorderSide(color: Colors.red.shade300, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCompleteDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Kategorie-Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(task.category.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (task.room != null) ...[
                          Text(
                            '${task.room!.emoji} ${task.room!.label}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (task.estimatedMinutes != null) ...[
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(
                            '${task.estimatedMinutes} Min',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status-Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isOverdue && taskStatus.daysOverdue != null)
                    Text(
                      '${taskStatus.daysOverdue} Tag${taskStatus.daysOverdue! > 1 ? 'e' : ''} überfällig',
                      style: TextStyle(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  else if (taskStatus.isDueToday)
                    Text(
                      'Heute',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  else if (taskStatus.daysUntilDue != null)
                    Text(
                      'in ${taskStatus.daysUntilDue} Tag${taskStatus.daysUntilDue! > 1 ? 'en' : ''}',
                      style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    int? actualMinutes;
    int? effortRating;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(taskStatus.task.category.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              taskStatus.task.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              taskStatus.task.category.label,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tatsächliche Zeit
                  const Text('Zeit (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final mins in [5, 10, 15, 30, 45, 60])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${mins}m'),
                            selected: actualMinutes == mins,
                            onSelected: (sel) => setModalState(() => actualMinutes = sel ? mins : null),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Anstrengung
                  const Text('Wie anstrengend? (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return GestureDetector(
                        onTap: () => setModalState(() => effortRating = effortRating == rating ? null : rating),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: effortRating == rating ? Colors.blue.shade100 : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: effortRating == rating ? Border.all(color: Colors.blue, width: 2) : null,
                          ),
                          child: Text(
                            '$rating',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: effortRating == rating ? Colors.blue.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Überspringen
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _completeTask(ref, wasSkipped: true);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.skip_next),
                          label: const Text('Überspringen'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Erledigt
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            _completeTask(ref, actualMinutes: actualMinutes, effortRating: effortRating);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Erledigt'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _completeTask(WidgetRef ref, {int? actualMinutes, int? effortRating, bool wasSkipped = false}) {
    final completion = TaskCompletion(
      id: const Uuid().v4(),
      taskId: taskStatus.task.id,
      userId: userId,
      completedAt: DateTime.now(),
      actualMinutes: actualMinutes ?? taskStatus.task.estimatedMinutes,
      effortRating: effortRating,
      wasSkipped: wasSkipped,
    );

    ref.read(householdCompletionsProvider(userId).notifier).add(completion);
  }
}

// ============================================================================
// ALL TASKS TAB - Alle Aufgaben verwalten
// ============================================================================

class _AllTasksTab extends ConsumerWidget {
  final String userId;

  const _AllTasksTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(householdTasksProvider(userId));

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Keine Aufgaben angelegt',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Nach Kategorie gruppieren
    final byCategory = <HouseholdCategory, List<HouseholdTask>>{};
    for (final cat in HouseholdCategory.values) {
      final catTasks = tasks.where((t) => t.category == cat).toList();
      if (catTasks.isNotEmpty) {
        byCategory[cat] = catTasks;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(entry.key.colorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(entry.key.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.key.label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${entry.value.length} Aufgabe${entry.value.length > 1 ? 'n' : ''}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ...entry.value.map((task) => _TaskListTile(task: task, userId: userId)),
        ],
      ],
    );
  }
}

class _TaskListTile extends ConsumerWidget {
  final HouseholdTask task;
  final String userId;

  const _TaskListTile({required this.task, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: task.isPaused
            ? Icon(Icons.pause_circle, color: Colors.orange.shade400)
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(task.category.colorValue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(task.category.emoji),
              ),
        title: Text(
          task.name,
          style: TextStyle(
            decoration: task.isPaused ? TextDecoration.lineThrough : null,
            color: task.isPaused ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(task.frequency.label),
            if (task.frequency == TaskFrequency.everyXDays && task.frequencyDays != null)
              Text(' (${task.frequencyDays} Tage)'),
            if (task.estimatedMinutes != null) ...[
              const Text(' • '),
              Text('${task.estimatedMinutes} Min'),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, ref, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: task.isPaused ? 'resume' : 'pause',
              child: Row(
                children: [
                  Icon(task.isPaused ? Icons.play_arrow : Icons.pause),
                  const SizedBox(width: 8),
                  Text(task.isPaused ? 'Fortsetzen' : 'Pausieren'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Bearbeiten'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
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
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'pause':
      case 'resume':
        ref.read(householdTasksProvider(userId).notifier).update(
              task.copyWith(isPaused: !task.isPaused, updatedAt: DateTime.now()),
            );
        break;
      case 'edit':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _AddTaskSheet(editTask: task),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Aufgabe löschen?'),
            content: Text('„${task.name}" wird gelöscht.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(householdTasksProvider(userId).notifier).delete(task.id);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

// ============================================================================
// STATS TAB - Statistiken
// ============================================================================

class _StatsTab extends ConsumerWidget {
  final String userId;

  const _StatsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(householdStatisticsProvider(userId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Routine-Score
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Routine-Score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: stats.routineScore / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          stats.routineScore >= 80
                              ? Colors.green
                              : stats.routineScore >= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${stats.routineScore.round()}%',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stats.routineScore >= 80
                      ? 'Super! Du hältst deine Routine!'
                      : stats.routineScore >= 50
                          ? 'Gut, aber Luft nach oben'
                          : 'Einige Aufgaben sind überfällig',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Übersichts-Karten
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Heute',
                value: '${stats.completedToday}',
                subtitle: '${stats.totalMinutesToday} Min',
                icon: Icons.today,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Diese Woche',
                value: '${stats.completedThisWeek}',
                subtitle: '${stats.totalMinutesThisWeek} Min',
                icon: Icons.calendar_today,
                color: Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Überfällig',
                value: '${stats.overdueCount}',
                subtitle: 'Aufgaben',
                icon: Icons.warning,
                color: stats.overdueCount > 0 ? Colors.red : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Ø Anstrengung',
                value: stats.avgEffortRating > 0 ? stats.avgEffortRating.toStringAsFixed(1) : '-',
                subtitle: 'von 5',
                icon: Icons.fitness_center,
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Erledigungen pro Tag (letzte 7 Tage)
        if (stats.completionsByDay.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Letzte 7 Tage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: stats.completionsByDay.entries.map((entry) {
                        final maxVal = stats.completionsByDay.values.fold(1, (a, b) => a > b ? a : b);
                        final height = entry.value / maxVal * 60;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.value}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 30,
                              height: height.clamp(4, 60).toDouble(),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.key,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Nach Kategorie
        if (stats.completionsByCategory.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diese Woche nach Kategorie',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...stats.completionsByCategory.entries.map((entry) {
                    final total = stats.completedThisWeek;
                    final percent = total > 0 ? entry.value / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(entry.key.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key.label),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(Color(entry.key.colorValue)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ADD/EDIT TASK SHEET
// ============================================================================

class _AddTaskSheet extends ConsumerStatefulWidget {
  final HouseholdTask? editTask;

  const _AddTaskSheet({this.editTask});

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  HouseholdCategory _category = HouseholdCategory.cleaning;
  TaskFrequency _frequency = TaskFrequency.weekly;
  int _frequencyDays = 3;
  int? _estimatedMinutes;
  EnergyLevel? _energyLevel;
  HouseholdRoom? _room;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    if (widget.editTask != null) {
      final task = widget.editTask!;
      _nameController.text = task.name;
      _notesController.text = task.notes ?? '';
      _category = task.category;
      _frequency = task.frequency;
      _frequencyDays = task.frequencyDays ?? 3;
      _estimatedMinutes = task.estimatedMinutes;
      _energyLevel = task.energyLevel;
      _room = task.room;
      _showSuggestions = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isEditing = widget.editTask != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      isEditing ? 'Aufgabe bearbeiten' : 'Neue Aufgabe',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Vorschläge
                if (!isEditing && _showSuggestions) ...[
                  const Text('Vorschläge', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final cat in HouseholdCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _SuggestionCategory(
                              category: cat,
                              onSelect: (template) {
                                setState(() {
                                  _nameController.text = template.name;
                                  _category = template.category;
                                  _frequency = template.suggestedFrequency;
                                  _estimatedMinutes = template.suggestedMinutes;
                                  _energyLevel = template.suggestedEnergy;
                                  _room = template.suggestedRoom;
                                  _showSuggestions = false;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                ],

                // Name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name der Aufgabe *',
                    hintText: 'z. B. Staubsaugen',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 16),

                // Kategorie
                const Text('Kategorie', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HouseholdCategory.values.map((cat) {
                    final isSelected = _category == cat;
                    return ChoiceChip(
                      avatar: Text(cat.emoji),
                      label: Text(cat.label),
                      selected: isSelected,
                      selectedColor: Color(cat.colorValue).withOpacity(0.3),
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Häufigkeit
                const Text('Häufigkeit', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskFrequency.values.map((freq) {
                    return ChoiceChip(
                      label: Text(freq.label),
                      selected: _frequency == freq,
                      onSelected: (_) => setState(() => _frequency = freq),
                    );
                  }).toList(),
                ),
                if (_frequency == TaskFrequency.everyXDays) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Alle '),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          controller: TextEditingController(text: '$_frequencyDays'),
                          onChanged: (val) {
                            final v = int.tryParse(val);
                            if (v != null && v > 0) {
                              _frequencyDays = v;
                            }
                          },
                        ),
                      ),
                      const Text(' Tage'),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Zeit
                const Text('Geschätzte Zeit (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mins in [5, 10, 15, 20, 30, 45, 60, 90, 120])
                      ChoiceChip(
                        label: Text('$mins Min'),
                        selected: _estimatedMinutes == mins,
                        onSelected: (sel) => setState(() => _estimatedMinutes = sel ? mins : null),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Energie
                const Text('Energieaufwand (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: EnergyLevel.values.map((level) {
                    return ChoiceChip(
                      avatar: Text(level.emoji),
                      label: Text(level.label),
                      selected: _energyLevel == level,
                      onSelected: (sel) => setState(() => _energyLevel = sel ? level : null),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Raum
                const Text('Raum (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<HouseholdRoom?>(
                  initialValue: _room,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Raum auswählen',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Kein Raum')),
                    ...HouseholdRoom.values.map((room) => DropdownMenuItem(
                          value: room,
                          child: Row(
                            children: [
                              Text(room.emoji),
                              const SizedBox(width: 8),
                              Text(room.label),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (val) => setState(() => _room = val),
                ),

                const SizedBox(height: 16),

                // Notizen
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notizen (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Speichern
                FilledButton.icon(
                  onPressed: _nameController.text.trim().isEmpty || user == null
                      ? null
                      : () => _save(user.id),
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Speichern' : 'Aufgabe hinzufügen'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _save(String userId) {
    final now = DateTime.now();

    if (widget.editTask != null) {
      // Update
      final updated = widget.editTask!.copyWith(
        name: _nameController.text.trim(),
        category: _category,
        frequency: _frequency,
        frequencyDays: _frequency == TaskFrequency.everyXDays ? _frequencyDays : null,
        estimatedMinutes: _estimatedMinutes,
        energyLevel: _energyLevel,
        room: _room,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: now,
      );
      ref.read(householdTasksProvider(userId).notifier).update(updated);
    } else {
      // Create
      final task = HouseholdTask(
        id: const Uuid().v4(),
        userId: userId,
        name: _nameController.text.trim(),
        category: _category,
        frequency: _frequency,
        frequencyDays: _frequency == TaskFrequency.everyXDays ? _frequencyDays : null,
        estimatedMinutes: _estimatedMinutes,
        energyLevel: _energyLevel,
        room: _room,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      ref.read(householdTasksProvider(userId).notifier).add(task);
    }

    Navigator.pop(context);
  }
}

class _SuggestionCategory extends StatelessWidget {
  final HouseholdCategory category;
  final void Function(HouseholdTaskTemplate) onSelect;

  const _SuggestionCategory({required this.category, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final templates = HouseholdTaskTemplate.byCategory[category] ?? [];
    if (templates.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(category.colorValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(category.colorValue).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.emoji),
              const SizedBox(width: 6),
              Text(category.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: templates.take(6).map((t) {
                  return GestureDetector(
                    onTap: () => onSelect(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.name, style: const TextStyle(fontSize: 11)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
