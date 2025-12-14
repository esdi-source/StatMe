/// Todo Edit Screen with RRULE Builder

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class TodoEditScreen extends ConsumerStatefulWidget {
  final TodoModel? todo;
  final String userId;

  const TodoEditScreen({
    super.key,
    this.todo,
    required this.userId,
  });

  @override
  ConsumerState<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends ConsumerState<TodoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  DateTime? _endDate;
  RecurrenceType _recurrenceType = RecurrenceType.once;
  TodoPriority _priority = TodoPriority.medium;
  bool _isActive = true;
  
  // RRULE options
  final List<int> _weekDays = [];
  int _monthDay = 1;
  int _interval = 1;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController = TextEditingController(text: widget.todo?.description ?? '');
    _startDate = widget.todo?.startDate ?? DateTime.now();
    _endDate = widget.todo?.endDate;
    _recurrenceType = widget.todo?.recurrenceType ?? RecurrenceType.once;
    _priority = widget.todo?.priority ?? TodoPriority.medium;
    _isActive = widget.todo?.active ?? true;
    
    // Parse RRULE if exists
    if (widget.todo?.rruleText != null) {
      _parseRrule(widget.todo!.rruleText!);
    }
  }

  void _parseRrule(String rrule) {
    // Simple RRULE parsing
    if (rrule.contains('BYDAY=')) {
      final dayMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rrule);
      if (dayMatch != null) {
        final days = dayMatch.group(1)!.split(',');
        final dayMap = {'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7};
        for (final day in days) {
          if (dayMap.containsKey(day)) {
            _weekDays.add(dayMap[day]!);
          }
        }
      }
    }
    
    if (rrule.contains('BYMONTHDAY=')) {
      final match = RegExp(r'BYMONTHDAY=(\d+)').firstMatch(rrule);
      if (match != null) {
        _monthDay = int.tryParse(match.group(1)!) ?? 1;
      }
    }
    
    if (rrule.contains('INTERVAL=')) {
      final match = RegExp(r'INTERVAL=(\d+)').firstMatch(rrule);
      if (match != null) {
        _interval = int.tryParse(match.group(1)!) ?? 1;
      }
    }
  }

  String _buildRrule() {
    if (_recurrenceType == RecurrenceType.once) return '';
    
    final parts = <String>[];
    
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        parts.add('FREQ=DAILY');
        break;
      case RecurrenceType.weekly:
        parts.add('FREQ=WEEKLY');
        if (_weekDays.isNotEmpty) {
          final dayNames = ['', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
          parts.add('BYDAY=${_weekDays.map((d) => dayNames[d]).join(',')}');
        }
        break;
      case RecurrenceType.monthly:
        parts.add('FREQ=MONTHLY');
        parts.add('BYMONTHDAY=$_monthDay');
        break;
      case RecurrenceType.yearly:
        parts.add('FREQ=YEARLY');
        break;
      case RecurrenceType.custom:
        parts.add('FREQ=DAILY');
        break;
      default:
        break;
    }
    
    if (_interval > 1) {
      parts.add('INTERVAL=$_interval');
    }
    
    return parts.join(';');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final todoNotifier = ref.read(todoNotifierProvider.notifier);
      
      final todo = TodoModel(
        id: widget.todo?.id ?? const Uuid().v4(),
        userId: widget.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        rruleText: _buildRrule().isEmpty ? null : _buildRrule(),
        timezone: 'Europe/Berlin',
        active: _isActive,
        priority: _priority,
        createdAt: widget.todo?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.todo == null) {
        await todoNotifier.create(todo);
      } else {
        await todoNotifier.update(todo);
      }

      if (mounted) {
        Navigator.of(context).pop(todo);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ToDo bearbeiten' : 'Neues ToDo'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Titel eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Priority
              Text(
                'Priorität',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TodoPriority>(
                segments: const [
                  ButtonSegment(
                    value: TodoPriority.low,
                    label: Text('Niedrig'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TodoPriority.medium,
                    label: Text('Mittel'),
                    icon: Icon(Icons.remove),
                  ),
                  ButtonSegment(
                    value: TodoPriority.high,
                    label: Text('Hoch'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TodoPriority.urgent,
                    label: Text('Dringend'),
                    icon: Icon(Icons.priority_high),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (selected) {
                  setState(() => _priority = selected.first);
                },
              ),
              const SizedBox(height: 24),

              // Start Date
              ListTile(
                title: const Text('Startdatum'),
                subtitle: Text(_formatDate(_startDate)),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              const Divider(),

              // End Date (optional)
              ListTile(
                title: const Text('Enddatum (optional)'),
                subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Nicht gesetzt'),
                leading: const Icon(Icons.event),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _endDate = null),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                    firstDate: _startDate,
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Recurrence
              Text(
                'Wiederholung',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RecurrenceType.values.map((type) {
                  return ChoiceChip(
                    label: Text(_recurrenceLabel(type)),
                    selected: _recurrenceType == type,
                    onSelected: (selected) {
                      setState(() => _recurrenceType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Recurrence Options
              if (_recurrenceType == RecurrenceType.weekly) ...[
                Text(
                  'An welchen Tagen?',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ('Mo', 1),
                    ('Di', 2),
                    ('Mi', 3),
                    ('Do', 4),
                    ('Fr', 5),
                    ('Sa', 6),
                    ('So', 7),
                  ].map((day) {
                    return FilterChip(
                      label: Text(day.$1),
                      selected: _weekDays.contains(day.$2),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _weekDays.add(day.$2);
                          } else {
                            _weekDays.remove(day.$2);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              if (_recurrenceType == RecurrenceType.monthly) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Am '),
                    DropdownButton<int>(
                      value: _monthDay,
                      items: List.generate(31, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('$d.')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _monthDay = value);
                        }
                      },
                    ),
                    const Text(' des Monats'),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Active Toggle
              SwitchListTile(
                title: const Text('Aktiv'),
                subtitle: const Text('Deaktivierte ToDos werden nicht angezeigt'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 24),

              // RRULE Preview
              if (_recurrenceType != RecurrenceType.once)
                Card(
                  color: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RRULE (RFC 5545)',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _buildRrule(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.once:
        return 'Einmalig';
      case RecurrenceType.daily:
        return 'Täglich';
      case RecurrenceType.weekly:
        return 'Wöchentlich';
      case RecurrenceType.monthly:
        return 'Monatlich';
      case RecurrenceType.yearly:
        return 'Jährlich';
      case RecurrenceType.custom:
        return 'Benutzerdefiniert';
    }
  }
}
