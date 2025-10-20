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
  category: $enumDecodeNullable(_$MaintenanceCategoryEnumMap, json['category']),
  status:
      $enumDecodeNullable(_$MaintenanceStatusEnumMap, json['status']) ??
      MaintenanceStatus.planned,
  reminderType: $enumDecode(_$ReminderTypeEnumMap, json['reminder_type']),
  dueDate:
      json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
  dueMileage: (json['due_mileage'] as num?)?.toInt(),
  mileageAtMaintenance: (json['mileage_at_maintenance'] as num?)?.toInt(),
  isRecurring: json['is_recurring'] as bool? ?? false,
  recurrenceIntervalDays: (json['recurrence_interval_days'] as num?)?.toInt(),
  recurrenceIntervalKm: (json['recurrence_interval_km'] as num?)?.toInt(),
  workshopName: json['workshop_name'] as String?,
  workshopAddress: json['workshop_address'] as String?,
  cost: (json['cost'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  documents:
      (json['documents'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  notificationEnabled: json['notification_enabled'] as bool? ?? true,
  lastNotificationSent:
      json['last_notification_sent'] == null
          ? null
          : DateTime.parse(json['last_notification_sent'] as String),
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
  'category': _$MaintenanceCategoryEnumMap[instance.category],
  'status': _$MaintenanceStatusEnumMap[instance.status]!,
  'reminder_type': _$ReminderTypeEnumMap[instance.reminderType]!,
  'due_date': instance.dueDate?.toIso8601String(),
  'due_mileage': instance.dueMileage,
  'mileage_at_maintenance': instance.mileageAtMaintenance,
  'is_recurring': instance.isRecurring,
  'recurrence_interval_days': instance.recurrenceIntervalDays,
  'recurrence_interval_km': instance.recurrenceIntervalKm,
  'workshop_name': instance.workshopName,
  'workshop_address': instance.workshopAddress,
  'cost': instance.cost,
  'notes': instance.notes,
  'photos': instance.photos,
  'documents': instance.documents,
  'notification_enabled': instance.notificationEnabled,
  'last_notification_sent': instance.lastNotificationSent?.toIso8601String(),
  'is_completed': instance.isCompleted,
  'completed_at': instance.completedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$MaintenanceCategoryEnumMap = {
  MaintenanceCategory.oilChange: 'oil_change',
  MaintenanceCategory.tireChange: 'tire_change',
  MaintenanceCategory.brakes: 'brakes',
  MaintenanceCategory.tuv: 'tuv',
  MaintenanceCategory.inspection: 'inspection',
  MaintenanceCategory.battery: 'battery',
  MaintenanceCategory.filter: 'filter',
  MaintenanceCategory.insurance: 'insurance',
  MaintenanceCategory.tax: 'tax',
  MaintenanceCategory.other: 'other',
};

const _$MaintenanceStatusEnumMap = {
  MaintenanceStatus.planned: 'planned',
  MaintenanceStatus.completed: 'completed',
  MaintenanceStatus.overdue: 'overdue',
};

const _$ReminderTypeEnumMap = {
  ReminderType.date: 'date',
  ReminderType.mileage: 'mileage',
};
