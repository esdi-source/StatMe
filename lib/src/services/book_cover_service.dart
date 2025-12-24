/// Book Cover Service
/// Priorisierte Cover-Ermittlung mit Kaskade und Caching
/// 
/// Reihenfolge:
/// 1. Lokaler Cache (gecachte CDN-URL)
/// 2. Google Books API
/// 3. Open Library Covers API
/// 4. Placeholder
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Status eines Cover-Fetch-Vorgangs
enum CoverFetchStatus {
  pending,
  loading,
  success,
  notFound,
  error,
}

/// Ergebnis eines Cover-Fetch-Vorgangs
class CoverFetchResult {
  final CoverFetchStatus status;
  final String? coverUrl;
  final String? source;
  final String? error;
  final DateTime? fetchedAt;
  final double? confidence;

  const CoverFetchResult({
    required this.status,
    this.coverUrl,
    this.source,
    this.error,
    this.fetchedAt,
    this.confidence,
  });

  bool get hasValidCover => status == CoverFetchStatus.success && coverUrl != null;

  factory CoverFetchResult.loading() => const CoverFetchResult(status: CoverFetchStatus.loading);
  
  factory CoverFetchResult.notFound() => const CoverFetchResult(status: CoverFetchStatus.notFound);
  
  factory CoverFetchResult.error(String message) => CoverFetchResult(
    status: CoverFetchStatus.error,
    error: message,
  );

  factory CoverFetchResult.success({
    required String coverUrl,
    String? source,
    double? confidence,
  }) => CoverFetchResult(
    status: CoverFetchStatus.success,
    coverUrl: coverUrl,
    source: source,
    confidence: confidence,
    fetchedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'coverUrl': coverUrl,
    'source': source,
    'error': error,
    'fetchedAt': fetchedAt?.toIso8601String(),
    'confidence': confidence,
  };

  factory CoverFetchResult.fromJson(Map<String, dynamic> json) {
    return CoverFetchResult(
      status: CoverFetchStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CoverFetchStatus.pending,
      ),
      coverUrl: json['coverUrl'] as String?,
      source: json['source'] as String?,
      error: json['error'] as String?,
      fetchedAt: json['fetchedAt'] != null 
          ? DateTime.parse(json['fetchedAt'] as String)
          : null,
      confidence: json['confidence'] as double?,
    );
  }
}

/// Service für Buchcover-Ermittlung
class BookCoverService {
  static const String _cacheKeyPrefix = 'book_cover_';
  static const Duration _cacheDuration = Duration(days: 30);
  static const Duration _failureCacheDuration = Duration(days: 7);
  
  /// ISBN normalisieren
  static String? normalizeIsbn(String? isbn) {
    if (isbn == null || isbn.isEmpty) return null;
    return isbn.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
  }

  /// ISBN-10 zu ISBN-13 konvertieren
  static String? isbn10To13(String isbn10) {
    final normalized = normalizeIsbn(isbn10);
    if (normalized == null || normalized.length != 10) return null;

    final base = '978${normalized.substring(0, 9)}';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.parse(base[i]);
      sum += i.isEven ? digit : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return '$base$checkDigit';
  }

