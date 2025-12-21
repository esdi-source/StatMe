/// Übungen Datenbank Screen
/// 
/// Durchsuche und wähle Übungen nach:
/// - Muskelgruppe
/// - Kategorie (Push/Pull/Legs/Core)
/// - Equipment

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/exercise_db_service.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  /// Optional: Callback wenn Übung ausgewählt wird (für Plan-Builder)
  final void Function(Exercise)? onExerciseSelected;
  
  const ExercisesScreen({super.key, this.onExerciseSelected});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMuscle;
  ExerciseCategory? _selectedCategory;

  static const _muscleGroups = [
    ('chest', 'Brust', Icons.accessibility_new),
    ('shoulders', 'Schultern', Icons.accessibility),
    ('triceps', 'Trizeps', Icons.fitness_center),
    ('back', 'Rücken', Icons.airline_seat_recline_normal),
    ('lats', 'Latissimus', Icons.height),
    ('biceps', 'Bizeps', Icons.sports_martial_arts),
    ('quads', 'Quadrizeps', Icons.directions_run),
    ('hamstrings', 'Beinbizeps', Icons.directions_walk),
    ('glutes', 'Gesäß', Icons.chair),
    ('calves', 'Waden', Icons.snowboarding),
    ('abs', 'Bauch', Icons.grid_view),
    ('obliques', 'Schräge Bauchmuskeln', Icons.rotate_right),
  ];

  static const _categories = [
    (ExerciseCategory.push, 'Push', '💪'),
    (ExerciseCategory.pull, 'Pull', '🔙'),
    (ExerciseCategory.legs, 'Legs', '🦵'),
    (ExerciseCategory.core, 'Core', '🎯'),
    (ExerciseCategory.cardio, 'Cardio', '❤️'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Übungen'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Suche'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Muskeln'),
            Tab(icon: Icon(Icons.category), text: 'Kategorie'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(tokens),
          _buildMuscleTab(tokens),
          _buildCategoryTab(tokens),
        ],
      ),
    );
  }

  Widget _buildSearchTab(DesignTokens tokens) {
    final allExercises = ref.watch(allExercisesProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Übung suchen...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: allExercises.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (exercises) {
              final filtered = _searchQuery.isEmpty
                  ? exercises
                  : exercises.where((e) =>
                      e.nameDe.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      e.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      e.primaryMuscle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      e.category.label.toLowerCase().contains(_searchQuery.toLowerCase())
                    ).toList();
              
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: tokens.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty 
                            ? 'Suche nach einer Übung'
                            : 'Keine Übungen gefunden',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              
              return _buildExerciseList(tokens, filtered);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleTab(DesignTokens tokens) {
    if (_selectedMuscle != null) {
      return _buildMuscleExercises(tokens, _selectedMuscle!);
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _muscleGroups.length,
      itemBuilder: (context, index) {
        final (id, name, icon) = _muscleGroups[index];
        return _buildMuscleCard(tokens, id, name, icon);
      },
    );
  }

  Widget _buildMuscleCard(DesignTokens tokens, String id, String name, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMuscle = id),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: tokens.primary),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleExercises(DesignTokens tokens, String muscleId) {
    final exercises = ref.watch(exercisesByMuscleProvider(muscleId));
    final muscleName = _muscleGroups.firstWhere((m) => m.$1 == muscleId).$2;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedMuscle = null),
              ),
              Text(
                muscleName,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: exercises.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (list) => _buildExerciseList(tokens, list),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(DesignTokens tokens) {
    if (_selectedCategory != null) {
      return _buildCategoryExercises(tokens, _selectedCategory!);
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final (id, name, emoji) = _categories[index];
        return _buildCategoryCard(tokens, id, name, emoji);
      },
    );
  }

  Widget _buildCategoryCard(DesignTokens tokens, ExerciseCategory category, String name, String emoji) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryExercises(DesignTokens tokens, ExerciseCategory category) {
    final exercises = ref.watch(exercisesByCategoryProvider(category));
    final categoryName = _categories.firstWhere((c) => c.$1 == category).$2;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedCategory = null),
              ),
              Text(
                categoryName,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: exercises.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (list) => _buildExerciseList(tokens, list),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(DesignTokens tokens, List<Exercise> exercises) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(tokens, exercise);
      },
    );
  }

  Widget _buildExerciseCard(DesignTokens tokens, Exercise exercise) {
    final isSelectable = widget.onExerciseSelected != null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isSelectable
            ? () {
                widget.onExerciseSelected!(exercise);
                Navigator.of(context).pop();
              }
            : () => _showExerciseDetails(exercise),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Equipment Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getEquipmentEmoji(exercise.equipment.isNotEmpty ? exercise.equipment.first : 'bodyweight'),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nameDe,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(tokens, _getMuscleGerman(exercise.primaryMuscle), tokens.primary),
                        const SizedBox(width: 6),
                        _buildTag(tokens, exercise.category.label, tokens.textDisabled),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelectable)
                Icon(Icons.add_circle, color: tokens.primary)
              else
                Icon(Icons.chevron_right, color: tokens.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(DesignTokens tokens, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getEquipmentEmoji(String equipment) {
    return switch (equipment.toLowerCase()) {
      'bodyweight' => '🏃',
      'dumbbells' => '🏋️',
      'barbell' => '🏋️‍♂️',
      'kettlebell' => '🔔',
      'machine' => '⚙️',
      'cable' => '🔗',
      'bands' => '🎗️',
      'pullup_bar' => '🧗',
      'bench' => '🪑',
      _ => '💪',
    };
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
      'full_body' => 'Ganzkörper',
      _ => muscle,
    };
  }

  void _showExerciseDetails(Exercise exercise) {
    final tokens = ref.read(designTokensProvider);
    final mainEquipment = exercise.equipment.isNotEmpty ? exercise.equipment.first : 'bodyweight';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLarge),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Übungsname
              Text(
                exercise.nameDe,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDetailTag(tokens, '💪 ${_getMuscleGerman(exercise.primaryMuscle)}', tokens.primary),
                  _buildDetailTag(tokens, '${_getEquipmentEmoji(mainEquipment)} ${_getEquipmentGerman(mainEquipment)}', tokens.secondary),
                  _buildDetailTag(tokens, exercise.category.label, tokens.textSecondary),
                  if (exercise.caloriesPerMinute > 0)
                    _buildDetailTag(tokens, '🔥 ~${exercise.caloriesPerMinute} kcal/min', Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              
              // Sekundäre Muskeln
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                Text(
                  'Sekundäre Muskeln',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: exercise.secondaryMuscles
                      .map((m) => _buildDetailTag(tokens, _getMuscleGerman(m), tokens.textDisabled))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
              
              // Beschreibung
              if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
                Text(
                  'Beschreibung',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.instructions!,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Zum Trainingsplan hinzufügen
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erstelle einen Trainingsplan um Übungen hinzuzufügen')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Zum Trainingsplan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTag(DesignTokens tokens, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getEquipmentGerman(String equipment) {
    return switch (equipment.toLowerCase()) {
      'bodyweight' => 'Körpergewicht',
      'dumbbells' => 'Kurzhanteln',
      'barbell' => 'Langhantel',
      'kettlebell' => 'Kettlebell',
      'machine' => 'Maschine',
      'cable' => 'Kabelzug',
      'bands' => 'Bänder',
      'pullup_bar' => 'Klimmzugstange',
      'bench' => 'Bank',
      _ => equipment,
    };
  }
}
