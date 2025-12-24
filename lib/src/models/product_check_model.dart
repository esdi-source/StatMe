import 'package:equatable/equatable.dart';

enum ProductSource {
  openFoodFacts,
  openBeautyFacts,
  unknown,
}

enum IngredientSafety {
  safe,
  caution,
  unsafe,
  unknown,
}

class ProductCheckResult extends Equatable {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final ProductSource source;
  final List<String> ingredients;
  final List<String> labels; // e.g., Vegan, Bio
  final String? nutriscore; // A, B, C, D, E
  final String? ecoscore; // A, B, C, D, E
  final List<String> additives;
  final List<String> allergens;
  final DateTime scannedAt;

  const ProductCheckResult({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.source,
    this.ingredients = const [],
    this.labels = const [],
    this.nutriscore,
    this.ecoscore,
    this.additives = const [],
    this.allergens = const [],
    required this.scannedAt,
  });

  factory ProductCheckResult.fromJson(Map<String, dynamic> json, ProductSource source) {
    final product = json['product'] ?? {};
    
    // Helper to safely get list
    List<String> getList(String key) {
      if (product[key] == null) return [];
      if (product[key] is String) {
        return (product[key] as String).split(',').map((e) => e.trim()).toList();
      }
      if (product[key] is List) {
        return (product[key] as List).map((e) => e.toString()).toList();
      }
      return [];
    }

    // Helper for additives (often tags)
    List<String> getTags(String key) {
      if (product[key] == null) return [];
      return (product[key] as List)
          .map((e) => e.toString().replaceAll('en:', '').replaceAll('-', ' '))
          .toList();
    }

    return ProductCheckResult(
      barcode: json['code'] ?? '',
      name: product['product_name'] ?? product['product_name_de'] ?? product['product_name_en'] ?? 'Unbekanntes Produkt',
      brand: product['brands'],
      imageUrl: product['image_url'] ?? product['image_front_url'],
      source: source,
      ingredients: product['ingredients_text'] != null 
          ? (product['ingredients_text'] as String).split(',').map((e) => e.trim()).toList()
          : [],
      labels: getTags('labels_tags'),
      nutriscore: product['nutriscore_grade']?.toString().toUpperCase(),
      ecoscore: product['ecoscore_grade']?.toString().toUpperCase(),
      additives: getTags('additives_tags'),
      allergens: getTags('allergens_tags'),
      scannedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'source': source.name,
      'ingredients': ingredients,
      'labels': labels,
      'nutriscore': nutriscore,
      'ecoscore': ecoscore,
      'additives': additives,
      'allergens': allergens,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory ProductCheckResult.fromLocalJson(Map<String, dynamic> json) {
    return ProductCheckResult(
      barcode: json['barcode'],
      name: json['name'],
      brand: json['brand'],
      imageUrl: json['imageUrl'],
      source: ProductSource.values.firstWhere((e) => e.name == json['source'], orElse: () => ProductSource.unknown),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      labels: List<String>.from(json['labels'] ?? []),
      nutriscore: json['nutriscore'],
      ecoscore: json['ecoscore'],
      additives: List<String>.from(json['additives'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
      scannedAt: DateTime.parse(json['scannedAt']),
    );
  }

  @override
  List<Object?> get props => [barcode, name, brand, source, scannedAt];
}
