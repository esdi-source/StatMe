/// Skin Routine Screen - Pflegeroutine verwalten

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SkinRoutineScreen extends ConsumerStatefulWidget {
  const SkinRoutineScreen({super.key});

  @override
  ConsumerState<SkinRoutineScreen> createState() => _SkinRoutineScreenState();
}

class _SkinRoutineScreenState extends ConsumerState<SkinRoutineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final steps = ref.watch(skinCareStepsNotifierProvider);
    final completions = ref.watch(skinCareCompletionsNotifierProvider);
    
    final dailySteps = steps.where((s) => s.isDaily).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final occasionalSteps = steps.where((s) => !s.isDaily).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pflegeroutine'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Täglich (${dailySteps.length})'),
            Tab(text: 'Gelegentlich (${occasionalSteps.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStepsList(tokens, dailySteps, completions, isDaily: true),
          _buildStepsList(tokens, occasionalSteps, completions, isDaily: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStepDialog(_tabController.index == 0),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStepsList(DesignTokens tokens, List<SkinCareStep> steps, List<SkinCareCompletion> completions, {required bool isDaily}) {
    if (steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.spa,
              size: 64,
              color: tokens.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isDaily 
                  ? 'Keine täglichen Schritte' 
                  : 'Keine gelegentlichen Schritte',
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf + um einen Schritt hinzuzufügen',
              style: TextStyle(
                color: tokens.textDisabled,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final orderedIds = steps.map((s) => s.id).toList();
        final id = orderedIds.removeAt(oldIndex);
        orderedIds.insert(newIndex, id);
        ref.read(skinCareStepsNotifierProvider.notifier).reorder(orderedIds);
      },
      itemBuilder: (context, index) {
        final step = steps[index];
        final isCompleted = completions.any((c) => c.stepId == step.id);
        
        return _buildStepCard(tokens, step, isCompleted, key: ValueKey(step.id));
      },
    );
  }

  Widget _buildStepCard(DesignTokens tokens, SkinCareStep step, bool isCompleted, {Key? key}) {
    return Dismissible(
      key: key ?? ValueKey(step.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: tokens.error,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Schritt löschen?'),
            content: Text('Möchtest du "${step.name}" wirklich löschen?'),
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
      },
      onDismissed: (_) {
        ref.read(skinCareStepsNotifierProvider.notifier).delete(step.id);
      },
      child: Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(
            color: isCompleted ? tokens.success : tokens.divider,
          ),
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: () {
              ref.read(skinCareCompletionsNotifierProvider.notifier).toggle(step.id);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? tokens.success.withOpacity(0.1)
                    : tokens.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? tokens.success : tokens.divider,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle_outlined,
                color: isCompleted ? tokens.success : tokens.textDisabled,
                size: 20,
              ),
            ),
          ),
          title: Text(
            step.name,
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: step.name != null
              ? Text(
                  'Mit Produkt verknüpft',
                  style: TextStyle(
                    color: tokens.textDisabled,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: ReorderableDragStartListener(
            index: 0,
            child: Icon(Icons.drag_handle, color: tokens.textDisabled),
          ),
          onTap: () => _showEditStepDialog(step),
        ),
      ),
    );
  }

  void _showAddStepDialog(bool isDaily) {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final tokens = ref.watch(designTokensProvider);
        
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
                'Neuer Pflegeschritt',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name des Schritts',
                  hintText: 'z.B. Reinigung, Serum, Feuchtigkeitspflege...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Quick suggestions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Reinigung', 'Toner', 'Serum', 'Feuchtigkeitspflege',
                  'Sonnenschutz', 'Augencrème', 'Peeling', 'Maske',
                ].map((name) => ActionChip(
                  label: Text(name),
                  onPressed: () {
                    controller.text = name;
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isNotEmpty) {
                      await _addStep(controller.text, isDaily);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Hinzufügen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditStepDialog(SkinCareStep step) {
    final controller = TextEditingController(text: step.name);
    bool isDaily = step.isDaily;
    
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
                    'Schritt bearbeiten',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Täglicher Schritt'),
                    subtitle: Text(
                      isDaily ? 'Wird jeden Tag angezeigt' : 'Wird als gelegentlich markiert',
                    ),
                    value: isDaily,
                    onChanged: (value) => setState(() => isDaily = value),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          await _updateStep(step, controller.text, isDaily);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addStep(String name, bool isDaily) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final steps = ref.read(skinCareStepsNotifierProvider);
    final maxOrder = steps.isEmpty ? 0 : steps.map((s) => s.order).reduce((a, b) => a > b ? a : b);
    
    final now = DateTime.now();
    final step = SkinCareStep(
      id: now.millisecondsSinceEpoch.toString(),
      userId: user.id,
      name: name,
      isDaily: isDaily,
      order: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );
    
    await ref.read(skinCareStepsNotifierProvider.notifier).add(step);
  }

  Future<void> _updateStep(SkinCareStep step, String name, bool isDaily) async {
    final updated = step.copyWith(
      name: name,
      isDaily: isDaily,
    );
    
    await ref.read(skinCareStepsNotifierProvider.notifier).update(updated);
  }
}
