import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../services/maintenance_export_service.dart';
import '../../services/maintenance_suggestions_service.dart';

/// Neues Wartungs-Dashboard mit Grid-Design
/// Inspiriert von modernem Payment-App Design
class MaintenanceHomeScreen extends StatefulWidget {
  const MaintenanceHomeScreen({super.key});

  @override
  State<MaintenanceHomeScreen> createState() => _MaintenanceHomeScreenState();
}

class _MaintenanceHomeScreenState extends State<MaintenanceHomeScreen> {
  bool _loading = true;
  List<MaintenanceReminder> _allReminders = [];
  Map<String, int> _stats = {};
  double _totalCost = 0.0;
  List<MaintenanceSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final svc = MaintenanceService(Supabase.instance.client);
      final reminders = await svc.fetchReminders(null, null);
      
      // Calculate stats
      int planned = 0, overdue = 0, completed = 0;
      double total = 0.0;
      
      for (var r in reminders) {
        if (r.status == MaintenanceStatus.planned) planned++;
        else if (r.status == MaintenanceStatus.overdue) overdue++;
        else if (r.status == MaintenanceStatus.completed) {
          completed++;
          total += r.cost ?? 0.0;
        }
      }

      // Generiere Suggestions basierend auf Historie
      final suggestionsService = MaintenanceSuggestionsService();
      // Hole aktuellen Kilometerstand vom ersten Fahrzeug (wenn vorhanden)
      int currentMileage = 50000; // Default
      try {
        final vehiclesRes = await Supabase.instance.client
            .from('vehicles')
            .select('mileage_km')
            .limit(1);
        if (vehiclesRes.isNotEmpty && vehiclesRes.first['mileage_km'] != null) {
          currentMileage = vehiclesRes.first['mileage_km'] as int;
        }
      } catch (_) {}
      
      final t = AppLocalizations.of(context);
      final suggestions = suggestionsService.generateSuggestions(
        currentMileage: currentMileage,
        history: reminders,
        t: t,
      );

      if (!mounted) return;
      setState(() {
        _allReminders = reminders;
        _stats = {'planned': planned, 'overdue': overdue, 'completed': completed};
        _totalCost = total;
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(t.maintenance_dashboard_title),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                t.profile_please_login,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                t.profile_login_message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t.profile_login_now),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(t.maintenance_dashboard_title),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar mit Gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1976D2),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                onPressed: _showExportMenu,
                tooltip: t.maintenance_export_title,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                t.maintenance_dashboard_title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 60, right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.maintenance_total_cost,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€${_totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.event_outlined,
                      label: t.maintenance_stats_upcoming,
                      value: '${_stats['planned'] ?? 0}',
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.warning_outlined,
                      label: t.maintenance_stats_overdue,
                      value: '${_stats['overdue'] ?? 0}',
                      color: const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      label: t.maintenance_stats_completed,
                      value: '${_stats['completed'] ?? 0}',
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kategorien Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.maintenance_categories,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _CategoryCard(
                        icon: Icons.oil_barrel_outlined,
                        label: t.maintenance_category_oil_change,
                        color: const Color(0xFFFFB74D),
                        onTap: () => _navigateToCategory(MaintenanceCategory.oilChange),
                      ),
                      _CategoryCard(
                        icon: Icons.tire_repair,
                        label: t.maintenance_category_tire_change,
                        color: const Color(0xFF64B5F6),
                        onTap: () => _navigateToCategory(MaintenanceCategory.tireChange),
                      ),
                      _CategoryCard(
                        icon: Icons.handyman_outlined,
                        label: t.maintenance_category_brakes,
                        color: const Color(0xFFE57373),
                        onTap: () => _navigateToCategory(MaintenanceCategory.brakes),
                      ),
                      _CategoryCard(
                        icon: Icons.verified_outlined,
                        label: t.maintenance_category_tuv,
                        color: const Color(0xFF81C784),
                        onTap: () => _navigateToCategory(MaintenanceCategory.tuv),
                      ),
                      _CategoryCard(
                        icon: Icons.build_circle_outlined,
                        label: t.maintenance_category_inspection,
                        color: const Color(0xFF9575CD),
                        onTap: () => _navigateToCategory(MaintenanceCategory.inspection),
                      ),
                      _CategoryCard(
                        icon: Icons.battery_charging_full,
                        label: t.maintenance_category_battery,
                        color: const Color(0xFFFFD54F),
                        onTap: () => _navigateToCategory(MaintenanceCategory.battery),
                      ),
                      _CategoryCard(
                        icon: Icons.filter_alt_outlined,
                        label: t.maintenance_category_filter,
                        color: const Color(0xFF4DD0E1),
                        onTap: () => _navigateToCategory(MaintenanceCategory.filter),
                      ),
                      _CategoryCard(
                        icon: Icons.more_horiz,
                        label: t.maintenance_category_other,
                        color: const Color(0xFF90A4AE),
                        onTap: () => _navigateToCategory(MaintenanceCategory.other),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Intelligente Vorschläge
          if (_suggestions.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.maintenance_suggestions_title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._suggestions.take(3).map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SuggestionCard(suggestion: suggestion),
                    )),
                  ],
                ),
              ),
            ),

          // Quick Actions
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add_circle_outline,
                          label: t.maintenance_new_reminder,
                          color: const Color(0xFF1976D2),
                          onTap: () => context.push('/maintenance/create'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.history,
                          label: t.maintenance_recently_completed,
                          color: const Color(0xFF4CAF50),
                          onTap: () => context.push('/maintenance'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _navigateToCategory(MaintenanceCategory category) {
    // Navigate to filtered list
    context.push('/maintenance?category=${category.name}');
  }

  Future<void> _exportCsv() async {
    try {
      final exportService = MaintenanceExportService();
      await exportService.exportToCsv(_allReminders);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _exportReport() async {
    try {
      final exportService = MaintenanceExportService();
      await exportService.exportStatsReport(_allReminders, _stats, _totalCost);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  void _showExportMenu() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF1976D2)),
              title: Text(t.maintenance_export_csv),
              onTap: () {
                Navigator.pop(context);
                _exportCsv();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF4CAF50)),
              title: Text(t.maintenance_export_title),
              subtitle: const Text('Detaillierter Report'),
              onTap: () {
                Navigator.pop(context);
                _exportReport();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Statistik Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Kategorie Card Widget
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Suggestion Card Widget
class _SuggestionCard extends StatelessWidget {
  final MaintenanceSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final priorityColor = suggestion.priority == SuggestionPriority.high
        ? const Color(0xFFE53935)
        : suggestion.priority == SuggestionPriority.medium
            ? const Color(0xFFFFA726)
            : const Color(0xFF66BB6A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getCategoryIcon(suggestion.category), color: priorityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(MaintenanceCategory category) {
    switch (category) {
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
    }
  }
}
