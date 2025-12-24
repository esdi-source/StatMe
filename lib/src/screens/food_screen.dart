/// Food Screen - Calorie tracking with favorites and custom products
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/openfoodfacts_service.dart';
import 'food_log_edit_screen.dart';
import 'barcode_scanner_screen.dart';
import 'custom_food_product_edit_screen.dart';

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadFoodLogs();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodLogs() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(foodLogNotifierProvider.notifier).load(user.id, _selectedDate);
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadFoodLogs();
  }
  
  Future<void> _scanBarcode() async {
    String? barcode;
    
    if (kIsWeb) {
      try {
        barcode = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
        );
      } catch (e) {
        barcode = await showDialog<String>(
          context: context,
          builder: (_) => _BarcodeInputDialog(),
        );
      }
    } else {
      barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );
    }
    
    if (barcode == null || barcode.isEmpty) return;
    
    // Check favorites first
    final favorites = ref.read(favoriteProductsProvider);
    final favorite = favorites.where((f) => f.barcode == barcode).firstOrNull;
    
    if (favorite != null) {
      _showFavoriteProductDialog(favorite);
      return;
    }
    
    // Fetch from OpenFoodFacts
    final product = await ref.read(productByBarcodeProvider(barcode).future);
    
    if (!mounted) return;
    
    if (product.found) {
      _showProductDialog(product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produkt mit Barcode $barcode nicht gefunden'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  void _showProductDialog(OpenFoodFactsProduct product) {
    showDialog(
      context: context,
      builder: (_) => _ProductDetailDialog(
        product: product,
        onAdd: (grams) => _addProductFromOpenFoodFacts(product, grams),
        onFavorite: () => _addToFavorites(product),
      ),
    );
  }
  
  void _showFavoriteProductDialog(FavoriteProduct favorite) {
    showDialog(
      context: context,
      builder: (_) => _FavoriteProductDialog(
        product: favorite,
        onAdd: (grams) => _addFromFavorite(favorite, grams),
      ),
    );
  }
  
  Future<void> _addToFavorites(OpenFoodFactsProduct product) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final favorite = FavoriteProduct(
      id: const Uuid().v4(),
      userId: user.id,
      name: product.fullName,
      kcalPer100g: product.calories ?? 0,
      proteinPer100g: product.proteins,
      carbsPer100g: product.carbohydrates,
      fatPer100g: product.fat,
      barcode: product.barcode,
      imageUrl: product.imageUrl,
      defaultGrams: 100,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await ref.read(favoriteProductsProvider.notifier).add(favorite);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.productName} zu Favoriten hinzugefügt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _addProductFromOpenFoodFacts(OpenFoodFactsProduct product, double grams) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final calories = (product.calories ?? 0) * grams / 100;
    
    final foodLog = FoodLogModel(
      id: const Uuid().v4(),
      userId: user.id,
      productName: product.fullName,
      calories: calories,
      grams: grams,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );
    
    try {
      await ref.read(foodLogNotifierProvider.notifier).add(foodLog);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.productName} hinzugefügt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _addFromFavorite(FavoriteProduct favorite, double grams) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final calories = favorite.calculateCalories(grams);
    
    final foodLog = FoodLogModel(
      id: const Uuid().v4(),
      userId: user.id,
      productName: favorite.name,
      calories: calories,
      grams: grams,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );
    
    try {
      await ref.read(foodLogNotifierProvider.notifier).add(foodLog);
      await ref.read(favoriteProductsProvider.notifier).incrementUseCount(favorite.id);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${favorite.name} hinzugefügt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _addFromCustomProduct(CustomFoodProduct product, double grams) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final calories = product.calculateCalories(grams);
    
    final foodLog = FoodLogModel(
      id: const Uuid().v4(),
      userId: user.id,
      productName: product.name,
      calories: calories,
      grams: grams,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );
    
    try {
      await ref.read(foodLogNotifierProvider.notifier).add(foodLog);
      await ref.read(customFoodProductsProvider.notifier).incrementUseCount(product.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} hinzugefügt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodLogs = ref.watch(foodLogNotifierProvider);
    final totalCalories = foodLogs.fold<double>(0, (sum, log) => sum + log.calories);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ernährung'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Heute'),
            Tab(icon: Icon(Icons.star), text: 'Favoriten'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Eigene'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(foodLogs, totalCalories),
          _FavoritesTab(
            onAddToLog: _addFromFavorite,
            onScan: _scanBarcode,
          ),
          _CustomProductsTab(
            onAddToLog: _addFromCustomProduct,
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }
  
  Widget? _buildFAB() {
    if (_tabController.index == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: _scanBarcode,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'search',
            onPressed: _showSearchDialog,
            child: const Icon(Icons.search),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: _openFoodLogEdit,
            icon: const Icon(Icons.add),
            label: const Text('Hinzufügen'),
          ),
        ],
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _scanBarcode,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Favorit scannen'),
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: () => _openCustomProductEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Neues Rezept'),
      );
    }
  }
  
  Widget _buildTodayTab(List<FoodLogModel> foodLogs, double totalCalories) {
    return Column(
      children: [
        // Date Selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeDate(-1),
              ),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                    _loadFoodLogs();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isToday(_selectedDate)
                        ? 'Heute'
                        : DateFormat('dd.MM.yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isToday(_selectedDate) ? null : () => _changeDate(1),
              ),
            ],
          ),
        ),

        // Calorie Summary
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      totalCalories.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Text('Gegessen'),
                  ],
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      '2000',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Text('Ziel'),
                  ],
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      (2000 - totalCalories).toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: totalCalories > 2000 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Text('Übrig'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (totalCalories / 2000).clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  totalCalories > 2000 ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${((totalCalories / 2000) * 100).toStringAsFixed(0)}% des Tagesziels',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Food Logs List
        Expanded(
          child: foodLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Einträge für diesen Tag',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFoodLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: foodLogs.length,
                    itemBuilder: (context, index) {
                      final log = foodLogs[index];
                      return _FoodLogCard(
                        log: log,
                        onDelete: () => _deleteLog(log),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => _ProductSearchDialog(
        onProductSelected: _showProductDialog,
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _openFoodLogEdit() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final result = await Navigator.of(context).push<FoodLogModel>(
      MaterialPageRoute(
        builder: (_) => FoodLogEditScreen(userId: user.id, date: _selectedDate),
      ),
    );

    if (result != null) {
      _loadFoodLogs();
    }
  }
  
  void _openCustomProductEdit() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomFoodProductEditScreen(userId: user.id),
      ),
    );
  }

  Future<void> _deleteLog(FoodLogModel log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eintrag löschen'),
        content: Text('Möchtest du "${log.productName}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(foodLogNotifierProvider.notifier).delete(log.id);
    }
  }
}

