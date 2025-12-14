/// StatMe App Entry Point
/// Health and productivity tracking application

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/config/app_config.dart';
import 'src/services/in_memory_database.dart';
import 'src/ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for localization
  await initializeDateFormatting('de_DE', null);
  await initializeDateFormatting('en_US', null);
  
  // Initialize FFI for desktop platforms (SQLite support) - only on non-web
  if (!kIsWeb) {
    // Dynamic import for desktop-only packages
    await _initDesktopDatabase();
  }
  
  // Initialize app configuration from .env
  await AppConfig.initialize();
  
  // Initialize based on mode
  if (AppConfig.isDemoMode) {
    print('🎮 Running in DEMO MODE - No external connections');
    await InMemoryDatabase().initialize();
  } else {
    print('🚀 Running in PRODUCTION MODE - Connecting to Supabase');
    await Supabase.initialize(
      url: AppConfig.instance.supabaseUrl!,
      anonKey: AppConfig.instance.supabaseAnonKey!,
    );
  }
  
  runApp(
    const ProviderScope(
      child: StatMeApp(),
    ),
  );
}

Future<void> _initDesktopDatabase() async {
  // This is only called on non-web platforms
  // SQLite FFI initialization would go here for desktop
  // For now, we use InMemoryDatabase which works everywhere
}
