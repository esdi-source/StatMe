/// OpenFoodFacts API Service
/// Ermöglicht das Abrufen von Produktdaten über Barcode-Scan
/// API Dokumentation: https://openfoodfacts.github.io/openfoodfacts-server/api/
library;

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
  static const String _baseUrl = 'https://world.openfoodfacts.org';
  static const String _userAgent = 'StatMe App - Flutter - Version 1.0 - https://github.com/esdi-source/StatMe';
  
  final http.Client _client;
  
  OpenFoodFactsService({http.Client? client}) : _client = client ?? http.Client();
  
  /// Produkt anhand des Barcodes abrufen
  Future<OpenFoodFactsProduct> getProductByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v0/product/$barcode.json');
      
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
  
  /// Produkte nach Name suchen - verwendet die CGI API für bessere Suche
  Future<List<OpenFoodFactsProduct>> searchProducts(String query, {int limit = 25}) async {
    try {
      // Verwende die CGI Search API für bessere Ergebnisse
      final uri = Uri.parse('$_baseUrl/cgi/search.pl').replace(queryParameters: {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'page_size': limit.toString(),
        'page': '1',
        'json': '1',
        'fields': 'code,product_name,product_name_de,brands,nutriments,nutriscore_grade,image_front_url,serving_size',
      });
      
      print('OpenFoodFacts Suche: $uri'); // Debug
      
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('OpenFoodFacts Suche Fehler: ${response.statusCode}');
        // Fallback auf Demo-Daten bei API-Fehler
        return _searchDemoProducts(query, limit);
      }
      
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final products = json['products'] as List<dynamic>? ?? [];
      
      print('OpenFoodFacts: ${products.length} Produkte gefunden für "$query"'); // Debug
      
      final results = products.map((p) {
        final productMap = p as Map<String, dynamic>;
        final code = productMap['code']?.toString() ?? productMap['_id']?.toString() ?? '';
        return OpenFoodFactsProduct.fromJson(code, {'product': productMap});
      }).where((p) => p.found && p.productName != null && p.productName!.isNotEmpty).toList();
      
      // Wenn keine Ergebnisse, Fallback auf Demo-Daten
      if (results.isEmpty) {
        return _searchDemoProducts(query, limit);
      }
      
      return results;
    } catch (e) {
      print('Fehler bei der OpenFoodFacts Suche: $e');
      // Fallback auf Demo-Daten bei Fehler (z.B. CORS, Timeout)
      return _searchDemoProducts(query, limit);
    }
  }
  
  /// Fallback-Suche in Demo-Produkten für CORS-Probleme im Web
  List<OpenFoodFactsProduct> _searchDemoProducts(String query, int limit) {
    print('Fallback auf Demo-Produkte für "$query"');
    final queryLower = query.toLowerCase();
    return DemoOpenFoodFactsService._allDemoProducts
        .where((p) {
          final name = (p.productName ?? '').toLowerCase();
          final brand = (p.brand ?? '').toLowerCase();
          return name.contains(queryLower) || brand.contains(queryLower);
        })
        .take(limit)
        .toList();
  }
  
  void dispose() {
    _client.close();
  }
}

/// Demo-Service für OpenFoodFacts (für DEMO_MODE)
class DemoOpenFoodFactsService extends OpenFoodFactsService {
  DemoOpenFoodFactsService() : super();
  
