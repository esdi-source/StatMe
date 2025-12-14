/// StatMe App Configuration
/// Manages demo mode and environment settings

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static AppConfig? _instance;
  
  late final bool demoMode;
  late final String? supabaseUrl;
  late final String? supabaseAnonKey;
  late final String? supabaseServiceKey;
  late final String? openaiApiKey;
  late final String openFoodFactsBaseUrl;
  late final String? edamamAppId;
  late final String? edamamAppKey;
  
  AppConfig._();
  
  static AppConfig get instance {
    if (_instance == null) {
      throw StateError('AppConfig not initialized. Call AppConfig.initialize() first.');
    }
    return _instance!;
  }
  
  static bool get isDemoMode => instance.demoMode;
  
  static Future<void> initialize() async {
    if (_instance != null) return;
    
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file not found, use defaults (demo mode)
      print('Warning: .env file not found, using demo mode defaults');
    }
    
    _instance = AppConfig._()
      ..demoMode = _getBool('DEMO_MODE', defaultValue: true)
      ..supabaseUrl = dotenv.env['SUPABASE_URL']
      ..supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']
      ..supabaseServiceKey = dotenv.env['SUPABASE_SERVICE_KEY']
      ..openaiApiKey = dotenv.env['OPENAI_API_KEY']
      ..openFoodFactsBaseUrl = dotenv.env['OPENFOODFACTS_BASEURL'] ?? 'https://world.openfoodfacts.org/api/v2'
      ..edamamAppId = dotenv.env['EDAMAM_APP_ID']
      ..edamamAppKey = dotenv.env['EDAMAM_APP_KEY'];
    
    print('AppConfig initialized: demoMode=${_instance!.demoMode}');
  }
  
  static bool _getBool(String key, {bool defaultValue = false}) {
    final value = dotenv.env[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }
}
