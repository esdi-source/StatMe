/// OpenFoodFacts API Service
/// Ermöglicht das Abrufen von Produktdaten über Barcode-Scan
/// API Dokumentation: https://openfoodfacts.github.io/openfoodfacts-server/api/

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Datenmodell für ein Produkt aus OpenFoodFacts
class OpenFoodFactsProduct {
  final String barcode;
  final String? productName;
  final String? brand;
  final String? imageUrl;
  final String? imageFrontUrl;
  final double? calories; // kcal per 100g
  final double? fat;
  final double? saturatedFat;
  final double? carbohydrates;
  final double? sugars;
  final double? fiber;
  final double? proteins;
  final double? salt;
  final String? servingSize;
  final double? servingQuantity;
  final String? nutriscore;
  final String? novaGroup;
  final List<String>? categories;
  final List<String>? ingredients;
  final bool found;
  
  OpenFoodFactsProduct({
    required this.barcode,
    this.productName,
    this.brand,
    this.imageUrl,
    this.imageFrontUrl,
    this.calories,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugars,
    this.fiber,
    this.proteins,
    this.salt,
    this.servingSize,
    this.servingQuantity,
    this.nutriscore,
    this.novaGroup,
    this.categories,
    this.ingredients,
    this.found = true,
  });
  
  /// Produkt nicht gefunden
  factory OpenFoodFactsProduct.notFound(String barcode) {
    return OpenFoodFactsProduct(
      barcode: barcode,
      found: false,
    );
  }
  
  /// Erstellt ein Produkt aus JSON-Daten
  factory OpenFoodFactsProduct.fromJson(String barcode, Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    
    if (product == null) {
      return OpenFoodFactsProduct.notFound(barcode);
    }
    
    // Nährwerte extrahieren
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    
    // Kategorien als Liste
    final categoriesStr = product['categories'] as String? ?? '';
    final categories = categoriesStr.isNotEmpty 
        ? categoriesStr.split(',').map((c) => c.trim()).toList()
        : <String>[];
    
    // Zutaten als Liste
    final ingredientsData = product['ingredients'] as List<dynamic>?;
    final ingredients = ingredientsData?.map((i) {
      if (i is Map<String, dynamic>) {
        return i['text']?.toString() ?? '';
      }
      return i.toString();
    }).where((s) => s.isNotEmpty).toList() ?? <String>[];
    
    return OpenFoodFactsProduct(
      barcode: barcode,
      productName: product['product_name_de'] ?? product['product_name'] ?? product['generic_name'],
      brand: product['brands'],
      imageUrl: product['image_url'],
      imageFrontUrl: product['image_front_url'] ?? product['image_front_small_url'],
      calories: _parseDouble(nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal']),
      fat: _parseDouble(nutriments['fat_100g'] ?? nutriments['fat']),
      saturatedFat: _parseDouble(nutriments['saturated-fat_100g'] ?? nutriments['saturated-fat']),
      carbohydrates: _parseDouble(nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates']),
      sugars: _parseDouble(nutriments['sugars_100g'] ?? nutriments['sugars']),
      fiber: _parseDouble(nutriments['fiber_100g'] ?? nutriments['fiber']),
      proteins: _parseDouble(nutriments['proteins_100g'] ?? nutriments['proteins']),
      salt: _parseDouble(nutriments['salt_100g'] ?? nutriments['salt']),
      servingSize: product['serving_size'],
      servingQuantity: _parseDouble(product['serving_quantity']),
      nutriscore: product['nutriscore_grade'],
      novaGroup: product['nova_group']?.toString(),
      categories: categories,
      ingredients: ingredients,
      found: true,
    );
  }
  
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Formatierte Nährwert-Zusammenfassung
  String get nutritionSummary {
    final parts = <String>[];
    if (calories != null) parts.add('${calories!.toStringAsFixed(0)} kcal');
    if (proteins != null) parts.add('${proteins!.toStringAsFixed(1)}g Protein');
    if (carbohydrates != null) parts.add('${carbohydrates!.toStringAsFixed(1)}g Kohlenhydrate');
    if (fat != null) parts.add('${fat!.toStringAsFixed(1)}g Fett');
    return parts.join(' • ');
  }
  
  /// Vollständiger Produktname mit Marke
  String get fullName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand - $productName';
    }
    return productName ?? 'Unbekanntes Produkt';
  }
}

