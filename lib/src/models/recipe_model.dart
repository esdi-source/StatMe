import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Rezept-Status
enum RecipeStatus {
  wishlist('Merkliste', '📋'),
  cooked('Gekocht', '✅');

  final String label;
  final String emoji;
  const RecipeStatus(this.label, this.emoji);
}

/// Rezept-Kategorie
enum RecipeCategory {
  breakfast('Frühstück', '🍳'),
  lunch('Mittagessen', '🥗'),
  dinner('Abendessen', '🍽️'),
  snack('Snack', '🍿'),
  dessert('Dessert', '🍰'),
  drink('Getränk', '🥤'),
  baking('Backen', '🍞'),
  salad('Salat', '🥗'),
  soup('Suppe', '🍲'),
  other('Sonstiges', '🍴');

  final String label;
  final String emoji;
  const RecipeCategory(this.label, this.emoji);
}

/// Tags für Rezepte
enum RecipeTag {
  vegan('Vegan', '🌱'),
  vegetarian('Vegetarisch', '🥬'),
  glutenFree('Glutenfrei', '🌾'),
  lactoseFree('Laktosefrei', '🥛'),
  quick('Schnell', '⚡'),
  easy('Einfach', '👍'),
  healthy('Gesund', '💚'),
  comfort('Comfort Food', '🛋️'),
  spicy('Scharf', '🌶️'),
  lowCarb('Low Carb', '🥩'),
  highProtein('High Protein', '💪'),
  mealPrep('Meal Prep', '📦'),
  budget('Günstig', '💰');

  final String label;
  final String emoji;
  const RecipeTag(this.label, this.emoji);
}

// ============================================================================
// INGREDIENT
// ============================================================================

class RecipeIngredient extends Equatable {
  final String name;
  final double? amount;
  final String? unit;
  final String? note;

  const RecipeIngredient({
    required this.name,
    this.amount,
    this.unit,
    this.note,
  });

  RecipeIngredient scaled(double factor) {
    return RecipeIngredient(
      name: name,
      amount: amount != null ? amount! * factor : null,
      unit: unit,
      note: note,
    );
  }

  String get displayText {
    final buffer = StringBuffer();
    if (amount != null) {
      buffer.write(amount! % 1 == 0 ? amount!.toInt() : amount!.toStringAsFixed(1));
      if (unit != null) buffer.write(' $unit');
      buffer.write(' ');
    }
    buffer.write(name);
    if (note != null) buffer.write(' ($note)');
    return buffer.toString();
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        'note': note,
      };

  @override
  List<Object?> get props => [name, amount, unit, note];
}

// ============================================================================
// RECIPE RATING (Bewertung nach dem Kochen)
// ============================================================================

class RecipeRating extends Equatable {
  final int overall; // 1-10
  final int? mood; // Stimmung nach dem Essen 1-10
  final String? notes;
  final DateTime ratedAt;

  const RecipeRating({
    required this.overall,
    this.mood,
    this.notes,
    required this.ratedAt,
  });

