// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MaintenanceReminder _$MaintenanceReminderFromJson(Map<String, dynamic> json) {
  return _MaintenanceReminder.fromJson(json);
}

/// @nodoc
mixin _$MaintenanceReminder {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'vehicle_id')
  String? get vehicleId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description =>
      throw _privateConstructorUsedError; // Kategorie & Status
  MaintenanceCategory? get category => throw _privateConstructorUsedError;
  MaintenanceStatus get status =>
      throw _privateConstructorUsedError; // Typ & Fälligkeiten
  @JsonKey(name: 'reminder_type')
  ReminderType get reminderType => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  DateTime? get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_mileage')
  int? get dueMileage => throw _privateConstructorUsedError; // Kilometerdaten
  @JsonKey(name: 'mileage_at_maintenance')
  int? get mileageAtMaintenance => throw _privateConstructorUsedError; // Wiederkehrend
  @JsonKey(name: 'is_recurring')
  bool get isRecurring => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_interval_days')
  int? get recurrenceIntervalDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_interval_km')
  int? get recurrenceIntervalKm => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_rule')
  Map<String, dynamic>? get recurrenceRule =>
      throw _privateConstructorUsedError; // Werkstatt
  @JsonKey(name: 'workshop_name')
  String? get workshopName => throw _privateConstructorUsedError;
  @JsonKey(name: 'workshop_address')
  String? get workshopAddress => throw _privateConstructorUsedError; // Kosten & Notizen
  double? get cost => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError; // Dateien
  List<String> get photos => throw _privateConstructorUsedError;
  List<String> get documents =>
      throw _privateConstructorUsedError; // Benachrichtigungen
  @JsonKey(name: 'notification_enabled')
  bool get notificationEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_notification_sent')
  DateTime? get lastNotificationSent => throw _privateConstructorUsedError;
  @JsonKey(name: 'notify_offset_minutes')
  int get notifyOffsetMinutes => throw _privateConstructorUsedError; // Legacy Felder (backward compatibility)
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError; // Timestamps
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MaintenanceReminder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaintenanceReminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaintenanceReminderCopyWith<MaintenanceReminder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaintenanceReminderCopyWith<$Res> {
  factory $MaintenanceReminderCopyWith(
    MaintenanceReminder value,
    $Res Function(MaintenanceReminder) then,
  ) = _$MaintenanceReminderCopyWithImpl<$Res, MaintenanceReminder>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'vehicle_id') String? vehicleId,
    String title,
    String? description,
    MaintenanceCategory? category,
    MaintenanceStatus status,
    @JsonKey(name: 'reminder_type') ReminderType reminderType,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'due_mileage') int? dueMileage,
    @JsonKey(name: 'mileage_at_maintenance') int? mileageAtMaintenance,
    @JsonKey(name: 'is_recurring') bool isRecurring,
    @JsonKey(name: 'recurrence_interval_days') int? recurrenceIntervalDays,
    @JsonKey(name: 'recurrence_interval_km') int? recurrenceIntervalKm,
    @JsonKey(name: 'recurrence_rule') Map<String, dynamic>? recurrenceRule,
    @JsonKey(name: 'workshop_name') String? workshopName,
    @JsonKey(name: 'workshop_address') String? workshopAddress,
    double? cost,
    String? notes,
    List<String> photos,
    List<String> documents,
    @JsonKey(name: 'notification_enabled') bool notificationEnabled,
    @JsonKey(name: 'last_notification_sent') DateTime? lastNotificationSent,
    @JsonKey(name: 'notify_offset_minutes') int notifyOffsetMinutes,
    @JsonKey(name: 'is_completed') bool isCompleted,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
  });
}

