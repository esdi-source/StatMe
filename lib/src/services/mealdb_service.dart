import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Service für TheMealDB API - Primäre Rezeptdatenbank
/// API-Dokumentation: https://www.themealdb.com/api.php
class MealDbService {
  static const _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  
  // ============================================================================
  // DEUTSCH-ENGLISCH ÜBERSETZUNG
  // ============================================================================
  
  /// Übersetzt deutsche Suchbegriffe zu Englisch für API-Anfragen
  static final Map<String, String> _germanToEnglish = {
    // Grundlagen
    'kuchen': 'cake',
    'torten': 'cake',
    'torte': 'cake',
    'plätzchen': 'cookies',
    'kekse': 'cookies',
    'brot': 'bread',
    'brötchen': 'bread',
    'nudeln': 'pasta',
    'spaghetti': 'spaghetti',
    'pizza': 'pizza',
    'reis': 'rice',
    'suppe': 'soup',
    'salat': 'salad',
    'fleisch': 'meat',
    'huhn': 'chicken',
    'hähnchen': 'chicken',
    'hühnchen': 'chicken',
    'rind': 'beef',
    'rindfleisch': 'beef',
    'schwein': 'pork',
    'schweinefleisch': 'pork',
    'fisch': 'fish',
    'lachs': 'salmon',
    'lamm': 'lamb',
    'ente': 'duck',
    'truthahn': 'turkey',
    
    // Gerichte
    'auflauf': 'casserole',
    'eintopf': 'stew',
    'braten': 'roast',
    'schnitzel': 'schnitzel',
    'gulasch': 'goulash',
    'curry': 'curry',
    'burger': 'burger',
    'sandwich': 'sandwich',
    'tacos': 'tacos',
    'wraps': 'wraps',
    'pfannkuchen': 'pancakes',
    'waffeln': 'waffles',
    'omelett': 'omelette',
    'rührei': 'scrambled',
    
    // Süßes
    'dessert': 'dessert',
    'nachtisch': 'dessert',
    'eis': 'ice cream',
    'pudding': 'pudding',
    'mousse': 'mousse',
    'creme': 'cream',
    'schokolade': 'chocolate',
    'vanille': 'vanilla',
    'erdbeeren': 'strawberry',
    'äpfel': 'apple',
    'apfel': 'apple',
    'banane': 'banana',
    'kirschen': 'cherry',
    'kirsche': 'cherry',
    'zimt': 'cinnamon',
    'brownie': 'brownie',
    'muffin': 'muffin',
    'cupcake': 'cupcake',
    
    // Küchen
    'italienisch': 'italian',
    'mexikanisch': 'mexican',
    'asiatisch': 'asian',
    'chinesisch': 'chinese',
    'japanisch': 'japanese',
    'indisch': 'indian',
    'thailändisch': 'thai',
    'griechisch': 'greek',
    'französisch': 'french',
    'amerikanisch': 'american',
    'britisch': 'british',
    'marokkanisch': 'moroccan',
    
    // Kategorien
    'frühstück': 'breakfast',
    'mittagessen': 'lunch',
    'abendessen': 'dinner',
    'snack': 'snack',
    'vorspeise': 'starter',
    'beilage': 'side',
    'hauptgericht': 'main',
    
    // Gemüse
    'gemüse': 'vegetable',
    'kartoffel': 'potato',
    'kartoffeln': 'potato',
    'tomaten': 'tomato',
    'tomate': 'tomato',
    'zwiebel': 'onion',
    'knoblauch': 'garlic',
    'paprika': 'pepper',
    'karotten': 'carrot',
    'brokkoli': 'broccoli',
    'spinat': 'spinach',
    'pilze': 'mushroom',
    'champignons': 'mushroom',
    'bohnen': 'beans',
    'erbsen': 'peas',
    'mais': 'corn',
    'kürbis': 'pumpkin',
    'zucchini': 'zucchini',
    'aubergine': 'eggplant',
    
    // Sonstiges
    'käse': 'cheese',
    'eier': 'egg',
    'ei': 'egg',
    'milch': 'milk',
    'butter': 'butter',
    'sahne': 'cream',
    'joghurt': 'yogurt',
    'nüsse': 'nuts',
    'mandeln': 'almond',
    'honig': 'honey',
    'zucker': 'sugar',
    'mehl': 'flour',
    
    // Spezifische Gerichte
    'lasagne': 'lasagna',
    'risotto': 'risotto',
    'paella': 'paella',
    'sushi': 'sushi',
    'teriyaki': 'teriyaki',
    'pad thai': 'pad thai',
    'korma': 'korma',
    'biryani': 'biryani',
    'fajitas': 'fajitas',
    'enchiladas': 'enchilada',
    'quesadilla': 'quesadilla',
    'nachos': 'nachos',
    'moussaka': 'moussaka',
    'gyros': 'gyros',
    'falafel': 'falafel',
    'hummus': 'hummus',
  };
  
