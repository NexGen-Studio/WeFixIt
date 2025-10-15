import 'dart:async';
import 'package:flutter/material.dart';
import '../../i18n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  bool _loading = true;
  List<Map<String, dynamic>> _tips = [];
  int _tipIndex = 0;
  Timer? _tipTimer;
  double _tipOpacity = 1.0;
  String? _avatarUrlUi;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTips();
  }

  void _showImagePreview(String url) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 32,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _loadProfile() async {
    final svc = SupabaseService(Supabase.instance.client);
    final p = await svc.fetchUserProfile();
    String? avatarUi;
    if ((p?.avatarUrl ?? '').isNotEmpty) {
      avatarUi = await svc.getSignedAvatarUrl(p!.avatarUrl!);
    }
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
      _avatarUrlUi = avatarUi;
    });
  }

  Future<void> _loadTips() async {
    final svc = SupabaseService(Supabase.instance.client);
    final list = await svc.fetchTips();
    if (!mounted) return;
    setState(() {
      _tips = list;
      _tipIndex = 0;
    });
    _tipTimer?.cancel();
    if (_tips.isNotEmpty) {
      _tipTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
        if (!mounted) return;
        setState(() => _tipOpacity = 0); // ausblenden (0.5s)
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() {
          _tipIndex = (_tipIndex + 1) % _tips.length; // neuen Tipp setzen
          _tipOpacity = 1; // einblenden (0.5s)
        });
      });
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  String _greeting(AppLocalizations t) {
    final name = _profile?.displayName?.trim().isNotEmpty == true
        ? _profile!.displayName!
        : (_profile?.nickname?.trim().isNotEmpty == true ? _profile!.nickname! : '');
    if (name.isEmpty) return t.tr('home.greeting');
    return '${t.tr('home.greeting').replaceAll('!', '')} $name!';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Begrüßung (optional mit kleinem Fahrzeugbild)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _loading ? t.tr('home.greeting') : _greeting(t),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: const Color(0xFF636564), fontWeight: FontWeight.w700),
                  ),
                ),
                if ((_avatarUrlUi ?? '').isNotEmpty)
                  GestureDetector(
                    onTap: () => _showImagePreview(_avatarUrlUi!),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(_avatarUrlUi!),
                      backgroundColor: Colors.white24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Reminders / Next maintenance card
            _InfoCard(
              title: t.tr('home.reminders'),
              subtitle: t.tr('home.next_maintenance_placeholder'),
              leading: const Icon(Icons.event_available, color: Color(0xFFF97316)),
            ),
            const SizedBox(height: 12),

            // Grid of quick actions
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _TileButton(
                  color: const Color(0xFFDC2626), // Kräftiges Rot - Warnung/Fehler
                  icon: Icons.car_repair,
                  label: t.tr('home.read_dtcs'),
                  onTap: () => context.go('/diagnose'),
                ),
                _TileButton(
                  color: const Color(0xFF0891B2), // Cyan - harmoniert mit Teal
                  icon: Icons.build,
                  label: t.tr('home.maintenance'),
                  onTap: () {},
                ),
                _TileButton(
                  color: const Color(0xFF008080), // teal - Finanzen
                  icon: Icons.attach_money,
                  label: t.tr('home.costs'),
                  onTap: () {},
                ),
                _TileButton(
                  color: const Color(0xFFFBBF24), // Gelb - Ask Toni!
                  icon: Icons.chat_bubble_outline,
                  label: t.tr('home.ask_toni'),
                  onTap: () => context.go('/asktoni'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Quick tips
            Text(
              t.tr('home.quick_tips'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: const Color(0xFF636564), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final title = _tips.isEmpty
                  ? t.tr('home.tip_1_title')
                  : (_tips[_tipIndex]['title'] ?? '').toString();
              final body = _tips.isEmpty
                  ? t.tr('home.tip_1_body')
                  : (_tips[_tipIndex]['body'] ?? '').toString();
              return Card(
                key: const ValueKey('tips_card_shell'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: const Color(0xFFF8F9FA),
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          opacity: _tipOpacity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({Key? key, required this.title, required this.subtitle, required this.leading}) : super(key: key);
  final String title;
  final String subtitle;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF8F9FA),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({required this.color, required this.icon, required this.label, this.onTap});
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
