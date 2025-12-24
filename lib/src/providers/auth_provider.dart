import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

// ============================================
// AUTH PROVIDERS
// ============================================

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoAuthRepository();
  }
  return SupabaseAuthRepository(Supabase.instance.client);
});

/// Current User Provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

/// Auth State Notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;
  
  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _init();
  }
  
  Future<void> _init() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  
  Future<void> signUp(String email, String password, String? displayName) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUp(email, password, displayName);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
