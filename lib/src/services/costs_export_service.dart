import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/vehicle_cost.dart';
import '../models/cost_category.dart';

/// Model für Fahrzeugdaten im PDF
class VehicleData {
  final String? make;
  final String? model;
  final int? year;
  final String? engineCode;
  final String? vin;
  final int? displacementCc;
  final double? displacementL;
  final int? mileageKm;
  final int? powerKw;
  
  VehicleData({
    this.make,
    this.model,
    this.year,
    this.engineCode,
    this.vin,
    this.displacementCc,
    this.displacementL,
    this.mileageKm,
    this.powerKw,
  });
  
  String toDisplayString() {
    final parts = <String>[];
    if (make != null) parts.add(make!);
    if (model != null) parts.add(model!);
    if (year != null) parts.add('($year)');
    return parts.join(' ');
  }
  
  List<String> getDetailLines() {
    final lines = <String>[];
    if (engineCode != null) lines.add('Motor: $engineCode');
    if (displacementL != null) lines.add('Hubraum: ${displacementL!.toStringAsFixed(1)}L');
    if (powerKw != null) lines.add('Leistung: ${powerKw}kW');
    if (mileageKm != null) lines.add('Kilometerstand: ${NumberFormat('#,###').format(mileageKm)} km');
    if (vin != null) lines.add('FIN: $vin');
    return lines;
  }
}

/// Service zum Exportieren von Fahrzeugkosten
class CostsExportService {
  
  /// Exportiert Fahrzeugkosten als CSV
  Future<void> exportToCsv(
    List<VehicleCost> costs,
    Map<String, CostCategory> categoriesMap, {
    bool isPro = false,
  }) async {
    if (costs.isEmpty) {
      throw Exception('Keine Kosten zum Exportieren vorhanden');
    }
    
    final csv = _generateCsv(costs, categoriesMap);
    final fileName = 'fahrzeugkosten_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WeFixIt Fahrzeugkosten',
        text: isPro 
            ? 'Hier ist deine vollständige Fahrzeugkosten-Historie als CSV-Datei.'
            : 'Hier sind deine Treibstoff-Kosten als CSV-Datei.',
      );
    } catch (e) {
      throw Exception('Fehler beim Exportieren: $e');
    }
  }

  /// Exportiert Fahrzeugkosten als PDF
  Future<void> exportToPdf(
    List<VehicleCost> costs,
    Map<String, CostCategory> categoriesMap, {
    bool isPro = false,
    VehicleData? vehicleData,
  }) async {
    if (costs.isEmpty) {
      throw Exception('Keine Kosten zum Exportieren vorhanden');
    }
    
    final pdf = await _generatePdf(costs, categoriesMap, vehicleData, isPro);
    final fileName = 'fahrzeugkosten_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WeFixIt Fahrzeugkosten PDF',
        text: isPro 
            ? 'Hier ist deine vollständige Fahrzeugkosten-Historie als PDF.'
            : 'Hier sind deine Treibstoff-Kosten als PDF.',
      );
    } catch (e) {
      throw Exception('Fehler beim PDF-Export: $e');
    }
  }

  Future<pw.Document> _generatePdf(
    List<VehicleCost> costs,
    Map<String, CostCategory> categoriesMap,
    VehicleData? vehicleData,
    bool isPro,
  ) async {
    final pdf = pw.Document();
    
    // Logo laden
    Uint8List? logoData;
    try {
      final data = await rootBundle.load('assets/images/WeFixIt_PDF_Logo.PNG');
      logoData = data.buffer.asUint8List();
    } catch (e) {
      print('Logo konnte nicht geladen werden: $e');
    }
    
    // Statistiken berechnen
    final totalCosts = costs.fold<double>(0, (sum, c) => sum + (c.isIncome ? 0 : c.amount));
    final totalIncome = costs.fold<double>(0, (sum, c) => sum + (c.isIncome ? c.amount : 0));
    final categoryTotals = <String, double>{};
    
    for (var cost in costs) {
      if (cost.isIncome) continue;
      categoryTotals[cost.categoryId] = 
          (categoryTotals[cost.categoryId] ?? 0) + cost.amount;
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header mit Logo und Fahrzeugdaten
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo und Titel untereinander
                if (logoData != null) ...[
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(
                      pw.MemoryImage(logoData),
                      height: 52,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],
                pw.Text(
                  'Fahrzeugkosten',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                
                pw.SizedBox(height: 8),
                pw.Text(
                  'Erstellt am ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                
                // Fahrzeugdaten
                if (vehicleData != null) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Mein Fahrzeug',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    vehicleData.toDisplayString(),
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  ...vehicleData.getDetailLines().map((line) => 
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        line,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ),
                  ),
                ],
                
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 2),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Statistiken
          pw.Text(
            'Übersicht',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildStatRow('Anzahl Einträge:', '${costs.length}'),
                if (isPro) ...[
                  _buildStatRow('Gesamtkosten:', '${totalCosts.toStringAsFixed(2)} EUR'),
                  if (totalIncome > 0)
                    _buildStatRow('Einnahmen:', '${totalIncome.toStringAsFixed(2)} EUR'),
                  _buildStatRow('Netto:', '${(totalCosts - totalIncome).toStringAsFixed(2)} EUR'),
                ] else
                  _buildStatRow('Treibstoff-Kosten:', '${totalCosts.toStringAsFixed(2)} EUR'),
              ],
            ),
          ),
          
          pw.SizedBox(height: 24),
          
          // Kosten nach Kategorie (nur bei Pro)
          if (isPro && categoryTotals.isNotEmpty) ...[
            pw.Text(
              'Kosten nach Kategorie',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Kategorie', isHeader: true, alignment: pw.Alignment.centerLeft),
                    _buildTableCell('Betrag', isHeader: true, alignment: pw.Alignment.centerRight),
                  ],
                ),
                // Daten
                ...categoryTotals.entries.map((entry) {
                  final categoryName = categoriesMap[entry.key]?.name ?? 'Unbekannt';
                  return pw.TableRow(
                    children: [
                      _buildTableCell(categoryName, alignment: pw.Alignment.centerLeft),
                      _buildTableCell('${entry.value.toStringAsFixed(2)} EUR', alignment: pw.Alignment.centerRight),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 24),
          ],
          
          // Kostenhistorie
          pw.Text(
            isPro ? 'Kostenhistorie' : 'Treibstoff-Historie',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          
          // Tabelle der Kosten
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Datum', isHeader: true),
                  _buildTableCell('Titel', isHeader: true),
                  _buildTableCell('Kategorie', isHeader: true),
                  _buildTableCell('Betrag', isHeader: true),
                ],
              ),
              // Daten
              ...costs.map((cost) {
                final categoryName = categoriesMap[cost.categoryId]?.name ?? 'Unbekannt';
                return pw.TableRow(
                  children: [
                    _buildTableCell(DateFormat('dd.MM.yy').format(cost.date)),
                    _buildTableCell(cost.title),
                    _buildTableCell(categoryName),
                    _buildTableCell(
                      '${cost.amount.toStringAsFixed(2)} EUR',
                      textColor: cost.isIncome ? PdfColors.green : PdfColors.black,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                );
              }),
            ],
          ),
          
          pw.SizedBox(height: 20),
          
          // Footer
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Erstellt mit WeFixIt',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
    
    return pdf;
  }

  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? textColor, pw.Alignment? alignment}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: alignment ?? pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 12 : 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
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

  /// Generiert einen Statistik-Report als Text (Legacy-Support)
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
