import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Supplement-Kategorie
enum SupplementCategory {
  vitamin('Vitamine', '💊', 0xFFFF9800),
  mineral('Mineralien', '⚪', 0xFF9E9E9E),
  aminoAcid('Aminosäuren', '🔵', 0xFF2196F3),
  omega('Omega-Fettsäuren', '🐟', 0xFF00BCD4),
  probiotic('Probiotika', '🦠', 0xFF4CAF50),
  herb('Kräuter & Pflanzen', '🌿', 0xFF8BC34A),
  protein('Protein', '💪', 0xFFE91E63),
  preWorkout('Pre-Workout', '⚡', 0xFFFF5722),
  sleep('Schlaf & Entspannung', '😴', 0xFF673AB7),
  immunity('Immunsystem', '🛡️', 0xFFFFC107),
  beauty('Haut, Haare, Nägel', '✨', 0xFFE040FB),
  other('Sonstige', '📦', 0xFF607D8B);

  final String label;
  final String emoji;
  final int colorValue;
  const SupplementCategory(this.label, this.emoji, this.colorValue);
}

/// Einnahmeform
enum SupplementForm {
  capsule('Kapsel', '💊'),
  tablet('Tablette', '⚪'),
  powder('Pulver', '🥄'),
  liquid('Flüssig', '💧'),
  gummy('Gummy', '🍬'),
  spray('Spray', '💨'),
  drops('Tropfen', '💦'),
  injection('Injektion', '💉'),
  patch('Pflaster', '🩹'),
  other('Andere', '📦');

  final String label;
  final String emoji;
  const SupplementForm(this.label, this.emoji);
}

/// Einnahme-Zeitpunkt
enum IntakeTime {
  morning('Morgens', '🌅'),
  noon('Mittags', '☀️'),
  evening('Abends', '🌆'),
  night('Nachts', '🌙'),
  beforeMeal('Vor dem Essen', '🍽️'),
  afterMeal('Nach dem Essen', '🍴'),
  withMeal('Zum Essen', '🥗'),
  asNeeded('Bei Bedarf', '❓');

  final String label;
  final String emoji;
  const IntakeTime(this.label, this.emoji);
}

// ============================================================================
// WIRKSTOFF MODEL
// ============================================================================

/// Ein Wirkstoff mit Menge pro Einheit
class Ingredient extends Equatable {
  final String id;
  final String name;
  final double amountPerUnit; // Menge pro Einheit
  final String unit; // mg, g, mcg, IU, etc.
  final double? dailyValue; // Tageswert in % (optional)

  const Ingredient({
    required this.id,
    required this.name,
    required this.amountPerUnit,
    required this.unit,
    this.dailyValue,
  });