  // Umfangreiche Demo-Produktdatenbank
  static final List<OpenFoodFactsProduct> _allDemoProducts = [
    // Obst
    OpenFoodFactsProduct(barcode: '1001', productName: 'Apfel', brand: 'Bio', calories: 52, fat: 0.2, carbohydrates: 14.0, proteins: 0.3, sugars: 10.0, fiber: 2.4, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '1002', productName: 'Banane', brand: 'Chiquita', calories: 89, fat: 0.3, carbohydrates: 23.0, proteins: 1.1, sugars: 12.0, fiber: 2.6, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '1003', productName: 'Orange', brand: 'Bio', calories: 47, fat: 0.1, carbohydrates: 12.0, proteins: 0.9, sugars: 9.0, fiber: 2.4, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '1004', productName: 'Erdbeeren', brand: 'Regional', calories: 32, fat: 0.3, carbohydrates: 7.7, proteins: 0.7, sugars: 4.9, fiber: 2.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '1005', productName: 'Blaubeeren', brand: 'Bio', calories: 57, fat: 0.3, carbohydrates: 14.5, proteins: 0.7, sugars: 10.0, fiber: 2.4, nutriscore: 'a'),
    
    // Gemüse
    OpenFoodFactsProduct(barcode: '2001', productName: 'Brokkoli', brand: 'Bio', calories: 34, fat: 0.4, carbohydrates: 7.0, proteins: 2.8, sugars: 1.7, fiber: 2.6, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '2002', productName: 'Karotten', brand: 'Regional', calories: 41, fat: 0.2, carbohydrates: 10.0, proteins: 0.9, sugars: 4.7, fiber: 2.8, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '2003', productName: 'Spinat', brand: 'Bio', calories: 23, fat: 0.4, carbohydrates: 3.6, proteins: 2.9, sugars: 0.4, fiber: 2.2, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '2004', productName: 'Tomaten', brand: 'Bio', calories: 18, fat: 0.2, carbohydrates: 3.9, proteins: 0.9, sugars: 2.6, fiber: 1.2, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '2005', productName: 'Paprika rot', brand: 'Bio', calories: 31, fat: 0.3, carbohydrates: 6.0, proteins: 1.0, sugars: 4.2, fiber: 2.1, nutriscore: 'a'),
    
    // Milchprodukte
    OpenFoodFactsProduct(barcode: '3001', productName: 'Vollmilch 3,5%', brand: 'Weihenstephan', calories: 64, fat: 3.5, carbohydrates: 4.8, proteins: 3.3, sugars: 4.8, nutriscore: 'b'),
    OpenFoodFactsProduct(barcode: '3002', productName: 'Fettarme Milch 1,5%', brand: 'Müller', calories: 47, fat: 1.5, carbohydrates: 4.8, proteins: 3.4, sugars: 4.8, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '3003', productName: 'Naturjoghurt', brand: 'Weihenstephan', calories: 62, fat: 3.5, carbohydrates: 4.6, proteins: 3.5, sugars: 4.6, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '3004', productName: 'Griechischer Joghurt', brand: 'Mevgal', calories: 133, fat: 10.0, carbohydrates: 4.0, proteins: 6.0, sugars: 4.0, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '3005', productName: 'Magerquark', brand: 'Milram', calories: 67, fat: 0.2, carbohydrates: 4.0, proteins: 12.0, sugars: 4.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '3006', productName: 'Gouda Käse', brand: 'Leerdammer', calories: 356, fat: 27.0, carbohydrates: 0.0, proteins: 25.0, sugars: 0.0, nutriscore: 'd'),
    OpenFoodFactsProduct(barcode: '3007', productName: 'Mozzarella', brand: 'Galbani', calories: 280, fat: 22.0, carbohydrates: 0.5, proteins: 19.0, sugars: 0.5, nutriscore: 'd'),
    
    // Getreide & Brot
    OpenFoodFactsProduct(barcode: '4001', productName: 'Haferflocken', brand: 'Kölln', calories: 372, fat: 7.0, carbohydrates: 58.7, proteins: 13.5, sugars: 1.0, fiber: 10.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '4002', productName: 'Vollkornbrot', brand: 'Bäcker', calories: 215, fat: 1.8, carbohydrates: 42.0, proteins: 8.0, sugars: 3.5, fiber: 6.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '4003', productName: 'Toastbrot', brand: 'Golden Toast', calories: 265, fat: 3.5, carbohydrates: 49.0, proteins: 8.0, sugars: 4.0, fiber: 2.5, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '4004', productName: 'Müsli', brand: 'Seitenbacher', calories: 380, fat: 8.0, carbohydrates: 60.0, proteins: 12.0, sugars: 15.0, fiber: 9.0, nutriscore: 'b'),
    OpenFoodFactsProduct(barcode: '4005', productName: 'Cornflakes', brand: 'Kelloggs', calories: 378, fat: 0.9, carbohydrates: 84.0, proteins: 7.5, sugars: 8.0, fiber: 3.0, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '4006', productName: 'Reis Basmati', brand: 'Uncle Bens', calories: 350, fat: 0.6, carbohydrates: 78.0, proteins: 7.0, sugars: 0.0, fiber: 1.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '4007', productName: 'Nudeln Spaghetti', brand: 'Barilla', calories: 359, fat: 1.5, carbohydrates: 71.0, proteins: 13.0, sugars: 3.0, fiber: 3.0, nutriscore: 'a'),
    
    // Fleisch & Fisch
    OpenFoodFactsProduct(barcode: '5001', productName: 'Hähnchenbrust', brand: 'Wiesenhof', calories: 110, fat: 1.0, carbohydrates: 0.0, proteins: 24.0, sugars: 0.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '5002', productName: 'Rinderhackfleisch', brand: 'Metzger', calories: 212, fat: 12.0, carbohydrates: 0.0, proteins: 26.0, sugars: 0.0, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '5003', productName: 'Lachs Filet', brand: 'Frisch', calories: 208, fat: 13.0, carbohydrates: 0.0, proteins: 20.0, sugars: 0.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '5004', productName: 'Thunfisch in Wasser', brand: 'Saupiquet', calories: 108, fat: 1.0, carbohydrates: 0.0, proteins: 25.0, sugars: 0.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '5005', productName: 'Putenbrust', brand: 'Gutfried', calories: 105, fat: 1.0, carbohydrates: 0.5, proteins: 23.0, sugars: 0.5, nutriscore: 'a'),
    
    // Snacks & Süßigkeiten
    OpenFoodFactsProduct(barcode: '6001', productName: 'Vollmilch Schokolade', brand: 'Milka', calories: 530, fat: 29.5, carbohydrates: 58.5, proteins: 6.3, sugars: 56.5, nutriscore: 'e'),
    OpenFoodFactsProduct(barcode: '6002', productName: 'Zartbitter Schokolade 70%', brand: 'Lindt', calories: 540, fat: 42.0, carbohydrates: 33.0, proteins: 8.0, sugars: 24.0, nutriscore: 'e'),
    OpenFoodFactsProduct(barcode: '6003', productName: 'Chips Paprika', brand: 'Chio', calories: 535, fat: 33.0, carbohydrates: 50.0, proteins: 5.5, sugars: 3.0, nutriscore: 'd'),
    OpenFoodFactsProduct(barcode: '6004', productName: 'Studentenfutter', brand: 'Seeberger', calories: 480, fat: 32.0, carbohydrates: 35.0, proteins: 14.0, sugars: 25.0, fiber: 5.0, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '6005', productName: 'Gummibärchen', brand: 'Haribo', calories: 343, fat: 0.5, carbohydrates: 77.0, proteins: 6.9, sugars: 46.0, nutriscore: 'd'),
    
    // Getränke
    OpenFoodFactsProduct(barcode: '7001', productName: 'Cola', brand: 'Coca-Cola', calories: 42, fat: 0.0, carbohydrates: 10.6, proteins: 0.0, sugars: 10.6, nutriscore: 'e'),
    OpenFoodFactsProduct(barcode: '7002', productName: 'Orangensaft', brand: 'Hohes C', calories: 45, fat: 0.0, carbohydrates: 10.0, proteins: 0.5, sugars: 9.0, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '7003', productName: 'Apfelschorle', brand: 'Gerolsteiner', calories: 24, fat: 0.0, carbohydrates: 5.5, proteins: 0.0, sugars: 5.5, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '7004', productName: 'Mineralwasser', brand: 'Volvic', calories: 0, fat: 0.0, carbohydrates: 0.0, proteins: 0.0, sugars: 0.0, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '7005', productName: 'Energy Drink', brand: 'Red Bull', calories: 45, fat: 0.0, carbohydrates: 11.0, proteins: 0.0, sugars: 11.0, nutriscore: 'd'),
    
    // Fertiggerichte
    OpenFoodFactsProduct(barcode: '8001', productName: 'Tiefkühlpizza Margherita', brand: 'Dr. Oetker', calories: 220, fat: 8.0, carbohydrates: 28.0, proteins: 9.0, sugars: 4.0, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '8002', productName: 'Lasagne Bolognese', brand: 'Frosta', calories: 140, fat: 6.0, carbohydrates: 13.0, proteins: 8.0, sugars: 3.0, nutriscore: 'b'),
    OpenFoodFactsProduct(barcode: '8003', productName: 'Gemüsepfanne Asia', brand: 'Iglo', calories: 65, fat: 2.0, carbohydrates: 8.0, proteins: 3.0, sugars: 4.0, nutriscore: 'a'),
    
    // Aufstriche
    OpenFoodFactsProduct(barcode: '9001', productName: 'Nutella', brand: 'Ferrero', calories: 539, fat: 30.9, carbohydrates: 57.5, proteins: 6.3, sugars: 56.3, nutriscore: 'e'),
    OpenFoodFactsProduct(barcode: '9002', productName: 'Erdnussbutter', brand: 'Calvé', calories: 600, fat: 50.0, carbohydrates: 12.0, proteins: 26.0, sugars: 6.0, nutriscore: 'c'),
    OpenFoodFactsProduct(barcode: '9003', productName: 'Honig', brand: 'Langnese', calories: 304, fat: 0.0, carbohydrates: 75.0, proteins: 0.3, sugars: 75.0, nutriscore: 'd'),
    OpenFoodFactsProduct(barcode: '9004', productName: 'Marmelade Erdbeere', brand: 'Schwartau', calories: 255, fat: 0.2, carbohydrates: 62.0, proteins: 0.3, sugars: 60.0, nutriscore: 'd'),
    
    // Eier & Proteine
    OpenFoodFactsProduct(barcode: '1101', productName: 'Eier Freiland', brand: 'Bio', calories: 155, fat: 11.0, carbohydrates: 1.1, proteins: 13.0, sugars: 1.1, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '1102', productName: 'Tofu Natur', brand: 'Taifun', calories: 124, fat: 7.0, carbohydrates: 1.5, proteins: 13.0, sugars: 0.5, nutriscore: 'a'),
    OpenFoodFactsProduct(barcode: '1103', productName: 'Tempeh', brand: 'Alberts', calories: 193, fat: 11.0, carbohydrates: 9.0, proteins: 19.0, sugars: 0.0, fiber: 6.0, nutriscore: 'a'),
  ];
  
  @override
  Future<OpenFoodFactsProduct> getProductByBarcode(String barcode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Suche in Demo-Produkten
    try {
      return _allDemoProducts.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
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
  }
  
  @override
  Future<List<OpenFoodFactsProduct>> searchProducts(String query, {int limit = 25}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final queryLower = query.toLowerCase();
    
    // Filtere Produkte nach Suchbegriff
    final results = _allDemoProducts.where((p) {
      final name = (p.productName ?? '').toLowerCase();
      final brand = (p.brand ?? '').toLowerCase();
      return name.contains(queryLower) || brand.contains(queryLower);
    }).take(limit).toList();
    
    return results;
  }
}
