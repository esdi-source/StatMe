/// Food Screen - Calorie tracking

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/openfoodfacts_service.dart';
import 'food_log_edit_screen.dart';
import 'barcode_scanner_screen.dart';

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  List<OpenFoodFactsProduct> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFoodLogs();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
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
  
  Future<void> _searchProducts(String query) async {
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
    
    // Auf Web: Versuche erst die Kamera, Fallback auf manuelle Eingabe
    if (kIsWeb) {
      // Auf mobilen Browsern (PWA) die Kamera verwenden
      try {
        barcode = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => const BarcodeScannerScreen(),
          ),
        );
      } catch (e) {
        // Falls Kamera nicht funktioniert, manueller Input
        barcode = await showDialog<String>(
          context: context,
          builder: (context) => _BarcodeInputDialog(),
        );
      }
    } else {
      // Native Apps: Direkt Kamera verwenden
      barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
    }
    
    if (barcode == null || barcode.isEmpty) return;
    
    // Produkt abrufen
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
      builder: (context) => _ProductDetailDialog(
        product: product,
        onAdd: (grams) => _addProductFromOpenFoodFacts(product, grams),
      ),
    );
  }
  
  Future<void> _addProductFromOpenFoodFacts(OpenFoodFactsProduct product, double grams) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    // Kalorien berechnen (pro 100g)
    final calories = (product.calories ?? 0) * grams / 100;
    
    final foodLog = FoodLogModel(
      id: '',
      userId: user.id,
      productName: product.fullName,
      calories: calories,
      grams: grams,
      date: _selectedDate,
      createdAt: DateTime.now(),
    );
    
    await ref.read(foodLogNotifierProvider.notifier).add(foodLog);
    
    if (mounted) {
      Navigator.of(context).pop(); // Dialog schließen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.productName} hinzugefügt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final foodLogs = ref.watch(foodLogNotifierProvider);
    final totalCalories = foodLogs.fold<double>(0, (sum, log) => sum + log.calories);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ernährung'),
      ),
      body: Column(
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
                        '${totalCalories.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Text('Gegessen'),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey.shade300,
                  ),
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
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey.shade300,
                  ),
                  Column(
                    children: [
                      Text(
                        '${(2000 - totalCalories).toStringAsFixed(0)}',
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
      ),
      floatingActionButton: Column(
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
            onPressed: () => _showSearchDialog(),
            child: const Icon(Icons.search),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _openFoodLogEdit(),
            icon: const Icon(Icons.add),
            label: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProductSearchDialog(
        onProductSelected: (product) => _showProductDialog(product),
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

  Future<void> _deleteLog(FoodLogModel log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

/// Dialog für manuelle Barcode-Eingabe
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
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Barcode scannen'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Im Web-Modus: Barcode manuell eingeben',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Barcode (EAN/UPC)',
              hintText: 'z.B. 4006381333931',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Text(
            'Demo-Barcodes: 4006381333931 (Haferflocken), 4000400144690 (Milch), 7622210449283 (Schokolade)',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Suchen'),
        ),
      ],
    );
  }
  
  void _submit() {
    if (_controller.text.isNotEmpty) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }
}

/// Dialog für Produktdetails
class _ProductDetailDialog extends StatefulWidget {
  final OpenFoodFactsProduct product;
  final Function(double grams) onAdd;
  
  const _ProductDetailDialog({required this.product, required this.onAdd});
  
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
              Text(
                widget.product.brand!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            const SizedBox(height: 16),
            
            // Nutri-Score
            if (widget.product.nutriscore != null)
              _buildNutriScore(widget.product.nutriscore!),
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
                    _buildNutrientRow('Fett', '${widget.product.fat?.toStringAsFixed(1) ?? '-'} g'),
                    _buildNutrientRow('Kohlenhydrate', '${widget.product.carbohydrates?.toStringAsFixed(1) ?? '-'} g'),
                    _buildNutrientRow('davon Zucker', '${widget.product.sugars?.toStringAsFixed(1) ?? '-'} g'),
                    _buildNutrientRow('Protein', '${widget.product.proteins?.toStringAsFixed(1) ?? '-'} g'),
                    _buildNutrientRow('Ballaststoffe', '${widget.product.fiber?.toStringAsFixed(1) ?? '-'} g'),
                    _buildNutrientRow('Salz', '${widget.product.salt?.toStringAsFixed(2) ?? '-'} g'),
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
  
  Widget _buildNutriScore(String score) {
    final colors = {
      'a': Colors.green,
      'b': Colors.lightGreen,
      'c': Colors.yellow.shade700,
      'd': Colors.orange,
      'e': Colors.red,
    };
    
    return Row(
      children: ['a', 'b', 'c', 'd', 'e'].map((s) {
        final isActive = s == score.toLowerCase();
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? colors[s] : colors[s]?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              s.toUpperCase(),
              style: TextStyle(
                color: isActive ? Colors.white : colors[s],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Dialog für Produktsuche
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
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                      ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Gib einen Suchbegriff ein'
                            : 'Keine Ergebnisse',
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
                          subtitle: Text(
                            '${product.brand ?? ''} • ${product.calories?.toStringAsFixed(0) ?? '-'} kcal/100g',
                          ),
                          trailing: product.nutriscore != null
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _nutriScoreColor(product.nutriscore!),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.nutriscore!.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
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
  
  Color _nutriScoreColor(String score) {
    switch (score.toLowerCase()) {
      case 'a': return Colors.green;
      case 'b': return Colors.lightGreen;
      case 'c': return Colors.yellow.shade700;
      case 'd': return Colors.orange;
      case 'e': return Colors.red;
      default: return Colors.grey;
    }
  }
}
