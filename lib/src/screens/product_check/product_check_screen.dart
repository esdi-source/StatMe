import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
import '../../models/product_check_model.dart';
import '../../services/product_check_service.dart';
import '../../providers/providers.dart';
import '../barcode_scanner_screen.dart';

class ProductCheckScreen extends ConsumerStatefulWidget {
  const ProductCheckScreen({super.key});

  @override
  ConsumerState<ProductCheckScreen> createState() => _ProductCheckScreenState();
}

class _ProductCheckScreenState extends ConsumerState<ProductCheckScreen> {
  final _service = ProductCheckService();
  List<ProductCheckResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _service.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode != null && mounted) {
      _fetchProduct(barcode);
    }
  }

  Future<void> _fetchProduct(String barcode) async {
    setState(() => _isLoading = true);
    
    final product = await _service.fetchProduct(barcode);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (product != null) {
        await _loadHistory(); // Reload to show new item at top
        _showProductDetails(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produkt nicht gefunden')),
        );
      }
    }
  }

  void _showProductDetails(ProductCheckResult product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ProductDetailSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkt-Check'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _service.clearHistory();
              _loadHistory();
            },
            tooltip: 'Verlauf löschen',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState(tokens)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final product = _history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: product.imageUrl != null
                            ? Image.network(product.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                            : const Icon(Icons.shopping_bag),
                        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(product.brand ?? 'Unbekannte Marke'),
                        trailing: _buildScoreBadge(product),
                        onTap: () => _showProductDetails(product),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcode,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scannen'),
        backgroundColor: tokens.primary,
      ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 80, color: tokens.textDisabled.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Noch keine Produkte gescannt',
            style: TextStyle(color: tokens.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _scanBarcode,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Jetzt scannen'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(ProductCheckResult product) {
    if (product.nutriscore != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getNutriscoreColor(product.nutriscore!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Nutri ${product.nutriscore}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getNutriscoreColor(String score) {
    switch (score.toUpperCase()) {
      case 'A': return Colors.green.shade800;
      case 'B': return Colors.green;
      case 'C': return Colors.yellow.shade800;
      case 'D': return Colors.orange;
      case 'E': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _ProductDetailSheet extends StatelessWidget {
  final ProductCheckResult product;

  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 24),
              if (product.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 100),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                product.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (product.brand != null)
                Text(
                  product.brand!,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              
              // Scores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (product.nutriscore != null)
                    _buildScoreCard('Nutri-Score', product.nutriscore!, _getNutriscoreColor(product.nutriscore!)),
                  if (product.ecoscore != null)
                    _buildScoreCard('Eco-Score', product.ecoscore!, Colors.green), // Simplified color
                ],
              ),
              const SizedBox(height: 24),

              // Ingredients
              const Text('Inhaltsstoffe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (product.ingredients.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.ingredients.map((i) => Chip(label: Text(i))).toList(),
                )
              else
                const Text('Keine Inhaltsstoffe gefunden.', style: TextStyle(fontStyle: FontStyle.italic)),
              
              const SizedBox(height: 24),

              // Additives
              if (product.additives.isNotEmpty) ...[
                const Text('Zusatzstoffe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.additives.map((a) => Chip(
                    label: Text(a),
                    backgroundColor: Colors.orange.shade100,
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Allergens
              if (product.allergens.isNotEmpty) ...[
                const Text('Allergene', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.allergens.map((a) => Chip(
                    label: Text(a),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: TextStyle(color: Colors.red.shade900),
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Source Info
              Text(
                'Datenquelle: ${product.source == ProductSource.openFoodFacts ? "Open Food Facts" : "Open Beauty Facts"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(String label, String score, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(score, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getNutriscoreColor(String score) {
    switch (score.toUpperCase()) {
      case 'A': return Colors.green.shade800;
      case 'B': return Colors.green;
      case 'C': return Colors.yellow.shade800;
      case 'D': return Colors.orange;
      case 'E': return Colors.red;
      default: return Colors.grey;
    }
  }
}
