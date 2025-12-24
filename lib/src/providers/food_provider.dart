import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/openfoodfacts_service.dart';
import 'auth_provider.dart'; // For authNotifierProvider
import 'provider_utils.dart';

// ============================================
// FOOD PROVIDERS
// ============================================

/// Food Repository Provider
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoFoodRepository();
  }
  return SupabaseFoodRepository(Supabase.instance.client);
});

/// OpenFoodFacts Service Provider
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoOpenFoodFactsService();
  }
  return OpenFoodFactsService();
});

/// Provider für Produkt-Suche per Barcode
final productByBarcodeProvider = FutureProvider.family<OpenFoodFactsProduct, String>((ref, barcode) async {
  final service = ref.watch(openFoodFactsServiceProvider);
  return service.getProductByBarcode(barcode);
});

/// Provider für Produkt-Suche per Name
final productSearchProvider = FutureProvider.family<List<OpenFoodFactsProduct>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.watch(openFoodFactsServiceProvider);
  return service.searchProducts(query);
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final foodLogsProvider = FutureProvider.family<List<FoodLogModel>, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(foodRepositoryProvider);
  return await repo.getFoodLogs(params.userId, params.date);
});

final localProductSearchProvider = FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(foodRepositoryProvider);
  return await repo.searchProducts(query);
});

class FoodLogNotifier extends StateNotifier<List<FoodLogModel>> {
  final FoodRepository _repository;
  
  FoodLogNotifier(this._repository) : super([]);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getFoodLogs(userId, date);
  }
  
  Future<void> add(FoodLogModel log) async {
    final added = await _repository.addFoodLog(log);
    state = [...state, added];
    // Event logging is handled in repository or here? 
    // The original code didn't have it here, but we should add it!
    await logWidgetEvent('calories', 'log_added', {
      'id': added.id,
      'calories': added.calories,
      'product': added.productName,
    });
  }
  
  Future<void> delete(String logId) async {
    await _repository.deleteFoodLog(logId);
    state = state.where((f) => f.id != logId).toList();
    await logWidgetEvent('calories', 'log_deleted', {'id': logId});
  }
  
  double get totalCalories => state.fold(0, (sum, log) => sum + log.calories);
}

final foodLogNotifierProvider = StateNotifierProvider<FoodLogNotifier, List<FoodLogModel>>((ref) {
  return FoodLogNotifier(ref.watch(foodRepositoryProvider));
});

// ============================================
// FOOD FAVORITES PROVIDER
// ============================================

class FavoriteProductsNotifier extends StateNotifier<List<FavoriteProduct>> {
  final String _userId;
  final SupabaseClient? _client;
  
  FavoriteProductsNotifier(this._userId, this._client) : super([]);
  
  Future<void> load() async {
    if (_client == null || _userId == 'demo') {
      state = [];
      return;
    }
    
    try {
      final response = await _client
          .from('favorite_products')
          .select()
          .eq('user_id', _userId)
          .order('use_count', ascending: false);
      
      state = (response as List).map((json) => FavoriteProduct.fromJson(json)).toList();
    } catch (e) {
      print('Error loading favorite products: $e');
    }
  }
  
  Future<FavoriteProduct> add(FavoriteProduct product) async {
    if (_client == null || _userId == 'demo') {
      state = [...state, product];
      return product;
    }
    
    try {
      final response = await _client
          .from('favorite_products')
          .insert(product.toJson())
          .select()
          .single();
      
      final added = FavoriteProduct.fromJson(response);
      state = [...state, added];
      
      await logWidgetEvent(
        'food',
        'favorite_added',
        {'id': added.id, 'name': added.name},
      );
      
      return added;
    } catch (e) {
      print('Error adding favorite product: $e');
      return product;
    }
  }
  
