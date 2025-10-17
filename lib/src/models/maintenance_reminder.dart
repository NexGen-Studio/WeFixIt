import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_reminder.freezed.dart';
part 'maintenance_reminder.g.dart';

enum ReminderType {
  @JsonValue('date')
  date,
  @JsonValue('mileage')
  mileage,
}

@freezed
class MaintenanceReminder with _$MaintenanceReminder {
  const factory MaintenanceReminder({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'vehicle_id') String? vehicleId,
    required String title,
    String? description,
    @JsonKey(name: 'reminder_type') required ReminderType reminderType,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'due_mileage') int? dueMileage,
    @JsonKey(name: 'is_recurring') @Default(false) bool isRecurring,
    @JsonKey(name: 'recurrence_interval_days') int? recurrenceIntervalDays,
    @JsonKey(name: 'recurrence_interval_km') int? recurrenceIntervalKm,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _MaintenanceReminder;

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceReminderFromJson(json);
}