// ============================================================================
// FAVORITES TAB
// ============================================================================

class _FavoritesTab extends ConsumerWidget {
  final Function(FavoriteProduct, double) onAddToLog;
  final VoidCallback onScan;

  const _FavoritesTab({required this.onAddToLog, required this.onScan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProductsProvider);

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Keine Favoriten'),
            const SizedBox(height: 8),
            Text(
              'Scanne Produkte und speichere sie als Favoriten',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Produkt scannen'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _FavoriteProductCard(
          product: favorite,
          onTap: () => _showAddDialog(context, favorite),
          onDelete: () => _deleteFavorite(context, ref, favorite),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, FavoriteProduct product) {
    showDialog(
      context: context,
      builder: (_) => _FavoriteProductDialog(
        product: product,
        onAdd: (grams) => onAddToLog(product, grams),
      ),
    );
  }

  Future<void> _deleteFavorite(BuildContext context, WidgetRef ref, FavoriteProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Favorit entfernen'),
        content: Text('Möchtest du "${product.name}" aus den Favoriten entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(favoriteProductsProvider.notifier).remove(product.id);
    }
  }
}

class _FavoriteProductCard extends StatelessWidget {
  final FavoriteProduct product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FavoriteProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.shade100,
          child: const Icon(Icons.star, color: Colors.amber),
        ),
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${product.kcalPer100g.toStringAsFixed(0)} kcal/100g • ${product.useCount}x verwendet'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onTap,
              color: Colors.green,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.red.shade300,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// CUSTOM PRODUCTS TAB
// ============================================================================

class _CustomProductsTab extends ConsumerWidget {
  final Function(CustomFoodProduct, double) onAddToLog;

