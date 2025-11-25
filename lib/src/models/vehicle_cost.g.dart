// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_cost.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VehicleCostImpl _$$VehicleCostImplFromJson(Map<String, dynamic> json) =>
    _$VehicleCostImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String?,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      date: DateTime.parse(json['date'] as String),
      mileage: (json['mileage'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      isRefueling: json['is_refueling'] as bool? ?? false,
      fuelType: json['fuel_type'] as String?,
      fuelAmountLiters: (json['fuel_amount_liters'] as num?)?.toDouble(),
      pricePerLiter: (json['price_per_liter'] as num?)?.toDouble(),
      isFullTank: json['is_full_tank'] as bool? ?? false,
      tripDistance: (json['trip_distance'] as num?)?.toInt(),
      gasStation: json['gas_station'] as String?,
      distanceHighway: (json['distance_highway'] as num?)?.toInt(),
      distanceCity: (json['distance_city'] as num?)?.toInt(),
      distanceCountry: (json['distance_country'] as num?)?.toInt(),
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maintenanceReminderId: json['maintenance_reminder_id'] as String?,
      periodStartDate:
          json['period_start_date'] == null
              ? null
              : DateTime.parse(json['period_start_date'] as String),
      periodEndDate:
          json['period_end_date'] == null
              ? null
              : DateTime.parse(json['period_end_date'] as String),
      isMonthlyAmount: json['is_monthly_amount'] as bool? ?? false,
      isIncome: json['is_income'] as bool? ?? false,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$VehicleCostImplToJson(_$VehicleCostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'vehicle_id': instance.vehicleId,
      'category_id': instance.categoryId,
      'title': instance.title,
      'amount': instance.amount,
      'currency': instance.currency,
      'date': instance.date.toIso8601String(),
      'mileage': instance.mileage,
      'notes': instance.notes,
      'is_refueling': instance.isRefueling,
      'fuel_type': instance.fuelType,
      'fuel_amount_liters': instance.fuelAmountLiters,
      'price_per_liter': instance.pricePerLiter,
      'is_full_tank': instance.isFullTank,
      'trip_distance': instance.tripDistance,
      'gas_station': instance.gasStation,
      'distance_highway': instance.distanceHighway,
      'distance_city': instance.distanceCity,
      'distance_country': instance.distanceCountry,
      'photos': instance.photos,
      'maintenance_reminder_id': instance.maintenanceReminderId,
      'period_start_date': instance.periodStartDate?.toIso8601String(),
      'period_end_date': instance.periodEndDate?.toIso8601String(),
      'is_monthly_amount': instance.isMonthlyAmount,
      'is_income': instance.isIncome,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
