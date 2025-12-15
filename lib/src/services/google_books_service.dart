import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service für die Google Books API
/// Ermöglicht Buchsuche und Cover-Abruf
class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  /// Suche nach Büchern anhand des Titels
  Future<List<GoogleBookResult>> searchBooks(String query, {int maxResults = 10}) async {
    if (query.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl?q=$encodedQuery&maxResults=$maxResults&printType=books';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        
        if (items == null) return [];
        
        return items
            .map((item) => GoogleBookResult.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Google Books API Error: $e');
      return [];
    }
  }

  /// Suche nach Büchern anhand der ISBN
  Future<GoogleBookResult?> searchByIsbn(String isbn) async {
    if (isbn.isEmpty) return null;

    try {
      final url = '$_baseUrl?q=isbn:$isbn';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        
        if (items != null && items.isNotEmpty) {
          return GoogleBookResult.fromJson(items.first as Map<String, dynamic>);
        }
      }
      
      return null;
    } catch (e) {
      print('Google Books API Error: $e');
      return null;
    }
  }

  /// Hole Details zu einem Buch anhand der Google Books ID
  Future<GoogleBookResult?> getBookById(String googleBooksId) async {
    try {
      final url = '$_baseUrl/$googleBooksId';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleBookResult.fromJson(data);
      }
      
      return null;
    } catch (e) {
      print('Google Books API Error: $e');
      return null;
    }
  }
}

/// Ergebnis von der Google Books API
class GoogleBookResult {
  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? thumbnailUrl;
  final String? smallThumbnailUrl;
  final int? pageCount;
  final List<String> categories;
  final String? isbn10;
  final String? isbn13;
  final String? publisher;
  final String? publishedDate;
  final double? averageRating;

  const GoogleBookResult({
    required this.id,
    required this.title,
    this.authors = const [],
    this.description,
    this.thumbnailUrl,
    this.smallThumbnailUrl,
    this.pageCount,
    this.categories = const [],
    this.isbn10,
    this.isbn13,
    this.publisher,
    this.publishedDate,
    this.averageRating,
  });

  /// Primärer Autor
  String get author => authors.isNotEmpty ? authors.first : 'Unbekannt';

  /// Alle Autoren als String
  String get authorsString => authors.join(', ');

  /// Beste verfügbare Cover-URL (mit https und hoher Auflösung)
  String? get bestCoverUrl {
    final url = thumbnailUrl ?? smallThumbnailUrl;
    if (url == null) return null;
    // Google Books liefert manchmal http URLs, wir brauchen https
    String result = url.replaceFirst('http://', 'https://');
    // Edge-Curl Parameter entfernen für bessere Darstellung
    result = result.replaceAll('&edge=curl', '');
    // Höhere Auflösung anfordern
    if (result.contains('zoom=')) {
      result = result.replaceFirst(RegExp(r'zoom=\d'), 'zoom=2');
    }
    return result;
  }

  /// Höher auflösendes Cover (zoom=3 für maximale Qualität)
  String? get highResCoverUrl {
    final url = bestCoverUrl;
    if (url == null) return null;
    // Ersetze zoom mit zoom=3 für höchste Auflösung
    if (url.contains('zoom=')) {
      return url.replaceFirst(RegExp(r'zoom=\d'), 'zoom=3');
    }
    return url;
  }

  /// Original Cover URL ohne Modifikationen (für Fallback)
  String? get originalCoverUrl {
    final url = thumbnailUrl ?? smallThumbnailUrl;
    if (url == null) return null;
    return url.replaceFirst('http://', 'https://');
  }

  factory GoogleBookResult.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final industryIdentifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;

    String? isbn10;
    String? isbn13;
    
    if (industryIdentifiers != null) {
      for (final identifier in industryIdentifiers) {
        final type = identifier['type'] as String?;
        final value = identifier['identifier'] as String?;
        if (type == 'ISBN_10') {
          isbn10 = value;
        } else if (type == 'ISBN_13') {
          isbn13 = value;
        }
      }
    }

