import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_cost.dart';
import '../models/cost_category.dart';

/// Service für Fahrzeugkosten mit Statistiken & Insights
class CostsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// Alle Kosten abrufen
  Future<List<VehicleCost>> fetchAllCosts({
    String? vehicleId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from('vehicle_costs')
          .select()
          .eq('user_id', userId);

      if (vehicleId != null) {
        query = query.eq('vehicle_id', vehicleId);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      final response = await query.order('date', ascending: false);

      return (response as List)
          .map((json) => VehicleCost.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching costs: $e');
      return [];
    }
  }

  /// Einzelnen Eintrag abrufen
  Future<VehicleCost?> fetchCostById(String id) async {
    try {
      final response = await _supabase
          .from('vehicle_costs')
          .select()
          .eq('id', id)
          .single();

      return VehicleCost.fromJson(response);
    } catch (e) {
      print('Error fetching cost: $e');
      return null;
    }
  }

  /// Kosteneintrag erstellen
  Future<VehicleCost?> createCost(VehicleCost cost) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final data = cost.toJson();
      data['user_id'] = userId;
      data.remove('id'); // ID wird von DB generiert
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _supabase
          .from('vehicle_costs')
          .insert(data)
          .select()
          .single();

      return VehicleCost.fromJson(response);
    } catch (e) {
      print('Error creating cost: $e');
      return null;
    }
  }

  /// Kosteneintrag aktualisieren
  Future<VehicleCost?> updateCost(String id, VehicleCost cost) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final data = cost.toJson();
      data.remove('id');
      data.remove('user_id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _supabase
          .from('vehicle_costs')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return VehicleCost.fromJson(response);
    } catch (e) {
      print('Error updating cost: $e');
      return null;
    }
  }

  /// Kosteneintrag löschen
  Future<bool> deleteCost(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('vehicle_costs')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error deleting cost: $e');
      return false;
    }
  }

  // ============================================================================
  // Statistiken & Berechnungen
  // ============================================================================

  /// Hilfsmethode: Kosten expandieren (periodische Kosten auf Monate aufteilen)
  List<VehicleCost> _expandCosts(List<VehicleCost> costs, DateTime start, DateTime end) {
    final expanded = <VehicleCost>[];
    // Erweitere den Suchzeitraum leicht, um Grenzfälle zu vermeiden
    final effectiveStart = DateTime(start.year, start.month, 1);
    final effectiveEnd = DateTime(end.year, end.month + 1, 0, 23, 59, 59);

    for (final cost in costs) {
      if (cost.periodStartDate != null && cost.periodEndDate != null) {
        // Periodische Kosten
        DateTime current = DateTime(cost.periodStartDate!.year, cost.periodStartDate!.month, 1);
        final periodEnd = cost.periodEndDate!;
        
        // Berechne monatlichen Betrag
        double monthlyAmount;
        if (cost.isMonthlyAmount) {
          monthlyAmount = cost.amount;
        } else {
          // Anzahl Monate im Gesamtzeitraum
          int totalMonths = (periodEnd.year - cost.periodStartDate!.year) * 12 + 
                           periodEnd.month - cost.periodStartDate!.month + 1;
          if (totalMonths < 1) totalMonths = 1;
          monthlyAmount = cost.amount / totalMonths;
        }

        // Iteriere durch Monate bis Ende
        while (current.isBefore(periodEnd) || 
               (current.year == periodEnd.year && current.month == periodEnd.month)) {
          
          // Prüfen ob dieser Monat im angefragten Zeitraum liegt
          final monthEnd = DateTime(current.year, current.month + 1, 0, 23, 59, 59);
          if (!monthEnd.isBefore(effectiveStart) && !current.isAfter(effectiveEnd)) {
            // Wir nehmen den 1. des Monats als Datum für den Eintrag
            expanded.add(cost.copyWith(
              date: current,
              amount: monthlyAmount,
              title: '${cost.title} (${current.month}/${current.year})',
            ));
          }
          
          // Nächster Monat
          current = DateTime(current.year, current.month + 1, 1);
        }
      } else {
        // Normale Kosten: Prüfen ob im Zeitraum
        if (!cost.date.isBefore(effectiveStart) && !cost.date.isAfter(effectiveEnd)) {
          expanded.add(cost);
        }
      }
    }
    return expanded;
  }

  /// Filter für Einnahmen/Ausgaben anwenden
  List<VehicleCost> _filterIncomeExpense(List<VehicleCost> costs, String? categoryId) {
    if (categoryId == null) {
      // Alle Kategorien -> Nur Ausgaben
      return costs.where((c) => !c.isIncome).toList();
    } else {
      // Spezifische Kategorie -> Alles anzeigen (auch Einnahmen, falls gewählt)
      return costs;
    }
  }

  /// Gesamtkosten in Zeitraum
  Future<double> getTotalCosts({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      // Lade alle Kosten (ohne Datumsfilter, damit wir periodische Kosten erwischen)
      final costs = await fetchAllCosts(
        categoryId: categoryId,
      );

      final start = startDate ?? DateTime(2000);
      final end = endDate ?? DateTime(2100);

      final expanded = _expandCosts(costs, start, end);
      final filtered = _filterIncomeExpense(expanded, categoryId);

      return filtered.fold<double>(0.0, (sum, cost) => sum + cost.amount);
    } catch (e) {
      print('Error calculating total costs: $e');
      return 0.0;
    }
  }

  /// Kosten pro Kategorie
  Future<Map<String, double>> getCostsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final costs = await fetchAllCosts(); // Alle laden

      final start = startDate ?? DateTime(2000);
      final end = endDate ?? DateTime(2100);

      final expanded = _expandCosts(costs, start, end);
      final filtered = _filterIncomeExpense(expanded, null); // Nur Ausgaben in Kategorie-Übersicht

      final Map<String, double> result = {};
      for (final cost in filtered) {
        result[cost.categoryId] = (result[cost.categoryId] ?? 0) + cost.amount;
      }

      return result;
    } catch (e) {
      print('Error calculating costs by category: $e');
      return {};
    }
  }

  /// Durchschnittliche Kosten pro Monat
  Future<double> getAverageMonthlyCosts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 365));
      final end = endDate ?? DateTime.now();
      
      final costs = await fetchAllCosts();

      final expanded = _expandCosts(costs, start, end);
      final filtered = _filterIncomeExpense(expanded, null); // Nur Ausgaben

      if (filtered.isEmpty) return 0.0;

      final total = filtered.fold<double>(0.0, (sum, cost) => sum + cost.amount);
      final months = (end.difference(start).inDays / 30).ceil();
      
      return months > 0 ? total / months : total;
    } catch (e) {
      print('Error calculating average monthly costs: $e');
      return 0.0;
    }
  }

  /// Kosten diesen Monat
  Future<double> getCostsThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getTotalCosts(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  // ============================================================================
  // Treibstoff-Statistiken
  // ============================================================================

  /// Durchschnittsverbrauch berechnen (l/100km)
  Future<double?> getAverageFuelConsumption() async {
    try {
      final costs = await fetchAllCosts();
      
      final refuelings = costs.where((c) => 
        c.isRefueling && 
        c.isFullTank && 
        c.tripDistance != null && 
        c.tripDistance! > 0 &&
        c.fuelAmountLiters != null &&
        c.fuelAmountLiters! > 0
      ).toList();

      if (refuelings.isEmpty) return null;

      double totalConsumption = 0;
      for (final refuel in refuelings) {
        final consumption = (refuel.fuelAmountLiters! * 100) / refuel.tripDistance!;
        totalConsumption += consumption;
      }

      return totalConsumption / refuelings.length;
    } catch (e) {
      print('Error calculating fuel consumption: $e');
      return null;
    }
  }

  /// Verbrauchstrend ermitteln (steigend/fallend/gleichbleibend)
  Future<FuelTrend> getFuelConsumptionTrend() async {
    try {
      final costs = await fetchAllCosts();
      
      final refuelings = costs.where((c) => 
        c.isRefueling && 
        c.isFullTank && 
        c.tripDistance != null && 
        c.tripDistance! > 0 &&
        c.fuelAmountLiters != null &&
        c.fuelAmountLiters! > 0
      ).toList();

      if (refuelings.length < 3) return FuelTrend.stable;

      // Letzten 3 Betankungen vergleichen
      final recent = refuelings.take(3).toList();
      final consumptions = recent.map((r) => 
        (r.fuelAmountLiters! * 100) / r.tripDistance!
      ).toList();

      final first = consumptions.first;
      final last = consumptions.last;
      final diff = first - last;

      if (diff > 0.5) return FuelTrend.decreasing; // Verbrauch sinkt
      if (diff < -0.5) return FuelTrend.increasing; // Verbrauch steigt
      return FuelTrend.stable;
    } catch (e) {
      print('Error calculating fuel trend: $e');
      return FuelTrend.stable;
    }
  }

  /// Günstigste Tankstelle finden
  Future<String?> getCheapestGasStation() async {
    try {
      final costs = await fetchAllCosts();
      
      final refuelings = costs.where((c) => 
        c.isRefueling && 
        c.gasStation != null &&
        c.pricePerLiter != null
      ).toList();

      if (refuelings.isEmpty) return null;

      // Gruppieren nach Tankstelle und Durchschnittspreis berechnen
      final Map<String, List<double>> stations = {};
      for (final refuel in refuelings) {
        if (!stations.containsKey(refuel.gasStation)) {
          stations[refuel.gasStation!] = [];
        }
        stations[refuel.gasStation]!.add(refuel.pricePerLiter!);
      }

      // Durchschnitt berechnen und günstigste finden
      String? cheapest;
      double lowestAvg = double.infinity;

      stations.forEach((name, prices) {
        final avg = prices.reduce((a, b) => a + b) / prices.length;
        if (avg < lowestAvg) {
          lowestAvg = avg;
          cheapest = name;
        }
      });

      return cheapest;
    } catch (e) {
      print('Error finding cheapest gas station: $e');
      return null;
    }
  }

  /// Tankstellen-Namen für Autocomplete
  Future<List<String>> getGasStationSuggestions() async {
    try {
      final costs = await fetchAllCosts();
      
      final stations = costs
          .where((c) => c.isRefueling && c.gasStation != null)
          .map((c) => c.gasStation!)
          .toSet()
          .toList();

      stations.sort();
      return stations;
    } catch (e) {
      print('Error fetching gas station suggestions: $e');
      return [];
    }
  }

  // ============================================================================
  // Chart-Daten
  // ============================================================================

  /// Kosten-Verlauf für Liniendiagramm
  Future<List<ChartDataPoint>> getCostsChartData({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 365));
      final end = endDate ?? DateTime.now();
      
      // Lade alle Kosten (Filterung in _expandCosts)
      final costs = await fetchAllCosts(
        categoryId: categoryId,
      );

      // Kategorien laden für Namen Mapping
      final categoriesResponse = await _supabase.from('cost_categories').select();
      final categoriesMap = {
        for (var c in categoriesResponse) c['id'] as String: c['name'] as String
      };

      final expanded = _expandCosts(costs, start, end);
      final filtered = _filterIncomeExpense(expanded, categoryId);

      // Gruppieren nach Tag
      final Map<String, double> dailyAmount = {};
      final Map<String, Set<String>> dailyCategories = {};

      for (final cost in filtered) {
        final key = '${cost.date.year}-${cost.date.month.toString().padLeft(2, '0')}-${cost.date.day.toString().padLeft(2, '0')}';
        
        dailyAmount[key] = (dailyAmount[key] ?? 0) + cost.amount;
        
        if (!dailyCategories.containsKey(key)) {
          dailyCategories[key] = {};
        }
        
        final catName = categoriesMap[cost.categoryId] ?? 'Unbekannt';
        dailyCategories[key]!.add(catName);
      }

      // In ChartDataPoint umwandeln
      final List<ChartDataPoint> chartData = [];
      dailyAmount.forEach((key, value) {
        final parts = key.split('-');
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        
        chartData.add(ChartDataPoint(
            date: date, 
            value: value,
            categoryNames: dailyCategories[key]!.toList()..sort()
        ));
      });

      chartData.sort((a, b) => a.date.compareTo(b.date));
      return chartData;
    } catch (e) {
      print('Error generating chart data: $e');
      return [];
    }
  }

  // ============================================================================
  // Wartungs-Integration
  // ============================================================================

  /// Kosten aus Wartung erstellen
  Future<VehicleCost?> createCostFromMaintenance({
    required String maintenanceReminderId,
    required String categoryId,
    required String title,
    required double amount,
    required DateTime date,
    int? mileage,
  }) async {
    try {
      final cost = VehicleCost(
        id: '', // Wird von DB generiert
        userId: _supabase.auth.currentUser!.id,
        categoryId: categoryId,
        title: title,
        amount: amount,
        date: date,
        mileage: mileage,
        maintenanceReminderId: maintenanceReminderId,
      );

      return await createCost(cost);
    } catch (e) {
      print('Error creating cost from maintenance: $e');
      return null;
    }
  }
}

// ============================================================================
// Hilfsklassen
// ============================================================================

enum FuelTrend {
  increasing, // ↑ Verbrauch steigt
  decreasing, // ↓ Verbrauch sinkt
  stable, // = Verbrauch gleichbleibend
}

class ChartDataPoint {
  final DateTime date;
  final double value;
  final List<String> categoryNames;

  ChartDataPoint({required this.date, required this.value, required this.categoryNames});
}
