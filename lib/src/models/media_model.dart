import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Medientyp
enum MediaType {
  movie('Film', '🎬'),
  tvShow('Serie', '📺');

  final String label;
  final String emoji;
  const MediaType(this.label, this.emoji);
}

/// Status eines Medieneintrags
enum MediaStatus {
  watchlist('Merkliste', '📋', 0xFFFFC107),
  watching('Am Schauen', '▶️', 0xFF2196F3),
  watched('Gesehen', '✅', 0xFF4CAF50),
  dropped('Abgebrochen', '❌', 0xFFF44336);

  final String label;
  final String emoji;
  final int colorValue;
  const MediaStatus(this.label, this.emoji, this.colorValue);
}

/// Genre-Kategorien (TMDB Genre IDs)
enum MediaGenre {
  action(28, 'Action', '💥'),
  adventure(12, 'Abenteuer', '🗺️'),
  animation(16, 'Animation', '🎨'),
  comedy(35, 'Komödie', '😂'),
  crime(80, 'Krimi', '🔍'),
  documentary(99, 'Dokumentation', '📹'),
  drama(18, 'Drama', '🎭'),
  family(10751, 'Familie', '👨‍👩‍👧‍👦'),
  fantasy(14, 'Fantasy', '🧙'),
  history(36, 'Geschichte', '📜'),
  horror(27, 'Horror', '👻'),
  music(10402, 'Musik', '🎵'),
  mystery(9648, 'Mystery', '🔮'),
  romance(10749, 'Romanze', '💕'),
  sciFi(878, 'Sci-Fi', '🚀'),
  tvMovie(10770, 'TV-Film', '📺'),
  thriller(53, 'Thriller', '😱'),
  war(10752, 'Krieg', '⚔️'),
  western(37, 'Western', '🤠'),
  // TV-spezifische Genres
  actionAdventure(10759, 'Action & Abenteuer', '🦸'),
  kids(10762, 'Kinder', '👶'),
  news(10763, 'Nachrichten', '📰'),
  reality(10764, 'Reality', '🎥'),
  sciFiFantasy(10765, 'Sci-Fi & Fantasy', '🌌'),
  soap(10766, 'Soap', '📻'),
  talk(10767, 'Talk', '🗣️'),
  warPolitics(10768, 'Krieg & Politik', '🏛️');

  final int tmdbId;
  final String label;
  final String emoji;
  const MediaGenre(this.tmdbId, this.label, this.emoji);

