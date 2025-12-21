/// Main App Widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../providers/providers.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import '../screens/screens.dart';
import '../screens/onboarding_screen.dart';

class StatMeApp extends ConsumerWidget {
  const StatMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    // Neues Theme-System - Design Tokens basiert
    final tokens = ref.watch(designTokensProvider);
    
    return MaterialApp(
      title: 'StatMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromTokens(tokens),
      themeMode: ThemeMode.light, // Theme wird durch Tokens gesteuert
      home: authState.when(
        data: (user) {
          // In demo mode, auto-login with demo user
          if (AppConfig.isDemoMode && user == null) {
            // Trigger auto-login for demo mode
            Future.microtask(() {
              ref.read(authNotifierProvider.notifier).signIn('demo@statme.app', 'demo');
            });
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Demo-Modus wird geladen...'),
                  ],
                ),
              ),
            );
          }
          
          if (user != null) {
            // Prüfe ob Onboarding für diesen User abgeschlossen ist
            return _UserHomeScreen(userId: user.id);
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(authNotifierProvider);
                  },
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Separate Widget um user-spezifisches Onboarding zu handhaben
class _UserHomeScreen extends ConsumerWidget {
  final String userId;
  
  const _UserHomeScreen({required this.userId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Automatische Datenmigration beim Login triggern
    ref.watch(autoMigrationProvider(userId));
    
    final onboardingComplete = ref.watch(userOnboardingProvider(userId));
    
    if (!onboardingComplete) {
      return OnboardingScreen(
        onComplete: () {
          // Force rebuild
          ref.invalidate(userOnboardingProvider(userId));
        },
      );
    }
    
    return const MainNavigationScreen();
  }
}
