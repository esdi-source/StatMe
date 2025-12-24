import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_check_model.dart';

class ProductCheckService {
  static const String _offApiUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const String _obfApiUrl = 'https://world.openbeautyfacts.org/api/v0/product';
  static const String _historyKey = 'product_check_history';

  // Singleton
  static final ProductCheckService _instance = ProductCheckService._internal();
  factory ProductCheckService() => _instance;
  ProductCheckService._internal();

  Future<ProductCheckResult?> fetchProduct(String barcode) async {
    // 1. Try Open Food Facts
    try {
      final offResponse = await http.get(Uri.parse('$_offApiUrl/$barcode.json'));
      if (offResponse.statusCode == 200) {
        final json = jsonDecode(offResponse.body);
        if (json['status'] == 1) {
          final product = ProductCheckResult.fromJson(json, ProductSource.openFoodFacts);
          await _addToHistory(product);
          return product;
        }
      }
    } catch (e) {
      print('Error fetching from OFF: $e');
    }

    // 2. Try Open Beauty Facts
    try {
      final obfResponse = await http.get(Uri.parse('$_obfApiUrl/$barcode.json'));
      if (obfResponse.statusCode == 200) {
        final json = jsonDecode(obfResponse.body);
        if (json['status'] == 1) {
          final product = ProductCheckResult.fromJson(json, ProductSource.openBeautyFacts);
          await _addToHistory(product);
          return product;
        }
      }
    } catch (e) {
      print('Error fetching from OBF: $e');
    }

    return null;
  }

  Future<void> _addToHistory(ProductCheckResult product) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    // Remove existing entry for same barcode to avoid duplicates and move to top
    historyJson.removeWhere((item) {
      try {
        final p = ProductCheckResult.fromLocalJson(jsonDecode(item));
        return p.barcode == product.barcode;
      } catch (e) {
        return false;
      }
    });

    // Add new entry
    historyJson.insert(0, jsonEncode(product.toJson()));
    
    // Limit history to 50 items
    if (historyJson.length > 50) {
      historyJson.removeRange(50, historyJson.length);
    }

    await prefs.setStringList(_historyKey, historyJson);
  }

  Future<List<ProductCheckResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    return historyJson.map((item) {
      try {
        return ProductCheckResult.fromLocalJson(jsonDecode(item));
      } catch (e) {
        return null;
      }
    }).whereType<ProductCheckResult>().toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
