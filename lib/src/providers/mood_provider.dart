import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

// ============================================
// MOOD PROVIDERS
// ============================================

/// Mood Repository Provider
final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoMoodRepository();
  }
  return SupabaseMoodRepository(Supabase.instance.client);
});

final moodProvider = FutureProvider.family<MoodLogModel?, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(moodRepositoryProvider);
  return await repo.getMood(params.userId, params.date);
});

final moodRangeProvider = FutureProvider.family<List<MoodLogModel>, ({String userId, DateTime start, DateTime end})>((ref, params) async {
  final repo = ref.watch(moodRepositoryProvider);
  return await repo.getMoodRange(params.userId, params.start, params.end);
});

class MoodNotifier extends StateNotifier<MoodLogModel?> {
  final MoodRepository _repository;
  
  MoodNotifier(this._repository) : super(null);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getMood(userId, date);
  }
  
  Future<void> upsert(MoodLogModel log) async {
    state = await _repository.upsertMood(log);
  }
}

final moodNotifierProvider = StateNotifierProvider<MoodNotifier, MoodLogModel?>((ref) {
  return MoodNotifier(ref.watch(moodRepositoryProvider));
});

/// Mood History Notifier for statistics
class MoodHistoryNotifier extends StateNotifier<List<MoodLogModel>> {
  final MoodRepository _repository;
  
  MoodHistoryNotifier(this._repository) : super([]);
  
  Future<void> loadRange(String userId, DateTime start, DateTime end) async {
    state = await _repository.getMoodRange(userId, start, end);
  }
}

final moodHistoryProvider = StateNotifierProvider<MoodHistoryNotifier, List<MoodLogModel>>((ref) {
  return MoodHistoryNotifier(ref.watch(moodRepositoryProvider));
});
