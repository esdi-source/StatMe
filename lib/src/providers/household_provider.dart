import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ============================================
// HOUSEHOLD PROVIDERS
// ============================================

class HouseholdTasksNotifier extends StateNotifier<List<HouseholdTask>> {
  final String userId;
  
  HouseholdTasksNotifier(this.userId) : super([]);
  
  Future<void> add(HouseholdTask task) async {}
  Future<void> update(HouseholdTask task) async {}
  Future<void> delete(String id) async {}
}

final householdTasksProvider = StateNotifierProvider.family<HouseholdTasksNotifier, List<HouseholdTask>, String>((ref, userId) {
  return HouseholdTasksNotifier(userId);
});

class HouseholdCompletionsNotifier extends StateNotifier<List<TaskCompletion>> {
  final String userId;
  
  HouseholdCompletionsNotifier(this.userId) : super([]);
  
  Future<void> add(TaskCompletion completion) async {}
}

final householdCompletionsProvider = StateNotifierProvider.family<HouseholdCompletionsNotifier, List<TaskCompletion>, String>((ref, userId) {
  return HouseholdCompletionsNotifier(userId);
});

final householdStatisticsProvider = Provider.family<HouseholdStatistics, String>((ref, userId) {
  return HouseholdStatistics.empty();
});
