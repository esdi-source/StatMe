import 'package:equatable/equatable.dart';

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
