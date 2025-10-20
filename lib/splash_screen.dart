import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/routes.dart';
import 'src/services/maintenance_notification_service.dart';

// Umschaltbarer Modus für die Launch-Animation:
// false (Standard): Kein Overlay-Icon – erst System-Icon, dann Splash-Content von 0 -> 1.
// true: Vorheriger Modus mit Overlay-Icon (Fortsetzung der System-Animation).
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
    // Mindestens 1600ms Splash anzeigen (parallel zu Supabase-Init)
    // So bleibt der Content nach seinem Zoom-In noch deutlich sichtbar
    final splashTimer = Future.delayed(const Duration(milliseconds: 1600));
    
    try {
      // Env-Variablen prüfen
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
      const supabaseAnon = String.fromEnvironment('SUPABASE_ANON_KEY');
      
      if (supabaseUrl.isEmpty || supabaseAnon.isEmpty) {
        await splashTimer;
        if (!mounted) return;
        // Hier könnte man zu einem Fehler-Screen navigieren
        return;
      }

      // Supabase initialisieren (parallel zum Splash-Timer)
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnon,
      );
      
      // Notification Service initialisieren
      await MaintenanceNotificationService.initialize();
      
      // Init-Status setzen
      markSupabaseInitialized();

      // Warte auf Splash-Mindestdauer (falls Supabase schneller fertig ist)
      await splashTimer;
      
      if (!mounted) return;

      // Nach erfolgreicher Init: Immer zur Home-Seite
      context.go('/home');
    } catch (e) {
      // Bei Fehler: warte auf Splash-Timer, dann trotzdem weiter
      await splashTimer;
      if (!mounted) return;
      // Bei Fehler trotzdem zur Home-Seite
      context.go('/home');
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
    final logoWidth = screenWidth * 0.75; // Noch größer

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Splash-Content (zoom/fade-in)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _contentOpacity.value,
                child: Transform.scale(
                  scale: _contentScaleIn.value,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dein zentrales Logo im Splash
                        Image.asset('assets/images/app_icon.png', width: logoWidth),
                        const SizedBox(height: 6), // Weniger Abstand
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textOpacity,
                            child: Transform.translate(
                              offset: const Offset(-8, 0), // Etwas nach links
                              child: Image.asset(
                                'assets/images/splash_text.png',
                                width: logoWidth * 1.25, // Größer
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
                    child: Image.asset('assets/images/app_icon.png', width: logoWidth),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
