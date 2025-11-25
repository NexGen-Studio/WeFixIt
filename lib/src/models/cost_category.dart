import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'cost_category.freezed.dart';
part 'cost_category.g.dart';

/// Kostenkategorie (Standard oder benutzerdefiniert)
@freezed
class CostCategory with _$CostCategory {
  const factory CostCategory({
    required String id,
    @JsonKey(name: 'user_id') String? userId, // null = System-Kategorie
    required String name,
    @JsonKey(name: 'icon_name') required String iconName, // Material Icon name
    @JsonKey(name: 'color_hex') required String colorHex, // z.B. '#FF5722'
    @JsonKey(name: 'is_system') @Default(false) bool isSystem,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CostCategory;

  factory CostCategory.fromJson(Map<String, dynamic> json) =>
      _$CostCategoryFromJson(json);

  /// Hilfsmethode: Farbe als Color-Objekt
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Hilfsmethode: Icon aus Name
  static IconData? getIconData(String iconName) {
    final iconMap = <String, IconData>{
      'local_gas_station': Icons.local_gas_station,
      'build': Icons.build,
      'shield': Icons.shield,
      'account_balance': Icons.account_balance,
      'credit_card': Icons.credit_card,
      'local_parking': Icons.local_parking,
      'local_car_wash': Icons.local_car_wash,
      'shopping_cart': Icons.shopping_cart,
      'confirmation_number': Icons.confirmation_number,
      'attach_money': Icons.attach_money,
      'more_horiz': Icons.more_horiz,
      
      // Maintenance Specific Icons
      'oil_barrel_outlined': Icons.oil_barrel_outlined,
      'tire_repair': Icons.tire_repair,
      'handyman_outlined': Icons.handyman_outlined,
      'verified_outlined': Icons.verified_outlined,
      'build_circle_outlined': Icons.build_circle_outlined,
      'battery_charging_full': Icons.battery_charging_full,
      'filter_alt_outlined': Icons.filter_alt_outlined,
      'receipt_long_outlined': Icons.receipt_long_outlined,
      'shield_outlined': Icons.shield_outlined, // Add specific shield outlined
      
      // Zusätzliche Icons für Custom Categories
      'star': Icons.star,
      'favorite': Icons.favorite,
      'home': Icons.home,
      'work': Icons.work,
      'settings': Icons.settings,
      'event': Icons.event,
      'person': Icons.person,
      'emoji_transportation': Icons.emoji_transportation,
      'directions_car': Icons.directions_car,
      'local_shipping': Icons.local_shipping,
      'two_wheeler': Icons.two_wheeler,
      'electric_car': Icons.electric_car,
    };
    
    return iconMap[iconName];
  }
}

/// Standard-Kategorien IDs (für einfachen Zugriff)
class SystemCategories {
  static const String fuel = 'fuel';
  static const String maintenance = 'maintenance';
  static const String insurance = 'insurance';
  static const String tax = 'tax';
  static const String leasing = 'leasing';
  static const String parking = 'parking';
  static const String cleaning = 'cleaning';
  static const String accessories = 'accessories';
  static const String vignette = 'vignette';
  static const String income = 'income';
  static const String other = 'other';
}
