import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/home_widget_model.dart';
import '../../models/product_check_model.dart';
import '../../services/product_check_service.dart';
import '../../providers/providers.dart';
import '../barcode_scanner_screen.dart';
import 'product_check_screen.dart';

class ProductCheckWidget extends ConsumerStatefulWidget {
  final HomeWidget widgetData;

  const ProductCheckWidget({super.key, required this.widgetData});

  @override
  ConsumerState<ProductCheckWidget> createState() => _ProductCheckWidgetState();
}

class _ProductCheckWidgetState extends ConsumerState<ProductCheckWidget> {
  ProductCheckResult? _lastProduct;

  @override
  void initState() {
    super.initState();
    _loadLastProduct();
  }

  Future<void> _loadLastProduct() async {
    final history = await ProductCheckService().getHistory();
    if (mounted && history.isNotEmpty) {
      setState(() {
        _lastProduct = history.first;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode != null && mounted) {
      // Navigate to full screen and fetch there
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ProductCheckScreen()),
      );
      // Ideally we would pass the barcode to auto-scan, but for now just opening the screen is fine.
      // Or we can fetch here and show a dialog.
      // Let's just open the screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final size = widget.widgetData.size;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProductCheckScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          boxShadow: tokens.shadowSmall,
        ),
        child: size.isSmall ? _buildSmall(tokens) : _buildLarge(tokens),
      ),
    );
  }

  Widget _buildSmall(DesignTokens tokens) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code_scanner, size: 32, color: tokens.primary),
        const SizedBox(height: 8),
        Text(
          'Scan',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLarge(DesignTokens tokens) {
    if (_lastProduct == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 48, color: tokens.primary),
          const SizedBox(height: 12),
          Text(
            'Produkt-Check',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tippe zum Scannen',
            style: TextStyle(color: tokens.textSecondary, fontSize: 12),
          ),
        ],
      );
    }

    final product = _lastProduct!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: tokens.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Zuletzt gescannt',
              style: TextStyle(color: tokens.textSecondary, fontSize: 10),
            ),
            const Spacer(),
            if (product.nutriscore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getNutriscoreColor(product.nutriscore!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Nutri ${product.nutriscore}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              if (product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (product.brand != null)
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
