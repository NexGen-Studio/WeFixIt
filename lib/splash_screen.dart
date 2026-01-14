import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/routes.dart';
import 'src/services/maintenance_notification_service.dart';
import 'src/services/navigation_service.dart';
import 'src/services/purchase_service.dart';
import 'src/services/network_service.dart';

// Umschaltbarer Modus für die Launch-Animation:
// false (Standard): Kein Overlay-Icon – direkt nach der nativen Launch-Animation
// den Splash-Content anzeigen (ohne zusätzliche Effekte).
const bool kUseOverlayContinuation = false;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _iconScaleOut; // Launcher-Icon schrumpft schnell
  late final Animation<double> _contentScaleIn; // Splash-Inhalt zoomt leicht ein
  late final Animation<double> _contentOpacity; // Splash-Inhalt blendet ein
  
  // Internet-Check Status
  bool _isCheckingInternet = true;
  bool _hasInternet = false;
  String _statusMessage = 'Prüfe Internetverbindung...';
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();
    final totalDuration = kUseOverlayContinuation
        ? const Duration(milliseconds: 1400)
        : const Duration(milliseconds: 1200);
    _controller = AnimationController(vsync: this, duration: totalDuration);

    if (kUseOverlayContinuation) {
      // B) Overlay-Continuation (vorheriger Modus)
      _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      // Icon: Stand ~800ms, schrumpfen ~250ms
      _iconScaleOut = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.571, 0.75, curve: Curves.easeInCubic),
        ),
      );
      // Content nach Icon
      _contentScaleIn = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.76, 1.0, curve: Curves.easeOutCubic),
        ),
      );
      _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.76, 1.0, curve: Curves.easeOut),
        ),
      );
    } else {
      // A) Standard (empfohlen): Kein Overlay – erst Content nach ~800ms, Zoom 0->1 (~400ms)
      _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
      );
      _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic)),
      );
      // Kein Icon-Overlay nötig, aber initialisieren, um null zu vermeiden
      _iconScaleOut = const AlwaysStoppedAnimation<double>(0.0);
      // Content erscheint nach ~800ms (0.0–0.667 warten), dann 0->1 bis Ende
      _contentScaleIn = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
        ),
      );
      _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
        ),
      );
    }
    _controller.forward();

    // Supabase NACH dem ersten Frame initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // SCHRITT 1: Auf Internet warten (max 7 Sekunden)
    setState(() {
      _isCheckingInternet = true;
      _statusMessage = 'Suche Internetverbindung...';
    });
    
    _hasInternet = await _networkService.waitForConnection(
      timeout: const Duration(seconds: 7),
    );
    
    if (!_hasInternet) {
      // Kein Internet nach 7 Sekunden
      setState(() {
        _isCheckingInternet = false;
        _statusMessage = 'Diese App benötigt eine Internetverbindung';
      });
      return; // App startet NICHT
    }
    
    // Internet verfügbar! Weiter mit Init
    setState(() {
      _statusMessage = 'Verbindung hergestellt...';
    });
    
    // Mindestens 1600ms Splash anzeigen (parallel zu Supabase-Init)
    // So bleibt der Content nach seinem Zoom-In noch deutlich sichtbar
    final splashTimer = Future.delayed(const Duration(milliseconds: 1600));
    
    try {
      // Env-Variablen prüfen (mit Development-Fallback)
      const supabaseUrl = String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://zbrlhswafnlpfwqikapu.supabase.co', // Development-Fallback
      );
      const supabaseAnon = String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0', // Development-Fallback
      );
      
      if (supabaseUrl.isEmpty || supabaseAnon.isEmpty) {
        print('❌ Supabase Credentials fehlen!');
        await splashTimer;
        if (!mounted) return;
        context.go('/home'); // Trotzdem weiter zur App (für Offline-Nutzung)
        return;
      }

      // Supabase initialisieren (parallel zum Splash-Timer)
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnon,
      );
      
      // Purchase Service initialisieren (RevenueCat)
      try {
        await PurchaseService().initialize();
        print('✅ Purchase Service initialisiert');
      } catch (e) {
        print('⚠️ Fehler beim Initialisieren des Purchase Service: $e');
      }
      
      // Notification Service initialisieren & Setup-Notification senden
      await MaintenanceNotificationService.initialize();
      // Sofort eine Setup-Notification senden, damit App in Benachrichtigungsliste erscheint
      await MaintenanceNotificationService.sendWelcomeNotification();
      
      // Init-Status setzen
      markSupabaseInitialized();

      // Warte auf Splash-Mindestdauer (falls Supabase schneller fertig ist)
      await splashTimer;
      
      if (!mounted) return;

      final pendingRoute = NavigationService.consumePendingRoute();
      if (pendingRoute != null) {
        context.go(pendingRoute);
        return;
      }

      // Nach erfolgreicher Init: Standardmäßig zur Home-Seite
      setState(() {
        _isCheckingInternet = false;
      });
      context.go('/home');
    } catch (e) {
      print('❌ Fehler beim Initialisieren: $e');
      // Bei Fehler: warte auf Splash-Timer, dann trotzdem weiter
      await splashTimer;
      if (!mounted) return;
      setState(() {
        _isCheckingInternet = false;
      });
      final pendingRoute = NavigationService.consumePendingRoute();
      if (pendingRoute != null) {
        context.go(pendingRoute);
      } else {
        // Bei Fehler trotzdem zur Home-Seite
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = screenWidth * 0.9; // Größer (90% der Breite)

    return Scaffold(
      backgroundColor: const Color(0xFF0D1218),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Splash-Content: direkt anzeigen, ohne zusätzliche Animation
          Center(
            child: Image.asset(
              'assets/images/splash_screen.png',
              width: logoWidth,
              fit: BoxFit.contain,
            ),
          ),

          // Optional: Overlay-Continuation nur im Legacy-Modus zeichnen
          if (kUseOverlayContinuation)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_iconScaleOut.value <= 0.01) return const SizedBox.shrink();
                return Center(
                  child: Transform.scale(
                    scale: _iconScaleOut.value,
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: logoWidth * 0.6,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          
          // Internet-Status Indicator (unten)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _buildInternetStatus(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInternetStatus() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // WiFi-Icon NUR bei fehlendem Internet anzeigen
        if (_isCheckingInternet && !_hasInternet)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Opacity(
                opacity: 0.3 + (value * 0.7), // Pulsiert zwischen 0.3 und 1.0
                child: const Icon(
                  Icons.wifi_find,
                  color: Color(0xFFFFB129),
                  size: 48,
                ),
              );
            },
            onEnd: () {
              if (_isCheckingInternet && mounted) {
                setState(() {}); // Trigger rebuild für Loop
              }
            },
          )
        else if (!_isCheckingInternet && !_hasInternet)
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
        
        // Status-Text nur bei fehlendem Internet
        if (_isCheckingInternet && !_hasInternet || !_isCheckingInternet && !_hasInternet) ...[
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: TextStyle(
              color: _isCheckingInternet ? Colors.white70 : Colors.red,
              fontSize: 14,
              fontWeight: _isCheckingInternet ? FontWeight.normal : FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        // Retry-Button wenn offline
        if (!_isCheckingInternet && !_hasInternet) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isCheckingInternet = true;
                _statusMessage = 'Erneut verbinden...';
              });
              _initializeApp();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB129),
              foregroundColor: const Color(0xFF0D1218),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
