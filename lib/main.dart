import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/misc/missing_env_screen.dart';
import 'src/services/maintenance_notification_service.dart';
import 'src/services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisiere Notification Service
  try {
    await MaintenanceNotificationService.initialize();
    print('✅ Notification Service initialisiert');
  } catch (e) {
    print('❌ Fehler beim Initialisieren des Notification Service: $e');
  }
  
  // Initialisiere Navigation Service (für Deep Links von Notifications)
  NavigationService.initialize();
  
  runApp(const ProviderScope(child: App()));
}
