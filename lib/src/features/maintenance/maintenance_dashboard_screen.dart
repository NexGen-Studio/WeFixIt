import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../i18n/app_localizations.dart';
import '../../models/maintenance_reminder.dart';
import '../../services/maintenance_service.dart';
import '../../services/maintenance_notification_service.dart';
import '../../services/costs_service.dart';
import '../../services/admob_service.dart';
import '../../services/maintenance_counter_service.dart';
import '../../services/purchase_service.dart';
import '../../services/maintenance_export_service.dart';
import '../../services/supabase_service.dart';
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
  final _adMobService = AdMobService();
  final _counterService = MaintenanceCounterService();
  final _purchaseService = PurchaseService();
  List<MaintenanceReminder> _reminders = [];
  bool _loading = true;
  bool _isPro = false;
  bool _adJustDismissed = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadReminders();
  }
  
  Future<void> _initializeServices() async {
    await _adMobService.initialize();
    await _adMobService.loadRewardedAd(); // Preload ad
    _isPro = await _purchaseService.isPro();
    if (mounted) setState(() {});
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
              if (r.dueDate == null) return false;
              final now = DateTime.now();
              final due = r.dueDate!.toLocal();
              // Anstehend = noch nicht überfällig
              return due.isAfter(now) || due.isAtSameMomentAs(now);
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

  // Alle verfügbaren Kategorien
  final List<MaintenanceCategory> _allCategories = MaintenanceCategory.values;

  void _showLockedFeatureDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, color: Color(0xFFFFB129)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.tr('dialog.category_locked_title'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const Icon(Icons.lock_outline, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('maintenance.lock_message'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('dialog.unlock_with'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _buildUnlockOption(Icons.check_circle, t.tr('subscription.pro_monthly'), t.tr('subscription.pro_monthly_price')),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.tr('common.cancel'), style: const TextStyle(color: Colors.white60)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/paywall');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB129),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(t.tr('common.go_to_paywall')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockOption(IconData icon, String title, String price) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFB129), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            color: Color(0xFFFFB129), 
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Zeigt den Export-Dialog an
  Future<void> _showExportDialog() async {
    final t = AppLocalizations.of(context);
    
    // Prüfe ob Wartungen vorhanden sind
    if (_reminders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.tr('maintenance.no_upcoming')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Pro Status abrufen
    // Nur Pro-User dürfen Wartungen exportieren (Lifetime NUR für Kosten)
    final isPro = await _purchaseService.isPro();
    
    String exportFormat = 'pdf';
    DateTime? startDate;
    DateTime? endDate;
    
    // Alle Kategorien ausgewählt (nur verfügbare wenn Free)
    final Set<MaintenanceCategory> selectedCategories = {};
    if (isPro) {
      selectedCategories.addAll(_allCategories);
    } else {
      // Free User: Nur 4 Basis-Kategorien
      selectedCategories.addAll(MaintenanceCategoryExtension.freeCategories);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tr('maintenance.export_dialog_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Format Auswahl
                Text(
                  t.tr('maintenance.export_format'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(t.tr('maintenance.export_pdf_document')),
                        selected: exportFormat == 'pdf',
                        onSelected: (selected) => setStateSheet(() => exportFormat = 'pdf'),
                        selectedColor: const Color(0xFFFFB129),
                        labelStyle: TextStyle(
                          color: exportFormat == 'pdf' ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: const Color(0xFF1A2028),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(t.tr('maintenance.export_csv_table')),
                        selected: exportFormat == 'csv',
                        onSelected: (selected) => setStateSheet(() => exportFormat = 'csv'),
                        selectedColor: const Color(0xFFFFB129),
                        labelStyle: TextStyle(
                          color: exportFormat == 'csv' ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: const Color(0xFF1A2028),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Zeitraum-Filter
                Text(
                  t.tr('maintenance.export_timeframe'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFFFB129),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setStateSheet(() => startDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          startDate != null
                              ? DateFormat('dd.MM.yyyy').format(startDate!)
                              : t.tr('export.from'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2028),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFFFB129),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setStateSheet(() => endDate = DateTime(date.year, date.month, date.day, 23, 59, 59));
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          endDate != null
                              ? DateFormat('dd.MM.yyyy').format(endDate!)
                              : t.tr('export.to'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2028),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // Kategorien Auswahl
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.tr('export.categories'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        setStateSheet(() {
                          if (isPro) {
                            if (selectedCategories.length == _allCategories.length) {
                              selectedCategories.clear();
                            } else {
                              selectedCategories.addAll(_allCategories);
                            }
                          } else {
                            // Free User: Toggle nur verfügbare 4 Kategorien
                            if (selectedCategories.length == MaintenanceCategoryExtension.freeCategories.length) {
                              selectedCategories.clear();
                            } else {
                              selectedCategories.addAll(MaintenanceCategoryExtension.freeCategories);
                            }
                          }
                        });
                      },
                      child: Text(
                        selectedCategories.isNotEmpty ? t.tr('maintenance.export_none_selected') : t.tr('maintenance.filter_all'),
                        style: const TextStyle(color: Color(0xFFFFB129)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2028),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _allCategories.length,
                      itemBuilder: (context, index) {
                        final category = _allCategories[index];
                        final isSelected = selectedCategories.contains(category);
                        
                        // Lock-Check: Nur 4 Kategorien sind free
                        final isLocked = !isPro && !category.isFreeCategory;
                        
                        return ListTile(
                          onTap: () {
                            if (isLocked) {
                              // Zeige Paywall-Overlay
                              _showLockedFeatureDialog();
                            } else {
                              setStateSheet(() {
                                if (isSelected) {
                                  selectedCategories.remove(category);
                                } else {
                                  selectedCategories.add(category);
                                }
                              });
                            }
                          },
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFB129) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFFB129) : Colors.white54,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isSelected 
                                ? const Icon(Icons.check, size: 16, color: Colors.black)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                _getCategoryDisplayName(category, t),
                                style: TextStyle(
                                  color: isLocked ? Colors.white38 : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              if (isLocked) ...[
                                const Spacer(),
                                const Icon(Icons.lock, size: 16, color: Color(0xFFFFB129)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Upgrade-Hinweis für Free-User
                if (!isPro) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: Color(0xFFFFB129)),
                      const SizedBox(width: 8),
                      Text(
                        t.tr('maintenance.export_upgrade_message'),
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedCategories.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            _performExport(
                              exportFormat,
                              selectedCategories.toList(),
                              startDate,
                              endDate,
                            );
                          },
                    icon: const Icon(Icons.download),
                    label: Text(t.tr('maintenance.export_download')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB129),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Führt den Export aus
  Future<void> _performExport(
    String format,
    List<MaintenanceCategory> categories,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final t = AppLocalizations.of(context);
    try {
      // Paywall-Check für PDF-Export: Nur Pro-User
      if (format == 'pdf') {
        final isPro = await _purchaseService.isPro();
        
        // Free-User dürfen nur 4 Basis-Kategorien exportieren
        if (!isPro) {
          final hasLockedCategory = categories.any((cat) => !cat.isFreeCategory);
          if (hasLockedCategory) {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: const Color(0xFF1A2028),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pro Feature',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t.tr('maintenance.lock_message'),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(t.tr('common.cancel'), style: const TextStyle(color: Colors.white60)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/paywall');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB129),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Upgrade'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            return;
          }
        }
      }
      
      // Filtere Wartungen basierend auf Auswahl und Datum
      final filteredReminders = _reminders.where((r) {
        // Kategorie-Filter
        if (r.category != null && !categories.contains(r.category)) return false;
        // Datum-Filter
        final reminderDate = r.dueDate ?? r.createdAt;
        if (startDate != null && reminderDate.isBefore(startDate)) return false;
        if (endDate != null && reminderDate.isAfter(endDate)) return false;
        return true;
      }).toList();

      if (filteredReminders.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.tr('maintenance.no_data_in_timeframe')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Fahrzeugdaten laden
      VehicleData? vehicleData;
      try {
        final vehicleMap = await SupabaseService(Supabase.instance.client).fetchPrimaryVehicle();
        if (vehicleMap != null) {
          vehicleData = VehicleData(
            make: vehicleMap['make'] as String?,
            model: vehicleMap['model'] as String?,
            year: vehicleMap['year'] as int?,
            engineCode: vehicleMap['engine_code'] as String?,
            vin: vehicleMap['vin'] as String?,
            displacementCc: vehicleMap['displacement_cc'] as int?,
            displacementL: (vehicleMap['displacement_l'] as num?)?.toDouble(),
            mileageKm: vehicleMap['mileage_km'] as int?,
            powerKw: vehicleMap['power_kw'] as int?,
          );
        }
      } catch (e) {
        print('Fehler beim Laden der Fahrzeugdaten: $e');
      }

      final exportService = MaintenanceExportService();

      if (format == 'csv') {
        await exportService.exportToCsv(
          filteredReminders,
          vehicleData: vehicleData,
        );
      } else {
        await exportService.exportToPdf(
          filteredReminders,
          vehicleData: vehicleData,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export erfolgreich!'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Gibt den Anzeigenamen für eine Kategorie zurück
  String _getCategoryDisplayName(MaintenanceCategory category, AppLocalizations t) {
    switch (category) {
      case MaintenanceCategory.oilChange:
        return t.tr('maintenance.category_oil_change');
      case MaintenanceCategory.tireChange:
        return t.tr('maintenance.category_tire_change');
      case MaintenanceCategory.brakes:
        return t.tr('maintenance.category_brakes');
      case MaintenanceCategory.tuv:
        return t.tr('maintenance.category_tuv');
      case MaintenanceCategory.inspection:
        return t.tr('maintenance.category_inspection');
      case MaintenanceCategory.battery:
        return t.tr('maintenance.category_battery');
      case MaintenanceCategory.filter:
        return t.tr('maintenance.category_filter');
      case MaintenanceCategory.insurance:
        return t.tr('maintenance.category_insurance');
      case MaintenanceCategory.tax:
        return t.tr('maintenance.category_tax');
      case MaintenanceCategory.other:
        return t.tr('maintenance.category_other');
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _showExportDialog,
            tooltip: 'Export',
          ),
        ],
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
                            color: const Color(0xFF2196F3),
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
                            color: const Color(0xFF4CAF50),
                            onTap: () async {
                              await _handleNewMaintenance();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.payments,
                            title: t.maintenance_costs,
                            color: const Color(0xFF388E3C),
                            onTap: () {
                              context.push('/costs');
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
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            t.maintenance_overdue_badge,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Scrollbarer Container - max 3 Einträge sichtbar
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _overdueReminders.length > 3 ? 300 : _overdueReminders.length * 100.0,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: _overdueReminders.length > 3 
                              ? const AlwaysScrollableScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemCount: _overdueReminders.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReminderCard(
                                reminder: _overdueReminders[index],
                                onRefresh: _loadReminders,
                              ),
                            );
                          },
                        ),
                      ),
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
                      // Scrollbarer Container - max 3 Einträge sichtbar
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _upcomingReminders.length > 3 ? 300 : _upcomingReminders.length * 100.0,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: _upcomingReminders.length > 3 
                              ? const AlwaysScrollableScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemCount: _upcomingReminders.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReminderCard(
                                reminder: _upcomingReminders[index],
                                onRefresh: _loadReminders,
                              ),
                            );
                          },
                        ),
                      ),

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
                      // Scrollbarer Container für erledigte Wartungen - max 3 sichtbar
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _recentCompleted.length > 3 ? 300 : _recentCompleted.length * 100.0,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: _recentCompleted.length > 3 
                              ? const AlwaysScrollableScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemCount: _completedGroupedByMonth.length,
                          itemBuilder: (context, monthIndex) {
                            final entry = _completedGroupedByMonth.entries.elementAt(monthIndex);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  /// Handle new maintenance creation with ad gate
  Future<void> _handleNewMaintenance() async {
    // Pro users bypass ad gate
    if (_isPro) {
      await context.push('/maintenance/create');
      _loadReminders();
      return;
    }

    // Check if user needs to watch ad
    final needsAd = await _counterService.needsToWatchAd();
    
    if (needsAd) {
      // Show ad gate dialog
      _showAdGateDialog();
    } else {
      // User has free slots, proceed
      await context.push('/maintenance/create');
      await _counterService.incrementCount();
      _loadReminders();
    }
  }

  /// Show ad gate dialog
  void _showAdGateDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.tr('maintenance.ad_gate_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          t.tr('maintenance.ad_gate_message'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.common_cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/paywall');
            },
            child: Text(
              t.tr('maintenance.become_pro'),
              style: const TextStyle(color: Color(0xFFFFB129)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _watchAdAndProceed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB129),
              foregroundColor: Colors.black,
            ),
            child: Text(t.tr('maintenance.watch_video')),
          ),
        ],
      ),
    );
  }

  /// Watch ad and proceed to maintenance creation
  Future<void> _watchAdAndProceed() async {
    print('\n🟢 [UI] ========== _watchAdAndProceed STARTED ==========');
    
    // CRITICAL: Save router BEFORE showing ad
    // The widget may be disposed during the AdActivity
    final router = GoRouter.of(context);

    // Prepare ad (wait if needed) - NO LOADING DIALOG
    print('🟢 [UI] Calling prepareRewardedAd()...');
    final ready = await _adMobService.prepareRewardedAd();
    print('✅ [UI] prepareRewardedAd() returned: $ready');

    if (ready) {
      print('🟢 [UI] Ad is ready, calling showRewardedAd()...');
      final success = await _adMobService.showRewardedAd();
      print('✅ [UI] showRewardedAd() RETURNED with success: $success');
      
      if (success) {
        print('🟢 [UI] User earned reward, resetting counter...');
        // User watched ad, reset counter
        await _counterService.resetCount();
        print('✅ [UI] Counter reset');
        
        // Navigate using saved GoRouter
        print('🟢 [UI] Navigating to /maintenance/create with saved router...');
        try {
          await router.push('/maintenance/create');
          print('✅ [UI] Navigation completed!');
          
          print('🟢 [UI] Incrementing counter...');
          await _counterService.incrementCount();
          print('🟢 [UI] Reloading reminders...');
          _loadReminders();
          print('✅ [UI] All done!');
        } catch (e) {
          print('❌ [UI] Navigation error: $e');
        }
      } else {
        print('⚠️ [UI] Ad did not succeed (user cancelled or error)');
      }
    } else {
      print('❌ [UI] Ad NOT ready!');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Werbung konnte nicht geladen werden. Bitte versuche es später erneut.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('🟢 [UI] ========== _watchAdAndProceed FINISHED ==========\n');
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
          height: 130, // Feste Höhe für gleichmäßige Cards
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF22303D)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
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
        return const Color(0xFF90A4AE);
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
    return const Color(0xFF90A4AE);
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
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (ctx) => _DeleteReminderDialog(
        reminder: reminder,
        t: t,
      ),
    );

    if (result?['confirmed'] == true) {
      try {
        final service = MaintenanceService(Supabase.instance.client);
        
        // Delete associated vehicle cost if requested and cost exists
        if (result?['deleteCost'] == true && reminder.cost != null && reminder.cost! > 0) {
          try {
            // Find and delete vehicle cost linked to this reminder
            final costsService = CostsService();
            final costs = await costsService.fetchAllCosts();
            final linkedCost = costs.where((c) => c.maintenanceReminderId == reminder.id).firstOrNull;
            if (linkedCost != null) {
              await costsService.deleteCost(linkedCost.id);
            }
          } catch (e) {
            print('Error deleting linked vehicle cost: $e');
            // Continue with reminder deletion even if cost deletion fails
          }
        }
        
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
    final detailDocuments = List<String>.from(reminder.documents);
    
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
                  
                  // Reifenart (nur bei Reifenwechsel)
                  if (reminder.category == MaintenanceCategory.tireChange && reminder.notes != null) ...
                    () {
                      final tireTypes = <String>[];
                      if (reminder.notes!.contains('summer')) tireTypes.add('Sommerreifen');
                      if (reminder.notes!.contains('winter')) tireTypes.add('Winterreifen');
                      if (tireTypes.isNotEmpty) {
                        return [_buildDetailRow(
                          icon: Icons.tire_repair,
                          label: 'Reifenart',
                          value: tireTypes.join(', '),
                        )];
                      }
                      return <Widget>[];
                    }(),
                  
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
                      value: DateFormat('dd.MM.yyyy HH:mm').format(reminder.dueDate!.toLocal()),
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
                      value: _getRecurrenceLabel(reminder, t),
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
                  
                  // Notizen (ohne Meta-Tags)
                  if (reminder.notes != null && reminder.notes!.isNotEmpty) ...
                    () {
                      // Entferne [meta:...] aus den Notizen
                      final cleanNotes = reminder.notes!.replaceAll(RegExp(r'\[meta:[^\]]+\]'), '').trim();
                      if (cleanNotes.isEmpty) return <Widget>[];
                      
                      return [
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
                            cleanNotes,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ];
                    }(),
                  
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
                                      final photoToDelete = detailPhotos[i];
                                      detailPhotos.removeAt(i);
                                      
                                      // Lösche Datei aus Supabase Storage
                                      try {
                                        await Supabase.instance.client.storage
                                          .from('maintenance-files')
                                          .remove([photoToDelete]);
                                      } catch (e) {
                                        print('⚠️ Fehler beim Löschen des Fotos: $e');
                                      }
                                      
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
                  if (detailDocuments.isNotEmpty) ...[
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
                      children: detailDocuments.asMap().entries.map((entry) {
                        final i = entry.key;
                        final key = entry.value;
                        return FutureBuilder<String?>(
                          future: service.getSignedUrl(key),
                          builder: (c, snap) {
                            final url = snap.data;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ActionChip(
                                  backgroundColor: const Color(0xFF0F141A),
                                  avatar: const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 18),
                                  label: const Text('PDF', style: TextStyle(color: Colors.white)),
                                  onPressed: url == null
                                      ? null
                                      : () async {
                                          final uri = Uri.parse(url);
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        },
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final docToDelete = detailDocuments[i];
                                      detailDocuments.removeAt(i);
                                      
                                      // Lösche Datei aus Supabase Storage
                                      try {
                                        await Supabase.instance.client.storage
                                          .from('maintenance-files')
                                          .remove([docToDelete]);
                                      } catch (e) {
                                        print('⚠️ Fehler beim Löschen des Dokuments: $e');
                                      }
                                      
                                      await service.updateReminder(id: reminder.id, documents: detailDocuments);
                                      setDetailState(() {});
                                      onRefresh();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }).toList(),
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
  
  String _getRecurrenceLabel(MaintenanceReminder reminder, AppLocalizations t) {
    if (reminder.recurrenceRule != null) {
      final rule = reminder.recurrenceRule!;
      final type = rule['type'];
      final interval = rule['interval'] ?? 1;
      
      if (type == 'daily') {
        return interval == 1 ? t.tr('repeat.every_day') : t.tr('recurrence.every_x_days').replaceAll('{count}', '$interval');
      } else if (type == 'weekly') {
        return interval == 1 ? t.tr('repeat.every_week') : t.tr('recurrence.every_x_weeks_on').replaceAll('{count}', '$interval').replaceAll(' am {days}', '');
      } else if (type == 'monthly') {
        return interval == 1 ? t.tr('repeat.every_month') : t.tr('recurrence.every_x_months_on_day').replaceAll('{count}', '$interval').replaceAll(' am {day}.', '');
      } else if (type == 'yearly') {
        return interval == 1 ? t.tr('repeat.every_year') : t.tr('recurrence.every_x_years_on').replaceAll('{count}', '$interval').replaceAll(' {day}.', '').replaceAll(' {month}', '');
      }
    }
    final days = reminder.recurrenceIntervalDays!;
    if (days == 1) return t.tr('repeat.every_day');
    if (days == 7) return t.tr('repeat.every_week');
    if (days == 30) return t.tr('repeat.every_month');
    if (days == 365) return t.tr('repeat.every_year');
    return t.tr('recurrence.every_x_days').replaceAll('{count}', '$days');
  }
  
  String _getNotificationLabel(MaintenanceReminder reminder, AppLocalizations t) {
    final minutes = reminder.notifyOffsetMinutes;
    if (minutes < 60) {
      return t.tr('reminder.minutes_before').replaceAll('{count}', '$minutes');
    } else if (minutes < 1440) {
      return t.tr('reminder.hours_before').replaceAll('{count}', '${minutes ~/ 60}');
    } else {
      return t.tr('reminder.days_before').replaceAll('{count}', '${minutes ~/ 1440}');
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
                      leading: const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
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
                        leading: const Icon(Icons.edit, color: Color(0xFFFF9800)),
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
                        leading: const Icon(Icons.refresh, color: Color(0xFFFF9800)),
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
                        leading: const Icon(Icons.upload_file, color: Color(0xFF4CAF50)),
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
                                          icon: const Icon(Icons.photo_camera, color: Colors.blue),
                                          label: Text(t.maintenance_photos_add, style: const TextStyle(color: Colors.blue)),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
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
                                          icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                                          label: Text(t.maintenance_documents_add, style: const TextStyle(color: Colors.blue)),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
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
                                            final photoToDelete = photos[i];
                                            photos.removeAt(i);
                                            
                                            // Lösche Datei aus Supabase Storage
                                            try {
                                              await Supabase.instance.client.storage
                                                .from('maintenance-files')
                                                .remove([photoToDelete]);
                                            } catch (e) {
                                              print('⚠️ Fehler beim Löschen des Fotos: $e');
                                            }
                                            
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
                            children: documents.asMap().entries.map((entry) {
                              final i = entry.key;
                              final key = entry.value;
                              return FutureBuilder<String?>(
                                future: service.getSignedUrl(key),
                                builder: (c, snap) {
                                  final url = snap.data;
                                  return Stack(
                                    children: [
                                      ActionChip(
                                        backgroundColor: const Color(0xFF0F141A),
                                        avatar: const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 18),
                                        label: const Text('PDF', style: TextStyle(color: Colors.white)),
                                        onPressed: url == null
                                            ? null
                                            : () async {
                                                final uri = Uri.parse(url);
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              },
                                      ),
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final docToDelete = documents[i];
                                            documents.removeAt(i);
                                            
                                            // Lösche Datei aus Supabase Storage
                                            try {
                                              await Supabase.instance.client.storage
                                                .from('maintenance-files')
                                                .remove([docToDelete]);
                                            } catch (e) {
                                              print('⚠️ Fehler beim Löschen des Dokuments: $e');
                                            }
                                            
                                            await service.updateReminder(id: reminder.id, documents: documents);
                                            setSt(() {});
                                            onRefresh();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }).toList(),
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
                // Nur anzeigen wenn Datum ODER KM gesetzt ist
                if (!compact && (reminder.dueDate != null || reminder.dueMileage != null)) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.dueDate != null
                        ? _formatDate(reminder.dueDate!)
                        : '${reminder.dueMileage} km',
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

// Delete Reminder Dialog mit optionalem Switch für Fahrzeugkosten
class _DeleteReminderDialog extends StatefulWidget {
  final MaintenanceReminder reminder;
  final AppLocalizations t;

  const _DeleteReminderDialog({
    required this.reminder,
    required this.t,
  });

  @override
  State<_DeleteReminderDialog> createState() => _DeleteReminderDialogState();
}

class _DeleteReminderDialogState extends State<_DeleteReminderDialog> {
  bool _deleteCost = false;

  @override
  Widget build(BuildContext context) {
    final hasCost = widget.reminder.cost != null && widget.reminder.cost! > 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        widget.t.maintenance_delete_title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.t.maintenance_delete_message.replaceAll('{title}', widget.reminder.title),
              style: const TextStyle(color: Colors.white70),
            ),
            if (hasCost) ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3139),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: SwitchListTile(
                  value: _deleteCost,
                  onChanged: (value) {
                    setState(() {
                      _deleteCost = value;
                    });
                  },
                  title: Text(
                    widget.t.maintenance_delete_cost_option,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${widget.reminder.cost!.toStringAsFixed(2)}€',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  activeColor: const Color(0xFFFFB129),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'confirmed': false, 'deleteCost': false}),
          child: Text(
            widget.t.maintenance_cancel,
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {'confirmed': true, 'deleteCost': _deleteCost}),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
          ),
          child: Text(
            widget.t.maintenance_delete_confirm,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
