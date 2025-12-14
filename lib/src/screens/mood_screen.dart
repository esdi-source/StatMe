/// Mood Screen - Mood tracking

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedMood = 5;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMood();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMood() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(moodNotifierProvider.notifier).load(user.id, _selectedDate);
      final mood = ref.read(moodNotifierProvider);
      if (mood != null) {
        setState(() {
          _selectedMood = mood.mood;
          _noteController.text = mood.note ?? '';
        });
      } else {
        setState(() {
          _selectedMood = 5;
          _noteController.clear();
        });
      }
    }
  }

  Future<void> _saveMood() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final log = MoodLogModel(
      id: ref.read(moodNotifierProvider)?.id ?? const Uuid().v4(),
      userId: user.id,
      mood: _selectedMood,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(moodNotifierProvider.notifier).upsert(log);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stimmung gespeichert')),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadMood();
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(moodNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stimmung'),
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
                      _loadMood();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
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

            // Mood Display
            Text(
              _getMoodEmoji(_selectedMood),
              style: const TextStyle(fontSize: 100),
            ),
            const SizedBox(height: 16),
            Text(
              _getMoodLabel(_selectedMood),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getMoodColor(_selectedMood),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_selectedMood / 10',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),

            // Mood Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Wie fühlst du dich?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('😢'),
                        Expanded(
                          child: Slider(
                            value: _selectedMood.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: _getMoodColor(_selectedMood),
                            onChanged: (value) {
                              setState(() => _selectedMood = value.round());
                            },
                          ),
                        ),
                        const Text('😄'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick Select Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(10, (index) {
                        final moodValue = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = moodValue),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedMood == moodValue
                                  ? _getMoodColor(moodValue)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$moodValue',
                              style: TextStyle(
                                color: _selectedMood == moodValue
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notiz (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'Was beschäftigt dich heute?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveMood,
                icon: const Icon(Icons.save),
                label: const Text('Stimmung speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _getMoodColor(_selectedMood),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mood Tips
            Card(
              color: _getMoodColor(_selectedMood).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: _getMoodColor(_selectedMood)),
                        const SizedBox(width: 8),
                        Text(
                          'Tipp',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: _getMoodColor(_selectedMood),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMoodTip(_selectedMood),
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

  String _getMoodEmoji(int mood) {
    if (mood <= 2) return '😢';
    if (mood <= 4) return '😕';
    if (mood <= 6) return '😐';
    if (mood <= 8) return '🙂';
    return '😄';
  }

  String _getMoodLabel(int mood) {
    if (mood <= 2) return 'Sehr schlecht';
    if (mood <= 4) return 'Schlecht';
    if (mood <= 6) return 'Neutral';
    if (mood <= 8) return 'Gut';
    return 'Sehr gut';
  }

  Color _getMoodColor(int mood) {
    if (mood <= 2) return Colors.red;
    if (mood <= 4) return Colors.orange;
    if (mood <= 6) return Colors.amber;
    if (mood <= 8) return Colors.lightGreen;
    return Colors.green;
  }

  String _getMoodTip(int mood) {
    if (mood <= 3) {
      return 'Es ist okay, schlechte Tage zu haben. Versuche einen Spaziergang, spreche mit jemandem oder mache etwas, das dir Freude bereitet.';
    }
    if (mood <= 5) {
      return 'Ein durchschnittlicher Tag kann zum guten Tag werden. Kleine positive Aktivitäten können helfen!';
    }
    if (mood <= 7) {
      return 'Schön, dass es dir gut geht! Nutze die positive Energie für Dinge, die dir wichtig sind.';
    }
    return 'Fantastisch! Genieße diesen wunderbaren Tag und teile deine positive Energie mit anderen!';
  }
}
