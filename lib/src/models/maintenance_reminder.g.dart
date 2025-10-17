// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MaintenanceReminderImpl _$$MaintenanceReminderImplFromJson(
  Map<String, dynamic> json,
) => _$MaintenanceReminderImpl(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  vehicleId: json['vehicle_id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  reminderType: $enumDecode(_$ReminderTypeEnumMap, json['reminder_type']),
  dueDate:
      json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
  dueMileage: (json['due_mileage'] as num?)?.toInt(),
  isRecurring: json['is_recurring'] as bool? ?? false,
  recurrenceIntervalDays: (json['recurrence_interval_days'] as num?)?.toInt(),
  recurrenceIntervalKm: (json['recurrence_interval_km'] as num?)?.toInt(),
  isCompleted: json['is_completed'] as bool? ?? false,
  completedAt:
      json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$MaintenanceReminderImplToJson(
  _$MaintenanceReminderImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'vehicle_id': instance.vehicleId,
  'title': instance.title,
  'description': instance.description,
  'reminder_type': _$ReminderTypeEnumMap[instance.reminderType]!,
  'due_date': instance.dueDate?.toIso8601String(),
  'due_mileage': instance.dueMileage,
  'is_recurring': instance.isRecurring,
  'recurrence_interval_days': instance.recurrenceIntervalDays,
  'recurrence_interval_km': instance.recurrenceIntervalKm,
  'is_completed': instance.isCompleted,
  'completed_at': instance.completedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$ReminderTypeEnumMap = {
  ReminderType.date: 'date',
  ReminderType.mileage: 'mileage',
};