  /// Übersetzt deutschen Begriff zu Englisch
  static String translateToEnglish(String german) {
    final lower = german.toLowerCase().trim();
    
    // Direkte Übersetzung
    if (_germanToEnglish.containsKey(lower)) {
      return _germanToEnglish[lower]!;
    }
    
    // Teilübersetzung versuchen (erste Wort das passt)
    for (final entry in _germanToEnglish.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Nichts gefunden - Original zurückgeben (funktioniert oft auch)
    return german;
  }
  
  /// Übersetzt englische Kategorie/Herkunft zu Deutsch
  static String translateCategoryToGerman(String english) {
    const translations = {
      'Beef': 'Rindfleisch',
      'Chicken': 'Hähnchen',
      'Dessert': 'Dessert',
      'Lamb': 'Lamm',
      'Miscellaneous': 'Verschiedenes',
      'Pasta': 'Pasta',
      'Pork': 'Schweinefleisch',
      'Seafood': 'Meeresfrüchte',
      'Side': 'Beilage',
      'Starter': 'Vorspeise',
      'Vegan': 'Vegan',
      'Vegetarian': 'Vegetarisch',
      'Breakfast': 'Frühstück',
      'Goat': 'Ziege',
    };
    return translations[english] ?? english;
  }
  
  static String translateAreaToGerman(String english) {
    const translations = {
      'American': 'Amerikanisch',
      'British': 'Britisch',
      'Canadian': 'Kanadisch',
      'Chinese': 'Chinesisch',
      'Croatian': 'Kroatisch',
      'Dutch': 'Niederländisch',
      'Egyptian': 'Ägyptisch',
      'Filipino': 'Philippinisch',
      'French': 'Französisch',
      'Greek': 'Griechisch',
      'Indian': 'Indisch',
      'Irish': 'Irisch',
      'Italian': 'Italienisch',
      'Jamaican': 'Jamaikanisch',
      'Japanese': 'Japanisch',
      'Kenyan': 'Kenianisch',
      'Malaysian': 'Malaysisch',
      'Mexican': 'Mexikanisch',
      'Moroccan': 'Marokkanisch',
      'Polish': 'Polnisch',
      'Portuguese': 'Portugiesisch',
      'Russian': 'Russisch',
      'Spanish': 'Spanisch',
      'Thai': 'Thailändisch',
      'Tunisian': 'Tunesisch',
      'Turkish': 'Türkisch',
      'Ukrainian': 'Ukrainisch',
      'Unknown': 'Unbekannt',
      'Vietnamese': 'Vietnamesisch',
    };
    return translations[english] ?? english;
  }
  
  // ============================================================================
  // API METHODEN
  // ============================================================================
  
  /// Sucht Rezepte nach Begriff (übersetzt automatisch)
  static Future<List<MealDbRecipe>> searchMeals(String query) async {
    if (query.trim().isEmpty) return [];
    
    // Deutsche Begriffe übersetzen
    final englishQuery = translateToEnglish(query);
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search.php?s=$englishQuery'),
      );
      
      if (response.statusCode != 200) return [];
      
      final data = jsonDecode(response.body);
      final meals = data['meals'];
      
      if (meals == null) return [];
      
      return (meals as List)
          .map((m) => MealDbRecipe.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Holt ein Rezept nach ID
  static Future<MealDbRecipe?> getMealById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lookup.php?i=$id'),
      );
      
      if (response.statusCode != 200) return null;
      
      final data = jsonDecode(response.body);
      final meals = data['meals'];
      
      if (meals == null || (meals as List).isEmpty) return null;
      
      return MealDbRecipe.fromJson(meals.first as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  /// Holt ein zufälliges Rezept
  static Future<MealDbRecipe?> getRandomMeal() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/random.php'),
      );
      
      if (response.statusCode != 200) return null;
      
      final data = jsonDecode(response.body);
      final meals = data['meals'];
      
      if (meals == null || (meals as List).isEmpty) return null;
      
      return MealDbRecipe.fromJson(meals.first as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  /// Holt alle Kategorien
  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories.php'),
      );
      
      if (response.statusCode != 200) return [];
      
      final data = jsonDecode(response.body);
      final categories = data['categories'] as List?;
      
      if (categories == null) return [];
      
      return categories
          .map((c) => c['strCategory'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Filtert nach Kategorie
  static Future<List<MealDbRecipe>> filterByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/filter.php?c=$category'),
      );
      
      if (response.statusCode != 200) return [];
      
      final data = jsonDecode(response.body);
      final meals = data['meals'];
      
      if (meals == null) return [];
      
      // Filter gibt nur Basis-Info, wir holen vollständige Daten
      final results = <MealDbRecipe>[];
      for (final m in (meals as List).take(10)) {
        final full = await getMealById(m['idMeal'] as String);
        if (full != null) results.add(full);
      }
      return results;
    } catch (e) {
      return [];
    }
  }
}

