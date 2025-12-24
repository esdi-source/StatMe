import '../core/config/app_config.dart';
import '../services/supabase_data_service.dart';

/// Zentrale Event-Logging Funktion für alle Provider
Future<void> logWidgetEvent(String widgetName, String eventType, Map<String, dynamic> payload) async {
  if (AppConfig.isDemoMode) return;
  try {
    await SupabaseDataService.instance.logEvent(
      widgetName: widgetName,
      eventType: eventType,
      payload: payload,
    );
  } catch (e) {
    print('Error logging event: $e');
  }
}
