/// Water Screen - Water intake tracking

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen> {
  DateTime _selectedDate = DateTime.now();
  final int _dailyGoal = 2500;

  @override
  void initState() {
    super.initState();
    _loadWaterLogs();
  }

  Future<void> _loadWaterLogs() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(waterLogNotifierProvider.notifier).load(user.id, _selectedDate);
    }
  }

  Future<void> _addWater(int ml) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final log = WaterLogModel(
      id: const Uuid().v4(),
      userId: user.id,
      ml: ml,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    await ref.read(waterLogNotifierProvider.notifier).add(log);
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadWaterLogs();
  }

  @override
  Widget build(BuildContext context) {
    final waterLogs = ref.watch(waterLogNotifierProvider);
    final totalWater = waterLogs.fold<int>(0, (sum, log) => sum + log.ml);
    final progress = totalWater / _dailyGoal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wasser'),
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
                      _loadWaterLogs();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isToday(_selectedDate)
                          ? 'Heute'
                          : DateFormat('dd.MM.yyyy').format(_selectedDate),
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
            const SizedBox(height: 24),

            // Water Progress Circle
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
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 48,
                        color: progress >= 1 ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalWater ml',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progress >= 1 ? Colors.green : Colors.blue,
                            ),
                      ),
                      Text(
                        'von $_dailyGoal ml',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      if (progress >= 1)
                        const Text(
                          '🎉 Ziel erreicht!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Add Buttons
            Text(
              'Schnell hinzufügen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _QuickAddButton(
                  ml: 150,
                  icon: Icons.coffee,
                  label: 'Glas',
                  onTap: () => _addWater(150),
                ),
                _QuickAddButton(
                  ml: 200,
                  icon: Icons.local_drink,
                  label: 'Klein',
                  onTap: () => _addWater(200),
                ),
                _QuickAddButton(
                  ml: 300,
                  icon: Icons.water_drop,
                  label: 'Mittel',
                  onTap: () => _addWater(300),
                ),
                _QuickAddButton(
                  ml: 500,
                  icon: Icons.sports_bar,
                  label: 'Groß',
                  onTap: () => _addWater(500),
                ),
                _QuickAddButton(
                  ml: 750,
                  icon: Icons.local_bar,
                  label: 'Flasche',
                  onTap: () => _addWater(750),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Custom Amount
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _CustomWaterInput(
                  onAdd: (ml) => _addWater(ml),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // History
            Text(
              'Heutige Einträge',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (waterLogs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Noch keine Einträge',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: waterLogs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = waterLogs[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.water_drop, color: Colors.white),
                      ),
                      title: Text('+${log.ml} ml'),
                      subtitle: Text(
                        DateFormat('HH:mm').format(log.createdAt),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(waterLogNotifierProvider.notifier).delete(log.id);
                        },
                        color: Colors.red.shade300,
                      ),
                    );
                  },
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

class _QuickAddButton extends StatelessWidget {
  final int ml;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.ml,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(height: 4),
            Text(
              '$ml ml',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomWaterInput extends StatefulWidget {
  final void Function(int ml) onAdd;

  const _CustomWaterInput({required this.onAdd});

  @override
  State<_CustomWaterInput> createState() => _CustomWaterInputState();
}

class _CustomWaterInputState extends State<_CustomWaterInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Eigene Menge (ml)',
              prefixIcon: Icon(Icons.edit),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            final ml = int.tryParse(_controller.text);
            if (ml != null && ml > 0) {
              widget.onAdd(ml);
              _controller.clear();
            }
          },
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
