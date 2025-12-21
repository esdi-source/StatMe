/// Trainingspläne Screen
/// 
/// Erstelle, verwalte und starte Trainingspläne:
/// - Übersicht aller Pläne
/// - Plan-Builder mit Übungsauswahl
/// - Schnellstart für Training

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../models/sport_model.dart';
import '../../services/exercise_db_service.dart';
import 'exercises_screen.dart';

class WorkoutPlansScreen extends ConsumerStatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  ConsumerState<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends ConsumerState<WorkoutPlansScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final plans = ref.watch(workoutPlansNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainingspläne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPlanBuilder(),
            tooltip: 'Neuer Plan',
          ),
        ],
      ),
      body: plans.isEmpty
          ? _buildEmptyState(tokens)
          : _buildPlansList(tokens, plans),
      floatingActionButton: plans.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showPlanBuilder,
              icon: const Icon(Icons.add),
              label: const Text('Neuer Plan'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: tokens.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Keine Trainingspläne',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Erstelle deinen ersten Trainingsplan mit Übungen aus der Datenbank.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showPlanBuilder,
              icon: const Icon(Icons.add),
              label: const Text('Plan erstellen'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showTemplates,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Vorlagen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(DesignTokens tokens, List<WorkoutPlan> plans) {
    // Gruppiere nach Typ
    final byType = <WorkoutPlanType, List<WorkoutPlan>>{};
    for (final plan in plans) {
      byType.putIfAbsent(plan.type, () => []).add(plan);
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Templates
        _buildQuickTemplates(tokens),
        const SizedBox(height: 24),
        
        // Pläne nach Typ
        ...byType.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '${entry.key.emoji} ${entry.key.label}',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ...entry.value.map((plan) => _buildPlanCard(tokens, plan)),
            const SizedBox(height: 16),
          ],
        )),
      ],
    );
  }

  Widget _buildQuickTemplates(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schnellstart',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTemplateChip(tokens, 'Push', WorkoutPlanType.push),
              _buildTemplateChip(tokens, 'Pull', WorkoutPlanType.pull),
              _buildTemplateChip(tokens, 'Legs', WorkoutPlanType.legs),
              _buildTemplateChip(tokens, 'Ganzkörper', WorkoutPlanType.fullBody),
              _buildTemplateChip(tokens, 'HIIT', WorkoutPlanType.hiit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateChip(DesignTokens tokens, String label, WorkoutPlanType type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Text(type.emoji),
        label: Text(label),
        onPressed: () => _createFromTemplate(type),
      ),
    );
  }

  Widget _buildPlanCard(DesignTokens tokens, WorkoutPlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showPlanDetails(plan),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(plan.type.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.fitness_center, size: 14, color: tokens.textDisabled),
                        const SizedBox(width: 4),
                        Text(
                          '${plan.exercises.length} Übungen',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer, size: 14, color: tokens.textDisabled),
                        const SizedBox(width: 4),
                        Text(
                          '~${plan.estimatedDurationMinutes} min',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (plan.primaryMuscles.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: plan.primaryMuscles.take(3).map((m) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getMuscleGerman(m),
                            style: TextStyle(
                              color: tokens.primary,
                              fontSize: 10,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.play_arrow, color: tokens.success),
                    onPressed: () => _startWorkout(plan),
                    tooltip: 'Training starten',
                  ),
                  Icon(Icons.chevron_right, color: tokens.textDisabled),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanBuilder({WorkoutPlan? existingPlan}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PlanBuilderScreen(existingPlan: existingPlan),
      ),
    );
  }

  void _showTemplates() {
    final tokens = ref.read(designTokensProvider);
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vorlagen',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('💪', style: TextStyle(fontSize: 28)),
              title: const Text('Push Day'),
              subtitle: const Text('Brust, Schultern, Trizeps'),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate(WorkoutPlanType.push);
              },
            ),
            ListTile(
              leading: const Text('🔙', style: TextStyle(fontSize: 28)),
              title: const Text('Pull Day'),
              subtitle: const Text('Rücken, Bizeps'),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate(WorkoutPlanType.pull);
              },
            ),
            ListTile(
              leading: const Text('🦵', style: TextStyle(fontSize: 28)),
              title: const Text('Leg Day'),
              subtitle: const Text('Beine, Gesäß'),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate(WorkoutPlanType.legs);
              },
            ),
            ListTile(
              leading: const Text('🏋️', style: TextStyle(fontSize: 28)),
              title: const Text('Ganzkörper'),
              subtitle: const Text('Alle Muskelgruppen'),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate(WorkoutPlanType.fullBody);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFromTemplate(WorkoutPlanType type) async {
    List<PlannedExercise> exercises = [];
    
    switch (type) {
      case WorkoutPlanType.push:
        final chest = await ExerciseDbService.getExercisesByMuscle('chest');
        final shoulders = await ExerciseDbService.getExercisesByMuscle('shoulders');
        final triceps = await ExerciseDbService.getExercisesByMuscle('triceps');
        exercises = [
          ...chest.take(2).map(_exerciseToPlanned),
          ...shoulders.take(2).map(_exerciseToPlanned),
          ...triceps.take(1).map(_exerciseToPlanned),
        ];
        break;
      case WorkoutPlanType.pull:
        final back = await ExerciseDbService.getExercisesByMuscle('back');
        final lats = await ExerciseDbService.getExercisesByMuscle('lats');
        final biceps = await ExerciseDbService.getExercisesByMuscle('biceps');
        exercises = [
          ...back.take(2).map(_exerciseToPlanned),
          ...lats.take(1).map(_exerciseToPlanned),
          ...biceps.take(2).map(_exerciseToPlanned),
        ];
        break;
      case WorkoutPlanType.legs:
        final quads = await ExerciseDbService.getExercisesByMuscle('quads');
        final hamstrings = await ExerciseDbService.getExercisesByMuscle('hamstrings');
        final glutes = await ExerciseDbService.getExercisesByMuscle('glutes');
        final calves = await ExerciseDbService.getExercisesByMuscle('calves');
        exercises = [
          ...quads.take(2).map(_exerciseToPlanned),
          ...hamstrings.take(1).map(_exerciseToPlanned),
          ...glutes.take(1).map(_exerciseToPlanned),
          ...calves.take(1).map(_exerciseToPlanned),
        ];
        break;
      case WorkoutPlanType.fullBody:
        final chest = await ExerciseDbService.getExercisesByMuscle('chest');
        final back = await ExerciseDbService.getExercisesByMuscle('back');
        final quads = await ExerciseDbService.getExercisesByMuscle('quads');
        final abs = await ExerciseDbService.getExercisesByMuscle('abs');
        exercises = [
          ...chest.take(1).map(_exerciseToPlanned),
          ...back.take(1).map(_exerciseToPlanned),
          ...quads.take(2).map(_exerciseToPlanned),
          ...abs.take(1).map(_exerciseToPlanned),
        ];
        break;
      default:
        exercises = [];
    }
    
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Übungen gefunden')),
      );
      return;
    }
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final plan = WorkoutPlan(
      id: const Uuid().v4(),
      userId: user.id,
      name: '${type.label} Workout',
      type: type,
      exercises: exercises,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await ref.read(workoutPlansNotifierProvider.notifier).add(plan);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plan.name} erstellt!')),
      );
    }
  }

  PlannedExercise _exerciseToPlanned(Exercise ex) {
    return PlannedExercise(
      exerciseId: ex.id,
      exerciseName: ex.nameDe,
      primaryMuscle: ex.primaryMuscle,
      secondaryMuscles: ex.secondaryMuscles,
      sets: 3,
      reps: 10,
      restSeconds: 60,
    );
  }

  void _showPlanDetails(WorkoutPlan plan) {
    final tokens = ref.read(designTokensProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLarge),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(tokens.radiusLarge),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(plan.type.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${plan.exercises.length} Übungen • ~${plan.estimatedDurationMinutes} min',
                              style: TextStyle(color: tokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pop(context);
                          _showPlanBuilder(existingPlan: plan);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref.read(workoutPlansNotifierProvider.notifier).delete(plan.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: plan.exercises.length,
                itemBuilder: (context, index) {
                  final ex = plan.exercises[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tokens.primary.withOpacity(0.1),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(ex.exerciseName),
                    subtitle: Text(ex.formattedSets),
                    trailing: ex.weightKg != null
                        ? Text('${ex.weightKg}kg', style: TextStyle(color: tokens.textSecondary))
                        : null,
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startWorkout(plan);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Training starten'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout(WorkoutPlan plan) {
    // TODO: Navigate to active workout screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} wird gestartet...')),
    );
  }

  String _getMuscleGerman(String muscle) {
    return switch (muscle.toLowerCase()) {
      'chest' => 'Brust',
      'shoulders' => 'Schultern',
      'triceps' => 'Trizeps',
      'back' => 'Rücken',
      'lats' => 'Latissimus',
      'biceps' => 'Bizeps',
      'quads' => 'Quadrizeps',
      'hamstrings' => 'Beinbizeps',
      'glutes' => 'Gesäß',
      'calves' => 'Waden',
      'abs' => 'Bauch',
      'obliques' => 'Schräge',
      'core' => 'Core',
      _ => muscle,
    };
  }
}

/// Plan Builder Screen - Erstelle/Bearbeite Trainingspläne
class _PlanBuilderScreen extends ConsumerStatefulWidget {
  final WorkoutPlan? existingPlan;
  
  const _PlanBuilderScreen({this.existingPlan});

  @override
  ConsumerState<_PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends ConsumerState<_PlanBuilderScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  WorkoutPlanType _type = WorkoutPlanType.custom;
  List<PlannedExercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _nameController.text = widget.existingPlan!.name;
      _descController.text = widget.existingPlan!.description ?? '';
      _type = widget.existingPlan!.type;
      _exercises = List.from(widget.existingPlan!.exercises);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPlan != null ? 'Plan bearbeiten' : 'Neuer Plan'),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'z.B. Push Day',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Typ
          DropdownButtonFormField<WorkoutPlanType>(
            value: _type,
            decoration: InputDecoration(
              labelText: 'Typ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
            ),
            items: WorkoutPlanType.values.map((type) => DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Text(type.emoji),
                  const SizedBox(width: 8),
                  Text(type.label),
                ],
              ),
            )).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
          const SizedBox(height: 16),
          
          // Beschreibung
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Beschreibung (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Übungen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Übungen (${_exercises.length})',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Hinzufügen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Übungsliste
          if (_exercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                border: Border.all(color: tokens.divider),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.fitness_center, size: 48, color: tokens.textDisabled),
                    const SizedBox(height: 12),
                    Text(
                      'Keine Übungen',
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _addExercise,
                      child: const Text('Übung hinzufügen'),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final ex = _exercises[index];
                return _buildExerciseItem(tokens, ex, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(DesignTokens tokens, PlannedExercise ex, int index) {
    return Dismissible(
      key: ValueKey('${ex.exerciseId}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _exercises.removeAt(index));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.drag_handle, color: tokens.textDisabled),
              ),
            ),
          ),
          title: Text(ex.exerciseName),
          subtitle: Text(ex.formattedSets),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editExercise(index),
          ),
        ),
      ),
    );
  }

  void _addExercise() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercisesScreen(
          onExerciseSelected: (exercise) {
            setState(() {
              _exercises.add(PlannedExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.nameDe,
                primaryMuscle: exercise.primaryMuscle,
                secondaryMuscles: exercise.secondaryMuscles,
                sets: 3,
                reps: 10,
                restSeconds: 60,
              ));
            });
          },
        ),
      ),
    );
  }

  void _editExercise(int index) {
    final ex = _exercises[index];
    final tokens = ref.read(designTokensProvider);
    
    int sets = ex.sets;
    int reps = ex.reps ?? 10;
    double? weight = ex.weightKg;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLarge),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex.exerciseName,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Sets
              Row(
                children: [
                  const Text('Sets:'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: sets > 1 ? () => setModalState(() => sets--) : null,
                  ),
                  Text('$sets', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setModalState(() => sets++),
                  ),
                ],
              ),
              
              // Reps
              Row(
                children: [
                  const Text('Reps:'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: reps > 1 ? () => setModalState(() => reps--) : null,
                  ),
                  Text('$reps', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setModalState(() => reps++),
                  ),
                ],
              ),
              
              // Weight
              Row(
                children: [
                  const Text('Gewicht (kg):'),
                  const Spacer(),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '-',
                        isDense: true,
                      ),
                      controller: TextEditingController(text: weight?.toString() ?? ''),
                      onChanged: (v) => weight = double.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _exercises[index] = ex.copyWith(
                        sets: sets,
                        reps: reps,
                        weightKg: weight,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Speichern'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePlan() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen ein')),
      );
      return;
    }
    
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Füge mindestens eine Übung hinzu')),
      );
      return;
    }
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final plan = WorkoutPlan(
      id: widget.existingPlan?.id ?? const Uuid().v4(),
      userId: user.id,
      name: _nameController.text,
      description: _descController.text.isEmpty ? null : _descController.text,
      type: _type,
      exercises: _exercises,
      createdAt: widget.existingPlan?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    if (widget.existingPlan != null) {
      await ref.read(workoutPlansNotifierProvider.notifier).update(plan);
    } else {
      await ref.read(workoutPlansNotifierProvider.notifier).add(plan);
    }
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plan.name} gespeichert!')),
      );
    }
  }
}