// ============================================================================
// MEALDB RECIPE MODEL
// ============================================================================

/// Rezept aus TheMealDB
class MealDbRecipe {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String instructions;
  final String? imageUrl;
  final String? youtubeUrl;
  final List<MealDbIngredient> ingredients;
  final String? source;
  
  const MealDbRecipe({
    required this.id,
    required this.name,
    this.category,
    this.area,
    required this.instructions,
    this.imageUrl,
    this.youtubeUrl,
    required this.ingredients,
    this.source,
  });
  
  /// Kategorie auf Deutsch
  String get categoryGerman => category != null 
      ? MealDbService.translateCategoryToGerman(category!)
      : 'Unbekannt';
  
  /// Herkunft auf Deutsch
  String get areaGerman => area != null 
      ? MealDbService.translateAreaToGerman(area!)
      : 'Unbekannt';
  
  /// Schritte als Liste
  List<String> get steps {
    return instructions
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 3)
        .toList();
  }
  
  factory MealDbRecipe.fromJson(Map<String, dynamic> json) {
    // Zutaten extrahieren (bis zu 20 Stück)
    final ingredients = <MealDbIngredient>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'] as String?;
      final measure = json['strMeasure$i'] as String?;
      
      if (ingredient != null && ingredient.trim().isNotEmpty) {
        ingredients.add(MealDbIngredient(
          name: ingredient.trim(),
          measure: measure?.trim(),
        ));
      }
    }
    
    return MealDbRecipe(
      id: json['idMeal'] as String,
      name: json['strMeal'] as String,
      category: json['strCategory'] as String?,
      area: json['strArea'] as String?,
      instructions: json['strInstructions'] as String? ?? '',
      imageUrl: json['strMealThumb'] as String?,
      youtubeUrl: json['strYoutube'] as String?,
      ingredients: ingredients,
      source: json['strSource'] as String?,
    );
  }
  
  /// Konvertiert zu App-internem Recipe Model
  Recipe toRecipe(String oderId) {
    final now = DateTime.now();
    
    // Kategorie mappen
    RecipeCategory appCategory;
    switch (category?.toLowerCase()) {
      case 'breakfast':
        appCategory = RecipeCategory.breakfast;
        break;
      case 'dessert':
        appCategory = RecipeCategory.dessert;
        break;
      case 'pasta':
      case 'side':
        appCategory = RecipeCategory.lunch;
        break;
      case 'starter':
        appCategory = RecipeCategory.snack;
        break;
      case 'vegan':
      case 'vegetarian':
        appCategory = RecipeCategory.salad;
        break;
      default:
        appCategory = RecipeCategory.dinner;
    }
    
    // Tags ableiten
    final tags = <RecipeTag>{};
    if (category?.toLowerCase() == 'vegan') tags.add(RecipeTag.vegan);
    if (category?.toLowerCase() == 'vegetarian') tags.add(RecipeTag.vegetarian);
    if (ingredients.length <= 5) tags.add(RecipeTag.easy);
    if (steps.length <= 5) tags.add(RecipeTag.quick);
    
    return Recipe(
      id: 'mealdb_$id',
      oderId: oderId,
      title: name,
      description: '$categoryGerman • $areaGerman',
      imageUrl: imageUrl,
      sourceUrl: source,
      ingredients: ingredients.map((i) => i.toRecipeIngredient()).toList(),
      steps: steps,
      servings: 4, // TheMealDB gibt keine Portionen an
      category: appCategory,
      tags: tags,
      status: RecipeStatus.wishlist,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Zutat aus TheMealDB
class MealDbIngredient {
  final String name;
  final String? measure;
  
  const MealDbIngredient({
    required this.name,
    this.measure,
  });
  
  /// Konvertiert zu App-internem Ingredient
  RecipeIngredient toRecipeIngredient() {
    // Versuche Menge und Einheit aus measure zu parsen
    double? amount;
    String? unit;
    
    if (measure != null && measure!.isNotEmpty) {
      final regex = RegExp(r'^([\d./]+)\s*(.*)$');
      final match = regex.firstMatch(measure!.trim());
      
      if (match != null) {
        // Brüche verarbeiten (z.B. "1/2")
        final numStr = match.group(1) ?? '';
        if (numStr.contains('/')) {
          final parts = numStr.split('/');
          if (parts.length == 2) {
            final num = double.tryParse(parts[0]);
            final denom = double.tryParse(parts[1]);
            if (num != null && denom != null && denom != 0) {
              amount = num / denom;
            }
          }
        } else {
          amount = double.tryParse(numStr);
        }
        unit = match.group(2)?.trim();
        if (unit?.isEmpty ?? true) unit = null;
      } else {
        // Keine Zahl gefunden, alles ist Einheit/Notiz
        unit = measure;
      }
    }
    
    return RecipeIngredient(
      name: name,
      amount: amount,
      unit: unit,
    );
  }
}
