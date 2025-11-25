import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../i18n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/maintenance_service.dart';
import '../../models/profile.dart';
import '../../models/maintenance_reminder.dart';
import '../../state/profile_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _tips = [];
  int _tipIndex = 0;
  Timer? _tipTimer;
  double _tipOpacity = 1.0;
  MaintenanceReminder? _nextReminder;
  List<MaintenanceReminder> _upcomingReminders = [];
  int _currentReminderIndex = 0;
  Timer? _reminderRotationTimer;
  PageController? _reminderPageController;
  double? _monthlyCosts;
  int _healthScore = 100;
  int _activeDtcsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(profileControllerProvider.notifier).ensureLoaded();
    _loadTips();
    _loadNextReminder();
    _loadMonthlyCosts();
    _loadHealthScore();
  }

  String _categoryLabel(AppLocalizations t, MaintenanceCategory? cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return t.maintenance_category_oil_change;
      case MaintenanceCategory.tireChange:
        return t.maintenance_category_tire_change;
      case MaintenanceCategory.brakes:
        return t.maintenance_category_brakes;
      case MaintenanceCategory.tuv:
        return t.maintenance_category_tuv;
      case MaintenanceCategory.inspection:
        return t.maintenance_category_inspection;
      case MaintenanceCategory.battery:
        return t.maintenance_category_battery;
      case MaintenanceCategory.filter:
        return t.maintenance_category_filter;
      case MaintenanceCategory.insurance:
        return t.maintenance_category_insurance;
      case MaintenanceCategory.tax:
        return t.maintenance_category_tax;
      case MaintenanceCategory.other:
        return t.maintenance_category_other;
      default:
        return '';
    }
  }

  // --- Kategorie-/Status-Hilfsfunktionen für Next-Reminder-Card ---
  IconData _categoryIcon(MaintenanceCategory? cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return Icons.oil_barrel_outlined;
      case MaintenanceCategory.tireChange:
        return Icons.tire_repair;
      case MaintenanceCategory.brakes:
        return Icons.handyman_outlined;
      case MaintenanceCategory.tuv:
        return Icons.verified_outlined;
      case MaintenanceCategory.inspection:
        return Icons.build_circle_outlined;
      case MaintenanceCategory.battery:
        return Icons.battery_charging_full;
      case MaintenanceCategory.filter:
        return Icons.filter_alt_outlined;
      case MaintenanceCategory.insurance:
        return Icons.shield_outlined;
      case MaintenanceCategory.tax:
        return Icons.receipt_long_outlined;
      case MaintenanceCategory.other:
        return Icons.more_horiz;
      default:
        return Icons.event_note;
    }
  }

  Color _categoryColor(MaintenanceCategory? cat) {
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return const Color(0xFFFFB74D);
      case MaintenanceCategory.tireChange:
        return const Color(0xFF64B5F6);
      case MaintenanceCategory.brakes:
        return const Color(0xFFEF5350);
      case MaintenanceCategory.tuv:
        return const Color(0xFF66BB6A);
      case MaintenanceCategory.inspection:
        return const Color(0xFF7E57C2);
      case MaintenanceCategory.battery:
        return const Color(0xFFFFD54F);
      case MaintenanceCategory.filter:
        return const Color(0xFF26C6DA);
      case MaintenanceCategory.insurance:
        return const Color(0xFF42A5F5);
      case MaintenanceCategory.tax:
        return const Color(0xFFFFA726);
      case MaintenanceCategory.other:
        return const Color(0xFF90A4AE);
      default:
        return const Color(0xFFF8AD20);
    }
  }

  Color _statusColor(MaintenanceReminder r) {
    if (r.isCompleted) return Colors.grey;
    if (r.reminderType == ReminderType.date && r.dueDate != null) {
      final d = r.dueDate!.difference(DateTime.now()).inDays;
      if (d < 0) return const Color(0xFFE53935);
      if (d <= 7) return const Color(0xFFF57C00);
      return const Color(0xFFF8AD20);
    }
    return const Color(0xFFF8AD20);
  }
  
  bool _isOverdue(MaintenanceReminder r) {
    if (r.isCompleted) return false;
    if (r.reminderType == ReminderType.date && r.dueDate != null) {
      final now = DateTime.now();
      final due = r.dueDate!.toLocal();
      return due.isBefore(now);
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Lade Daten neu wenn App wieder aktiv wird
      _loadNextReminder();
      _loadMonthlyCosts();
      _loadHealthScore();
    }
  }

  void _showLoginRequired(BuildContext context) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A22),
        title: Text(t.home_login_required_title, style: const TextStyle(color: Colors.white)),
        content: Text(t.home_login_required_message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.home_login_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/auth');
            },
            child: Text(t.home_login_confirm),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload Profil wenn zum Screen zurückgekehrt wird
    if (ModalRoute.of(context)?.isCurrent == true) {
      ref.read(profileControllerProvider.notifier).refreshFromRemote(force: true);
    }
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
    if (Supabase.instance.client.auth.currentSession == null) return;

    try {
      final svc = MaintenanceService(Supabase.instance.client);
      final reminder = await svc.fetchNextReminder();
      final reminders = await svc.fetchUpcomingReminders(limit: 10);
      if (!mounted) return;
      setState(() {
        _nextReminder = reminder;
        _upcomingReminders = reminders;
      });
      _loadHealthScore();
      _startReminderRotation();
    } catch (e) {
      // Fehler ignorieren, optional loggen
    }
  }

  void _startReminderRotation() {
    _reminderRotationTimer?.cancel();
    if (_upcomingReminders.length > 1) {
      _reminderPageController = PageController();
      _reminderRotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _currentReminderIndex = (_currentReminderIndex + 1) % _upcomingReminders.length;
        });
        _reminderPageController?.animateToPage(
          _currentReminderIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _loadMonthlyCosts() async {
    // Sum of completed maintenance costs in current month
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final res = await client
        .from('maintenance_reminders')
        .select('cost, completed_at, status')
        .eq('user_id', user.id);
    double sum = 0;
    for (final item in res) {
      final status = item['status'] as String?;
      final cost = (item['cost'] as num?)?.toDouble() ?? 0.0;
      final completedAtStr = item['completed_at'] as String?;
      final completedAt = completedAtStr != null ? DateTime.tryParse(completedAtStr) : null;
      if (status == 'completed' && completedAt != null && !completedAt.isBefore(startOfMonth)) {
        sum += cost;
      }
    }
    if (!mounted) return;
    setState(() => _monthlyCosts = sum);
  }

  Future<void> _loadHealthScore() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    final svc = MaintenanceService(client);
    final stats = await svc.fetchStats();
    // Heuristik: 100 - (overdue*20 + planned*3), min 10 max 100
    final overdue = stats['overdue'] ?? 0;
    final planned = stats['planned'] ?? 0;
    int score = 100 - (overdue * 20 + planned * 3) - (_activeDtcsCount * 10);
    // Wenn nächste Wartung heute/überfällig, stärker abwerten
    final d = _nextReminder?.dueDate != null
        ? _nextReminder!.dueDate!.difference(DateTime.now()).inDays
        : null;
    if (d != null && d <= 0) score -= 10;
    if (d != null && d > 0 && d <= 7) score -= 5;
    score = score.clamp(10, 100);
    if (!mounted) return;
    setState(() => _healthScore = score);
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final avatarUrlUi = profileState.avatarUrlUi;
    final vehicle = profileState.vehicle;
    final isProfileLoading = profileState.isLoading;
    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Dark Top Bar with centered title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/home-image.png',
                      height: 40,
                    ),
                    const Spacer(),
                    if ((avatarUrlUi ?? '').isNotEmpty)
                      GestureDetector(
                        onTap: () => _showImagePreview(avatarUrlUi!),
                        child: CircleAvatar(
                          radius: 18,
                          foregroundImage: CachedNetworkImageProvider(avatarUrlUi!),
                          backgroundColor: Colors.transparent,
                        ),
                      )
                    else
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF1A2028),
                        child: Icon(Icons.person_outline, color: Colors.white70, size: 18),
                      ),
                  ],
                ),
              ),
            ),

            // Vehicle Section (no card, matches mockup)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildVehicleSection(context, profileState, profile, vehicle, isProfileLoading),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Kurztipps Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  t.tr('home.quick_tips'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Tip Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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

  // Vehicle section implementing the mockup layout (no card container)
  Widget _buildVehicleSection(
    BuildContext context,
    ProfileState profileState,
    UserProfile? profile,
    Map<String, dynamic>? vehicle,
    bool isProfileLoading,
  ) {
    final t = AppLocalizations.of(context);
    final make = (vehicle?['make'] ?? '') as String;
    final model = (vehicle?['model'] ?? '') as String;
    final mileage = (vehicle?['mileage_km'] ?? 0) as int;
    final powerKw = (vehicle?['power_kw'] as num?)?.toInt();
    final powerPs = powerKw != null ? (powerKw * 1.36).round() : null;
    // Bestimme Grußnamen: Anzeigename > sonst "Hallo!"
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    String greetingName = 'Hallo!';
    
    if (isLoggedIn && profile != null) {
      if (profile.displayName?.isNotEmpty == true) {
        greetingName = 'Hallo, ${profile.displayName}!';
      }
    }
    
    final vehicleName = greetingName;
    
    final accent = const Color(0xFFFFB129);
    final vehiclePhoto = profile?.vehiclePhotoUrl;

    String statusLabel;
    if (_healthScore >= 85) statusLabel = t.tr('home.status_good');
    else if (_healthScore >= 60) statusLabel = t.tr('home.status_ok');
    else statusLabel = t.tr('home.status_attention');

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const SizedBox(height: 12),
            Text(
              vehicleName.isNotEmpty ? vehicleName : 'Hallo',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            if (!isLoggedIn) ...[
              const SizedBox(height: 4),
              const Text(
                'Bitte melde dich an!',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 12),
            // Vehicle photo below km, 2cm height, 90% width
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 100,
                width: MediaQuery.of(context).size.width * 0.9,
                color: const Color(0xFF1A2028),
                child: (vehiclePhoto ?? '').isNotEmpty
                    ? Image.network(vehiclePhoto!, fit: BoxFit.cover)
                    : Image.asset(
                        'assets/images/Placeholder.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Row 2: Align numbers (left red count, right % in ring) on same vertical center
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: Center(
                      child: Text(
                        '$_activeDtcsCount',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 56),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 160,
                  width: 160,
                  child: Transform.scale(
                    scale: 3.5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _healthScore / 100,
                          strokeWidth: 3,
                          backgroundColor: const Color(0xFF1F2A36),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                        Transform.scale(
                          scale: 0.29,
                          child: Text(
                            '$_healthScore%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Labels row: left text aligned horizontally with STATUS GUT on the right
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      t.tr('home.active_error_codes_label'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Center(
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Monthly costs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.tr('home.monthly_costs'),
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  _monthlyCosts == null ? '0 €' : '${_monthlyCosts!.toStringAsFixed(0)} €',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Four feature tiles styled like the old cards but dark
            Column(
              children: [
                _buildFeatureTile(
                  icon: Icons.search,
                  iconColor: const Color(0xFFE53935),
                  title: t.home_read_dtcs,
                  subtitle: t.home_read_dtcs_subtitle,
                  onTap: () => context.go('/diagnose'),
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  icon: Icons.build_outlined,
                  iconColor: const Color(0xFFF8AD20),
                  title: t.home_maintenance,
                  subtitle: t.home_maintenance_subtitle,
                  onTap: () => context.go('/maintenance'),
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF388E3C),
                  title: t.tr('home.vehicle_costs'),
                  subtitle: t.tr('home.vehicle_costs_desc'),
                  onTap: () => context.go('/costs'),
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFF57C00),
                  title: t.home_ask_toni,
                  subtitle: t.tr('home.ask_toni_subtitle'),
                  onTap: () {
                    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
                    if (!isLoggedIn) {
                      _showLoginRequired(context);
                    } else {
                      context.go('/asktoni');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Maintenance notice placed BELOW the tiles
            if (_upcomingReminders.isEmpty)
              GestureDetector(
                onTap: () => context.go('/maintenance'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.home_no_maintenance_title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(t.home_no_maintenance_subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              )
            else
              SizedBox(
                height: 80,
                child: PageView.builder(
                  controller: _reminderPageController,
                  itemCount: _upcomingReminders.length,
                  onPageChanged: (index) {
                    setState(() => _currentReminderIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final reminder = _upcomingReminders[index];
                    return GestureDetector(
                      onTap: () => context.go('/maintenance'),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151C23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isOverdue(reminder) 
                              ? const Color(0xFFE53935) 
                              : _categoryColor(reminder.category).withOpacity(0.6), 
                            width: _isOverdue(reminder) ? 2.0 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _categoryColor(reminder.category).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _categoryIcon(reminder.category),
                                    color: _categoryColor(reminder.category),
                                    size: 20,
                                  ),
                                ),
                                if (reminder.category != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _categoryLabel(t, reminder.category),
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(reminder.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    reminder.dueDate != null
                                        ? DateFormat('dd.MM.yyyy').format(reminder.dueDate!)
                                        : t.home_due_at_km.replaceAll('{km}', (reminder.dueMileage ?? 0).toString()),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1A2028),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2A3340), width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
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
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
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

  // Professional Tip Card (dark style, keep icon)
  Widget _buildTipCard({required String title, required String body}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      opacity: _tipOpacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151C23),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF22303D), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1E0C),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Colors.white70,
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

  Widget _primaryAction({
    required String label,
    required VoidCallback onTap,
    required Color accent,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tipTimer?.cancel();
    _reminderRotationTimer?.cancel();
    _reminderPageController?.dispose();
    super.dispose();
  }

}

