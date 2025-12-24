/// Haarpflege Produkte Screen
/// Ermöglicht das Verwalten von Pflegeprodukten
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/hair_model.dart';

class HairProductsScreen extends ConsumerWidget {
  const HairProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final products = ref.watch(hairProductsProvider(user.id));
    final activeProducts = products.where((p) => p.isActive).toList();
    final inactiveProducts = products.where((p) => !p.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkte'),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: tokens.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Produkte',
                    style: TextStyle(
                      fontSize: 18,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Füge deine Haarpflegeprodukte hinzu\num Reaktionen zu dokumentieren',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeProducts.isNotEmpty) ...[
                  _buildSectionHeader(tokens, 'Aktive Produkte'),
                  const SizedBox(height: 8),
                  ...activeProducts.map((p) => _buildProductCard(context, ref, tokens, p, user.id)),
                ],
                if (inactiveProducts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(tokens, 'Inaktive Produkte'),
                  const SizedBox(height: 8),
                  ...inactiveProducts.map((p) => _buildProductCard(context, ref, tokens, p, user.id)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(DesignTokens tokens, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, DesignTokens tokens, HairProduct product, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getReactionColor(product.reaction).withOpacity(0.1),
          child: Text(product.category.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: product.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand != null)
              Text(product.brand!),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.category.label,
                    style: TextStyle(fontSize: 11, color: tokens.primary),
                  ),
                ),
                if (product.reaction != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getReactionColor(product.reaction).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(product.reaction!.emoji),
                        const SizedBox(width: 4),
                        Text(
                          product.reaction!.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getReactionColor(product.reaction),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: product.brand != null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(context, ref, value, product, userId),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: product.isActive ? 'deactivate' : 'activate',
              child: Text(product.isActive ? 'Deaktivieren' : 'Aktivieren'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Löschen')),
          ],
        ),
      ),
    );
  }

  Color _getReactionColor(ProductReaction? reaction) {
    switch (reaction) {
      case ProductReaction.good:
        return Colors.green;
      case ProductReaction.neutral:
        return Colors.orange;
      case ProductReaction.bad:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleProductAction(BuildContext context, WidgetRef ref, String action, HairProduct product, String userId) {
    switch (action) {
      case 'activate':
        ref.read(hairProductsProvider(userId).notifier).update(product.copyWith(isActive: true));
        break;
      case 'deactivate':
        ref.read(hairProductsProvider(userId).notifier).update(product.copyWith(isActive: false));
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Produkt löschen?'),
            content: Text('Möchtest du "${product.name}" wirklich löschen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(hairProductsProvider(userId).notifier).delete(product.id);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddProductSheet(),
    );
  }
}

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet();

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  HairProductCategory _selectedCategory = HairProductCategory.shampoo;
  ProductReaction? _selectedReaction;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            'Neues Produkt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Produktname *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _brandController,
            decoration: InputDecoration(
              labelText: 'Marke (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          Text('Kategorie', style: TextStyle(color: tokens.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HairProductCategory.values.map((cat) => ChoiceChip(
              avatar: Text(cat.emoji),
              label: Text(cat.label),
              selected: _selectedCategory == cat,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategory = cat);
              },
            )).toList(),
          ),
          const SizedBox(height: 16),

          Text('Reaktion (optional)', style: TextStyle(color: tokens.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Keine Angabe'),
                selected: _selectedReaction == null,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedReaction = null);
                },
              ),
              ...ProductReaction.values.map((r) => ChoiceChip(
                avatar: Text(r.emoji),
                label: Text(r.label),
                selected: _selectedReaction == r,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedReaction = r);
                },
              )),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notiz (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nameController.text.trim().isEmpty || _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Speichern'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final product = HairProduct(
        id: 'hair_product_${DateTime.now().millisecondsSinceEpoch}',
        oderId: user.id,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        brand: _brandController.text.isNotEmpty ? _brandController.text : null,
        reaction: _selectedReaction,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(hairProductsProvider(user.id).notifier).add(product);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produkt gespeichert'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
