// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_diagnosis_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AiDiagnosis _$AiDiagnosisFromJson(Map<String, dynamic> json) {
  return _AiDiagnosis.fromJson(json);
}

/// @nodoc
mixin _$AiDiagnosis {
  String get code => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get detailedDescription => throw _privateConstructorUsedError;
  @JsonKey(name: 'possible_causes')
  List<PossibleCause> get possibleCauses => throw _privateConstructorUsedError;
  List<String>? get symptoms => throw _privateConstructorUsedError;
  @JsonKey(name: 'vehicle_specific_issues')
  List<String>? get vehicleSpecificIssues => throw _privateConstructorUsedError;
  String? get severity => throw _privateConstructorUsedError;
  @JsonKey(name: 'drive_safety')
  bool? get driveSafety => throw _privateConstructorUsedError;

  /// Serializes this AiDiagnosis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiDiagnosis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiDiagnosisCopyWith<AiDiagnosis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiDiagnosisCopyWith<$Res> {
  factory $AiDiagnosisCopyWith(
    AiDiagnosis value,
    $Res Function(AiDiagnosis) then,
  ) = _$AiDiagnosisCopyWithImpl<$Res, AiDiagnosis>;
  @useResult
  $Res call({
    String code,
    String description,
    String detailedDescription,
    @JsonKey(name: 'possible_causes') List<PossibleCause> possibleCauses,
    List<String>? symptoms,
    @JsonKey(name: 'vehicle_specific_issues')
    List<String>? vehicleSpecificIssues,
    String? severity,
    @JsonKey(name: 'drive_safety') bool? driveSafety,
  });
}

