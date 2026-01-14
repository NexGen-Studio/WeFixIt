import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';

/// Globaler Connection Monitor der die App blockiert bei Verbindungsverlust
class ConnectionMonitor extends ConsumerStatefulWidget {
  final Widget child;
  
  const ConnectionMonitor({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConnectionMonitor> createState() => _ConnectionMonitorState();
}

class _ConnectionMonitorState extends ConsumerState<ConnectionMonitor> {
  StreamSubscription<bool>? _connectivitySubscription;
  bool _showingDialog = false;
  bool _isOnline = true;
  
  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }
  
  void _startMonitoring() {
    final networkService = ref.read(networkServiceProvider);
    
    // Connectivity-Stream abonnieren
    _connectivitySubscription = networkService.connectivityStream.listen((hasInternet) {
      if (!mounted) return;
      
      setState(() {
        _isOnline = hasInternet;
      });
      
      if (!hasInternet && !_showingDialog) {
        // Verbindung verloren → Dialog anzeigen
        _showConnectionLostDialog();
      } else if (hasInternet && _showingDialog) {
        // Verbindung wiederhergestellt → Dialog schließen
        _closeDialog();
      }
    });
  }
  
  void _showConnectionLostDialog() {
    if (!mounted || _showingDialog) return;
    
    setState(() {
      _showingDialog = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Zurück-Button blockieren
        child: Dialog(
          backgroundColor: const Color(0xFF1A1F2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              minWidth: 320,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animiertes WiFi-Off Icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: 0.3 + (value * 0.7),
                      child: Container(
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
                    );
                  },
                  onEnd: () {
                    if (mounted && _showingDialog) {
                      setState(() {}); // Loop
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
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
                
                Text(
                  'Die Verbindung wurde unterbrochen.\nBitte überprüfe deine Internetverbindung.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Retry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final networkService = ref.read(networkServiceProvider);
                      final hasInternet = await networkService.hasInternetConnection();
                      
                      if (hasInternet) {
                        _closeDialog();
                      }
                      // Keine Aktion wenn offline - Dialog bleibt einfach offen
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB129),
                      foregroundColor: const Color(0xFF0D1218),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
           ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _showingDialog = false;
        });
      }
    });
  }
  
  void _closeDialog() {
    if (!mounted || !_showingDialog) return;
    
    setState(() {
      _showingDialog = false;
    });
    
    Navigator.of(context, rootNavigator: true).pop();
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
