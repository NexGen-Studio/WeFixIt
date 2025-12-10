import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/maintenance_reminder.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

/// Fahrzeugdaten für den Export
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
}

/// Service zum Exportieren von Wartungsdaten
class MaintenanceExportService {
  
  /// Exportiert Wartungen als CSV
  Future<void> exportToCsv(
    List<MaintenanceReminder> reminders, {
    VehicleData? vehicleData,
  }) async {
    final csv = _generateCsv(reminders, vehicleData);
    final fileName = 'wartungen_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WeFixIt Wartungshistorie',
        text: 'Hier ist deine Wartungshistorie als CSV-Datei.',
      );
    } catch (e) {
      throw Exception('Fehler beim Exportieren: $e');
    }
  }

  String _generateCsv(List<MaintenanceReminder> reminders, VehicleData? vehicleData) {
    final buffer = StringBuffer();
    
    // Fahrzeugdaten am Anfang (optional)
    if (vehicleData != null) {
      buffer.writeln('WeFixIt Wartungshistorie');
      buffer.writeln('Erstellt: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}');
      buffer.writeln('');
      if (vehicleData.make != null || vehicleData.model != null) {
        buffer.writeln('Fahrzeug: ${vehicleData.make ?? ''} ${vehicleData.model ?? ''}');
      }
      if (vehicleData.year != null) buffer.writeln('Baujahr: ${vehicleData.year}');
      if (vehicleData.vin != null) buffer.writeln('FIN: ${vehicleData.vin}');
      if (vehicleData.engineCode != null) buffer.writeln('Motorcode: ${vehicleData.engineCode}');
      buffer.writeln('');
    }
    
    // Header
    buffer.writeln('Datum;Titel;Kategorie;Typ;Fälligkeit;Kilometerstand;Werkstatt;Adresse;Kosten;Status;Notizen');
    
    // Daten
    for (var r in reminders) {
      final date = DateFormat('dd.MM.yyyy').format(r.createdAt);
      final dueDate = r.dueDate != null ? DateFormat('dd.MM.yyyy').format(r.dueDate!) : '';
      final category = r.category?.toString().split('.').last ?? '';
      final type = r.reminderType == ReminderType.date ? 'Datum' : 'Kilometer';
      final dueMileage = r.dueMileage?.toString() ?? '';
      final workshop = _escapeCsv(r.workshopName ?? '');
      final address = _escapeCsv(r.workshopAddress ?? '');
      final cost = r.cost?.toStringAsFixed(2) ?? '';
      final status = r.status == MaintenanceStatus.planned
          ? 'Geplant'
          : r.status == MaintenanceStatus.completed
              ? 'Erledigt'
              : 'Überfällig';
      final notes = _escapeCsv(r.notes ?? '');
      
      buffer.writeln('$date;${_escapeCsv(r.title)};$category;$type;$dueDate;$dueMileage;$workshop;$address;$cost;$status;$notes');
    }
    
    return buffer.toString();
  }

  String _escapeCsv(String text) {
    if (text.contains(';') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  /// Exportiert Wartungen als PDF
  Future<void> exportToPdf(
    List<MaintenanceReminder> reminders, {
    VehicleData? vehicleData,
  }) async {
    try {
      final pdf = await _generatePdf(reminders, vehicleData);
      final pdfBytes = await pdf.save();
      
      final directory = await getTemporaryDirectory();
      final fileName = 'wartungen_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final pdfFile = File('${directory.path}/$fileName');
      await pdfFile.writeAsBytes(pdfBytes);
      
      // Fotos werden direkt in die PDF eingebettet, keine separaten Dateien nötig
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'WeFixIt Wartungshistorie',
        text: 'Hier ist deine Wartungshistorie als PDF.',
      );
    } catch (e) {
      throw Exception('Fehler beim Exportieren der PDF: $e');
    }
  }

  /// Generiert das PDF-Dokument
  Future<pw.Document> _generatePdf(
    List<MaintenanceReminder> reminders,
    VehicleData? vehicleData,
  ) async {
    final pdf = pw.Document();
    
    // Lade Logo
    Uint8List? logoData;
    try {
      final byteData = await rootBundle.load('assets/images/WeFixIt_PDF_Logo.PNG');
      logoData = byteData.buffer.asUint8List();
    } catch (e) {
      print('Logo konnte nicht geladen werden: $e');
    }
    
    // Berechne Statistik
    final totalReminders = reminders.length;
    final totalCost = reminders.fold<double>(
      0,
      (sum, r) => sum + (r.cost ?? 0),
    );
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header mit Logo und Fahrzeugdaten
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo und Titel untereinander
              if (logoData != null) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(
                    pw.MemoryImage(logoData),
                    height: 60,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              pw.Text(
                'Wartungshistorie',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Erstellt am ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 24),
              
              // Fahrzeugdaten
              if (vehicleData != null) ...[
                pw.Text(
                  'Mein Fahrzeug',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                if (vehicleData.make != null || vehicleData.model != null)
                  _buildPdfInfoRow('Fahrzeug', '${vehicleData.make ?? ''} ${vehicleData.model ?? ''}'),
                if (vehicleData.year != null)
                  _buildPdfInfoRow('Baujahr', '${vehicleData.year}'),
                if (vehicleData.vin != null)
                  _buildPdfInfoRow('FIN', vehicleData.vin!),
                if (vehicleData.engineCode != null)
                  _buildPdfInfoRow('Motorcode', vehicleData.engineCode!),
                if (vehicleData.displacementL != null)
                  _buildPdfInfoRow('Hubraum', '${vehicleData.displacementL!.toStringAsFixed(1)} L'),
                if (vehicleData.powerKw != null)
                  _buildPdfInfoRow('Leistung', '${vehicleData.powerKw} kW'),
                if (vehicleData.mileageKm != null)
                  _buildPdfInfoRow('Kilometerstand', '${vehicleData.mileageKm} km'),
                pw.SizedBox(height: 20),
              ],
              
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 20),
              
              // Übersicht
              pw.Text(
                'Übersicht',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Anzahl Einträge:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('$totalReminders', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Gesamtkosten:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('${totalCost.toStringAsFixed(2)} EUR', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 20),
              
              // Historie-Überschrift
              pw.Text(
                'Wartungs-Historie',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
            ],
          ),
          
          // Historie-Tabelle
          _buildMaintenanceTable(reminders),
        ],
      ),
    );
    
    return pdf;
  }

  /// Baut eine Info-Zeile für das PDF
  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Baut die Wartungs-Tabelle für das PDF
  pw.Widget _buildMaintenanceTable(List<MaintenanceReminder> reminders) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey400),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellHeight: 35,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      headers: ['Datum', 'Titel', 'Kategorie', 'Werkstatt', 'Notizen', 'Kosten', 'Km-Stand'],
      data: reminders.map((r) {
        final date = r.dueDate != null ? DateFormat('dd.MM.yy').format(r.dueDate!) : '-';
        final title = r.title.length > 25 ? '${r.title.substring(0, 25)}...' : r.title;
        final category = _getCategoryDisplayName(r.category);
        final workshop = r.workshopName != null && r.workshopName!.isNotEmpty
            ? (r.workshopName!.length > 20 ? '${r.workshopName!.substring(0, 20)}...' : r.workshopName!)
            : '-';
        final workshopAddress = r.workshopAddress != null && r.workshopAddress!.isNotEmpty
            ? '\n${r.workshopAddress!}'
            : '';
        final notes = r.notes != null && r.notes!.isNotEmpty
            ? (r.notes!.length > 30 ? '${r.notes!.substring(0, 30)}...' : r.notes!)
            : '-';
        final cost = r.cost != null ? '${r.cost!.toStringAsFixed(2)} EUR' : '-';
        final mileage = r.mileageAtMaintenance != null ? '${r.mileageAtMaintenance} km' : '-';
        
        return [
          date,
          title,
          category,
          '$workshop$workshopAddress',
          notes,
          cost,
          mileage,
        ];
      }).toList(),
    );
  }

  /// Gibt den Anzeigenamen für eine Kategorie zurück
  String _getCategoryDisplayName(MaintenanceCategory? category) {
    if (category == null) return '-';
    switch (category) {
      case MaintenanceCategory.oilChange:
        return 'Ölwechsel';
      case MaintenanceCategory.tireChange:
        return 'Reifen';
      case MaintenanceCategory.brakes:
        return 'Bremsen';
      case MaintenanceCategory.tuv:
        return 'TÜV/AU';
      case MaintenanceCategory.inspection:
        return 'Inspektion';
      case MaintenanceCategory.battery:
        return 'Batterie';
      case MaintenanceCategory.filter:
        return 'Filter';
      case MaintenanceCategory.insurance:
        return 'Versicherung';
      case MaintenanceCategory.tax:
        return 'Steuer';
      case MaintenanceCategory.other:
        return 'Sonstiges';
    }
  }

  /// Generiert einen Statistik-Report als Text
  Future<void> exportStatsReport(
    List<MaintenanceReminder> reminders,
    Map<String, int> stats,
    double totalCost,
  ) async {
    final report = _generateStatsReport(reminders, stats, totalCost);
    final fileName = 'wartungs_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(report);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WeFixIt Wartungs-Report',
        text: 'Hier ist dein Wartungs-Report.',
      );
    } catch (e) {
      throw Exception('Fehler beim Exportieren: $e');
    }
  }

  String _generateStatsReport(
    List<MaintenanceReminder> reminders,
    Map<String, int> stats,
    double totalCost,
  ) {
    final buffer = StringBuffer();
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('     WeFixIt Wartungs-Report');
    buffer.writeln('     Erstellt: $now');
    buffer.writeln('═══════════════════════════════════════\n');
    
    buffer.writeln('📊 STATISTIK\n');
    buffer.writeln('Gesamt:      ${reminders.length} Wartungen');
    buffer.writeln('Geplant:     ${stats['planned'] ?? 0}');
    buffer.writeln('Überfällig:  ${stats['overdue'] ?? 0}');
    buffer.writeln('Erledigt:    ${stats['completed'] ?? 0}');
    buffer.writeln('');
    buffer.writeln('💰 KOSTEN\n');
    buffer.writeln('Gesamtkosten: €${totalCost.toStringAsFixed(2)}');
    
    final completed = reminders.where((r) => r.status == MaintenanceStatus.completed).toList();
    if (completed.isNotEmpty) {
      final avgCost = completed
          .where((r) => r.cost != null && r.cost! > 0)
          .fold<double>(0, (sum, r) => sum + r.cost!) / completed.where((r) => r.cost != null && r.cost! > 0).length;
      buffer.writeln('Durchschnitt: €${avgCost.toStringAsFixed(2)}');
    }
    
    buffer.writeln('\n═══════════════════════════════════════\n');
    
    buffer.writeln('📋 WARTUNGSLISTE\n');
    for (var r in reminders) {
      buffer.writeln('─────────────────────────────────────');
      buffer.writeln('${r.title}');
      if (r.category != null) {
        buffer.writeln('Kategorie: ${r.category.toString().split('.').last}');
      }
      if (r.dueDate != null) {
        buffer.writeln('Fällig: ${DateFormat('dd.MM.yyyy').format(r.dueDate!)}');
      }
      if (r.dueMileage != null) {
        buffer.writeln('Bei: ${r.dueMileage} km');
      }
      if (r.workshopName != null && r.workshopName!.isNotEmpty) {
        buffer.writeln('Werkstatt: ${r.workshopName}');
      }
      if (r.cost != null) {
        buffer.writeln('Kosten: €${r.cost!.toStringAsFixed(2)}');
      }
      final status = r.status == MaintenanceStatus.planned
          ? '⏳ Geplant'
          : r.status == MaintenanceStatus.completed
              ? '✅ Erledigt'
              : '⚠️ Überfällig';
      buffer.writeln('Status: $status');
      if (r.notes != null && r.notes!.isNotEmpty) {
        buffer.writeln('Notizen: ${r.notes}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Ende des Reports');
    
    return buffer.toString();
  }
}
