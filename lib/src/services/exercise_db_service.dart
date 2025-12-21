import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service für Übungs-Datenbank (ExerciseDB-ähnlich)
/// Bietet strukturierte Übungsdaten mit Muskelgruppen
class ExerciseDbService {
  // Lokaler Cache Key
  static const _cacheKey = 'exercise_db_cache';
  static const _cacheTimestampKey = 'exercise_db_cache_timestamp';
  static const _cacheDurationDays = 7;
  
  // ============================================================================
  // MUSKELGRUPPEN (Dynamisch, nicht hardcoded)
  // ============================================================================
  
  /// Alle Muskelgruppen
  static List<MuscleGroup> get allMuscleGroups => _muscleGroups;
  
  static final List<MuscleGroup> _muscleGroups = [
    // Oberkörper - Push
    MuscleGroup(id: 'chest', nameEn: 'Chest', nameDe: 'Brust', category: MuscleCategory.push),
    MuscleGroup(id: 'shoulders', nameEn: 'Shoulders', nameDe: 'Schultern', category: MuscleCategory.push),
    MuscleGroup(id: 'triceps', nameEn: 'Triceps', nameDe: 'Trizeps', category: MuscleCategory.push),
    
    // Oberkörper - Pull
    MuscleGroup(id: 'back', nameEn: 'Back', nameDe: 'Rücken', category: MuscleCategory.pull),
    MuscleGroup(id: 'lats', nameEn: 'Lats', nameDe: 'Latissimus', category: MuscleCategory.pull),
    MuscleGroup(id: 'biceps', nameEn: 'Biceps', nameDe: 'Bizeps', category: MuscleCategory.pull),
    MuscleGroup(id: 'forearms', nameEn: 'Forearms', nameDe: 'Unterarme', category: MuscleCategory.pull),
    MuscleGroup(id: 'traps', nameEn: 'Traps', nameDe: 'Trapezius', category: MuscleCategory.pull),
    
    // Unterkörper
    MuscleGroup(id: 'quads', nameEn: 'Quadriceps', nameDe: 'Oberschenkel (vorne)', category: MuscleCategory.legs),
    MuscleGroup(id: 'hamstrings', nameEn: 'Hamstrings', nameDe: 'Oberschenkel (hinten)', category: MuscleCategory.legs),
    MuscleGroup(id: 'glutes', nameEn: 'Glutes', nameDe: 'Gesäß', category: MuscleCategory.legs),
    MuscleGroup(id: 'calves', nameEn: 'Calves', nameDe: 'Waden', category: MuscleCategory.legs),
    MuscleGroup(id: 'adductors', nameEn: 'Adductors', nameDe: 'Adduktoren', category: MuscleCategory.legs),
    
    // Core
    MuscleGroup(id: 'abs', nameEn: 'Abs', nameDe: 'Bauch', category: MuscleCategory.core),
    MuscleGroup(id: 'obliques', nameEn: 'Obliques', nameDe: 'Seitliche Bauchmuskeln', category: MuscleCategory.core),
    MuscleGroup(id: 'lower_back', nameEn: 'Lower Back', nameDe: 'Unterer Rücken', category: MuscleCategory.core),
  ];
  
