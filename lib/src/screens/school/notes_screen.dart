/// Notizen Screen - Freie und fachbezogene Notizen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String? _filterSubjectId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final notes = ref.watch(schoolNotesNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);

    // Filter anwenden
    var filteredNotes = notes.where((n) {
      if (_filterSubjectId != null && n.subjectId != _filterSubjectId) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return n.title.toLowerCase().contains(query) || 
               n.content.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Sortieren: Angepinnt zuerst, dann nach Datum
    filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notizen'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list,
              color: _filterSubjectId != null ? tokens.primary : null,
            ),
            onSelected: (value) => setState(() => _filterSubjectId = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Alle Fächer')),
              const PopupMenuDivider(),
              ...subjects.map((s) => PopupMenuItem(
                value: s.id,
                child: Row(
                  children: [
                    if (_filterSubjectId == s.id)
                      Icon(Icons.check, size: 16, color: tokens.primary),
                    const SizedBox(width: 8),
                    Text(s.name),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: filteredNotes.isEmpty
          ? _buildEmptyState(tokens)
          : _buildNotesList(filteredNotes, subjects, tokens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteEditor(context, null, subjects, tokens),
        label: const Text('Neue Notiz'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 80, color: tokens.textSecondary),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Keine Notizen gefunden'
                : 'Noch keine Notizen erstellt',
            style: TextStyle(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<SchoolNote> notes, List<Subject> subjects, DesignTokens tokens) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final subject = subjects.cast<Subject?>().firstWhere(
          (s) => s?.id == note.subjectId,
          orElse: () => null,
        );

        return GestureDetector(
          onTap: () => _showNoteEditor(context, note, subjects, tokens),
          onLongPress: () => _showNoteOptions(context, note, tokens),
          child: Card(
            color: note.color != null 
                ? Color(int.parse(note.color!.replaceFirst('#', '0xFF')))
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      if (note.isPinned)
                        Icon(Icons.push_pin, size: 16, color: tokens.primary),
                      const Spacer(),
                      if (subject != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subject.name,
                            style: TextStyle(fontSize: 10, color: tokens.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Content Preview
                  Expanded(
                    child: Text(
                      note.content,
                      style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Date
                  Text(
                    DateFormat('dd.MM.yyyy').format(note.updatedAt),
                    style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNoteOptions(BuildContext context, SchoolNote note, DesignTokens tokens) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(note.isPinned ? 'Lösen' : 'Anpinnen'),
            onTap: () {
              ref.read(schoolNotesNotifierProvider.notifier).togglePin(note.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Farbe ändern'),
            onTap: () {
              Navigator.pop(context);
              _showColorPicker(context, note, tokens);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: tokens.error),
            title: Text('Löschen', style: TextStyle(color: tokens.error)),
            onTap: () {
              ref.read(schoolNotesNotifierProvider.notifier).delete(note.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, SchoolNote note, DesignTokens tokens) {
    final colors = [
      null, // Default
      '#FFECB3', // Gelb
      '#C8E6C9', // Grün
      '#BBDEFB', // Blau
      '#F8BBD9', // Rosa
      '#E1BEE7', // Lila
      '#FFCCBC', // Orange
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = note.color == color;
            return GestureDetector(
              onTap: () {
                ref.read(schoolNotesNotifierProvider.notifier).updateColor(note.id, color);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color != null 
                      ? Color(int.parse(color.replaceFirst('#', '0xFF')))
                      : tokens.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? tokens.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: color == null 
                    ? Icon(Icons.format_color_reset, color: tokens.textSecondary)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, SchoolNote? note, List<Subject> subjects, DesignTokens tokens) {
    final isEditing = note != null;
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    String? selectedSubjectId = note?.subjectId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Notiz bearbeiten' : 'Neue Notiz'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveNote(
                    context,
                    note,
                    titleController.text,
                    contentController.text,
                    selectedSubjectId,
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Subject selector
                  DropdownButtonFormField<String?>(
                    initialValue: selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Fach (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Kein Fach')),
                      ...subjects.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      )),
                    ],
                    onChanged: (value) => setState(() => selectedSubjectId = value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titel',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: !isEditing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Content
                  Expanded(
                    child: TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText: 'Inhalt',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNote(
    BuildContext context,
    SchoolNote? existingNote,
    String title,
    String content,
    String? subjectId,
  ) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Titel eingeben')),
      );
      return;
    }

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final now = DateTime.now();
    
    if (existingNote != null) {
      // Update
      final updated = existingNote.copyWith(
        title: title.trim(),
        content: content,
        subjectId: subjectId,
        updatedAt: now,
      );
      await ref.read(schoolNotesNotifierProvider.notifier).update(updated);
    } else {
      // Create
      final note = SchoolNote(
        id: 'note_${now.millisecondsSinceEpoch}',
        userId: user.id,
        subjectId: subjectId,
        title: title.trim(),
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(schoolNotesNotifierProvider.notifier).add(note);
    }

    if (context.mounted) Navigator.pop(context);
  }
}
