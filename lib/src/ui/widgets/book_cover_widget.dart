/// Book Cover Widget
/// Intelligentes Cover-Widget mit Ladezustand, Fallback und Retry-Option
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/book_model.dart';
import '../../services/book_cover_service.dart';

/// Provider für Cover-Fetch-Status pro Buch
final bookCoverProvider = FutureProvider.family<CoverFetchResult, BookModel>((ref, book) async {
  return BookCoverService.fetchCover(
    bookId: book.id,
    existingCoverUrl: book.coverUrl,
    isbn: book.isbn,
    googleBooksId: book.googleBooksId,
    title: book.title,
    author: book.author,
  );
});

/// Widget für Buchcover mit intelligenter Ladung und Fallback
class BookCoverWidget extends ConsumerStatefulWidget {
  final BookModel book;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool showRetryButton;
  final bool showUploadButton;
  final bool showSourceBadge;
  final VoidCallback? onCoverUpdated;

  const BookCoverWidget({
    super.key,
    required this.book,
    this.width = 100,
    this.height = 150,
    this.borderRadius,
    this.showRetryButton = false,
    this.showUploadButton = false,
    this.showSourceBadge = false,
    this.onCoverUpdated,
  });

  @override
  ConsumerState<BookCoverWidget> createState() => _BookCoverWidgetState();
}

class _BookCoverWidgetState extends ConsumerState<BookCoverWidget> {
  bool _isRetrying = false;
  bool _isUploading = false;
  // String? _errorMessage;
  CoverFetchResult? _localResult;

  @override
  Widget build(BuildContext context) {
    final coverAsync = ref.watch(bookCoverProvider(widget.book));

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: _buildContent(coverAsync),
      ),
    );
  }

  Widget _buildContent(AsyncValue<CoverFetchResult> coverAsync) {
    // Lokales Ergebnis hat Vorrang (nach Retry/Upload)
    if (_localResult != null && _localResult!.hasValidCover) {
      return _buildCoverImage(_localResult!.coverUrl!, _localResult!.source);
    }

    // Lade-/Upload-Zustand
    if (_isRetrying || _isUploading) {
      return _buildLoadingState();
    }

    return coverAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (result) {
        if (result.hasValidCover) {
          return _buildCoverImage(result.coverUrl!, result.source);
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          if (_isUploading) ...[
            const SizedBox(height: 8),
            Text(
              'Hochladen...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      color: Colors.red.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 32),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Fehler',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.showRetryButton)
            TextButton(
              onPressed: _retry,
              child: const Text('Erneut', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      color: primaryColor.withOpacity(0.1),
      child: Stack(
        children: [
          // Zentrierter Inhalt
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: widget.width * 0.35,
                  color: primaryColor.withOpacity(0.4),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.book.title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: primaryColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          if (widget.showRetryButton || widget.showUploadButton)
            Positioned(
              right: 4,
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showRetryButton)
                    _buildActionButton(
                      icon: Icons.refresh,
                      tooltip: 'Cover suchen',
                      onTap: _retry,
                    ),
                  if (widget.showUploadButton) ...[
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.upload,
                      tooltip: 'Cover hochladen',
                      onTap: _uploadCover,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, size: 14, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildCoverImage(String url, String? source) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),

        // Source Badge
        if (widget.showSourceBadge && source != null)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getSourceLabel(source),
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Retry/Upload Buttons bei bestehendem Cover
        if (widget.showRetryButton || widget.showUploadButton)
          Positioned(
            right: 4,
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showRetryButton)
                  _buildActionButton(
                    icon: Icons.refresh,
                    tooltip: 'Neues Cover suchen',
                    onTap: _retry,
                  ),
                if (widget.showUploadButton) ...[
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.upload,
                    tooltip: 'Cover hochladen',
                    onTap: _uploadCover,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'google_books':
        return 'Google';
      case 'open_library':
        return 'OpenLib';
      case 'user_upload':
        return 'Eigenes';
      case 'cached':
        return 'Cache';
      default:
        return source;
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      // _errorMessage = null;
    });

    try {
      // Cache löschen
      await BookCoverService.clearCache(widget.book.id);

      // Neu laden
      final result = await BookCoverService.fetchCover(
        bookId: widget.book.id,
        isbn: widget.book.isbn,
        googleBooksId: widget.book.googleBooksId,
        title: widget.book.title,
        author: widget.book.author,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _localResult = result;
          _isRetrying = false;
        });

        // Provider invalidieren für globales Update
        ref.invalidate(bookCoverProvider(widget.book));

        if (result.hasValidCover) {
          widget.onCoverUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cover gefunden (${_getSourceLabel(result.source ?? 'unbekannt')})'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kein Cover gefunden'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRetrying = false;
          // _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _uploadCover() async {
    if (_isUploading) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      // TODO: Hier würde der Upload zu Supabase Storage erfolgen
      // Für jetzt nur lokale Anzeige
      
      final localFile = File(pickedFile.path);
      
      // Simuliere kurze Verzögerung
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isUploading = false;
          // Lokales File als Cover verwenden
          _localResult = CoverFetchResult.success(
            coverUrl: localFile.path,
            source: 'user_upload',
          );
        });

        widget.onCoverUpdated?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover hochgeladen'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }
}

/// Kompaktes Cover-Widget für Listen (ohne Buttons)
class CompactBookCover extends ConsumerWidget {
  final BookModel book;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const CompactBookCover({
    super.key,
    required this.book,
    this.width = 60,
    this.height = 90,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookCoverWidget(
      book: book,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showRetryButton: false,
      showUploadButton: false,
      showSourceBadge: false,
    );
  }
}

/// Cover-Widget für Detail-Ansicht (mit allen Optionen)
class DetailBookCover extends ConsumerWidget {
  final BookModel book;
  final double width;
  final double height;
  final VoidCallback? onCoverUpdated;

  const DetailBookCover({
    super.key,
    required this.book,
    this.width = 120,
    this.height = 180,
    this.onCoverUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookCoverWidget(
      book: book,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(12),
      showRetryButton: true,
      showUploadButton: true,
      showSourceBadge: true,
      onCoverUpdated: onCoverUpdated,
    );
  }
}