  Ingredient copyWith({
    String? id,
    String? name,
    double? amountPerUnit,
    String? unit,
    double? dailyValue,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      amountPerUnit: amountPerUnit ?? this.amountPerUnit,
      unit: unit ?? this.unit,
      dailyValue: dailyValue ?? this.dailyValue,
    );
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      amountPerUnit: (json['amountPerUnit'] as num).toDouble(),
      unit: json['unit'] as String,
      dailyValue: json['dailyValue'] != null 
          ? (json['dailyValue'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amountPerUnit': amountPerUnit,
      'unit': unit,
      'dailyValue': dailyValue,
    };
  }

  /// Formatierte Anzeige
  String get formattedAmount {
    if (amountPerUnit >= 1000 && unit == 'mg') {
      return '${(amountPerUnit / 1000).toStringAsFixed(1)} g';
    }
    if (amountPerUnit >= 1000 && unit == 'mcg') {
      return '${(amountPerUnit / 1000).toStringAsFixed(1)} mg';
    }
    return '${amountPerUnit.toStringAsFixed(amountPerUnit.truncateToDouble() == amountPerUnit ? 0 : 1)} $unit';
  }

  @override
  List<Object?> get props => [id, name, amountPerUnit, unit, dailyValue];
}

// ============================================================================
// SUPPLEMENT MODEL
// ============================================================================

/// Ein Supplement (Nahrungsergänzungsmittel)
class Supplement extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? brand; // Markenname
  final SupplementCategory category;
  final SupplementForm form;
  final List<Ingredient> ingredients;
  final double defaultDosage; // Standard-Dosierung (Anzahl Einheiten)
  final String dosageUnit; // z.B. "Kapseln", "ml", "Löffel"
  final List<IntakeTime> recommendedTimes; // Empfohlene Einnahmezeiten
  final String? notes;
  final String? imageUrl; // Foto der Verpackung
  final bool isPaused; // Pausiert (ohne Datenverlust)
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplement({
    required this.id,
    required this.userId,
    required this.name,
    this.brand,
    required this.category,
    required this.form,
    this.ingredients = const [],
    this.defaultDosage = 1.0,
    this.dosageUnit = 'Einheit(en)',
    this.recommendedTimes = const [],
    this.notes,
    this.imageUrl,
    this.isPaused = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Supplement copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    SupplementCategory? category,
    SupplementForm? form,
    List<Ingredient>? ingredients,
    double? defaultDosage,
    String? dosageUnit,
    List<IntakeTime>? recommendedTimes,
    String? notes,
    String? imageUrl,
    bool? isPaused,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      form: form ?? this.form,
      ingredients: ingredients ?? this.ingredients,
      defaultDosage: defaultDosage ?? this.defaultDosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      recommendedTimes: recommendedTimes ?? this.recommendedTimes,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: SupplementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SupplementCategory.other,
      ),
      form: SupplementForm.values.firstWhere(
        (e) => e.name == json['form'],
        orElse: () => SupplementForm.other,
      ),
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      defaultDosage: (json['defaultDosage'] as num?)?.toDouble() ?? 1.0,
      dosageUnit: json['dosageUnit'] as String? ?? 'Einheit(en)',
      recommendedTimes: (json['recommendedTimes'] as List<dynamic>?)
          ?.map((e) => IntakeTime.values.firstWhere(
                (t) => t.name == e,
                orElse: () => IntakeTime.asNeeded,
              ))
          .toList() ?? [],
      notes: json['notes'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isPaused: json['isPaused'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'brand': brand,
      'category': category.name,
      'form': form.name,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'defaultDosage': defaultDosage,
      'dosageUnit': dosageUnit,
      'recommendedTimes': recommendedTimes.map((e) => e.name).toList(),
      'notes': notes,
      'imageUrl': imageUrl,
      'isPaused': isPaused,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Gesamtmenge eines Wirkstoffs pro Einnahme
  double getIngredientAmount(String ingredientName, double dosage) {
    final ingredient = ingredients.firstWhere(
      (i) => i.name.toLowerCase() == ingredientName.toLowerCase(),
      orElse: () => Ingredient(id: '', name: '', amountPerUnit: 0, unit: ''),
    );
    return ingredient.amountPerUnit * dosage;
  }

  @override
  List<Object?> get props => [
    id, userId, name, brand, category, form, ingredients,
    defaultDosage, dosageUnit, recommendedTimes, notes, imageUrl,
    isPaused, createdAt, updatedAt,
  ];
}

// ============================================================================
// SUPPLEMENT INTAKE MODEL (Einnahme)
// ============================================================================

/// Eine einzelne Supplement-Einnahme
class SupplementIntake extends Equatable {
  final String id;
  final String oderId;
  final String supplementId;
  final DateTime timestamp;
  final double dosage; // Anzahl Einheiten
  final IntakeTime? intakeTime; // Wann eingenommen
  final String? feeling; // Wie fühlst du dich? (optional)
  final String? notes;
  final DateTime createdAt;

  const SupplementIntake({
    required this.id,
    required this.oderId,
    required this.supplementId,
    required this.timestamp,
    required this.dosage,
    this.intakeTime,
    this.feeling,
    this.notes,
    required this.createdAt,
  });

  SupplementIntake copyWith({
    String? id,
    String? oderId,
    String? supplementId,
    DateTime? timestamp,
    double? dosage,
    IntakeTime? intakeTime,
    String? feeling,
    String? notes,
    DateTime? createdAt,
  }) {
    return SupplementIntake(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      supplementId: supplementId ?? this.supplementId,
      timestamp: timestamp ?? this.timestamp,
      dosage: dosage ?? this.dosage,
      intakeTime: intakeTime ?? this.intakeTime,
      feeling: feeling ?? this.feeling,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SupplementIntake.fromJson(Map<String, dynamic> json) {
    return SupplementIntake(
      id: json['id'] as String,
      oderId: json['oderId'] as String,
      supplementId: json['supplementId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      dosage: (json['dosage'] as num).toDouble(),
      intakeTime: json['intakeTime'] != null
          ? IntakeTime.values.firstWhere(
              (e) => e.name == json['intakeTime'],
              orElse: () => IntakeTime.asNeeded,
            )
          : null,
      feeling: json['feeling'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oderId': oderId,
      'supplementId': supplementId,
      'timestamp': timestamp.toIso8601String(),
      'dosage': dosage,
      'intakeTime': intakeTime?.name,
      'feeling': feeling,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, oderId, supplementId, timestamp, dosage, intakeTime, feeling, notes, createdAt,
  ];
}

// ============================================================================
// SUPPLEMENT STATISTIK
// ============================================================================

/// Wirkstoff-Statistik für einen Zeitraum
class IngredientStats {
  final String name;
  final String unit;
  final double totalAmount;
  final int intakeCount;
  final double avgPerDay;
  final double? dailyValuePercent;

  const IngredientStats({
    required this.name,
    required this.unit,
    required this.totalAmount,
    required this.intakeCount,
    required this.avgPerDay,
    this.dailyValuePercent,
  });

  String get formattedTotal {
    if (totalAmount >= 1000 && unit == 'mg') {
      return '${(totalAmount / 1000).toStringAsFixed(1)} g';
    }
    if (totalAmount >= 1000 && unit == 'mcg') {
      return '${(totalAmount / 1000).toStringAsFixed(1)} mg';
    }
    return '${totalAmount.toStringAsFixed(1)} $unit';
  }
}

/// Supplement-Statistik
class SupplementStatistics {
  final int totalSupplements;
  final int activeSupplements;
  final int pausedSupplements;
  final int todayIntakes;
  final int weekIntakes;
  final Map<String, IngredientStats> ingredientStats;
  final Map<SupplementCategory, int> byCategory;
  final double avgIntakesPerDay;

  const SupplementStatistics({
    required this.totalSupplements,
    required this.activeSupplements,
    required this.pausedSupplements,
    required this.todayIntakes,
    required this.weekIntakes,
    required this.ingredientStats,
    required this.byCategory,
    required this.avgIntakesPerDay,
  });

  factory SupplementStatistics.empty() {
    return const SupplementStatistics(
      totalSupplements: 0,
      activeSupplements: 0,
      pausedSupplements: 0,
      todayIntakes: 0,
      weekIntakes: 0,
      ingredientStats: {},
      byCategory: {},
      avgIntakesPerDay: 0,
    );
  }

  /// Berechnet Statistiken aus Supplements und Einnahmen
  factory SupplementStatistics.calculate({
    required List<Supplement> supplements,
    required List<SupplementIntake> intakes,
    required int days,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final periodStart = today.subtract(Duration(days: days));

    // Basis-Statistik
    final active = supplements.where((s) => !s.isPaused).length;
    final paused = supplements.where((s) => s.isPaused).length;

    // Einnahmen heute
    final todayIntakes = intakes.where((i) {
      final d = i.timestamp;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;

    // Einnahmen diese Woche
    final weekIntakes = intakes.where((i) => i.timestamp.isAfter(weekAgo)).length;

    // Einnahmen im Zeitraum
    final periodIntakes = intakes.where((i) => i.timestamp.isAfter(periodStart)).toList();

    // Wirkstoffe aggregieren
    final ingredientMap = <String, IngredientStats>{};
    for (final intake in periodIntakes) {
      final supplement = supplements.cast<Supplement?>().firstWhere(
        (s) => s?.id == intake.supplementId,
        orElse: () => null,
      );
      if (supplement == null) continue;

      for (final ingredient in supplement.ingredients) {
        final amount = ingredient.amountPerUnit * intake.dosage;
        final existing = ingredientMap[ingredient.name];
        if (existing != null) {
          ingredientMap[ingredient.name] = IngredientStats(
            name: ingredient.name,
            unit: ingredient.unit,
            totalAmount: existing.totalAmount + amount,
            intakeCount: existing.intakeCount + 1,
            avgPerDay: (existing.totalAmount + amount) / days,
            dailyValuePercent: ingredient.dailyValue,
          );
        } else {
          ingredientMap[ingredient.name] = IngredientStats(
            name: ingredient.name,
            unit: ingredient.unit,
            totalAmount: amount,
            intakeCount: 1,
            avgPerDay: amount / days,
            dailyValuePercent: ingredient.dailyValue,
          );
        }
      }
    }

    // Nach Kategorie gruppieren
    final byCategory = <SupplementCategory, int>{};
    for (final supplement in supplements) {
      byCategory[supplement.category] = (byCategory[supplement.category] ?? 0) + 1;
    }

    return SupplementStatistics(
      totalSupplements: supplements.length,
      activeSupplements: active,
      pausedSupplements: paused,
      todayIntakes: todayIntakes,
      weekIntakes: weekIntakes,
      ingredientStats: ingredientMap,
      byCategory: byCategory,
      avgIntakesPerDay: days > 0 ? periodIntakes.length / days : 0,
    );
  }
}

// ============================================================================
// OCR SCAN RESULT
// ============================================================================

/// Ergebnis eines OCR-Scans einer Supplement-Verpackung
class SupplementScanResult {
  final String? name;
  final String? brand;
  final List<Ingredient> detectedIngredients;
  final String? dosageInfo;
  final String rawText;
  final double confidence;

  const SupplementScanResult({
    this.name,
    this.brand,
    this.detectedIngredients = const [],
    this.dosageInfo,
    required this.rawText,
    this.confidence = 0.0,
  });

  bool get hasData => name != null || detectedIngredients.isNotEmpty;
}