  factory RecipeRating.fromJson(Map<String, dynamic> json) {
    return RecipeRating(
      overall: json['overall'] as int,
      mood: json['mood'] as int?,
      notes: json['notes'] as String?,
      ratedAt: DateTime.parse(json['ratedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'mood': mood,
        'notes': notes,
        'ratedAt': ratedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [overall, mood, notes, ratedAt];
}

// ============================================================================
// COOK LOG (Wann wurde gekocht)
// ============================================================================

class CookLog extends Equatable {
  final String id;
  final DateTime cookedAt;
  final int servingsCooked;
  final RecipeRating? rating;

  const CookLog({
    required this.id,
    required this.cookedAt,
    required this.servingsCooked,
    this.rating,
  });

  factory CookLog.fromJson(Map<String, dynamic> json) {
    return CookLog(
      id: json['id'] as String,
      cookedAt: DateTime.parse(json['cookedAt'] as String),
      servingsCooked: json['servingsCooked'] as int? ?? 1,
      rating: json['rating'] != null
          ? RecipeRating.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cookedAt': cookedAt.toIso8601String(),
        'servingsCooked': servingsCooked,
        'rating': rating?.toJson(),
      };

  @override
  List<Object?> get props => [id, cookedAt, servingsCooked, rating];
}

// ============================================================================
// RECIPE
// ============================================================================

class Recipe extends Equatable {
  final String id;
  final String oderId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? sourceUrl;
  
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  
  final int servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final RecipeCategory category;
  final Set<RecipeTag> tags;
  
  final int? caloriesPerServing;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;
  
  final RecipeStatus status;
  final bool isFavorite;
  final String? notes;
  final List<CookLog> cookLogs;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.oderId,
    required this.title,
    this.description,
    this.imageUrl,
    this.sourceUrl,
    required this.ingredients,
    required this.steps,
    required this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    required this.category,
    this.tags = const {},
    this.caloriesPerServing,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    required this.status,
    this.isFavorite = false,
    this.notes,
    this.cookLogs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalTimeMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  String get formattedTime {
    final total = totalTimeMinutes;
    if (total == 0) return '-';
    if (total < 60) return '$total Min';
    final h = total ~/ 60;
    final m = total % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  int get cookCount => cookLogs.length;

  double? get avgRating {
    final rated = cookLogs.where((c) => c.rating != null).toList();
    if (rated.isEmpty) return null;
    return rated.map((c) => c.rating!.overall).reduce((a, b) => a + b) / rated.length;
  }

  DateTime? get lastCookedAt {
    if (cookLogs.isEmpty) return null;
    return cookLogs.map((c) => c.cookedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  int? get daysSinceLastCooked {
    final last = lastCookedAt;
    if (last == null) return null;
    return DateTime.now().difference(last).inDays;
  }

  List<RecipeIngredient> ingredientsForServings(int target) {
    if (target == servings) return ingredients;
    final factor = target / servings;
    return ingredients.map((i) => i.scaled(factor)).toList();
  }

  Recipe copyWith({
    String? id,
    String? oderId,
    String? title,
    String? description,
    String? imageUrl,
    String? sourceUrl,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    RecipeCategory? category,
    Set<RecipeTag>? tags,
    int? caloriesPerServing,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    RecipeStatus? status,
    bool? isFavorite,
    String? notes,
    List<CookLog>? cookLogs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      cookLogs: cookLogs ?? this.cookLogs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      oderId: json['oderId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      servings: json['servings'] as int? ?? 4,
      prepTimeMinutes: json['prepTimeMinutes'] as int?,
      cookTimeMinutes: json['cookTimeMinutes'] as int?,
      category: RecipeCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => RecipeCategory.other,
      ),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => RecipeTag.values.firstWhere((t) => t.name == e, orElse: () => RecipeTag.easy))
              .toSet() ??
          {},
      caloriesPerServing: json['caloriesPerServing'] as int?,
      proteinGrams: json['proteinGrams'] as int?,
      carbsGrams: json['carbsGrams'] as int?,
      fatGrams: json['fatGrams'] as int?,
      status: RecipeStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RecipeStatus.wishlist,
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
      notes: json['notes'] as String?,
      cookLogs: (json['cookLogs'] as List<dynamic>?)
              ?.map((e) => CookLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'oderId': oderId,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'sourceUrl': sourceUrl,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps,
        'servings': servings,
        'prepTimeMinutes': prepTimeMinutes,
        'cookTimeMinutes': cookTimeMinutes,
        'category': category.name,
        'tags': tags.map((t) => t.name).toList(),
        'caloriesPerServing': caloriesPerServing,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'status': status.name,
        'isFavorite': isFavorite,
        'notes': notes,
        'cookLogs': cookLogs.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, title, status, cookLogs, isFavorite, updatedAt];
}

// ============================================================================
// RECIPE STATISTICS
// ============================================================================

class RecipeStatistics extends Equatable {
  final int totalRecipes;
  final int wishlistCount;
  final int cookedCount;
  final int favoritesCount;
  final int totalCookCount;
  final double avgRating;
  final Map<RecipeCategory, int> byCategory;
  final List<Recipe> topCooked; // Meistgekocht
  final List<Recipe> longNotCooked; // Lange nicht gekocht

  const RecipeStatistics({
    required this.totalRecipes,
    required this.wishlistCount,
    required this.cookedCount,
    required this.favoritesCount,
    required this.totalCookCount,
    required this.avgRating,
    required this.byCategory,
    required this.topCooked,
    required this.longNotCooked,
  });

  factory RecipeStatistics.empty() {
    return const RecipeStatistics(
      totalRecipes: 0,
      wishlistCount: 0,
      cookedCount: 0,
      favoritesCount: 0,
      totalCookCount: 0,
      avgRating: 0,
      byCategory: {},
      topCooked: [],
      longNotCooked: [],
    );
  }

  factory RecipeStatistics.calculate(List<Recipe> recipes) {
    if (recipes.isEmpty) return RecipeStatistics.empty();

    final wishlist = recipes.where((r) => r.status == RecipeStatus.wishlist).length;
    final cooked = recipes.where((r) => r.status == RecipeStatus.cooked).length;
    final favorites = recipes.where((r) => r.isFavorite).length;

    // Total cook count
    final totalCooks = recipes.fold(0, (sum, r) => sum + r.cookCount);

    // Average rating
    final allRatings = <int>[];
    for (final r in recipes) {
      for (final log in r.cookLogs) {
        if (log.rating != null) {
          allRatings.add(log.rating!.overall);
        }
      }
    }
    final avgRating = allRatings.isNotEmpty
        ? allRatings.reduce((a, b) => a + b) / allRatings.length
        : 0.0;

    // By category
    final byCategory = <RecipeCategory, int>{};
    for (final r in recipes) {
      byCategory[r.category] = (byCategory[r.category] ?? 0) + 1;
    }

    // Top cooked
    final sortedByCookCount = recipes.where((r) => r.cookCount > 0).toList()
      ..sort((a, b) => b.cookCount.compareTo(a.cookCount));
    final topCooked = sortedByCookCount.take(5).toList();

    // Long not cooked (gekocht, aber >30 Tage her)
    final now = DateTime.now();
    final longNotCooked = recipes
        .where((r) => r.status == RecipeStatus.cooked && r.lastCookedAt != null)
        .where((r) => now.difference(r.lastCookedAt!).inDays > 30)
        .toList()
      ..sort((a, b) => a.lastCookedAt!.compareTo(b.lastCookedAt!));

    return RecipeStatistics(
      totalRecipes: recipes.length,
      wishlistCount: wishlist,
      cookedCount: cooked,
      favoritesCount: favorites,
      totalCookCount: totalCooks,
      avgRating: avgRating,
      byCategory: byCategory,
      topCooked: topCooked,
      longNotCooked: longNotCooked.take(5).toList(),
    );
  }

  @override
  List<Object?> get props => [totalRecipes, wishlistCount, cookedCount, favoritesCount, totalCookCount, avgRating];
}
