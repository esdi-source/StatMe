/// Haarpflege Ereignisse Screen
/// Ermöglicht das Erfassen von besonderen Ereignissen (Haarschnitt, Färben, etc.)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/hair_model.dart';

class HairEventScreen extends ConsumerStatefulWidget {
  final bool addNew;

  const HairEventScreen({super.key, this.addNew = false});

  @override
  ConsumerState<HairEventScreen> createState() => _HairEventScreenState();
}

class _HairEventScreenState extends ConsumerState<HairEventScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.addNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddEventDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final events = ref.watch(hairEventsProvider(user.id));
    final sortedEvents = events.toList()..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ereignisse'),
      ),
      body: sortedEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 64, color: tokens.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Ereignisse',
                    style: TextStyle(
                      fontSize: 18,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Füge deinen ersten Haarschnitt oder\nein anderes Ereignis hinzu',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedEvents.length,
              itemBuilder: (context, index) {
                final event = sortedEvents[index];
                return _buildEventCard(tokens, event, user.id);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(DesignTokens tokens, HairEvent event, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tokens.primary.withOpacity(0.1),
          child: Text(event.eventType.emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          event.title ?? event.eventType.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(event.date)),
            if (event.salonName != null)
              Text('📍 ${event.salonName}'),
            if (event.note != null)
              Text(event.note!, style: TextStyle(color: tokens.textSecondary)),
          ],
        ),
        trailing: event.cost != null
            ? Text(
                '${event.cost!.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              )
            : null,
        isThreeLine: event.salonName != null || event.note != null,
        onLongPress: () => _showDeleteDialog(event, userId),
      ),
    );
  }

  void _showDeleteDialog(HairEvent event, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ereignis löschen?'),
        content: Text('Möchtest du "${event.title ?? event.eventType.label}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(hairEventsProvider(userId).notifier).delete(event.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddEventSheet(),
    );
  }
}

class _AddEventSheet extends ConsumerStatefulWidget {
  const _AddEventSheet();

  @override
  ConsumerState<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<_AddEventSheet> {
  HairEventType _selectedType = HairEventType.haircut;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _salonController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _salonController.dispose();
    _costController.dispose();
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
          // Handle
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
            'Neues Ereignis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Event Type
          Text('Art des Ereignisses', style: TextStyle(color: tokens.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HairEventType.values.map((type) => ChoiceChip(
              avatar: Text(type.emoji),
              label: Text(type.label),
              selected: _selectedType == type,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = type);
              },
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today, color: tokens.primary),
            title: Text(DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(_selectedDate)),
            trailing: const Icon(Icons.edit),
            onTap: _selectDate,
          ),
          const SizedBox(height: 8),

          // Title (optional)
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Titel (optional)',
              hintText: 'z.B. Neuer Look',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Salon
          TextField(
            controller: _salonController,
            decoration: InputDecoration(
              labelText: 'Salon/Friseur (optional)',
              hintText: 'z.B. Salon XY',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Cost
          TextField(
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Kosten (optional)',
              hintText: '0.00',
              suffixText: '€',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Note
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notiz (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _save,
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final event = HairEvent(
        id: 'hair_event_${DateTime.now().millisecondsSinceEpoch}',
        oderId: user.id,
        date: _selectedDate,
        eventType: _selectedType,
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        salonName: _salonController.text.isNotEmpty ? _salonController.text : null,
        cost: _costController.text.isNotEmpty ? double.tryParse(_costController.text.replaceAll(',', '.')) : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(hairEventsProvider(user.id).notifier).add(event);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ereignis gespeichert'),
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
