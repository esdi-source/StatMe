/// Custom Food Product Edit Screen - Für eigene Produkte/Rezepte
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/openfoodfacts_service.dart';
import 'barcode_scanner_screen.dart';

class CustomFoodProductEditScreen extends ConsumerStatefulWidget {
  final CustomFoodProduct? product; // null = neu erstellen
  final String userId;

  const CustomFoodProductEditScreen({
    super.key,
    this.product,
    required this.userId,
  });

  @override
  ConsumerState<CustomFoodProductEditScreen> createState() => _CustomFoodProductEditScreenState();
}

class _CustomFoodProductEditScreenState extends ConsumerState<CustomFoodProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _servingController;
  
  bool _isRecipe = false;
  bool _calculateFromIngredients = false;
  List<CustomFoodIngredient> _ingredients = [];
  bool _isSaving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _kcalController = TextEditingController(text: p?.kcalPer100g.toStringAsFixed(1) ?? '');
    _proteinController = TextEditingController(text: p?.proteinPer100g?.toStringAsFixed(1) ?? '');
    _carbsController = TextEditingController(text: p?.carbsPer100g?.toStringAsFixed(1) ?? '');
    _fatController = TextEditingController(text: p?.fatPer100g?.toStringAsFixed(1) ?? '');
    _servingController = TextEditingController(text: p?.defaultServingGrams?.toStringAsFixed(0) ?? '');
    _isRecipe = p?.isRecipe ?? false;
    _ingredients = List.from(p?.ingredients ?? []);
    _calculateFromIngredients = _ingredients.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  void _recalculateNutrients() {
    if (!_calculateFromIngredients || _ingredients.isEmpty) return;
    
    final totalWeight = _ingredients.fold<double>(0, (sum, i) => sum + i.grams);
    if (totalWeight == 0) return;
    
    final totalKcal = _ingredients.fold<double>(0, (sum, i) => sum + i.calories);
    final totalProtein = _ingredients.fold<double>(0, (sum, i) => sum + i.protein);
    final totalCarbs = _ingredients.fold<double>(0, (sum, i) => sum + i.carbs);
    final totalFat = _ingredients.fold<double>(0, (sum, i) => sum + i.fat);
    
    // Pro 100g berechnen
    setState(() {
      _kcalController.text = ((totalKcal / totalWeight) * 100).toStringAsFixed(1);
      _proteinController.text = ((totalProtein / totalWeight) * 100).toStringAsFixed(1);
      _carbsController.text = ((totalCarbs / totalWeight) * 100).toStringAsFixed(1);
      _fatController.text = ((totalFat / totalWeight) * 100).toStringAsFixed(1);
      _servingController.text = totalWeight.toStringAsFixed(0);
    });
  }

  Future<void> _addIngredient() async {
    final result = await showModalBottomSheet<CustomFoodIngredient>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddIngredientSheet(
        favorites: ref.read(favoriteProductsProvider),
      ),
    );
    
    if (result != null) {
      setState(() {
        _ingredients.add(result);
      });
      _recalculateNutrients();
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
    _recalculateNutrients();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final now = DateTime.now();
      final product = CustomFoodProduct(
        id: widget.product?.id ?? const Uuid().v4(),
        userId: widget.userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        kcalPer100g: double.parse(_kcalController.text.replaceAll(',', '.')),
        proteinPer100g: _proteinController.text.isEmpty 
            ? null 
            : double.parse(_proteinController.text.replaceAll(',', '.')),
        carbsPer100g: _carbsController.text.isEmpty 
            ? null 
            : double.parse(_carbsController.text.replaceAll(',', '.')),
        fatPer100g: _fatController.text.isEmpty 
            ? null 
            : double.parse(_fatController.text.replaceAll(',', '.')),
        defaultServingGrams: _servingController.text.isEmpty 
            ? null 
            : double.parse(_servingController.text.replaceAll(',', '.')),
        ingredients: _ingredients,
        isRecipe: _isRecipe,
        useCount: widget.product?.useCount ?? 0,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      
      if (isEditing) {
        await ref.read(customFoodProductsProvider.notifier).update(product);
      } else {
        await ref.read(customFoodProductsProvider.notifier).add(product);
      }
      
      if (mounted) {
        Navigator.of(context).pop(product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing 
            ? (_isRecipe ? 'Rezept bearbeiten' : 'Produkt bearbeiten')
            : (_isRecipe ? 'Neues Rezept' : 'Neues Produkt')),
        actions: [
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Typ-Auswahl
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        label: 'Produkt',
                        icon: Icons.inventory_2,
                        selected: !_isRecipe,
                        onTap: () => setState(() => _isRecipe = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeChip(
                        label: 'Rezept',
                        icon: Icons.restaurant_menu,
                        selected: _isRecipe,
                        onTap: () => setState(() => _isRecipe = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'z.B. Salatsoße, Overnight Oats',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bitte Namen eingeben' : null,
            ),
            const SizedBox(height: 16),
            
            // Beschreibung
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // Nährwerte berechnen vs. manuell
            if (_isRecipe) ...[
              SwitchListTile(
                title: const Text('Nährwerte aus Zutaten berechnen'),
                subtitle: const Text('Scanne Zutaten und die Kalorien werden automatisch berechnet'),
                value: _calculateFromIngredients,
                onChanged: (v) => setState(() => _calculateFromIngredients = v),
              ),
              const SizedBox(height: 16),
            ],
            
            // Zutaten-Liste (wenn Rezept)
            if (_isRecipe && _calculateFromIngredients) ...[
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Zutaten',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          FilledButton.icon(
                            onPressed: _addIngredient,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Hinzufügen'),
                          ),
                        ],
                      ),
                    ),
                    if (_ingredients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Noch keine Zutaten hinzugefügt'),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ingredients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final ingredient = _ingredients[index];
                          return ListTile(
                            title: Text(ingredient.name),
                            subtitle: Text('${ingredient.grams.toStringAsFixed(0)}g • ${ingredient.calories.toStringAsFixed(0)} kcal'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeIngredient(index),
                            ),
                          );
                        },
                      ),
                    if (_ingredients.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _NutrientSummary(
                              label: 'Gesamt',
                              value: '${_ingredients.fold<double>(0, (s, i) => s + i.grams).toStringAsFixed(0)}g',
                            ),
                            _NutrientSummary(
                              label: 'Kalorien',
                              value: _ingredients.fold<double>(0, (s, i) => s + i.calories).toStringAsFixed(0),
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Nährwerte pro 100g
            Text(
              'Nährwerte pro 100g',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kcalController,
                    decoration: const InputDecoration(
                      labelText: 'Kalorien *',
                      suffixText: 'kcal',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_calculateFromIngredients,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Pflichtfeld';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Ungültig';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_calculateFromIngredients,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Kohlenhydrate',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_calculateFromIngredients,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fett',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_calculateFromIngredients,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Portionsgröße
            TextFormField(
              controller: _servingController,
              decoration: const InputDecoration(
                labelText: 'Standard-Portionsgröße',
                hintText: 'Optional',
                suffixText: 'g',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_calculateFromIngredients,
            ),
            
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          border: Border.all(
            color: selected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _NutrientSummary({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Sheet zum Hinzufügen einer Zutat
class _AddIngredientSheet extends ConsumerStatefulWidget {
  final List<FavoriteProduct> favorites;

  const _AddIngredientSheet({required this.favorites});

  @override
  ConsumerState<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends ConsumerState<_AddIngredientSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController(text: '100');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _kcalController = TextEditingController();
  
  List<OpenFoodFactsProduct> _searchResults = [];
  bool _isSearching = false;
  bool _manualInput = false;
  OpenFoodFactsProduct? _selectedProduct;
  FavoriteProduct? _selectedFavorite;

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    _nameController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() => _isSearching = true);
    
    final service = ref.read(openFoodFactsServiceProvider);
    final results = await service.searchProducts(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
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
    final favorite = widget.favorites.firstWhere(
      (f) => f.barcode == barcode,
      orElse: () => FavoriteProduct(
        id: '', userId: '', name: '', kcalPer100g: 0,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ),
    );
    
    if (favorite.id.isNotEmpty) {
      setState(() {
        _selectedFavorite = favorite;
        _selectedProduct = null;
        _gramsController.text = favorite.defaultGrams?.toStringAsFixed(0) ?? '100';
      });
      return;
    }
    
    // Search OpenFoodFacts
    final product = await ref.read(productByBarcodeProvider(barcode).future);
    
    if (product.found) {
      setState(() {
        _selectedProduct = product;
        _selectedFavorite = null;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produkt mit Barcode $barcode nicht gefunden'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _addIngredient() {
    final grams = double.tryParse(_gramsController.text.replaceAll(',', '.')) ?? 100;
    
    CustomFoodIngredient ingredient;
    
    if (_selectedFavorite != null) {
      ingredient = CustomFoodIngredient(
        productId: _selectedFavorite!.id,
        barcode: _selectedFavorite!.barcode,
        name: _selectedFavorite!.name,
        grams: grams,
        kcalPer100g: _selectedFavorite!.kcalPer100g,
        proteinPer100g: _selectedFavorite!.proteinPer100g,
        carbsPer100g: _selectedFavorite!.carbsPer100g,
        fatPer100g: _selectedFavorite!.fatPer100g,
      );
    } else if (_selectedProduct != null) {
      ingredient = CustomFoodIngredient(
        barcode: _selectedProduct!.barcode,
        name: _selectedProduct!.fullName,
        grams: grams,
        kcalPer100g: _selectedProduct!.calories ?? 0,
        proteinPer100g: _selectedProduct!.proteins,
        carbsPer100g: _selectedProduct!.carbohydrates,
        fatPer100g: _selectedProduct!.fat,
      );
    } else if (_manualInput) {
      final kcal = double.tryParse(_kcalController.text.replaceAll(',', '.')) ?? 0;
      ingredient = CustomFoodIngredient(
        name: _nameController.text.trim(),
        grams: grams,
        kcalPer100g: kcal,
      );
    } else {
      return;
    }
    
    Navigator.of(context).pop(ingredient);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Zutat hinzufügen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Scan/Search/Manual Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scannen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _manualInput = !_manualInput),
                    icon: const Icon(Icons.edit),
                    label: Text(_manualInput ? 'Suche' : 'Manuell'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Selected Product Display
            if (_selectedProduct != null || _selectedFavorite != null)
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(_selectedFavorite?.name ?? _selectedProduct!.fullName),
                  subtitle: Text(
                    '${(_selectedFavorite?.kcalPer100g ?? _selectedProduct!.calories ?? 0).toStringAsFixed(0)} kcal/100g',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectedProduct = null;
                      _selectedFavorite = null;
                    }),
                  ),
                ),
              )
            else if (_manualInput) ...[
              // Manual Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kcalController,
                decoration: const InputDecoration(
                  labelText: 'Kalorien pro 100g',
                  suffixText: 'kcal',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              // Search
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Produkt suchen',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _search,
              ),
              const SizedBox(height: 8),
              
              // Favorites
              if (widget.favorites.isNotEmpty && _searchController.text.isEmpty) ...[
                Text(
                  'Favoriten',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.favorites.length,
                    itemBuilder: (context, index) {
                      final fav = widget.favorites[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(fav.name),
                          onPressed: () => setState(() {
                            _selectedFavorite = fav;
                            _gramsController.text = fav.defaultGrams?.toStringAsFixed(0) ?? '100';
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              // Search Results
              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final product = _searchResults[index];
                      return ListTile(
                        title: Text(product.productName ?? 'Unbekannt'),
                        subtitle: Text(
                          '${product.calories?.toStringAsFixed(0) ?? '?'} kcal/100g',
                        ),
                        onTap: () => setState(() => _selectedProduct = product),
                      );
                    },
                  ),
                ),
            ],
            
            const Spacer(),
            
            // Grams Input & Add Button
            if (_selectedProduct != null || _selectedFavorite != null || _manualInput)
              Column(
                children: [
                  TextFormField(
                    controller: _gramsController,
                    decoration: const InputDecoration(
                      labelText: 'Menge',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _addIngredient,
                      child: const Text('Zutat hinzufügen'),
                    ),
                  ),
                ],
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
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Barcode eingeben'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Barcode',
          hintText: 'z.B. 4000417025005',
        ),
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Suchen'),
        ),
      ],
    );
  }
}
