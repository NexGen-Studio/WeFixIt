import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Service für Error Logging in Supabase
class ErrorLoggingService {
  final _supabase = Supabase.instance.client;

  /// Logge einen Fehler in Supabase
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? screen,
    String? errorCode,
    Map<String, dynamic>? context,
    String severity = 'medium',
  }) async {
    try {
      final user = _supabase.auth.currentUser;

      // Device Info sammeln
      final deviceInfo = {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'isDebug': kDebugMode,
      };

      await _supabase.from('error_logs').insert({
        'user_id': user?.id,
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        'screen': screen,
        'error_code': errorCode,
        'device_info': deviceInfo,
        'context': context,
        'severity': severity,
      });

      if (kDebugMode) {
        print('✅ Error logged to Supabase: $errorType');
      }
    } catch (e) {
      // Fehler beim Loggen sollte nicht die App crashen
      if (kDebugMode) {
        print('❌ Failed to log error to Supabase: $e');
      }
    }
  }

  /// Helper: Logge AI Diagnosis Fehler
  Future<void> logAiDiagnosisError({
    required String errorMessage,
    required String errorCode,
    String? stackTrace,
  }) async {
    await logError(
      errorType: 'ai_diagnosis_error',
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      screen: 'ai_diagnosis_detail',
      errorCode: errorCode,
      severity: 'high', // AI Fehler sind wichtig
      context: {
        'feature': 'ai_diagnosis',
        'action': 'analyze_code',
      },
    );
  }

  /// Helper: Logge OBD2 Connection Fehler
  Future<void> logObd2Error({
    required String errorMessage,
    String? stackTrace,
  }) async {
    await logError(
      errorType: 'obd2_connection_error',
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      screen: 'diagnose',
      severity: 'medium',
      context: {
        'feature': 'obd2_diagnosis',
        'action': 'connect',
      },
    );
  }

  /// Helper: Logge kritische Fehler
  Future<void> logCriticalError({
    required String errorMessage,
    required String screen,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await logError(
      errorType: 'critical_error',
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      screen: screen,
      severity: 'critical', // Trigger Benachrichtigung
      context: context,
    );
  }

  /// Hole Error Logs für aktuellen User (für Debug-Screen)
  Future<List<Map<String, dynamic>>> getUserErrorLogs({int limit = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('error_logs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch error logs: $e');
      }
      return [];
    }
  }

  /// Error Statistics (für Admin Dashboard)
  Future<List<Map<String, dynamic>>> getErrorStatistics() async {
    try {
      final response = await _supabase
          .from('error_statistics')
          .select()
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch error statistics: $e');
      }
      return [];
    }
  }
}
