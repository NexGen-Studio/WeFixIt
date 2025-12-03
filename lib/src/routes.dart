import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/diagnose/diagnose_screen.dart';
import 'features/chatbot/chatbot_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/maintenance/create_reminder_screen.dart';
import 'features/maintenance/maintenance_dashboard_screen.dart';
import 'features/maintenance/maintenance_home_screen.dart';
import 'features/maintenance/extended_create_reminder_screen.dart';
import 'features/costs/costs_main_screen.dart';
import 'features/costs/cost_form_screen.dart';
import 'features/costs/category_manager_screen.dart';
import 'features/costs/achievements_screen.dart';
import 'widgets/ad_banner.dart';
import 'features/home/home_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'i18n/app_localizations.dart';
import '../splash_screen.dart';

// Globaler Init-Status für Supabase
bool _supabaseInitialized = false;

void markSupabaseInitialized() {
  _supabaseInitialized = true;
}

bool isSupabaseInitialized() => _supabaseInitialized;

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _supabaseInitialized
        ? GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange)
        : null,
    redirect: (context, state) async {
      // Externe Deep Links abfangen (z.B. wefixit://reset-password?...)
      final loc = state.uri.toString();
      if (loc.startsWith('wefixit://')) {
        // Supabase-Session aus Recovery-Link herstellen
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(state.uri);
        } catch (_) {}
        // Immer auf interne Route mappen
        return '/reset-password';
      }
      final inSplash = state.matchedLocation == '/splash';
      // Splash darf immer sichtbar sein
      if (inSplash) return null;
      
      // Wenn Supabase noch nicht initialisiert: Splash zeigen
      if (!_supabaseInitialized) {
        return '/splash';
      }
      
      final supa = Supabase.instance.client;
      final isLoggedIn = supa.auth.currentSession != null;
      final location = state.matchedLocation;
      final loggingIn = location == '/auth';

      // Nur bestimmte Routen schützen (KI-Features benötigen Login)
      final isProtected = location.startsWith('/asktoni');

      // Wenn nicht eingeloggt und geschützte Route: zur Auth
      if (!isLoggedIn && isProtected) return '/auth';
      // Wenn bereits eingeloggt und auf /auth: zurück nach Home
      if (isLoggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => const NoTransitionPage(child: AuthScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => const NoTransitionPage(child: ResetPasswordScreen()),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) => const NoTransitionPage(child: PaywallScreen()),
      ),
      GoRoute(
        path: '/costs/add',
        pageBuilder: (context, state) => const NoTransitionPage(child: CostFormScreen()),
      ),
      GoRoute(
        path: '/costs/edit/:id',
        pageBuilder: (context, state) => NoTransitionPage(
          child: CostFormScreen(costId: state.pathParameters['id']),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => _RootScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/diagnose',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiagnoseScreen(),
            ),
          ),
          GoRoute(
            path: '/asktoni',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatbotScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/maintenance',
            builder: (context, state) => const MaintenanceDashboardScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const ExtendedCreateReminderScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/maintenance-home',
            builder: (context, state) => const MaintenanceHomeScreen(),
          ),
          GoRoute(
            path: '/costs',
            builder: (context, state) => const CostsMainScreen(),
            routes: [
              GoRoute(
                path: 'categories',
                builder: (context, state) => const CategoryManagerScreen(),
              ),
              GoRoute(
                path: 'achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _RootScaffold extends StatefulWidget {
  const _RootScaffold({required this.child});
  final Widget child;

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<_RootScaffold> {
  int _indexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/diagnose')) return 1;
    if (location.startsWith('/asktoni')) return 2;
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/diagnose');
        break;
      case 2:
        GoRouter.of(context).go('/asktoni');
        break;
      case 3:
        GoRouter.of(context).go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0F141A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: widget.child),
            const AdBannerWidget(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2028),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFFB129),
          unselectedItemColor: Colors.white70,
          selectedIconTheme: const IconThemeData(size: 28),
          unselectedIconTheme: const IconThemeData(size: 24),
          selectedFontSize: 14,
          unselectedFontSize: 12,
          currentIndex: currentIndex,
          onTap: _onTap,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: AppLocalizations.of(context).tr('tabs.home')),
            BottomNavigationBarItem(icon: const Icon(Icons.search), label: AppLocalizations.of(context).tr('tabs.diagnose')),
            BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: AppLocalizations.of(context).tr('tabs.ask_toni')),
            BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: AppLocalizations.of(context).tr('tabs.profile')),
          ],
        ),
      ),
    );
  }
}
