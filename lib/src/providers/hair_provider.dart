import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ============================================
// HAIR PROVIDERS
// ============================================

class HairCareEntriesNotifier extends StateNotifier<List<HairCareEntry>> {
  final String userId;
  
  HairCareEntriesNotifier(this.userId) : super([]);
  
  HairCareEntry? getForDate(DateTime date) {
    // TODO: Implement
    return null;
  }
  
  Future<void> addOrUpdate(HairCareEntry entry) async {
    // TODO: Implement
  }
}

final hairCareEntriesProvider = StateNotifierProvider.family<HairCareEntriesNotifier, List<HairCareEntry>, String>((ref, userId) {
  return HairCareEntriesNotifier(userId);
});

class HairEventsNotifier extends StateNotifier<List<HairEvent>> {
  final String userId;
  
  HairEventsNotifier(this.userId) : super([]);
  
  Future<void> delete(String eventId) async {
    // TODO: Implement
  }
  
  Future<void> add(HairEvent event) async {
    // TODO: Implement
  }
}

final hairEventsProvider = StateNotifierProvider.family<HairEventsNotifier, List<HairEvent>, String>((ref, userId) {
  return HairEventsNotifier(userId);
});

class HairProductsNotifier extends StateNotifier<List<HairProduct>> {
  final String userId;
  HairProductsNotifier(this.userId) : super([]);
  
  Future<void> add(HairProduct product) async {}
  Future<void> update(HairProduct product) async {}
  Future<void> delete(String id) async {}
}

final hairProductsProvider = StateNotifierProvider.family<HairProductsNotifier, List<HairProduct>, String>((ref, userId) {
  return HairProductsNotifier(userId);
});

class HairCareStatisticsNotifier extends StateNotifier<HairCareStatistics> {
  final String userId;
  
  HairCareStatisticsNotifier(this.userId) : super(HairCareStatistics.empty());
}

final hairCareStatisticsProvider = StateNotifierProvider.family<HairCareStatisticsNotifier, HairCareStatistics, String>((ref, userId) {
  return HairCareStatisticsNotifier(userId);
});