/// @nodoc
class _$AiDiagnosisCopyWithImpl<$Res, $Val extends AiDiagnosis>
    implements $AiDiagnosisCopyWith<$Res> {
  _$AiDiagnosisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiDiagnosis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? description = null,
    Object? detailedDescription = null,
    Object? possibleCauses = null,
    Object? symptoms = freezed,
    Object? vehicleSpecificIssues = freezed,
    Object? severity = freezed,
    Object? driveSafety = freezed,
  }) {
    return _then(
      _value.copyWith(
            code:
                null == code
                    ? _value.code
                    : code // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            detailedDescription:
                null == detailedDescription
                    ? _value.detailedDescription
                    : detailedDescription // ignore: cast_nullable_to_non_nullable
                        as String,
            possibleCauses:
                null == possibleCauses
                    ? _value.possibleCauses
                    : possibleCauses // ignore: cast_nullable_to_non_nullable
                        as List<PossibleCause>,
            symptoms:
                freezed == symptoms
                    ? _value.symptoms
                    : symptoms // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            vehicleSpecificIssues:
                freezed == vehicleSpecificIssues
                    ? _value.vehicleSpecificIssues
                    : vehicleSpecificIssues // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            severity:
                freezed == severity
                    ? _value.severity
                    : severity // ignore: cast_nullable_to_non_nullable
                        as String?,
            driveSafety:
                freezed == driveSafety
                    ? _value.driveSafety
                    : driveSafety // ignore: cast_nullable_to_non_nullable
                        as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiDiagnosisImplCopyWith<$Res>
    implements $AiDiagnosisCopyWith<$Res> {
  factory _$$AiDiagnosisImplCopyWith(
    _$AiDiagnosisImpl value,
    $Res Function(_$AiDiagnosisImpl) then,
  ) = __$$AiDiagnosisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    String description,
    String detailedDescription,
    @JsonKey(name: 'possible_causes') List<PossibleCause> possibleCauses,
    List<String>? symptoms,
    @JsonKey(name: 'vehicle_specific_issues')
    List<String>? vehicleSpecificIssues,
    String? severity,
    @JsonKey(name: 'drive_safety') bool? driveSafety,
  });
}

/// @nodoc
class __$$AiDiagnosisImplCopyWithImpl<$Res>
    extends _$AiDiagnosisCopyWithImpl<$Res, _$AiDiagnosisImpl>
    implements _$$AiDiagnosisImplCopyWith<$Res> {
  __$$AiDiagnosisImplCopyWithImpl(
    _$AiDiagnosisImpl _value,
    $Res Function(_$AiDiagnosisImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiDiagnosis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? description = null,
    Object? detailedDescription = null,
    Object? possibleCauses = null,
    Object? symptoms = freezed,
    Object? vehicleSpecificIssues = freezed,
    Object? severity = freezed,
    Object? driveSafety = freezed,
  }) {
    return _then(
      _$AiDiagnosisImpl(
        code:
            null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        detailedDescription:
            null == detailedDescription
                ? _value.detailedDescription
                : detailedDescription // ignore: cast_nullable_to_non_nullable
                    as String,
        possibleCauses:
            null == possibleCauses
                ? _value._possibleCauses
                : possibleCauses // ignore: cast_nullable_to_non_nullable
                    as List<PossibleCause>,
        symptoms:
            freezed == symptoms
                ? _value._symptoms
                : symptoms // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        vehicleSpecificIssues:
            freezed == vehicleSpecificIssues
                ? _value._vehicleSpecificIssues
                : vehicleSpecificIssues // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        severity:
            freezed == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                    as String?,
        driveSafety:
            freezed == driveSafety
                ? _value.driveSafety
                : driveSafety // ignore: cast_nullable_to_non_nullable
                    as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiDiagnosisImpl implements _AiDiagnosis {
  const _$AiDiagnosisImpl({
    required this.code,
    required this.description,
    required this.detailedDescription,
    @JsonKey(name: 'possible_causes')
    required final List<PossibleCause> possibleCauses,
    final List<String>? symptoms,
    @JsonKey(name: 'vehicle_specific_issues')
    final List<String>? vehicleSpecificIssues,
    this.severity,
    @JsonKey(name: 'drive_safety') this.driveSafety,
  }) : _possibleCauses = possibleCauses,
       _symptoms = symptoms,
       _vehicleSpecificIssues = vehicleSpecificIssues;

  factory _$AiDiagnosisImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiDiagnosisImplFromJson(json);

  @override
  final String code;
  @override
  final String description;
  @override
  final String detailedDescription;
  final List<PossibleCause> _possibleCauses;
  @override
  @JsonKey(name: 'possible_causes')
  List<PossibleCause> get possibleCauses {
    if (_possibleCauses is EqualUnmodifiableListView) return _possibleCauses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_possibleCauses);
  }

  final List<String>? _symptoms;
  @override
  List<String>? get symptoms {
    final value = _symptoms;
    if (value == null) return null;
    if (_symptoms is EqualUnmodifiableListView) return _symptoms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _vehicleSpecificIssues;
  @override
  @JsonKey(name: 'vehicle_specific_issues')
  List<String>? get vehicleSpecificIssues {
    final value = _vehicleSpecificIssues;
    if (value == null) return null;
    if (_vehicleSpecificIssues is EqualUnmodifiableListView)
      return _vehicleSpecificIssues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? severity;
  @override
  @JsonKey(name: 'drive_safety')
  final bool? driveSafety;

  @override
  String toString() {
    return 'AiDiagnosis(code: $code, description: $description, detailedDescription: $detailedDescription, possibleCauses: $possibleCauses, symptoms: $symptoms, vehicleSpecificIssues: $vehicleSpecificIssues, severity: $severity, driveSafety: $driveSafety)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiDiagnosisImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.detailedDescription, detailedDescription) ||
                other.detailedDescription == detailedDescription) &&
            const DeepCollectionEquality().equals(
              other._possibleCauses,
              _possibleCauses,
            ) &&
            const DeepCollectionEquality().equals(other._symptoms, _symptoms) &&
            const DeepCollectionEquality().equals(
              other._vehicleSpecificIssues,
              _vehicleSpecificIssues,
            ) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.driveSafety, driveSafety) ||
                other.driveSafety == driveSafety));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    description,
    detailedDescription,
    const DeepCollectionEquality().hash(_possibleCauses),
    const DeepCollectionEquality().hash(_symptoms),
    const DeepCollectionEquality().hash(_vehicleSpecificIssues),
    severity,
    driveSafety,
  );

  /// Create a copy of AiDiagnosis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiDiagnosisImplCopyWith<_$AiDiagnosisImpl> get copyWith =>
      __$$AiDiagnosisImplCopyWithImpl<_$AiDiagnosisImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiDiagnosisImplToJson(this);
  }
}

abstract class _AiDiagnosis implements AiDiagnosis {
  const factory _AiDiagnosis({
    required final String code,
    required final String description,
    required final String detailedDescription,
    @JsonKey(name: 'possible_causes')
    required final List<PossibleCause> possibleCauses,
    final List<String>? symptoms,
    @JsonKey(name: 'vehicle_specific_issues')
    final List<String>? vehicleSpecificIssues,
    final String? severity,
    @JsonKey(name: 'drive_safety') final bool? driveSafety,
  }) = _$AiDiagnosisImpl;

  factory _AiDiagnosis.fromJson(Map<String, dynamic> json) =
      _$AiDiagnosisImpl.fromJson;

  @override
  String get code;
  @override
  String get description;
  @override
  String get detailedDescription;
  @override
  @JsonKey(name: 'possible_causes')
  List<PossibleCause> get possibleCauses;
  @override
  List<String>? get symptoms;
  @override
  @JsonKey(name: 'vehicle_specific_issues')
  List<String>? get vehicleSpecificIssues;
  @override
  String? get severity;
  @override
  @JsonKey(name: 'drive_safety')
  bool? get driveSafety;

  /// Create a copy of AiDiagnosis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiDiagnosisImplCopyWith<_$AiDiagnosisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PossibleCause _$PossibleCauseFromJson(Map<String, dynamic> json) {
  return _PossibleCause.fromJson(json);
}

/// @nodoc
mixin _$PossibleCause {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get fullDescription => throw _privateConstructorUsedError;
  @JsonKey(name: 'repair_steps')
  List<RepairStep> get repairSteps => throw _privateConstructorUsedError;
  @JsonKey(name: 'estimated_cost')
  CostEstimate get estimatedCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'probability')
  String? get probability => throw _privateConstructorUsedError; // 'high', 'medium', 'low'
  @JsonKey(name: 'difficulty')
  String? get difficulty => throw _privateConstructorUsedError; // 'easy', 'medium', 'hard'
  String? get causeKey => throw _privateConstructorUsedError;

  /// Serializes this PossibleCause to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PossibleCause
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PossibleCauseCopyWith<PossibleCause> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PossibleCauseCopyWith<$Res> {
  factory $PossibleCauseCopyWith(
    PossibleCause value,
    $Res Function(PossibleCause) then,
  ) = _$PossibleCauseCopyWithImpl<$Res, PossibleCause>;
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    String fullDescription,
    @JsonKey(name: 'repair_steps') List<RepairStep> repairSteps,
    @JsonKey(name: 'estimated_cost') CostEstimate estimatedCost,
    @JsonKey(name: 'probability') String? probability,
    @JsonKey(name: 'difficulty') String? difficulty,
    String? causeKey,
  });

  $CostEstimateCopyWith<$Res> get estimatedCost;
}

