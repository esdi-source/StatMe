/// Fachprofile Screen - Übersicht aller Fächer mit Details

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SubjectProfilesScreen extends ConsumerWidget {
  const SubjectProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final subjects = ref.watch(subjectsNotifierProvider);
    final grades = ref.watch(gradesNotifierProvider);
    final studySessions = ref.watch(studySessionsNotifierProvider);
    final events = ref.watch(schoolEventsNotifierProvider);
    final homework = ref.watch(homeworkNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fächer'),
      ),
      body: subjects.isEmpty
          ? _buildEmptyState(context, ref, tokens)
          : _buildSubjectList(context, ref, subjects, grades, studySessions, events, homework, tokens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(context, ref, tokens),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 80, color: tokens.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Keine Fächer angelegt',
            style: TextStyle(color: tokens.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showAddSubjectDialog(context, ref, tokens),
            icon: const Icon(Icons.add),
            label: const Text('Fach anlegen'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(
    BuildContext context,
    WidgetRef ref,
    List<Subject> subjects,
    List<Grade> grades,
    List<StudySession> studySessions,
    List<SchoolEvent> events,
    List<Homework> homework,
    DesignTokens tokens,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        
        // Aggregierte Daten für dieses Fach
        final subjectGrades = grades.where((g) => g.subjectId == subject.id).toList();
        final subjectStudy = studySessions.where((s) => s.subjectId == subject.id).toList();
        final subjectEvents = events.where((e) => e.subjectId == subject.id).toList();
        final subjectHomework = homework.where((h) => h.subjectId == subject.id && h.status != HomeworkStatus.done).toList();
        
        // Durchschnitt berechnen
        double average = 0;
        if (subjectGrades.isNotEmpty) {
          double weightedSum = 0;
          double totalWeight = 0;
          for (final grade in subjectGrades) {
            weightedSum += grade.points * grade.weight;
            totalWeight += grade.weight;
          }
          average = totalWeight > 0 ? weightedSum / totalWeight : 0;
        }
        
        // Gesamte Lernzeit
        final totalMinutes = subjectStudy.fold(0, (sum, s) => sum + s.durationMinutes);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showSubjectDetails(context, ref, subject, tokens),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: subject.colorValue != null
                            ? Color(subject.colorValue!)
                            : tokens.primary,
                        child: Text(
                          subject.shortName ?? subject.name.substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                _buildFunFactorStars(subject.funFactor, tokens),
                                const SizedBox(width: 8),
                                Text(
                                  'Spaß-Faktor',
                                  style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditSubjectDialog(context, ref, subject, tokens);
                          } else if (value == 'delete') {
                            _deleteSubject(context, ref, subject.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                          const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Statistik-Zeile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.grade,
                        average > 0 ? 'Ø ${average.toStringAsFixed(1)}' : '–',
                        'Punkte',
                        tokens,
                      ),
                      _buildStatItem(
                        Icons.timer,
                        _formatMinutes(totalMinutes),
                        'Lernzeit',
                        tokens,
                      ),
                      _buildStatItem(
                        Icons.description,
                        '${subjectGrades.length}',
                        'Noten',
                        tokens,
                      ),
                      _buildStatItem(
                        Icons.assignment,
                        '${subjectHomework.length}',
                        'Offen',
                        tokens,
                      ),
                    ],
                  ),
                  
                  // Anstehende Termine
                  if (subjectEvents.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            '${subjectEvents.length} anstehende Termine',
                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, DesignTokens tokens) {
    return Column(
      children: [
        Icon(icon, size: 20, color: tokens.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10, color: tokens.textSecondary)),
      ],
    );
  }

  Widget _buildFunFactorStars(int funFactor, DesignTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < funFactor ? Icons.star : Icons.star_border,
        size: 14,
        color: i < funFactor ? Colors.amber : tokens.textSecondary,
      )),
    );
  }

  void _showSubjectDetails(BuildContext context, WidgetRef ref, Subject subject, DesignTokens tokens) {
    // Einfache Detail-Ansicht
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => _SubjectDetailSheet(
          subject: subject,
          scrollController: controller,
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, DesignTokens tokens) {
    final nameController = TextEditingController();
    final shortNameController = TextEditingController();
    int funFactor = 3;
    Color? selectedColor;

    final colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.cyan, Colors.teal,
      Colors.green, Colors.lightGreen, Colors.orange, Colors.amber,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Neues Fach'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Fachname'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shortNameController,
                  decoration: const InputDecoration(
                    labelText: 'Kürzel (optional)',
                    hintText: 'z.B. M für Mathe',
                  ),
                  maxLength: 3,
                ),
                const SizedBox(height: 12),
                
                Text('Spaß-Faktor', style: TextStyle(color: tokens.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < funFactor ? Icons.star : Icons.star_border,
                      color: i < funFactor ? Colors.amber : tokens.textSecondary,
                    ),
                    onPressed: () => setState(() => funFactor = i + 1),
                  )),
                ),
                const SizedBox(height: 12),
                
                Text('Farbe', style: TextStyle(color: tokens.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) => GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: selectedColor == color ? [
                          BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
                        ] : null,
                      ),
                    ),
                  )).toList(),
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
                  colorValue: selectedColor?.value,
                  funFactor: funFactor,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await ref.read(subjectsNotifierProvider.notifier).add(subject);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, WidgetRef ref, Subject subject, DesignTokens tokens) {
    final nameController = TextEditingController(text: subject.name);
    final shortNameController = TextEditingController(text: subject.shortName);
    int funFactor = subject.funFactor;
    Color? selectedColor = subject.colorValue != null ? Color(subject.colorValue!) : null;

    final colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.cyan, Colors.teal,
      Colors.green, Colors.lightGreen, Colors.orange, Colors.amber,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Fach bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Fachname'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shortNameController,
                  decoration: const InputDecoration(labelText: 'Kürzel'),
                  maxLength: 3,
                ),
                const SizedBox(height: 12),
                
                Text('Spaß-Faktor', style: TextStyle(color: tokens.textSecondary)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < funFactor ? Icons.star : Icons.star_border,
                      color: i < funFactor ? Colors.amber : tokens.textSecondary,
                    ),
                    onPressed: () => setState(() => funFactor = i + 1),
                  )),
                ),
                const SizedBox(height: 12),
                
                Text('Farbe', style: TextStyle(color: tokens.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) => GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor?.value == color.value ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  )).toList(),
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
                if (nameController.text.trim().isEmpty) return;
                
                final updated = subject.copyWith(
                  name: nameController.text.trim(),
                  shortName: shortNameController.text.trim().isEmpty 
                      ? null 
                      : shortNameController.text.trim(),
                  colorValue: selectedColor?.value,
                  funFactor: funFactor,
                  updatedAt: DateTime.now(),
                );
                
                await ref.read(subjectsNotifierProvider.notifier).update(updated);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSubject(BuildContext context, WidgetRef ref, String subjectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fach löschen?'),
        content: const Text('Alle Daten zu diesem Fach werden gelöscht (Noten, Lernzeit, Termine, etc.).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(subjectsNotifierProvider.notifier).delete(subjectId);
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

/// Detail-Sheet für ein Fach
class _SubjectDetailSheet extends ConsumerWidget {
  final Subject subject;
  final ScrollController scrollController;

  const _SubjectDetailSheet({
    required this.subject,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final grades = ref.watch(gradesNotifierProvider).where((g) => g.subjectId == subject.id).toList();
    final studySessions = ref.watch(studySessionsNotifierProvider).where((s) => s.subjectId == subject.id).toList();
    final events = ref.watch(schoolEventsNotifierProvider).where((e) => e.subjectId == subject.id).toList();
    final homework = ref.watch(homeworkNotifierProvider).where((h) => h.subjectId == subject.id).toList();
    final notes = ref.watch(schoolNotesNotifierProvider).where((n) => n.subjectId == subject.id).toList();

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: subject.colorValue != null
                    ? Color(subject.colorValue!)
                    : tokens.primary,
                child: Text(
                  subject.shortName ?? subject.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < subject.funFactor ? Icons.star : Icons.star_border,
                        size: 16,
                        color: i < subject.funFactor ? Colors.amber : tokens.textSecondary,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Statistiken
          _buildSection('Übersicht', [
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Noten'),
              trailing: Text('${grades.length}'),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Lernzeit'),
              trailing: Text(_formatMinutes(studySessions.fold(0, (sum, s) => sum + s.durationMinutes))),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Termine'),
              trailing: Text('${events.length}'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Hausaufgaben'),
              trailing: Text('${homework.where((h) => h.status != HomeworkStatus.done).length} offen'),
            ),
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('Notizen'),
              trailing: Text('${notes.length}'),
            ),
          ], tokens),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
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
