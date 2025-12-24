/// Food Log Edit Screen - Add food entries with product search
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class FoodLogEditScreen extends ConsumerStatefulWidget {
  final String userId;
  final DateTime date;
  final FoodLogModel? log;

  const FoodLogEditScreen({
    super.key,
    required this.userId,
    required this.date,
    this.log,
  });

  @override
  ConsumerState<FoodLogEditScreen> createState() => _FoodLogEditScreenState();
}

class _FoodLogEditScreenState extends ConsumerState<FoodLogEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController();
  
  ProductModel? _selectedProduct;
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  double _calculatedCalories = 0;

  @override
  void initState() {
    super.initState();
    if (widget.log != null) {
      _searchController.text = widget.log!.productName;
      _gramsController.text = widget.log!.grams.toString();
      _calculatedCalories = widget.log!.calories;
    }
    _gramsController.addListener(_calculateCalories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  void _calculateCalories() {
    if (_selectedProduct != null && _gramsController.text.isNotEmpty) {
      final grams = double.tryParse(_gramsController.text) ?? 0;
      setState(() {
        _calculatedCalories = _selectedProduct!.calculateCalories(grams);
      });
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final repo = ref.read(foodRepositoryProvider);
      final results = await repo.searchProducts(query);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suche fehlgeschlagen: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      _searchController.text = product.productName;
      _searchResults = [];
    });
    _calculateCalories();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final grams = double.tryParse(_gramsController.text) ?? 0;
      final calories = _selectedProduct != null
          ? _selectedProduct!.calculateCalories(grams)
          : _calculatedCalories;

      final log = FoodLogModel(
        id: widget.log?.id ?? const Uuid().v4(),
        userId: widget.userId,
        productId: _selectedProduct?.id,
        productName: _searchController.text.trim(),
        grams: grams,
        calories: calories,
        date: widget.date,
        createdAt: widget.log?.createdAt ?? DateTime.now(),
      );

      await ref.read(foodLogNotifierProvider.notifier).add(log);

      if (mounted) {
        Navigator.of(context).pop(log);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log != null ? 'Eintrag bearbeiten' : 'Essen hinzufügen'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Search
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Produkt suchen',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _searchProducts(value);
                  } else {
                    setState(() => _searchResults = []);
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Produkt eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Search Results
              if (_searchResults.isNotEmpty)
                Card(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(Icons.restaurant_menu, size: 20),
                          ),
                          title: Text(product.productName),
                          subtitle: Text('${product.kcalPer100g.toStringAsFixed(0)} kcal/100g'),
                          onTap: () => _selectProduct(product),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Selected Product Info
              if (_selectedProduct != null)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProduct!.productName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _NutritionRow(
                          label: 'Kalorien',
                          value: '${_selectedProduct!.kcalPer100g.toStringAsFixed(0)} kcal',
                        ),
                        if (_selectedProduct!.proteinPer100g != null)
                          _NutritionRow(
                            label: 'Protein',
                            value: '${_selectedProduct!.proteinPer100g!.toStringAsFixed(1)}g',
                          ),
                        if (_selectedProduct!.carbsPer100g != null)
                          _NutritionRow(
                            label: 'Kohlenhydrate',
                            value: '${_selectedProduct!.carbsPer100g!.toStringAsFixed(1)}g',
                          ),
                        if (_selectedProduct!.fatPer100g != null)
                          _NutritionRow(
                            label: 'Fett',
                            value: '${_selectedProduct!.fatPer100g!.toStringAsFixed(1)}g',
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Grams Input
              TextFormField(
                controller: _gramsController,
                decoration: const InputDecoration(
                  labelText: 'Menge (Gramm)',
                  prefixIcon: Icon(Icons.scale),
                  suffixText: 'g',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Menge eingeben';
                  }
                  final grams = double.tryParse(value);
                  if (grams == null || grams <= 0) {
                    return 'Bitte gültige Menge eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Quick Gram Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [50, 100, 150, 200, 250, 300].map((g) {
                  return ActionChip(
                    label: Text('${g}g'),
                    onPressed: () {
                      _gramsController.text = g.toString();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Calculated Calories
              if (_calculatedCalories > 0)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department, 
                            color: Colors.orange, size: 48),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_calculatedCalories.toStringAsFixed(0)} kcal',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                            ),
                            const Text('Berechnete Kalorien'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
