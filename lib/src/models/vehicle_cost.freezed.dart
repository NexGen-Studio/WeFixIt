// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_cost.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VehicleCost _$VehicleCostFromJson(Map<String, dynamic> json) {
  return _VehicleCost.fromJson(json);
}

/// @nodoc
mixin _$VehicleCost {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'vehicle_id')
  String? get vehicleId => throw _privateConstructorUsedError; // Optional: Wird in Phase 1 aus Profil genommen
  @JsonKey(name: 'category_id')
  String get categoryId => throw _privateConstructorUsedError; // Basisdaten
  String get title => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  int? get mileage => throw _privateConstructorUsedError;
  String? get notes =>
      throw _privateConstructorUsedError; // Treibstoff-spezifisch (nur für Treibstoff-Kategorie)
  @JsonKey(name: 'is_refueling')
  bool get isRefueling => throw _privateConstructorUsedError;
  @JsonKey(name: 'fuel_type')
  String? get fuelType => throw _privateConstructorUsedError; // 'petrol', 'diesel', 'electric', 'hybrid'
  @JsonKey(name: 'fuel_amount_liters')
  double? get fuelAmountLiters => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_per_liter')
  double? get pricePerLiter => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_full_tank')
  bool get isFullTank => throw _privateConstructorUsedError;
  @JsonKey(name: 'trip_distance')
  int? get tripDistance => throw _privateConstructorUsedError; // km seit letzter Betankung
  @JsonKey(name: 'gas_station')
  String? get gasStation => throw _privateConstructorUsedError; // Streckentyp (optional)
  @JsonKey(name: 'distance_highway')
  int? get distanceHighway => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_city')
  int? get distanceCity => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_country')
  int? get distanceCountry => throw _privateConstructorUsedError; // Medien
  List<String> get photos => throw _privateConstructorUsedError; // Storage URLs
  // Verknüpfung mit Wartungen
  @JsonKey(name: 'maintenance_reminder_id')
  String? get maintenanceReminderId => throw _privateConstructorUsedError; // Zeitraum-spezifisch (nur für Versicherung/Steuer/Kredit)
  @JsonKey(name: 'period_start_date')
  DateTime? get periodStartDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'period_end_date')
  DateTime? get periodEndDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_monthly_amount')
  bool get isMonthlyAmount => throw _privateConstructorUsedError; // Einnahme oder Ausgabe
  @JsonKey(name: 'is_income')
  bool get isIncome => throw _privateConstructorUsedError; // Timestamps
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this VehicleCost to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VehicleCost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VehicleCostCopyWith<VehicleCost> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VehicleCostCopyWith<$Res> {
  factory $VehicleCostCopyWith(
    VehicleCost value,
    $Res Function(VehicleCost) then,
  ) = _$VehicleCostCopyWithImpl<$Res, VehicleCost>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'vehicle_id') String? vehicleId,
    @JsonKey(name: 'category_id') String categoryId,
    String title,
    double amount,
    String currency,
    DateTime date,
    int? mileage,
    String? notes,
    @JsonKey(name: 'is_refueling') bool isRefueling,
    @JsonKey(name: 'fuel_type') String? fuelType,
    @JsonKey(name: 'fuel_amount_liters') double? fuelAmountLiters,
    @JsonKey(name: 'price_per_liter') double? pricePerLiter,
    @JsonKey(name: 'is_full_tank') bool isFullTank,
    @JsonKey(name: 'trip_distance') int? tripDistance,
    @JsonKey(name: 'gas_station') String? gasStation,
    @JsonKey(name: 'distance_highway') int? distanceHighway,
    @JsonKey(name: 'distance_city') int? distanceCity,
    @JsonKey(name: 'distance_country') int? distanceCountry,
    List<String> photos,
    @JsonKey(name: 'maintenance_reminder_id') String? maintenanceReminderId,
    @JsonKey(name: 'period_start_date') DateTime? periodStartDate,
    @JsonKey(name: 'period_end_date') DateTime? periodEndDate,
    @JsonKey(name: 'is_monthly_amount') bool isMonthlyAmount,
    @JsonKey(name: 'is_income') bool isIncome,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$VehicleCostCopyWithImpl<$Res, $Val extends VehicleCost>
    implements $VehicleCostCopyWith<$Res> {
  _$VehicleCostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VehicleCost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? vehicleId = freezed,
    Object? categoryId = null,
    Object? title = null,
    Object? amount = null,
    Object? currency = null,
    Object? date = null,
    Object? mileage = freezed,
    Object? notes = freezed,
    Object? isRefueling = null,
    Object? fuelType = freezed,
    Object? fuelAmountLiters = freezed,
    Object? pricePerLiter = freezed,
    Object? isFullTank = null,
    Object? tripDistance = freezed,
    Object? gasStation = freezed,
    Object? distanceHighway = freezed,
    Object? distanceCity = freezed,
    Object? distanceCountry = freezed,
    Object? photos = null,
    Object? maintenanceReminderId = freezed,
    Object? periodStartDate = freezed,
    Object? periodEndDate = freezed,
    Object? isMonthlyAmount = null,
    Object? isIncome = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
            categoryId:
                null == categoryId
                    ? _value.categoryId
                    : categoryId // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            amount:
                null == amount
                    ? _value.amount
                    : amount // ignore: cast_nullable_to_non_nullable
                        as double,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
                        as String,
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            mileage:
                freezed == mileage
                    ? _value.mileage
                    : mileage // ignore: cast_nullable_to_non_nullable
                        as int?,
            notes:
                freezed == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String?,
            isRefueling:
                null == isRefueling
                    ? _value.isRefueling
                    : isRefueling // ignore: cast_nullable_to_non_nullable
                        as bool,
            fuelType:
                freezed == fuelType
                    ? _value.fuelType
                    : fuelType // ignore: cast_nullable_to_non_nullable
                        as String?,
            fuelAmountLiters:
                freezed == fuelAmountLiters
                    ? _value.fuelAmountLiters
                    : fuelAmountLiters // ignore: cast_nullable_to_non_nullable
                        as double?,
            pricePerLiter:
                freezed == pricePerLiter
                    ? _value.pricePerLiter
                    : pricePerLiter // ignore: cast_nullable_to_non_nullable
                        as double?,
            isFullTank:
                null == isFullTank
                    ? _value.isFullTank
                    : isFullTank // ignore: cast_nullable_to_non_nullable
                        as bool,
            tripDistance:
                freezed == tripDistance
                    ? _value.tripDistance
                    : tripDistance // ignore: cast_nullable_to_non_nullable
                        as int?,
            gasStation:
                freezed == gasStation
                    ? _value.gasStation
                    : gasStation // ignore: cast_nullable_to_non_nullable
                        as String?,
            distanceHighway:
                freezed == distanceHighway
                    ? _value.distanceHighway
                    : distanceHighway // ignore: cast_nullable_to_non_nullable
                        as int?,
            distanceCity:
                freezed == distanceCity
                    ? _value.distanceCity
                    : distanceCity // ignore: cast_nullable_to_non_nullable
                        as int?,
            distanceCountry:
                freezed == distanceCountry
                    ? _value.distanceCountry
                    : distanceCountry // ignore: cast_nullable_to_non_nullable
                        as int?,
            photos:
                null == photos
                    ? _value.photos
                    : photos // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            maintenanceReminderId:
                freezed == maintenanceReminderId
                    ? _value.maintenanceReminderId
                    : maintenanceReminderId // ignore: cast_nullable_to_non_nullable
                        as String?,
            periodStartDate:
                freezed == periodStartDate
                    ? _value.periodStartDate
                    : periodStartDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            periodEndDate:
                freezed == periodEndDate
                    ? _value.periodEndDate
                    : periodEndDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            isMonthlyAmount:
                null == isMonthlyAmount
                    ? _value.isMonthlyAmount
                    : isMonthlyAmount // ignore: cast_nullable_to_non_nullable
                        as bool,
            isIncome:
                null == isIncome
                    ? _value.isIncome
                    : isIncome // ignore: cast_nullable_to_non_nullable
                        as bool,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VehicleCostImplCopyWith<$Res>
    implements $VehicleCostCopyWith<$Res> {
  factory _$$VehicleCostImplCopyWith(
    _$VehicleCostImpl value,
    $Res Function(_$VehicleCostImpl) then,
  ) = __$$VehicleCostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'vehicle_id') String? vehicleId,
    @JsonKey(name: 'category_id') String categoryId,
    String title,
    double amount,
    String currency,
    DateTime date,
    int? mileage,
    String? notes,
    @JsonKey(name: 'is_refueling') bool isRefueling,
    @JsonKey(name: 'fuel_type') String? fuelType,
    @JsonKey(name: 'fuel_amount_liters') double? fuelAmountLiters,
    @JsonKey(name: 'price_per_liter') double? pricePerLiter,
    @JsonKey(name: 'is_full_tank') bool isFullTank,
    @JsonKey(name: 'trip_distance') int? tripDistance,
    @JsonKey(name: 'gas_station') String? gasStation,
    @JsonKey(name: 'distance_highway') int? distanceHighway,
    @JsonKey(name: 'distance_city') int? distanceCity,
    @JsonKey(name: 'distance_country') int? distanceCountry,
    List<String> photos,
    @JsonKey(name: 'maintenance_reminder_id') String? maintenanceReminderId,
    @JsonKey(name: 'period_start_date') DateTime? periodStartDate,
    @JsonKey(name: 'period_end_date') DateTime? periodEndDate,
    @JsonKey(name: 'is_monthly_amount') bool isMonthlyAmount,
    @JsonKey(name: 'is_income') bool isIncome,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$VehicleCostImplCopyWithImpl<$Res>
    extends _$VehicleCostCopyWithImpl<$Res, _$VehicleCostImpl>
    implements _$$VehicleCostImplCopyWith<$Res> {
  __$$VehicleCostImplCopyWithImpl(
    _$VehicleCostImpl _value,
    $Res Function(_$VehicleCostImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VehicleCost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? vehicleId = freezed,
    Object? categoryId = null,
    Object? title = null,
    Object? amount = null,
    Object? currency = null,
    Object? date = null,
    Object? mileage = freezed,
    Object? notes = freezed,
    Object? isRefueling = null,
    Object? fuelType = freezed,
    Object? fuelAmountLiters = freezed,
    Object? pricePerLiter = freezed,
    Object? isFullTank = null,
    Object? tripDistance = freezed,
    Object? gasStation = freezed,
    Object? distanceHighway = freezed,
    Object? distanceCity = freezed,
    Object? distanceCountry = freezed,
    Object? photos = null,
    Object? maintenanceReminderId = freezed,
    Object? periodStartDate = freezed,
    Object? periodEndDate = freezed,
    Object? isMonthlyAmount = null,
    Object? isIncome = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$VehicleCostImpl(
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
        categoryId:
            null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        amount:
            null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                    as double,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                    as String,
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        mileage:
            freezed == mileage
                ? _value.mileage
                : mileage // ignore: cast_nullable_to_non_nullable
                    as int?,
        notes:
            freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String?,
        isRefueling:
            null == isRefueling
                ? _value.isRefueling
                : isRefueling // ignore: cast_nullable_to_non_nullable
                    as bool,
        fuelType:
            freezed == fuelType
                ? _value.fuelType
                : fuelType // ignore: cast_nullable_to_non_nullable
                    as String?,
        fuelAmountLiters:
            freezed == fuelAmountLiters
                ? _value.fuelAmountLiters
                : fuelAmountLiters // ignore: cast_nullable_to_non_nullable
                    as double?,
        pricePerLiter:
            freezed == pricePerLiter
                ? _value.pricePerLiter
                : pricePerLiter // ignore: cast_nullable_to_non_nullable
                    as double?,
        isFullTank:
            null == isFullTank
                ? _value.isFullTank
                : isFullTank // ignore: cast_nullable_to_non_nullable
                    as bool,
        tripDistance:
            freezed == tripDistance
                ? _value.tripDistance
                : tripDistance // ignore: cast_nullable_to_non_nullable
                    as int?,
        gasStation:
            freezed == gasStation
                ? _value.gasStation
                : gasStation // ignore: cast_nullable_to_non_nullable
                    as String?,
        distanceHighway:
            freezed == distanceHighway
                ? _value.distanceHighway
                : distanceHighway // ignore: cast_nullable_to_non_nullable
                    as int?,
        distanceCity:
            freezed == distanceCity
                ? _value.distanceCity
                : distanceCity // ignore: cast_nullable_to_non_nullable
                    as int?,
        distanceCountry:
            freezed == distanceCountry
                ? _value.distanceCountry
                : distanceCountry // ignore: cast_nullable_to_non_nullable
                    as int?,
        photos:
            null == photos
                ? _value._photos
                : photos // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        maintenanceReminderId:
            freezed == maintenanceReminderId
                ? _value.maintenanceReminderId
                : maintenanceReminderId // ignore: cast_nullable_to_non_nullable
                    as String?,
        periodStartDate:
            freezed == periodStartDate
                ? _value.periodStartDate
                : periodStartDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        periodEndDate:
            freezed == periodEndDate
                ? _value.periodEndDate
                : periodEndDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        isMonthlyAmount:
            null == isMonthlyAmount
                ? _value.isMonthlyAmount
                : isMonthlyAmount // ignore: cast_nullable_to_non_nullable
                    as bool,
        isIncome:
            null == isIncome
                ? _value.isIncome
                : isIncome // ignore: cast_nullable_to_non_nullable
                    as bool,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VehicleCostImpl implements _VehicleCost {
  const _$VehicleCostImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'vehicle_id') this.vehicleId,
    @JsonKey(name: 'category_id') required this.categoryId,
    required this.title,
    required this.amount,
    this.currency = 'EUR',
    required this.date,
    this.mileage,
    this.notes,
    @JsonKey(name: 'is_refueling') this.isRefueling = false,
    @JsonKey(name: 'fuel_type') this.fuelType,
    @JsonKey(name: 'fuel_amount_liters') this.fuelAmountLiters,
    @JsonKey(name: 'price_per_liter') this.pricePerLiter,
    @JsonKey(name: 'is_full_tank') this.isFullTank = false,
    @JsonKey(name: 'trip_distance') this.tripDistance,
    @JsonKey(name: 'gas_station') this.gasStation,
    @JsonKey(name: 'distance_highway') this.distanceHighway,
    @JsonKey(name: 'distance_city') this.distanceCity,
    @JsonKey(name: 'distance_country') this.distanceCountry,
    final List<String> photos = const [],
    @JsonKey(name: 'maintenance_reminder_id') this.maintenanceReminderId,
    @JsonKey(name: 'period_start_date') this.periodStartDate,
    @JsonKey(name: 'period_end_date') this.periodEndDate,
    @JsonKey(name: 'is_monthly_amount') this.isMonthlyAmount = false,
    @JsonKey(name: 'is_income') this.isIncome = false,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _photos = photos;

  factory _$VehicleCostImpl.fromJson(Map<String, dynamic> json) =>
      _$$VehicleCostImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  // Optional: Wird in Phase 1 aus Profil genommen
  @override
  @JsonKey(name: 'category_id')
  final String categoryId;
  // Basisdaten
  @override
  final String title;
  @override
  final double amount;
  @override
  @JsonKey()
  final String currency;
  @override
  final DateTime date;
  @override
  final int? mileage;
  @override
  final String? notes;
  // Treibstoff-spezifisch (nur für Treibstoff-Kategorie)
  @override
  @JsonKey(name: 'is_refueling')
  final bool isRefueling;
  @override
  @JsonKey(name: 'fuel_type')
  final String? fuelType;
  // 'petrol', 'diesel', 'electric', 'hybrid'
  @override
  @JsonKey(name: 'fuel_amount_liters')
  final double? fuelAmountLiters;
  @override
  @JsonKey(name: 'price_per_liter')
  final double? pricePerLiter;
  @override
  @JsonKey(name: 'is_full_tank')
  final bool isFullTank;
  @override
  @JsonKey(name: 'trip_distance')
  final int? tripDistance;
  // km seit letzter Betankung
  @override
  @JsonKey(name: 'gas_station')
  final String? gasStation;
  // Streckentyp (optional)
  @override
  @JsonKey(name: 'distance_highway')
  final int? distanceHighway;
  @override
  @JsonKey(name: 'distance_city')
  final int? distanceCity;
  @override
  @JsonKey(name: 'distance_country')
  final int? distanceCountry;
  // Medien
  final List<String> _photos;
  // Medien
  @override
  @JsonKey()
  List<String> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  // Storage URLs
  // Verknüpfung mit Wartungen
  @override
  @JsonKey(name: 'maintenance_reminder_id')
  final String? maintenanceReminderId;
  // Zeitraum-spezifisch (nur für Versicherung/Steuer/Kredit)
  @override
  @JsonKey(name: 'period_start_date')
  final DateTime? periodStartDate;
  @override
  @JsonKey(name: 'period_end_date')
  final DateTime? periodEndDate;
  @override
  @JsonKey(name: 'is_monthly_amount')
  final bool isMonthlyAmount;
  // Einnahme oder Ausgabe
  @override
  @JsonKey(name: 'is_income')
  final bool isIncome;
  // Timestamps
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'VehicleCost(id: $id, userId: $userId, vehicleId: $vehicleId, categoryId: $categoryId, title: $title, amount: $amount, currency: $currency, date: $date, mileage: $mileage, notes: $notes, isRefueling: $isRefueling, fuelType: $fuelType, fuelAmountLiters: $fuelAmountLiters, pricePerLiter: $pricePerLiter, isFullTank: $isFullTank, tripDistance: $tripDistance, gasStation: $gasStation, distanceHighway: $distanceHighway, distanceCity: $distanceCity, distanceCountry: $distanceCountry, photos: $photos, maintenanceReminderId: $maintenanceReminderId, periodStartDate: $periodStartDate, periodEndDate: $periodEndDate, isMonthlyAmount: $isMonthlyAmount, isIncome: $isIncome, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VehicleCostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.mileage, mileage) || other.mileage == mileage) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isRefueling, isRefueling) ||
                other.isRefueling == isRefueling) &&
            (identical(other.fuelType, fuelType) ||
                other.fuelType == fuelType) &&
            (identical(other.fuelAmountLiters, fuelAmountLiters) ||
                other.fuelAmountLiters == fuelAmountLiters) &&
            (identical(other.pricePerLiter, pricePerLiter) ||
                other.pricePerLiter == pricePerLiter) &&
            (identical(other.isFullTank, isFullTank) ||
                other.isFullTank == isFullTank) &&
            (identical(other.tripDistance, tripDistance) ||
                other.tripDistance == tripDistance) &&
            (identical(other.gasStation, gasStation) ||
                other.gasStation == gasStation) &&
            (identical(other.distanceHighway, distanceHighway) ||
                other.distanceHighway == distanceHighway) &&
            (identical(other.distanceCity, distanceCity) ||
                other.distanceCity == distanceCity) &&
            (identical(other.distanceCountry, distanceCountry) ||
                other.distanceCountry == distanceCountry) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            (identical(other.maintenanceReminderId, maintenanceReminderId) ||
                other.maintenanceReminderId == maintenanceReminderId) &&
            (identical(other.periodStartDate, periodStartDate) ||
                other.periodStartDate == periodStartDate) &&
            (identical(other.periodEndDate, periodEndDate) ||
                other.periodEndDate == periodEndDate) &&
            (identical(other.isMonthlyAmount, isMonthlyAmount) ||
                other.isMonthlyAmount == isMonthlyAmount) &&
            (identical(other.isIncome, isIncome) ||
                other.isIncome == isIncome) &&
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
    categoryId,
    title,
    amount,
    currency,
    date,
    mileage,
    notes,
    isRefueling,
    fuelType,
    fuelAmountLiters,
    pricePerLiter,
    isFullTank,
    tripDistance,
    gasStation,
    distanceHighway,
    distanceCity,
    distanceCountry,
    const DeepCollectionEquality().hash(_photos),
    maintenanceReminderId,
    periodStartDate,
    periodEndDate,
    isMonthlyAmount,
    isIncome,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of VehicleCost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VehicleCostImplCopyWith<_$VehicleCostImpl> get copyWith =>
      __$$VehicleCostImplCopyWithImpl<_$VehicleCostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VehicleCostImplToJson(this);
  }
}

abstract class _VehicleCost implements VehicleCost {
  const factory _VehicleCost({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'vehicle_id') final String? vehicleId,
    @JsonKey(name: 'category_id') required final String categoryId,
    required final String title,
    required final double amount,
    final String currency,
    required final DateTime date,
    final int? mileage,
    final String? notes,
    @JsonKey(name: 'is_refueling') final bool isRefueling,
    @JsonKey(name: 'fuel_type') final String? fuelType,
    @JsonKey(name: 'fuel_amount_liters') final double? fuelAmountLiters,
    @JsonKey(name: 'price_per_liter') final double? pricePerLiter,
    @JsonKey(name: 'is_full_tank') final bool isFullTank,
    @JsonKey(name: 'trip_distance') final int? tripDistance,
    @JsonKey(name: 'gas_station') final String? gasStation,
    @JsonKey(name: 'distance_highway') final int? distanceHighway,
    @JsonKey(name: 'distance_city') final int? distanceCity,
    @JsonKey(name: 'distance_country') final int? distanceCountry,
    final List<String> photos,
    @JsonKey(name: 'maintenance_reminder_id')
    final String? maintenanceReminderId,
    @JsonKey(name: 'period_start_date') final DateTime? periodStartDate,
    @JsonKey(name: 'period_end_date') final DateTime? periodEndDate,
    @JsonKey(name: 'is_monthly_amount') final bool isMonthlyAmount,
    @JsonKey(name: 'is_income') final bool isIncome,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$VehicleCostImpl;

  factory _VehicleCost.fromJson(Map<String, dynamic> json) =
      _$VehicleCostImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'vehicle_id')
  String? get vehicleId; // Optional: Wird in Phase 1 aus Profil genommen
  @override
  @JsonKey(name: 'category_id')
  String get categoryId; // Basisdaten
  @override
  String get title;
  @override
  double get amount;
  @override
  String get currency;
  @override
  DateTime get date;
  @override
  int? get mileage;
  @override
  String? get notes; // Treibstoff-spezifisch (nur für Treibstoff-Kategorie)
  @override
  @JsonKey(name: 'is_refueling')
  bool get isRefueling;
  @override
  @JsonKey(name: 'fuel_type')
  String? get fuelType; // 'petrol', 'diesel', 'electric', 'hybrid'
  @override
  @JsonKey(name: 'fuel_amount_liters')
  double? get fuelAmountLiters;
  @override
  @JsonKey(name: 'price_per_liter')
  double? get pricePerLiter;
  @override
  @JsonKey(name: 'is_full_tank')
  bool get isFullTank;
  @override
  @JsonKey(name: 'trip_distance')
  int? get tripDistance; // km seit letzter Betankung
  @override
  @JsonKey(name: 'gas_station')
  String? get gasStation; // Streckentyp (optional)
  @override
  @JsonKey(name: 'distance_highway')
  int? get distanceHighway;
  @override
  @JsonKey(name: 'distance_city')
  int? get distanceCity;
  @override
  @JsonKey(name: 'distance_country')
  int? get distanceCountry; // Medien
  @override
  List<String> get photos; // Storage URLs
  // Verknüpfung mit Wartungen
  @override
  @JsonKey(name: 'maintenance_reminder_id')
  String? get maintenanceReminderId; // Zeitraum-spezifisch (nur für Versicherung/Steuer/Kredit)
  @override
  @JsonKey(name: 'period_start_date')
  DateTime? get periodStartDate;
  @override
  @JsonKey(name: 'period_end_date')
  DateTime? get periodEndDate;
  @override
  @JsonKey(name: 'is_monthly_amount')
  bool get isMonthlyAmount; // Einnahme oder Ausgabe
  @override
  @JsonKey(name: 'is_income')
  bool get isIncome; // Timestamps
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of VehicleCost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VehicleCostImplCopyWith<_$VehicleCostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
