import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../i18n/app_localizations.dart';
import '../../../services/costs_service.dart';
import '../../../services/category_service.dart';
import '../../../models/cost_category.dart';

/// Diagramm-Tab: Liniendiagramm für Kosten-Verlauf
class CostsChartsTab extends StatefulWidget {
  final ScrollController scrollController;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;
  
  const CostsChartsTab({
    Key? key, 
    required this.scrollController,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<CostsChartsTab> createState() => _CostsChartsTabState();
}

class _CostsChartsTabState extends State<CostsChartsTab> {
  final CostsService _costsService = CostsService();
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = true;
  List<ChartDataPoint> _chartData = [];
  List<CostCategory> _categories = [];
  String? _selectedCategoryId; // null = Gesamt
  double? _yearlyAverage; // Jahresdurchschnitt (unabhängig vom Zeitraum)

  @override
  void initState() {
    super.initState();
    loadData();
    _loadYearlyAverage(); // Lade Jahresdurchschnitt (unabhängig vom Zeitraum)
  }
  
  @override
  void didUpdateWidget(CostsChartsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate || widget.endDate != oldWidget.endDate) {
      loadData();
    }
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _categoryService.fetchAllCategories();
      final chartData = await _costsService.getCostsChartData(
        startDate: widget.startDate,
        endDate: widget.endDate,
        categoryId: _selectedCategoryId,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _chartData = chartData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chart data: $e');
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
          const SizedBox(height: 16),

          // Kategorie-Filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151C23),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tr('costs.category'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  dropdownColor: const Color(0xFF1A2028),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt, color: Color(0xFFFFB129), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            t.tr('costs.all_categories'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    ..._categories.map((cat) => DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(
                            CostCategory.getIconData(cat.iconName),
                            color: CostCategory.hexToColor(cat.colorHex),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            cat.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                    loadData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chart oder "Keine Daten" basierend auf _chartData
          if (_chartData.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.tr('costs.no_chart_data'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Titel
            Text(
              t.tr('costs.costs_trend'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            // Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151C23),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= _chartData.length) {
                          return const Text('');
                        }
                        final date = _chartData[value.toInt()].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd.MM').format(date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}€',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_chartData.length - 1).toDouble(),
                minY: 0,
                maxY: _chartData.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFB129),
                        const Color(0xFFFFB129).withOpacity(0.5),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFFFFB129),
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF151C23),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFB129).withOpacity(0.3),
                          const Color(0xFFFFB129).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF1A2028),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dataPoint = _chartData[spot.x.toInt()];
                        final date = dataPoint.date;
                        final categories = dataPoint.categoryNames;
                        
                        // Kategorienamen direkt verwenden (bereits in richtiger Sprache)
                        final translatedCats = categories.join('\n');

                        return LineTooltipItem(
                          '${DateFormat('dd.MM.yyyy').format(date)}\n$translatedCats\n${spot.y.toStringAsFixed(2)} €',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legende / Statistiken
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151C23),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildStatRow(
                  t.tr('costs.highest_month'),
                  _getHighestMonthText(),
                  Icons.arrow_upward,
                  Colors.red,
                ),
                const Divider(color: Color(0xFF1A2028), height: 24),
                _buildStatRow(
                  t.tr('costs.lowest_month'),
                  _getLowestMonthText(),
                  Icons.arrow_downward,
                  Colors.green,
                ),
                const Divider(color: Color(0xFF1A2028), height: 24),
                _buildStatRow(
                  t.tr('costs.average_month'),
                  _getYearlyAverageText(),
                  Icons.show_chart,
                  const Color(0xFFFFB129),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _getHighestMonthText() {
    if (_chartData.isEmpty) return '0 €';
    
    // Gruppiere nach Monat
    final monthlyTotals = <String, double>{};
    for (var point in _chartData) {
      final monthKey = '${point.date.year}-${point.date.month.toString().padLeft(2, '0')}';
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + point.value;
    }
    
    if (monthlyTotals.isEmpty) return '0 €';
    
    // Finde höchsten Monat
    var highestEntry = monthlyTotals.entries.first;
    for (var entry in monthlyTotals.entries) {
      if (entry.value > highestEntry.value) {
        highestEntry = entry;
      }
    }
    
    // Formatiere Monatsnamen
    final parts = highestEntry.key.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final monthName = DateFormat.MMM('de').format(date);
    
    return '$monthName ${highestEntry.value.toStringAsFixed(2)} €';
  }

  String _getLowestMonthText() {
    if (_chartData.isEmpty) return '0 €';
    
    // Gruppiere nach Monat
    final monthlyTotals = <String, double>{};
    for (var point in _chartData) {
      final monthKey = '${point.date.year}-${point.date.month.toString().padLeft(2, '0')}';
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + point.value;
    }
    
    if (monthlyTotals.isEmpty) return '0 €';
    
    // Finde niedrigsten Monat
    var lowestEntry = monthlyTotals.entries.first;
    for (var entry in monthlyTotals.entries) {
      if (entry.value < lowestEntry.value) {
        lowestEntry = entry;
      }
    }
    
    // Formatiere Monatsnamen
    final parts = lowestEntry.key.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final monthName = DateFormat.MMM('de').format(date);
    
    return '$monthName ${lowestEntry.value.toStringAsFixed(2)} €';
  }

  String _getYearlyAverageText() {
    // WICHTIG: Jahresdurchschnitt ist UNABHÄNGIG vom gewählten Zeitraum
    // und verwendet ALLE Kosten (wie auf dem Homescreen)
    if (_yearlyAverage == null) return '... €';
    return '${_yearlyAverage!.toStringAsFixed(2)} €';
  }
  
  Future<void> _loadYearlyAverage() async {
    try {
      // Lade ALLE Kosten (ohne Zeitraum-Filter)
      final allCosts = await _costsService.fetchAllCosts();
      
      // Filtere nur Ausgaben (keine Einnahmen)
      final expenses = allCosts.where((cost) => !cost.isIncome).toList();
      
      // Berechne Gesamtkosten
      final totalCosts = expenses.fold<double>(0.0, (sum, cost) => sum + cost.amount);
      
      // Jahresdurchschnitt = Gesamtkosten / 12 Monate
      final yearlyAverage = totalCosts / 12;
      
      if (mounted) {
        setState(() => _yearlyAverage = yearlyAverage);
      }
    } catch (e) {
      print('Error loading yearly average: $e');
    }
  }
}
