import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

// ============================================
// SETTINGS PROVIDERS
// ============================================

/// Settings Repository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSettingsRepository();
  }
  return SupabaseSettingsRepository(Supabase.instance.client);
});

final settingsProvider = FutureProvider.family<SettingsModel?, String>((ref, userId) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings(userId);
});

class SettingsNotifier extends StateNotifier<SettingsModel?> {
  final SettingsRepository _repository;
  
  SettingsNotifier(this._repository) : super(null);
  
  Future<void> load(String userId) async {
    state = await _repository.getSettings(userId);
  }
  
  Future<void> update(SettingsModel settings) async {
    state = await _repository.updateSettings(settings);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsModel?>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

// ============================================
// THEME COLOR PROVIDER
// ============================================

/// Provider für die aktuelle Theme-Farbe
final themeColorProvider = StateProvider<Color>((ref) {
  // Default Sage (Salbei) - passend zu den neuen Pastell-Farben
  return const Color(0xFFB2C9AD);
});

/// Provider der die Theme-Farbe aus den Settings synchronisiert
final themeColorFromSettingsProvider = Provider<Color>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  if (settings != null && settings.themeColorValue != 0) {
    return Color(settings.themeColorValue);
  }
  return const Color(0xFFB2C9AD);
});
