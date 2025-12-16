/// Skin Products Screen - Hautpflegeprodukte verwalten

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SkinProductsScreen extends ConsumerWidget {
  const SkinProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final products = ref.watch(skinProductsNotifierProvider);
    
    // Group by category
    final Map<SkinProductCategory, List<SkinProduct>> grouped = {};
    for (final product in products) {
      grouped.putIfAbsent(product.category, () => []).add(product);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkte'),
      ),
      body: products.isEmpty
          ? _buildEmptyState(context, tokens)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: SkinProductCategory.values.map((category) {
                final categoryProducts = grouped[category] ?? [];
                if (categoryProducts.isEmpty) return const SizedBox.shrink();
                return _buildCategorySection(context, ref, tokens, category, categoryProducts);
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 64,
            color: tokens.textDisabled.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Produkte',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge deine Hautpflegeprodukte hinzu',
            style: TextStyle(
              color: tokens.textDisabled,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(SkinProductCategory category) {
    switch (category) {
      case SkinProductCategory.cleanser:
        return Icons.water_drop;
      case SkinProductCategory.toner:
        return Icons.opacity;
      case SkinProductCategory.serum:
        return Icons.science;
      case SkinProductCategory.moisturizer:
        return Icons.spa;
      case SkinProductCategory.sunscreen:
        return Icons.wb_sunny;
      case SkinProductCategory.mask:
        return Icons.face;
      case SkinProductCategory.other:
        return Icons.category;
    }
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    DesignTokens tokens,
    SkinProductCategory category,
    List<SkinProduct> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(_getCategoryIcon(category), color: tokens.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...products.map((product) => _buildProductCard(context, ref, tokens, product)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    DesignTokens tokens,
    SkinProduct product,
  ) {
    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: tokens.error,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(skinProductsNotifierProvider.notifier).delete(product.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (product.note != null)
                    Text(
                      product.note!,
                      style: TextStyle(
                        color: tokens.textDisabled,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (product.tolerance != null)
              _buildToleranceBadge(tokens, product.tolerance!),
          ],
        ),
      ),
    );
  }

  Widget _buildToleranceBadge(DesignTokens tokens, ProductTolerance tolerance) {
    Color color;
    String emoji;
    switch (tolerance) {
      case ProductTolerance.good:
        color = tokens.success;
        emoji = '✓';
        break;
      case ProductTolerance.neutral:
        color = tokens.warning;
        emoji = '~';
        break;
      case ProductTolerance.bad:
        color = tokens.error;
        emoji = '✗';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 4),
          Text(
            tolerance.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final noteController = TextEditingController();
    SkinProductCategory category = SkinProductCategory.moisturizer;
    ProductTolerance? tolerance;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final tokens = ref.watch(designTokensProvider);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: tokens.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: tokens.textDisabled.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Neues Produkt',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Produktname',
                        hintText: 'z.B. Hyaluron Serum',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Notiz (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Kategorie',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SkinProductCategory.values.map((cat) {
                        final isSelected = category == cat;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getCategoryIcon(cat), size: 16),
                              const SizedBox(width: 4),
                              Text(cat.label),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => category = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Verträglichkeit (optional)',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProductTolerance.values.map((tol) {
                        final isSelected = tolerance == tol;
                        return ChoiceChip(
                          label: Text(tol.label),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            tolerance = isSelected ? null : tol;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty) {
                            await _addProduct(
                              ref,
                              nameController.text,
                              noteController.text.isEmpty ? null : noteController.text,
                              category,
                              tolerance,
                            );
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Hinzufügen'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addProduct(
    WidgetRef ref,
    String name,
    String? note,
    SkinProductCategory category,
    ProductTolerance? tolerance,
  ) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final now = DateTime.now();
    final product = SkinProduct(
      id: now.millisecondsSinceEpoch.toString(),
      userId: user.id,
      name: name,
      category: category,
      tolerance: tolerance,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    
    await ref.read(skinProductsNotifierProvider.notifier).add(product);
  }
}