/// @nodoc
class _$MaintenanceReminderCopyWithImpl<$Res, $Val extends MaintenanceReminder>
    implements $MaintenanceReminderCopyWith<$Res> {
  _$MaintenanceReminderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaintenanceReminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? vehicleId = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? status = null,
    Object? reminderType = null,
    Object? dueDate = freezed,
    Object? dueMileage = freezed,
    Object? mileageAtMaintenance = freezed,
    Object? isRecurring = null,
    Object? recurrenceIntervalDays = freezed,
    Object? recurrenceIntervalKm = freezed,
    Object? recurrenceRule = freezed,
    Object? workshopName = freezed,
    Object? workshopAddress = freezed,
    Object? cost = freezed,
    Object? notes = freezed,
    Object? photos = null,
    Object? documents = null,
    Object? notificationEnabled = null,
    Object? lastNotificationSent = freezed,
    Object? notifyOffsetMinutes = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            vehicleId:
                freezed == vehicleId
                    ? _value.vehicleId
                    : vehicleId // ignore: cast_nullable_to_non_nullable
                        as String?,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            category:
                freezed == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as MaintenanceCategory?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as MaintenanceStatus,
            reminderType:
                null == reminderType
                    ? _value.reminderType
                    : reminderType // ignore: cast_nullable_to_non_nullable
                        as ReminderType,
            dueDate:
                freezed == dueDate
                    ? _value.dueDate
                    : dueDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            dueMileage:
                freezed == dueMileage
                    ? _value.dueMileage
                    : dueMileage // ignore: cast_nullable_to_non_nullable
                        as int?,
            mileageAtMaintenance:
                freezed == mileageAtMaintenance
                    ? _value.mileageAtMaintenance
                    : mileageAtMaintenance // ignore: cast_nullable_to_non_nullable
                        as int?,
            isRecurring:
                null == isRecurring
                    ? _value.isRecurring
                    : isRecurring // ignore: cast_nullable_to_non_nullable
                        as bool,
            recurrenceIntervalDays:
                freezed == recurrenceIntervalDays
                    ? _value.recurrenceIntervalDays
                    : recurrenceIntervalDays // ignore: cast_nullable_to_non_nullable
                        as int?,
            recurrenceIntervalKm:
                freezed == recurrenceIntervalKm
                    ? _value.recurrenceIntervalKm
                    : recurrenceIntervalKm // ignore: cast_nullable_to_non_nullable
                        as int?,
            recurrenceRule:
                freezed == recurrenceRule
                    ? _value.recurrenceRule
                    : recurrenceRule // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>?,
            workshopName:
                freezed == workshopName
                    ? _value.workshopName
                    : workshopName // ignore: cast_nullable_to_non_nullable
                        as String?,
            workshopAddress:
                freezed == workshopAddress
                    ? _value.workshopAddress
                    : workshopAddress // ignore: cast_nullable_to_non_nullable
                        as String?,
            cost:
                freezed == cost
                    ? _value.cost
                    : cost // ignore: cast_nullable_to_non_nullable
                        as double?,
            notes:
                freezed == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String?,
            photos:
                null == photos
                    ? _value.photos
                    : photos // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            documents:
                null == documents
                    ? _value.documents
                    : documents // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            notificationEnabled:
                null == notificationEnabled
                    ? _value.notificationEnabled
                    : notificationEnabled // ignore: cast_nullable_to_non_nullable
                        as bool,
            lastNotificationSent:
                freezed == lastNotificationSent
                    ? _value.lastNotificationSent
                    : lastNotificationSent // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            notifyOffsetMinutes:
                null == notifyOffsetMinutes
                    ? _value.notifyOffsetMinutes
                    : notifyOffsetMinutes // ignore: cast_nullable_to_non_nullable
                        as int,
            isCompleted:
                null == isCompleted
                    ? _value.isCompleted
                    : isCompleted // ignore: cast_nullable_to_non_nullable
                        as bool,
            completedAt:
                freezed == completedAt
                    ? _value.completedAt
                    : completedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaintenanceReminderImplCopyWith<$Res>
    implements $MaintenanceReminderCopyWith<$Res> {
  factory _$$MaintenanceReminderImplCopyWith(
    _$MaintenanceReminderImpl value,
    $Res Function(_$MaintenanceReminderImpl) then,
  ) = __$$MaintenanceReminderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'vehicle_id') String? vehicleId,
    String title,
    String? description,
    MaintenanceCategory? category,
    MaintenanceStatus status,
    @JsonKey(name: 'reminder_type') ReminderType reminderType,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'due_mileage') int? dueMileage,
    @JsonKey(name: 'mileage_at_maintenance') int? mileageAtMaintenance,
    @JsonKey(name: 'is_recurring') bool isRecurring,
    @JsonKey(name: 'recurrence_interval_days') int? recurrenceIntervalDays,
    @JsonKey(name: 'recurrence_interval_km') int? recurrenceIntervalKm,
    @JsonKey(name: 'recurrence_rule') Map<String, dynamic>? recurrenceRule,
    @JsonKey(name: 'workshop_name') String? workshopName,
    @JsonKey(name: 'workshop_address') String? workshopAddress,
    double? cost,
    String? notes,
    List<String> photos,
    List<String> documents,
    @JsonKey(name: 'notification_enabled') bool notificationEnabled,
    @JsonKey(name: 'last_notification_sent') DateTime? lastNotificationSent,
    @JsonKey(name: 'notify_offset_minutes') int notifyOffsetMinutes,
    @JsonKey(name: 'is_completed') bool isCompleted,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
  });
}

