/// Steps Screen - Step tracking
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});

  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  DateTime _selectedDate = DateTime.now();
  final _stepsController = TextEditingController();
  final int _dailyGoal = 10000;

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadSteps() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(stepsNotifierProvider.notifier).load(user.id, _selectedDate);
      final steps = ref.read(stepsNotifierProvider);
      if (steps != null) {
        _stepsController.text = steps.steps.toString();
      } else {
        _stepsController.clear();
      }
    }
  }

  Future<void> _saveSteps() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final steps = int.tryParse(_stepsController.text);
    if (steps == null || steps < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gültige Schrittzahl eingeben')),
      );
      return;
    }

    final log = StepsLogModel(
      id: ref.read(stepsNotifierProvider)?.id ?? const Uuid().v4(),
      userId: user.id,
      steps: steps,
      date: _selectedDate,
      source: 'manual',
    );

    await ref.read(stepsNotifierProvider.notifier).upsert(log);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schritte gespeichert')),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadSteps();
  }

  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(stepsNotifierProvider);
    final currentSteps = steps?.steps ?? 0;
    final progress = currentSteps / _dailyGoal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schritte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                ),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _loadSteps();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isToday(_selectedDate)
                          ? 'Heute'
                          : DateFormat('dd.MM.yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isToday(_selectedDate) ? null : () => _changeDate(1),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Steps Progress Circle
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 20,
                      backgroundColor: Colors.green.shade100,
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1 ? Colors.amber : Colors.green,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 48,
                        color: progress >= 1 ? Colors.amber : Colors.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat('#,###').format(currentSteps),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progress >= 1 ? Colors.amber : Colors.green,
                            ),
                      ),
                      Text(
                        'von ${NumberFormat('#,###').format(_dailyGoal)} Schritten',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      if (progress >= 1)
                        const Text(
                          '🏆 Ziel erreicht!',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Manual Entry
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manueller Eintrag',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stepsController,
                            decoration: const InputDecoration(
                              labelText: 'Schritte',
                              prefixIcon: Icon(Icons.directions_walk),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _saveSteps,
                          child: const Text('Speichern'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Add Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schnell hinzufügen',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [500, 1000, 2000, 5000].map((s) {
                        return ActionChip(
                          label: Text('+$s'),
                          avatar: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            final current = int.tryParse(_stepsController.text) ?? 0;
                            _stepsController.text = (current + s).toString();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Fit / Apple Health',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Integration mit Fitness-Apps kommt in einer zukünftigen Version.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
