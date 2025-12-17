import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Service zum Parsen von Rezepten aus URLs (JSON-LD / schema.org)
class RecipeParserService {
  
  /// Extrahiert Rezeptdaten aus einer URL
  static Future<ParsedRecipeData?> parseFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; StatMe/1.0)',
        'Accept': 'text/html',
      });

      if (response.statusCode != 200) return null;

      final html = response.body;
      
      // JSON-LD extrahieren
      final jsonLd = _extractJsonLd(html);
      if (jsonLd != null) {
        return _parseJsonLd(jsonLd, url);
      }

      // Fallback: Titel aus HTML
      return _extractBasic(html, url);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _extractJsonLd(String html) {
    final regex = RegExp(
      '<script[^>]*type=["\']application/ld\\+json["\'][^>]*>([\\s\\S]*?)</script>',
      caseSensitive: false,
    );

    for (final match in regex.allMatches(html)) {
      try {
        final data = jsonDecode(match.group(1)?.trim() ?? '');
        
        if (data is List) {
          for (final item in data) {
            if (_isRecipe(item)) return item as Map<String, dynamic>;
          }
        } else if (data is Map<String, dynamic>) {
          if (_isRecipe(data)) return data;
          if (data['@graph'] is List) {
            for (final item in data['@graph']) {
              if (_isRecipe(item)) return item as Map<String, dynamic>;
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static bool _isRecipe(dynamic data) {
    if (data is! Map) return false;
    final type = data['@type'];
    return type == 'Recipe' || (type is List && type.contains('Recipe'));
  }

  static ParsedRecipeData? _parseJsonLd(Map<String, dynamic> data, String sourceUrl) {
    final title = data['name'] as String?;
    if (title == null || title.isEmpty) return null;

    // Zutaten
    final ingredients = <String>[];
    if (data['recipeIngredient'] is List) {
      ingredients.addAll((data['recipeIngredient'] as List).map((e) => e.toString()));
    }

    // Schritte
    final steps = <String>[];
    final instructions = data['recipeInstructions'];
    if (instructions is List) {
      for (final step in instructions) {
        if (step is String) {
          steps.add(step);
        } else if (step is Map) {
          final text = step['text'] ?? step['name'] ?? '';
          if (text.toString().isNotEmpty) steps.add(text.toString());
        }
      }
    } else if (instructions is String) {
      steps.addAll(instructions.split('\n').where((s) => s.trim().isNotEmpty));
    }

    // Zeit
    int? prepTime = _parseDuration(data['prepTime']);
    int? cookTime = _parseDuration(data['cookTime']) ?? _parseDuration(data['totalTime']);

    // Portionen
    int servings = 4;
    final yield_ = data['recipeYield'];
    if (yield_ is int) {
      servings = yield_;
    } else if (yield_ is String) {
      final m = RegExp(r'(\d+)').firstMatch(yield_);
      if (m != null) servings = int.tryParse(m.group(1) ?? '') ?? 4;
    }

    // Bild
    String? imageUrl;
    final img = data['image'];
    if (img is String) {
      imageUrl = img;
    } else if (img is List && img.isNotEmpty) {
      imageUrl = img.first is String ? img.first : (img.first as Map?)?['url'];
    } else if (img is Map) {
      imageUrl = img['url'] as String?;
    }

    // Nährwerte
    int? calories, protein, carbs, fat;
    if (data['nutrition'] is Map) {
      final n = data['nutrition'] as Map;
      calories = _parseNum(n['calories']);
      protein = _parseNum(n['proteinContent']);
      carbs = _parseNum(n['carbohydrateContent']);
      fat = _parseNum(n['fatContent']);
    }

    return ParsedRecipeData(
      title: title,
      description: data['description'] as String?,
      imageUrl: imageUrl,
      sourceUrl: sourceUrl,
      ingredientsRaw: ingredients,
      steps: steps,
      servings: servings,
      prepTimeMinutes: prepTime,
      cookTimeMinutes: cookTime,
      caloriesPerServing: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      category: _guessCategory(title),
    );
  }

  static int? _parseDuration(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    final s = v.toString();
    if (!s.contains('P')) return int.tryParse(s);
    
    int mins = 0;
    final h = RegExp(r'(\d+)H').firstMatch(s);
    if (h != null) mins += (int.tryParse(h.group(1) ?? '') ?? 0) * 60;
    final m = RegExp(r'(\d+)M').firstMatch(s);
    if (m != null) mins += int.tryParse(m.group(1) ?? '') ?? 0;
    return mins > 0 ? mins : null;
  }

  static int? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    final m = RegExp(r'(\d+)').firstMatch(v.toString());
    return m != null ? int.tryParse(m.group(1) ?? '') : null;
  }

  static RecipeCategory _guessCategory(String title) {
    final t = title.toLowerCase();
    if (t.contains('frühstück') || t.contains('breakfast')) return RecipeCategory.breakfast;
    if (t.contains('salat') || t.contains('salad')) return RecipeCategory.salad;
    if (t.contains('suppe') || t.contains('soup')) return RecipeCategory.soup;
    if (t.contains('kuchen') || t.contains('torte') || t.contains('dessert')) return RecipeCategory.dessert;
    if (t.contains('smoothie') || t.contains('shake')) return RecipeCategory.drink;
    if (t.contains('brot') || t.contains('backen')) return RecipeCategory.baking;
    return RecipeCategory.other;
  }

  static ParsedRecipeData? _extractBasic(String html, String url) {
    final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false).firstMatch(html);
    if (titleMatch == null) return null;
    
    var title = titleMatch.group(1)?.trim() ?? '';
    title = title.split(RegExp(r'\s*[\|–-]\s*')).first.trim();
    if (title.isEmpty) return null;

    return ParsedRecipeData(
      title: title,
      sourceUrl: url,
      ingredientsRaw: [],
      steps: [],
      servings: 4,
    );
  }

  /// Parsed rohe Zutaten-Strings in strukturierte Zutaten
  static List<RecipeIngredient> parseIngredients(List<String> raw) {
    return raw.map(_parseIngredient).toList();
  }

  static RecipeIngredient _parseIngredient(String s) {
    s = s.trim();
    
    final pattern = RegExp(
      r'^(\d+(?:[,./]\d+)?)\s*(g|kg|ml|l|TL|EL|Stück|Prise|Bund|Dose)?\.?\s+(.+?)(?:\s*\(([^)]+)\))?$',
      caseSensitive: false,
    );
    
    final m = pattern.firstMatch(s);
    if (m != null) {
      var amountStr = m.group(1)?.replaceAll(',', '.');
      double? amount;
      if (amountStr != null) {
        if (amountStr.contains('/')) {
          final parts = amountStr.split('/');
          if (parts.length == 2) {
            final num = double.tryParse(parts[0]);
            final denom = double.tryParse(parts[1]);
            if (num != null && denom != null && denom != 0) amount = num / denom;
          }
        } else {
          amount = double.tryParse(amountStr);
        }
      }
      
      return RecipeIngredient(
        name: m.group(3)?.trim() ?? s,
        amount: amount,
        unit: m.group(2),
        note: m.group(4),
      );
    }
    
    return RecipeIngredient(name: s);
  }
}

/// Geparste Rezeptdaten
class ParsedRecipeData {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? sourceUrl;
  final List<String> ingredientsRaw;
  final List<String> steps;
  final int servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? caloriesPerServing;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;
  final RecipeCategory? category;

  const ParsedRecipeData({
    required this.title,
    this.description,
    this.imageUrl,
    this.sourceUrl,
    required this.ingredientsRaw,
    required this.steps,
    required this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.caloriesPerServing,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.category,
  });

  List<RecipeIngredient> get parsedIngredients =>
      RecipeParserService.parseIngredients(ingredientsRaw);
}
