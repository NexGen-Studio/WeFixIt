import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../i18n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/maintenance_service.dart';
import '../../models/profile.dart';
import '../../models/maintenance_reminder.dart';

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
  MaintenanceReminder? _nextReminder;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTips();
    _loadNextReminder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload Profil wenn zum Screen zurückgekehrt wird
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadProfile();
    }
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
    // Nur laden wenn eingeloggt
    if (Supabase.instance.client.auth.currentSession == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    
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

  Future<void> _loadNextReminder() async {
    // Nur laden wenn eingeloggt
    if (Supabase.instance.client.auth.currentSession == null) return;

    try {
      final svc = MaintenanceService(Supabase.instance.client);
      final reminder = await svc.fetchNextReminder();
      if (!mounted) return;
      setState(() => _nextReminder = reminder);
    } catch (e) {
      // Fehler ignorieren, optional loggen
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

  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).home_login_required_title),
        content: Text(AppLocalizations.of(context).home_login_required_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).home_login_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/auth');
            },
            child: Text(AppLocalizations.of(context).home_login_confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header mit Begrüßung
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loading ? t.tr('home.greeting') : _greeting(t),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.home_vehicle_overview,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((_avatarUrlUi ?? '').isNotEmpty)
                      GestureDetector(
                        onTap: () => _showImagePreview(_avatarUrlUi!),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(_avatarUrlUi!),
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[100],
                          child: Icon(Icons.person_outline, color: Colors.grey[600], size: 24),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Nächste Wartungen (rotierend wie Kurztipps)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildRotatingMaintenanceCard(context),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // "Mein Fahrzeug" Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  t.home_my_vehicle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Feature Liste
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProFeatureCard(
                    icon: Icons.search,
                    iconColor: const Color(0xFFE53935),
                    iconBg: const Color(0xFFFFEBEE),
                    title: t.home_read_dtcs,
                    subtitle: t.home_read_dtcs_subtitle,
                    onTap: () => context.go('/diagnose'),
                  ),
                  const SizedBox(height: 12),
                  _buildProFeatureCard(
                    icon: Icons.build_outlined,
                    iconColor: const Color(0xFF1976D2),
                    iconBg: const Color(0xFFE3F2FD),
                    title: t.home_maintenance,
                    subtitle: t.home_maintenance_subtitle,
                    onTap: () => context.go('/maintenance'),
                  ),
                  const SizedBox(height: 12),
                  _buildProFeatureCard(
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF388E3C),
                    iconBg: const Color(0xFFE8F5E9),
                    title: t.home_costs,
                    subtitle: t.home_costs_subtitle,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildProFeatureCard(
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFFF57C00),
                    iconBg: const Color(0xFFFFF3E0),
                    title: t.home_ask_toni,
                    subtitle: t.home_ask_toni_subtitle,
                    onTap: () {
                      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
                      if (!isLoggedIn) {
                        _showLoginRequired(context);
                      } else {
                        context.go('/asktoni');
                      }
                    },
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Kurztipps Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  t.tr('home.quick_tips'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Tip Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(builder: (context) {
                  // Bestimme Sprache basierend auf aktuellem Locale
                  final locale = Localizations.localeOf(context).languageCode;
                  final isGerman = locale == 'de';
                  
                  final title = _tips.isEmpty
                      ? t.tr('home.tip_1_title')
                      : (_tips[_tipIndex][isGerman ? 'title_de' : 'title_en'] ?? '').toString();
                  final body = _tips.isEmpty
                      ? t.tr('home.tip_1_body')
                      : (_tips[_tipIndex][isGerman ? 'body_de' : 'body_en'] ?? '').toString();
                  return _buildTipCard(title: title, body: body);
                }),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // Rotierende Wartungs-Card (wie Kurztipps)
  Widget _buildRotatingMaintenanceCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Placeholder wenn keine Wartung vorhanden
    if (_nextReminder == null) {
      return GestureDetector(
        onTap: () => context.go('/maintenance'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1976D2).withOpacity(0.15),
                const Color(0xFF1976D2).withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.home_no_maintenance_title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.home_no_maintenance_subtitle,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      );
    }
    
    final reminder = _nextReminder!;
    final daysUntil = reminder.dueDate != null
        ? reminder.dueDate!.difference(DateTime.now()).inDays
        : null;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (daysUntil != null) {
      if (daysUntil < 0) {
        statusColor = const Color(0xFFE53935); // Rot: überfällig
        statusText = t.home_overdue;
        statusIcon = Icons.warning;
      } else if (daysUntil == 0) {
        statusColor = const Color(0xFFF57C00); // Orange: heute
        statusText = t.home_due_today;
        statusIcon = Icons.event_available;
      } else if (daysUntil <= 7) {
        statusColor = const Color(0xFFF57C00); // Orange: bald
        statusText = t.home_in_days.replaceAll('{days}', daysUntil.toString());
        statusIcon = Icons.event_note;
      } else {
        statusColor = const Color(0xFF4CAF50); // Grün: ok
        statusText = t.home_in_days.replaceAll('{days}', daysUntil.toString());
        statusIcon = Icons.event;
      }
    } else {
      statusColor = const Color(0xFF1976D2); // Blau: kilometer
      statusText = t.home_due_at_km.replaceAll('{km}', (reminder.dueMileage ?? 0).toString());
      statusIcon = Icons.speed;
    }

    return GestureDetector(
      onTap: () => context.go('/maintenance'),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        opacity: _tipOpacity,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.15),
                statusColor.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (reminder.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        reminder.description!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Professional Feature Card (Tesla/Kleinanzeigen Style)
  Widget _buildProFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Professional Tip Card
  Widget _buildTipCard({required String title, required String body}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      opacity: _tipOpacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFF57C00),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

