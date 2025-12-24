/// Skin Entry Screen - Täglichen Hautzustand erfassen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SkinEntryScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final SkinEntry? existingEntry;

  const SkinEntryScreen({
    super.key,
    required this.date,
    this.existingEntry,
  });

  @override
  ConsumerState<SkinEntryScreen> createState() => _SkinEntryScreenState();
}

class _SkinEntryScreenState extends ConsumerState<SkinEntryScreen> {
  late SkinCondition _overallCondition;
  final Map<FaceArea, SkinCondition> _areaConditions = {};
  final Set<SkinAttribute> _attributes = {};
  final _notesController = TextEditingController();
  
  bool _showFaceAreas = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingEntry != null) {
      _overallCondition = widget.existingEntry!.overallCondition;
      if (widget.existingEntry!.areaConditions != null) {
        _areaConditions.addAll(widget.existingEntry!.areaConditions!);
      }
      _attributes.addAll(widget.existingEntry!.attributes);
      _notesController.text = widget.existingEntry!.note ?? '';
    } else {
      _overallCondition = SkinCondition.neutral;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Eintrag bearbeiten' : 'Neuer Eintrag'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: tokens.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, dd. MMMM yyyy', 'de_DE').format(widget.date),
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Overall condition
            _buildOverallConditionSection(tokens),
            const SizedBox(height: 24),
            
            // Face areas (collapsible)
            _buildFaceAreasSection(tokens),
            const SizedBox(height: 24),
            
            // Attributes
            _buildAttributesSection(tokens),
            const SizedBox(height: 24),
            
            // Notes
            _buildNotesSection(tokens),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Speichern' : 'Eintrag erstellen'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallConditionSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gesamtzustand',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Wie fühlt sich deine Haut heute an?',
          style: TextStyle(
            color: tokens.textDisabled,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: SkinCondition.values.map((condition) {
            final isSelected = _overallCondition == condition;
            return GestureDetector(
              onTap: () => setState(() => _overallCondition = condition),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? tokens.primary.withOpacity(0.1)
                      : tokens.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? tokens.primary : tokens.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      condition.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condition.label,
                      style: TextStyle(
                        color: isSelected ? tokens.primary : tokens.textSecondary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFaceAreasSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showFaceAreas = !_showFaceAreas),
          child: Row(
            children: [
              Icon(
                _showFaceAreas ? Icons.expand_less : Icons.expand_more,
                color: tokens.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Gesichtsbereiche (optional)',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        if (_showFaceAreas) ...[
          const SizedBox(height: 16),
          ...FaceArea.values.map((area) => _buildFaceAreaTile(tokens, area)),
        ],
      ],
    );
  }

  Widget _buildFaceAreaTile(DesignTokens tokens, FaceArea area) {
    final currentCondition = _areaConditions[area] ?? SkinCondition.neutral;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                area.label,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                currentCondition.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: currentCondition.value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (value) {
                setState(() {
                  _areaConditions[area] = SkinCondition.values[value.round() - 1];
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hautattribute',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Was beschreibt deine Haut heute?',
          style: TextStyle(
            color: tokens.textDisabled,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SkinAttribute.values.map((attr) {
            final isSelected = _attributes.contains(attr);
            return FilterChip(
              label: Text(attr.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _attributes.add(attr);
                  } else {
                    _attributes.remove(attr);
                  }
                });
              },
              selectedColor: tokens.primary.withOpacity(0.2),
              checkmarkColor: tokens.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notizen',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Besonderheiten, Trigger, etc...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Dieser Eintrag wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _delete();
    }
  }

  Future<void> _delete() async {
    if (widget.existingEntry == null) return;
    
    await ref.read(skinEntriesNotifierProvider.notifier).delete(widget.existingEntry!.id);
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eintrag gelöscht')),
      );
    }
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final now = DateTime.now();
    final entry = SkinEntry(
      id: widget.existingEntry?.id ?? now.millisecondsSinceEpoch.toString(),
      userId: user.id,
      date: widget.date,
      overallCondition: _overallCondition,
      areaConditions: _areaConditions.isNotEmpty ? Map.from(_areaConditions) : null,
      attributes: _attributes.toList(),
      note: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: widget.existingEntry?.createdAt ?? now,
      updatedAt: now,
    );
    
    if (widget.existingEntry != null) {
      await ref.read(skinEntriesNotifierProvider.notifier).update(entry);
    } else {
      await ref.read(skinEntriesNotifierProvider.notifier).add(entry);
    }
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingEntry != null ? 'Eintrag aktualisiert' : 'Eintrag erstellt')),
      );
    }
  }
}