    return GoogleBookResult(
      id: json['id'] as String? ?? '',
      title: volumeInfo['title'] as String? ?? 'Unbekannter Titel',
      authors: (volumeInfo['authors'] as List<dynamic>?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      description: volumeInfo['description'] as String?,
      thumbnailUrl: imageLinks?['thumbnail'] as String?,
      smallThumbnailUrl: imageLinks?['smallThumbnail'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      categories: (volumeInfo['categories'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
      isbn10: isbn10,
      isbn13: isbn13,
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      averageRating: (volumeInfo['averageRating'] as num?)?.toDouble(),
    );
  }
}

/// Demo-Service für den Offline-Modus
class DemoGoogleBooksService extends GoogleBooksService {
  static final List<GoogleBookResult> _demoBooks = [
    const GoogleBookResult(
      id: 'demo_1',
      title: 'Der Herr der Ringe',
      authors: ['J.R.R. Tolkien'],
      description: 'Ein episches Fantasy-Epos über den Kampf gegen das Böse.',
      thumbnailUrl: 'https://books.google.com/books/content?id=yl4dILkcqm4C&printsec=frontcover&img=1&zoom=1',
      pageCount: 1200,
      categories: ['Fantasy'],
    ),
    const GoogleBookResult(
      id: 'demo_2',
      title: 'Harry Potter und der Stein der Weisen',
      authors: ['J.K. Rowling'],
      description: 'Der Beginn einer magischen Reise.',
      thumbnailUrl: 'https://books.google.com/books/content?id=wrOQLV6xB-wC&printsec=frontcover&img=1&zoom=1',
      pageCount: 336,
      categories: ['Fantasy', 'Jugendliteratur'],
    ),
    const GoogleBookResult(
      id: 'demo_3',
      title: '1984',
      authors: ['George Orwell'],
      description: 'Eine dystopische Vision der Zukunft.',
      thumbnailUrl: 'https://books.google.com/books/content?id=yxv1LK5gyV4C&printsec=frontcover&img=1&zoom=1',
      pageCount: 328,
      categories: ['Dystopie', 'Klassiker'],
    ),
    const GoogleBookResult(
      id: 'demo_4',
      title: 'Stolz und Vorurteil',
      authors: ['Jane Austen'],
      description: 'Ein Klassiker der englischen Literatur.',
      thumbnailUrl: 'https://books.google.com/books/content?id=s1gVAAAAYAAJ&printsec=frontcover&img=1&zoom=1',
      pageCount: 432,
      categories: ['Klassiker', 'Romanze'],
    ),
    const GoogleBookResult(
      id: 'demo_5',
      title: 'Der kleine Prinz',
      authors: ['Antoine de Saint-Exupéry'],
      description: 'Eine poetische Erzählung über Freundschaft und Liebe.',
      thumbnailUrl: 'https://books.google.com/books/content?id=OL_FDAAAQBAJ&printsec=frontcover&img=1&zoom=1',
      pageCount: 96,
      categories: ['Klassiker', 'Kinderbuch'],
    ),
  ];

  @override
  Future<List<GoogleBookResult>> searchBooks(String query, {int maxResults = 10}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (query.isEmpty) return _demoBooks;
    
    final lowerQuery = query.toLowerCase();
    return _demoBooks.where((book) {
      return book.title.toLowerCase().contains(lowerQuery) ||
          book.authors.any((a) => a.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  @override
  Future<GoogleBookResult?> searchByIsbn(String isbn) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _demoBooks.isNotEmpty ? _demoBooks.first : null;
  }

  @override
  Future<GoogleBookResult?> getBookById(String googleBooksId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _demoBooks.firstWhere(
      (b) => b.id == googleBooksId,
      orElse: () => _demoBooks.first,
    );
  }
}
