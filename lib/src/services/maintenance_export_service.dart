import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/maintenance_reminder.dart';
import 'package:intl/intl.dart';

/// Service zum Exportieren von Wartungsdaten
class MaintenanceExportService {
  
  /// Exportiert Wartungen als CSV
  Future<void> exportToCsv(List<MaintenanceReminder> reminders) async {
    final csv = _generateCsv(reminders);
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

  String _generateCsv(List<MaintenanceReminder> reminders) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Datum;Titel;Kategorie;Typ;Fälligkeit;Kilometerstand;Werkstatt;Adresse;Kosten;Status;Notizen');
    
    // Daten
    for (var r in reminders) {
      final date = r.createdAt != null ? DateFormat('dd.MM.yyyy').format(r.createdAt!) : '';
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
