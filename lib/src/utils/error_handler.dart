import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/internet_required_dialog.dart';

/// Globaler Error Handler für Network-Exceptions
class ErrorHandler {
  /// Prüft ob es ein Network-Error ist
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is http.ClientException) return true;
    
    // String-basierte Checks für Supabase/RevenueCat Errors
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed host lookup') ||
           errorString.contains('no address associated with hostname') ||
           errorString.contains('network error') ||
           errorString.contains('unable to resolve host') ||
           errorString.contains('socketexception');
  }
  
  /// Zeigt einen nutzerfreundlichen Error-Dialog
  static Future<void> handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;
    
    if (isNetworkError(error)) {
      // Network Error → Internet-Dialog
      await InternetRequiredDialog.show(
        context,
        message: 'Für diese Funktion wird eine Internetverbindung benötigt.',
        onRetry: onRetry,
      );
    } else {
      // Anderer Fehler → Generic Error
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange),
              SizedBox(width: 12),
              Text(
                'Fehler',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            'Ein unerwarteter Fehler ist aufgetreten.',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFFFB129)),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  /// Wrapper für async Funktionen mit automatischem Error-Handling
  static Future<T?> executeWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() action,
    VoidCallback? onRetry,
    bool showLoadingIndicator = false,
  }) async {
    if (!context.mounted) return null;
    
    if (showLoadingIndicator) {
      // Loading-Dialog anzeigen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFB129),
          ),
        ),
      );
    }
    
    try {
      final result = await action();
      
      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop(); // Loading-Dialog schließen
      }
      
      return result;
    } catch (e) {
      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop(); // Loading-Dialog schließen
      }
      
      if (context.mounted) {
        await handleError(context, e, onRetry: onRetry);
      }
      
      return null;
    }
  }
}

/// Extension für einfacheres Error-Handling in Widgets
extension BuildContextErrorHandler on BuildContext {
  /// Zeigt Error-Dialog
  Future<void> showError(dynamic error, {VoidCallback? onRetry}) {
    return ErrorHandler.handleError(this, error, onRetry: onRetry);
  }
  
  /// Führt Aktion mit Error-Handling aus
  Future<T?> executeWithErrorHandling<T>({
    required Future<T> Function() action,
    VoidCallback? onRetry,
    bool showLoadingIndicator = false,
  }) {
    return ErrorHandler.executeWithErrorHandling<T>(
      context: this,
      action: action,
      onRetry: onRetry,
      showLoadingIndicator: showLoadingIndicator,
    );
  }
}
