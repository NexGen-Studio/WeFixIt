import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/services/maintenance_notification_service.dart';
import 'src/services/navigation_service.dart';
import 'src/utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Globale Error Zone: Fängt alle unbehandelten Exceptions ab
  runZonedGuarded(
    () async {
      // Initialisiere Notification Service
      try {
        await MaintenanceNotificationService.initialize();
        print('✅ Notification Service initialisiert');
      } catch (e) {
        print('❌ Fehler beim Initialisieren des Notification Service: $e');
      }
      
      // Initialisiere Navigation Service (für Deep Links von Notifications)
      NavigationService.initialize();
      
      // Flutter Error Handler: Unterdrückt hässliche Error-Screens
      FlutterError.onError = (FlutterErrorDetails details) {
        // Network-Errors nicht loggen (zu viel Spam)
        if (ErrorHandler.isNetworkError(details.exception)) {
          print('🌐 Network-Fehler unterdrückt: ${details.exception}');
          return;
        }
        
        // Andere Fehler nur in Debug-Modus loggen
        if (details.silent) return;
        
        FlutterError.dumpErrorToConsole(details);
      };
      
      runApp(const ProviderScope(child: App()));
    },
    (error, stack) {
      // Unbehandelte async Errors
      if (ErrorHandler.isNetworkError(error)) {
        print('🌐 Async Network-Fehler unterdrückt: $error');
      } else {
        print('❌ Unbehandelter Fehler: $error');
        print('Stack: $stack');
      }
    },
  );
}
