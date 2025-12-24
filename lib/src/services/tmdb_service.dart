/// TMDB API Service - The Movie Database
/// Für Film- und Serien-Metadaten
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_model.dart';

class TmdbService {
  // TMDB API Key (kostenlos registrierbar auf themoviedb.org)
  static const String _apiKey = '2a8d8f6c8d8f6c8d8f6c8d8f6c8d8f6c'; // Platzhalter
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _language = 'de-DE';

  /// Suche nach Filmen
  static Future<List<MediaItem>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&language=$_language&query=${Uri.encodeComponent(query)}&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.movie))
            .toList();
      }
    } catch (e) {
      print('TMDB searchMovies error: $e');
    }
    return [];
  }

  /// Suche nach Serien
  static Future<List<MediaItem>> searchTvShows(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/tv?api_key=$_apiKey&language=$_language&query=${Uri.encodeComponent(query)}&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.tvShow))
            .toList();
      }
    } catch (e) {
      print('TMDB searchTvShows error: $e');
    }
    return [];
  }

  /// Suche nach allem (Multi-Search)
  static Future<List<MediaItem>> searchMulti(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/multi?api_key=$_apiKey&language=$_language&query=${Uri.encodeComponent(query)}&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .where((json) => json['media_type'] == 'movie' || json['media_type'] == 'tv')
            .map((json) {
              final type = json['media_type'] == 'movie' ? MediaType.movie : MediaType.tvShow;
              return MediaItem.fromTmdbJson(json as Map<String, dynamic>, type);
            })
            .toList();
      }
    } catch (e) {
      print('TMDB searchMulti error: $e');
    }
    return [];
  }

  /// Film-Details mit Credits
  static Future<MediaItem?> getMovieDetails(int tmdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$tmdbId?api_key=$_apiKey&language=$_language&append_to_response=credits'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MediaItem.fromTmdbJson(data as Map<String, dynamic>, MediaType.movie);
      }
    } catch (e) {
      print('TMDB getMovieDetails error: $e');
    }
    return null;
  }

  /// Serien-Details mit Credits
  static Future<MediaItem?> getTvShowDetails(int tmdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$tmdbId?api_key=$_apiKey&language=$_language&append_to_response=credits'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MediaItem.fromTmdbJson(data as Map<String, dynamic>, MediaType.tvShow);
      }
    } catch (e) {
      print('TMDB getTvShowDetails error: $e');
    }
    return null;
  }

  /// Staffel-Details mit Episoden
  static Future<Season?> getSeasonDetails(int tvId, int seasonNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$tvId/season/$seasonNumber?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Season.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      print('TMDB getSeasonDetails error: $e');
    }
    return null;
  }

  /// Trending Filme
  static Future<List<MediaItem>> getTrendingMovies({String timeWindow = 'week'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/movie/$timeWindow?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.movie))
            .toList();
      }
    } catch (e) {
      print('TMDB getTrendingMovies error: $e');
    }
    return [];
  }

  /// Trending Serien
  static Future<List<MediaItem>> getTrendingTvShows({String timeWindow = 'week'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/tv/$timeWindow?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.tvShow))
            .toList();
      }
    } catch (e) {
      print('TMDB getTrendingTvShows error: $e');
    }
    return [];
  }

  /// Populäre Filme
  static Future<List<MediaItem>> getPopularMovies({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey&language=$_language&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.movie))
            .toList();
      }
    } catch (e) {
      print('TMDB getPopularMovies error: $e');
    }
    return [];
  }

  /// Populäre Serien
  static Future<List<MediaItem>> getPopularTvShows({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/popular?api_key=$_apiKey&language=$_language&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.tvShow))
            .toList();
      }
    } catch (e) {
      print('TMDB getPopularTvShows error: $e');
    }
    return [];
  }

  /// Person-Details (Schauspieler/Regisseur)
  static Future<Map<String, dynamic>?> getPersonDetails(int personId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/person/$personId?api_key=$_apiKey&language=$_language&append_to_response=combined_credits'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('TMDB getPersonDetails error: $e');
    }
    return null;
  }

  /// Filme einer Person
  static Future<List<MediaItem>> getPersonMovies(int personId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/person/$personId/movie_credits?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cast = data['cast'] as List<dynamic>;
        return cast
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.movie))
            .toList();
      }
    } catch (e) {
      print('TMDB getPersonMovies error: $e');
    }
    return [];
  }

  /// Ähnliche Filme
  static Future<List<MediaItem>> getSimilarMovies(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId/similar?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.movie))
            .toList();
      }
    } catch (e) {
      print('TMDB getSimilarMovies error: $e');
    }
    return [];
  }

  /// Ähnliche Serien
  static Future<List<MediaItem>> getSimilarTvShows(int tvId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$tvId/similar?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => MediaItem.fromTmdbJson(json as Map<String, dynamic>, MediaType.tvShow))
            .toList();
      }
    } catch (e) {
      print('TMDB getSimilarTvShows error: $e');
    }
    return [];
  }

  /// Genre-Liste für Filme
  static Future<Map<int, String>> getMovieGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/movie/list?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final genres = data['genres'] as List<dynamic>;
        return {
          for (var g in genres)
            (g as Map<String, dynamic>)['id'] as int: g['name'] as String
        };
      }
    } catch (e) {
      print('TMDB getMovieGenres error: $e');
    }
    return {};
  }

  /// Genre-Liste für Serien
  static Future<Map<int, String>> getTvGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/tv/list?api_key=$_apiKey&language=$_language'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final genres = data['genres'] as List<dynamic>;
        return {
          for (var g in genres)
            (g as Map<String, dynamic>)['id'] as int: g['name'] as String
        };
      }
    } catch (e) {
      print('TMDB getTvGenres error: $e');
    }
    return {};
  }
}
