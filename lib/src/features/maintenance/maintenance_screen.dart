import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/login_required_dialog.dart';
import 'add_reminder_dialog.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _service = MaintenanceService(Supabase.instance.client);
  List<MaintenanceReminder> _reminders = [];
  bool _loading = true;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _loading = true);
    try {
      final reminders = await _service.fetchReminders(
        null,
        _showCompleted ? MaintenanceStatus.completed : null,
      );
      if (!mounted) return;
      setState(() {
        _reminders = _showCompleted
            ? reminders
            : reminders.where((r) => !r.isCompleted).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden: $e')),
      );
    }
  }

  Future<void> _completeReminder(MaintenanceReminder reminder) async {
    try {
      await _service.completeReminder(reminder.id);
      _loadReminders();
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _deleteReminder(MaintenanceReminder reminder) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.tr('maintenance.delete_reminder_title')),
        content: Text(t.tr('maintenance.delete_reminder_message').replaceAll('{title}', reminder.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.tr('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteReminder(reminder.id);
      _loadReminders();
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  void _showAddReminderDialog() {
    // Login-Check
    if (Supabase.instance.client.auth.currentUser == null) {
      showLoginRequiredDialog(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AddReminderDialog(
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadReminders();
        },
      ),
    );
  }

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
          onPressed: () => context.go('/maintenance'),
        ),
        title: const Text(
          'Wartungen',
          style: TextStyle(
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: IconButton(
              icon: Icon(
                _showCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                color: const Color(0xFF0A0A0A),
              ),
              onPressed: () {
                setState(() => _showCompleted = !_showCompleted);
                _loadReminders();
              },
              tooltip: 'Erledigte anzeigen',
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Untertitel Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text(
                t.tr('maintenance.reminders_overview'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Liste
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_reminders.isEmpty)
            SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _showCompleted
                            ? t.tr('maintenance.no_completed_reminders')
                            : t.tr('maintenance.no_reminders'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tippe auf + um eine neue anzulegen',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reminder = _reminders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReminderCard(
                        reminder: reminder,
                        onComplete: () => _completeReminder(reminder),
                        onDelete: () => _deleteReminder(reminder),
                      ),
                    );
                  },
                  childCount: _reminders.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        backgroundColor: const Color(0xFF1976D2),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          t.tr('maintenance.new_reminder'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final MaintenanceReminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Color _getStatusColor() {
    if (reminder.isCompleted) return Colors.grey;
    
    if (reminder.reminderType == ReminderType.date && reminder.dueDate != null) {
      final daysUntil = reminder.dueDate!.difference(DateTime.now()).inDays;
      if (daysUntil < 0) return const Color(0xFFE53935); // Rot: überfällig
      if (daysUntil <= 7) return const Color(0xFFF57C00); // Orange: bald fällig
      return const Color(0xFF4CAF50); // Grün: noch Zeit
    }
    
    return const Color(0xFF1976D2); // Blau: kilometer-basiert
  }

  IconData _getIcon() {
    if (reminder.isCompleted) return Icons.check_circle;
    if (reminder.reminderType == ReminderType.date) return Icons.event;
    return Icons.speed;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isCompleted ? Colors.grey[300]! : statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: reminder.isCompleted ? null : onComplete,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(), color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: reminder.isCompleted ? Colors.grey[600] : const Color(0xFF0A0A0A),
                          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (reminder.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            reminder.reminderType == ReminderType.date
                                ? Icons.calendar_today
                                : Icons.speed,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reminder.reminderType == ReminderType.date && reminder.dueDate != null
                                ? _formatDate(reminder.dueDate!)
                                : '${reminder.dueMileage ?? 0} km',
                            style: TextStyle(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (reminder.isRecurring) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!reminder.isCompleted)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
