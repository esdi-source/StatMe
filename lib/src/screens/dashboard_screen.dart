/// Dashboard Screen - All-in-one overview with clickable cards

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../core/config/app_config.dart';
import 'screens.dart';

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
    await ref.read(settingsNotifierProvider.notifier).load(user.id);
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
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
    final settings = ref.watch(settingsNotifierProvider);

    final totalCalories = foodLogs.fold<double>(0, (sum, log) => sum + log.calories);
    final totalWater = waterLogs.fold<int>(0, (sum, log) => sum + log.ml);
    final todayTodos = todos.where((t) => t.active && _isForToday(t)).toList();
    
    final calorieGoal = settings?.dailyCalorieGoal ?? 2000;
    final waterGoal = settings?.dailyWaterGoalMl ?? 2500;
    final stepsGoal = settings?.dailyStepsGoal ?? 10000;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined),
            const SizedBox(width: 8),
            const Text('StatMe'),
            const Spacer(),
            if (AppConfig.isDemoMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DEMO',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiken',
            onPressed: () => _navigateTo(const StatsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () => _navigateTo(const SettingsScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              _GreetingCard(user: user),
              const SizedBox(height: 20),

              // Quick Stats Grid - Clickable
              Text(
                'Heute auf einen Blick',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                    childAspectRatio: 1.3,
                    children: [
                      _ClickableStatCard(
                        title: 'Kalorien',
                        value: '${totalCalories.toStringAsFixed(0)}',
                        unit: 'kcal',
                        icon: Icons.restaurant,
                        color: Colors.orange,
                        progress: totalCalories / calorieGoal,
                        subtitle: 'von $calorieGoal kcal',
                        onTap: () => _navigateTo(const FoodScreen()),
                      ),
                      _ClickableStatCard(
                        title: 'Wasser',
                        value: '$totalWater',
                        unit: 'ml',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                        progress: totalWater / waterGoal,
                        subtitle: 'von $waterGoal ml',
                        onTap: () => _navigateTo(const WaterScreen()),
                      ),
                      _ClickableStatCard(
                        title: 'Schritte',
                        value: '${steps?.steps ?? 0}',
                        unit: '',
                        icon: Icons.directions_walk,
                        color: Colors.green,
                        progress: (steps?.steps ?? 0) / stepsGoal,
                        subtitle: 'von ${(stepsGoal / 1000).toStringAsFixed(0)}k',
                        onTap: () => _navigateTo(const StepsScreen()),
                      ),
                      _ClickableStatCard(
                        title: 'Schlaf',
                        value: sleep?.formattedDuration ?? '--',
                        unit: '',
                        icon: Icons.bedtime,
                        color: Colors.purple,
                        progress: (sleep?.durationMinutes ?? 0) / 480,
                        subtitle: 'Ziel: 8h',
                        onTap: () => _navigateTo(const SleepScreen()),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Mood Card - Clickable
              _ClickableMoodCard(
                mood: mood,
                onTap: () => _navigateTo(const MoodScreen()),
              ),
              const SizedBox(height: 20),

              // Today's Todos - with checkboxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Heutige ToDos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateTo(const TodosScreen()),
                    icon: const Icon(Icons.add),
                    label: const Text('Alle ToDos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _TodosSection(
                todos: todayTodos,
                onToggle: (todo) => _toggleTodo(todo),
                onViewAll: () => _navigateTo(const TodosScreen()),
              ),
              const SizedBox(height: 20),

              // Recent Food Logs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Heutige Mahlzeiten',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateTo(const FoodScreen()),
                    icon: const Icon(Icons.add),
                    label: const Text('Hinzufügen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FoodLogsSection(foodLogs: foodLogs),
            ],
          ),
        ),
      ),
    );
  }

  bool _isForToday(TodoModel todo) {
    final now = DateTime.now();
    final todoDate = todo.startDate;
    return todoDate.year == now.year && 
           todoDate.month == now.month && 
           todoDate.day == now.day;
  }

  Future<void> _toggleTodo(TodoModel todo) async {
    final updated = todo.copyWith(active: !todo.active);
    await ref.read(todoNotifierProvider.notifier).update(updated);
  }
}

// ============================================
// WIDGET COMPONENTS
// ============================================

class _GreetingCard extends StatelessWidget {
  final UserModel? user;

  const _GreetingCard({this.user});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Guten Morgen';
    } else if (hour < 18) {
      greeting = 'Guten Tag';
    } else {
      greeting = 'Guten Abend';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : user?.email[0].toUpperCase() ?? 'D',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, ${user?.displayName ?? user?.email.split('@').first ?? 'Demo'}!',
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
    );
  }
}

class _ClickableStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double progress;
  final String subtitle;
  final VoidCallback onTap;

  const _ClickableStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.progress,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        unit,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                ],
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
      ),
    );
  }
}

class _ClickableMoodCard extends StatelessWidget {
  final MoodLogModel? mood;
  final VoidCallback onTap;

  const _ClickableMoodCard({this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.mood, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stimmung heute',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (mood != null)
                      Text(
                        '${mood!.moodEmoji} ${mood!.moodLabel} (${mood!.mood}/10)',
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    else
                      Text(
                        'Tippe um einzutragen',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
              if (mood != null)
                Text(
                  mood!.moodEmoji,
                  style: const TextStyle(fontSize: 32),
                )
              else
                Icon(Icons.add_circle_outline, color: Colors.grey.shade400, size: 32),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodosSection extends StatelessWidget {
  final List<TodoModel> todos;
  final Function(TodoModel) onToggle;
  final VoidCallback onViewAll;

  const _TodosSection({
    required this.todos,
    required this.onToggle,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return Card(
        child: InkWell(
          onTap: onViewAll,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
                  const SizedBox(height: 8),
                  const Text(
                    'Keine ToDos für heute!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Tippe um alle ToDos zu sehen',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ...todos.take(5).map((todo) => _TodoListItem(
                todo: todo,
                onToggle: () => onToggle(todo),
              )),
          if (todos.length > 5)
            ListTile(
              leading: const Icon(Icons.more_horiz),
              title: Text('${todos.length - 5} weitere ToDos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onViewAll,
            ),
        ],
      ),
    );
  }
}

class _TodoListItem extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;

  const _TodoListItem({required this.todo, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: !todo.active,
        onChanged: (_) => onToggle(),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: !todo.active ? TextDecoration.lineThrough : null,
          color: !todo.active ? Colors.grey : null,
        ),
      ),
      subtitle: todo.description != null && todo.description!.isNotEmpty
          ? Text(
              todo.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: _priorityIndicator(todo.priority),
    );
  }

  Widget _priorityIndicator(TodoPriority priority) {
    Color color;
    switch (priority) {
      case TodoPriority.urgent:
        color = Colors.red;
        break;
      case TodoPriority.high:
        color = Colors.orange;
        break;
      case TodoPriority.medium:
        color = Colors.blue;
        break;
      case TodoPriority.low:
        color = Colors.grey;
        break;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FoodLogsSection extends StatelessWidget {
  final List<FoodLogModel> foodLogs;

  const _FoodLogsSection({required this.foodLogs});

  @override
  Widget build(BuildContext context) {
    if (foodLogs.isEmpty) {
      return Card(
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
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: foodLogs.take(5).length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = foodLogs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Icon(Icons.restaurant, color: Colors.orange.shade700),
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
    );
  }
}
