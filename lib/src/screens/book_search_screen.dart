/// Book Search Screen - Search and add books using Google Books API

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/book_model.dart';
import '../services/google_books_service.dart';

class BookSearchScreen extends ConsumerStatefulWidget {
  const BookSearchScreen({super.key});

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final _searchController = TextEditingController();
  List<GoogleBookResult> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(googleBooksServiceProvider);
      final results = await service.searchBooks(query, maxResults: 20);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler bei der Suche: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buch suchen'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Titel, Autor oder ISBN eingeben...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          // Search Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _search,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Suche...' : 'Suchen'),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Error Message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          
          // Results
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Suche nach einem Buch',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final book = _searchResults[index];
                      return _buildSearchResultCard(book);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(GoogleBookResult book) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showAddBookDialog(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.bestCoverUrl != null
                    ? Image.network(
                        book.bestCoverUrl!,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorsString.isNotEmpty ? book.authorsString : 'Unbekannter Autor',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (book.publishedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.publishedDate!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (book.pageCount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${book.pageCount} Seiten',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Add Icon
              const Icon(Icons.add_circle_outline, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey.shade200,
      child: Icon(Icons.menu_book, color: Colors.grey.shade400),
    );
  }

  void _showAddBookDialog(GoogleBookResult book) {
    BookStatus selectedStatus = BookStatus.wantToRead;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buch hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Info
              Row(
                children: [
                  if (book.bestCoverUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        book.bestCoverUrl!,
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          book.author,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Zu welcher Liste hinzufügen?'),
              const SizedBox(height: 12),
              // Status Selection
              ...BookStatus.values.map((status) {
                return RadioListTile<BookStatus>(
                  title: Text(status.label),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedStatus = value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => _addBook(book, selectedStatus),
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBook(GoogleBookResult book, BookStatus status) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final newBook = BookModel(
      id: '', // Will be generated
      oderId: user.id,
      title: book.title,
      author: book.authorsString,
      coverUrl: book.highResCoverUrl,
      googleBooksId: book.id,
      isbn: book.isbn13 ?? book.isbn10,
      status: status,
      addedAt: DateTime.now(),
      pageCount: book.pageCount,
    );

    await ref.read(bookNotifierProvider.notifier).addBook(newBook);
    
    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\"${book.title}\" zur ${status.label}-Liste hinzugefügt'),
        ),
      );
    }
  }
}
