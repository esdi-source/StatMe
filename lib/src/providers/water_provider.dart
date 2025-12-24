import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'provider_utils.dart';

// ============================================
// WATER PROVIDERS
// ============================================

/// Water Repository Provider
final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoWaterRepository();
  }
  return SupabaseWaterRepository(Supabase.instance.client);
});

final waterLogsProvider = FutureProvider.family<List<WaterLogModel>, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(waterRepositoryProvider);
  return await repo.getWaterLogs(params.userId, params.date);
});

final totalWaterProvider = FutureProvider.family<int, ({String userId, DateTime date})>((ref, params) async {
  final repo = ref.watch(waterRepositoryProvider);
  return await repo.getTotalWater(params.userId, params.date);
});

class WaterLogNotifier extends StateNotifier<List<WaterLogModel>> {
  final WaterRepository _repository;
  
  WaterLogNotifier(this._repository) : super([]);
  
  Future<void> load(String userId, DateTime date) async {
    state = await _repository.getWaterLogs(userId, date);
  }
  
  Future<void> add(WaterLogModel log) async {
    final added = await _repository.addWaterLog(log);
    state = [...state, added];
    await logWidgetEvent('water', 'log_added', {
      'id': added.id,
      'ml': added.ml,
      'date': added.date.toIso8601String(),
    });
  }
  
  Future<void> delete(String logId) async {
    await _repository.deleteWaterLog(logId);
    state = state.where((w) => w.id != logId).toList();
    await logWidgetEvent('water', 'log_deleted', {'id': logId});
  }
  
  int get totalMl => state.fold(0, (sum, log) => sum + log.ml);
}

final waterLogNotifierProvider = StateNotifierProvider<WaterLogNotifier, List<WaterLogModel>>((ref) {
  return WaterLogNotifier(ref.watch(waterRepositoryProvider));
});
