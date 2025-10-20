import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import 'edit_reminder_dialog.dart';

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
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<MaintenanceReminder> get _upcomingReminders =>
      _reminders.where((r) => !r.isCompleted).take(3).toList();

  List<MaintenanceReminder> get _overdueReminders =>
      _reminders.where((r) {
        if (r.isCompleted) return false;
        if (r.dueDate == null) return false;
        return r.dueDate!.isBefore(DateTime.now());
      }).toList();

  List<MaintenanceReminder> get _recentCompleted =>
      _reminders.where((r) => r.isCompleted).take(5).toList();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A0A0A)),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          t.maintenance_dashboard_title,
          style: TextStyle(
            color: Color(0xFF0A0A0A),
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

                    // Quick Actions
                    Text(
                      t.maintenance_quick_access,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('KFZ-Kosten Feature kommt bald!')),
                              );
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_upcomingReminders.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            t.maintenance_no_upcoming,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._upcomingReminders.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReminderCard(reminder: r, onRefresh: _loadReminders),
                          )),

                    const SizedBox(height: 24),

                    // Kürzlich erledigt
                    if (_recentCompleted.isNotEmpty) ...[
                      Text(
                        t.maintenance_recently_completed,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._recentCompleted.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReminderCard(reminder: r, compact: true, onRefresh: _loadReminders),
                          )),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
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
                  color: Color(0xFF0A0A0A),
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

  Color _getStatusColor() {
    if (reminder.isCompleted) return Colors.grey;
    if (reminder.reminderType == ReminderType.date && reminder.dueDate != null) {
      final daysUntil = reminder.dueDate!.difference(DateTime.now()).inDays;
      if (daysUntil < 0) return const Color(0xFFE53935);
      if (daysUntil <= 7) return const Color(0xFFF57C00);
      return const Color(0xFF4CAF50);
    }
    return const Color(0xFF1976D2);
  }

  Future<void> _completeReminder(BuildContext context) async {
    final t = AppLocalizations.of(context);
    try {
      final service = MaintenanceService(Supabase.instance.client);
      await service.completeReminder(reminder.id);
      if (context.mounted) {
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.maintenance_completed_success),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.maintenance_uncompleted_success),
            backgroundColor: Color(0xFF1976D2),
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.maintenance_deleted_success),
              backgroundColor: Color(0xFFE53935),
            ),
          );
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

  void _showOptions(BuildContext context) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              reminder.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            
            // Optionen für NICHT ERLEDIGTE Wartungen
            if (!reminder.isCompleted) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                title: Text(t.maintenance_mark_complete),
                onTap: () {
                  Navigator.pop(ctx);
                  _completeReminder(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                title: Text(t.maintenance_edit),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => EditReminderDialog(
                      reminder: reminder,
                      onSaved: () {
                        Navigator.of(dialogCtx).pop();
                        onRefresh();
                      },
                    ),
                  );
                },
              ),
            ],
            
            // Optionen für ERLEDIGTE Wartungen
            if (reminder.isCompleted) ...[
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFF1976D2)),
                title: Text(t.maintenance_mark_incomplete),
                onTap: () {
                  Navigator.pop(ctx);
                  _uncompleteReminder(context);
                },
              ),
            ],
            
            // Löschen ist immer verfügbar
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFE53935)),
              title: Text(t.maintenance_delete),
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
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reminder.isCompleted ? Colors.grey[300]! : statusColor.withOpacity(0.3),
          ),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              reminder.isCompleted ? Icons.check_circle : Icons.event_note,
              color: statusColor,
              size: compact ? 18 : 20,
            ),
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
                    color: reminder.isCompleted ? Colors.grey[600] : const Color(0xFF0A0A0A),
                    decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.dueDate != null
                        ? _formatDate(reminder.dueDate!)
                        : '${reminder.dueMileage ?? 0} km',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
      ),
    );
  }
}
