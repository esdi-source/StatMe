/// Stundenplan Screen - Wöchentliche Übersicht
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _weekdays = [
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
  ];

  @override
  void initState() {
    super.initState();
    // Start bei aktuellem Wochentag
    final today = DateTime.now().weekday - 1;
    final initialIndex = today.clamp(0, 4);
    _tabController = TabController(length: 5, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final timetable = ref.watch(timetableNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stundenplan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _weekdays.map((day) => Tab(text: day.short)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _weekdays.map((day) {
          final lessons = timetable.where((t) => t.weekday == day).toList()
            ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
          return _buildDayView(day, lessons, subjects, tokens);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(subjects, tokens),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayView(Weekday day, List<TimetableEntry> lessons, List<Subject> subjects, DesignTokens tokens) {
    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: tokens.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Keine Stunden am ${day.label}',
              style: TextStyle(color: tokens.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddEntryDialog(subjects, tokens, preselectedDay: day),
              icon: const Icon(Icons.add),
              label: const Text('Stunde hinzufügen'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final subject = subjects.cast<Subject?>().firstWhere(
          (s) => s?.id == lesson.subjectId,
          orElse: () => null,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: subject?.colorValue != null
                  ? Color(subject!.colorValue!)
                  : tokens.primary,
              child: Text(
                '${lesson.lessonNumber}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(subject?.name ?? 'Unbekanntes Fach'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lesson.startTime != null && lesson.endTime != null)
                  Text('${lesson.startTime} - ${lesson.endTime}'),
                if (lesson.room != null)
                  Text('Raum: ${lesson.room}'),
                if (lesson.teacher != null)
                  Text('Lehrer: ${lesson.teacher}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditEntryDialog(lesson, subjects, tokens);
                } else if (value == 'delete') {
                  _deleteEntry(lesson.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                const PopupMenuItem(value: 'delete', child: Text('Löschen')),
              ],
            ),
            isThreeLine: (lesson.room != null || lesson.teacher != null),
          ),
        );
      },
    );
  }

  void _showAddEntryDialog(List<Subject> subjects, DesignTokens tokens, {Weekday? preselectedDay}) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte erst ein Fach anlegen')),
      );
      return;
    }

    String? selectedSubjectId = subjects.first.id;
    Weekday selectedDay = preselectedDay ?? _weekdays[_tabController.index];
    int lessonNumber = 1;
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final roomController = TextEditingController();
    final teacherController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Stunde hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach'),
                  items: subjects.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedSubjectId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Weekday>(
                  initialValue: selectedDay,
                  decoration: const InputDecoration(labelText: 'Tag'),
                  items: _weekdays.map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.label),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedDay = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: lessonNumber,
                  decoration: const InputDecoration(labelText: 'Stunde'),
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}. Stunde'),
                  )),
                  onChanged: (value) => setState(() => lessonNumber = value!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        decoration: const InputDecoration(labelText: 'Von', hintText: '08:00'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        decoration: const InputDecoration(labelText: 'Bis', hintText: '08:45'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Raum (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teacherController,
                  decoration: const InputDecoration(labelText: 'Lehrer (optional)'),
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
                if (selectedSubjectId == null) return;
                
                final user = ref.read(authNotifierProvider).valueOrNull;
                if (user == null) return;
                
                final now = DateTime.now();
                final entry = TimetableEntry(
                  id: 'timetable_${now.millisecondsSinceEpoch}',
                  userId: user.id,
                  subjectId: selectedSubjectId!,
                  weekday: selectedDay,
                  lessonNumber: lessonNumber,
                  startTime: startTimeController.text.isEmpty ? null : startTimeController.text,
                  endTime: endTimeController.text.isEmpty ? null : endTimeController.text,
                  room: roomController.text.isEmpty ? null : roomController.text,
                  teacher: teacherController.text.isEmpty ? null : teacherController.text,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await ref.read(timetableNotifierProvider.notifier).add(entry);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEntryDialog(TimetableEntry entry, List<Subject> subjects, DesignTokens tokens) {
    String? selectedSubjectId = entry.subjectId;
    Weekday selectedDay = entry.weekday;
    int lessonNumber = entry.lessonNumber;
    final startTimeController = TextEditingController(text: entry.startTime);
    final endTimeController = TextEditingController(text: entry.endTime);
    final roomController = TextEditingController(text: entry.room);
    final teacherController = TextEditingController(text: entry.teacher);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Stunde bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach'),
                  items: subjects.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedSubjectId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Weekday>(
                  initialValue: selectedDay,
                  decoration: const InputDecoration(labelText: 'Tag'),
                  items: _weekdays.map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.label),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedDay = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: lessonNumber,
                  decoration: const InputDecoration(labelText: 'Stunde'),
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}. Stunde'),
                  )),
                  onChanged: (value) => setState(() => lessonNumber = value!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        decoration: const InputDecoration(labelText: 'Von'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        decoration: const InputDecoration(labelText: 'Bis'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Raum'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teacherController,
                  decoration: const InputDecoration(labelText: 'Lehrer'),
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
                final updated = entry.copyWith(
                  subjectId: selectedSubjectId,
                  weekday: selectedDay,
                  lessonNumber: lessonNumber,
                  startTime: startTimeController.text.isEmpty ? null : startTimeController.text,
                  endTime: endTimeController.text.isEmpty ? null : endTimeController.text,
                  room: roomController.text.isEmpty ? null : roomController.text,
                  teacher: teacherController.text.isEmpty ? null : teacherController.text,
                  updatedAt: DateTime.now(),
                );
                
                await ref.read(timetableNotifierProvider.notifier).update(updated);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stunde löschen?'),
        content: const Text('Diese Stunde wird aus dem Stundenplan entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(timetableNotifierProvider.notifier).delete(entryId);
    }
  }
}
