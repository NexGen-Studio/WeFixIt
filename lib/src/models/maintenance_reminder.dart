import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_reminder.freezed.dart';
part 'maintenance_reminder.g.dart';

enum ReminderType {
  @JsonValue('date')
  date,
  @JsonValue('mileage')
  mileage,
}

enum MaintenanceCategory {
  @JsonValue('oil_change')
  oilChange,
  @JsonValue('tire_change')
  tireChange,
  @JsonValue('brakes')
  brakes,
  @JsonValue('tuv')
  tuv,
  @JsonValue('inspection')
  inspection,
  @JsonValue('battery')
  battery,
  @JsonValue('filter')
  filter,
  @JsonValue('insurance')
  insurance,
  @JsonValue('tax')
  tax,
  @JsonValue('other')
  other,
}

extension MaintenanceCategoryExtension on MaintenanceCategory {
  String toJsonValue() {
    switch (this) {
      case MaintenanceCategory.oilChange:
        return 'oil_change';
      case MaintenanceCategory.tireChange:
        return 'tire_change';
      case MaintenanceCategory.brakes:
        return 'brakes';
      case MaintenanceCategory.tuv:
        return 'tuv';
      case MaintenanceCategory.inspection:
        return 'inspection';
      case MaintenanceCategory.battery:
        return 'battery';
      case MaintenanceCategory.filter:
        return 'filter';
      case MaintenanceCategory.insurance:
        return 'insurance';
      case MaintenanceCategory.tax:
        return 'tax';
      case MaintenanceCategory.other:
        return 'other';
    }
  }
}

enum MaintenanceStatus {
  @JsonValue('planned')
  planned,
  @JsonValue('completed')
  completed,
  @JsonValue('overdue')
  overdue,
}

@freezed
class MaintenanceReminder with _$MaintenanceReminder {
  const factory MaintenanceReminder({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'vehicle_id') String? vehicleId,
    required String title,
    String? description,
    // Kategorie & Status
    MaintenanceCategory? category,
    @Default(MaintenanceStatus.planned) MaintenanceStatus status,
    // Typ & Fälligkeiten
    @JsonKey(name: 'reminder_type') required ReminderType reminderType,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'due_mileage') int? dueMileage,
    // Kilometerdaten
    @JsonKey(name: 'mileage_at_maintenance') int? mileageAtMaintenance,
    // Wiederkehrend
    @JsonKey(name: 'is_recurring') @Default(false) bool isRecurring,
    @JsonKey(name: 'recurrence_interval_days') int? recurrenceIntervalDays,
    @JsonKey(name: 'recurrence_interval_km') int? recurrenceIntervalKm,
    // Werkstatt
    @JsonKey(name: 'workshop_name') String? workshopName,
    @JsonKey(name: 'workshop_address') String? workshopAddress,
    // Kosten & Notizen
    double? cost,
    String? notes,
    // Dateien
    @Default([]) List<String> photos,
    @Default([]) List<String> documents,
    // Benachrichtigungen
    @JsonKey(name: 'notification_enabled') @Default(true) bool notificationEnabled,
    @JsonKey(name: 'last_notification_sent') DateTime? lastNotificationSent,
    // Legacy Felder (backward compatibility)
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    // Timestamps
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _MaintenanceReminder;

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceReminderFromJson(json);
}