/// @nodoc
class __$$MaintenanceReminderImplCopyWithImpl<$Res>
    extends _$MaintenanceReminderCopyWithImpl<$Res, _$MaintenanceReminderImpl>
    implements _$$MaintenanceReminderImplCopyWith<$Res> {
  __$$MaintenanceReminderImplCopyWithImpl(
    _$MaintenanceReminderImpl _value,
    $Res Function(_$MaintenanceReminderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaintenanceReminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? vehicleId = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? status = null,
    Object? reminderType = null,
    Object? dueDate = freezed,
    Object? dueMileage = freezed,
    Object? mileageAtMaintenance = freezed,
    Object? isRecurring = null,
    Object? recurrenceIntervalDays = freezed,
    Object? recurrenceIntervalKm = freezed,
    Object? recurrenceRule = freezed,
    Object? workshopName = freezed,
    Object? workshopAddress = freezed,
    Object? cost = freezed,
    Object? notes = freezed,
    Object? photos = null,
    Object? documents = null,
    Object? notificationEnabled = null,
    Object? lastNotificationSent = freezed,
    Object? notifyOffsetMinutes = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$MaintenanceReminderImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        vehicleId:
            freezed == vehicleId
                ? _value.vehicleId
                : vehicleId // ignore: cast_nullable_to_non_nullable
                    as String?,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        category:
            freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as MaintenanceCategory?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as MaintenanceStatus,
        reminderType:
            null == reminderType
                ? _value.reminderType
                : reminderType // ignore: cast_nullable_to_non_nullable
                    as ReminderType,
        dueDate:
            freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        dueMileage:
            freezed == dueMileage
                ? _value.dueMileage
                : dueMileage // ignore: cast_nullable_to_non_nullable
                    as int?,
        mileageAtMaintenance:
            freezed == mileageAtMaintenance
                ? _value.mileageAtMaintenance
                : mileageAtMaintenance // ignore: cast_nullable_to_non_nullable
                    as int?,
        isRecurring:
            null == isRecurring
                ? _value.isRecurring
                : isRecurring // ignore: cast_nullable_to_non_nullable
                    as bool,
        recurrenceIntervalDays:
            freezed == recurrenceIntervalDays
                ? _value.recurrenceIntervalDays
                : recurrenceIntervalDays // ignore: cast_nullable_to_non_nullable
                    as int?,
        recurrenceIntervalKm:
            freezed == recurrenceIntervalKm
                ? _value.recurrenceIntervalKm
                : recurrenceIntervalKm // ignore: cast_nullable_to_non_nullable
                    as int?,
        recurrenceRule:
            freezed == recurrenceRule
                ? _value._recurrenceRule
                : recurrenceRule // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
        workshopName:
            freezed == workshopName
                ? _value.workshopName
                : workshopName // ignore: cast_nullable_to_non_nullable
                    as String?,
        workshopAddress:
            freezed == workshopAddress
                ? _value.workshopAddress
                : workshopAddress // ignore: cast_nullable_to_non_nullable
                    as String?,
        cost:
            freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                    as double?,
        notes:
            freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String?,
        photos:
            null == photos
                ? _value._photos
                : photos // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        documents:
            null == documents
                ? _value._documents
                : documents // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        notificationEnabled:
            null == notificationEnabled
                ? _value.notificationEnabled
                : notificationEnabled // ignore: cast_nullable_to_non_nullable
                    as bool,
        lastNotificationSent:
            freezed == lastNotificationSent
                ? _value.lastNotificationSent
                : lastNotificationSent // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        notifyOffsetMinutes:
            null == notifyOffsetMinutes
                ? _value.notifyOffsetMinutes
                : notifyOffsetMinutes // ignore: cast_nullable_to_non_nullable
                    as int,
        isCompleted:
            null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                    as bool,
        completedAt:
            freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaintenanceReminderImpl implements _MaintenanceReminder {
  const _$MaintenanceReminderImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'vehicle_id') this.vehicleId,
    required this.title,
    this.description,
    this.category,
    this.status = MaintenanceStatus.planned,
    @JsonKey(name: 'reminder_type') required this.reminderType,
    @JsonKey(name: 'due_date') this.dueDate,
    @JsonKey(name: 'due_mileage') this.dueMileage,
    @JsonKey(name: 'mileage_at_maintenance') this.mileageAtMaintenance,
    @JsonKey(name: 'is_recurring') this.isRecurring = false,
    @JsonKey(name: 'recurrence_interval_days') this.recurrenceIntervalDays,
    @JsonKey(name: 'recurrence_interval_km') this.recurrenceIntervalKm,
    @JsonKey(name: 'recurrence_rule')
    final Map<String, dynamic>? recurrenceRule,
    @JsonKey(name: 'workshop_name') this.workshopName,
    @JsonKey(name: 'workshop_address') this.workshopAddress,
    this.cost,
    this.notes,
    final List<String> photos = const [],
    final List<String> documents = const [],
    @JsonKey(name: 'notification_enabled') this.notificationEnabled = true,
    @JsonKey(name: 'last_notification_sent') this.lastNotificationSent,
    @JsonKey(name: 'notify_offset_minutes') this.notifyOffsetMinutes = 10,
    @JsonKey(name: 'is_completed') this.isCompleted = false,
    @JsonKey(name: 'completed_at') this.completedAt,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
  }) : _recurrenceRule = recurrenceRule,
       _photos = photos,
       _documents = documents;

  factory _$MaintenanceReminderImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaintenanceReminderImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @override
  final String title;
  @override
  final String? description;
  // Kategorie & Status
  @override
  final MaintenanceCategory? category;
  @override
  @JsonKey()
  final MaintenanceStatus status;
  // Typ & Fälligkeiten
  @override
  @JsonKey(name: 'reminder_type')
  final ReminderType reminderType;
  @override
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @override
  @JsonKey(name: 'due_mileage')
  final int? dueMileage;
  // Kilometerdaten
  @override
  @JsonKey(name: 'mileage_at_maintenance')
  final int? mileageAtMaintenance;
  // Wiederkehrend
  @override
  @JsonKey(name: 'is_recurring')
  final bool isRecurring;
  @override
  @JsonKey(name: 'recurrence_interval_days')
  final int? recurrenceIntervalDays;
  @override
  @JsonKey(name: 'recurrence_interval_km')
  final int? recurrenceIntervalKm;
  final Map<String, dynamic>? _recurrenceRule;
  @override
  @JsonKey(name: 'recurrence_rule')
  Map<String, dynamic>? get recurrenceRule {
    final value = _recurrenceRule;
    if (value == null) return null;
    if (_recurrenceRule is EqualUnmodifiableMapView) return _recurrenceRule;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // Werkstatt
  @override
  @JsonKey(name: 'workshop_name')
  final String? workshopName;
  @override
  @JsonKey(name: 'workshop_address')
  final String? workshopAddress;
  // Kosten & Notizen
  @override
  final double? cost;
  @override
  final String? notes;
  // Dateien
  final List<String> _photos;
  // Dateien
  @override
  @JsonKey()
  List<String> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  final List<String> _documents;
  @override
  @JsonKey()
  List<String> get documents {
    if (_documents is EqualUnmodifiableListView) return _documents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_documents);
  }

  // Benachrichtigungen
  @override
  @JsonKey(name: 'notification_enabled')
  final bool notificationEnabled;
  @override
  @JsonKey(name: 'last_notification_sent')
  final DateTime? lastNotificationSent;
  @override
  @JsonKey(name: 'notify_offset_minutes')
  final int notifyOffsetMinutes;
  // Legacy Felder (backward compatibility)
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  // Timestamps
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MaintenanceReminder(id: $id, userId: $userId, vehicleId: $vehicleId, title: $title, description: $description, category: $category, status: $status, reminderType: $reminderType, dueDate: $dueDate, dueMileage: $dueMileage, mileageAtMaintenance: $mileageAtMaintenance, isRecurring: $isRecurring, recurrenceIntervalDays: $recurrenceIntervalDays, recurrenceIntervalKm: $recurrenceIntervalKm, recurrenceRule: $recurrenceRule, workshopName: $workshopName, workshopAddress: $workshopAddress, cost: $cost, notes: $notes, photos: $photos, documents: $documents, notificationEnabled: $notificationEnabled, lastNotificationSent: $lastNotificationSent, notifyOffsetMinutes: $notifyOffsetMinutes, isCompleted: $isCompleted, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaintenanceReminderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.reminderType, reminderType) ||
                other.reminderType == reminderType) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.dueMileage, dueMileage) ||
                other.dueMileage == dueMileage) &&
            (identical(other.mileageAtMaintenance, mileageAtMaintenance) ||
                other.mileageAtMaintenance == mileageAtMaintenance) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.recurrenceIntervalDays, recurrenceIntervalDays) ||
                other.recurrenceIntervalDays == recurrenceIntervalDays) &&
            (identical(other.recurrenceIntervalKm, recurrenceIntervalKm) ||
                other.recurrenceIntervalKm == recurrenceIntervalKm) &&
            const DeepCollectionEquality().equals(
              other._recurrenceRule,
              _recurrenceRule,
            ) &&
            (identical(other.workshopName, workshopName) ||
                other.workshopName == workshopName) &&
            (identical(other.workshopAddress, workshopAddress) ||
                other.workshopAddress == workshopAddress) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            const DeepCollectionEquality().equals(
              other._documents,
              _documents,
            ) &&
            (identical(other.notificationEnabled, notificationEnabled) ||
                other.notificationEnabled == notificationEnabled) &&
            (identical(other.lastNotificationSent, lastNotificationSent) ||
                other.lastNotificationSent == lastNotificationSent) &&
            (identical(other.notifyOffsetMinutes, notifyOffsetMinutes) ||
                other.notifyOffsetMinutes == notifyOffsetMinutes) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    userId,
    vehicleId,
    title,
    description,
    category,
    status,
    reminderType,
    dueDate,
    dueMileage,
    mileageAtMaintenance,
    isRecurring,
    recurrenceIntervalDays,
    recurrenceIntervalKm,
    const DeepCollectionEquality().hash(_recurrenceRule),
    workshopName,
    workshopAddress,
    cost,
    notes,
    const DeepCollectionEquality().hash(_photos),
    const DeepCollectionEquality().hash(_documents),
    notificationEnabled,
    lastNotificationSent,
    notifyOffsetMinutes,
    isCompleted,
    completedAt,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of MaintenanceReminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaintenanceReminderImplCopyWith<_$MaintenanceReminderImpl> get copyWith =>
      __$$MaintenanceReminderImplCopyWithImpl<_$MaintenanceReminderImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaintenanceReminderImplToJson(this);
  }
}

