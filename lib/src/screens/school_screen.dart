/// Schule Haupt-Screen - Container für alle Sub-Widgets
/// 
/// Übersicht über:
/// - Stundenplan (heute)
/// - Anstehende Termine
/// - Offene Hausaufgaben
/// - Letzte Noten
/// - Lernzeit-Statistik
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'school/timetable_screen.dart';
import 'school/grades_screen.dart';
import 'school/study_time_screen.dart';
import 'school/subject_profiles_screen.dart';
import 'school/school_calendar_screen.dart';
import 'school/homework_screen.dart';
import 'school/notes_screen.dart';
import 'school/grade_calculator_screen.dart';

class SchoolScreen extends ConsumerStatefulWidget {
  const SchoolScreen({super.key});

  @override
  ConsumerState<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends ConsumerState<SchoolScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    await Future.wait([
      ref.read(subjectsNotifierProvider.notifier).load(user.id),
      ref.read(timetableNotifierProvider.notifier).load(user.id),
      ref.read(gradesNotifierProvider.notifier).load(user.id),
      ref.read(studySessionsNotifierProvider.notifier).load(user.id),
      ref.read(schoolEventsNotifierProvider.notifier).load(user.id),
      ref.read(homeworkNotifierProvider.notifier).load(user.id),
      ref.read(schoolNotesNotifierProvider.notifier).load(user.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final subjects = ref.watch(subjectsNotifierProvider);
    final timetable = ref.watch(timetableNotifierProvider);
    final grades = ref.watch(gradesNotifierProvider);
    final studySessions = ref.watch(studySessionsNotifierProvider);
    final events = ref.watch(schoolEventsNotifierProvider);
    final homework = ref.watch(homeworkNotifierProvider);

    // Heutiger Wochentag
    final today = _getCurrentWeekday();
    final todayLessons = timetable.where((t) => t.weekday == today).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.school, color: tokens.primary),
            const SizedBox(width: 8),
            const Text('Schule'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _navigateToSubScreen(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'subjects', child: Text('Fächer verwalten')),
              const PopupMenuItem(value: 'calculator', child: Text('Notenrechner')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: subjects.isEmpty
            ? _buildEmptyState(tokens)
            : _buildContent(tokens, subjects, todayLessons, grades, studySessions, events, homework),
      ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: tokens.textSecondary),
            const SizedBox(height: 24),
            Text(
              'Noch keine Fächer angelegt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lege zuerst deine Schulfächer an, um loszulegen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddSubjectDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Erstes Fach anlegen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    DesignTokens tokens,
    List<Subject> subjects,
    List<TimetableEntry> todayLessons,
    List<Grade> grades,
    List<StudySession> studySessions,
    List<SchoolEvent> events,
    List<Homework> homework,
  ) {
    final upcomingEvents = events
        .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .take(3)
        .toList();
    
    final pendingHomework = homework
        .where((h) => h.status != HomeworkStatus.done)
        .take(5)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schnellzugriff-Karten
          _buildQuickAccessGrid(tokens),
          const SizedBox(height: 24),

          // Stundenplan heute
          _buildSectionHeader('Stundenplan heute', Icons.schedule, tokens,
              onTap: () => _navigateToSubScreen('timetable')),
          const SizedBox(height: 8),
          _buildTodayTimetable(todayLessons, subjects, tokens),
          const SizedBox(height: 24),

          // Anstehende Termine
          if (upcomingEvents.isNotEmpty) ...[
            _buildSectionHeader('Anstehende Termine', Icons.event, tokens,
                onTap: () => _navigateToSubScreen('calendar')),
            const SizedBox(height: 8),
            _buildUpcomingEvents(upcomingEvents, subjects, tokens),
            const SizedBox(height: 24),
          ],

          // Offene Hausaufgaben
          if (pendingHomework.isNotEmpty) ...[
            _buildSectionHeader('Offene Hausaufgaben', Icons.assignment, tokens,
                onTap: () => _navigateToSubScreen('homework')),
            const SizedBox(height: 8),
            _buildPendingHomework(pendingHomework, subjects, tokens),
            const SizedBox(height: 24),
          ],

          // Notenübersicht
          if (grades.isNotEmpty) ...[
            _buildSectionHeader('Letzte Noten', Icons.grade, tokens,
                onTap: () => _navigateToSubScreen('grades')),
            const SizedBox(height: 8),
            _buildRecentGrades(grades.take(5).toList(), subjects, tokens),
            const SizedBox(height: 24),
          ],

          // Lernzeit Übersicht
          _buildSectionHeader('Lernzeit diese Woche', Icons.timer, tokens,
              onTap: () => _navigateToSubScreen('studytime')),
          const SizedBox(height: 8),
          _buildStudyTimeOverview(studySessions, subjects, tokens),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(DesignTokens tokens) {
    final items = [
      _QuickAccessItem('Stundenplan', Icons.calendar_view_day, 'timetable', tokens.primary),
      _QuickAccessItem('Noten', Icons.grade, 'grades', Colors.orange),
      _QuickAccessItem('Hausaufgaben', Icons.assignment, 'homework', Colors.green),
      _QuickAccessItem('Lernzeit', Icons.timer, 'studytime', Colors.purple),
      _QuickAccessItem('Termine', Icons.event, 'calendar', Colors.red),
      _QuickAccessItem('Fächer', Icons.folder, 'subjects', Colors.teal),
      _QuickAccessItem('Notizen', Icons.note, 'notes', Colors.amber),
      _QuickAccessItem('Rechner', Icons.calculate, 'calculator', Colors.indigo),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildQuickAccessCard(item, tokens);
      },
    );
  }

  Widget _buildQuickAccessCard(_QuickAccessItem item, DesignTokens tokens) {
    return InkWell(
      onTap: () => _navigateToSubScreen(item.route),
      borderRadius: BorderRadius.circular(tokens.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 28),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(fontSize: 11, color: tokens.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, DesignTokens tokens, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: tokens.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const Spacer(),
          if (onTap != null)
            Icon(Icons.chevron_right, color: tokens.textSecondary),
        ],
      ),
    );
  }

  Widget _buildTodayTimetable(List<TimetableEntry> lessons, List<Subject> subjects, DesignTokens tokens) {
    if (lessons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.celebration, color: tokens.success),
              const SizedBox(width: 12),
              Text('Heute kein Unterricht!', style: TextStyle(color: tokens.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: lessons.map((lesson) {
          final subject = subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == lesson.subjectId,
            orElse: () => null,
          );
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: subject?.colorValue != null 
                  ? Color(subject!.colorValue!) 
                  : tokens.primary,
              radius: 16,
              child: Text(
                '${lesson.lessonNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(subject?.name ?? 'Unbekannt'),
            subtitle: lesson.room != null ? Text('Raum: ${lesson.room}') : null,
            trailing: lesson.startTime != null
                ? Text(lesson.startTime!, style: TextStyle(color: tokens.textSecondary))
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingEvents(List<SchoolEvent> events, List<Subject> subjects, DesignTokens tokens) {
    return Card(
      child: Column(
        children: events.map((event) {
          final subject = subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == event.subjectId,
            orElse: () => null,
          );
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getEventColor(event.type),
              child: Icon(_getEventIcon(event.type), color: Colors.white, size: 18),
            ),
            title: Text(event.title),
            subtitle: Text(
              '${DateFormat('dd.MM.').format(event.date)} • ${subject?.name ?? 'Allgemein'}',
            ),
            trailing: _buildDaysUntilBadge(event.daysUntil, tokens),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDaysUntilBadge(int days, DesignTokens tokens) {
    Color bgColor;
    String text;
    
    if (days == 0) {
      bgColor = Colors.red;
      text = 'Heute';
    } else if (days == 1) {
      bgColor = Colors.orange;
      text = 'Morgen';
    } else if (days <= 7) {
      bgColor = Colors.amber;
      text = '$days Tage';
    } else {
      bgColor = tokens.textSecondary;
      text = '$days Tage';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: bgColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPendingHomework(List<Homework> homework, List<Subject> subjects, DesignTokens tokens) {
    return Card(
      child: Column(
        children: homework.map((hw) {
          final subject = subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == hw.subjectId,
            orElse: () => null,
          );
          final isOverdue = hw.isOverdue;
          
          return ListTile(
            leading: Checkbox(
              value: hw.status == HomeworkStatus.done,
              onChanged: (_) => ref.read(homeworkNotifierProvider.notifier).toggleStatus(hw.id),
            ),
            title: Text(
              hw.title,
              style: TextStyle(
                decoration: hw.status == HomeworkStatus.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${DateFormat('dd.MM.').format(hw.dueDate)} • ${subject?.name ?? 'Allgemein'}',
              style: TextStyle(color: isOverdue ? Colors.red : tokens.textSecondary),
            ),
            trailing: isOverdue
                ? const Icon(Icons.warning, color: Colors.red, size: 20)
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentGrades(List<Grade> grades, List<Subject> subjects, DesignTokens tokens) {
    return Card(
      child: Column(
        children: grades.map((grade) {
          final subject = subjects.cast<Subject?>().firstWhere(
            (s) => s?.id == grade.subjectId,
            orElse: () => null,
          );
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getGradeColor(grade.points),
              child: Text(
                '${grade.points}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(subject?.name ?? 'Unbekannt'),
            subtitle: Text('${grade.type.label} • ${DateFormat('dd.MM.').format(grade.date)}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudyTimeOverview(List<StudySession> sessions, List<Subject> subjects, DesignTokens tokens) {
    // Lernzeit nach Fach aggregieren
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final thisWeekSessions = sessions.where((s) => 
        s.startTime.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day)));
    
    final Map<String, int> minutesBySubject = {};
    for (final session in thisWeekSessions) {
      minutesBySubject[session.subjectId] = 
          (minutesBySubject[session.subjectId] ?? 0) + session.durationMinutes;
    }

    final totalMinutes = minutesBySubject.values.fold(0, (a, b) => a + b);

    if (totalMinutes == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: tokens.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Diese Woche noch keine Lernzeit erfasst.',
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToSubScreen('studytime'),
                child: const Text('Starten'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: tokens.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  _formatMinutes(totalMinutes),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...minutesBySubject.entries.take(3).map((entry) {
              final subject = subjects.cast<Subject?>().firstWhere(
                (s) => s?.id == entry.key,
                orElse: () => null,
              );
              final percentage = (entry.value / totalMinutes * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(subject?.name ?? 'Unbekannt'),
                    ),
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
        ),
      ),
    );
  }

  void _navigateToSubScreen(String route) {
    Widget screen;
    switch (route) {
      case 'timetable':
        screen = const TimetableScreen();
        break;
      case 'grades':
        screen = const GradesScreen();
        break;
      case 'homework':
        screen = const HomeworkScreen();
        break;
      case 'studytime':
        screen = const StudyTimeScreen();
        break;
      case 'calendar':
        screen = const SchoolCalendarScreen();
        break;
      case 'subjects':
        screen = const SubjectProfilesScreen();
        break;
      case 'notes':
        screen = const NotesScreen();
        break;
      case 'calculator':
        screen = const GradeCalculatorScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    final shortNameController = TextEditingController();
    final tokens = ref.read(designTokensProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neues Fach anlegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Fachname',
                hintText: 'z.B. Mathematik',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shortNameController,
              decoration: const InputDecoration(
                labelText: 'Kürzel (optional)',
                hintText: 'z.B. M',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              
              final user = ref.read(authNotifierProvider).valueOrNull;
              if (user == null) return;
              
              final now = DateTime.now();
              final subject = Subject(
                id: 'subject_${now.millisecondsSinceEpoch}',
                userId: user.id,
                name: nameController.text.trim(),
                shortName: shortNameController.text.trim().isEmpty 
                    ? null 
                    : shortNameController.text.trim(),
                createdAt: now,
                updatedAt: now,
              );
              
              await ref.read(subjectsNotifierProvider.notifier).add(subject);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );
  }

  Weekday _getCurrentWeekday() {
    final day = DateTime.now().weekday;
    switch (day) {
      case 1: return Weekday.monday;
      case 2: return Weekday.tuesday;
      case 3: return Weekday.wednesday;
      case 4: return Weekday.thursday;
      case 5: return Weekday.friday;
      case 6: return Weekday.saturday;
      case 7: return Weekday.sunday;
      default: return Weekday.monday;
    }
  }

  Color _getEventColor(SchoolEventType type) {
    switch (type) {
      case SchoolEventType.exam: return Colors.red;
      case SchoolEventType.shortTest: return Colors.orange;
      case SchoolEventType.presentation: return Colors.purple;
      case SchoolEventType.deadline: return Colors.blue;
      case SchoolEventType.excursion: return Colors.green;
      case SchoolEventType.other: return Colors.grey;
    }
  }

  IconData _getEventIcon(SchoolEventType type) {
    switch (type) {
      case SchoolEventType.exam: return Icons.description;
      case SchoolEventType.shortTest: return Icons.quiz;
      case SchoolEventType.presentation: return Icons.present_to_all;
      case SchoolEventType.deadline: return Icons.flag;
      case SchoolEventType.excursion: return Icons.directions_bus;
      case SchoolEventType.other: return Icons.event;
    }
  }

  Color _getGradeColor(int points) {
    if (points >= 13) return Colors.green;
    if (points >= 10) return Colors.lightGreen;
    if (points >= 7) return Colors.amber;
    if (points >= 4) return Colors.orange;
    return Colors.red;
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

class _QuickAccessItem {
  final String label;
  final IconData icon;
  final String route;
  final Color color;

  _QuickAccessItem(this.label, this.icon, this.route, this.color);
}
