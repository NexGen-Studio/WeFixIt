import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';

/// Dialog der angezeigt wird wenn Internet-Verbindung fehlt
class InternetRequiredDialog extends ConsumerWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  
  const InternetRequiredDialog({
    super.key,
    this.message,
    this.onRetry,
    this.showRetryButton = true,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WiFi Icon mit rotem Circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off,
                size: 40,
                color: Colors.red,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Titel
            const Text(
              'Keine Internetverbindung',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              message ?? 'Diese Funktion benötigt eine aktive Internetverbindung.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                // Abbrechen Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                
                if (showRetryButton) ...[
                  const SizedBox(width: 12),
                  
                  // Erneut versuchen Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final networkService = ref.read(networkServiceProvider);
                        final hasInternet = await networkService.hasInternetConnection();
                        
                        if (hasInternet) {
                          Navigator.of(context).pop(true);
                          onRetry?.call();
                        } else {
                          // Immer noch offline
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Immer noch keine Verbindung'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB129),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Erneut versuchen',
                        style: TextStyle(
                          color: Color(0xFF0D1218),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Zeigt den Dialog und gibt true zurück wenn erneut versucht werden soll
  static Future<bool?> show(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
    bool showRetryButton = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InternetRequiredDialog(
        message: message,
        onRetry: onRetry,
        showRetryButton: showRetryButton,
      ),
    );
  }
}

/// Utility Mixin für Screens die Internet-Checks benötigen
mixin InternetAwareScreen {
  /// Zeigt Internet-Required Dialog wenn keine Verbindung besteht
  Future<bool> checkInternetOrShowDialog(
    BuildContext context,
    WidgetRef ref, {
    String? message,
  }) async {
    final networkService = ref.read(networkServiceProvider);
    final hasInternet = await networkService.hasInternetConnection();
    
    if (!hasInternet && context.mounted) {
      final retry = await InternetRequiredDialog.show(
        context,
        message: message,
      );
      return retry == true;
    }
    
    return hasInternet;
  }
  
  /// Führt Aktion mit automatischem Internet-Check aus
  Future<T?> executeWithInternetCheck<T>({
    required BuildContext context,
    required WidgetRef ref,
    required Future<T> Function() action,
    String? errorMessage,
  }) async {
    if (!await checkInternetOrShowDialog(context, ref, message: errorMessage)) {
      return null;
    }
    
    try {
      return await action();
    } on SocketException catch (_) {
      if (context.mounted) {
        await InternetRequiredDialog.show(
          context,
          message: 'Verbindung zum Server unterbrochen',
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
