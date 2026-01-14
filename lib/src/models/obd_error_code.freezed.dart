// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'obd_error_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ObdErrorCode _$ObdErrorCodeFromJson(Map<String, dynamic> json) {
  return _ObdErrorCode.fromJson(json);
}

/// @nodoc
mixin _$ObdErrorCode {
  String get code => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get descriptionDe => throw _privateConstructorUsedError;
  String? get descriptionEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'code_type')
  String? get codeType => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_generic')
  bool get isGeneric => throw _privateConstructorUsedError;
  List<String>? get symptoms => throw _privateConstructorUsedError;
  @JsonKey(name: 'common_causes')
  List<String>? get commonCauses => throw _privateConstructorUsedError;
  @JsonKey(name: 'diagnostic_steps')
  List<String>? get diagnosticSteps => throw _privateConstructorUsedError;
  @JsonKey(name: 'repair_suggestions')
  List<String>? get repairSuggestions => throw _privateConstructorUsedError;
  @JsonKey(name: 'affected_components')
  List<String>? get affectedComponents => throw _privateConstructorUsedError;
  String? get severity =>
      throw _privateConstructorUsedError; // 'low', 'medium', 'high', 'critical'
  @JsonKey(name: 'drive_safety')
  bool get driveSafety => throw _privateConstructorUsedError;
  @JsonKey(name: 'immediate_action_required')
  bool get immediateActionRequired => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_codes')
  List<String>? get relatedCodes => throw _privateConstructorUsedError;
  @JsonKey(name: 'typical_cost_range_eur')
  String? get typicalCostRange => throw _privateConstructorUsedError;
  @JsonKey(name: 'occurrence_frequency')
  String? get occurrenceFrequency => throw _privateConstructorUsedError;

  /// Serializes this ObdErrorCode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ObdErrorCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ObdErrorCodeCopyWith<ObdErrorCode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObdErrorCodeCopyWith<$Res> {
  factory $ObdErrorCodeCopyWith(
    ObdErrorCode value,
    $Res Function(ObdErrorCode) then,
  ) = _$ObdErrorCodeCopyWithImpl<$Res, ObdErrorCode>;
  @useResult
  $Res call({
    String code,
    String? description,
    String? descriptionDe,
    String? descriptionEn,
    @JsonKey(name: 'code_type') String? codeType,
    @JsonKey(name: 'is_generic') bool isGeneric,
    List<String>? symptoms,
    @JsonKey(name: 'common_causes') List<String>? commonCauses,
    @JsonKey(name: 'diagnostic_steps') List<String>? diagnosticSteps,
    @JsonKey(name: 'repair_suggestions') List<String>? repairSuggestions,
    @JsonKey(name: 'affected_components') List<String>? affectedComponents,
    String? severity,
    @JsonKey(name: 'drive_safety') bool driveSafety,
    @JsonKey(name: 'immediate_action_required') bool immediateActionRequired,
    @JsonKey(name: 'related_codes') List<String>? relatedCodes,
    @JsonKey(name: 'typical_cost_range_eur') String? typicalCostRange,
    @JsonKey(name: 'occurrence_frequency') String? occurrenceFrequency,
  });
}

