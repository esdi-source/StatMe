/// Sleep Screen - Sleep tracking
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);

  @override
  void initState() {
    super.initState();
    _loadSleep();
  }

  Future<void> _loadSleep() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(sleepNotifierProvider.notifier).load(user.id, _selectedDate);
      final sleep = ref.read(sleepNotifierProvider);
      if (sleep != null) {
        setState(() {
          _bedTime = TimeOfDay.fromDateTime(sleep.startTs);
          _wakeTime = TimeOfDay.fromDateTime(sleep.endTs);
        });
      }
    }
  }

  int _calculateDuration() {
    final bedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day - 1,
      _bedTime.hour,
      _bedTime.minute,
    );
    final wakeDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _wakeTime.hour,
      _wakeTime.minute,
    );
    return wakeDateTime.difference(bedDateTime).inMinutes;
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  Future<void> _saveSleep() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final bedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day - 1,
      _bedTime.hour,
      _bedTime.minute,
    );
    final wakeDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _wakeTime.hour,
      _wakeTime.minute,
    );

    final log = SleepLogModel.calculate(
      id: ref.read(sleepNotifierProvider)?.id ?? const Uuid().v4(),
      userId: user.id,
      startTs: bedDateTime,
      endTs: wakeDateTime,
    );

    try {
      await ref.read(sleepNotifierProvider.notifier).upsert(log);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schlaf gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadSleep();
  }

  @override
  Widget build(BuildContext context) {
    final sleep = ref.watch(sleepNotifierProvider);
    final duration = _calculateDuration();
    final progress = duration / 480; // 8 hours = 480 minutes

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schlaf'),
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
                      _loadSleep();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isToday(_selectedDate)
                          ? 'Heute Nacht'
                          : 'Nacht zum ${DateFormat('dd.MM.').format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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

            // Sleep Duration Display
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
                      backgroundColor: Colors.purple.shade100,
                      valueColor: AlwaysStoppedAnimation(
                        _getSleepColor(duration),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bedtime,
                        size: 48,
                        color: _getSleepColor(duration),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(duration),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getSleepColor(duration),
                            ),
                      ),
                      Text(
                        'Schlafdauer',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSleepQualityText(duration),
                        style: TextStyle(
                          color: _getSleepColor(duration),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Time Pickers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Bed Time
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: const Icon(Icons.nights_stay, color: Colors.indigo),
                      ),
                      title: const Text('Eingeschlafen'),
                      subtitle: const Text('Gestern Abend'),
                      trailing: TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _bedTime,
                          );
                          if (time != null) {
                            setState(() => _bedTime = time);
                          }
                        },
                        child: Text(
                          _bedTime.format(context),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const Divider(),
                    // Wake Time
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.shade100,
                        child: const Icon(Icons.wb_sunny, color: Colors.amber),
                      ),
                      title: const Text('Aufgewacht'),
                      subtitle: Text(DateFormat('dd.MM.').format(_selectedDate)),
                      trailing: TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _wakeTime,
                          );
                          if (time != null) {
                            setState(() => _wakeTime = time);
                          }
                        },
                        child: Text(
                          _wakeTime.format(context),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSleep,
                icon: const Icon(Icons.save),
                label: const Text('Schlaf speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tips Card
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          'Schlaf-Tipp',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.purple,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSleepTip(duration),
                      style: const TextStyle(fontSize: 14),
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

  Color _getSleepColor(int minutes) {
    if (minutes < 300) return Colors.red; // < 5h
    if (minutes < 360) return Colors.orange; // 5-6h
    if (minutes < 420) return Colors.amber; // 6-7h
    if (minutes <= 540) return Colors.green; // 7-9h
    return Colors.blue; // > 9h
  }

  String _getSleepQualityText(int minutes) {
    if (minutes < 300) return '😴 Zu wenig Schlaf';
    if (minutes < 360) return '😕 Könnte besser sein';
    if (minutes < 420) return '🙂 Ausreichend';
    if (minutes <= 540) return '😊 Optimal!';
    return '😴 Vielleicht zu viel?';
  }

  String _getSleepTip(int minutes) {
    if (minutes < 360) {
      return 'Versuche, 7-9 Stunden pro Nacht zu schlafen. Ausreichend Schlaf verbessert Konzentration, Stimmung und Gesundheit.';
    }
    if (minutes <= 540) {
      return 'Großartig! Du hast eine gesunde Schlafdauer. Versuche, diesen Rhythmus beizubehalten.';
    }
    return 'Zu viel Schlaf kann müde machen. Versuche, einen regelmäßigen Schlafrhythmus zu finden.';
  }
}
