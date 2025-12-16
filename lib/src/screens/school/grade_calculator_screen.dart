/// Notenrechner Screen - Berechne benötigte Noten für Wunschschnitt

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class GradeCalculatorScreen extends ConsumerStatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  ConsumerState<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends ConsumerState<GradeCalculatorScreen> {
  String? _selectedSubjectId;
  double _targetAverage = 10.0;
  final List<_TempGrade> _hypotheticalGrades = [];

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final subjects = ref.watch(subjectsNotifierProvider);
    final grades = ref.watch(gradesNotifierProvider);

    // Noten für ausgewähltes Fach
    final subjectGrades = _selectedSubjectId != null
        ? grades.where((g) => g.subjectId == _selectedSubjectId).toList()
        : <Grade>[];

    // Durchschnitt berechnen
    final currentAverage = _calculateAverage(subjectGrades);
    final projectedAverage = _calculateProjectedAverage(subjectGrades);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notenrechner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fach auswählen
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fach auswählen', style: TextStyle(color: tokens.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedSubjectId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Alle Fächer')),
                        ...subjects.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        )),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedSubjectId = value;
                        _hypotheticalGrades.clear();
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Aktueller Schnitt
            if (_selectedSubjectId != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAverageDisplay(
                          'Aktueller Schnitt',
                          currentAverage,
                          tokens,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: tokens.surface,
                      ),
                      Expanded(
                        child: _buildAverageDisplay(
                          'Prognose',
                          projectedAverage,
                          tokens,
                          isProjected: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vorhandene Noten
              Text('Vorhandene Noten (${subjectGrades.length})', 
                   style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (subjectGrades.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Noch keine Noten eingetragen',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjectGrades.map((g) => Chip(
                    label: Text('${g.points} (${g.type.label})'),
                    backgroundColor: _getGradeColor(g.points).withOpacity(0.2),
                  )).toList(),
                ),
              const SizedBox(height: 24),

              // Hypothetische Noten
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Was-wäre-wenn', style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _addHypotheticalGrade,
                    icon: const Icon(Icons.add),
                    label: const Text('Note hinzufügen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_hypotheticalGrades.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Füge hypothetische Noten hinzu',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_hypotheticalGrades.length, (index) {
                  final grade = _hypotheticalGrades[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getGradeColor(grade.points),
                        child: Text(
                          '${grade.points}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(grade.type.label),
                      subtitle: Text('Gewichtung: ${(grade.weight * 100).toInt()}%'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: tokens.error),
                        onPressed: () => setState(() => _hypotheticalGrades.removeAt(index)),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Zielschnitt
              Card(
                color: tokens.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welche Note brauchst du?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Ziel-Schnitt:', style: TextStyle(color: tokens.textSecondary)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: _targetAverage,
                              min: 1,
                              max: 15,
                              divisions: 14,
                              label: _targetAverage.toStringAsFixed(0),
                              onChanged: (value) => setState(() => _targetAverage = value),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getGradeColor(_targetAverage.round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_targetAverage.round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRequiredGradeCalculation(subjectGrades, tokens),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Gesamtübersicht
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Übersicht alle Fächer', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      ...subjects.map((subject) {
                        final sGrades = grades.where((g) => g.subjectId == subject.id).toList();
                        final avg = _calculateAverage(sGrades);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(child: Text(subject.name)),
                              if (sGrades.isNotEmpty) ...[
                                Text('${sGrades.length} Noten'),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(avg.round()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    avg.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ] else
                                Text('Keine Noten', style: TextStyle(color: tokens.textSecondary)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAverageDisplay(String label, double value, DesignTokens tokens, {bool isProjected = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value.isNaN ? '-' : value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isProjected ? tokens.primary : _getGradeColor(value.round()),
          ),
        ),
        if (!value.isNaN)
          Text(
            _getGradeLetter(value),
            style: TextStyle(color: tokens.textSecondary),
          ),
      ],
    );
  }

  Widget _buildRequiredGradeCalculation(List<Grade> existingGrades, DesignTokens tokens) {
    final allGrades = [
      ...existingGrades.map((g) => _TempGrade(g.points, g.type, g.weight)),
      ..._hypotheticalGrades,
    ];

    if (allGrades.isEmpty) {
      return Text(
        'Trage erst Noten ein, um eine Berechnung zu sehen.',
        style: TextStyle(color: tokens.textSecondary),
      );
    }

    final totalWeight = allGrades.fold<double>(0, (sum, g) => sum + g.weight);
    final weightedSum = allGrades.fold<double>(0, (sum, g) => sum + g.points * g.weight);

    // Berechne benötigte Note für eine zusätzliche Note mit Gewicht 1
    final requiredPoints = (_targetAverage * (totalWeight + 1) - weightedSum);

    String message;
    if (requiredPoints <= 0) {
      message = '✨ Du hast dein Ziel bereits erreicht!';
    } else if (requiredPoints > 15) {
      message = '😰 Leider nicht mehr erreichbar mit einer Note.';
    } else {
      message = 'Du brauchst mindestens ${requiredPoints.ceil()} Punkte in der nächsten Note.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            requiredPoints <= 0 
                ? Icons.check_circle 
                : requiredPoints > 15 
                    ? Icons.warning 
                    : Icons.info_outline,
            color: requiredPoints <= 0 
                ? tokens.success 
                : requiredPoints > 15 
                    ? tokens.error 
                    : tokens.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  double _calculateAverage(List<Grade> grades) {
    if (grades.isEmpty) return double.nan;
    
    double totalWeight = 0;
    double weightedSum = 0;
    
    for (final grade in grades) {
      weightedSum += grade.points * grade.weight;
      totalWeight += grade.weight;
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : double.nan;
  }

  double _calculateProjectedAverage(List<Grade> existingGrades) {
    final allGrades = [
      ...existingGrades.map((g) => _TempGrade(g.points, g.type, g.weight)),
      ..._hypotheticalGrades,
    ];
    
    if (allGrades.isEmpty) return double.nan;
    
    double totalWeight = 0;
    double weightedSum = 0;
    
    for (final grade in allGrades) {
      weightedSum += grade.points * grade.weight;
      totalWeight += grade.weight;
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : double.nan;
  }

  void _addHypotheticalGrade() {
    GradeType selectedType = GradeType.oralExam;
    int selectedPoints = 10;
    double selectedWeight = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hypothetische Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Punkte
              Text('Punkte: $selectedPoints'),
              Slider(
                value: selectedPoints.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                label: '$selectedPoints',
                onChanged: (value) => setDialogState(() => selectedPoints = value.round()),
              ),
              const SizedBox(height: 12),
              // Typ
              DropdownButtonFormField<GradeType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Art'),
                items: GradeType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.label),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedType = value;
                      selectedWeight = value.defaultWeight;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              // Gewichtung
              Text('Gewichtung: ${(selectedWeight * 100).toInt()}%'),
              Slider(
                value: selectedWeight,
                min: 0.25,
                max: 2.0,
                divisions: 7,
                label: '${(selectedWeight * 100).toInt()}%',
                onChanged: (value) => setDialogState(() => selectedWeight = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _hypotheticalGrades.add(_TempGrade(selectedPoints, selectedType, selectedWeight));
                });
                Navigator.pop(context);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(int points) {
    if (points >= 13) return Colors.green;
    if (points >= 10) return Colors.lightGreen;
    if (points >= 7) return Colors.amber;
    if (points >= 4) return Colors.orange;
    return Colors.red;
  }

  String _getGradeLetter(double points) {
    if (points >= 13) return 'Sehr gut (1)';
    if (points >= 10) return 'Gut (2)';
    if (points >= 7) return 'Befriedigend (3)';
    if (points >= 4) return 'Ausreichend (4)';
    if (points >= 1) return 'Mangelhaft (5)';
    return 'Ungenügend (6)';
  }
}

class _TempGrade {
  final int points;
  final GradeType type;
  final double weight;

  _TempGrade(this.points, this.type, this.weight);
}