/// Service für OpenFoodFacts API Anfragen
class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';
  static const String _userAgent = 'StatMe App - Flutter - Version 1.0';
  
  final http.Client _client;
  
  OpenFoodFactsService({http.Client? client}) : _client = client ?? http.Client();
  
  /// Produkt anhand des Barcodes abrufen
  Future<OpenFoodFactsProduct> getProductByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/product/$barcode.json');
      
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode != 200) {
        print('OpenFoodFacts API Fehler: ${response.statusCode}');
        return OpenFoodFactsProduct.notFound(barcode);
      }
      
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Prüfen ob Produkt gefunden wurde
      final status = json['status'] as int?;
      if (status != 1) {
        return OpenFoodFactsProduct.notFound(barcode);
      }
      
      return OpenFoodFactsProduct.fromJson(barcode, json);
    } catch (e) {
      print('Fehler beim Abrufen von OpenFoodFacts: $e');
      return OpenFoodFactsProduct.notFound(barcode);
    }
  }
  
  /// Produkte nach Name suchen
  Future<List<OpenFoodFactsProduct>> searchProducts(String query, {int limit = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'search_terms': query,
        'page_size': limit.toString(),
        'countries_tags_en': 'germany',
        'sort_by': 'popularity_key',
        'json': '1',
      });
      
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode != 200) {
        print('OpenFoodFacts Suche Fehler: ${response.statusCode}');
        return [];
      }
      
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final products = json['products'] as List<dynamic>? ?? [];
      
      return products.map((p) {
        final productMap = p as Map<String, dynamic>;
        final code = productMap['code'] ?? productMap['_id'] ?? '';
        return OpenFoodFactsProduct.fromJson(code, {'product': productMap});
      }).where((p) => p.found && p.productName != null).toList();
    } catch (e) {
      print('Fehler bei der OpenFoodFacts Suche: $e');
      return [];
    }
  }
  
  void dispose() {
    _client.close();
  }
}

/// Demo-Service für OpenFoodFacts (für DEMO_MODE)
class DemoOpenFoodFactsService extends OpenFoodFactsService {
  DemoOpenFoodFactsService() : super();
  
  @override
  Future<OpenFoodFactsProduct> getProductByBarcode(String barcode) async {
    // Simulierte Verzögerung
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Demo-Produkte basierend auf Barcode
    final demoProducts = {
      '4006381333931': OpenFoodFactsProduct(
        barcode: '4006381333931',
        productName: 'Haferflocken',
        brand: 'Kölln',
        calories: 372,
        fat: 7.0,
        carbohydrates: 58.7,
        proteins: 13.5,
        fiber: 10.0,
        sugars: 1.0,
        salt: 0.01,
        nutriscore: 'a',
        servingSize: '40g',
      ),
      '4000400144690': OpenFoodFactsProduct(
        barcode: '4000400144690',
        productName: 'Milch 1,5%',
        brand: 'Müller',
        calories: 47,
        fat: 1.5,
        carbohydrates: 4.8,
        proteins: 3.4,
        sugars: 4.8,
        salt: 0.13,
        nutriscore: 'b',
        servingSize: '250ml',
      ),
      '7622210449283': OpenFoodFactsProduct(
        barcode: '7622210449283',
        productName: 'Vollmilch Schokolade',
        brand: 'Milka',
        calories: 530,
        fat: 29.5,
        carbohydrates: 58.5,
        proteins: 6.3,
        sugars: 56.5,
        salt: 0.33,
        nutriscore: 'e',
        servingSize: '100g',
      ),
    };
    
    if (demoProducts.containsKey(barcode)) {
      return demoProducts[barcode]!;
    }
    
    // Generisches Demo-Produkt für unbekannte Barcodes
    return OpenFoodFactsProduct(
      barcode: barcode,
      productName: 'Demo Produkt',
      brand: 'Demo Marke',
      calories: 250,
      fat: 10.0,
      carbohydrates: 30.0,
      proteins: 8.0,
      sugars: 5.0,
      salt: 0.5,
      nutriscore: 'c',
      servingSize: '100g',
    );
  }
  
  @override
  Future<List<OpenFoodFactsProduct>> searchProducts(String query, {int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Demo-Suchergebnisse
    return [
      OpenFoodFactsProduct(
        barcode: '1234567890123',
        productName: 'Apfel',
        brand: 'Bio',
        calories: 52,
        fat: 0.2,
        carbohydrates: 14.0,
        proteins: 0.3,
        sugars: 10.0,
        fiber: 2.4,
        nutriscore: 'a',
      ),
      OpenFoodFactsProduct(
        barcode: '2345678901234',
        productName: 'Vollkornbrot',
        brand: 'Bäcker Müller',
        calories: 215,
        fat: 1.8,
        carbohydrates: 42.0,
        proteins: 8.0,
        sugars: 3.5,
        fiber: 6.0,
        nutriscore: 'a',
      ),
      OpenFoodFactsProduct(
        barcode: '3456789012345',
        productName: 'Naturjoghurt',
        brand: 'Weihenstephan',
        calories: 62,
        fat: 3.5,
        carbohydrates: 4.6,
        proteins: 3.5,
        sugars: 4.6,
        nutriscore: 'a',
      ),
    ];
  }
}