  const _CustomProductsTab({required this.onAddToLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(customFoodProductsProvider);
    final recipes = products.where((p) => p.isRecipe).toList();
    final simpleProducts = products.where((p) => !p.isRecipe).toList();

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Keine eigenen Produkte'),
            const SizedBox(height: 8),
            Text(
              'Erstelle Rezepte oder eigene Produkte wie Salatsoße',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openCustomProductEdit(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Neues Rezept erstellen'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recipes.isNotEmpty) ...[
          Text(
            'Rezepte',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...recipes.map((p) => _CustomProductCard(
                product: p,
                onTap: () => _showAddDialog(context, p),
                onEdit: () => _editProduct(context, ref, p),
                onDelete: () => _deleteProduct(context, ref, p),
              )),
          const SizedBox(height: 16),
        ],
        if (simpleProducts.isNotEmpty) ...[
          Text(
            'Eigene Produkte',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...simpleProducts.map((p) => _CustomProductCard(
                product: p,
                onTap: () => _showAddDialog(context, p),
                onEdit: () => _editProduct(context, ref, p),
                onDelete: () => _deleteProduct(context, ref, p),
              )),
        ],
      ],
    );
  }

  void _showAddDialog(BuildContext context, CustomFoodProduct product) {
    showDialog(
      context: context,
      builder: (_) => _CustomProductDialog(
        product: product,
        onAdd: (grams) {
          onAddToLog(product, grams);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openCustomProductEdit(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomFoodProductEditScreen(userId: user.id),
      ),
    );
  }

  void _editProduct(BuildContext context, WidgetRef ref, CustomFoodProduct product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomFoodProductEditScreen(
          product: product,
          userId: product.userId,
        ),
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, CustomFoodProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Produkt löschen'),
        content: Text('Möchtest du "${product.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(customFoodProductsProvider.notifier).remove(product.id);
    }
  }
}

class _CustomProductCard extends StatelessWidget {
  final CustomFoodProduct product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: product.isRecipe ? Colors.green.shade100 : Colors.blue.shade100,
                child: Icon(
                  product.isRecipe ? Icons.restaurant_menu : Icons.inventory_2,
                  color: product.isRecipe ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${product.kcalPer100g.toStringAsFixed(0)} kcal/100g',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (product.ingredients.isNotEmpty) ...[
                          const Text(' • '),
                          Icon(Icons.list, size: 14, color: Colors.grey.shade600),
                          Text(
                            ' ${product.ingredients.length}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                        if (product.useCount > 0) ...[
                          const Text(' • '),
                          Text(
                            '${product.useCount}×',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Quick add button
              FilledButton.tonal(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Hinzufügen'),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                  const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DIALOGS
// ============================================================================

class _FoodLogCard extends StatelessWidget {
  final FoodLogModel log;
  final VoidCallback onDelete;

  const _FoodLogCard({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.restaurant, color: Colors.orange),
        ),
        title: Text(log.productName),
        subtitle: Text('${log.grams.toStringAsFixed(0)}g'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${log.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.red.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeInputDialog extends StatefulWidget {
  @override
  State<_BarcodeInputDialog> createState() => _BarcodeInputDialogState();
}

class _BarcodeInputDialogState extends State<_BarcodeInputDialog> {
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Barcode eingeben'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Barcode (EAN/UPC)',
          hintText: 'z.B. 4006381333931',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Suchen'),
        ),
      ],
    );
  }
}

class _ProductDetailDialog extends StatefulWidget {
  final OpenFoodFactsProduct product;
  final Function(double grams) onAdd;
  final VoidCallback onFavorite;
  
  const _ProductDetailDialog({
    required this.product,
    required this.onAdd,
    required this.onFavorite,
  });
  
  @override
  State<_ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<_ProductDetailDialog> {
  final _gramsController = TextEditingController(text: '100');
  
  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }
  
  double get _grams => double.tryParse(_gramsController.text) ?? 100;
  double get _calculatedCalories => (widget.product.calories ?? 0) * _grams / 100;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.productName ?? 'Produkt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product.brand != null)
              Text(widget.product.brand!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            
            // Nährwerte pro 100g
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nährwerte pro 100g', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildNutrientRow('Kalorien', '${widget.product.calories?.toStringAsFixed(0) ?? '-'} kcal'),
                    _buildNutrientRow('Protein', '${widget.product.proteins?.toStringAsFixed(1) ?? '-'} g'),
                    _buildNutrientRow('Kohlenhydrate', '${widget.product.carbohydrates?.toStringAsFixed(1) ?? '-'} g'),
                    _buildNutrientRow('Fett', '${widget.product.fat?.toStringAsFixed(1) ?? '-'} g'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Menge eingeben
            TextField(
              controller: _gramsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Menge (g)',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            
            // Berechnete Kalorien
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kalorien:'),
                  Text(
                    '${_calculatedCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            widget.onFavorite();
          },
          icon: const Icon(Icons.star_border),
          label: const Text('Favorit'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: () => widget.onAdd(_grams),
          icon: const Icon(Icons.add),
          label: const Text('Hinzufügen'),
        ),
      ],
    );
  }
  
  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FavoriteProductDialog extends StatefulWidget {
  final FavoriteProduct product;
  final Function(double grams) onAdd;
  
  const _FavoriteProductDialog({required this.product, required this.onAdd});
  
  @override
  State<_FavoriteProductDialog> createState() => _FavoriteProductDialogState();
}

class _FavoriteProductDialogState extends State<_FavoriteProductDialog> {
  late final TextEditingController _gramsController;
  
  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(
      text: widget.product.defaultGrams?.toStringAsFixed(0) ?? '100',
    );
  }
  
  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }
  
  double get _grams => double.tryParse(_gramsController.text) ?? 100;
  double get _calculatedCalories => widget.product.calculateCalories(_grams);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.product.kcalPer100g.toStringAsFixed(0)} kcal/100g'),
          const SizedBox(height: 16),
          TextField(
            controller: _gramsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Menge (g)',
              border: OutlineInputBorder(),
              suffixText: 'g',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kalorien:'),
                Text(
                  '${_calculatedCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: () => widget.onAdd(_grams),
          icon: const Icon(Icons.add),
          label: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}

class _CustomProductDialog extends StatefulWidget {
  final CustomFoodProduct product;
  final Function(double grams) onAdd;
  
  const _CustomProductDialog({required this.product, required this.onAdd});
  
  @override
  State<_CustomProductDialog> createState() => _CustomProductDialogState();
}

class _CustomProductDialogState extends State<_CustomProductDialog> {
  late final TextEditingController _gramsController;
  
  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(
      text: widget.product.defaultServingGrams?.toStringAsFixed(0) ?? '100',
    );
  }
  
  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }
  
  double get _grams => double.tryParse(_gramsController.text) ?? 100;
  double get _calculatedCalories => widget.product.calculateCalories(_grams);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.product.isRecipe ? Icons.restaurant_menu : Icons.inventory_2,
            color: widget.product.isRecipe ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.product.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.product.description!,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            Text('${widget.product.kcalPer100g.toStringAsFixed(0)} kcal/100g'),
            
            // Zutaten anzeigen
            if (widget.product.ingredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  '${widget.product.ingredients.length} Zutaten',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                children: widget.product.ingredients.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(i.name, style: const TextStyle(fontSize: 13))),
                      Text('${i.grams.toStringAsFixed(0)}g', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                )).toList(),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Schnellauswahl-Buttons
            if (widget.product.defaultServingGrams != null) ...[
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text('1 Portion (${widget.product.defaultServingGrams!.toStringAsFixed(0)}g)'),
                    onPressed: () => setState(() {
                      _gramsController.text = widget.product.defaultServingGrams!.toStringAsFixed(0);
                    }),
                  ),
                  ActionChip(
                    label: const Text('½ Portion'),
                    onPressed: () => setState(() {
                      _gramsController.text = (widget.product.defaultServingGrams! / 2).toStringAsFixed(0);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            TextField(
              controller: _gramsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Menge (g)',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kalorien:'),
                  Text(
                    '${_calculatedCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: () => widget.onAdd(_grams),
          icon: const Icon(Icons.add),
          label: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}

class _ProductSearchDialog extends ConsumerStatefulWidget {
  final Function(OpenFoodFactsProduct) onProductSelected;
  
  const _ProductSearchDialog({required this.onProductSelected});
  
  @override
  ConsumerState<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends ConsumerState<_ProductSearchDialog> {
  final _searchController = TextEditingController();
  List<OpenFoodFactsProduct> _results = [];
  bool _isLoading = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _search() async {
    if (_searchController.text.length < 2) return;
    
    setState(() => _isLoading = true);
    
    final service = ref.read(openFoodFactsServiceProvider);
    final results = await service.searchProducts(_searchController.text);
    
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Produkt suchen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Produktname eingeben...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty ? 'Gib einen Suchbegriff ein' : 'Keine Ergebnisse',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final product = _results[index];
                        return ListTile(
                          title: Text(product.productName ?? 'Unbekannt'),
                          subtitle: Text('${product.brand ?? ''} • ${product.calories?.toStringAsFixed(0) ?? '-'} kcal/100g'),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onProductSelected(product);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}