/// @nodoc
class _$PossibleCauseCopyWithImpl<$Res, $Val extends PossibleCause>
    implements $PossibleCauseCopyWith<$Res> {
  _$PossibleCauseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PossibleCause
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? fullDescription = null,
    Object? repairSteps = null,
    Object? estimatedCost = null,
    Object? probability = freezed,
    Object? difficulty = freezed,
    Object? causeKey = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            fullDescription:
                null == fullDescription
                    ? _value.fullDescription
                    : fullDescription // ignore: cast_nullable_to_non_nullable
                        as String,
            repairSteps:
                null == repairSteps
                    ? _value.repairSteps
                    : repairSteps // ignore: cast_nullable_to_non_nullable
                        as List<RepairStep>,
            estimatedCost:
                null == estimatedCost
                    ? _value.estimatedCost
                    : estimatedCost // ignore: cast_nullable_to_non_nullable
                        as CostEstimate,
            probability:
                freezed == probability
                    ? _value.probability
                    : probability // ignore: cast_nullable_to_non_nullable
                        as String?,
            difficulty:
                freezed == difficulty
                    ? _value.difficulty
                    : difficulty // ignore: cast_nullable_to_non_nullable
                        as String?,
            causeKey:
                freezed == causeKey
                    ? _value.causeKey
                    : causeKey // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of PossibleCause
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CostEstimateCopyWith<$Res> get estimatedCost {
    return $CostEstimateCopyWith<$Res>(_value.estimatedCost, (value) {
      return _then(_value.copyWith(estimatedCost: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PossibleCauseImplCopyWith<$Res>
    implements $PossibleCauseCopyWith<$Res> {
  factory _$$PossibleCauseImplCopyWith(
    _$PossibleCauseImpl value,
    $Res Function(_$PossibleCauseImpl) then,
  ) = __$$PossibleCauseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    String fullDescription,
    @JsonKey(name: 'repair_steps') List<RepairStep> repairSteps,
    @JsonKey(name: 'estimated_cost') CostEstimate estimatedCost,
    @JsonKey(name: 'probability') String? probability,
    @JsonKey(name: 'difficulty') String? difficulty,
    String? causeKey,
  });

  @override
  $CostEstimateCopyWith<$Res> get estimatedCost;
}

/// @nodoc
class __$$PossibleCauseImplCopyWithImpl<$Res>
    extends _$PossibleCauseCopyWithImpl<$Res, _$PossibleCauseImpl>
    implements _$$PossibleCauseImplCopyWith<$Res> {
  __$$PossibleCauseImplCopyWithImpl(
    _$PossibleCauseImpl _value,
    $Res Function(_$PossibleCauseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PossibleCause
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? fullDescription = null,
    Object? repairSteps = null,
    Object? estimatedCost = null,
    Object? probability = freezed,
    Object? difficulty = freezed,
    Object? causeKey = freezed,
  }) {
    return _then(
      _$PossibleCauseImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        fullDescription:
            null == fullDescription
                ? _value.fullDescription
                : fullDescription // ignore: cast_nullable_to_non_nullable
                    as String,
        repairSteps:
            null == repairSteps
                ? _value._repairSteps
                : repairSteps // ignore: cast_nullable_to_non_nullable
                    as List<RepairStep>,
        estimatedCost:
            null == estimatedCost
                ? _value.estimatedCost
                : estimatedCost // ignore: cast_nullable_to_non_nullable
                    as CostEstimate,
        probability:
            freezed == probability
                ? _value.probability
                : probability // ignore: cast_nullable_to_non_nullable
                    as String?,
        difficulty:
            freezed == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                    as String?,
        causeKey:
            freezed == causeKey
                ? _value.causeKey
                : causeKey // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PossibleCauseImpl implements _PossibleCause {
  const _$PossibleCauseImpl({
    required this.id,
    required this.title,
    required this.description,
    required this.fullDescription,
    @JsonKey(name: 'repair_steps') required final List<RepairStep> repairSteps,
    @JsonKey(name: 'estimated_cost') required this.estimatedCost,
    @JsonKey(name: 'probability') this.probability,
    @JsonKey(name: 'difficulty') this.difficulty,
    this.causeKey,
  }) : _repairSteps = repairSteps;

  factory _$PossibleCauseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PossibleCauseImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String fullDescription;
  final List<RepairStep> _repairSteps;
  @override
  @JsonKey(name: 'repair_steps')
  List<RepairStep> get repairSteps {
    if (_repairSteps is EqualUnmodifiableListView) return _repairSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_repairSteps);
  }

  @override
  @JsonKey(name: 'estimated_cost')
  final CostEstimate estimatedCost;
  @override
  @JsonKey(name: 'probability')
  final String? probability;
  // 'high', 'medium', 'low'
  @override
  @JsonKey(name: 'difficulty')
  final String? difficulty;
  // 'easy', 'medium', 'hard'
  @override
  final String? causeKey;

  @override
  String toString() {
    return 'PossibleCause(id: $id, title: $title, description: $description, fullDescription: $fullDescription, repairSteps: $repairSteps, estimatedCost: $estimatedCost, probability: $probability, difficulty: $difficulty, causeKey: $causeKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PossibleCauseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.fullDescription, fullDescription) ||
                other.fullDescription == fullDescription) &&
            const DeepCollectionEquality().equals(
              other._repairSteps,
              _repairSteps,
            ) &&
            (identical(other.estimatedCost, estimatedCost) ||
                other.estimatedCost == estimatedCost) &&
            (identical(other.probability, probability) ||
                other.probability == probability) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.causeKey, causeKey) ||
                other.causeKey == causeKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    fullDescription,
    const DeepCollectionEquality().hash(_repairSteps),
    estimatedCost,
    probability,
    difficulty,
    causeKey,
  );

  /// Create a copy of PossibleCause
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PossibleCauseImplCopyWith<_$PossibleCauseImpl> get copyWith =>
      __$$PossibleCauseImplCopyWithImpl<_$PossibleCauseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PossibleCauseImplToJson(this);
  }
}

abstract class _PossibleCause implements PossibleCause {
  const factory _PossibleCause({
    required final String id,
    required final String title,
    required final String description,
    required final String fullDescription,
    @JsonKey(name: 'repair_steps') required final List<RepairStep> repairSteps,
    @JsonKey(name: 'estimated_cost') required final CostEstimate estimatedCost,
    @JsonKey(name: 'probability') final String? probability,
    @JsonKey(name: 'difficulty') final String? difficulty,
    final String? causeKey,
  }) = _$PossibleCauseImpl;

  factory _PossibleCause.fromJson(Map<String, dynamic> json) =
      _$PossibleCauseImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get fullDescription;
  @override
  @JsonKey(name: 'repair_steps')
  List<RepairStep> get repairSteps;
  @override
  @JsonKey(name: 'estimated_cost')
  CostEstimate get estimatedCost;
  @override
  @JsonKey(name: 'probability')
  String? get probability; // 'high', 'medium', 'low'
  @override
  @JsonKey(name: 'difficulty')
  String? get difficulty; // 'easy', 'medium', 'hard'
  @override
  String? get causeKey;

  /// Create a copy of PossibleCause
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PossibleCauseImplCopyWith<_$PossibleCauseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RepairStep _$RepairStepFromJson(Map<String, dynamic> json) {
  return _RepairStep.fromJson(json);
}

/// @nodoc
mixin _$RepairStep {
  int get step => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String>? get tools => throw _privateConstructorUsedError;
  String? get warning => throw _privateConstructorUsedError;

  /// Serializes this RepairStep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RepairStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RepairStepCopyWith<RepairStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RepairStepCopyWith<$Res> {
  factory $RepairStepCopyWith(
    RepairStep value,
    $Res Function(RepairStep) then,
  ) = _$RepairStepCopyWithImpl<$Res, RepairStep>;
  @useResult
  $Res call({
    int step,
    String title,
    String description,
    List<String>? tools,
    String? warning,
  });
}

/// @nodoc
class _$RepairStepCopyWithImpl<$Res, $Val extends RepairStep>
    implements $RepairStepCopyWith<$Res> {
  _$RepairStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RepairStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? title = null,
    Object? description = null,
    Object? tools = freezed,
    Object? warning = freezed,
  }) {
    return _then(
      _value.copyWith(
            step:
                null == step
                    ? _value.step
                    : step // ignore: cast_nullable_to_non_nullable
                        as int,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            tools:
                freezed == tools
                    ? _value.tools
                    : tools // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            warning:
                freezed == warning
                    ? _value.warning
                    : warning // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RepairStepImplCopyWith<$Res>
    implements $RepairStepCopyWith<$Res> {
  factory _$$RepairStepImplCopyWith(
    _$RepairStepImpl value,
    $Res Function(_$RepairStepImpl) then,
  ) = __$$RepairStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int step,
    String title,
    String description,
    List<String>? tools,
    String? warning,
  });
}

/// @nodoc
class __$$RepairStepImplCopyWithImpl<$Res>
    extends _$RepairStepCopyWithImpl<$Res, _$RepairStepImpl>
    implements _$$RepairStepImplCopyWith<$Res> {
  __$$RepairStepImplCopyWithImpl(
    _$RepairStepImpl _value,
    $Res Function(_$RepairStepImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RepairStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? title = null,
    Object? description = null,
    Object? tools = freezed,
    Object? warning = freezed,
  }) {
    return _then(
      _$RepairStepImpl(
        step:
            null == step
                ? _value.step
                : step // ignore: cast_nullable_to_non_nullable
                    as int,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        tools:
            freezed == tools
                ? _value._tools
                : tools // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        warning:
            freezed == warning
                ? _value.warning
                : warning // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RepairStepImpl implements _RepairStep {
  const _$RepairStepImpl({
    required this.step,
    required this.title,
    required this.description,
    final List<String>? tools,
    this.warning,
  }) : _tools = tools;

  factory _$RepairStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$RepairStepImplFromJson(json);

  @override
  final int step;
  @override
  final String title;
  @override
  final String description;
  final List<String>? _tools;
  @override
  List<String>? get tools {
    final value = _tools;
    if (value == null) return null;
    if (_tools is EqualUnmodifiableListView) return _tools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? warning;

  @override
  String toString() {
    return 'RepairStep(step: $step, title: $title, description: $description, tools: $tools, warning: $warning)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RepairStepImpl &&
            (identical(other.step, step) || other.step == step) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._tools, _tools) &&
            (identical(other.warning, warning) || other.warning == warning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    step,
    title,
    description,
    const DeepCollectionEquality().hash(_tools),
    warning,
  );

  /// Create a copy of RepairStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RepairStepImplCopyWith<_$RepairStepImpl> get copyWith =>
      __$$RepairStepImplCopyWithImpl<_$RepairStepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RepairStepImplToJson(this);
  }
}

abstract class _RepairStep implements RepairStep {
  const factory _RepairStep({
    required final int step,
    required final String title,
    required final String description,
    final List<String>? tools,
    final String? warning,
  }) = _$RepairStepImpl;

  factory _RepairStep.fromJson(Map<String, dynamic> json) =
      _$RepairStepImpl.fromJson;

  @override
  int get step;
  @override
  String get title;
  @override
  String get description;
  @override
  List<String>? get tools;
  @override
  String? get warning;

  /// Create a copy of RepairStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RepairStepImplCopyWith<_$RepairStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CostEstimate _$CostEstimateFromJson(Map<String, dynamic> json) {
  return _CostEstimate.fromJson(json);
}

/// @nodoc
mixin _$CostEstimate {
  @JsonKey(name: 'min_eur')
  double get minEur => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_eur')
  double get maxEur => throw _privateConstructorUsedError;
  @JsonKey(name: 'parts_cost')
  double? get partsCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'labor_hours')
  double? get laborHours => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this CostEstimate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CostEstimate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CostEstimateCopyWith<CostEstimate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CostEstimateCopyWith<$Res> {
  factory $CostEstimateCopyWith(
    CostEstimate value,
    $Res Function(CostEstimate) then,
  ) = _$CostEstimateCopyWithImpl<$Res, CostEstimate>;
  @useResult
  $Res call({
    @JsonKey(name: 'min_eur') double minEur,
    @JsonKey(name: 'max_eur') double maxEur,
    @JsonKey(name: 'parts_cost') double? partsCost,
    @JsonKey(name: 'labor_hours') double? laborHours,
    String? note,
  });
}

/// @nodoc
class _$CostEstimateCopyWithImpl<$Res, $Val extends CostEstimate>
    implements $CostEstimateCopyWith<$Res> {
  _$CostEstimateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CostEstimate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minEur = null,
    Object? maxEur = null,
    Object? partsCost = freezed,
    Object? laborHours = freezed,
    Object? note = freezed,
  }) {
    return _then(
      _value.copyWith(
            minEur:
                null == minEur
                    ? _value.minEur
                    : minEur // ignore: cast_nullable_to_non_nullable
                        as double,
            maxEur:
                null == maxEur
                    ? _value.maxEur
                    : maxEur // ignore: cast_nullable_to_non_nullable
                        as double,
            partsCost:
                freezed == partsCost
                    ? _value.partsCost
                    : partsCost // ignore: cast_nullable_to_non_nullable
                        as double?,
            laborHours:
                freezed == laborHours
                    ? _value.laborHours
                    : laborHours // ignore: cast_nullable_to_non_nullable
                        as double?,
            note:
                freezed == note
                    ? _value.note
                    : note // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CostEstimateImplCopyWith<$Res>
    implements $CostEstimateCopyWith<$Res> {
  factory _$$CostEstimateImplCopyWith(
    _$CostEstimateImpl value,
    $Res Function(_$CostEstimateImpl) then,
  ) = __$$CostEstimateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'min_eur') double minEur,
    @JsonKey(name: 'max_eur') double maxEur,
    @JsonKey(name: 'parts_cost') double? partsCost,
    @JsonKey(name: 'labor_hours') double? laborHours,
    String? note,
  });
}

/// @nodoc
class __$$CostEstimateImplCopyWithImpl<$Res>
    extends _$CostEstimateCopyWithImpl<$Res, _$CostEstimateImpl>
    implements _$$CostEstimateImplCopyWith<$Res> {
  __$$CostEstimateImplCopyWithImpl(
    _$CostEstimateImpl _value,
    $Res Function(_$CostEstimateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CostEstimate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minEur = null,
    Object? maxEur = null,
    Object? partsCost = freezed,
    Object? laborHours = freezed,
    Object? note = freezed,
  }) {
    return _then(
      _$CostEstimateImpl(
        minEur:
            null == minEur
                ? _value.minEur
                : minEur // ignore: cast_nullable_to_non_nullable
                    as double,
        maxEur:
            null == maxEur
                ? _value.maxEur
                : maxEur // ignore: cast_nullable_to_non_nullable
                    as double,
        partsCost:
            freezed == partsCost
                ? _value.partsCost
                : partsCost // ignore: cast_nullable_to_non_nullable
                    as double?,
        laborHours:
            freezed == laborHours
                ? _value.laborHours
                : laborHours // ignore: cast_nullable_to_non_nullable
                    as double?,
        note:
            freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CostEstimateImpl implements _CostEstimate {
  const _$CostEstimateImpl({
    @JsonKey(name: 'min_eur') required this.minEur,
    @JsonKey(name: 'max_eur') required this.maxEur,
    @JsonKey(name: 'parts_cost') this.partsCost,
    @JsonKey(name: 'labor_hours') this.laborHours,
    this.note,
  });

  factory _$CostEstimateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CostEstimateImplFromJson(json);

  @override
  @JsonKey(name: 'min_eur')
  final double minEur;
  @override
  @JsonKey(name: 'max_eur')
  final double maxEur;
  @override
  @JsonKey(name: 'parts_cost')
  final double? partsCost;
  @override
  @JsonKey(name: 'labor_hours')
  final double? laborHours;
  @override
  final String? note;

  @override
  String toString() {
    return 'CostEstimate(minEur: $minEur, maxEur: $maxEur, partsCost: $partsCost, laborHours: $laborHours, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CostEstimateImpl &&
            (identical(other.minEur, minEur) || other.minEur == minEur) &&
            (identical(other.maxEur, maxEur) || other.maxEur == maxEur) &&
            (identical(other.partsCost, partsCost) ||
                other.partsCost == partsCost) &&
            (identical(other.laborHours, laborHours) ||
                other.laborHours == laborHours) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, minEur, maxEur, partsCost, laborHours, note);

  /// Create a copy of CostEstimate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CostEstimateImplCopyWith<_$CostEstimateImpl> get copyWith =>
      __$$CostEstimateImplCopyWithImpl<_$CostEstimateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CostEstimateImplToJson(this);
  }
}

abstract class _CostEstimate implements CostEstimate {
  const factory _CostEstimate({
    @JsonKey(name: 'min_eur') required final double minEur,
    @JsonKey(name: 'max_eur') required final double maxEur,
    @JsonKey(name: 'parts_cost') final double? partsCost,
    @JsonKey(name: 'labor_hours') final double? laborHours,
    final String? note,
  }) = _$CostEstimateImpl;

  factory _CostEstimate.fromJson(Map<String, dynamic> json) =
      _$CostEstimateImpl.fromJson;

  @override
  @JsonKey(name: 'min_eur')
  double get minEur;
  @override
  @JsonKey(name: 'max_eur')
  double get maxEur;
  @override
  @JsonKey(name: 'parts_cost')
  double? get partsCost;
  @override
  @JsonKey(name: 'labor_hours')
  double? get laborHours;
  @override
  String? get note;

  /// Create a copy of CostEstimate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CostEstimateImplCopyWith<_$CostEstimateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
