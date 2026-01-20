import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();

  factory AppConfigService() {
    return _instance;
  }

  AppConfigService._internal();

  late String _admobAppId = '';
  late String _admobBanner320x50 = '';
  late String _revenuecatKey = '';

  // Getter
  String get admobAppId => _admobAppId;
  String get admobBanner320x50 => _admobBanner320x50;
  String get revenuecatKey => _revenuecatKey;

  /// Lade Config vom Backend (Supabase Edge Function)
  Future<void> initialize() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'get-app-config',
      );

      if (response != null) {
        final data = response as Map<String, dynamic>;
        
        // Extrahiere AdMob Config
        final admob = data['admob'] as Map<String, dynamic>? ?? {};
        _admobAppId = admob['appId'] ?? '';
        _admobBanner320x50 = admob['banner320x50'] ?? '';

        // Extrahiere RevenueCat Config
        final revenuecat = data['revenuecat'] as Map<String, dynamic>? ?? {};
        _revenuecatKey = revenuecat['publicSdkKey'] ?? '';

        print('✅ App Config geladen');
        print('AdMob App ID: $_admobAppId');
        print('RevenueCat Key: ${_revenuecatKey.isNotEmpty ? '***' : 'NICHT GESETZT'}');
      }
    } catch (e) {
      print('⚠️ Fehler beim Laden der App Config: $e');
      // Fallback auf Dart-Defines oder Defaults
      _loadFallbackConfig();
    }
  }

  /// Fallback: Lade aus Dart-Defines (für Development)
  void _loadFallbackConfig() {
    _admobAppId = const String.fromEnvironment('ADMOB_APP_ID_ANDROID', defaultValue: '');
    _admobBanner320x50 = const String.fromEnvironment('ADMOB_BANNER_320x50_ANDROID', defaultValue: '');
    _revenuecatKey = const String.fromEnvironment('REVENUECAT_PUBLIC_SDK_KEY_ANDROID', defaultValue: '');
  }
}
