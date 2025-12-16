/// Sport Timer Screen - Timer für Sporteinheiten

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SportTimerScreen extends ConsumerStatefulWidget {
  const SportTimerScreen({super.key});

  @override
  ConsumerState<SportTimerScreen> createState() => _SportTimerScreenState();
}

class _SportTimerScreenState extends ConsumerState<SportTimerScreen> {
  final _sportTypeController = TextEditingController();
  final _notesController = TextEditingController();
  
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  SportIntensity _intensity = SportIntensity.medium;
  DateTime? _startTime;
  
  final List<String> _commonSports = [
    'Laufen', 'Radfahren', 'Schwimmen', 'Krafttraining', 
    'Yoga', 'Spazieren', 'Wandern', 'HIIT',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _sportTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_sportTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle eine Sportart')),
      );
      return;
    }
    
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _startTime = DateTime.now();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
    
    if (_elapsed.inSeconds > 0) {
      _showSaveDialog();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _isRunning = false;
      _isPaused = false;
      _startTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sport Timer'),
        actions: [
          if (_elapsed.inSeconds > 0 && !_isRunning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetTimer,
              tooltip: 'Zurücksetzen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Sport type selection (only show before starting)
            if (!_isRunning) ...[
              _buildSportTypeSection(tokens),
              const SizedBox(height: 24),
            ] else ...[
              // Show selected sport while running
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSportIcon(_sportTypeController.text),
                      color: tokens.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _sportTypeController.text,
                      style: TextStyle(
                        color: tokens.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
            
            // Timer display
            _buildTimerDisplay(tokens),
            const SizedBox(height: 40),
            
            // Control buttons
            _buildControlButtons(tokens),
            const SizedBox(height: 40),
            
            // Intensity selection (only show before starting or while paused)
            if (!_isRunning || _isPaused) ...[
              _buildIntensitySection(tokens),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSportTypeSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sportart wählen',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sportTypeController,
          decoration: InputDecoration(
            hintText: 'z.B. Laufen, Krafttraining...',
            prefixIcon: const Icon(Icons.fitness_center),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonSports.map((sport) {
            final isSelected = _sportTypeController.text == sport;
            return FilterChip(
              label: Text(sport),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _sportTypeController.text = sport;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(DesignTokens tokens) {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRunning && !_isPaused 
                ? tokens.primary.withOpacity(0.1)
                : tokens.surface,
            border: Border.all(
              color: _isRunning && !_isPaused ? tokens.primary : tokens.divider,
              width: 4,
            ),
          ),
          child: Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: _isRunning && !_isPaused ? tokens.primary : tokens.textPrimary,
            ),
          ),
        ),
        if (_isRunning && !_isPaused) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Läuft...',
                style: TextStyle(
                  color: tokens.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        if (_isPaused) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.warning,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pausiert',
                style: TextStyle(
                  color: tokens.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildControlButtons(DesignTokens tokens) {
    if (!_isRunning && _elapsed.inSeconds == 0) {
      // Initial state - show start button
      return SizedBox(
        width: 200,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _startTimer,
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text('Start', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      );
    } else if (_isRunning && !_isPaused) {
      // Running - show pause and stop
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _pauseTimer,
              icon: const Icon(Icons.pause, size: 24),
              label: const Text('Pause'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _stopTimer,
              icon: const Icon(Icons.stop, size: 24),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_isPaused) {
      // Paused - show resume and stop
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _resumeTimer,
              icon: const Icon(Icons.play_arrow, size: 24),
              label: const Text('Fortsetzen'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _stopTimer,
              icon: const Icon(Icons.stop, size: 24),
              label: const Text('Beenden'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tokens.error),
                foregroundColor: tokens.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Stopped with elapsed time - show save
      return Column(
        children: [
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _showSaveDialog,
              icon: const Icon(Icons.save, size: 24),
              label: const Text('Speichern', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetTimer,
            child: const Text('Verwerfen'),
          ),
        ],
      );
    }
  }

  Widget _buildIntensitySection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensität',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: SportIntensity.values.map((intensity) {
            final isSelected = _intensity == intensity;
            return GestureDetector(
              onTap: () => setState(() => _intensity = intensity),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? tokens.primary.withOpacity(0.2)
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? tokens.primary : tokens.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      intensity.label,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intensity.label,
                    style: TextStyle(
                      color: isSelected ? tokens.primary : tokens.textSecondary,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showSaveDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaveSessionSheet(
        sportType: _sportTypeController.text,
        duration: _elapsed,
        intensity: _intensity,
        startTime: _startTime ?? DateTime.now().subtract(_elapsed),
        onSaved: () {
          _resetTimer();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  IconData _getSportIcon(String sportType) {
    final type = sportType.toLowerCase();
    if (type.contains('lauf') || type.contains('jogg') || type.contains('run')) {
      return Icons.directions_run;
    } else if (type.contains('rad') || type.contains('bike') || type.contains('cycl')) {
      return Icons.directions_bike;
    } else if (type.contains('schwimm') || type.contains('swim')) {
      return Icons.pool;
    } else if (type.contains('yoga') || type.contains('stretch')) {
      return Icons.self_improvement;
    } else if (type.contains('kraft') || type.contains('weight') || type.contains('gym')) {
      return Icons.fitness_center;
    }
    return Icons.fitness_center;
  }
}

// ============================================
// SAVE SESSION SHEET
// ============================================

class _SaveSessionSheet extends ConsumerStatefulWidget {
  final String sportType;
  final Duration duration;
  final SportIntensity intensity;
  final DateTime startTime;
  final VoidCallback onSaved;

  const _SaveSessionSheet({
    required this.sportType,
    required this.duration,
    required this.intensity,
    required this.startTime,
    required this.onSaved,
  });

  @override
  ConsumerState<_SaveSessionSheet> createState() => _SaveSessionSheetState();
}

class _SaveSessionSheetState extends ConsumerState<_SaveSessionSheet> {
  final _notesController = TextEditingController();
  late SportIntensity _intensity;

  @override
  void initState() {
    super.initState();
    _intensity = widget.intensity;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final hours = widget.duration.inHours;
    final minutes = widget.duration.inMinutes.remainder(60);
    
    // Estimate calories
    final caloriesPerMinute = _intensity.calorieMultiplier * 3.5 * 70 / 200;
    final calories = (caloriesPerMinute * widget.duration.inMinutes).round();

    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.textDisabled.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Einheit speichern',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: tokens.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sportType,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        hours > 0 
                            ? '${hours}h ${minutes}m'
                            : '$minutes min',
                        style: TextStyle(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '~$calories',
                      style: TextStyle(
                        color: tokens.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        color: tokens.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Intensity adjustment
          Text(
            'Intensität anpassen',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: SportIntensity.values.map((intensity) {
              final isSelected = _intensity == intensity;
              return GestureDetector(
                onTap: () => setState(() => _intensity = intensity),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? tokens.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? tokens.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(intensity.label, style: const TextStyle(fontSize: 20)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          
          // Notes
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notizen (optional)',
              hintText: 'Wie war das Training?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final caloriesPerMinute = _intensity.calorieMultiplier * 3.5 * 70 / 200;
    final calories = (caloriesPerMinute * widget.duration.inMinutes).round();
    
    final session = SportSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.id,
      sportType: widget.sportType,
      duration: widget.duration,
      intensity: _intensity,
      caloriesBurned: calories,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      date: widget.startTime,
      createdAt: DateTime.now(),
    );
    
    await ref.read(sportSessionsNotifierProvider.notifier).add(session);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sporteinheit gespeichert!')),
      );
      widget.onSaved();
    }
  }
}