abstract class _MaintenanceReminder implements MaintenanceReminder {
  const factory _MaintenanceReminder({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'vehicle_id') final String? vehicleId,
    required final String title,
    final String? description,
    final MaintenanceCategory? category,
    final MaintenanceStatus status,
    @JsonKey(name: 'reminder_type') required final ReminderType reminderType,
    @JsonKey(name: 'due_date') final DateTime? dueDate,
    @JsonKey(name: 'due_mileage') final int? dueMileage,
    @JsonKey(name: 'mileage_at_maintenance') final int? mileageAtMaintenance,
    @JsonKey(name: 'is_recurring') final bool isRecurring,
    @JsonKey(name: 'recurrence_interval_days')
    final int? recurrenceIntervalDays,
    @JsonKey(name: 'recurrence_interval_km') final int? recurrenceIntervalKm,
    @JsonKey(name: 'recurrence_rule')
    final Map<String, dynamic>? recurrenceRule,
    @JsonKey(name: 'workshop_name') final String? workshopName,
    @JsonKey(name: 'workshop_address') final String? workshopAddress,
    final double? cost,
    final String? notes,
    final List<String> photos,
    final List<String> documents,
    @JsonKey(name: 'notification_enabled') final bool notificationEnabled,
    @JsonKey(name: 'last_notification_sent')
    final DateTime? lastNotificationSent,
    @JsonKey(name: 'notify_offset_minutes') final int notifyOffsetMinutes,
    @JsonKey(name: 'is_completed') final bool isCompleted,
    @JsonKey(name: 'completed_at') final DateTime? completedAt,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
  }) = _$MaintenanceReminderImpl;

  factory _MaintenanceReminder.fromJson(Map<String, dynamic> json) =
      _$MaintenanceReminderImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'vehicle_id')
  String? get vehicleId;
  @override
  String get title;
  @override
  String? get description; // Kategorie & Status
  @override
  MaintenanceCategory? get category;
  @override
  MaintenanceStatus get status; // Typ & Fälligkeiten
  @override
  @JsonKey(name: 'reminder_type')
  ReminderType get reminderType;
  @override
  @JsonKey(name: 'due_date')
  DateTime? get dueDate;
  @override
  @JsonKey(name: 'due_mileage')
  int? get dueMileage; // Kilometerdaten
  @override
  @JsonKey(name: 'mileage_at_maintenance')
  int? get mileageAtMaintenance; // Wiederkehrend
  @override
  @JsonKey(name: 'is_recurring')
  bool get isRecurring;
  @override
  @JsonKey(name: 'recurrence_interval_days')
  int? get recurrenceIntervalDays;
  @override
  @JsonKey(name: 'recurrence_interval_km')
  int? get recurrenceIntervalKm;
  @override
  @JsonKey(name: 'recurrence_rule')
  Map<String, dynamic>? get recurrenceRule; // Werkstatt
  @override
  @JsonKey(name: 'workshop_name')
  String? get workshopName;
  @override
  @JsonKey(name: 'workshop_address')
  String? get workshopAddress; // Kosten & Notizen
  @override
  double? get cost;
  @override
  String? get notes; // Dateien
  @override
  List<String> get photos;
  @override
  List<String> get documents; // Benachrichtigungen
  @override
  @JsonKey(name: 'notification_enabled')
  bool get notificationEnabled;
  @override
  @JsonKey(name: 'last_notification_sent')
  DateTime? get lastNotificationSent;
  @override
  @JsonKey(name: 'notify_offset_minutes')
  int get notifyOffsetMinutes; // Legacy Felder (backward compatibility)
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt; // Timestamps
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of MaintenanceReminder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaintenanceReminderImplCopyWith<_$MaintenanceReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
