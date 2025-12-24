import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/book_model.dart';
import '../repositories/repositories.dart';
import '../services/google_books_service.dart';

// ============================================
// GOOGLE BOOKS PROVIDER
// ============================================

/// Google Books Service Provider
final googleBooksServiceProvider = Provider<GoogleBooksService>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoGoogleBooksService();
  }
  return GoogleBooksService();
});

/// Book Repository Provider
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoBookRepository();
  }
  return SupabaseBookRepository(Supabase.instance.client);
});

// ============================================
// BOOK PROVIDERS
// ============================================

/// Book Notifier for managing user's book library
class BookNotifier extends StateNotifier<List<BookModel>> {
  final BookRepository _repository;
  
  BookNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    state = await _repository.getBooks(userId);
  }
  
  Future<void> addBook(BookModel book) async {
    final newBook = await _repository.addBook(book);
    state = [...state, newBook];
  }
  
  Future<void> updateBook(BookModel book) async {
    final updated = await _repository.updateBook(book);
    state = state.map((b) => b.id == book.id ? updated : b).toList();
  }
  
  Future<void> deleteBook(String bookId) async {
    await _repository.deleteBook(bookId);
    state = state.where((b) => b.id != bookId).toList();
  }
}

final bookNotifierProvider = StateNotifierProvider<BookNotifier, List<BookModel>>((ref) {
  return BookNotifier(ref.watch(bookRepositoryProvider));
});

/// Reading Goal Notifier
class ReadingGoalNotifier extends StateNotifier<ReadingGoalModel?> {
  final BookRepository _repository;
  
  ReadingGoalNotifier(this._repository) : super(null);
  
  Future<void> load(String userId) async {
    state = await _repository.getReadingGoal(userId);
    
    // Create default goal if none exists
    if (state == null) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      state = ReadingGoalModel(
        id: userId,
        oderId: userId,
        weeklyGoalMinutes: 240, // 4 hours default
        readMinutesThisWeek: 0,
        weekStartDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      );
      await _repository.upsertReadingGoal(state!);
    }
  }
  
  Future<void> updateGoal(ReadingGoalModel goal) async {
    state = await _repository.upsertReadingGoal(goal);
  }
  
  Future<void> addReadingSession(String oderId, ReadingSession session) async {
    await _repository.addReadingSession(oderId, session);
    // Reload to get updated state
    await load(oderId);
  }
}

final readingGoalNotifierProvider = StateNotifierProvider<ReadingGoalNotifier, ReadingGoalModel?>((ref) {
  return ReadingGoalNotifier(ref.watch(bookRepositoryProvider));
});
