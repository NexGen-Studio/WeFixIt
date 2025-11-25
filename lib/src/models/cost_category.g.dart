// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CostCategoryImpl _$$CostCategoryImplFromJson(Map<String, dynamic> json) =>
    _$CostCategoryImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      iconName: json['icon_name'] as String,
      colorHex: json['color_hex'] as String,
      isSystem: json['is_system'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CostCategoryImplToJson(_$CostCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'icon_name': instance.iconName,
      'color_hex': instance.colorHex,
      'is_system': instance.isSystem,
      'sort_order': instance.sortOrder,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
