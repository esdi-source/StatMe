/// Schul-Kalender Screen - Termine für Schulaufgaben, Referate etc.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SchoolCalendarScreen extends ConsumerWidget {
  const SchoolCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final events = ref.watch(schoolEventsNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);

    // Gruppieren nach Datum
    final eventsByDate = <DateTime, List<SchoolEvent>>{};
    for (final event in events) {
      final dateKey = DateTime(event.date.year, event.date.month, event.date.day);
      eventsByDate.putIfAbsent(dateKey, () => []).add(event);
    }
    
    final sortedDates = eventsByDate.keys.toList()..sort();
    final upcomingDates = sortedDates.where((d) => 
        d.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schultermine'),
      ),
      body: events.isEmpty
          ? _buildEmptyState(tokens)
          : _buildEventsList(upcomingDates, eventsByDate, subjects, tokens, ref),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, ref, subjects, tokens),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: tokens.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Keine Termine eingetragen',
            style: TextStyle(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    List<DateTime> dates,
    Map<DateTime, List<SchoolEvent>> eventsByDate,
    List<Subject> subjects,
    DesignTokens tokens,
    WidgetRef ref,
  ) {
    if (dates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 64, color: tokens.success),
            const SizedBox(height: 16),
            Text('Keine anstehenden Termine!', style: TextStyle(color: tokens.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final dayEvents = eventsByDate[date]!;
        final isToday = _isToday(date);
        final isTomorrow = _isTomorrow(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datum-Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isToday 
                    ? tokens.primary.withOpacity(0.2) 
                    : isTomorrow 
                        ? Colors.orange.withOpacity(0.2)
                        : tokens.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    isToday 
                        ? 'Heute' 
                        : isTomorrow 
                            ? 'Morgen'
                            : DateFormat('EEEE, d. MMMM', 'de').format(date),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? tokens.primary : tokens.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd.MM.yyyy').format(date),
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Events
            ...dayEvents.map((event) {
              final subject = subjects.cast<Subject?>().firstWhere(
                (s) => s?.id == event.subjectId,
                orElse: () => null,
              );
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getEventColor(event.type),
                    child: Icon(_getEventIcon(event.type), color: Colors.white, size: 20),
                  ),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.type.label),
                      if (subject != null)
                        Text(subject.name, style: TextStyle(color: tokens.primary)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref.read(schoolEventsNotifierProvider.notifier).delete(event.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                    ],
                  ),
                  isThreeLine: subject != null,
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref, List<Subject> subjects, DesignTokens tokens) {
    String? selectedSubjectId;
    SchoolEventType selectedType = SchoolEventType.exam;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Termin hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titel'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SchoolEventType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Art'),
                  items: SchoolEventType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Kein Fach')),
                    ...subjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    )),
                  ],
                  onChanged: (value) => setState(() => selectedSubjectId = value),
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
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
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
                if (titleController.text.trim().isEmpty) return;
                
                final user = ref.read(authNotifierProvider).valueOrNull;
                if (user == null) return;
                
                final now = DateTime.now();
                final event = SchoolEvent(
                  id: 'event_${now.millisecondsSinceEpoch}',
                  userId: user.id,
                  subjectId: selectedSubjectId,
                  title: titleController.text.trim(),
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  type: selectedType,
                  date: selectedDate,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await ref.read(schoolEventsNotifierProvider.notifier).add(event);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Hinzufügen'),
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

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
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
}
