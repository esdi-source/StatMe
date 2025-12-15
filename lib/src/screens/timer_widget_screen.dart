/// Timer Widget Screen - Universeller Timer für verschiedene Aktivitäten
/// Kann für Lesen, Meditation, Sport etc. verwendet werden

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_widget_model.dart';
import '../providers/providers.dart';

class TimerWidgetScreen extends ConsumerStatefulWidget {
  const TimerWidgetScreen({super.key});

  @override
  ConsumerState<TimerWidgetScreen> createState() => _TimerWidgetScreenState();
}

class _TimerWidgetScreenState extends ConsumerState<TimerWidgetScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  TimerActivityType _selectedActivity = TimerActivityType.reading;
  DateTime? _startTime;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _seconds = 0;
      _isRunning = false;
      _startTime = null;
    });
  }

  Future<void> _saveSession() async {
    if (_seconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Die Session muss mindestens 1 Minute dauern'),
        ),
      );
      return;
    }

    _pauseTimer();
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final session = TimerSessionModel(
      id: const Uuid().v4(),
      oderId: user.id,
      activityType: _selectedActivity,
      startTime: _startTime ?? DateTime.now().subtract(Duration(seconds: _seconds)),
      endTime: DateTime.now(),
      durationSeconds: _seconds,
    );

    // Session speichern
    await ref.read(timerSessionsProvider.notifier).addSession(session);

    if (mounted) {
      _resetTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedActivity.label} Session gespeichert: ${session.shortDuration}',
          ),
        ),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final sessions = ref.watch(timerSessionsProvider);

    // Statistiken für diese Woche
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    final weekSessions = sessions.where((s) =>
        s.activityType == _selectedActivity &&
        s.startTime.isAfter(weekStartDay));
    final weekTotalSeconds = weekSessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final weekHours = weekTotalSeconds ~/ 3600;
    final weekMinutes = (weekTotalSeconds % 3600) ~/ 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Aktivitäts-Auswahl
            _buildActivitySelector(tokens),
            
            const SizedBox(height: 32),
            
            // Timer-Anzeige
            _buildTimerDisplay(tokens),
            
            const SizedBox(height: 32),
            
            // Steuerung
            _buildControls(tokens),
            
            const SizedBox(height: 40),
            
            // Wochen-Statistik
            _buildWeekStats(weekHours, weekMinutes, weekSessions.length, tokens),
            
            const SizedBox(height: 24),
            
            // Letzte Sessions
            _buildRecentSessions(sessions, tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySelector(DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivität auswählen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TimerActivityType.values.map((type) {
              final isSelected = type == _selectedActivity;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getActivityIcon(type),
                      size: 16,
                      color: isSelected ? Colors.white : tokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(type.label),
                  ],
                ),
                selected: isSelected,
                onSelected: _isRunning ? null : (selected) {
                  if (selected) {
                    setState(() => _selectedActivity = type);
                  }
                },
                selectedColor: tokens.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : tokens.textPrimary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(DesignTokens tokens) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tokens.primary.withOpacity(0.1),
                  tokens.primary.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: _isRunning ? tokens.primary : tokens.divider,
                width: 4,
              ),
              boxShadow: _isRunning
                  ? [
                      BoxShadow(
                        color: tokens.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getActivityIcon(_selectedActivity),
                  size: 32,
                  color: tokens.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(_seconds),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  _selectedActivity.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(DesignTokens tokens) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        if (_seconds > 0) ...[
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: _resetTimer,
            backgroundColor: tokens.surface,
            child: Icon(Icons.refresh, color: tokens.textSecondary),
          ),
          const SizedBox(width: 24),
        ],
        
        // Start/Pause Button
        FloatingActionButton.large(
          heroTag: 'play',
          onPressed: _isRunning ? _pauseTimer : _startTimer,
          backgroundColor: _isRunning ? Colors.orange : tokens.primary,
          child: Icon(
            _isRunning ? Icons.pause : Icons.play_arrow,
            size: 36,
          ),
        ),
        
        // Save Button
        if (_seconds >= 60 && !_isRunning) ...[
          const SizedBox(width: 24),
          FloatingActionButton(
            heroTag: 'save',
            onPressed: _saveSession,
            backgroundColor: tokens.success,
            child: const Icon(Icons.check),
          ),
        ],
      ],
    );
  }

  Widget _buildWeekStats(int hours, int minutes, int sessionCount, DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.divider),
      ),
      child: Row(
        children: [
          Icon(
            _getActivityIcon(_selectedActivity),
            size: 40,
            color: tokens.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diese Woche - ${_selectedActivity.label}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hours > 0 
                      ? '${hours}h ${minutes}min in $sessionCount Sessions'
                      : '${minutes}min in $sessionCount Sessions',
                  style: TextStyle(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(List<TimerSessionModel> sessions, DesignTokens tokens) {
    final recentSessions = sessions
        .where((s) => s.activityType == _selectedActivity)
        .take(5)
        .toList();

    if (recentSessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: tokens.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Noch keine ${_selectedActivity.label} Sessions',
              style: TextStyle(color: tokens.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Letzte Sessions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...recentSessions.map((session) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.divider),
          ),
          child: Row(
            children: [
              Icon(
                _getActivityIcon(session.activityType),
                color: tokens.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.shortDuration,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(session.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return 'Heute ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Gestern ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month}. ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _getActivityIcon(TimerActivityType type) {
    switch (type) {
      case TimerActivityType.reading:
        return Icons.menu_book;
      case TimerActivityType.meditation:
        return Icons.self_improvement;
      case TimerActivityType.sport:
        return Icons.fitness_center;
      case TimerActivityType.work:
        return Icons.work;
      case TimerActivityType.study:
        return Icons.school;
      case TimerActivityType.custom:
        return Icons.timer;
    }
  }
}
