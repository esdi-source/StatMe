/// Book Detail Screen - View and edit book details, add ratings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/book_model.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  late BookModel _book;
  bool _showDetailedRatings = false;
  
  // Rating controllers
  int _overallRating = 5;
  int _storyRating = 5;
  int _charactersRating = 5;
  int _writingRating = 5;
  int _pacingRating = 5;
  int _emotionalRating = 5;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    if (_book.rating != null) {
      _overallRating = _book.rating!.overall;
      _storyRating = _book.rating!.story ?? 5;
      _charactersRating = _book.rating!.characters ?? 5;
      _writingRating = _book.rating!.writing ?? 5;
      _pacingRating = _book.rating!.pacing ?? 5;
      _emotionalRating = _book.rating!.emotionalImpact ?? 5;
      _noteController.text = _book.rating!.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buchdetails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Cover
            Container(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _book.coverUrl != null
                        ? Image.network(
                            _book.coverUrl!,
                            width: 120,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                          )
                        : _buildPlaceholderCover(),
                  ),
                  const SizedBox(width: 20),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _book.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_book.author != null)
                          Text(
                            _book.author!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_book.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _book.status.label,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        if (_book.pageCount != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.menu_book, size: 16),
                              const SizedBox(width: 4),
                              Text('${_book.pageCount} Seiten'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Status Change Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status ändern',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BookStatus.values.map((status) {
                      final isSelected = _book.status == status;
                      return ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        onSelected: (_) => _updateStatus(status),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Rating Section (only for finished books)
            if (_book.status == BookStatus.finished) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bewertung',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Overall Rating
                    _buildRatingRow('Gesamtbewertung', _overallRating, (value) {
                      setState(() => _overallRating = value);
                    }, isMain: true),
                    
                    // Toggle for detailed ratings
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _showDetailedRatings = !_showDetailedRatings),
                      icon: Icon(_showDetailedRatings ? Icons.expand_less : Icons.expand_more),
                      label: Text(_showDetailedRatings 
                          ? 'Weniger Kategorien' 
                          : 'Detaillierte Bewertung'),
                    ),
                    
                    // Detailed Ratings
                    if (_showDetailedRatings) ...[
                      const SizedBox(height: 12),
                      _buildRatingRow('Geschichte', _storyRating, (value) {
                        setState(() => _storyRating = value);
                      }),
                      _buildRatingRow('Charaktere', _charactersRating, (value) {
                        setState(() => _charactersRating = value);
                      }),
                      _buildRatingRow('Schreibstil', _writingRating, (value) {
                        setState(() => _writingRating = value);
                      }),
                      _buildRatingRow('Tempo', _pacingRating, (value) {
                        setState(() => _pacingRating = value);
                      }),
                      _buildRatingRow('Emotionale Wirkung', _emotionalRating, (value) {
                        setState(() => _emotionalRating = value);
                      }),
                    ],
                    
                    // Note
                    const SizedBox(height: 20),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Kurze Notiz / Fazit',
                        hintText: 'Was hat dir besonders gefallen oder nicht gefallen?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    
                    // Save Rating Button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveRating,
                        icon: const Icon(Icons.save),
                        label: const Text('Bewertung speichern'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Prompt to mark as finished
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.star_border, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Markiere das Buch als "Gelesen" um es zu bewerten.',
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            
            // Book Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informationen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Hinzugefügt', _formatDate(_book.addedAt)),
                  if (_book.finishedAt != null)
                    _buildInfoRow('Beendet', _formatDate(_book.finishedAt!)),
                  if (_book.isbn != null)
                    _buildInfoRow('ISBN', _book.isbn!),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 120,
      height: 180,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _book.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int value, Function(int) onChanged, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                fontSize: isMain ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(10, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => onChanged(starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      starValue <= value ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: isMain ? 28 : 20,
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMain ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Color _getStatusColor(BookStatus status) {
    switch (status) {
      case BookStatus.wantToRead:
        return Colors.blue;
      case BookStatus.reading:
        return Colors.orange;
      case BookStatus.finished:
        return Colors.green;
    }
  }

  Future<void> _updateStatus(BookStatus status) async {
    final updatedBook = _book.copyWith(
      status: status,
      finishedAt: status == BookStatus.finished ? DateTime.now() : null,
    );
    
    await ref.read(bookNotifierProvider.notifier).updateBook(updatedBook);
    setState(() => _book = updatedBook);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status geändert zu "${status.label}"')),
      );
    }
  }

  Future<void> _saveRating() async {
    final rating = BookRating(
      overall: _overallRating,
      story: _showDetailedRatings ? _storyRating : null,
      characters: _showDetailedRatings ? _charactersRating : null,
      writing: _showDetailedRatings ? _writingRating : null,
      pacing: _showDetailedRatings ? _pacingRating : null,
      emotionalImpact: _showDetailedRatings ? _emotionalRating : null,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    
    final updatedBook = _book.copyWith(rating: rating);
    await ref.read(bookNotifierProvider.notifier).updateBook(updatedBook);
    setState(() => _book = updatedBook);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bewertung gespeichert')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buch löschen?'),
        content: Text('Möchtest du "${_book.title}" wirklich aus deiner Bibliothek entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(bookNotifierProvider.notifier).deleteBook(_book.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
