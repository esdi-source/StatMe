/// Erweiterter Mood Screen - Stimmung mit zusätzlichen Dimensionen
/// 
/// Features:
/// - Hauptstimmung (1-10, Pflicht)
/// - Stresslevel (optional)
/// - Energielevel (optional)
/// - Motivation (optional)
/// - Innere Ruhe (optional)
/// - Kontext-Notiz
library;

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
  
  // Hauptstimmung (Pflicht)
  int _selectedMood = 5;
  
  // Zusätzliche Dimensionen (optional)
  int? _stressLevel;
  int? _energyLevel;
  int? _motivation;
  int? _innerCalm;
  
  // Notiz
  final _noteController = TextEditingController();
  
  // UI State
  bool _showAdditionalDimensions = false;

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
          _stressLevel = mood.stressLevel;
          _energyLevel = mood.energyLevel;
          _motivation = mood.motivation;
          _innerCalm = mood.innerCalm;
          _noteController.text = mood.note ?? '';
          _showAdditionalDimensions = mood.stressLevel != null || 
                                       mood.energyLevel != null || 
                                       mood.motivation != null || 
                                       mood.innerCalm != null;
        });
      } else {
        setState(() {
          _selectedMood = 5;
          _stressLevel = null;
          _energyLevel = null;
          _motivation = null;
          _innerCalm = null;
          _noteController.clear();
          _showAdditionalDimensions = false;
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
      stressLevel: _stressLevel,
      energyLevel: _energyLevel,
      motivation: _motivation,
      innerCalm: _innerCalm,
    );

    try {
      await ref.read(moodNotifierProvider.notifier).upsert(log);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stimmung gespeichert')),
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
    _loadMood();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.mood, color: tokens.primary),
            const SizedBox(width: 8),
            const Text('Stimmung'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Datums-Auswahl
            _buildDateSelector(tokens),
            const SizedBox(height: 24),

            // Hauptstimmung (Pflicht)
            _buildMainMoodCard(tokens),
            const SizedBox(height: 16),

            // Toggle für zusätzliche Dimensionen
            _buildDimensionsToggle(tokens),
            
            // Zusätzliche Dimensionen
            if (_showAdditionalDimensions) ...[
              const SizedBox(height: 16),
              _buildStressCard(tokens),
              const SizedBox(height: 12),
              _buildEnergyCard(tokens),
              const SizedBox(height: 12),
              _buildMotivationCard(tokens),
              const SizedBox(height: 12),
              _buildCalmCard(tokens),
            ],
            const SizedBox(height: 16),

            // Kontext-Notiz
            _buildNoteCard(tokens),
            const SizedBox(height: 24),

            // Speichern
            _buildSaveButton(tokens),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(DesignTokens tokens) {
    return Row(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.primary,
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
            ),
            child: Text(
              _isToday(_selectedDate)
                  ? 'Heute'
                  : DateFormat('dd.MM.yyyy').format(_selectedDate),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _isToday(_selectedDate) ? null : () => _changeDate(1),
        ),
      ],
    );
  }

  Widget _buildMainMoodCard(DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        children: [
          // Emoji Display
          Text(
            _getMoodEmoji(_selectedMood),
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 8),
          Text(
            _getMoodLabel(_selectedMood),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getMoodColor(_selectedMood),
            ),
          ),
          Text(
            '$_selectedMood / 10',
            style: TextStyle(
              fontSize: 14,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Slider
          Row(
            children: [
              const Text('😢', style: TextStyle(fontSize: 20)),
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
              const Text('😄', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Quick Select
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(10, (index) {
              final moodValue = index + 1;
              final isSelected = _selectedMood == moodValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = moodValue),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? _getMoodColor(moodValue) : tokens.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? _getMoodColor(moodValue) : tokens.divider,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$moodValue',
                    style: TextStyle(
                      color: isSelected ? Colors.white : tokens.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsToggle(DesignTokens tokens) {
    return GestureDetector(
      onTap: () => setState(() => _showAdditionalDimensions = !_showAdditionalDimensions),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _showAdditionalDimensions 
              ? tokens.primary.withOpacity(0.1) 
              : tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(
            color: _showAdditionalDimensions ? tokens.primary : tokens.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _showAdditionalDimensions 
                  ? Icons.expand_less 
                  : Icons.expand_more,
              color: _showAdditionalDimensions ? tokens.primary : tokens.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zusätzliche Details',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Stress, Energie, Motivation, Innere Ruhe',
                    style: TextStyle(
                      color: tokens.textDisabled,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'optional',
              style: TextStyle(
                color: tokens.textDisabled,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressCard(DesignTokens tokens) {
    return _buildDimensionCard(
      tokens: tokens,
      title: 'Stresslevel',
      emoji: _stressLevel != null ? _getStressEmoji(_stressLevel!) : '😶',
      value: _stressLevel,
      color: Colors.orange,
      lowLabel: 'Entspannt',
      highLabel: 'Sehr gestresst',
      onChanged: (value) => setState(() => _stressLevel = value),
      onClear: () => setState(() => _stressLevel = null),
    );
  }

  Widget _buildEnergyCard(DesignTokens tokens) {
    return _buildDimensionCard(
      tokens: tokens,
      title: 'Energielevel',
      emoji: _energyLevel != null ? _getEnergyEmoji(_energyLevel!) : '😶',
      value: _energyLevel,
      color: Colors.amber,
      lowLabel: 'Erschöpft',
      highLabel: 'Voller Energie',
      onChanged: (value) => setState(() => _energyLevel = value),
      onClear: () => setState(() => _energyLevel = null),
    );
  }

  Widget _buildMotivationCard(DesignTokens tokens) {
    return _buildDimensionCard(
      tokens: tokens,
      title: 'Motivation',
      emoji: _motivation != null ? _getMotivationEmoji(_motivation!) : '😶',
      value: _motivation,
      color: Colors.green,
      lowLabel: 'Unmotiviert',
      highLabel: 'Hoch motiviert',
      onChanged: (value) => setState(() => _motivation = value),
      onClear: () => setState(() => _motivation = null),
    );
  }

  Widget _buildCalmCard(DesignTokens tokens) {
    return _buildDimensionCard(
      tokens: tokens,
      title: 'Innere Ruhe',
      emoji: _innerCalm != null ? _getCalmEmoji(_innerCalm!) : '😶',
      value: _innerCalm,
      color: Colors.teal,
      lowLabel: 'Unruhig',
      highLabel: 'Sehr ruhig',
      onChanged: (value) => setState(() => _innerCalm = value),
      onClear: () => setState(() => _innerCalm = null),
    );
  }

  Widget _buildDimensionCard({
    required DesignTokens tokens,
    required String title,
    required String emoji,
    required int? value,
    required Color color,
    required String lowLabel,
    required String highLabel,
    required void Function(int?) onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: value != null ? color.withOpacity(0.5) : tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (value != null) ...[
                const Spacer(),
                Text(
                  '$value/10',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, size: 18, color: tokens.textDisabled),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                lowLabel,
                style: TextStyle(color: tokens.textDisabled, fontSize: 10),
              ),
              Expanded(
                child: Slider(
                  value: (value ?? 5).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: value != null ? color : tokens.textDisabled,
                  inactiveColor: tokens.divider,
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
              Text(
                highLabel,
                style: TextStyle(color: tokens.textDisabled, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(DesignTokens tokens) {
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
            children: [
              Icon(Icons.note, color: tokens.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Warum heute so?',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'optional',
                style: TextStyle(
                  color: tokens.textDisabled,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Kurze Notiz zum Tag...',
              hintStyle: TextStyle(color: tokens.textDisabled),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                borderSide: BorderSide(color: tokens.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                borderSide: BorderSide(color: tokens.divider),
              ),
            ),
            maxLines: 3,
            style: TextStyle(color: tokens.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(DesignTokens tokens) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveMood,
        icon: const Icon(Icons.save),
        label: const Text('Speichern'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: _getMoodColor(_selectedMood),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // Hilfsfunktionen
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
    if (mood <= 6) return 'Okay';
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

  String _getStressEmoji(int level) {
    if (level <= 2) return '😌';
    if (level <= 4) return '🙂';
    if (level <= 6) return '😐';
    if (level <= 8) return '😰';
    return '🤯';
  }

  String _getEnergyEmoji(int level) {
    if (level <= 2) return '😴';
    if (level <= 4) return '🥱';
    if (level <= 6) return '😐';
    if (level <= 8) return '⚡';
    return '🔥';
  }

  String _getMotivationEmoji(int level) {
    if (level <= 2) return '😔';
    if (level <= 4) return '😕';
    if (level <= 6) return '😐';
    if (level <= 8) return '💪';
    return '🚀';
  }

  String _getCalmEmoji(int level) {
    if (level <= 2) return '😵';
    if (level <= 4) return '😣';
    if (level <= 6) return '😐';
    if (level <= 8) return '😊';
    return '🧘';
  }
}
