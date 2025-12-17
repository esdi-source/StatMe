/// Book Detail Screen - View and edit book details with extended ratings
/// Features: 5-star overall rating + optional detailed categories

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/book_model.dart';
import '../ui/widgets/book_cover_widget.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  late BookModel _book;
  
  // Ratings (intern 1-10, angezeigt als 1-5 Sterne)
  int _overallRating = 6; // 3 Sterne
  int? _storyRating;
  int? _charactersRating;
  int? _writingRating;
  int? _pacingRating;
  int? _emotionalRating;
  
  bool _showDetailedRatings = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    if (_book.rating != null) {
      _overallRating = _book.rating!.overall;
      _storyRating = _book.rating!.story;
      _charactersRating = _book.rating!.characters;
      _writingRating = _book.rating!.writing;
      _pacingRating = _book.rating!.pacing;
      _emotionalRating = _book.rating!.emotionalImpact;
      _noteController.text = _book.rating!.note ?? '';
      
      // Zeige Detail-Ratings wenn vorhanden
      _showDetailedRatings = _storyRating != null || 
                            _charactersRating != null || 
                            _writingRating != null;
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
            _buildHeader(tokens),
            _buildQuickActions(tokens),
            const Divider(height: 32),
            
            if (_book.status == BookStatus.finished)
              _buildRatingSection(tokens)
            else
              _buildFinishPrompt(tokens),
            
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
          // Neues Cover-Widget mit Retry und Upload
          DetailBookCover(
            book: _book,
            width: 100,
            height: 150,
            onCoverUpdated: () {
              // Buch neu laden um aktualisiertes Cover zu erhalten
              setState(() {});
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _book.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_book.author != null) ...[
                  const SizedBox(height: 4),
                  Text(_book.author!, style: TextStyle(fontSize: 16, color: tokens.textSecondary)),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_book.status),
                    borderRadius: BorderRadius.circular(tokens.radiusFull),
                  ),
                  child: Text(
                    _book.status.label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                if (_book.pageCount != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.menu_book, size: 16, color: tokens.textSecondary),
                      const SizedBox(width: 4),
                      Text('${_book.pageCount} Seiten', style: TextStyle(color: tokens.textSecondary)),
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

  Widget _buildQuickActions(DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status ändern', style: TextStyle(fontWeight: FontWeight.bold, color: tokens.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusButton(BookStatus.wantToRead, Icons.bookmark_border, tokens),
              const SizedBox(width: 8),
              _buildStatusButton(BookStatus.finished, Icons.check_circle_outline, tokens),
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
          side: BorderSide(color: isSelected ? tokens.primary : tokens.divider),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: tokens.textPrimary),
          ),
          const SizedBox(height: 20),
          
          // Gesamtbewertung (5 Sterne)
          _buildMainRating(tokens),
          
          const SizedBox(height: 24),
          
          // Toggle für Detail-Bewertungen
          _buildDetailedRatingsToggle(tokens),
          
          // Detail-Bewertungen
          if (_showDetailedRatings) ...[
            const SizedBox(height: 20),
            _buildDetailedRatings(tokens),
          ],
          
          const SizedBox(height: 24),
          
          // Notiz
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Kurze Notiz (optional)',
              hintText: 'Was hat dir besonders gefallen?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusSmall)),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          
          const SizedBox(height: 16),
          
          // Speichern
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveRating,
              icon: const Icon(Icons.save),
              label: const Text('Bewertung speichern'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRating(DesignTokens tokens) {
    final starRating = (_overallRating / 2).round();
    
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _overallRating = starValue * 2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starValue <= starRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 44,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(starRating),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRatingsToggle(DesignTokens tokens) {
    return InkWell(
      onTap: () => setState(() => _showDetailedRatings = !_showDetailedRatings),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.divider),
        ),
        child: Row(
          children: [
            Icon(
              _showDetailedRatings ? Icons.expand_less : Icons.expand_more,
              color: tokens.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detaillierte Bewertung',
                    style: TextStyle(fontWeight: FontWeight.bold, color: tokens.textPrimary),
                  ),
                  Text(
                    _showDetailedRatings 
                        ? 'Bewerte einzelne Kategorien' 
                        : 'Geschichte, Charaktere, Schreibstil...',
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: _showDetailedRatings,
              onChanged: (value) => setState(() => _showDetailedRatings = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatings(DesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        children: [
          _buildCategoryRating('Geschichte', Icons.auto_stories, _storyRating, 
              (v) => setState(() => _storyRating = v), tokens),
          const SizedBox(height: 16),
          _buildCategoryRating('Charaktere', Icons.people, _charactersRating, 
              (v) => setState(() => _charactersRating = v), tokens),
          const SizedBox(height: 16),
          _buildCategoryRating('Schreibstil', Icons.edit, _writingRating, 
              (v) => setState(() => _writingRating = v), tokens),
          const SizedBox(height: 16),
          _buildCategoryRating('Tempo', Icons.speed, _pacingRating, 
              (v) => setState(() => _pacingRating = v), tokens),
          const SizedBox(height: 16),
          _buildCategoryRating('Emotionale Wirkung', Icons.favorite, _emotionalRating, 
              (v) => setState(() => _emotionalRating = v), tokens),
        ],
      ),
    );
  }

  Widget _buildCategoryRating(String label, IconData icon, int? value, 
      Function(int?) onChanged, DesignTokens tokens) {
    final starValue = value != null ? (value / 2).round() : 0;
    
    return Row(
      children: [
        Icon(icon, color: tokens.textSecondary, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(color: tokens.textPrimary, fontSize: 13)),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(5, (index) {
              final sv = index + 1;
              return GestureDetector(
                onTap: () => onChanged(value == sv * 2 ? null : sv * 2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    sv <= starValue ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: tokens.textPrimary)),
          const SizedBox(height: 16),
          
          if (_book.isbn != null)
            _buildInfoRow('ISBN', _book.isbn!, Icons.barcode_reader, tokens),
          
          _buildInfoRow('Hinzugefügt', _formatDate(_book.addedAt), Icons.calendar_today, tokens),
          
          if (_book.finishedAt != null)
            _buildInfoRow('Beendet', _formatDate(_book.finishedAt!), Icons.check_circle, tokens),
          
          if (_book.googleBooksId != null)
            _buildInfoRow('Google Books ID', _book.googleBooksId!, Icons.cloud, tokens),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, DesignTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tokens.textSecondary),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: tokens.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: tokens.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getRatingLabel(int stars) {
    switch (stars) {
      case 1: return 'Schlecht';
      case 2: return 'Okay';
      case 3: return 'Gut';
      case 4: return 'Sehr gut';
      case 5: return 'Ausgezeichnet';
      default: return '';
    }
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
    setState(() {
      _book = _book.copyWith(
        status: status,
        finishedAt: status == BookStatus.finished ? DateTime.now() : null,
      );
    });
    await ref.read(bookNotifierProvider.notifier).updateBook(_book);
  }

  Future<void> _saveRating() async {
    final rating = BookRating(
      overall: _overallRating,
      story: _showDetailedRatings ? _storyRating : null,
      characters: _showDetailedRatings ? _charactersRating : null,
      writing: _showDetailedRatings ? _writingRating : null,
      pacing: _showDetailedRatings ? _pacingRating : null,
      emotionalImpact: _showDetailedRatings ? _emotionalRating : null,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    final updatedBook = _book.copyWith(rating: rating);
    await ref.read(bookNotifierProvider.notifier).updateBook(updatedBook);
    
    setState(() => _book = updatedBook);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bewertung gespeichert!')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buch löschen?'),
        content: Text('Möchtest du „${_book.title}" wirklich aus deiner Bibliothek entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(bookNotifierProvider.notifier).deleteBook(_book.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
