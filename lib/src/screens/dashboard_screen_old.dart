/// Dashboard Screen - Overview of all metrics
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../core/config/app_config.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final today = DateTime.now();
    
    await ref.read(foodLogNotifierProvider.notifier).load(user.id, today);
    await ref.read(waterLogNotifierProvider.notifier).load(user.id, today);
    await ref.read(stepsNotifierProvider.notifier).load(user.id, today);
    await ref.read(sleepNotifierProvider.notifier).load(user.id, today);
    await ref.read(moodNotifierProvider.notifier).load(user.id, today);
    await ref.read(todoNotifierProvider.notifier).load(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final foodLogs = ref.watch(foodLogNotifierProvider);
    final waterLogs = ref.watch(waterLogNotifierProvider);
    final steps = ref.watch(stepsNotifierProvider);
    final sleep = ref.watch(sleepNotifierProvider);
    final mood = ref.watch(moodNotifierProvider);
    final todos = ref.watch(todoNotifierProvider);

    final totalCalories = foodLogs.fold<double>(0, (sum, log) => sum + log.calories);
    final totalWater = waterLogs.fold<int>(0, (sum, log) => sum + log.ml);
    final pendingTodos = todos.where((t) => t.active).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Dashboard'),
            const Spacer(),
            if (AppConfig.isDemoMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DEMO MODUS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : user?.email[0].toUpperCase() ?? 'D',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hallo, ${user?.displayName ?? user?.email.split('@').first ?? 'Demo'}!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(DateTime.now()),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Stats Grid
              Text(
                'Heute auf einen Blick',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        title: 'Kalorien',
                        value: '${totalCalories.toStringAsFixed(0)} kcal',
                        icon: Icons.restaurant,
                        color: Colors.orange,
                        progress: totalCalories / 2000,
                        subtitle: 'von 2000 kcal',
                      ),
                      _StatCard(
                        title: 'Wasser',
                        value: '$totalWater ml',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                        progress: totalWater / 2500,
                        subtitle: 'von 2500 ml',
                      ),
                      _StatCard(
                        title: 'Schritte',
                        value: '${steps?.steps ?? 0}',
                        icon: Icons.directions_walk,
                        color: Colors.green,
                        progress: (steps?.steps ?? 0) / 10000,
                        subtitle: 'von 10.000',
                      ),
                      _StatCard(
                        title: 'Schlaf',
                        value: sleep?.formattedDuration ?? '--',
                        icon: Icons.bedtime,
                        color: Colors.purple,
                        progress: (sleep?.durationMinutes ?? 0) / 480,
                        subtitle: 'Ziel: 8h',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Mood & Todos Row
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _MoodCard(mood: mood)),
                        const SizedBox(width: 12),
                        Expanded(child: _TodosCard(pendingCount: pendingTodos, todos: todos)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _MoodCard(mood: mood),
                      const SizedBox(height: 12),
                      _TodosCard(pendingCount: pendingTodos, todos: todos),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Food Logs
              Text(
                'Heutige Mahlzeiten',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (foodLogs.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Noch keine Mahlzeiten eingetragen',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: foodLogs.take(5).length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = foodLogs[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.restaurant, color: Colors.white),
                        ),
                        title: Text(log.productName),
                        subtitle: Text('${log.grams.toStringAsFixed(0)}g'),
                        trailing: Text(
                          '${log.calories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.progress,
    required this.subtitle,
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
                Text(title, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final MoodLogModel? mood;

  const _MoodCard({this.mood});

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
                const Icon(Icons.mood, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Stimmung heute',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mood != null)
              Row(
                children: [
                  Text(
                    mood!.moodEmoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${mood!.mood}/10',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        mood!.moodLabel,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              )
            else
              Text(
                'Noch nicht eingetragen',
                style: TextStyle(color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodosCard extends StatelessWidget {
  final int pendingCount;
  final List<TodoModel> todos;

  const _TodosCard({required this.pendingCount, required this.todos});

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
                const Icon(Icons.checklist, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Aktive ToDos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$pendingCount',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            ...todos.take(3).map((todo) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _priorityColor(todo.priority),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          todo.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.urgent:
        return Colors.red;
      case TodoPriority.high:
        return Colors.orange;
      case TodoPriority.medium:
        return Colors.blue;
      case TodoPriority.low:
        return Colors.grey;
    }
  }
}