  static MuscleGroup? getMuscleGroupById(String id) {
    try {
      return _muscleGroups.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
  
  // ============================================================================
  // EQUIPMENT
  // ============================================================================
  
  static final List<Equipment> allEquipment = [
    Equipment(id: 'bodyweight', nameEn: 'Bodyweight', nameDe: 'Körpergewicht', icon: '🏃'),
    Equipment(id: 'dumbbell', nameEn: 'Dumbbell', nameDe: 'Kurzhantel', icon: '🏋️'),
    Equipment(id: 'barbell', nameEn: 'Barbell', nameDe: 'Langhantel', icon: '🏋️‍♂️'),
    Equipment(id: 'kettlebell', nameEn: 'Kettlebell', nameDe: 'Kettlebell', icon: '🔔'),
    Equipment(id: 'cable', nameEn: 'Cable Machine', nameDe: 'Kabelzug', icon: '🔌'),
    Equipment(id: 'machine', nameEn: 'Machine', nameDe: 'Gerät', icon: '🏭'),
    Equipment(id: 'resistance_band', nameEn: 'Resistance Band', nameDe: 'Widerstandsband', icon: '🎗️'),
    Equipment(id: 'pull_up_bar', nameEn: 'Pull-up Bar', nameDe: 'Klimmzugstange', icon: '📏'),
    Equipment(id: 'bench', nameEn: 'Bench', nameDe: 'Bank', icon: '🪑'),
    Equipment(id: 'ez_bar', nameEn: 'EZ Bar', nameDe: 'SZ-Stange', icon: '〰️'),
  ];
  
  // ============================================================================
  // DEUTSCH-ENGLISCH ÜBERSETZUNG
  // ============================================================================
  
  static final Map<String, String> _germanToEnglish = {
    // Körperteile
    'brust': 'chest',
    'schultern': 'shoulders',
    'schulter': 'shoulders',
    'trizeps': 'triceps',
    'rücken': 'back',
    'bizeps': 'biceps',
    'unterarme': 'forearms',
    'unterarm': 'forearms',
    'beine': 'legs',
    'oberschenkel': 'quads',
    'quadrizeps': 'quads',
    'beinbeuger': 'hamstrings',
    'po': 'glutes',
    'gesäß': 'glutes',
    'waden': 'calves',
    'wade': 'calves',
    'bauch': 'abs',
    'core': 'core',
    
    // Übungen
    'liegestütze': 'push ups',
    'liegestütz': 'push ups',
    'klimmzüge': 'pull ups',
    'klimmzug': 'pull ups',
    'kniebeugen': 'squats',
    'kniebeuge': 'squats',
    'kreuzheben': 'deadlift',
    'bankdrücken': 'bench press',
    'schulterdrücken': 'shoulder press',
    'rudern': 'row',
    'planke': 'plank',
    'unterarmstütz': 'plank',
    'ausfallschritte': 'lunges',
    'ausfallschritt': 'lunges',
    'dips': 'dips',
    'sit-ups': 'sit ups',
    'situps': 'sit ups',
    'crunches': 'crunches',
    'bizeps curls': 'bicep curls',
    'trizeps drücken': 'tricep pushdown',
    'beinpresse': 'leg press',
    'wadenheben': 'calf raises',
    'seitheben': 'lateral raise',
    'frontheben': 'front raise',
    'butterfly': 'chest fly',
    'fliegende': 'chest fly',
    
    // Equipment
    'kurzhantel': 'dumbbell',
    'kurzhanteln': 'dumbbell',
    'langhantel': 'barbell',
    'körpergewicht': 'bodyweight',
    'kabelzug': 'cable',
    'gerät': 'machine',
    'maschine': 'machine',
    'band': 'resistance band',
    'theraband': 'resistance band',
    'klimmzugstange': 'pull up bar',
    'bank': 'bench',
  };
  
  static String translateToEnglish(String german) {
    final lower = german.toLowerCase().trim();
    if (_germanToEnglish.containsKey(lower)) {
      return _germanToEnglish[lower]!;
    }
    for (final entry in _germanToEnglish.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return german;
  }
  
  // ============================================================================
  // EINGEBAUTE ÜBUNGSDATENBANK
  // ============================================================================
  
  /// Vordefinierte Übungen (keine API nötig für Basis-Funktionalität)
  static final List<Exercise> _builtInExercises = [
    // ===== BRUST (Push) =====
    Exercise(
      id: 'bench_press',
      nameEn: 'Bench Press',
      nameDe: 'Bankdrücken',
      primaryMuscle: 'chest',
      secondaryMuscles: ['triceps', 'shoulders'],
      equipment: ['barbell', 'bench'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 8,
    ),
    Exercise(
      id: 'push_ups',
      nameEn: 'Push Ups',
      nameDe: 'Liegestütze',
      primaryMuscle: 'chest',
      secondaryMuscles: ['triceps', 'shoulders', 'abs'],
      equipment: ['bodyweight'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 7,
    ),
    Exercise(
      id: 'incline_bench_press',
      nameEn: 'Incline Bench Press',
      nameDe: 'Schrägbankdrücken',
      primaryMuscle: 'chest',
      secondaryMuscles: ['triceps', 'shoulders'],
      equipment: ['barbell', 'dumbbell', 'bench'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 8,
    ),
    Exercise(
      id: 'chest_fly',
      nameEn: 'Chest Fly',
      nameDe: 'Fliegende',
      primaryMuscle: 'chest',
      secondaryMuscles: ['shoulders'],
      equipment: ['dumbbell', 'cable', 'bench'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 6,
    ),
    Exercise(
      id: 'dips',
      nameEn: 'Dips',
      nameDe: 'Dips',
      primaryMuscle: 'chest',
      secondaryMuscles: ['triceps', 'shoulders'],
      equipment: ['bodyweight'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 8,
    ),
    
    // ===== SCHULTERN (Push) =====
    Exercise(
      id: 'shoulder_press',
      nameEn: 'Shoulder Press',
      nameDe: 'Schulterdrücken',
      primaryMuscle: 'shoulders',
      secondaryMuscles: ['triceps', 'traps'],
      equipment: ['barbell', 'dumbbell'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 7,
    ),
    Exercise(
      id: 'lateral_raise',
      nameEn: 'Lateral Raise',
      nameDe: 'Seitheben',
      primaryMuscle: 'shoulders',
      secondaryMuscles: ['traps'],
      equipment: ['dumbbell', 'cable'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    Exercise(
      id: 'front_raise',
      nameEn: 'Front Raise',
      nameDe: 'Frontheben',
      primaryMuscle: 'shoulders',
      secondaryMuscles: ['chest'],
      equipment: ['dumbbell', 'cable', 'barbell'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    
    // ===== TRIZEPS (Push) =====
    Exercise(
      id: 'tricep_pushdown',
      nameEn: 'Tricep Pushdown',
      nameDe: 'Trizepsdrücken am Kabel',
      primaryMuscle: 'triceps',
      secondaryMuscles: [],
      equipment: ['cable'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    Exercise(
      id: 'skull_crushers',
      nameEn: 'Skull Crushers',
      nameDe: 'French Press',
      primaryMuscle: 'triceps',
      secondaryMuscles: [],
      equipment: ['ez_bar', 'dumbbell', 'bench'],
      category: ExerciseCategory.push,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 6,
    ),
    
    // ===== RÜCKEN (Pull) =====
    Exercise(
      id: 'pull_ups',
      nameEn: 'Pull Ups',
      nameDe: 'Klimmzüge',
      primaryMuscle: 'lats',
      secondaryMuscles: ['biceps', 'back', 'forearms'],
      equipment: ['pull_up_bar', 'bodyweight'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 9,
    ),
    Exercise(
      id: 'lat_pulldown',
      nameEn: 'Lat Pulldown',
      nameDe: 'Latzug',
      primaryMuscle: 'lats',
      secondaryMuscles: ['biceps', 'back'],
      equipment: ['cable', 'machine'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 6,
    ),
    Exercise(
      id: 'barbell_row',
      nameEn: 'Barbell Row',
      nameDe: 'Langhantelrudern',
      primaryMuscle: 'back',
      secondaryMuscles: ['biceps', 'lats', 'lower_back'],
      equipment: ['barbell'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 8,
    ),
    Exercise(
      id: 'dumbbell_row',
      nameEn: 'Dumbbell Row',
      nameDe: 'Kurzhantelrudern',
      primaryMuscle: 'back',
      secondaryMuscles: ['biceps', 'lats'],
      equipment: ['dumbbell', 'bench'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 7,
    ),
    Exercise(
      id: 'deadlift',
      nameEn: 'Deadlift',
      nameDe: 'Kreuzheben',
      primaryMuscle: 'back',
      secondaryMuscles: ['hamstrings', 'glutes', 'lower_back', 'traps', 'forearms'],
      equipment: ['barbell'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.advanced,
      caloriesPerMinute: 10,
    ),
    Exercise(
      id: 'face_pulls',
      nameEn: 'Face Pulls',
      nameDe: 'Face Pulls',
      primaryMuscle: 'back',
      secondaryMuscles: ['shoulders', 'traps'],
      equipment: ['cable'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    
    // ===== BIZEPS (Pull) =====
    Exercise(
      id: 'bicep_curls',
      nameEn: 'Bicep Curls',
      nameDe: 'Bizeps Curls',
      primaryMuscle: 'biceps',
      secondaryMuscles: ['forearms'],
      equipment: ['dumbbell', 'barbell', 'cable'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    Exercise(
      id: 'hammer_curls',
      nameEn: 'Hammer Curls',
      nameDe: 'Hammer Curls',
      primaryMuscle: 'biceps',
      secondaryMuscles: ['forearms'],
      equipment: ['dumbbell'],
      category: ExerciseCategory.pull,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    
    // ===== BEINE =====
    Exercise(
      id: 'squats',
      nameEn: 'Squats',
      nameDe: 'Kniebeugen',
      primaryMuscle: 'quads',
      secondaryMuscles: ['glutes', 'hamstrings', 'abs', 'lower_back'],
      equipment: ['barbell', 'bodyweight'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 9,
    ),
    Exercise(
      id: 'leg_press',
      nameEn: 'Leg Press',
      nameDe: 'Beinpresse',
      primaryMuscle: 'quads',
      secondaryMuscles: ['glutes', 'hamstrings'],
      equipment: ['machine'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 7,
    ),
    Exercise(
      id: 'lunges',
      nameEn: 'Lunges',
      nameDe: 'Ausfallschritte',
      primaryMuscle: 'quads',
      secondaryMuscles: ['glutes', 'hamstrings'],
      equipment: ['bodyweight', 'dumbbell'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 7,
    ),
    Exercise(
      id: 'leg_curls',
      nameEn: 'Leg Curls',
      nameDe: 'Beinbeuger',
      primaryMuscle: 'hamstrings',
      secondaryMuscles: ['calves'],
      equipment: ['machine'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    Exercise(
      id: 'leg_extension',
      nameEn: 'Leg Extension',
      nameDe: 'Beinstrecken',
      primaryMuscle: 'quads',
      secondaryMuscles: [],
      equipment: ['machine'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    Exercise(
      id: 'romanian_deadlift',
      nameEn: 'Romanian Deadlift',
      nameDe: 'Rumänisches Kreuzheben',
      primaryMuscle: 'hamstrings',
      secondaryMuscles: ['glutes', 'lower_back'],
      equipment: ['barbell', 'dumbbell'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 8,
    ),
    Exercise(
      id: 'hip_thrust',
      nameEn: 'Hip Thrust',
      nameDe: 'Hip Thrust',
      primaryMuscle: 'glutes',
      secondaryMuscles: ['hamstrings'],
      equipment: ['barbell', 'bench', 'bodyweight'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 7,
    ),
    Exercise(
      id: 'calf_raises',
      nameEn: 'Calf Raises',
      nameDe: 'Wadenheben',
      primaryMuscle: 'calves',
      secondaryMuscles: [],
      equipment: ['machine', 'bodyweight', 'dumbbell'],
      category: ExerciseCategory.legs,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 4,
    ),
    
    // ===== CORE =====
    Exercise(
      id: 'plank',
      nameEn: 'Plank',
      nameDe: 'Unterarmstütz',
      primaryMuscle: 'abs',
      secondaryMuscles: ['obliques', 'lower_back', 'shoulders'],
      equipment: ['bodyweight'],
      category: ExerciseCategory.core,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 4,
    ),
    Exercise(
      id: 'crunches',
      nameEn: 'Crunches',
      nameDe: 'Crunches',
      primaryMuscle: 'abs',
      secondaryMuscles: ['obliques'],
      equipment: ['bodyweight'],
      category: ExerciseCategory.core,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 5,
    ),
    Exercise(
      id: 'russian_twist',
      nameEn: 'Russian Twist',
      nameDe: 'Russische Drehung',
      primaryMuscle: 'obliques',
      secondaryMuscles: ['abs'],
      equipment: ['bodyweight', 'dumbbell', 'kettlebell'],
      category: ExerciseCategory.core,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 6,
    ),
    Exercise(
      id: 'leg_raises',
      nameEn: 'Leg Raises',
      nameDe: 'Beinheben',
      primaryMuscle: 'abs',
      secondaryMuscles: ['obliques'],
      equipment: ['bodyweight', 'pull_up_bar'],
      category: ExerciseCategory.core,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 6,
    ),
    Exercise(
      id: 'mountain_climbers',
      nameEn: 'Mountain Climbers',
      nameDe: 'Bergsteiger',
      primaryMuscle: 'abs',
      secondaryMuscles: ['shoulders', 'quads'],
      equipment: ['bodyweight'],
      category: ExerciseCategory.core,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 10,
    ),
    
    // ===== CARDIO =====
    Exercise(
      id: 'burpees',
      nameEn: 'Burpees',
      nameDe: 'Burpees',
      primaryMuscle: 'abs',
      secondaryMuscles: ['chest', 'quads', 'shoulders'],
      equipment: ['bodyweight'],
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.intermediate,
      caloriesPerMinute: 12,
    ),
    Exercise(
      id: 'jumping_jacks',
      nameEn: 'Jumping Jacks',
      nameDe: 'Hampelmänner',
      primaryMuscle: 'quads',
      secondaryMuscles: ['calves', 'shoulders'],
      equipment: ['bodyweight'],
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.beginner,
      caloriesPerMinute: 8,
    ),
  ];
  
  // ============================================================================
  // API METHODEN
  // ============================================================================
  
  /// Alle Übungen laden (mit Cache)
  static Future<List<Exercise>> getAllExercises() async {
    // Prüfe Cache
    final cached = await _loadFromCache();
    if (cached != null) return cached;
    
    // Nutze eingebaute Übungen als Fallback
    return _builtInExercises;
  }
  
  /// Übungen suchen
  static Future<List<Exercise>> searchExercises(String query) async {
    final exercises = await getAllExercises();
    final searchTermEn = translateToEnglish(query).toLowerCase();
    final searchTermDe = query.toLowerCase();
    
    return exercises.where((e) {
      return e.nameDe.toLowerCase().contains(searchTermDe) ||
             e.nameEn.toLowerCase().contains(searchTermEn) ||
             e.primaryMuscle.toLowerCase().contains(searchTermEn) ||
             e.secondaryMuscles.any((m) => m.toLowerCase().contains(searchTermEn));
    }).toList();
  }
  
  /// Übungen nach Muskelgruppe filtern
  static Future<List<Exercise>> getExercisesByMuscle(String muscleId) async {
    final exercises = await getAllExercises();
    return exercises.where((e) =>
      e.primaryMuscle == muscleId || e.secondaryMuscles.contains(muscleId)
    ).toList();
  }
  
  /// Übungen nach Equipment filtern
  static Future<List<Exercise>> getExercisesByEquipment(String equipmentId) async {
    final exercises = await getAllExercises();
    return exercises.where((e) => e.equipment.contains(equipmentId)).toList();
  }
  
  /// Übungen nach Kategorie filtern
  static Future<List<Exercise>> getExercisesByCategory(ExerciseCategory category) async {
    final exercises = await getAllExercises();
    return exercises.where((e) => e.category == category).toList();
  }
  
  /// Multi-Filter Suche
  static Future<List<Exercise>> filterExercises({
    String? query,
    String? muscleId,
    String? equipmentId,
    ExerciseCategory? category,
    ExerciseDifficulty? difficulty,
  }) async {
    var exercises = await getAllExercises();
    
    if (query != null && query.isNotEmpty) {
      final searchTermEn = translateToEnglish(query).toLowerCase();
      final searchTermDe = query.toLowerCase();
      exercises = exercises.where((e) =>
        e.nameDe.toLowerCase().contains(searchTermDe) ||
        e.nameEn.toLowerCase().contains(searchTermEn)
      ).toList();
    }
    
    if (muscleId != null) {
      exercises = exercises.where((e) =>
        e.primaryMuscle == muscleId || e.secondaryMuscles.contains(muscleId)
      ).toList();
    }
    
    if (equipmentId != null) {
      exercises = exercises.where((e) => e.equipment.contains(equipmentId)).toList();
    }
    
    if (category != null) {
      exercises = exercises.where((e) => e.category == category).toList();
    }
    
    if (difficulty != null) {
      exercises = exercises.where((e) => e.difficulty == difficulty).toList();
    }
    
    return exercises;
  }
  
  /// Übung nach ID
  static Exercise? getExerciseById(String id) {
    try {
      return _builtInExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
  
  // ============================================================================
  // CACHE METHODS
  // ============================================================================
  
  static Future<List<Exercise>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      
      if (timestamp == null) return null;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDurationDays * 24 * 60 * 60 * 1000) {
        return null; // Cache abgelaufen
      }
      
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return null;
      
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
  
  static Future<void> _saveToCache(List<Exercise> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(exercises.map((e) => e.toJson()).toList()));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}

// ============================================================================
// MODELS
// ============================================================================

/// Muskelgruppen-Kategorie
enum MuscleCategory {
  push('Push', '💪'),
  pull('Pull', '🔙'),
  legs('Beine', '🦵'),
  core('Core', '🎯');
  
  final String label;
  final String emoji;
  const MuscleCategory(this.label, this.emoji);
}

/// Muskelgruppe
class MuscleGroup {
  final String id;
  final String nameEn;
  final String nameDe;
  final MuscleCategory category;
  
  const MuscleGroup({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.category,
  });
}

/// Equipment
class Equipment {
  final String id;
  final String nameEn;
  final String nameDe;
  final String icon;
  
  const Equipment({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.icon,
  });
}

/// Übungs-Kategorie
enum ExerciseCategory {
  push('Push', '💪'),
  pull('Pull', '🔙'),
  legs('Beine', '🦵'),
  core('Core', '🎯'),
  cardio('Cardio', '❤️');
  
  final String label;
  final String emoji;
  const ExerciseCategory(this.label, this.emoji);
}

/// Schwierigkeitsgrad
enum ExerciseDifficulty {
  beginner('Anfänger', 1),
  intermediate('Fortgeschritten', 2),
  advanced('Profi', 3);
  
  final String label;
  final int value;
  const ExerciseDifficulty(this.label, this.value);
}

/// Übung
class Exercise {
  final String id;
  final String nameEn;
  final String nameDe;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final ExerciseCategory category;
  final ExerciseDifficulty difficulty;
  final int caloriesPerMinute;
  final String? imageUrl;
  final String? instructions;
  
  const Exercise({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.equipment,
    required this.category,
    required this.difficulty,
    required this.caloriesPerMinute,
    this.imageUrl,
    this.instructions,
  });
  
  /// Primäre Muskelgruppe als Objekt
  MuscleGroup? get primaryMuscleGroup => ExerciseDbService.getMuscleGroupById(primaryMuscle);
  
  /// Sekundäre Muskelgruppen als Objekte
  List<MuscleGroup> get secondaryMuscleGroups {
    return secondaryMuscles
        .map((id) => ExerciseDbService.getMuscleGroupById(id))
        .whereType<MuscleGroup>()
        .toList();
  }
  
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameDe: json['name_de'] as String,
      primaryMuscle: json['primary_muscle'] as String,
      secondaryMuscles: (json['secondary_muscles'] as List).cast<String>(),
      equipment: (json['equipment'] as List).cast<String>(),
      category: ExerciseCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ExerciseCategory.push,
      ),
      difficulty: ExerciseDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => ExerciseDifficulty.intermediate,
      ),
      caloriesPerMinute: json['calories_per_minute'] as int? ?? 5,
      imageUrl: json['image_url'] as String?,
      instructions: json['instructions'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name_en': nameEn,
    'name_de': nameDe,
    'primary_muscle': primaryMuscle,
    'secondary_muscles': secondaryMuscles,
    'equipment': equipment,
    'category': category.name,
    'difficulty': difficulty.name,
    'calories_per_minute': caloriesPerMinute,
    'image_url': imageUrl,
    'instructions': instructions,
  };
}
