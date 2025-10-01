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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final svc = SupabaseService(Supabase.instance.client);
    final p = await svc.fetchUserProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
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
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                if ((_profile?.vehiclePhotoUrl ?? '').isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _profile!.vehiclePhotoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Reminders / Next maintenance card
            _InfoCard(
              title: t.tr('home.reminders'),
              subtitle: t.tr('home.next_maintenance_placeholder'),
              leading: const Icon(Icons.event_available, color: Colors.orange),
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
                  color: const Color(0xFF5C6BC0),
                  icon: Icons.car_repair,
                  label: t.tr('home.read_dtcs'),
                  onTap: () => context.go('/diagnose'),
                ),
                _TileButton(
                  color: const Color(0xFF26A69A),
                  icon: Icons.build,
                  label: t.tr('home.maintenance'),
                  onTap: () {},
                ),
                _TileButton(
                  color: const Color(0xFF42A5F5),
                  icon: Icons.attach_money,
                  label: t.tr('home.costs'),
                  onTap: () {},
                ),
                _TileButton(
                  color: const Color(0xFFFFA726),
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
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            _InfoCard(
              title: t.tr('home.tip_1_title'),
              subtitle: t.tr('home.tip_1_body'),
              leading: const Icon(Icons.tips_and_updates, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle, required this.leading});
  final String title;
  final String subtitle;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.92),
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
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
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
