// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cost_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CostCategory _$CostCategoryFromJson(Map<String, dynamic> json) {
  return _CostCategory.fromJson(json);
}

/// @nodoc
mixin _$CostCategory {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError; // null = System-Kategorie
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'icon_name')
  String get iconName => throw _privateConstructorUsedError; // Material Icon name
  @JsonKey(name: 'color_hex')
  String get colorHex => throw _privateConstructorUsedError; // z.B. '#FF5722'
  @JsonKey(name: 'is_system')
  bool get isSystem => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_locked')
  bool get isLocked => throw _privateConstructorUsedError; // Für Premium-Gate
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CostCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CostCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CostCategoryCopyWith<CostCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CostCategoryCopyWith<$Res> {
  factory $CostCategoryCopyWith(
    CostCategory value,
    $Res Function(CostCategory) then,
  ) = _$CostCategoryCopyWithImpl<$Res, CostCategory>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String? userId,
    String name,
    @JsonKey(name: 'icon_name') String iconName,
    @JsonKey(name: 'color_hex') String colorHex,
    @JsonKey(name: 'is_system') bool isSystem,
    @JsonKey(name: 'is_locked') bool isLocked,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$CostCategoryCopyWithImpl<$Res, $Val extends CostCategory>
    implements $CostCategoryCopyWith<$Res> {
  _$CostCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CostCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? name = null,
    Object? iconName = null,
    Object? colorHex = null,
    Object? isSystem = null,
    Object? isLocked = null,
    Object? sortOrder = null,
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
                freezed == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String?,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            iconName:
                null == iconName
                    ? _value.iconName
                    : iconName // ignore: cast_nullable_to_non_nullable
                        as String,
            colorHex:
                null == colorHex
                    ? _value.colorHex
                    : colorHex // ignore: cast_nullable_to_non_nullable
                        as String,
            isSystem:
                null == isSystem
                    ? _value.isSystem
                    : isSystem // ignore: cast_nullable_to_non_nullable
                        as bool,
            isLocked:
                null == isLocked
                    ? _value.isLocked
                    : isLocked // ignore: cast_nullable_to_non_nullable
                        as bool,
            sortOrder:
                null == sortOrder
                    ? _value.sortOrder
                    : sortOrder // ignore: cast_nullable_to_non_nullable
                        as int,
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
abstract class _$$CostCategoryImplCopyWith<$Res>
    implements $CostCategoryCopyWith<$Res> {
  factory _$$CostCategoryImplCopyWith(
    _$CostCategoryImpl value,
    $Res Function(_$CostCategoryImpl) then,
  ) = __$$CostCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String? userId,
    String name,
    @JsonKey(name: 'icon_name') String iconName,
    @JsonKey(name: 'color_hex') String colorHex,
    @JsonKey(name: 'is_system') bool isSystem,
    @JsonKey(name: 'is_locked') bool isLocked,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$CostCategoryImplCopyWithImpl<$Res>
    extends _$CostCategoryCopyWithImpl<$Res, _$CostCategoryImpl>
    implements _$$CostCategoryImplCopyWith<$Res> {
  __$$CostCategoryImplCopyWithImpl(
    _$CostCategoryImpl _value,
    $Res Function(_$CostCategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CostCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? name = null,
    Object? iconName = null,
    Object? colorHex = null,
    Object? isSystem = null,
    Object? isLocked = null,
    Object? sortOrder = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CostCategoryImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        userId:
            freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String?,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        iconName:
            null == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                    as String,
        colorHex:
            null == colorHex
                ? _value.colorHex
                : colorHex // ignore: cast_nullable_to_non_nullable
                    as String,
        isSystem:
            null == isSystem
                ? _value.isSystem
                : isSystem // ignore: cast_nullable_to_non_nullable
                    as bool,
        isLocked:
            null == isLocked
                ? _value.isLocked
                : isLocked // ignore: cast_nullable_to_non_nullable
                    as bool,
        sortOrder:
            null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                    as int,
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
class _$CostCategoryImpl implements _CostCategory {
  const _$CostCategoryImpl({
    required this.id,
    @JsonKey(name: 'user_id') this.userId,
    required this.name,
    @JsonKey(name: 'icon_name') required this.iconName,
    @JsonKey(name: 'color_hex') required this.colorHex,
    @JsonKey(name: 'is_system') this.isSystem = false,
    @JsonKey(name: 'is_locked') this.isLocked = false,
    @JsonKey(name: 'sort_order') this.sortOrder = 0,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$CostCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CostCategoryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  // null = System-Kategorie
  @override
  final String name;
  @override
  @JsonKey(name: 'icon_name')
  final String iconName;
  // Material Icon name
  @override
  @JsonKey(name: 'color_hex')
  final String colorHex;
  // z.B. '#FF5722'
  @override
  @JsonKey(name: 'is_system')
  final bool isSystem;
  @override
  @JsonKey(name: 'is_locked')
  final bool isLocked;
  // Für Premium-Gate
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CostCategory(id: $id, userId: $userId, name: $name, iconName: $iconName, colorHex: $colorHex, isSystem: $isSystem, isLocked: $isLocked, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CostCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.isSystem, isSystem) ||
                other.isSystem == isSystem) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    iconName,
    colorHex,
    isSystem,
    isLocked,
    sortOrder,
    createdAt,
    updatedAt,
  );

  /// Create a copy of CostCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CostCategoryImplCopyWith<_$CostCategoryImpl> get copyWith =>
      __$$CostCategoryImplCopyWithImpl<_$CostCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CostCategoryImplToJson(this);
  }
}

abstract class _CostCategory implements CostCategory {
  const factory _CostCategory({
    required final String id,
    @JsonKey(name: 'user_id') final String? userId,
    required final String name,
    @JsonKey(name: 'icon_name') required final String iconName,
    @JsonKey(name: 'color_hex') required final String colorHex,
    @JsonKey(name: 'is_system') final bool isSystem,
    @JsonKey(name: 'is_locked') final bool isLocked,
    @JsonKey(name: 'sort_order') final int sortOrder,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$CostCategoryImpl;

  factory _CostCategory.fromJson(Map<String, dynamic> json) =
      _$CostCategoryImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String? get userId; // null = System-Kategorie
  @override
  String get name;
  @override
  @JsonKey(name: 'icon_name')
  String get iconName; // Material Icon name
  @override
  @JsonKey(name: 'color_hex')
  String get colorHex; // z.B. '#FF5722'
  @override
  @JsonKey(name: 'is_system')
  bool get isSystem;
  @override
  @JsonKey(name: 'is_locked')
  bool get isLocked; // Für Premium-Gate
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of CostCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CostCategoryImplCopyWith<_$CostCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
