import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/misc/missing_env_screen.dart';
import 'src/services/maintenance_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisiere Notification Service
  try {
    await MaintenanceNotificationService.initialize();
    print('✅ Notification Service initialisiert');
  } catch (e) {
    print('❌ Fehler beim Initialisieren des Notification Service: $e');
  }
  
  runApp(const ProviderScope(child: App()));
}
