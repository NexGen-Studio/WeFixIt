import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../i18n/app_localizations.dart';
import '../../../services/costs_service.dart';
import '../../../services/category_service.dart';
import '../../../services/costs_export_service.dart';
import '../../../services/purchase_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/vehicle_cost.dart';
import '../../../models/cost_category.dart';

/// Verlauf-Tab: Chronologische Liste aller Kosten
class CostsHistoryTab extends StatefulWidget {
  final ScrollController scrollController;
  
  const CostsHistoryTab({Key? key, required this.scrollController}) : super(key: key);

  @override
  State<CostsHistoryTab> createState() => _CostsHistoryTabState();
}

class _CostsHistoryTabState extends State<CostsHistoryTab> {
  final CostsService _costsService = CostsService();
  final CategoryService _categoryService = CategoryService();

  List<VehicleCost> _costs = [];
  List<CostCategory> _categories = [];
  bool _isLoading = true;

  // Filter
  String? _selectedCategoryId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);

    try {
      final costs = await _costsService.fetchAllCosts(
        categoryId: _selectedCategoryId,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );

      final categories = await _categoryService.fetchAllCategories();

      setState(() {
        _costs = costs;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading costs: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showCostsCategoryLockedDialog(BuildContext context) {
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
                      ],
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('costs.category_locked_message'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('dialog.unlock_with'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _buildCostsUnlockOption(Icons.star, t.tr('subscription.lifetime_unlock'), t.tr('subscription.lifetime_price')),
                const SizedBox(height: 8),
                _buildCostsUnlockOption(Icons.star, t.tr('subscription.pro_monthly'), t.tr('subscription.pro_monthly_price')),
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

  Widget _buildCostsUnlockOption(IconData icon, String title, String price) {
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

  void _showCostOptionsDialog(VehicleCost cost, CostCategory category, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
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
                cost.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Details
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                title: Text(
                  t.tr('maintenance.details'),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCostDetailsDialog(cost, category, t);
                },
              ),

              // Bearbeiten
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFFF9800)),
                title: Text(
                  t.tr('maintenance.edit'),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.push('/costs/edit/${cost.id}');
                  loadData();
                },
              ),

              // Löschen
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFF44336)),
                title: Text(
                  t.tr('costs.delete'),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF151C23),
                      title: Text(
                        t.tr('costs.delete_confirm_title'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        t.tr('costs.delete_confirm_message'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t.tr('common.cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(t.tr('common.delete')),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _costsService.deleteCost(cost.id);
                    loadData();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCostDetailsDialog(VehicleCost cost, CostCategory category, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                  icon: CostCategory.getIconData(category.iconName),
                  label: t.tr('costs.category_field'),
                  value: category.name,
                  iconColor: CostCategory.hexToColor(category.colorHex),
                ),

                // Titel
                _buildDetailRow(
                  icon: Icons.title,
                  label: t.tr('costs.title_field'),
                  value: cost.title,
                ),

                // Datum
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: t.tr('costs.date'),
                  value: DateFormat('dd.MM.yyyy HH:mm').format(cost.date),
                ),

                // Kilometerstand
                if (cost.mileage != null)
                  _buildDetailRow(
                    icon: Icons.speed,
                    label: t.tr('costs.mileage'),
                    value: '${cost.mileage} km',
                  ),

                // Kosten
                _buildDetailRow(
                  icon: Icons.euro,
                  label: t.tr('costs.amount'),
                  value: '${cost.amount.toStringAsFixed(2)} ${cost.currency}',
                  iconColor: const Color(0xFF4CAF50),
                ),

                // Notizen
                if (cost.notes != null && cost.notes!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.notes,
                    label: t.tr('costs.notes'),
                    value: cost.notes!,
                  ),

                // Fotos
                if (cost.photos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    t.tr('maintenance.photos_title'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cost.photos.map((photoUrl) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
                ],

              ],
            ),
          ),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
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

  void _showExportDialog() async {
    final t = AppLocalizations.of(context);
    
    // 1. Pro/Lifetime Status prüfen
    final isPro = await PurchaseService().isPro();
    final hasLifetime = await PurchaseService().hasCostsUnlock();
    final canExportAll = isPro || hasLifetime;
    
    if (!mounted) return;

    // Initial selection: Nur Treibstoff für Free, Alle für Pro
    final fuelCategory = _categories.firstWhere(
      (c) => c.name.toLowerCase().contains('fuel') || c.name.toLowerCase().contains('treibstoff') || c.name == 'Fuel', // Fallback detection
      orElse: () => _categories.first,
    );
    
    // Set selected categories based on subscription
    final Set<String> selectedCategoryIds = canExportAll 
        ? _categories.map((c) => c.id).toSet()
        : {fuelCategory.id};

    String exportFormat = 'pdf'; // Default 'pdf' or 'csv'
    DateTime? startDate;
    DateTime? endDate;

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
            height: MediaQuery.of(context).size.height * 0.85, // Etwas höher für Datumsfelder
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tr('costs.export_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Format Auswahl
                Text(
                  'Format',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(t.tr('costs.export_pdf')),
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
                        label: Text(t.tr('costs.export_csv_format')),
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
                    if (canExportAll)
                      TextButton(
                        onPressed: () {
                          setStateSheet(() {
                            if (selectedCategoryIds.length == _categories.length) {
                              selectedCategoryIds.clear();
                            } else {
                              selectedCategoryIds.addAll(_categories.map((c) => c.id));
                            }
                          });
                        },
                        child: Text(
                          selectedCategoryIds.length == _categories.length ? 'Keine' : 'Alle',
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
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isFuel = category.id == fuelCategory.id;
                        final isSelected = selectedCategoryIds.contains(category.id);
                        
                        // Free User sehen nur Treibstoff als aktiv, andere ausgegraut
                        final isLocked = !canExportAll && !isFuel;
                        
                        return ListTile(
                          onTap: () {
                            if (isLocked) {
                              _showCostsCategoryLockedDialog(context);
                            } else {
                              setStateSheet(() {
                                if (isSelected) {
                                  selectedCategoryIds.remove(category.id);
                                } else {
                                  selectedCategoryIds.add(category.id);
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
                              Icon(
                                CostCategory.getIconData(category.iconName),
                                color: isLocked 
                                    ? Colors.white30 
                                    : CostCategory.hexToColor(category.colorHex),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category.getLocalizedName(t),
                                  style: TextStyle(
                                    color: isLocked ? Colors.white38 : Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isLocked)
                                const Icon(Icons.lock, size: 16, color: Color(0xFFFFB129)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (!canExportAll)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Color(0xFFFFB129), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.tr('costs.export_upgrade_message'),
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedCategoryIds.isEmpty 
                        ? null 
                        : () {
                            Navigator.pop(context);
                            _performExport(exportFormat, selectedCategoryIds.toList(), canExportAll, startDate, endDate);
                          },
                    icon: const Icon(Icons.download),
                    label: Text(t.tr('maintenance.export_download')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB129),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _performExport(
    String format, 
    List<String> categoryIds, 
    bool isPro, 
    DateTime? startDate, 
    DateTime? endDate,
  ) async {
    final t = AppLocalizations.of(context);
    try {
      // Filtere Kosten basierend auf Auswahl und Datum
      final filteredCosts = _costs.where((c) {
        if (!categoryIds.contains(c.categoryId)) return false;
        if (startDate != null && c.date.isBefore(startDate)) return false;
        if (endDate != null && c.date.isAfter(endDate)) return false;
        return true;
      }).toList();
      
      // Erstelle Map für schnellere Kategorie-Lookups
      final categoriesMap = <String, CostCategory>{};
      for (var cat in _categories) {
        categoriesMap[cat.id] = cat;
      }
      
      final exportService = CostsExportService();
      
      if (format == 'csv') {
        await exportService.exportToCsv(filteredCosts, categoriesMap, isPro: isPro);
      } else {
        // Fahrzeugdaten laden für PDF
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
        
        await exportService.exportToPdf(
          filteredCosts, 
          categoriesMap, 
          isPro: isPro,
          vehicleData: vehicleData,
        );
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.tr('costs.export_success')),
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    final t = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.tr('costs.filter_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          
          // Kategorie-Filter
          Text(
            t.tr('costs.filter_category'),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A2028),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: const Color(0xFF1A2028),
            style: const TextStyle(color: Colors.white),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(t.tr('costs.filter_all_categories')),
              ),
              ..._categories.map((cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Icon(
                          CostCategory.getIconData(cat.iconName),
                          size: 20,
                          color: CostCategory.hexToColor(cat.colorHex),
                        ),
                        const SizedBox(width: 8),
                        Text(cat.getLocalizedName(t)),
                      ],
                    ),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
              // Daten sofort neu laden
              loadData();
            },
          ),
          const SizedBox(height: 24),
          
          // Zeitraum-Filter
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterStartDate ?? DateTime.now(),
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
                      setState(() => _filterStartDate = date);
                      // Daten sofort neu laden
                      loadData();
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _filterStartDate != null
                        ? DateFormat('dd.MM.yyyy').format(_filterStartDate!)
                        : t.tr('costs.filter_start_date'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2028),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterEndDate ?? DateTime.now(),
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
                      // Setze End-Datum auf 23:59:59 um den ganzen Tag einzuschließen
                      setState(() => _filterEndDate = DateTime(date.year, date.month, date.day, 23, 59, 59));
                      // Daten sofort neu laden
                      loadData();
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _filterEndDate != null
                        ? DateFormat('dd.MM.yyyy').format(_filterEndDate!)
                        : t.tr('costs.filter_end_date'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2028),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _filterStartDate = null;
                      _filterEndDate = null;
                    });
                    Navigator.pop(context);
                    loadData();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: Text(t.tr('costs.filter_reset')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB129),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(t.tr('costs.filter_apply')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFFFB129)),
        ),
      );
    }

    return Column(
      children: [
        // Filter-Bar (immer sichtbar)
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF151C23),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_costs.length} ${t.tr('costs.entries')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(t.tr('costs.filter')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white70),
                onPressed: _costs.isEmpty ? null : _showExportDialog,
                tooltip: 'Exportieren',
              ),
            ],
          ),
        ),
        
        // Liste oder "Keine Einträge"
        Expanded(
          child: _costs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.tr('costs.no_entries'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => context.push('/costs/add'),
                        icon: const Icon(Icons.add),
                        label: Text(t.tr('costs.add_first_entry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadData,
                  color: const Color(0xFFFFB129),
                  backgroundColor: const Color(0xFF151C23),
                  child: ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _costs.length,
                    itemBuilder: (context, index) {
                      final cost = _costs[index];
                      final category = _categories.firstWhere(
                        (c) => c.id == cost.categoryId,
                        orElse: () => _categories.first,
                      );
                      
                      return _buildCostCard(cost, category, t);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCostCard(VehicleCost cost, CostCategory category, AppLocalizations t) {
    return Dismissible(
      key: Key(cost.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF151C23),
            title: Text(
              t.tr('costs.delete_confirm_title'),
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              t.tr('costs.delete_confirm_message'),
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.tr('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(t.tr('common.delete')),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _costsService.deleteCost(cost.id);
        loadData();
      },
      child: GestureDetector(
        onTap: () {
          // Normaler Klick: Options-Dialog
          _showCostOptionsDialog(cost, category, t);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151C23),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CostCategory.hexToColor(category.colorHex).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CostCategory.hexToColor(category.colorHex).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CostCategory.getIconData(category.iconName),
                  color: CostCategory.hexToColor(category.colorHex),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cost.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('dd.MM.yyyy').format(cost.date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (cost.photos.isNotEmpty) ...[
                          const Text(' • ', style: TextStyle(color: Colors.white70)),
                          const Icon(
                            Icons.photo,
                            size: 14,
                            color: Color(0xFFFFB129),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Betrag
              Text(
                '${cost.amount.toStringAsFixed(2)} ${cost.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
