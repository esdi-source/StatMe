/// StatMe App Configuration
/// Manages demo mode and environment settings

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static AppConfig? _instance;
  
  // ============================================
  // PRODUCTION FALLBACK VALUES
  // Diese werden verwendet wenn keine .env Datei vorhanden ist
  // ============================================
  static const String _prodSupabaseUrl = 'https://uycmnojefmpepyolgkih.supabase.co';
  static const String _prodSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5Y21ub2plZm1wZXB5b2xna2loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MzczODAsImV4cCI6MjA4MTMxMzM4MH0.8bcHqiV2uMLZFWzAv4iv77SLnF0hbmaWBzf0-cWF-xA';
  // ============================================
  
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
    
    bool envLoaded = false;
    try {
      await dotenv.load(fileName: '.env');
      envLoaded = true;
    } catch (e) {
      // .env file not found, use production fallbacks
      print('Info: .env file not found, using production fallbacks');
    }
    
    // Wenn .env geladen wurde, verwende die Werte daraus
    // Ansonsten verwende die Production Fallbacks (NICHT Demo-Modus!)
    final envDemoMode = dotenv.env['DEMO_MODE']?.toLowerCase();
    final useDemoMode = envLoaded 
        ? (envDemoMode == 'true' || envDemoMode == '1' || envDemoMode == 'yes')
        : false; // Kein Demo-Modus wenn keine .env (= Production Build)
    
    _instance = AppConfig._()
      ..demoMode = useDemoMode
      ..supabaseUrl = dotenv.env['SUPABASE_URL'] ?? _prodSupabaseUrl
      ..supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? _prodSupabaseAnonKey
      ..supabaseServiceKey = dotenv.env['SUPABASE_SERVICE_KEY']
      ..openaiApiKey = dotenv.env['OPENAI_API_KEY']
      ..openFoodFactsBaseUrl = dotenv.env['OPENFOODFACTS_BASEURL'] ?? 'https://world.openfoodfacts.org/api/v2'
      ..edamamAppId = dotenv.env['EDAMAM_APP_ID']
      ..edamamAppKey = dotenv.env['EDAMAM_APP_KEY'];
    
    print('AppConfig initialized: demoMode=${_instance!.demoMode}, supabaseUrl=${_instance!.supabaseUrl}');
  }
}
