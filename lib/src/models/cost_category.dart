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
    @JsonKey(name: 'is_locked') @Default(false) bool isLocked, // Für Premium-Gate
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CostCategory;

  factory CostCategory.fromJson(Map<String, dynamic> json) =>
      _$CostCategoryFromJson(json);

  /// Hilfsmethode: Farbe als Color-Objekt
  static Color hexToColor(String hexString) {
    // Handle both formats: 0xFFFFB129 and #FFFB129
    String cleanHex = hexString
        .replaceFirst('0x', '')
        .replaceFirst('#', '')
        .toUpperCase();
    
    // Add alpha channel if missing
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    
    return Color(int.parse(cleanHex, radix: 16));
  }

  /// Hilfsmethode: Icon aus Name
  static IconData getIconData(String iconName) {
    final iconMap = <String, IconData>{
      // Kostenkategorien Icons
      'local_gas_station': Icons.local_gas_station,
      'build': Icons.build,
      'security': Icons.security, // FIX: Versicherung
      'shield': Icons.shield,
      'account_balance': Icons.account_balance,
      'credit_card': Icons.credit_card,
      'local_parking': Icons.local_parking,
      'local_car_wash': Icons.local_car_wash,
      'shopping_cart': Icons.shopping_cart,
      'toll': Icons.toll, // FIX: Maut & Vignette
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
      'shield_outlined': Icons.shield_outlined,
      
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
    
    // Fallback wenn Icon nicht gefunden wird
    return iconMap[iconName] ?? Icons.category;
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

/// Extension für lokalisierte Kategorien-Namen
extension CostCategoryLocalization on CostCategory {
  /// Gibt den lokalisierten Namen der Kategorie zurück
  /// Verwendet i18n Keys basierend auf dem deutschen Namen aus der DB
  String getLocalizedName(dynamic localizationContext) {
    // Für Custom-Kategorien (user_id != null) gib den Namen direkt zurück
    if (userId != null) {
      return name;
    }
    
    // Map deutsche Namen auf i18n Keys
    final nameKeyMap = {
      'Treibstoff': 'costs.category_fuel_name',
      'Wartung & Reparatur': 'costs.category_maintenance_name',
      'Versicherung': 'costs.category_insurance_name',
      'Steuer': 'costs.category_tax_name',
      'Parkgebühren': 'costs.category_parking_name',
      'Autowäsche': 'costs.category_washing_name',
      'Maut & Vignette': 'costs.category_toll_name',
      'Reifen': 'costs.category_tires_name',
      'Zubehör': 'costs.category_accessories_name',
      'Einnahmen': 'costs.category_income_name',
      'Sonstiges': 'costs.category_other_name',
    };
    
    final i18nKey = nameKeyMap[name];
    if (i18nKey != null && localizationContext != null) {
      try {
        return localizationContext.tr(i18nKey);
      } catch (_) {
        return name; // Fallback
      }
    }
    
    return name; // Fallback für unbekannte Kategorien
  }
}