  static MediaGenre? fromTmdbId(int id) {
    try {
      return MediaGenre.values.firstWhere((g) => g.tmdbId == id);
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// PERSON MODEL (Schauspieler, Regisseur)
// ============================================================================

class MediaPerson extends Equatable {
  final int tmdbId;
  final String name;
  final String? profilePath;
  final String? character; // Rolle bei Schauspielern
  final String? job; // Job bei Crew (z.B. "Director")
  final int? order; // Reihenfolge im Cast

  const MediaPerson({
    required this.tmdbId,
    required this.name,
    this.profilePath,
    this.character,
    this.job,
    this.order,
  });

  String? get fullProfileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : null;

  factory MediaPerson.fromJson(Map<String, dynamic> json) {
    return MediaPerson(
      tmdbId: json['id'] as int,
      name: json['name'] as String,
      profilePath: json['profile_path'] as String?,
      character: json['character'] as String?,
      job: json['job'] as String?,
      order: json['order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': tmdbId,
      'name': name,
      'profile_path': profilePath,
      'character': character,
      'job': job,
      'order': order,
    };
  }

  @override
  List<Object?> get props => [tmdbId, name, profilePath, character, job, order];
}

// ============================================================================
// EPISODE MODEL (für Serien)
// ============================================================================

class Episode extends Equatable {
  final int tmdbId;
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final DateTime? airDate;
  final int? runtime; // Minuten
  final double? voteAverage;

  const Episode({
    required this.tmdbId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtime,
    this.voteAverage,
  });

  String? get fullStillUrl => stillPath != null
      ? 'https://image.tmdb.org/t/p/w300$stillPath'
      : null;

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      tmdbId: json['id'] as int,
      seasonNumber: json['season_number'] as int,
      episodeNumber: json['episode_number'] as int,
      name: json['name'] as String,
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      airDate: json['air_date'] != null
          ? DateTime.tryParse(json['air_date'] as String)
          : null,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': tmdbId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'name': name,
      'overview': overview,
      'still_path': stillPath,
      'air_date': airDate?.toIso8601String(),
      'runtime': runtime,
      'vote_average': voteAverage,
    };
  }

  @override
  List<Object?> get props => [tmdbId, seasonNumber, episodeNumber, name];
}

// ============================================================================
// SEASON MODEL
// ============================================================================

class Season extends Equatable {
  final int tmdbId;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final DateTime? airDate;
  final int episodeCount;
  final List<Episode> episodes;

  const Season({
    required this.tmdbId,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.episodeCount = 0,
    this.episodes = const [],
  });

  String? get fullPosterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w185$posterPath'
      : null;

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      tmdbId: json['id'] as int,
      seasonNumber: json['season_number'] as int,
      name: json['name'] as String,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      airDate: json['air_date'] != null
          ? DateTime.tryParse(json['air_date'] as String)
          : null,
      episodeCount: json['episode_count'] as int? ?? 0,
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': tmdbId,
      'season_number': seasonNumber,
      'name': name,
      'overview': overview,
      'poster_path': posterPath,
      'air_date': airDate?.toIso8601String(),
      'episode_count': episodeCount,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [tmdbId, seasonNumber, name];
}

// ============================================================================
// MEDIA ITEM MODEL (Film oder Serie)
// ============================================================================

class MediaItem extends Equatable {
  final int tmdbId;
  final MediaType type;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final List<int> genreIds;
  final DateTime? releaseDate;
  final int? runtime; // Minuten (für Filme)
  final double? voteAverage;
  final int? voteCount;
  final String? originalLanguage;
  
  // Serien-spezifisch
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<Season> seasons;
  final String? status; // "Returning Series", "Ended", etc.
  
  // Credits
  final List<MediaPerson> cast;
  final List<MediaPerson> crew;
  
  // Zusätzliche Infos
  final String? tagline;
  final List<String>? productionCompanies;
  final List<String>? productionCountries;

  const MediaItem({
    required this.tmdbId,
    required this.type,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.genreIds = const [],
    this.releaseDate,
    this.runtime,
    this.voteAverage,
    this.voteCount,
    this.originalLanguage,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.seasons = const [],
    this.status,
    this.cast = const [],
    this.crew = const [],
    this.tagline,
    this.productionCompanies,
    this.productionCountries,
  });

  String? get fullPosterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w342$posterPath'
      : null;

  String? get fullBackdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : null;

  String get year => releaseDate?.year.toString() ?? '';

  List<MediaGenre> get genres => genreIds
      .map((id) => MediaGenre.fromTmdbId(id))
      .where((g) => g != null)
      .cast<MediaGenre>()
      .toList();

  MediaPerson? get director => crew.cast<MediaPerson?>().firstWhere(
        (p) => p?.job == 'Director',
        orElse: () => null,
      );

  List<MediaPerson> get mainCast => cast.take(10).toList();

  factory MediaItem.fromTmdbJson(Map<String, dynamic> json, MediaType type) {
    final isMovie = type == MediaType.movie;
    
    return MediaItem(
      tmdbId: json['id'] as int,
      type: type,
      title: (isMovie ? json['title'] : json['name']) as String? ?? '',
      originalTitle: (isMovie ? json['original_title'] : json['original_name']) as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          (json['genres'] as List<dynamic>?)
              ?.map((e) => (e as Map<String, dynamic>)['id'] as int)
              .toList() ??
          [],
      releaseDate: (isMovie ? json['release_date'] : json['first_air_date']) != null
          ? DateTime.tryParse((isMovie ? json['release_date'] : json['first_air_date']) as String)
          : null,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      originalLanguage: json['original_language'] as String?,
      numberOfSeasons: json['number_of_seasons'] as int?,
      numberOfEpisodes: json['number_of_episodes'] as int?,
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => Season.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String?,
      cast: (json['credits']?['cast'] as List<dynamic>?)
              ?.map((e) => MediaPerson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      crew: (json['credits']?['crew'] as List<dynamic>?)
              ?.map((e) => MediaPerson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tagline: json['tagline'] as String?,
      productionCompanies: (json['production_companies'] as List<dynamic>?)
          ?.map((e) => (e as Map<String, dynamic>)['name'] as String)
          .toList(),
      productionCountries: (json['production_countries'] as List<dynamic>?)
          ?.map((e) => (e as Map<String, dynamic>)['name'] as String)
          .toList(),
    );
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      tmdbId: json['tmdbId'] as int,
      type: MediaType.values.firstWhere((t) => t.name == json['type']),
      title: json['title'] as String,
      originalTitle: json['originalTitle'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      genreIds: (json['genreIds'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'] as String)
          : null,
      runtime: json['runtime'] as int?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: json['voteCount'] as int?,
      originalLanguage: json['originalLanguage'] as String?,
      numberOfSeasons: json['numberOfSeasons'] as int?,
      numberOfEpisodes: json['numberOfEpisodes'] as int?,
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => Season.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String?,
      cast: (json['cast'] as List<dynamic>?)
              ?.map((e) => MediaPerson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      crew: (json['crew'] as List<dynamic>?)
              ?.map((e) => MediaPerson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tagline: json['tagline'] as String?,
      productionCompanies: (json['productionCompanies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      productionCountries: (json['productionCountries'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'type': type.name,
      'title': title,
      'originalTitle': originalTitle,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'genreIds': genreIds,
      'releaseDate': releaseDate?.toIso8601String(),
      'runtime': runtime,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'originalLanguage': originalLanguage,
      'numberOfSeasons': numberOfSeasons,
      'numberOfEpisodes': numberOfEpisodes,
      'seasons': seasons.map((e) => e.toJson()).toList(),
      'status': status,
      'cast': cast.map((e) => e.toJson()).toList(),
      'crew': crew.map((e) => e.toJson()).toList(),
      'tagline': tagline,
      'productionCompanies': productionCompanies,
      'productionCountries': productionCountries,
    };
  }

  @override
  List<Object?> get props => [tmdbId, type, title];
}

// ============================================================================
// BEWERTUNG MODEL
// ============================================================================

class MediaRating extends Equatable {
  final double overall; // 1-10
  final double? story;
  final double? acting;
  final double? atmosphere;
  final double? rewatchFactor;
  final String? notes;

  const MediaRating({
    required this.overall,
    this.story,
    this.acting,
    this.atmosphere,
    this.rewatchFactor,
    this.notes,
  });

  factory MediaRating.fromJson(Map<String, dynamic> json) {
    return MediaRating(
      overall: (json['overall'] as num).toDouble(),
      story: (json['story'] as num?)?.toDouble(),
      acting: (json['acting'] as num?)?.toDouble(),
      atmosphere: (json['atmosphere'] as num?)?.toDouble(),
      rewatchFactor: (json['rewatchFactor'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'story': story,
      'acting': acting,
      'atmosphere': atmosphere,
      'rewatchFactor': rewatchFactor,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [overall, story, acting, atmosphere, rewatchFactor, notes];
}

// ============================================================================
// USER MEDIA ENTRY (Benutzereintrag für Film/Serie)
// ============================================================================

class UserMediaEntry extends Equatable {
  final String id;
  final String oderId;
  final MediaItem media;
  final MediaStatus status;
  final MediaRating? rating;
  
  // Serien-Fortschritt
  final Set<String> watchedEpisodes; // Format: "S01E01"
  final int? currentSeason;
  final int? currentEpisode;
  
  // Zusätzliche Daten
  final DateTime? watchedDate; // Wann gesehen
  final int? watchTimeMinutes; // Wie lange geschaut
  final int? moodAfter; // Stimmung danach (1-10)
  final bool isRewatch;
  final List<String>? watchedWith; // Mit wem
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserMediaEntry({
    required this.id,
    required this.oderId,
    required this.media,
    required this.status,
    this.rating,
    this.watchedEpisodes = const {},
    this.currentSeason,
    this.currentEpisode,
    this.watchedDate,
    this.watchTimeMinutes,
    this.moodAfter,
    this.isRewatch = false,
    this.watchedWith,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Fortschritt für Serien (0.0 - 1.0)
  double get progress {
    if (media.type == MediaType.movie) {
      return status == MediaStatus.watched ? 1.0 : 0.0;
    }
    final total = media.numberOfEpisodes ?? 0;
    if (total == 0) return 0.0;
    return watchedEpisodes.length / total;
  }

  /// Anzahl gesehener Episoden
  int get watchedEpisodeCount => watchedEpisodes.length;

  /// Ist eine Episode gesehen?
  bool isEpisodeWatched(int season, int episode) {
    return watchedEpisodes.contains('S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}');
  }

  UserMediaEntry copyWith({
    String? id,
    String? oderId,
    MediaItem? media,
    MediaStatus? status,
    MediaRating? rating,
    Set<String>? watchedEpisodes,
    int? currentSeason,
    int? currentEpisode,
    DateTime? watchedDate,
    int? watchTimeMinutes,
    int? moodAfter,
    bool? isRewatch,
    List<String>? watchedWith,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserMediaEntry(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      media: media ?? this.media,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      currentSeason: currentSeason ?? this.currentSeason,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      watchedDate: watchedDate ?? this.watchedDate,
      watchTimeMinutes: watchTimeMinutes ?? this.watchTimeMinutes,
      moodAfter: moodAfter ?? this.moodAfter,
      isRewatch: isRewatch ?? this.isRewatch,
      watchedWith: watchedWith ?? this.watchedWith,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserMediaEntry.fromJson(Map<String, dynamic> json) {
    return UserMediaEntry(
      id: json['id'] as String,
      oderId: json['oderId'] as String,
      media: MediaItem.fromJson(json['media'] as Map<String, dynamic>),
      status: MediaStatus.values.firstWhere((s) => s.name == json['status']),
      rating: json['rating'] != null
          ? MediaRating.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
      watchedEpisodes: (json['watchedEpisodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      currentSeason: json['currentSeason'] as int?,
      currentEpisode: json['currentEpisode'] as int?,
      watchedDate: json['watchedDate'] != null
          ? DateTime.tryParse(json['watchedDate'] as String)
          : null,
      watchTimeMinutes: json['watchTimeMinutes'] as int?,
      moodAfter: json['moodAfter'] as int?,
      isRewatch: json['isRewatch'] as bool? ?? false,
      watchedWith: (json['watchedWith'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oderId': oderId,
      'media': media.toJson(),
      'status': status.name,
      'rating': rating?.toJson(),
      'watchedEpisodes': watchedEpisodes.toList(),
      'currentSeason': currentSeason,
      'currentEpisode': currentEpisode,
      'watchedDate': watchedDate?.toIso8601String(),
      'watchTimeMinutes': watchTimeMinutes,
      'moodAfter': moodAfter,
      'isRewatch': isRewatch,
      'watchedWith': watchedWith,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, media.tmdbId, status];
}

// ============================================================================
// MEDIA STATISTICS
// ============================================================================

class MediaStatistics {
  final int totalMovies;
  final int totalTvShows;
  final int watchlistCount;
  final int watchedCount;
  final int watchingCount;
  final double avgRating;
  final Map<MediaGenre, int> genreDistribution;
  final Map<String, int> topActors; // Name -> Anzahl
  final Map<String, int> topDirectors;
  final int totalWatchTimeMinutes;
  final double moviesVsTvRatio;

  const MediaStatistics({
    required this.totalMovies,
    required this.totalTvShows,
    required this.watchlistCount,
    required this.watchedCount,
    required this.watchingCount,
    required this.avgRating,
    required this.genreDistribution,
    required this.topActors,
    required this.topDirectors,
    required this.totalWatchTimeMinutes,
    required this.moviesVsTvRatio,
  });

  factory MediaStatistics.empty() {
    return const MediaStatistics(
      totalMovies: 0,
      totalTvShows: 0,
      watchlistCount: 0,
      watchedCount: 0,
      watchingCount: 0,
      avgRating: 0,
      genreDistribution: {},
      topActors: {},
      topDirectors: {},
      totalWatchTimeMinutes: 0,
      moviesVsTvRatio: 0,
    );
  }

  factory MediaStatistics.calculate(List<UserMediaEntry> entries) {
    if (entries.isEmpty) return MediaStatistics.empty();

    final movies = entries.where((e) => e.media.type == MediaType.movie).toList();
    final tvShows = entries.where((e) => e.media.type == MediaType.tvShow).toList();
    
    final watchlist = entries.where((e) => e.status == MediaStatus.watchlist).length;
    final watched = entries.where((e) => e.status == MediaStatus.watched).length;
    final watching = entries.where((e) => e.status == MediaStatus.watching).length;

    // Durchschnittsbewertung
    final rated = entries.where((e) => e.rating != null).toList();
    final avgRating = rated.isNotEmpty
        ? rated.map((e) => e.rating!.overall).reduce((a, b) => a + b) / rated.length
        : 0.0;

    // Genre-Verteilung
    final genreMap = <MediaGenre, int>{};
    for (final entry in entries) {
      for (final genre in entry.media.genres) {
        genreMap[genre] = (genreMap[genre] ?? 0) + 1;
      }
    }

    // Top Schauspieler
    final actorMap = <String, int>{};
    for (final entry in entries) {
      for (final actor in entry.media.mainCast) {
        actorMap[actor.name] = (actorMap[actor.name] ?? 0) + 1;
      }
    }
    final topActors = Map.fromEntries(
      actorMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10),
    );

    // Top Regisseure
    final directorMap = <String, int>{};
    for (final entry in entries) {
      final director = entry.media.director;
      if (director != null) {
        directorMap[director.name] = (directorMap[director.name] ?? 0) + 1;
      }
    }
    final topDirectors = Map.fromEntries(
      directorMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10),
    );

    // Watch-Zeit
    final totalTime = entries
        .where((e) => e.watchTimeMinutes != null)
        .map((e) => e.watchTimeMinutes!)
        .fold(0, (a, b) => a + b);

    return MediaStatistics(
      totalMovies: movies.length,
      totalTvShows: tvShows.length,
      watchlistCount: watchlist,
      watchedCount: watched,
      watchingCount: watching,
      avgRating: avgRating,
      genreDistribution: genreMap,
      topActors: topActors,
      topDirectors: topDirectors,
      totalWatchTimeMinutes: totalTime,
      moviesVsTvRatio: entries.isNotEmpty ? movies.length / entries.length : 0,
    );
  }

  /// Lieblingsgenre
  MediaGenre? get favoriteGenre {
    if (genreDistribution.isEmpty) return null;
    return genreDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Formatierte Watch-Zeit
  String get formattedWatchTime {
    final hours = totalWatchTimeMinutes ~/ 60;
    final days = hours ~/ 24;
    if (days > 0) return '$days Tage ${hours % 24} Std';
    if (hours > 0) return '$hours Std ${totalWatchTimeMinutes % 60} Min';
    return '$totalWatchTimeMinutes Min';
  }
}
