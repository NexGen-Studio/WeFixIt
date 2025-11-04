import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../services/maintenance_notification_service.dart';
import 'extended_create_reminder_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  const MaintenanceDashboardScreen({super.key});

  @override
  State<MaintenanceDashboardScreen> createState() => _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState extends State<MaintenanceDashboardScreen> {
  final _service = MaintenanceService(Supabase.instance.client);
  List<MaintenanceReminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _loading = true);
    try {
      final reminders = await _service.fetchReminders(null, null);
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _loading = false;
      });
      // Prüfe überfällige Wartungen und sende Notifications
      _checkOverdueAndNotify();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _checkOverdueAndNotify() async {
    try {
      // Initialisiere Notification Service
      await MaintenanceNotificationService.initialize();
      
      // Finde alle überfälligen Wartungen
      for (final reminder in _overdueReminders) {
        // Prüfe ob bereits eine Notification gesendet wurde (heute)
        final lastSent = reminder.lastNotificationSent;
        final now = DateTime.now();
        
        // Sende nur einmal pro Tag
        if (lastSent == null || 
            lastSent.year != now.year || 
            lastSent.month != now.month || 
            lastSent.day != now.day) {
          await MaintenanceNotificationService.scheduleOverdueNotification(reminder);
        }
      }
    } catch (e) {
      // Fehler ignorieren, Notifications sind nicht kritisch
      print('Fehler beim Senden von Notifications: $e');
    }
  }

  List<MaintenanceReminder> get _upcomingReminders =>
      (_reminders
            .where((r) {
              if (r.isCompleted) return false;
              if (r.dueDate == null) return true; // mileage-based zählt als anstehend
              // Anstehend = nur zukünftige Termine (noch nicht überfällig)
              final now = DateTime.now();
              final due = r.dueDate!.toLocal();
              return due.isAfter(now);
            })
            .toList()
          ..sort((a, b) {
            final ad = a.dueDate;
            final bd = b.dueDate;
            if (ad == null && bd == null) return 0;
            if (ad == null) return 1;
            if (bd == null) return -1;
            return ad.compareTo(bd);
          }))
          .take(3)
          .toList();

  List<MaintenanceReminder> get _overdueReminders =>
      _reminders.where((r) {
        if (r.isCompleted) return false;
        if (r.dueDate == null) return false;
        final now = DateTime.now();
        final due = r.dueDate!.toLocal();
        // Überfällig = Due Date/Time ist vorbei (inkl. Uhrzeit)
        return due.isBefore(now);
      }).toList();

  List<MaintenanceReminder> get _recentCompleted {
    final completed = _reminders.where((r) => r.isCompleted).toList();
    // Sortiere nach completed_at, neueste zuerst
    completed.sort((a, b) {
      final aDate = a.completedAt ?? a.dueDate ?? DateTime.now();
      final bDate = b.completedAt ?? b.dueDate ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return completed;
  }

  Map<String, List<MaintenanceReminder>> get _completedGroupedByMonth {
    final Map<String, List<MaintenanceReminder>> grouped = {};
    for (final reminder in _recentCompleted) {
      final date = reminder.completedAt ?? reminder.dueDate ?? DateTime.now();
      final monthKey = DateFormat('MMM yyyy', 'de').format(date);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(reminder);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          t.maintenance_dashboard_title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistik-Cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: t.maintenance_upcoming,
                            value: '${_upcomingReminders.length}',
                            icon: Icons.event_note,
                            color: const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: t.maintenance_overdue_count,
                            value: '${_overdueReminders.length}',
                            icon: Icons.warning,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: t.maintenance_completed,
                            value: '${_recentCompleted.length}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: t.maintenance_total,
                            value: '${_reminders.length}',
                            icon: Icons.analytics,
                            color: const Color(0xFFF57C00),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions (Titel entfernt)
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_circle,
                            title: t.maintenance_new_reminder,
                            color: const Color(0xFF1976D2),
                            onTap: () async {
                              await context.push('/maintenance/create');
                              _loadReminders(); // Refresh nach Rückkehr
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.euro,
                            title: t.maintenance_costs,
                            color: const Color(0xFF388E3C),
                            onTap: () {
                              // TODO: Navigate to /costs when implemented
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Überfällige Wartungen (falls vorhanden)
                    if (_overdueReminders.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            t.maintenance_overdue_badge,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_overdueReminders.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._overdueReminders.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReminderCard(reminder: r, onRefresh: _loadReminders),
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Anstehende Wartungen
                    Text(
                      t.maintenance_upcoming_reminders,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_upcomingReminders.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            t.maintenance_no_upcoming,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      ..._upcomingReminders.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReminderCard(reminder: r, onRefresh: _loadReminders),
                          )),

                    const SizedBox(height: 24),

                    // Erledigte Wartungen
                    if (_recentCompleted.isNotEmpty) ...[
                      Text(
                        t.maintenance_recently_completed,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Gruppiert nach Monat/Jahr
                      ..._completedGroupedByMonth.entries.expand((entry) => [
                        // Monats-Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFF22303D), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFF22303D), thickness: 1)),
                            ],
                          ),
                        ),
                        // Wartungen des Monats
                        ...entry.value.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ReminderCard(reminder: r, compact: true, onRefresh: _loadReminders),
                        )),
                      ]),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22303D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151C23),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF22303D)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final MaintenanceReminder reminder;
  final bool compact;
  final VoidCallback onRefresh;

  const _ReminderCard({required this.reminder, this.compact = false, required this.onRefresh});

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

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
        return const Color(0xFF1976D2);
    }
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

  Color _getStatusColor() {
    if (reminder.isCompleted) return Colors.grey;
    if (reminder.reminderType == ReminderType.date && reminder.dueDate != null) {
      final now = DateTime.now();
      final due = reminder.dueDate!.toLocal();
      final hoursUntil = due.difference(now).inHours;
      
      if (hoursUntil < 0) return const Color(0xFFE53935); // Überfällig
      if (hoursUntil <= 24) return const Color(0xFFF57C00); // < 1 Tag
      if (hoursUntil <= 168) return const Color(0xFFF57C00); // < 7 Tage (168h)
      return const Color(0xFF4CAF50); // > 7 Tage
    }
    return const Color(0xFF1976D2);
  }

  bool _isOverdue() {
    if (reminder.isCompleted) return false;
    if (reminder.reminderType == ReminderType.date && reminder.dueDate != null) {
      final now = DateTime.now();
      final due = reminder.dueDate!.toLocal();
      // Überfällig = Due Date/Time ist vorbei (inkl. Uhrzeit)
      return due.isBefore(now);
    }
    return false;
  }

  Color _getBorderColor() {
    // Überfällig: Auffälliges Rot mit voller Deckkraft
    if (_isOverdue()) return const Color(0xFFE53935);
    // Sonst: Kategorie-Farbe
    return _categoryColor(reminder.category).withOpacity(0.6);
  }

  Future<void> _completeReminder(BuildContext context) async {
    final t = AppLocalizations.of(context);
    try {
      final service = MaintenanceService(Supabase.instance.client);
      await service.completeReminder(reminder.id);
      if (context.mounted) {
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _uncompleteReminder(BuildContext context) async {
    final t = AppLocalizations.of(context);
    try {
      final service = MaintenanceService(Supabase.instance.client);
      await service.uncompleteReminder(reminder.id);
      if (context.mounted) {
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(t.maintenance_delete_title),
        content: SizedBox(
          width: 600,
          child: Text(t.maintenance_delete_message.replaceAll('{title}', reminder.title)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.maintenance_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: Text(t.maintenance_delete_confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = MaintenanceService(Supabase.instance.client);
        await service.deleteReminder(reminder.id);
        if (context.mounted) {
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  void _showDetailsDialog(BuildContext context) {
    final t = AppLocalizations.of(context);
    final service = MaintenanceService(Supabase.instance.client);
    final detailPhotos = List<String>.from(reminder.photos);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDetailState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Titel
                  Text(
                    'Details',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Kategorie
                  _buildDetailRow(
                  icon: _categoryIcon(reminder.category),
                  label: t.maintenance_categories,
                  value: _categoryName(reminder.category, t),
                  iconColor: _categoryColor(reminder.category),
                  ),
                  
                  // Titel
                  _buildDetailRow(
                    icon: Icons.title,
                    label: t.maintenance_title_label,
                    value: reminder.title,
                  ),
                  
                  // Beschreibung
                  if (reminder.description != null && reminder.description!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.description,
                      label: t.maintenance_description_label,
                      value: reminder.description!,
                    ),
                  
                  // Fälligkeitsdatum
                  if (reminder.dueDate != null)
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: t.maintenance_due_date_label,
                      value: DateFormat('dd.MM.yyyy').format(reminder.dueDate!),
                    ),
                  
                  // Fälligkeits-Kilometer
                  if (reminder.dueMileage != null)
                    _buildDetailRow(
                      icon: Icons.speed,
                      label: t.maintenance_due_mileage_label,
                      value: '${reminder.dueMileage} km',
                    ),
                  
                  // Wiederholung
                  if (reminder.isRecurring && reminder.recurrenceIntervalDays != null)
                    _buildDetailRow(
                      icon: Icons.repeat,
                      label: t.maintenance_repeat_title,
                      value: _getRecurrenceLabel(reminder),
                    ),
                  
                  // Erinnerung
                  if (reminder.notificationEnabled)
                    _buildDetailRow(
                      icon: Icons.notifications,
                      label: t.maintenance_notification_title,
                      value: _getNotificationLabel(reminder, t),
                    ),
                  
                  // Werkstatt Name
                  if (reminder.workshopName != null && reminder.workshopName!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.build,
                      label: t.maintenance_workshop_name,
                      value: reminder.workshopName!,
                    ),
                  
                  // Werkstatt Adresse
                  if (reminder.workshopAddress != null && reminder.workshopAddress!.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.location_on,
                      label: t.maintenance_workshop_address,
                      value: reminder.workshopAddress!,
                    ),
                  
                  // Kosten
                  if (reminder.cost != null)
                    _buildDetailRow(
                      icon: Icons.euro,
                      label: t.maintenance_cost_title,
                      value: '${reminder.cost!.toStringAsFixed(2)} €',
                    ),
                  
                  // Notizen
                  if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.notes, color: Colors.white70, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          t.maintenance_notes_title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F141A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reminder.notes!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  
                  // Fotos
                  if (detailPhotos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.photo, color: Colors.white70, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          t.maintenance_photos_title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: detailPhotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (c, i) => FutureBuilder<String?>(
                          future: service.getSignedUrl(detailPhotos[i]),
                          builder: (c, snap) {
                            final url = snap.data;
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: url == null
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (dialogCtx) => Stack(
                                              children: [
                                                GestureDetector(
                                                  onTap: () => Navigator.pop(dialogCtx),
                                                  child: Container(
                                                    color: Colors.black,
                                                    child: InteractiveViewer(
                                                      child: Image.network(url),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 20,
                                                  right: 20,
                                                  child: GestureDetector(
                                                    onTap: () => Navigator.pop(dialogCtx),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F141A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: url == null
                                        ? const Center(child: CircularProgressIndicator())
                                        : Image.network(url, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () async {
                                      detailPhotos.removeAt(i);
                                      await service.updateReminder(id: reminder.id, photos: detailPhotos);
                                      setDetailState(() {});
                                      onRefresh();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  
                  // Dokumente
                  if (reminder.documents.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.white70, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          t.maintenance_documents_title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reminder.documents
                          .map((key) => FutureBuilder<String?>(
                                future: service.getSignedUrl(key),
                                builder: (c, snap) {
                                  final url = snap.data;
                                  return ActionChip(
                                    backgroundColor: const Color(0xFF0F141A),
                                    avatar: const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 18),
                                    label: const Text('PDF', style: TextStyle(color: Colors.white)),
                                    onPressed: url == null
                                        ? null
                                        : () async {
                                            final uri = Uri.parse(url);
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          },
                                  );
                                },
                              ))
                          .toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    final color = iconColor ?? Colors.white70;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRecurrenceLabel(MaintenanceReminder reminder) {
    if (reminder.recurrenceRule != null) {
      final rule = reminder.recurrenceRule!;
      final type = rule['type'];
      final interval = rule['interval'] ?? 1;
      
      if (type == 'daily') {
        return interval == 1 ? 'Jeden Tag' : 'Alle $interval Tage';
      } else if (type == 'weekly') {
        return interval == 1 ? 'Jede Woche' : 'Alle $interval Wochen';
      } else if (type == 'monthly') {
        return interval == 1 ? 'Jeden Monat' : 'Alle $interval Monate';
      } else if (type == 'yearly') {
        return interval == 1 ? 'Jedes Jahr' : 'Alle $interval Jahre';
      }
    }
    final days = reminder.recurrenceIntervalDays!;
    if (days == 1) return 'Jeden Tag';
    if (days == 7) return 'Jede Woche';
    if (days == 30) return 'Jeden Monat';
    if (days == 365) return 'Jedes Jahr';
    return 'Alle $days Tage';
  }
  
  String _getNotificationLabel(MaintenanceReminder reminder, AppLocalizations t) {
    final minutes = reminder.notifyOffsetMinutes;
    if (minutes < 60) {
      return '$minutes Min. vorher';
    } else if (minutes < 1440) {
      return '${minutes ~/ 60} Std. vorher';
    } else {
      return '${minutes ~/ 1440} Tag(e) vorher';
    }
  }
  
  String _categoryName(MaintenanceCategory? cat, AppLocalizations t) {
    if (cat == null) return t.maintenance_category_other;
    switch (cat) {
      case MaintenanceCategory.oilChange:
        return t.maintenance_category_oil_change;
      case MaintenanceCategory.inspection:
        return t.maintenance_category_inspection;
      case MaintenanceCategory.tireChange:
        return t.maintenance_category_tire_change;
      case MaintenanceCategory.brakes:
        return t.maintenance_category_brakes;
      case MaintenanceCategory.battery:
        return t.maintenance_category_battery;
      case MaintenanceCategory.filter:
        return t.maintenance_category_filter;
      case MaintenanceCategory.tuv:
        return t.maintenance_category_tuv;
      case MaintenanceCategory.insurance:
        return t.maintenance_category_insurance;
      case MaintenanceCategory.tax:
        return t.maintenance_category_tax;
      case MaintenanceCategory.other:
        return t.maintenance_category_other;
    }
  }

  void _showOptions(BuildContext context) {
    final t = AppLocalizations.of(context);
    final service = MaintenanceService(Supabase.instance.client);
    final photos = List<String>.from(reminder.photos);
    final documents = List<String>.from(reminder.documents);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details-Button (für alle Wartungen)
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
                      title: const Text(
                        'Details',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDetailsDialog(context);
                      },
                    ),

                    if (!reminder.isCompleted) ...[
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                        title: Text(
                          t.maintenance_mark_complete,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _completeReminder(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                        title: Text(
                          t.maintenance_edit,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExtendedCreateReminderScreen(existing: reminder),
                            ),
                          );
                          if (changed == true && context.mounted) onRefresh();
                        },
                      ),
                    ],

                    if (reminder.isCompleted) ...[
                      ListTile(
                        leading: const Icon(Icons.refresh, color: Color(0xFF1976D2)),
                        title: Text(
                          t.maintenance_mark_incomplete,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _uncompleteReminder(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.upload_file, color: Color(0xFF1976D2)),
                        title: Text(
                          '${t.maintenance_photos_title} / ${t.maintenance_documents_title}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF151C23),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (subCtx) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.upload_file, color: Colors.white70),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${t.maintenance_photos_title} / ${t.maintenance_documents_title}',
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                                            if (picked != null && picked.path.isNotEmpty) {
                                              final key = await service.uploadPhoto(picked.path);
                                              if (key != null) {
                                                photos.add(key);
                                                await service.updateReminder(id: reminder.id, photos: photos);
                                                if (context.mounted) {
                                                  Navigator.pop(subCtx);
                                                  onRefresh();
                                                }
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.photo_camera, color: Color(0xFF1976D2)),
                                          label: Text(t.maintenance_photos_add, style: const TextStyle(color: Color(0xFF1976D2))),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1976D2))),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                                            if (res != null && res.files.single.path != null) {
                                              final key = await service.uploadDocument(res.files.single.path!);
                                              if (key != null) {
                                                documents.add(key);
                                                await service.updateReminder(id: reminder.id, documents: documents);
                                                if (context.mounted) {
                                                  Navigator.pop(subCtx);
                                                  onRefresh();
                                                }
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1976D2)),
                                          label: Text(t.maintenance_documents_upload_pdf, style: const TextStyle(color: Color(0xFF1976D2))),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1976D2))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (photos.isNotEmpty || documents.isNotEmpty) ...[
                        Text(t.maintenance_photos_title, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        if (photos.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (c, i) => FutureBuilder<String?>(
                                future: service.getSignedUrl(photos[i]),
                                builder: (c, snap) {
                                  final url = snap.data;
                                  return Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: url == null
                                            ? null
                                            : () {
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogCtx) => Stack(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () => Navigator.pop(dialogCtx),
                                                        child: Container(
                                                          color: Colors.black,
                                                          child: InteractiveViewer(
                                                            child: url == null ? const SizedBox.shrink() : Image.network(url),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 20,
                                                        right: 20,
                                                        child: GestureDetector(
                                                          onTap: () => Navigator.pop(dialogCtx),
                                                          child: Container(
                                                            padding: const EdgeInsets.all(6),
                                                            decoration: const BoxDecoration(
                                                              color: Colors.red,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: const Icon(Icons.close, color: Colors.white, size: 24),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F141A),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: url == null
                                              ? const Center(child: Icon(Icons.image, color: Colors.white24))
                                              : Image.network(url, fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () async {
                                            photos.removeAt(i);
                                            await service.updateReminder(id: reminder.id, photos: photos);
                                            setSt(() {});
                                            onRefresh();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemCount: photos.length,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (documents.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(t.maintenance_documents_title, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: documents
                                .map((key) => FutureBuilder<String?>(
                                      future: service.getSignedUrl(key),
                                      builder: (c, snap) {
                                        final url = snap.data;
                                        return ActionChip(
                                          backgroundColor: const Color(0xFF0F141A),
                                          avatar: const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 18),
                                          label: const Text('PDF', style: TextStyle(color: Colors.white)),
                                          onPressed: url == null
                                              ? null
                                              : () async {
                                                  final uri = Uri.parse(url);
                                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                },
                                        );
                                      },
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ],

                    ListTile(
                      leading: const Icon(Icons.delete, color: Color(0xFFE53935)),
                      title: Text(
                        t.maintenance_delete_maintenance,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _deleteReminder(context);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final catColor = _categoryColor(reminder.category);
    final catIcon = _categoryIcon(reminder.category);
    final t = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFF151C23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: _isOverdue() ? 2.0 : 1.0,
          ),
        ),
      child: Row(
        children: [
          // Linke Seite: Kategorie-Icon; bei "erledigt" mit Label darunter
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  catIcon,
                  color: catColor,
                  size: compact ? 18 : 20,
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
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: reminder.isCompleted ? Colors.white : Colors.white,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.dueDate != null
                        ? _formatDate(reminder.dueDate!)
                        : '${reminder.dueMileage ?? 0} km',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (reminder.isCompleted)
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20)
          else
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
      ),
    );
  }
}
