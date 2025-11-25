import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';

/// Service für Navigation von nativen Notifications
class NavigationService {
  static const _channel = MethodChannel('com.example.wefixit/navigation');
  static GoRouter? _router;
  static String? _pendingRoute;
  
  /// Initialisiert den Navigation Service
  static void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
    print('✅ Navigation Service initialisiert');
  }
  
  /// Setzt den Router (wird von App aufgerufen)
  static void setRouter(GoRouter router) {
    _router = router;
    print('✅ Router gesetzt für Navigation Service');

    // Falls noch eine Route aus nativer Benachrichtigung aussteht → jetzt navigieren
    if (_pendingRoute != null && isSupabaseInitialized()) {
      final route = _pendingRoute!;
      _pendingRoute = null;
      print('🔁 Navigiere aus pendingRoute: $route');
      _router!.go(route);
    }
  }
  
  /// Gibt eine ausstehende Route zurück und löscht sie.
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Behandelt Method Calls vom nativen Code
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('📱 Navigation Service: ${call.method} with ${call.arguments}');
    
    switch (call.method) {
      case 'navigate':
        final route = call.arguments as String?;
        if (route == null) {
          print('⚠️ Route null - keine Navigation');
          return false;
        }

        final shouldCache = _router == null || !isSupabaseInitialized();
        if (shouldCache) {
          print('🕒 Supabase/Router noch nicht bereit - speichere Route: $route');
          _pendingRoute = route;
        }

        if (_router != null) {
          try {
            print('🔄 Navigiere zu: $route');
            _router!.go(route);
            if (!shouldCache) {
              _pendingRoute = null;
            }
            return true;
          } catch (e) {
            print('⚠️ Fehler bei Navigation: $e');
          }
        }

        return false;
      default:
        throw PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }
}
