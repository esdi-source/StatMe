import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ============================================
// MEDIA PROVIDERS
// ============================================

class UserMediaEntriesNotifier extends StateNotifier<List<UserMediaEntry>> {
  final String userId;
  
  UserMediaEntriesNotifier(this.userId) : super([]);
  
  Future<void> add(UserMediaEntry entry) async {}
  Future<void> update(UserMediaEntry entry) async {}
  Future<void> delete(String id) async {}
}

final userMediaEntriesProvider = StateNotifierProvider.family<UserMediaEntriesNotifier, List<UserMediaEntry>, String>((ref, userId) {
  return UserMediaEntriesNotifier(userId);
});
