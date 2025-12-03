import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../i18n/app_localizations.dart';
import '../../../services/costs_service.dart';
import '../../../services/category_service.dart';
import '../../../models/cost_category.dart';

/// Statistik-Tab: Tabellen mit Berechnungen und Insights
class CostsStatisticsTab extends StatefulWidget {
  final ScrollController scrollController;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;
  
  const CostsStatisticsTab({
    Key? key, 
    required this.scrollController,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<CostsStatisticsTab> createState() => _CostsStatisticsTabState();
}

class _CostsStatisticsTabState extends State<CostsStatisticsTab> {
  final CostsService _costsService = CostsService();
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = true;
  List<CostCategory> _categories = [];
  Map<String, double> _costsByCategory = {};
  double _totalCosts = 0;
  double _totalIncome = 0;
  double _avgMonthly = 0;
  double _avgMonthlyIncome = 0;
  double _costsThisMonth = 0;
  double _incomeThisMonth = 0;
  int _entriesCount = 0;
  int _incomeEntriesCount = 0;
  bool _showIncome = false; // Toggle zwischen Kosten und Einnahmen
  Timer? _toggleTimer;
  double? _avgFuelConsumption;
  FuelTrend _fuelTrend = FuelTrend.stable;
  String? _cheapestStation;

  @override
  void initState() {
    super.initState();
    loadData();
    
    // Timer für automatischen Wechsel zwischen Kosten/Einnahmen
    _toggleTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() => _showIncome = !_showIncome);
      }
    });
  }
  
  @override
  void didUpdateWidget(CostsStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate || widget.endDate != oldWidget.endDate) {
      loadData();
    }
  }
  
  @override
  void dispose() {
    _toggleTimer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _categoryService.fetchAllCategories();
      final costsByCategory = await _costsService.getCostsByCategory(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      final total = await _costsService.getTotalCosts(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      final avgMonthly = await _costsService.getAverageMonthlyCosts(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      final costsThisMonth = await _costsService.getCostsThisMonth();
      final avgConsumption = await _costsService.getAverageFuelConsumption();
      final trend = await _costsService.getFuelConsumptionTrend();
      final cheapest = await _costsService.getCheapestGasStation();
      
      // Anzahl der Einträge laden
      final allCosts = await _costsService.fetchAllCosts(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      
      // Einnahmen separat berechnen
      final incomeCosts = allCosts.where((c) => c.isIncome).toList();
      final expenseCosts = allCosts.where((c) => !c.isIncome).toList();
      final totalIncome = incomeCosts.fold<double>(0.0, (sum, c) => sum + c.amount);
      final incomeThisMonthCosts = await _costsService.fetchAllCosts(
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        endDate: DateTime.now(),
      );
      final incomeThisMonth = incomeThisMonthCosts
          .where((c) => c.isIncome)
          .fold<double>(0.0, (sum, c) => sum + c.amount);
      
      // Durchschnitt Einnahmen berechnen
      // Korrekte Monatsberechnung: Zähle volle Monate zwischen Start und End
      int monthsDiff = (widget.endDate.year - widget.startDate.year) * 12 + 
                       (widget.endDate.month - widget.startDate.month) + 1;
      // Korrektur: Wenn exakt gleicher Tag (z.B. 02.12.2024-02.12.2025), dann -1
      if (widget.endDate.day == widget.startDate.day && monthsDiff > 1) {
        monthsDiff -= 1;
      }
      // Mindestens 1 Monat
      if (monthsDiff <= 0) monthsDiff = 1;
      
      final avgMonthlyIncome = totalIncome / monthsDiff;

      if (mounted) {
        setState(() {
          _categories = categories;
          _costsByCategory = costsByCategory;
          _totalCosts = total;
          _totalIncome = totalIncome;
          _avgMonthly = avgMonthly;
          _avgMonthlyIncome = avgMonthlyIncome;
          _costsThisMonth = costsThisMonth;
          _incomeThisMonth = incomeThisMonth;
          _entriesCount = expenseCosts.length;
          _incomeEntriesCount = incomeCosts.length;
          _avgFuelConsumption = avgConsumption;
          _fuelTrend = trend;
          _cheapestStation = cheapest;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDatePicker() async {
    final t = AppLocalizations.of(context);
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.tr('costs.select_timeframe'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onDateRangeChanged(
                        DateTime.now().subtract(const Duration(days: 7)),
                        DateTime.now(),
                      );
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB129),
                    ),
                    child: Text(t.tr('costs.last_week')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onDateRangeChanged(
                        DateTime.now().subtract(const Duration(days: 30)),
                        DateTime.now(),
                      );
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB129),
                    ),
                    child: Text(t.tr('costs.last_30_days')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onDateRangeChanged(
                        DateTime.now().subtract(const Duration(days: 365)),
                        DateTime.now(),
                      );
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB129),
                    ),
                    child: Text(t.tr('costs.last_year')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showCustomDatePicker();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB129),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t.tr('costs.custom_timeframe')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final t = AppLocalizations.of(context);
    DateTime? start = widget.startDate;
    DateTime? end = widget.endDate;
    
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF151C23),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.tr('costs.custom_timeframe'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t.tr('costs.start_date'),
                  style: const TextStyle(color: Colors.white70),
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    start != null ? DateFormat('dd.MM.yyyy').format(start!) : t.tr('costs.select_date'),
                    style: const TextStyle(color: Color(0xFFFFB129), fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: start ?? DateTime.now(),
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
                  if (date != null && context.mounted) {
                    start = date;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t.tr('costs.end_date'),
                  style: const TextStyle(color: Colors.white70),
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    end != null ? DateFormat('dd.MM.yyyy').format(end!) : t.tr('costs.select_date'),
                    style: const TextStyle(color: Color(0xFFFFB129), fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: end ?? DateTime.now(),
                    firstDate: start ?? DateTime(2000),
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
                  if (date != null && context.mounted) {
                    end = date;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t.tr('common.cancel'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (start != null && end != null) {
                        widget.onDateRangeChanged(start!, end!);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB129),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      t.tr('common.ok'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeitraum-Selektor
          GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151C23),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB129), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFFFFB129), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${DateFormat('dd.MM.yyyy').format(widget.startDate)} - ${DateFormat('dd.MM.yyyy').format(widget.endDate)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Insights-Karten
          if (_avgFuelConsumption != null || _cheapestStation != null)
            _buildInsightsSection(t),

          // Übersicht-Karten (wechseln zwischen Kosten/Einnahmen)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Column(
              key: ValueKey(_showIncome),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        _showIncome ? t.tr('costs.total_income') : t.tr('costs.total_costs'),
                        _showIncome 
                            ? '${_totalIncome.toStringAsFixed(2)} €'
                            : '${_totalCosts.toStringAsFixed(2)} €',
                        Icons.account_balance_wallet,
                        _showIncome ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        t.tr('costs.avg_monthly'),
                        _showIncome
                            ? '${_avgMonthlyIncome.toStringAsFixed(2)} €'
                            : '${_avgMonthly.toStringAsFixed(2)} €',
                        Icons.trending_up,
                        _showIncome ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        t.tr('costs.this_month'),
                        _showIncome
                            ? '${_incomeThisMonth.toStringAsFixed(2)} €'
                            : '${_costsThisMonth.toStringAsFixed(2)} €',
                        Icons.calendar_month,
                        const Color(0xFFFFB129),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        t.tr('costs.entries_count'),
                        _showIncome ? '$_incomeEntriesCount' : '$_entriesCount',
                        Icons.receipt,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Kosten-Tabelle nach Kategorie
          Text(
            t.tr('costs.costs_by_category'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryTable(t),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(AppLocalizations t) {
    return Column(
      children: [
        if (_avgFuelConsumption != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE53935).withOpacity(0.2),
                  const Color(0xFFE53935).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _fuelTrend == FuelTrend.increasing
                        ? Icons.trending_up
                        : _fuelTrend == FuelTrend.decreasing
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: const Color(0xFFE53935),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.tr('costs.avg_fuel_consumption'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_avgFuelConsumption!.toStringAsFixed(1)} l/100km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _fuelTrend == FuelTrend.increasing
                      ? Icons.arrow_upward
                      : _fuelTrend == FuelTrend.decreasing
                          ? Icons.arrow_downward
                          : Icons.remove,
                  color: _fuelTrend == FuelTrend.increasing
                      ? Colors.red
                      : _fuelTrend == FuelTrend.decreasing
                          ? Colors.green
                          : Colors.grey,
                  size: 32,
                ),
              ],
            ),
          ),
        if (_cheapestStation != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.2),
                  const Color(0xFF4CAF50).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_gas_station,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.tr('costs.cheapest_station'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cheapestStation!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.star,
                  color: Color(0xFFFFB129),
                  size: 24,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTable(AppLocalizations t) {
    if (_costsByCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151C23),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            t.tr('costs.no_data'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A2028),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    t.tr('costs.category'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    t.tr('costs.total'),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ..._costsByCategory.entries.map((entry) {
            final category = _categories.firstWhere(
              (c) => c.id == entry.key,
              orElse: () => _categories.first,
            );
            final percentage = (_totalCosts > 0) ? (entry.value / _totalCosts * 100) : 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1A2028), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        CostCategory.getIconData(category.iconName),
                        color: CostCategory.hexToColor(category.colorHex),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${entry.value.toStringAsFixed(2)} €',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: const Color(0xFF1A2028),
                    valueColor: AlwaysStoppedAnimation(
                      CostCategory.hexToColor(category.colorHex),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
