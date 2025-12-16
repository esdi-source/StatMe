/// Lernzeit Screen - Timer und manuelle Erfassung

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class StudyTimeScreen extends ConsumerStatefulWidget {
  const StudyTimeScreen({super.key});

  @override
  ConsumerState<StudyTimeScreen> createState() => _StudyTimeScreenState();
}

class _StudyTimeScreenState extends ConsumerState<StudyTimeScreen> {
  // Timer-Zustand
  bool _isTimerRunning = false;
  DateTime? _timerStartTime;
  String? _timerSubjectId;
  Timer? _updateTimer;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startTimer(String subjectId) {
    setState(() {
      _isTimerRunning = true;
      _timerStartTime = DateTime.now();
      _timerSubjectId = subjectId;
      _elapsedSeconds = 0;
    });
    
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_timerStartTime!).inSeconds;
      });
    });
  }

  Future<void> _stopTimer() async {
    _updateTimer?.cancel();
    
    if (_timerStartTime != null && _timerSubjectId != null) {
      final user = ref.read(authNotifierProvider).valueOrNull;
      if (user == null) return;
      
      final now = DateTime.now();
      final duration = now.difference(_timerStartTime!).inMinutes;
      
      if (duration > 0) {
        final session = StudySession(
          id: 'study_${now.millisecondsSinceEpoch}',
          userId: user.id,
          subjectId: _timerSubjectId!,
          startTime: _timerStartTime!,
          endTime: now,
          durationMinutes: duration,
          isTimerBased: true,
          createdAt: now,
          updatedAt: now,
        );
        
        await ref.read(studySessionsNotifierProvider.notifier).add(session);
      }
    }
    
    setState(() {
      _isTimerRunning = false;
      _timerStartTime = null;
      _timerSubjectId = null;
      _elapsedSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final sessions = ref.watch(studySessionsNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lernzeit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer-Bereich
            _buildTimerSection(subjects, tokens),
            const SizedBox(height: 24),
            
            // Wochenübersicht
            _buildWeeklyOverview(sessions, subjects, tokens),
            const SizedBox(height: 24),
            
            // Letzte Sessions
            Text(
              'Letzte Lerneinheiten',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecentSessions(sessions.take(10).toList(), subjects, tokens),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualEntryDialog(subjects, tokens),
        tooltip: 'Manuell eintragen',
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildTimerSection(List<Subject> subjects, DesignTokens tokens) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Timer-Anzeige
            Text(
              _formatSeconds(_elapsedSeconds),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _isTimerRunning ? tokens.primary : tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            
            if (_isTimerRunning && _timerSubjectId != null) ...[
              Text(
                'Lernen: ${subjects.firstWhere((s) => s.id == _timerSubjectId, orElse: () => subjects.first).name}',
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _stopTimer,
                icon: const Icon(Icons.stop),
                label: const Text('Stoppen & Speichern'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ] else ...[
              Text(
                'Wähle ein Fach und starte den Timer',
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(height: 16),
              
              if (subjects.isEmpty)
                Text('Bitte erst Fächer anlegen', style: TextStyle(color: tokens.error))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: subjects.take(6).map((subject) {
                    return ActionChip(
                      avatar: Icon(
                        Icons.play_arrow,
                        color: subject.colorValue != null
                            ? Color(subject.colorValue!)
                            : tokens.primary,
                      ),
                      label: Text(subject.shortName ?? subject.name),
                      onPressed: () => _startTimer(subject.id),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview(List<StudySession> sessions, List<Subject> subjects, DesignTokens tokens) {
    final weeklyMinutes = ref.read(studySessionsNotifierProvider.notifier).weeklyMinutes;
    
    // Nach Fach gruppieren
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final thisWeekSessions = sessions.where((s) => 
        s.startTime.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day)));
    
    final Map<String, int> minutesBySubject = {};
    for (final session in thisWeekSessions) {
      minutesBySubject[session.subjectId] = 
          (minutesBySubject[session.subjectId] ?? 0) + session.durationMinutes;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: tokens.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Diese Woche',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatMinutes(weeklyMinutes),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
              ],
            ),
            if (minutesBySubject.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...minutesBySubject.entries.map((entry) {
                final subject = subjects.cast<Subject?>().firstWhere(
                  (s) => s?.id == entry.key,
                  orElse: () => null,
                );
                final percentage = weeklyMinutes > 0 
                    ? (entry.value / weeklyMinutes * 100).round() 
                    : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: subject?.colorValue != null
                              ? Color(subject!.colorValue!)
                              : tokens.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(subject?.name ?? 'Unbekannt')),
                      Text(_formatMinutes(entry.value)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$percentage%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(List<StudySession> sessions, List<Subject> subjects, DesignTokens tokens) {
    if (sessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Noch keine Lerneinheiten erfasst',
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: sessions.map((session) {
          final subject = subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == session.subjectId,
            orElse: () => null,
          );
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: subject?.colorValue != null
                  ? Color(subject!.colorValue!)
                  : tokens.primary,
              child: Icon(
                session.isTimerBased ? Icons.timer : Icons.edit,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(subject?.name ?? 'Unbekannt'),
            subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(session.startTime)),
            trailing: Text(
              session.formattedDuration,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tokens.primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showManualEntryDialog(List<Subject> subjects, DesignTokens tokens) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte erst ein Fach anlegen')),
      );
      return;
    }

    String? selectedSubjectId = subjects.first.id;
    int hours = 0;
    int minutes = 30;
    DateTime selectedDate = DateTime.now();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Lernzeit eintragen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach'),
                  items: subjects.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedSubjectId = value),
                ),
                const SizedBox(height: 16),
                
                Text('Dauer', style: TextStyle(color: tokens.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Stunden'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: hours > 0 ? () => setState(() => hours--) : null,
                              ),
                              Text('$hours', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => hours++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Minuten'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: minutes > 0 ? () => setState(() => minutes -= 5) : null,
                              ),
                              Text('$minutes', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => minutes += 5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Datum'),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                  ),
                ),
                
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notizen (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final totalMinutes = hours * 60 + minutes;
                if (totalMinutes == 0 || selectedSubjectId == null) return;
                
                final user = ref.read(authNotifierProvider).valueOrNull;
                if (user == null) return;
                
                final now = DateTime.now();
                final session = StudySession(
                  id: 'study_${now.millisecondsSinceEpoch}',
                  userId: user.id,
                  subjectId: selectedSubjectId!,
                  startTime: selectedDate,
                  durationMinutes: totalMinutes,
                  isTimerBased: false,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await ref.read(studySessionsNotifierProvider.notifier).add(session);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Eintragen'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}min';
    }
    return '${mins}min';
  }
}