  Future<void> remove(String productId) async {
    state = state.where((p) => p.id != productId).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client.from('favorite_products').delete().eq('id', productId);
        await logWidgetEvent(
          'food',
          'favorite_removed',
          {'id': productId},
        );
      } catch (e) {
        print('Error removing favorite product: $e');
      }
    }
  }
  
  Future<void> incrementUseCount(String productId) async {
    state = state.map((p) => 
      p.id == productId ? p.copyWith(useCount: p.useCount + 1) : p
    ).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client.rpc('increment_food_use_count', params: {
          'table_name': 'favorite_products',
          'product_id': productId,
        });
      } catch (e) {
        print('Error incrementing use count: $e');
      }
    }
  }
  
  FavoriteProduct? findByBarcode(String barcode) {
    try {
      return state.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      return null;
    }
  }
}

final favoriteProductsProvider = StateNotifierProvider<FavoriteProductsNotifier, List<FavoriteProduct>>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  final userId = user?.id ?? 'demo';
  final client = AppConfig.isDemoMode ? null : Supabase.instance.client;
  
  final notifier = FavoriteProductsNotifier(userId, client);
  if (user != null) {
    notifier.load();
  }
  return notifier;
});

// ============================================
// CUSTOM FOOD PRODUCTS PROVIDER
// ============================================

class CustomFoodProductsNotifier extends StateNotifier<List<CustomFoodProduct>> {
  final String _userId;
  final SupabaseClient? _client;
  
  CustomFoodProductsNotifier(this._userId, this._client) : super([]);
  
  Future<void> load() async {
    if (_client == null || _userId == 'demo') {
      state = [];
      return;
    }
    
    try {
      final response = await _client
          .from('custom_food_products')
          .select()
          .eq('user_id', _userId)
          .order('use_count', ascending: false);
      
      state = (response as List).map((json) => CustomFoodProduct.fromJson(json)).toList();
    } catch (e) {
      print('Error loading custom food products: $e');
    }
  }
  
  Future<CustomFoodProduct> add(CustomFoodProduct product) async {
    if (_client == null || _userId == 'demo') {
      state = [...state, product];
      return product;
    }
    
    try {
      final response = await _client
          .from('custom_food_products')
          .insert(product.toJson())
          .select()
          .single();
      
      final added = CustomFoodProduct.fromJson(response);
      state = [...state, added];
      
      await logWidgetEvent(
        'food',
        product.isRecipe ? 'recipe_created' : 'custom_product_created',
        {'id': added.id, 'name': added.name, 'kcal_per_100g': added.kcalPer100g},
      );
      
      return added;
    } catch (e) {
      print('Error adding custom food product: $e');
      return product;
    }
  }
  
  Future<void> update(CustomFoodProduct product) async {
    state = state.map((p) => p.id == product.id ? product : p).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client
            .from('custom_food_products')
            .update(product.toJson())
            .eq('id', product.id);
        
        await logWidgetEvent(
          'food',
          'custom_product_updated',
          {'id': product.id, 'name': product.name},
        );
      } catch (e) {
        print('Error updating custom food product: $e');
      }
    }
  }
  
  Future<void> remove(String productId) async {
    state = state.where((p) => p.id != productId).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client.from('custom_food_products').delete().eq('id', productId);
        await logWidgetEvent(
          'food',
          'custom_product_deleted',
          {'id': productId},
        );
      } catch (e) {
        print('Error removing custom food product: $e');
      }
    }
  }
  
  Future<void> incrementUseCount(String productId) async {
    state = state.map((p) => 
      p.id == productId ? p.copyWith(useCount: p.useCount + 1) : p
    ).toList();
    
    if (_client != null && _userId != 'demo') {
      try {
        await _client.rpc('increment_food_use_count', params: {
          'table_name': 'custom_food_products',
          'product_id': productId,
        });
      } catch (e) {
        print('Error incrementing use count: $e');
      }
    }
  }
  
  List<CustomFoodProduct> get recipes => state.where((p) => p.isRecipe).toList();
  List<CustomFoodProduct> get simpleProducts => state.where((p) => !p.isRecipe).toList();
}

final customFoodProductsProvider = StateNotifierProvider<CustomFoodProductsNotifier, List<CustomFoodProduct>>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  final userId = user?.id ?? 'demo';
  final client = AppConfig.isDemoMode ? null : Supabase.instance.client;
  
  final notifier = CustomFoodProductsNotifier(userId, client);
  if (user != null) {
    notifier.load();
  }
  return notifier;
});
