import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'provider_utils.dart';

// ============================================
// STEPS PROVIDERS
// ============================================

/// Steps Repository Provider
final stepsRepositoryProvider = Provider<StepsRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoStepsRepository();
  }
  return SupabaseStepsRepository(Supabase.instance.client);
});

final stepsProvider = FutureProvider.family<StepsLogModel?, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(stepsRepositoryProvider);
  return await repo.getSteps(params.userId, params.date);
});

final stepsRangeProvider = FutureProvider.family<List<StepsLogModel>, ({String userId, DateTime start, DateTime end})>((ref, params) async {
  final repo = ref.watch(stepsRepositoryProvider);
  return await repo.getStepsRange(params.userId, params.start, params.end);
});

class StepsNotifier extends StateNotifier<StepsLogModel?> {
  final StepsRepository _repository;
  
  StepsNotifier(this._repository) : super(null);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getSteps(userId, date);
  }
  
  Future<void> upsert(StepsLogModel log) async {
    state = await _repository.upsertSteps(log);
    await logWidgetEvent('steps', 'updated', {
      'id': state?.id,
      'steps': log.steps,
      'date': log.date.toIso8601String(),
    });
  }
}

final stepsNotifierProvider = StateNotifierProvider<StepsNotifier, StepsLogModel?>((ref) {
  return StepsNotifier(ref.watch(stepsRepositoryProvider));
});
