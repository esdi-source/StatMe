/// Noten Screen - Alle Noten mit Trend und Durchschnitt

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final grades = ref.watch(gradesNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);

    // Gruppieren nach Fach
    final gradesBySubject = <String, List<Grade>>{};
    for (final grade in grades) {
      gradesBySubject.putIfAbsent(grade.subjectId, () => []).add(grade);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noten'),
        actions: [
          if (grades.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Ø ${ref.read(gradesNotifierProvider.notifier).overallAverage.toStringAsFixed(1)} P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tokens.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: grades.isEmpty
          ? _buildEmptyState(tokens)
          : _buildGradesList(gradesBySubject, subjects, tokens, ref),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGradeDialog(context, ref, subjects, tokens),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade_outlined, size: 80, color: tokens.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Noch keine Noten eingetragen',
            style: TextStyle(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList(
    Map<String, List<Grade>> gradesBySubject,
    List<Subject> subjects,
    DesignTokens tokens,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gradesBySubject.length,
      itemBuilder: (context, index) {
        final subjectId = gradesBySubject.keys.elementAt(index);
        final subjectGrades = gradesBySubject[subjectId]!
          ..sort((a, b) => b.date.compareTo(a.date));
        final subject = subjects.cast<Subject?>().firstWhere(
          (s) => s?.id == subjectId,
          orElse: () => null,
        );
        
        final average = ref.read(gradesNotifierProvider.notifier).getAverageForSubject(subjectId);
        final trend = _calculateTrend(subjectGrades);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: subject?.colorValue != null
                  ? Color(subject!.colorValue!)
                  : tokens.primary,
              child: Text(
                subject?.shortName ?? subject?.name.substring(0, 1) ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(subject?.name ?? 'Unbekannt'),
            subtitle: Row(
              children: [
                Text('Ø ${average.toStringAsFixed(1)} Punkte'),
                const SizedBox(width: 8),
                _buildTrendIcon(trend, tokens),
              ],
            ),
            children: subjectGrades.map((grade) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getGradeColor(grade.points),
                radius: 18,
                child: Text(
                  '${grade.points}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              title: Text(grade.type.label),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(grade.date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (grade.weight != 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tokens.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×${grade.weight}',
                        style: TextStyle(fontSize: 12, color: tokens.primary),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref.read(gradesNotifierProvider.notifier).delete(grade.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTrendIcon(int trend, DesignTokens tokens) {
    if (trend == 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: Colors.green, size: 16),
          const SizedBox(width: 2),
          Text('steigend', style: TextStyle(fontSize: 11, color: Colors.green)),
        ],
      );
    } else if (trend == -1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_down, color: Colors.red, size: 16),
          const SizedBox(width: 2),
          Text('fallend', style: TextStyle(fontSize: 11, color: Colors.red)),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_flat, color: tokens.textSecondary, size: 16),
        const SizedBox(width: 2),
        Text('stabil', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
      ],
    );
  }

  int _calculateTrend(List<Grade> grades) {
    if (grades.length < 2) return 0;
    final sorted = List<Grade>.from(grades)..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length < 2) return 0;
    
    final midPoint = sorted.length ~/ 2;
    final firstHalf = sorted.take(midPoint).map((g) => g.points).toList();
    final secondHalf = sorted.skip(midPoint).map((g) => g.points).toList();
    
    if (firstHalf.isEmpty || secondHalf.isEmpty) return 0;
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    if (secondAvg > firstAvg + 1) return 1;
    if (secondAvg < firstAvg - 1) return -1;
    return 0;
  }

  Color _getGradeColor(int points) {
    if (points >= 13) return Colors.green;
    if (points >= 10) return Colors.lightGreen;
    if (points >= 7) return Colors.amber;
    if (points >= 4) return Colors.orange;
    return Colors.red;
  }

  void _showAddGradeDialog(BuildContext context, WidgetRef ref, List<Subject> subjects, DesignTokens tokens) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte erst ein Fach anlegen')),
      );
      return;
    }

    String? selectedSubjectId = subjects.first.id;
    GradeType selectedType = GradeType.exam;
    int points = 10;
    double weight = 1.0;
    DateTime selectedDate = DateTime.now();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Note eintragen'),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<GradeType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Art'),
                  items: GradeType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                
                // Punkte Auswahl (1-15)
                Text('Punkte: $points', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: points.toDouble(),
                  min: 0,
                  max: 15,
                  divisions: 15,
                  label: '$points',
                  onChanged: (value) => setState(() => points = value.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0', style: TextStyle(fontSize: 12)),
                    Text('15', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Gewichtung
                Row(
                  children: [
                    const Text('Gewichtung: '),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: weight,
                        items: [0.5, 1.0, 1.5, 2.0, 3.0].map((w) => DropdownMenuItem(
                          value: w,
                          child: Text('×$w'),
                        )).toList(),
                        onChanged: (value) => setState(() => weight = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Datum
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
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
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
                final grade = Grade(
                  id: 'grade_${now.millisecondsSinceEpoch}',
                  userId: user.id,
                  subjectId: selectedSubjectId!,
                  points: points,
                  type: selectedType,
                  weight: weight,
                  date: selectedDate,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await ref.read(gradesNotifierProvider.notifier).add(grade);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Eintragen'),
            ),
          ],
        ),
      ),
    );
  }
}
