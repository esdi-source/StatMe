/// Haarpflege Eintrag Screen
/// Ermöglicht das Erfassen der täglichen Haarpflege
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/hair_model.dart';

class HairEntryScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const HairEntryScreen({super.key, required this.date});

  @override
  ConsumerState<HairEntryScreen> createState() => _HairEntryScreenState();
}

class _HairEntryScreenState extends ConsumerState<HairEntryScreen> {
  final Set<HairCareType> _selectedTypes = {};
  final List<String> _customProducts = [];
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customProductController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final existing = ref.read(hairCareEntriesProvider(user.id).notifier).getForDate(widget.date);
    if (existing != null) {
      setState(() {
        _selectedTypes.addAll(existing.careTypes);
        _customProducts.addAll(existing.customProducts);
        _noteController.text = existing.note ?? '';
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customProductController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, d. MMMM', 'de_DE').format(widget.date)),
        actions: [
          if (_selectedTypes.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pflege-Typen
          _buildSectionHeader(tokens, 'Was hast du heute gemacht?'),
          const SizedBox(height: 12),
          _buildCareTypeGrid(tokens),
          
          const SizedBox(height: 24),
          
          // Custom Produkte
          _buildSectionHeader(tokens, 'Verwendete Produkte (optional)'),
          const SizedBox(height: 12),
          _buildCustomProductsSection(tokens),
          
          const SizedBox(height: 24),
          
          // Notiz
          _buildSectionHeader(tokens, 'Notiz (optional)'),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'z.B. Neues Shampoo ausprobiert...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(DesignTokens tokens, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
    );
  }

  Widget _buildCareTypeGrid(DesignTokens tokens) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HairCareType.values.where((t) => t != HairCareType.custom).map((type) {
        final isSelected = _selectedTypes.contains(type);
        return FilterChip(
          avatar: Text(type.emoji),
          label: Text(type.label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
          selectedColor: tokens.primary.withOpacity(0.2),
          checkmarkColor: tokens.primary,
        );
      }).toList(),
    );
  }

  Widget _buildCustomProductsSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vorhandene Produkte
        if (_customProducts.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customProducts.map((product) => Chip(
              label: Text(product),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _customProducts.remove(product);
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Neues Produkt hinzufügen
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customProductController,
                decoration: InputDecoration(
                  hintText: 'Produktname eingeben...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _addCustomProduct,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _addCustomProduct(_customProductController.text),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  void _addCustomProduct(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_customProducts.contains(trimmed)) {
      setState(() {
        _customProducts.add(trimmed);
        _customProductController.clear();
      });
    }
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final entry = HairCareEntry(
        id: 'hair_${widget.date.toIso8601String().split('T').first}_${DateTime.now().millisecondsSinceEpoch}',
        oderId: user.id,
        date: widget.date,
        careTypes: _selectedTypes.toList(),
        customProducts: _customProducts,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(hairCareEntriesProvider(user.id).notifier).addOrUpdate(entry);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haarpflege gespeichert'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
