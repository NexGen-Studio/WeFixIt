import '../models/maintenance_reminder.dart';
import '../i18n/app_localizations.dart';

/// Service für intelligente Wartungsvorschläge
class MaintenanceSuggestionsService {
  
  /// Generiert Vorschläge basierend auf Kilometerstand und Historie
  List<MaintenanceSuggestion> generateSuggestions({
    required int currentMileage,
    required List<MaintenanceReminder> history,
    required AppLocalizations t,
  }) {
    final suggestions = <MaintenanceSuggestion>[];

    // Ölwechsel-Vorschlag (alle 15.000 km)
    final lastOilChange = _findLastMaintenance(history, MaintenanceCategory.oilChange);
    if (lastOilChange == null) {
      suggestions.add(MaintenanceSuggestion(
        category: MaintenanceCategory.oilChange,
        title: t.maintenance_suggestion_oil_recommended_title,
        reason: t.maintenance_suggestion_oil_reason_none,
        suggestedMileage: currentMileage + 1000,
        priority: SuggestionPriority.high,
      ));
    } else if (lastOilChange.mileageAtMaintenance != null) {
      final kmSince = currentMileage - lastOilChange.mileageAtMaintenance!;
      if (kmSince >= 15000) {
        suggestions.add(MaintenanceSuggestion(
          category: MaintenanceCategory.oilChange,
          title: t.maintenance_suggestion_oil_due_title,
          reason: t.maintenance_suggestion_oil_reason_since_km.replaceAll('{km}', '$kmSince'),
          suggestedMileage: currentMileage + 500,
          priority: SuggestionPriority.high,
        ));
      } else if (kmSince >= 12000) {
        suggestions.add(MaintenanceSuggestion(
          category: MaintenanceCategory.oilChange,
          title: t.maintenance_suggestion_oil_soon_title,
          reason: t.maintenance_suggestion_oil_reason_since_km.replaceAll('{km}', '$kmSince'),
          suggestedMileage: currentMileage + 3000,
          priority: SuggestionPriority.medium,
        ));
      }
    }

    // Reifenwechsel-Vorschlag (halbjährlich)
    final lastTireChange = _findLastMaintenance(history, MaintenanceCategory.tireChange);
    if (lastTireChange != null && lastTireChange.completedAt != null) {
      final monthsSince = DateTime.now().difference(lastTireChange.completedAt!).inDays ~/ 30;
      if (monthsSince >= 6) {
        final season = DateTime.now().month >= 4 && DateTime.now().month <= 9 
            ? t.maintenance_season_summer 
            : t.maintenance_season_winter;
        suggestions.add(MaintenanceSuggestion(
          category: MaintenanceCategory.tireChange,
          title: t.maintenance_suggestion_tire_change_title.replaceAll('{season}', season),
          reason: t.maintenance_suggestion_tire_change_reason_months.replaceAll('{months}', '$monthsSince'),
          suggestedDate: DateTime.now().add(const Duration(days: 14)),
          priority: SuggestionPriority.medium,
        ));
      }
    }

    // TÜV-Vorschlag (alle 2 Jahre)
    final lastTuv = _findLastMaintenance(history, MaintenanceCategory.tuv);
    if (lastTuv != null && lastTuv.completedAt != null) {
      final monthsSince = DateTime.now().difference(lastTuv.completedAt!).inDays ~/ 30;
      if (monthsSince >= 22) {
        suggestions.add(MaintenanceSuggestion(
          category: MaintenanceCategory.tuv,
          title: t.maintenance_suggestion_tuv_due_title,
          reason: t.maintenance_suggestion_tuv_reason_months.replaceAll('{months}', '$monthsSince'),
          suggestedDate: DateTime.now().add(const Duration(days: 30)),
          priority: SuggestionPriority.high,
        ));
      } else if (monthsSince >= 20) {
        suggestions.add(MaintenanceSuggestion(
          category: MaintenanceCategory.tuv,
          title: t.maintenance_suggestion_tuv_soon_title,
          reason: t.maintenance_suggestion_tuv_reason_months.replaceAll('{months}', '$monthsSince'),
          suggestedDate: DateTime.now().add(const Duration(days: 60)),
          priority: SuggestionPriority.medium,
        ));
      }
    }

    // Inspektion-Vorschlag (alle 30.000 km oder jährlich)
    final lastInspection = _findLastMaintenance(history, MaintenanceCategory.inspection);
    if (lastInspection != null) {
      if (lastInspection.mileageAtMaintenance != null) {
        final kmSince = currentMileage - lastInspection.mileageAtMaintenance!;
        if (kmSince >= 30000) {
          suggestions.add(MaintenanceSuggestion(
            category: MaintenanceCategory.inspection,
            title: t.maintenance_suggestion_inspection_title,
            reason: t.maintenance_suggestion_inspection_reason_km.replaceAll('{km}', '$kmSince'),
            suggestedMileage: currentMileage + 1000,
            priority: SuggestionPriority.medium,
          ));
        }
      }
      if (lastInspection.completedAt != null) {
        final monthsSince = DateTime.now().difference(lastInspection.completedAt!).inDays ~/ 30;
        if (monthsSince >= 12) {
          suggestions.add(MaintenanceSuggestion(
            category: MaintenanceCategory.inspection,
            title: t.maintenance_suggestion_annual_inspection_title,
            reason: t.maintenance_suggestion_inspection_reason_months.replaceAll('{months}', '$monthsSince'),
            suggestedDate: DateTime.now().add(const Duration(days: 30)),
            priority: SuggestionPriority.medium,
          ));
        }
      }
    }

    // Batterie-Check (alle 3 Jahre)
    final lastBattery = _findLastMaintenance(history, MaintenanceCategory.battery);
    if (lastBattery != null && lastBattery.completedAt != null) {
      final monthsSince = DateTime.now().difference(lastBattery.completedAt!).inDays ~/ 30;
      if (monthsSince >= 36) {
        suggestions.add(MaintenanceSuggestion(
          category: MaintenanceCategory.battery,
          title: t.maintenance_suggestion_battery_check_title,
          reason: t.maintenance_suggestion_battery_reason_months.replaceAll('{months}', '$monthsSince'),
          suggestedDate: DateTime.now().add(const Duration(days: 30)),
          priority: SuggestionPriority.low,
        ));
      }
    }

    // Sortiere nach Priorität
    suggestions.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return suggestions;
  }

  MaintenanceReminder? _findLastMaintenance(
    List<MaintenanceReminder> history,
    MaintenanceCategory category,
  ) {
    final filtered = history
        .where((r) => r.category == category && r.status == MaintenanceStatus.completed)
        .toList();
    
    if (filtered.isEmpty) return null;
    
    filtered.sort((a, b) {
      final aDate = a.completedAt ?? a.createdAt ?? DateTime(2000);
      final bDate = b.completedAt ?? b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    
    return filtered.first;
  }
}

/// Wartungsvorschlag
class MaintenanceSuggestion {
  final MaintenanceCategory category;
  final String title;
  final String reason;
  final int? suggestedMileage;
  final DateTime? suggestedDate;
  final SuggestionPriority priority;

  MaintenanceSuggestion({
    required this.category,
    required this.title,
    required this.reason,
    this.suggestedMileage,
    this.suggestedDate,
    required this.priority,
  });
}

enum SuggestionPriority {
  low,
  medium,
  high,
}
