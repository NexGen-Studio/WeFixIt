import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_cost.freezed.dart';
part 'vehicle_cost.g.dart';

/// Fahrzeugkosten-Eintrag
@freezed
class VehicleCost with _$VehicleCost {
  const factory VehicleCost({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'vehicle_id') String? vehicleId, // Optional: Wird in Phase 1 aus Profil genommen
    @JsonKey(name: 'category_id') required String categoryId,
    
    // Basisdaten
    required String title,
    required double amount,
    @Default('EUR') String currency,
    required DateTime date,
    int? mileage,
    String? notes,
    
    // Treibstoff-spezifisch (nur für Treibstoff-Kategorie)
    @JsonKey(name: 'is_refueling') @Default(false) bool isRefueling,
    @JsonKey(name: 'fuel_type') String? fuelType, // 'petrol', 'diesel', 'electric', 'hybrid'
    @JsonKey(name: 'fuel_amount_liters') double? fuelAmountLiters,
    @JsonKey(name: 'price_per_liter') double? pricePerLiter,
    @JsonKey(name: 'is_full_tank') @Default(false) bool isFullTank,
    @JsonKey(name: 'trip_distance') int? tripDistance, // km seit letzter Betankung
    @JsonKey(name: 'gas_station') String? gasStation,
    
    // Streckentyp (optional)
    @JsonKey(name: 'distance_highway') int? distanceHighway,
    @JsonKey(name: 'distance_city') int? distanceCity,
    @JsonKey(name: 'distance_country') int? distanceCountry,
    
    // Medien
    @Default([]) List<String> photos, // Storage URLs
    
    // Verknüpfung mit Wartungen
    @JsonKey(name: 'maintenance_reminder_id') String? maintenanceReminderId,
    
    // Zeitraum-spezifisch (nur für Versicherung/Steuer/Kredit)
    @JsonKey(name: 'period_start_date') DateTime? periodStartDate,
    @JsonKey(name: 'period_end_date') DateTime? periodEndDate,
    @JsonKey(name: 'is_monthly_amount') @Default(false) bool isMonthlyAmount,
    
    // Einnahme oder Ausgabe
    @JsonKey(name: 'is_income') @Default(false) bool isIncome,
    
    // Timestamps
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _VehicleCost;

  factory VehicleCost.fromJson(Map<String, dynamic> json) =>
      _$VehicleCostFromJson(json);
}

/// Treibstoff-Typen
enum FuelType {
  petrol('petrol'),
  diesel('diesel'),
  electric('electric'),
  hybrid('hybrid');

  final String value;
  const FuelType(this.value);

  static FuelType? fromString(String? value) {
    if (value == null) return null;
    return FuelType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FuelType.petrol,
    );
  }
}
