import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ============================================
// RECIPE PROVIDERS
// ============================================

class RecipesNotifier extends StateNotifier<List<Recipe>> {
  final String userId;
  
  RecipesNotifier(this.userId) : super([]);
  
  Future<void> addRecipe(Recipe recipe) async {}
  Future<void> updateRecipe(Recipe recipe) async {}
  Future<void> removeRecipe(String id) async {}
}

final recipesProvider = StateNotifierProvider.family<RecipesNotifier, List<Recipe>, String>((ref, userId) {
  return RecipesNotifier(userId);
});
