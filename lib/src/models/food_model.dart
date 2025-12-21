import 'package:equatable/equatable.dart';

/// Favorisiertes Produkt (aus OpenFoodFacts oder eigene Produkte)
class FavoriteProduct extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final String? barcode;
  final String? imageUrl;
  final double? defaultGrams; // Standard-Portion
  final int useCount; // Wie oft verwendet
  final DateTime createdAt;
  final DateTime updatedAt;

  const FavoriteProduct({
    required this.id,
    required this.userId,
    required this.name,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.barcode,
    this.imageUrl,
    this.defaultGrams,
    this.useCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    return FavoriteProduct(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      kcalPer100g: (json['kcal_per_100g'] as num).toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble(),
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble(),
      barcode: json['barcode'] as String?,
      imageUrl: json['image_url'] as String?,
      defaultGrams: (json['default_grams'] as num?)?.toDouble(),
      useCount: (json['use_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'barcode': barcode,
      'image_url': imageUrl,
      'default_grams': defaultGrams,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double calculateCalories(double grams) => (kcalPer100g / 100) * grams;
  double calculateProtein(double grams) => (proteinPer100g ?? 0) / 100 * grams;
  double calculateCarbs(double grams) => (carbsPer100g ?? 0) / 100 * grams;
  double calculateFat(double grams) => (fatPer100g ?? 0) / 100 * grams;

  FavoriteProduct copyWith({
    String? id,
    String? userId,
    String? name,
    double? kcalPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    String? barcode,
    String? imageUrl,
    double? defaultGrams,
    int? useCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteProduct(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      defaultGrams: defaultGrams ?? this.defaultGrams,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, kcalPer100g, barcode, useCount];
}

/// Eigenes Produkt/Rezept (z.B. Salatsoße, selbstgemachte Gerichte)
class CustomFoodProduct extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? defaultServingGrams; // Standard-Portionsgröße
  final List<CustomFoodIngredient> ingredients; // Falls aus Zutaten berechnet
  final String? imageUrl;
  final bool isRecipe; // Rezept vs. einfaches Produkt
  final int useCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomFoodProduct({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.defaultServingGrams,
    this.ingredients = const [],
    this.imageUrl,
    this.isRecipe = false,
    this.useCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomFoodProduct.fromJson(Map<String, dynamic> json) {
    return CustomFoodProduct(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      kcalPer100g: (json['kcal_per_100g'] as num).toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble(),
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble(),
      defaultServingGrams: (json['default_serving_grams'] as num?)?.toDouble(),
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((i) => CustomFoodIngredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      imageUrl: json['image_url'] as String?,
      isRecipe: (json['is_recipe'] as bool?) ?? false,
      useCount: (json['use_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'default_serving_grams': defaultServingGrams,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'image_url': imageUrl,
      'is_recipe': isRecipe,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double calculateCalories(double grams) => (kcalPer100g / 100) * grams;
  double calculateProtein(double grams) => (proteinPer100g ?? 0) / 100 * grams;
  double calculateCarbs(double grams) => (carbsPer100g ?? 0) / 100 * grams;
  double calculateFat(double grams) => (fatPer100g ?? 0) / 100 * grams;

  /// Gesamtgewicht aller Zutaten
  double get totalIngredientsWeight =>
      ingredients.fold(0.0, (sum, i) => sum + i.grams);

  /// Gesamtkalorien aller Zutaten
  double get totalIngredientsCalories =>
      ingredients.fold(0.0, (sum, i) => sum + i.calories);

  CustomFoodProduct copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? kcalPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? defaultServingGrams,
    List<CustomFoodIngredient>? ingredients,
    String? imageUrl,
    bool? isRecipe,
    int? useCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomFoodProduct(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      defaultServingGrams: defaultServingGrams ?? this.defaultServingGrams,
      ingredients: ingredients ?? this.ingredients,
      imageUrl: imageUrl ?? this.imageUrl,
      isRecipe: isRecipe ?? this.isRecipe,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, kcalPer100g, isRecipe, useCount];
}

/// Zutat für ein eigenes Rezept
class CustomFoodIngredient extends Equatable {
  final String? productId; // Referenz auf Favorit oder null
  final String? barcode;
  final String name;
  final double grams;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;

  const CustomFoodIngredient({
    this.productId,
    this.barcode,
    required this.name,
    required this.grams,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
  });

  double get calories => (kcalPer100g / 100) * grams;
  double get protein => (proteinPer100g ?? 0) / 100 * grams;
  double get carbs => (carbsPer100g ?? 0) / 100 * grams;
  double get fat => (fatPer100g ?? 0) / 100 * grams;

  factory CustomFoodIngredient.fromJson(Map<String, dynamic> json) {
    return CustomFoodIngredient(
      productId: json['product_id'] as String?,
      barcode: json['barcode'] as String?,
      name: json['name'] as String,
      grams: (json['grams'] as num).toDouble(),
      kcalPer100g: (json['kcal_per_100g'] as num).toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble(),
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'barcode': barcode,
      'name': name,
      'grams': grams,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
    };
  }

  @override
  List<Object?> get props => [productId, barcode, name, grams, kcalPer100g];
}

class ProductModel extends Equatable {
  final String? id;
  final String? barcode;
  final String productName;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;
  final Map<String, dynamic>? rawApi;
  final DateTime lastChecked;

  const ProductModel({
    this.id,
    this.barcode,
    required this.productName,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fiberPer100g,
    this.rawApi,
    required this.lastChecked,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String?,
      barcode: json['barcode'] as String?,
      productName: json['product_name'] as String,
      kcalPer100g: (json['nutri_kcal_per_100g'] as num).toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble(),
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble(),
      fiberPer100g: (json['fiber_per_100g'] as num?)?.toDouble(),
      rawApi: json['raw_api'] as Map<String, dynamic>?,
      lastChecked: DateTime.parse(json['last_checked'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'barcode': barcode,
      'product_name': productName,
      'nutri_kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'fiber_per_100g': fiberPer100g,
      'raw_api': rawApi,
      'last_checked': lastChecked.toIso8601String(),
    };
  }

  double calculateCalories(double grams) {
    return (kcalPer100g / 100) * grams;
  }

  @override
  List<Object?> get props => [
        id,
        barcode,
        productName,
        kcalPer100g,
        proteinPer100g,
        carbsPer100g,
        fatPer100g,
        fiberPer100g,
        lastChecked,
      ];
}

class FoodLogModel extends Equatable {
  final String id;
  final String userId;
  final String? productId;
  final String productName;
  final double grams;
  final double calories;
  final DateTime date;
  final Map<String, dynamic>? rawApi;
  final DateTime createdAt;

  const FoodLogModel({
    required this.id,
    required this.userId,
    this.productId,
    required this.productName,
    required this.grams,
    required this.calories,
    required this.date,
    this.rawApi,
    required this.createdAt,
  });

  factory FoodLogModel.fromJson(Map<String, dynamic> json) {
    return FoodLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String,
      grams: (json['grams'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      rawApi: json['raw_api'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'grams': grams,
      'calories': calories,
      'date': date.toIso8601String().split('T')[0],
      'raw_api': rawApi,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FoodLogModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    double? grams,
    double? calories,
    DateTime? date,
    Map<String, dynamic>? rawApi,
    DateTime? createdAt,
  }) {
    return FoodLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      grams: grams ?? this.grams,
      calories: calories ?? this.calories,
      date: date ?? this.date,
      rawApi: rawApi ?? this.rawApi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        productName,
        grams,
        calories,
        date,
        createdAt,
      ];
}
