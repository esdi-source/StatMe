/// Book Detail Screen - View and edit book details, add ratings
/// Redesigned with 5-star rating system and responsive layout

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
  
  // Rating (1-5 Sterne, intern als 1-10 gespeichert)
  int _starRating = 3;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    if (_book.rating != null) {
      // Konvertiere 1-10 zu 1-5 Sterne
      _starRating = (_book.rating!.overall / 2).round().clamp(1, 5);
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
    final tokens = ref.watch(designTokensProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buchdetails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header mit Cover
            _buildHeader(tokens),
            
            // Quick Actions
            _buildQuickActions(tokens),
            
            const Divider(height: 32),
            
            // Rating Section (nur für gelesene Bücher)
            if (_book.status == BookStatus.finished)
              _buildRatingSection(tokens)
            else
              _buildFinishPrompt(tokens),
            
            // Book Info
            _buildInfoSection(tokens),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DesignTokens tokens) {
    return Container(
      color: tokens.primary.withOpacity(0.1),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
            child: SizedBox(
              width: 100,
              height: 150,
              child: _buildCover(),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _book.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_book.author != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _book.author!,
                    style: TextStyle(
                      fontSize: 16,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_book.status),
                    borderRadius: BorderRadius.circular(tokens.radiusFull),
                  ),
                  child: Text(
                    _book.status.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_book.pageCount != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.menu_book, size: 16, color: tokens.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${_book.pageCount} Seiten',
                        style: TextStyle(color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (_book.coverUrl != null && _book.coverUrl!.isNotEmpty) {
      String coverUrl = _book.coverUrl!;
      coverUrl = coverUrl.replaceFirst('http://', 'https://');
      if (coverUrl.contains('zoom=')) {
        coverUrl = coverUrl.replaceFirst(RegExp(r'zoom=\d'), 'zoom=2');
      }
      
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
      );
    }
    return _buildPlaceholderCover();
  }

  Widget _buildPlaceholderCover() {
    final tokens = ref.read(designTokensProvider);
    return Container(
      color: tokens.divider,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 32, color: tokens.textDisabled),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _book.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8, color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status ändern',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusButton(
                BookStatus.wantToRead,
                Icons.bookmark_border,
                tokens,
              ),
              const SizedBox(width: 8),
              _buildStatusButton(
                BookStatus.finished,
                Icons.check_circle_outline,
                tokens,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(BookStatus status, IconData icon, DesignTokens tokens) {
    final isSelected = _book.status == status;
    
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _updateStatus(status),
        icon: Icon(icon),
        label: Text(status.label),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? tokens.primary.withOpacity(0.1) : null,
          foregroundColor: isSelected ? tokens.primary : tokens.textSecondary,
          side: BorderSide(
            color: isSelected ? tokens.primary : tokens.divider,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFinishPrompt(DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: tokens.warning.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.star_border, color: tokens.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Markiere das Buch als "Gelesen" um es zu bewerten.',
                  style: TextStyle(color: tokens.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deine Bewertung',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // 5-Sterne Rating (groß und zentriert)
          Center(
            child: Column(
              children: [
                // Sterne
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _starRating = starValue),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starValue <= _starRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 44,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                // Text-Label
                Text(
                  _getRatingLabel(_starRating),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Notiz-Feld
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Kurze Notiz (optional)',
              hintText: 'Was hat dir besonders gefallen?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
              ),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          
          const SizedBox(height: 16),
          
          // Speichern Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveRating,
              icon: const Icon(Icons.save),
              label: const Text('Bewertung speichern'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Nicht empfehlenswert';
      case 2:
        return 'Geht so';
      case 3:
        return 'Ganz okay';
      case 4:
        return 'Sehr gut';
      case 5:
        return 'Fantastisch!';
      default:
        return '';
    }
  }

  Widget _buildInfoSection(DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informationen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Hinzugefügt', _formatDate(_book.addedAt), tokens),
          if (_book.finishedAt != null)
            _buildInfoRow('Beendet', _formatDate(_book.finishedAt!), tokens),
          if (_book.isbn != null)
            _buildInfoRow('ISBN', _book.isbn!, tokens),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Color _getStatusColor(BookStatus status) {
    final tokens = ref.read(designTokensProvider);
    switch (status) {
      case BookStatus.wantToRead:
        return tokens.info;
      case BookStatus.reading:
        return tokens.warning;
      case BookStatus.finished:
        return tokens.success;
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
    // Konvertiere 1-5 Sterne zu 1-10 für interne Speicherung
    final rating = BookRating(
      overall: _starRating * 2,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    
    final updatedBook = _book.copyWith(rating: rating);
    await ref.read(bookNotifierProvider.notifier).updateBook(updatedBook);
    setState(() => _book = updatedBook);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bewertung gespeichert ⭐')),
      );
    }
  }

  void _confirmDelete() {
    final tokens = ref.read(designTokensProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buch löschen?'),
        content: Text('Möchtest du „${_book.title}" wirklich entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(bookNotifierProvider.notifier).deleteBook(_book.id);
              if (mounted) {
                Navigator.pop(context); // Dialog schließen
                Navigator.pop(context); // Detail-Screen schließen
              }
            },
            style: TextButton.styleFrom(foregroundColor: tokens.error),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