/// @nodoc
class _$ObdErrorCodeCopyWithImpl<$Res, $Val extends ObdErrorCode>
    implements $ObdErrorCodeCopyWith<$Res> {
  _$ObdErrorCodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ObdErrorCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? description = freezed,
    Object? descriptionDe = freezed,
    Object? descriptionEn = freezed,
    Object? codeType = freezed,
    Object? isGeneric = null,
    Object? symptoms = freezed,
    Object? commonCauses = freezed,
    Object? diagnosticSteps = freezed,
    Object? repairSuggestions = freezed,
    Object? affectedComponents = freezed,
    Object? severity = freezed,
    Object? driveSafety = null,
    Object? immediateActionRequired = null,
    Object? relatedCodes = freezed,
    Object? typicalCostRange = freezed,
    Object? occurrenceFrequency = freezed,
  }) {
    return _then(
      _value.copyWith(
            code:
                null == code
                    ? _value.code
                    : code // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            descriptionDe:
                freezed == descriptionDe
                    ? _value.descriptionDe
                    : descriptionDe // ignore: cast_nullable_to_non_nullable
                        as String?,
            descriptionEn:
                freezed == descriptionEn
                    ? _value.descriptionEn
                    : descriptionEn // ignore: cast_nullable_to_non_nullable
                        as String?,
            codeType:
                freezed == codeType
                    ? _value.codeType
                    : codeType // ignore: cast_nullable_to_non_nullable
                        as String?,
            isGeneric:
                null == isGeneric
                    ? _value.isGeneric
                    : isGeneric // ignore: cast_nullable_to_non_nullable
                        as bool,
            symptoms:
                freezed == symptoms
                    ? _value.symptoms
                    : symptoms // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            commonCauses:
                freezed == commonCauses
                    ? _value.commonCauses
                    : commonCauses // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            diagnosticSteps:
                freezed == diagnosticSteps
                    ? _value.diagnosticSteps
                    : diagnosticSteps // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            repairSuggestions:
                freezed == repairSuggestions
                    ? _value.repairSuggestions
                    : repairSuggestions // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            affectedComponents:
                freezed == affectedComponents
                    ? _value.affectedComponents
                    : affectedComponents // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            severity:
                freezed == severity
                    ? _value.severity
                    : severity // ignore: cast_nullable_to_non_nullable
                        as String?,
            driveSafety:
                null == driveSafety
                    ? _value.driveSafety
                    : driveSafety // ignore: cast_nullable_to_non_nullable
                        as bool,
            immediateActionRequired:
                null == immediateActionRequired
                    ? _value.immediateActionRequired
                    : immediateActionRequired // ignore: cast_nullable_to_non_nullable
                        as bool,
            relatedCodes:
                freezed == relatedCodes
                    ? _value.relatedCodes
                    : relatedCodes // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            typicalCostRange:
                freezed == typicalCostRange
                    ? _value.typicalCostRange
                    : typicalCostRange // ignore: cast_nullable_to_non_nullable
                        as String?,
            occurrenceFrequency:
                freezed == occurrenceFrequency
                    ? _value.occurrenceFrequency
                    : occurrenceFrequency // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ObdErrorCodeImplCopyWith<$Res>
    implements $ObdErrorCodeCopyWith<$Res> {
  factory _$$ObdErrorCodeImplCopyWith(
    _$ObdErrorCodeImpl value,
    $Res Function(_$ObdErrorCodeImpl) then,
  ) = __$$ObdErrorCodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    String? description,
    String? descriptionDe,
    String? descriptionEn,
    @JsonKey(name: 'code_type') String? codeType,
    @JsonKey(name: 'is_generic') bool isGeneric,
    List<String>? symptoms,
    @JsonKey(name: 'common_causes') List<String>? commonCauses,
    @JsonKey(name: 'diagnostic_steps') List<String>? diagnosticSteps,
    @JsonKey(name: 'repair_suggestions') List<String>? repairSuggestions,
    @JsonKey(name: 'affected_components') List<String>? affectedComponents,
    String? severity,
    @JsonKey(name: 'drive_safety') bool driveSafety,
    @JsonKey(name: 'immediate_action_required') bool immediateActionRequired,
    @JsonKey(name: 'related_codes') List<String>? relatedCodes,
    @JsonKey(name: 'typical_cost_range_eur') String? typicalCostRange,
    @JsonKey(name: 'occurrence_frequency') String? occurrenceFrequency,
  });
}

/// @nodoc
class __$$ObdErrorCodeImplCopyWithImpl<$Res>
    extends _$ObdErrorCodeCopyWithImpl<$Res, _$ObdErrorCodeImpl>
    implements _$$ObdErrorCodeImplCopyWith<$Res> {
  __$$ObdErrorCodeImplCopyWithImpl(
    _$ObdErrorCodeImpl _value,
    $Res Function(_$ObdErrorCodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ObdErrorCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? description = freezed,
    Object? descriptionDe = freezed,
    Object? descriptionEn = freezed,
    Object? codeType = freezed,
    Object? isGeneric = null,
    Object? symptoms = freezed,
    Object? commonCauses = freezed,
    Object? diagnosticSteps = freezed,
    Object? repairSuggestions = freezed,
    Object? affectedComponents = freezed,
    Object? severity = freezed,
    Object? driveSafety = null,
    Object? immediateActionRequired = null,
    Object? relatedCodes = freezed,
    Object? typicalCostRange = freezed,
    Object? occurrenceFrequency = freezed,
  }) {
    return _then(
      _$ObdErrorCodeImpl(
        code:
            null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        descriptionDe:
            freezed == descriptionDe
                ? _value.descriptionDe
                : descriptionDe // ignore: cast_nullable_to_non_nullable
                    as String?,
        descriptionEn:
            freezed == descriptionEn
                ? _value.descriptionEn
                : descriptionEn // ignore: cast_nullable_to_non_nullable
                    as String?,
        codeType:
            freezed == codeType
                ? _value.codeType
                : codeType // ignore: cast_nullable_to_non_nullable
                    as String?,
        isGeneric:
            null == isGeneric
                ? _value.isGeneric
                : isGeneric // ignore: cast_nullable_to_non_nullable
                    as bool,
        symptoms:
            freezed == symptoms
                ? _value._symptoms
                : symptoms // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        commonCauses:
            freezed == commonCauses
                ? _value._commonCauses
                : commonCauses // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        diagnosticSteps:
            freezed == diagnosticSteps
                ? _value._diagnosticSteps
                : diagnosticSteps // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        repairSuggestions:
            freezed == repairSuggestions
                ? _value._repairSuggestions
                : repairSuggestions // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        affectedComponents:
            freezed == affectedComponents
                ? _value._affectedComponents
                : affectedComponents // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        severity:
            freezed == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                    as String?,
        driveSafety:
            null == driveSafety
                ? _value.driveSafety
                : driveSafety // ignore: cast_nullable_to_non_nullable
                    as bool,
        immediateActionRequired:
            null == immediateActionRequired
                ? _value.immediateActionRequired
                : immediateActionRequired // ignore: cast_nullable_to_non_nullable
                    as bool,
        relatedCodes:
            freezed == relatedCodes
                ? _value._relatedCodes
                : relatedCodes // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        typicalCostRange:
            freezed == typicalCostRange
                ? _value.typicalCostRange
                : typicalCostRange // ignore: cast_nullable_to_non_nullable
                    as String?,
        occurrenceFrequency:
            freezed == occurrenceFrequency
                ? _value.occurrenceFrequency
                : occurrenceFrequency // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ObdErrorCodeImpl implements _ObdErrorCode {
  const _$ObdErrorCodeImpl({
    required this.code,
    this.description,
    this.descriptionDe,
    this.descriptionEn,
    @JsonKey(name: 'code_type') this.codeType,
    @JsonKey(name: 'is_generic') this.isGeneric = true,
    final List<String>? symptoms,
    @JsonKey(name: 'common_causes') final List<String>? commonCauses,
    @JsonKey(name: 'diagnostic_steps') final List<String>? diagnosticSteps,
    @JsonKey(name: 'repair_suggestions') final List<String>? repairSuggestions,
    @JsonKey(name: 'affected_components')
    final List<String>? affectedComponents,
    this.severity,
    @JsonKey(name: 'drive_safety') this.driveSafety = true,
    @JsonKey(name: 'immediate_action_required')
    this.immediateActionRequired = false,
    @JsonKey(name: 'related_codes') final List<String>? relatedCodes,
    @JsonKey(name: 'typical_cost_range_eur') this.typicalCostRange,
    @JsonKey(name: 'occurrence_frequency') this.occurrenceFrequency,
  }) : _symptoms = symptoms,
       _commonCauses = commonCauses,
       _diagnosticSteps = diagnosticSteps,
       _repairSuggestions = repairSuggestions,
       _affectedComponents = affectedComponents,
       _relatedCodes = relatedCodes;

  factory _$ObdErrorCodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ObdErrorCodeImplFromJson(json);

  @override
  final String code;
  @override
  final String? description;
  @override
  final String? descriptionDe;
  @override
  final String? descriptionEn;
  @override
  @JsonKey(name: 'code_type')
  final String? codeType;
  @override
  @JsonKey(name: 'is_generic')
  final bool isGeneric;
  final List<String>? _symptoms;
  @override
  List<String>? get symptoms {
    final value = _symptoms;
    if (value == null) return null;
    if (_symptoms is EqualUnmodifiableListView) return _symptoms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _commonCauses;
  @override
  @JsonKey(name: 'common_causes')
  List<String>? get commonCauses {
    final value = _commonCauses;
    if (value == null) return null;
    if (_commonCauses is EqualUnmodifiableListView) return _commonCauses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _diagnosticSteps;
  @override
  @JsonKey(name: 'diagnostic_steps')
  List<String>? get diagnosticSteps {
    final value = _diagnosticSteps;
    if (value == null) return null;
    if (_diagnosticSteps is EqualUnmodifiableListView) return _diagnosticSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _repairSuggestions;
  @override
  @JsonKey(name: 'repair_suggestions')
  List<String>? get repairSuggestions {
    final value = _repairSuggestions;
    if (value == null) return null;
    if (_repairSuggestions is EqualUnmodifiableListView)
      return _repairSuggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _affectedComponents;
  @override
  @JsonKey(name: 'affected_components')
  List<String>? get affectedComponents {
    final value = _affectedComponents;
    if (value == null) return null;
    if (_affectedComponents is EqualUnmodifiableListView)
      return _affectedComponents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? severity;
  // 'low', 'medium', 'high', 'critical'
  @override
  @JsonKey(name: 'drive_safety')
  final bool driveSafety;
  @override
  @JsonKey(name: 'immediate_action_required')
  final bool immediateActionRequired;
  final List<String>? _relatedCodes;
  @override
  @JsonKey(name: 'related_codes')
  List<String>? get relatedCodes {
    final value = _relatedCodes;
    if (value == null) return null;
    if (_relatedCodes is EqualUnmodifiableListView) return _relatedCodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'typical_cost_range_eur')
  final String? typicalCostRange;
  @override
  @JsonKey(name: 'occurrence_frequency')
  final String? occurrenceFrequency;

  @override
  String toString() {
    return 'ObdErrorCode(code: $code, description: $description, descriptionDe: $descriptionDe, descriptionEn: $descriptionEn, codeType: $codeType, isGeneric: $isGeneric, symptoms: $symptoms, commonCauses: $commonCauses, diagnosticSteps: $diagnosticSteps, repairSuggestions: $repairSuggestions, affectedComponents: $affectedComponents, severity: $severity, driveSafety: $driveSafety, immediateActionRequired: $immediateActionRequired, relatedCodes: $relatedCodes, typicalCostRange: $typicalCostRange, occurrenceFrequency: $occurrenceFrequency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ObdErrorCodeImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.descriptionDe, descriptionDe) ||
                other.descriptionDe == descriptionDe) &&
            (identical(other.descriptionEn, descriptionEn) ||
                other.descriptionEn == descriptionEn) &&
            (identical(other.codeType, codeType) ||
                other.codeType == codeType) &&
            (identical(other.isGeneric, isGeneric) ||
                other.isGeneric == isGeneric) &&
            const DeepCollectionEquality().equals(other._symptoms, _symptoms) &&
            const DeepCollectionEquality().equals(
              other._commonCauses,
              _commonCauses,
            ) &&
            const DeepCollectionEquality().equals(
              other._diagnosticSteps,
              _diagnosticSteps,
            ) &&
            const DeepCollectionEquality().equals(
              other._repairSuggestions,
              _repairSuggestions,
            ) &&
            const DeepCollectionEquality().equals(
              other._affectedComponents,
              _affectedComponents,
            ) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.driveSafety, driveSafety) ||
                other.driveSafety == driveSafety) &&
            (identical(
                  other.immediateActionRequired,
                  immediateActionRequired,
                ) ||
                other.immediateActionRequired == immediateActionRequired) &&
            const DeepCollectionEquality().equals(
              other._relatedCodes,
              _relatedCodes,
            ) &&
            (identical(other.typicalCostRange, typicalCostRange) ||
                other.typicalCostRange == typicalCostRange) &&
            (identical(other.occurrenceFrequency, occurrenceFrequency) ||
                other.occurrenceFrequency == occurrenceFrequency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    description,
    descriptionDe,
    descriptionEn,
    codeType,
    isGeneric,
    const DeepCollectionEquality().hash(_symptoms),
    const DeepCollectionEquality().hash(_commonCauses),
    const DeepCollectionEquality().hash(_diagnosticSteps),
    const DeepCollectionEquality().hash(_repairSuggestions),
    const DeepCollectionEquality().hash(_affectedComponents),
    severity,
    driveSafety,
    immediateActionRequired,
    const DeepCollectionEquality().hash(_relatedCodes),
    typicalCostRange,
    occurrenceFrequency,
  );

  /// Create a copy of ObdErrorCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ObdErrorCodeImplCopyWith<_$ObdErrorCodeImpl> get copyWith =>
      __$$ObdErrorCodeImplCopyWithImpl<_$ObdErrorCodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ObdErrorCodeImplToJson(this);
  }
}

abstract class _ObdErrorCode implements ObdErrorCode {
  const factory _ObdErrorCode({
    required final String code,
    final String? description,
    final String? descriptionDe,
    final String? descriptionEn,
    @JsonKey(name: 'code_type') final String? codeType,
    @JsonKey(name: 'is_generic') final bool isGeneric,
    final List<String>? symptoms,
    @JsonKey(name: 'common_causes') final List<String>? commonCauses,
    @JsonKey(name: 'diagnostic_steps') final List<String>? diagnosticSteps,
    @JsonKey(name: 'repair_suggestions') final List<String>? repairSuggestions,
    @JsonKey(name: 'affected_components')
    final List<String>? affectedComponents,
    final String? severity,
    @JsonKey(name: 'drive_safety') final bool driveSafety,
    @JsonKey(name: 'immediate_action_required')
    final bool immediateActionRequired,
    @JsonKey(name: 'related_codes') final List<String>? relatedCodes,
    @JsonKey(name: 'typical_cost_range_eur') final String? typicalCostRange,
    @JsonKey(name: 'occurrence_frequency') final String? occurrenceFrequency,
  }) = _$ObdErrorCodeImpl;

  factory _ObdErrorCode.fromJson(Map<String, dynamic> json) =
      _$ObdErrorCodeImpl.fromJson;

  @override
  String get code;
  @override
  String? get description;
  @override
  String? get descriptionDe;
  @override
  String? get descriptionEn;
  @override
  @JsonKey(name: 'code_type')
  String? get codeType;
  @override
  @JsonKey(name: 'is_generic')
  bool get isGeneric;
  @override
  List<String>? get symptoms;
  @override
  @JsonKey(name: 'common_causes')
  List<String>? get commonCauses;
  @override
  @JsonKey(name: 'diagnostic_steps')
  List<String>? get diagnosticSteps;
  @override
  @JsonKey(name: 'repair_suggestions')
  List<String>? get repairSuggestions;
  @override
  @JsonKey(name: 'affected_components')
  List<String>? get affectedComponents;
  @override
  String? get severity; // 'low', 'medium', 'high', 'critical'
  @override
  @JsonKey(name: 'drive_safety')
  bool get driveSafety;
  @override
  @JsonKey(name: 'immediate_action_required')
  bool get immediateActionRequired;
  @override
  @JsonKey(name: 'related_codes')
  List<String>? get relatedCodes;
  @override
  @JsonKey(name: 'typical_cost_range_eur')
  String? get typicalCostRange;
  @override
  @JsonKey(name: 'occurrence_frequency')
  String? get occurrenceFrequency;

  /// Create a copy of ObdErrorCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ObdErrorCodeImplCopyWith<_$ObdErrorCodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
