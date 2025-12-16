/// Hausaufgaben Screen - Tägliche Aufgaben mit Abhaken

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> with SingleTickerProviderStateMixin {
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
    final homework = ref.watch(homeworkNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);

    final open = homework.where((h) => h.status != HomeworkStatus.done).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final completed = homework.where((h) => h.status == HomeworkStatus.done).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hausaufgaben'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Offen (${open.length})'),
            Tab(text: 'Erledigt (${completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeworkList(open, subjects, tokens, false),
          _buildHomeworkList(completed, subjects, tokens, true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHomeworkDialog(context, subjects, tokens),
        label: const Text('Hausaufgabe'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHomeworkList(
    List<Homework> items, 
    List<Subject> subjects,
    DesignTokens tokens, 
    bool isCompleted,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.history : Icons.check_circle_outline,
              size: 64,
              color: tokens.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? 'Keine erledigten Aufgaben' : 'Keine offenen Aufgaben 🎉',
              style: TextStyle(color: tokens.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final hw = items[index];
        final subject = subjects.cast<Subject?>().firstWhere(
          (s) => s?.id == hw.subjectId,
          orElse: () => null,
        );
        final isDone = hw.status == HomeworkStatus.done;
        final daysLeft = hw.dueDate.difference(DateTime.now()).inDays;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: Checkbox(
                  value: isDone,
                  onChanged: (value) {
                    final newStatus = value == true ? HomeworkStatus.done : HomeworkStatus.pending;
                    ref.read(homeworkNotifierProvider.notifier).updateStatus(hw.id, newStatus);
                  },
                ),
                title: Text(
                  hw.title,
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone 
                        ? tokens.textSecondary 
                        : hw.isOverdue 
                            ? tokens.error 
                            : tokens.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subject != null)
                      Text(subject.name, style: TextStyle(color: tokens.primary)),
                    if (hw.description != null)
                      Text(hw.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildDueLabel(tokens, hw, daysLeft),
                    Text(
                      DateFormat('dd.MM.').format(hw.dueDate),
                      style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                    ),
                  ],
                ),
                isThreeLine: hw.description != null || subject != null,
              ),
              // Status indicator
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _getStatusColor(hw.status),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDueLabel(DesignTokens tokens, Homework hw, int daysLeft) {
    if (hw.status == HomeworkStatus.done) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: tokens.success.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('✓', style: TextStyle(color: tokens.success)),
      );
    }

    String label;
    Color color;

    if (hw.isOverdue) {
      label = 'Überfällig!';
      color = tokens.error;
    } else if (daysLeft == 0) {
      label = 'Heute';
      color = Colors.orange;
    } else if (daysLeft == 1) {
      label = 'Morgen';
      color = Colors.orange;
    } else if (daysLeft <= 3) {
      label = 'In $daysLeft Tagen';
      color = Colors.amber;
    } else {
      label = 'In $daysLeft Tagen';
      color = tokens.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.pending: return Colors.grey;
      case HomeworkStatus.inProgress: return Colors.orange;
      case HomeworkStatus.done: return Colors.green;
    }
  }

  void _showAddHomeworkDialog(BuildContext context, List<Subject> subjects, DesignTokens tokens) {
    String? selectedSubjectId;
    DateTime selectedDue = DateTime.now().add(const Duration(days: 1));
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Hausaufgabe hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Aufgabe'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Fach'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Kein Fach')),
                    ...subjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    )),
                  ],
                  onChanged: (value) => setState(() => selectedSubjectId = value),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fällig am'),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDue,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDue = date);
                      }
                    },
                    child: Text(DateFormat('dd.MM.yyyy').format(selectedDue)),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Details (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                
                final user = ref.read(authNotifierProvider).valueOrNull;
                if (user == null) return;
                
                final now = DateTime.now();
                final hw = Homework(
                  id: 'hw_${now.millisecondsSinceEpoch}',
                  userId: user.id,
                  subjectId: selectedSubjectId,
                  title: titleController.text.trim(),
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  dueDate: selectedDue,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await ref.read(homeworkNotifierProvider.notifier).add(hw);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