  /// ISBN-13 zu ISBN-10 konvertieren
  static String? isbn13To10(String isbn13) {
    final normalized = normalizeIsbn(isbn13);
    if (normalized == null || normalized.length != 13) return null;
    if (!normalized.startsWith('978')) return null;

    final base = normalized.substring(3, 12);
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(base[i]) * (10 - i);
    }
    final remainder = (11 - (sum % 11)) % 11;
    final checkDigit = remainder == 10 ? 'X' : remainder.toString();
    return '$base$checkDigit';
  }

  /// Alle ISBN-Varianten für ein Buch generieren
  static List<String> getAllIsbnVariants(String? isbn) {
    final variants = <String>{};
    
    void addVariants(String? isbnValue) {
      if (isbnValue == null) return;
      final normalized = normalizeIsbn(isbnValue);
      if (normalized == null) return;
      
      variants.add(normalized);
      
      if (normalized.length == 10) {
        final isbn13 = isbn10To13(normalized);
        if (isbn13 != null) variants.add(isbn13);
      } else if (normalized.length == 13) {
        final isbn10 = isbn13To10(normalized);
        if (isbn10 != null) variants.add(isbn10);
      }
    }

    addVariants(isbn);
    return variants.toList();
  }

  /// Cover aus Cache laden
  static Future<CoverFetchResult?> getFromCache(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$bookId';
      final cached = prefs.getString(cacheKey);
      
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final result = CoverFetchResult.fromJson(data);
        
        // Prüfe ob Cache noch gültig
        if (result.fetchedAt != null) {
          final age = DateTime.now().difference(result.fetchedAt!);
          final maxAge = result.hasValidCover ? _cacheDuration : _failureCacheDuration;
          
          if (age < maxAge) {
            return result;
          }
        }
      }
    } catch (e) {
      // Cache-Fehler ignorieren
    }
    return null;
  }

  /// Ergebnis in Cache speichern
  static Future<void> saveToCache(String bookId, CoverFetchResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$bookId';
      await prefs.setString(cacheKey, jsonEncode(result.toJson()));
    } catch (e) {
      // Cache-Fehler ignorieren
    }
  }

  /// Cover von Google Books API laden
  static Future<CoverFetchResult?> fetchFromGoogleBooks({
    String? isbn,
    String? googleBooksId,
    String? title,
    String? author,
  }) async {
    try {
      // Zuerst per ISBN versuchen
      if (isbn != null) {
        final variants = getAllIsbnVariants(isbn);
        for (final isbnVariant in variants) {
          final url = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbnVariant';
          final response = await http.get(Uri.parse(url));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>?;
            
            if (items != null && items.isNotEmpty) {
              final volumeInfo = items[0]['volumeInfo'] as Map<String, dynamic>?;
              final imageLinks = volumeInfo?['imageLinks'] as Map<String, dynamic>?;
              
              if (imageLinks != null) {
                String? coverUrl = imageLinks['extraLarge'] as String? ??
                    imageLinks['large'] as String? ??
                    imageLinks['medium'] as String? ??
                    imageLinks['thumbnail'] as String?;
                
                if (coverUrl != null) {
                  coverUrl = coverUrl
                      .replaceFirst('http://', 'https://')
                      .replaceAll('&edge=curl', '')
                      .replaceFirst(RegExp(r'zoom=\d'), 'zoom=3');
                  
                  return CoverFetchResult.success(
                    coverUrl: coverUrl,
                    source: 'google_books',
                    confidence: 1.0,
                  );
                }
              }
            }
          }
        }
      }

      // Per Google Books ID versuchen
      if (googleBooksId != null) {
        final url = 'https://www.googleapis.com/books/v1/volumes/$googleBooksId';
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final volumeInfo = data['volumeInfo'] as Map<String, dynamic>?;
          final imageLinks = volumeInfo?['imageLinks'] as Map<String, dynamic>?;
          
          if (imageLinks != null) {
            String? coverUrl = imageLinks['extraLarge'] as String? ??
                imageLinks['large'] as String? ??
                imageLinks['medium'] as String? ??
                imageLinks['thumbnail'] as String?;
            
            if (coverUrl != null) {
              coverUrl = coverUrl
                  .replaceFirst('http://', 'https://')
                  .replaceAll('&edge=curl', '')
                  .replaceFirst(RegExp(r'zoom=\d'), 'zoom=3');
              
              return CoverFetchResult.success(
                coverUrl: coverUrl,
                source: 'google_books',
                confidence: 1.0,
              );
            }
          }
        }
      }

      // Per Titel + Autor versuchen
      if (title != null && title.isNotEmpty) {
        var query = 'intitle:${Uri.encodeComponent(title)}';
        if (author != null && author.isNotEmpty) {
          query += '+inauthor:${Uri.encodeComponent(author)}';
        }
        
        final url = 'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=5';
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>?;
          
          if (items != null && items.isNotEmpty) {
            for (final item in items) {
              final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;
              final imageLinks = volumeInfo?['imageLinks'] as Map<String, dynamic>?;
              
              if (imageLinks != null) {
                String? coverUrl = imageLinks['extraLarge'] as String? ??
                    imageLinks['large'] as String? ??
                    imageLinks['medium'] as String? ??
                    imageLinks['thumbnail'] as String?;
                
                if (coverUrl != null) {
                  coverUrl = coverUrl
                      .replaceFirst('http://', 'https://')
                      .replaceAll('&edge=curl', '')
                      .replaceFirst(RegExp(r'zoom=\d'), 'zoom=3');
                  
                  // Titel-Match prüfen für Confidence
                  final resultTitle = volumeInfo?['title'] as String? ?? '';
                  final titleMatch = resultTitle.toLowerCase().contains(title.toLowerCase());
                  
                  return CoverFetchResult.success(
                    coverUrl: coverUrl,
                    source: 'google_books',
                    confidence: titleMatch ? 0.85 : 0.7,
                  );
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // Fehler loggen aber weitermachen
      print('Google Books error: $e');
    }
    
    return null;
  }

  /// Cover von Open Library laden
  static Future<CoverFetchResult?> fetchFromOpenLibrary({
    String? isbn,
  }) async {
    if (isbn == null) return null;

    try {
      final variants = getAllIsbnVariants(isbn);
      
      for (final isbnVariant in variants) {
        // Direkte Cover URL
        final coverUrl = 'https://covers.openlibrary.org/b/isbn/$isbnVariant-L.jpg';
        
        // HEAD-Request um zu prüfen ob Cover existiert
        final response = await http.head(Uri.parse(coverUrl));
        
        if (response.statusCode == 200) {
          final contentLength = response.headers['content-length'];
          // Open Library gibt 1x1 Pixel (~807 bytes) für fehlende Cover zurück
          if (contentLength != null && int.parse(contentLength) > 1000) {
            return CoverFetchResult.success(
              coverUrl: coverUrl,
              source: 'open_library',
              confidence: 1.0,
            );
          }
        }
      }

      // Fallback: API-Abfrage
      for (final isbnVariant in variants) {
        final url = 'https://openlibrary.org/api/books?bibkeys=ISBN:$isbnVariant&format=json&jscmd=data';
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final bookData = data['ISBN:$isbnVariant'] as Map<String, dynamic>?;
          
          if (bookData != null) {
            final cover = bookData['cover'] as Map<String, dynamic>?;
            if (cover != null) {
              final coverUrl = (cover['large'] ?? cover['medium']) as String?;
              if (coverUrl != null) {
                return CoverFetchResult.success(
                  coverUrl: coverUrl.replaceFirst('http://', 'https://'),
                  source: 'open_library',
                  confidence: 1.0,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('Open Library error: $e');
    }
    
    return null;
  }

  /// Hauptmethode: Cover für ein Buch ermitteln
  /// Versucht Quellen in priorisierter Reihenfolge
  static Future<CoverFetchResult> fetchCover({
    required String bookId,
    String? existingCoverUrl,
    String? isbn,
    String? googleBooksId,
    String? title,
    String? author,
    bool forceRefresh = false,
  }) async {
    // 1. Bestehende URL verwenden wenn vorhanden und nicht refresh erzwungen
    if (!forceRefresh && existingCoverUrl != null && existingCoverUrl.isNotEmpty) {
      return CoverFetchResult.success(
        coverUrl: existingCoverUrl,
        source: 'cached',
      );
    }

    // 2. Cache prüfen
    if (!forceRefresh) {
      final cached = await getFromCache(bookId);
      if (cached != null) {
        return cached;
      }
    }

    // 3. Quellen in priorisierter Reihenfolge versuchen

    // 3a. Google Books
    var result = await fetchFromGoogleBooks(
      isbn: isbn,
      googleBooksId: googleBooksId,
      title: title,
      author: author,
    );
    if (result != null && result.hasValidCover) {
      await saveToCache(bookId, result);
      return result;
    }

    // 3b. Open Library
    result = await fetchFromOpenLibrary(isbn: isbn);
    if (result != null && result.hasValidCover) {
      await saveToCache(bookId, result);
      return result;
    }

    // Kein Cover gefunden
    final notFoundResult = CoverFetchResult.notFound();
    await saveToCache(bookId, notFoundResult);
    return notFoundResult;
  }

  /// Cache für ein bestimmtes Buch löschen
  static Future<void> clearCache(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cacheKeyPrefix$bookId');
    } catch (e) {
      // Ignorieren
    }
  }

  /// Gesamten Cover-Cache löschen
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignorieren
    }
  }
}
