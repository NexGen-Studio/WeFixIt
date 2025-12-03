import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/vehicle_cost.dart';
import '../models/cost_category.dart';

/// Service zum Exportieren von Fahrzeugkosten
class CostsExportService {
  
  /// Exportiert Fahrzeugkosten als CSV
  Future<void> exportToCsv(
    List<VehicleCost> costs,
    Map<String, CostCategory> categoriesMap,
  ) async {
    final csv = _generateCsv(costs, categoriesMap);
    final fileName = 'fahrzeugkosten_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WeFixIt Fahrzeugkosten',
        text: 'Hier ist deine Fahrzeugkosten-Historie als CSV-Datei.',
      );
    } catch (e) {
      throw Exception('Fehler beim Exportieren: $e');
    }
  }

  String _generateCsv(
    List<VehicleCost> costs,
    Map<String, CostCategory> categoriesMap,
  ) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Datum;Titel;Kategorie;Betrag;Währung;Kilometerstand;Tankstelle;Liter;Preis/Liter;Volltank;Notizen');
    
    // Daten
    for (var cost in costs) {
      final date = DateFormat('dd.MM.yyyy').format(cost.date);
      final category = categoriesMap[cost.categoryId]?.name ?? 'Unbekannt';
      final amount = cost.amount.toStringAsFixed(2);
      final mileage = cost.mileage?.toString() ?? '';
      final gasStation = _escapeCsv(cost.gasStation ?? '');
      final liters = cost.fuelAmountLiters?.toStringAsFixed(2) ?? '';
      final pricePerLiter = cost.pricePerLiter?.toStringAsFixed(2) ?? '';
      final fullTank = cost.isFullTank ? 'Ja' : 'Nein';
      final notes = _escapeCsv(cost.notes ?? '');
      
      buffer.writeln('$date;${_escapeCsv(cost.title)};$category;$amount;${cost.currency};$mileage;$gasStation;$liters;$pricePerLiter;$fullTank;$notes');
    }
    
    return buffer.toString();
  }

  String _escapeCsv(String text) {
    if (text.contains(';') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  /// Generiert einen Statistik-Report als Text
  Future<void> exportStatsReport(
    List<VehicleCost> costs,
    Map<String, CostCategory> categoriesMap,
    double totalCosts,
    Map<String, double> categoryTotals,
  ) async {
    final report = _generateStatsReport(costs, categoriesMap, totalCosts, categoryTotals);
    final fileName = 'kosten_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(report);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WeFixIt Kosten-Report',
        text: 'Hier ist dein Fahrzeugkosten-Report.',
      );
    } catch (e) {
      throw Exception('Fehler beim Exportieren: $e');
    }
  }

  String _generateStatsReport(
    List<VehicleCost> costs,
    Map<String, CostCategory> categoriesMap,
    double totalCosts,
    Map<String, double> categoryTotals,
  ) {
    final buffer = StringBuffer();
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('     WeFixIt Kosten-Report');
    buffer.writeln('     Erstellt: $now');
    buffer.writeln('═══════════════════════════════════════\n');
    
    buffer.writeln('📊 STATISTIK\n');
    buffer.writeln('Gesamt Einträge: ${costs.length}');
    buffer.writeln('');
    buffer.writeln('💰 GESAMTKOSTEN\n');
    buffer.writeln('Total: €${totalCosts.toStringAsFixed(2)}');
    
    if (costs.isNotEmpty) {
      final avgCost = totalCosts / costs.length;
      buffer.writeln('Durchschnitt: €${avgCost.toStringAsFixed(2)}');
    }
    
    buffer.writeln('\n📂 KOSTEN NACH KATEGORIE\n');
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sortedCategories) {
      final categoryName = categoriesMap[entry.key]?.name ?? 'Unbekannt';
      buffer.writeln('$categoryName: €${entry.value.toStringAsFixed(2)}');
    }
    
    buffer.writeln('\n═══════════════════════════════════════\n');
    
    buffer.writeln('📋 KOSTEN-HISTORIE\n');
    for (var cost in costs) {
      buffer.writeln('─────────────────────────────────────');
      buffer.writeln('${cost.title}');
      final categoryName = categoriesMap[cost.categoryId]?.name ?? 'Unbekannt';
      buffer.writeln('Kategorie: $categoryName');
      buffer.writeln('Datum: ${DateFormat('dd.MM.yyyy').format(cost.date)}');
      buffer.writeln('Betrag: €${cost.amount.toStringAsFixed(2)}');
      if (cost.mileage != null) {
        buffer.writeln('Kilometerstand: ${cost.mileage} km');
      }
      if (cost.isRefueling) {
        buffer.writeln('⛽ Tankvorgang');
        if (cost.fuelAmountLiters != null) {
          buffer.writeln('Menge: ${cost.fuelAmountLiters!.toStringAsFixed(2)} Liter');
        }
        if (cost.pricePerLiter != null) {
          buffer.writeln('Preis/Liter: €${cost.pricePerLiter!.toStringAsFixed(2)}');
        }
        if (cost.gasStation != null && cost.gasStation!.isNotEmpty) {
          buffer.writeln('Tankstelle: ${cost.gasStation}');
        }
      }
      if (cost.notes != null && cost.notes!.isNotEmpty) {
        buffer.writeln('Notizen: ${cost.notes}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Ende des Reports');
    
    return buffer.toString();
  }
}
