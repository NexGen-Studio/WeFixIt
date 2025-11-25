import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../i18n/app_localizations.dart';
import '../../../services/costs_service.dart';
import '../../../services/category_service.dart';
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
                        Text(t.tr('costs.category_${cat.name}')),
                      ],
                    ),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
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
                      lastDate: DateTime.now(),
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
                      lastDate: DateTime.now(),
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
                      setState(() => _filterEndDate = date);
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
                icon: const Icon(Icons.file_download, color: Colors.white70),
                onPressed: () {
                  // TODO: CSV Export
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.tr('costs.export_coming_soon'))),
                  );
                },
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
        onTap: () async {
          // Öffne Cost-Form zum Bearbeiten
          await context.push('/costs/edit/${cost.id}');
          loadData();
        },
        onLongPress: () async {
          // Long-Press: Löschen-Dialog
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
                        if (cost.mileage != null) ...[
                          const Text(' • ', style: TextStyle(color: Colors.white70)),
                          Text(
                            '${cost.mileage} km',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
