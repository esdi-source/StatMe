import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'provider_utils.dart';

// ============================================
// SLEEP PROVIDERS
// ============================================

/// Sleep Repository Provider
final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSleepRepository();
  }
  return SupabaseSleepRepository(Supabase.instance.client);
});

final sleepProvider = FutureProvider.family<SleepLogModel?, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return await repo.getSleep(params.userId, params.date);
});

final sleepRangeProvider = FutureProvider.family<List<SleepLogModel>, ({String userId, DateTime start, DateTime end})>((ref, params) async {
  final repo = ref.watch(sleepRepositoryProvider);
  return await repo.getSleepRange(params.userId, params.start, params.end);
});

class SleepNotifier extends StateNotifier<SleepLogModel?> {
  final SleepRepository _repository;
  
  SleepNotifier(this._repository) : super(null);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getSleep(userId, date);
  }
  
  Future<void> upsert(SleepLogModel log) async {
    state = await _repository.upsertSleep(log);
    await logWidgetEvent('sleep', 'updated', {
      'id': state?.id,
      'duration': log.durationMinutes / 60,
      'quality': log.quality,
      'date': log.startTs.toIso8601String(),
    });
  }
  
  Future<void> delete(String userId, DateTime date) async {
    await _repository.deleteSleepByDate(userId, date);
    state = null;
    await logWidgetEvent('sleep', 'deleted', {
      'date': date.toIso8601String(),
    });
  }
}

final sleepNotifierProvider = StateNotifierProvider<SleepNotifier, SleepLogModel?>((ref) {
  final repo = ref.watch(sleepRepositoryProvider);
  return SleepNotifier(repo);
});
