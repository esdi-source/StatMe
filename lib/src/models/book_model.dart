import 'package:equatable/equatable.dart';

/// Status eines Buches
enum BookStatus {
  wantToRead('Möchte lesen'),
  reading('Lese gerade'),
  finished('Gelesen');

  final String label;
  const BookStatus(this.label);
}

/// Bewertungskategorien für gelesene Bücher
class BookRating extends Equatable {
  final int overall; // 1-10 Gesamtbewertung
  final int? story; // Geschichte
  final int? characters; // Charaktere
  final int? writing; // Schreibstil
  final int? pacing; // Tempo
  final int? emotionalImpact; // Emotionale Wirkung
  final String? note; // Kurzer Satz / Notiz

  const BookRating({
    required this.overall,
    this.story,
    this.characters,
    this.writing,
    this.pacing,
    this.emotionalImpact,
    this.note,
  });

  factory BookRating.fromJson(Map<String, dynamic> json) {
    return BookRating(
      overall: json['overall'] as int? ?? 5,
      story: json['story'] as int?,
      characters: json['characters'] as int?,
      writing: json['writing'] as int?,
      pacing: json['pacing'] as int?,
      emotionalImpact: json['emotional_impact'] as int?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'story': story,
      'characters': characters,
      'writing': writing,
      'pacing': pacing,
      'emotional_impact': emotionalImpact,
      'note': note,
    };
  }

  BookRating copyWith({
    int? overall,
    int? story,
    int? characters,
    int? writing,
    int? pacing,
    int? emotionalImpact,
    String? note,
  }) {
    return BookRating(
      overall: overall ?? this.overall,
      story: story ?? this.story,
      characters: characters ?? this.characters,
      writing: writing ?? this.writing,
      pacing: pacing ?? this.pacing,
      emotionalImpact: emotionalImpact ?? this.emotionalImpact,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [overall, story, characters, writing, pacing, emotionalImpact, note];
}

/// Ein Buch in der Bibliothek
class BookModel extends Equatable {
  final String id;
  final String oderId; // User ID
  final String title;
  final String? author;
  final String? coverUrl; // URL zum Buchcover
  final String? googleBooksId; // ID von Google Books API
  final String? isbn;
  final BookStatus status;
  final BookRating? rating; // Nur für gelesene Bücher
  final DateTime addedAt;
  final DateTime? finishedAt;
  final int? pageCount;

  const BookModel({
    required this.id,
    required this.oderId,
    required this.title,
    this.author,
    this.coverUrl,
    this.googleBooksId,
    this.isbn,
    this.status = BookStatus.wantToRead,
    this.rating,
    required this.addedAt,
    this.finishedAt,
    this.pageCount,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      coverUrl: json['cover_url'] as String?,
      googleBooksId: json['google_books_id'] as String?,
      isbn: json['isbn'] as String?,
      status: BookStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BookStatus.wantToRead,
      ),
      rating: json['rating'] != null
          ? BookRating.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
      addedAt: DateTime.parse(json['added_at'] as String),
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      pageCount: json['page_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'google_books_id': googleBooksId,
      'isbn': isbn,
      'status': status.name,
      'rating': rating?.toJson(),
      'added_at': addedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'page_count': pageCount,
    };
  }

  BookModel copyWith({
    String? id,
    String? oderId,
    String? title,
    String? author,
    String? coverUrl,
    String? googleBooksId,
    String? isbn,
    BookStatus? status,
    BookRating? rating,
    DateTime? addedAt,
    DateTime? finishedAt,
    int? pageCount,
  }) {
    return BookModel(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      googleBooksId: googleBooksId ?? this.googleBooksId,
      isbn: isbn ?? this.isbn,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      addedAt: addedAt ?? this.addedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        oderId,
        title,
        author,
        coverUrl,
        googleBooksId,
        isbn,
        status,
        rating,
        addedAt,
        finishedAt,
        pageCount,
      ];
}

/// Leseziel und Tracking
class ReadingGoalModel extends Equatable {
  final String id;
  final String oderId;
  final int weeklyGoalMinutes; // Wochenziel in Minuten
  final int readMinutesThisWeek; // Gelesene Minuten diese Woche
  final DateTime weekStartDate; // Start der aktuellen Woche
  final List<ReadingSession> sessions; // Lese-Sessions

  const ReadingGoalModel({
    required this.id,
    required this.oderId,
    required this.weeklyGoalMinutes,
    this.readMinutesThisWeek = 0,
    required this.weekStartDate,
    this.sessions = const [],
  });

  /// Verbleibende Minuten diese Woche
  int get remainingMinutes => (weeklyGoalMinutes - readMinutesThisWeek).clamp(0, weeklyGoalMinutes);

  /// Fortschritt in Prozent
  double get progressPercent => weeklyGoalMinutes > 0
      ? (readMinutesThisWeek / weeklyGoalMinutes).clamp(0.0, 1.0)
      : 0.0;

  /// Formatierte Anzeige des Ziels
  String get formattedGoal {
    final hours = weeklyGoalMinutes ~/ 60;
    final minutes = weeklyGoalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  /// Formatierte Anzeige der gelesenen Zeit
  String get formattedRead {
    final hours = readMinutesThisWeek ~/ 60;
    final minutes = readMinutesThisWeek % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  factory ReadingGoalModel.fromJson(Map<String, dynamic> json) {
    return ReadingGoalModel(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      weeklyGoalMinutes: json['weekly_goal_minutes'] as int? ?? 240,
      readMinutesThisWeek: json['read_minutes_this_week'] as int? ?? 0,
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => ReadingSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'weekly_goal_minutes': weeklyGoalMinutes,
      'read_minutes_this_week': readMinutesThisWeek,
      'week_start_date': weekStartDate.toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  ReadingGoalModel copyWith({
    String? id,
    String? oderId,
    int? weeklyGoalMinutes,
    int? readMinutesThisWeek,
    DateTime? weekStartDate,
    List<ReadingSession>? sessions,
  }) {
    return ReadingGoalModel(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      readMinutesThisWeek: readMinutesThisWeek ?? this.readMinutesThisWeek,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  List<Object?> get props => [id, oderId, weeklyGoalMinutes, readMinutesThisWeek, weekStartDate, sessions];
}

/// Eine einzelne Lese-Session
class ReadingSession extends Equatable {
  final String id;
  final DateTime date;
  final int durationMinutes;
  final String? bookId; // Optional: Welches Buch wurde gelesen

  const ReadingSession({
    required this.id,
    required this.date,
    required this.durationMinutes,
    this.bookId,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['duration_minutes'] as int,
      bookId: json['book_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'book_id': bookId,
    };
  }

  @override
  List<Object?> get props => [id, date, durationMinutes, bookId];
}
