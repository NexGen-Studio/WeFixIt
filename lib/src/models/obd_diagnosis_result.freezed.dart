// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'obd_diagnosis_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ObdDiagnosisResult _$ObdDiagnosisResultFromJson(Map<String, dynamic> json) {
  return _ObdDiagnosisResult.fromJson(json);
}

/// @nodoc
mixin _$ObdDiagnosisResult {
  String get code => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get detailedAnalysis => throw _privateConstructorUsedError;
  List<DiagnosisStep> get diagnosticSteps => throw _privateConstructorUsedError;
  List<RepairStep> get repairSteps => throw _privateConstructorUsedError;
  String? get severity => throw _privateConstructorUsedError;
  bool get driveSafety => throw _privateConstructorUsedError;
  bool get immediateActionRequired => throw _privateConstructorUsedError;
  List<String>? get requiredTools => throw _privateConstructorUsedError;
  String? get estimatedCost => throw _privateConstructorUsedError;
  String? get estimatedTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_type')
  String? get sourceType => throw _privateConstructorUsedError; // 'database', 'ai_generated'
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ObdDiagnosisResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ObdDiagnosisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ObdDiagnosisResultCopyWith<ObdDiagnosisResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObdDiagnosisResultCopyWith<$Res> {
  factory $ObdDiagnosisResultCopyWith(
    ObdDiagnosisResult value,
    $Res Function(ObdDiagnosisResult) then,
  ) = _$ObdDiagnosisResultCopyWithImpl<$Res, ObdDiagnosisResult>;
  @useResult
  $Res call({
    String code,
    String? title,
    String? description,
    String? detailedAnalysis,
    List<DiagnosisStep> diagnosticSteps,
    List<RepairStep> repairSteps,
    String? severity,
    bool driveSafety,
    bool immediateActionRequired,
    List<String>? requiredTools,
    String? estimatedCost,
    String? estimatedTime,
    @JsonKey(name: 'source_type') String? sourceType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$ObdDiagnosisResultCopyWithImpl<$Res, $Val extends ObdDiagnosisResult>
    implements $ObdDiagnosisResultCopyWith<$Res> {
  _$ObdDiagnosisResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ObdDiagnosisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? detailedAnalysis = freezed,
    Object? diagnosticSteps = null,
    Object? repairSteps = null,
    Object? severity = freezed,
    Object? driveSafety = null,
    Object? immediateActionRequired = null,
    Object? requiredTools = freezed,
    Object? estimatedCost = freezed,
    Object? estimatedTime = freezed,
    Object? sourceType = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            code:
                null == code
                    ? _value.code
                    : code // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                freezed == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String?,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            detailedAnalysis:
                freezed == detailedAnalysis
                    ? _value.detailedAnalysis
                    : detailedAnalysis // ignore: cast_nullable_to_non_nullable
                        as String?,
            diagnosticSteps:
                null == diagnosticSteps
                    ? _value.diagnosticSteps
                    : diagnosticSteps // ignore: cast_nullable_to_non_nullable
                        as List<DiagnosisStep>,
            repairSteps:
                null == repairSteps
                    ? _value.repairSteps
                    : repairSteps // ignore: cast_nullable_to_non_nullable
                        as List<RepairStep>,
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
            requiredTools:
                freezed == requiredTools
                    ? _value.requiredTools
                    : requiredTools // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            estimatedCost:
                freezed == estimatedCost
                    ? _value.estimatedCost
                    : estimatedCost // ignore: cast_nullable_to_non_nullable
                        as String?,
            estimatedTime:
                freezed == estimatedTime
                    ? _value.estimatedTime
                    : estimatedTime // ignore: cast_nullable_to_non_nullable
                        as String?,
            sourceType:
                freezed == sourceType
                    ? _value.sourceType
                    : sourceType // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ObdDiagnosisResultImplCopyWith<$Res>
    implements $ObdDiagnosisResultCopyWith<$Res> {
  factory _$$ObdDiagnosisResultImplCopyWith(
    _$ObdDiagnosisResultImpl value,
    $Res Function(_$ObdDiagnosisResultImpl) then,
  ) = __$$ObdDiagnosisResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    String? title,
    String? description,
    String? detailedAnalysis,
    List<DiagnosisStep> diagnosticSteps,
    List<RepairStep> repairSteps,
    String? severity,
    bool driveSafety,
    bool immediateActionRequired,
    List<String>? requiredTools,
    String? estimatedCost,
    String? estimatedTime,
    @JsonKey(name: 'source_type') String? sourceType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$ObdDiagnosisResultImplCopyWithImpl<$Res>
    extends _$ObdDiagnosisResultCopyWithImpl<$Res, _$ObdDiagnosisResultImpl>
    implements _$$ObdDiagnosisResultImplCopyWith<$Res> {
  __$$ObdDiagnosisResultImplCopyWithImpl(
    _$ObdDiagnosisResultImpl _value,
    $Res Function(_$ObdDiagnosisResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ObdDiagnosisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? detailedAnalysis = freezed,
    Object? diagnosticSteps = null,
    Object? repairSteps = null,
    Object? severity = freezed,
    Object? driveSafety = null,
    Object? immediateActionRequired = null,
    Object? requiredTools = freezed,
    Object? estimatedCost = freezed,
    Object? estimatedTime = freezed,
    Object? sourceType = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ObdDiagnosisResultImpl(
        code:
            null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String?,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        detailedAnalysis:
            freezed == detailedAnalysis
                ? _value.detailedAnalysis
                : detailedAnalysis // ignore: cast_nullable_to_non_nullable
                    as String?,
        diagnosticSteps:
            null == diagnosticSteps
                ? _value._diagnosticSteps
                : diagnosticSteps // ignore: cast_nullable_to_non_nullable
                    as List<DiagnosisStep>,
        repairSteps:
            null == repairSteps
                ? _value._repairSteps
                : repairSteps // ignore: cast_nullable_to_non_nullable
                    as List<RepairStep>,
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
        requiredTools:
            freezed == requiredTools
                ? _value._requiredTools
                : requiredTools // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        estimatedCost:
            freezed == estimatedCost
                ? _value.estimatedCost
                : estimatedCost // ignore: cast_nullable_to_non_nullable
                    as String?,
        estimatedTime:
            freezed == estimatedTime
                ? _value.estimatedTime
                : estimatedTime // ignore: cast_nullable_to_non_nullable
                    as String?,
        sourceType:
            freezed == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ObdDiagnosisResultImpl implements _ObdDiagnosisResult {
  const _$ObdDiagnosisResultImpl({
    required this.code,
    this.title,
    this.description,
    this.detailedAnalysis,
    final List<DiagnosisStep> diagnosticSteps = const [],
    final List<RepairStep> repairSteps = const [],
    this.severity,
    this.driveSafety = true,
    this.immediateActionRequired = false,
    final List<String>? requiredTools,
    this.estimatedCost,
    this.estimatedTime,
    @JsonKey(name: 'source_type') this.sourceType,
    @JsonKey(name: 'created_at') this.createdAt,
  }) : _diagnosticSteps = diagnosticSteps,
       _repairSteps = repairSteps,
       _requiredTools = requiredTools;

  factory _$ObdDiagnosisResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ObdDiagnosisResultImplFromJson(json);

  @override
  final String code;
  @override
  final String? title;
  @override
  final String? description;
  @override
  final String? detailedAnalysis;
  final List<DiagnosisStep> _diagnosticSteps;
  @override
  @JsonKey()
  List<DiagnosisStep> get diagnosticSteps {
    if (_diagnosticSteps is EqualUnmodifiableListView) return _diagnosticSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_diagnosticSteps);
  }

  final List<RepairStep> _repairSteps;
  @override
  @JsonKey()
  List<RepairStep> get repairSteps {
    if (_repairSteps is EqualUnmodifiableListView) return _repairSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_repairSteps);
  }

  @override
  final String? severity;
  @override
  @JsonKey()
  final bool driveSafety;
  @override
  @JsonKey()
  final bool immediateActionRequired;
  final List<String>? _requiredTools;
  @override
  List<String>? get requiredTools {
    final value = _requiredTools;
    if (value == null) return null;
    if (_requiredTools is EqualUnmodifiableListView) return _requiredTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? estimatedCost;
  @override
  final String? estimatedTime;
  @override
  @JsonKey(name: 'source_type')
  final String? sourceType;
  // 'database', 'ai_generated'
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ObdDiagnosisResult(code: $code, title: $title, description: $description, detailedAnalysis: $detailedAnalysis, diagnosticSteps: $diagnosticSteps, repairSteps: $repairSteps, severity: $severity, driveSafety: $driveSafety, immediateActionRequired: $immediateActionRequired, requiredTools: $requiredTools, estimatedCost: $estimatedCost, estimatedTime: $estimatedTime, sourceType: $sourceType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ObdDiagnosisResultImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.detailedAnalysis, detailedAnalysis) ||
                other.detailedAnalysis == detailedAnalysis) &&
            const DeepCollectionEquality().equals(
              other._diagnosticSteps,
              _diagnosticSteps,
            ) &&
            const DeepCollectionEquality().equals(
              other._repairSteps,
              _repairSteps,
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
              other._requiredTools,
              _requiredTools,
            ) &&
            (identical(other.estimatedCost, estimatedCost) ||
                other.estimatedCost == estimatedCost) &&
            (identical(other.estimatedTime, estimatedTime) ||
                other.estimatedTime == estimatedTime) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    title,
    description,
    detailedAnalysis,
    const DeepCollectionEquality().hash(_diagnosticSteps),
    const DeepCollectionEquality().hash(_repairSteps),
    severity,
    driveSafety,
    immediateActionRequired,
    const DeepCollectionEquality().hash(_requiredTools),
    estimatedCost,
    estimatedTime,
    sourceType,
    createdAt,
  );

  /// Create a copy of ObdDiagnosisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ObdDiagnosisResultImplCopyWith<_$ObdDiagnosisResultImpl> get copyWith =>
      __$$ObdDiagnosisResultImplCopyWithImpl<_$ObdDiagnosisResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ObdDiagnosisResultImplToJson(this);
  }
}

abstract class _ObdDiagnosisResult implements ObdDiagnosisResult {
  const factory _ObdDiagnosisResult({
    required final String code,
    final String? title,
    final String? description,
    final String? detailedAnalysis,
    final List<DiagnosisStep> diagnosticSteps,
    final List<RepairStep> repairSteps,
    final String? severity,
    final bool driveSafety,
    final bool immediateActionRequired,
    final List<String>? requiredTools,
    final String? estimatedCost,
    final String? estimatedTime,
    @JsonKey(name: 'source_type') final String? sourceType,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$ObdDiagnosisResultImpl;

  factory _ObdDiagnosisResult.fromJson(Map<String, dynamic> json) =
      _$ObdDiagnosisResultImpl.fromJson;

  @override
  String get code;
  @override
  String? get title;
  @override
  String? get description;
  @override
  String? get detailedAnalysis;
  @override
  List<DiagnosisStep> get diagnosticSteps;
  @override
  List<RepairStep> get repairSteps;
  @override
  String? get severity;
  @override
  bool get driveSafety;
  @override
  bool get immediateActionRequired;
  @override
  List<String>? get requiredTools;
  @override
  String? get estimatedCost;
  @override
  String? get estimatedTime;
  @override
  @JsonKey(name: 'source_type')
  String? get sourceType; // 'database', 'ai_generated'
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of ObdDiagnosisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ObdDiagnosisResultImplCopyWith<_$ObdDiagnosisResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiagnosisStep _$DiagnosisStepFromJson(Map<String, dynamic> json) {
  return _DiagnosisStep.fromJson(json);
}

/// @nodoc
mixin _$DiagnosisStep {
  int get stepNumber => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String>? get warnings => throw _privateConstructorUsedError;

  /// Serializes this DiagnosisStep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiagnosisStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiagnosisStepCopyWith<DiagnosisStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagnosisStepCopyWith<$Res> {
  factory $DiagnosisStepCopyWith(
    DiagnosisStep value,
    $Res Function(DiagnosisStep) then,
  ) = _$DiagnosisStepCopyWithImpl<$Res, DiagnosisStep>;
  @useResult
  $Res call({
    int stepNumber,
    String? title,
    String? description,
    List<String>? warnings,
  });
}

/// @nodoc
class _$DiagnosisStepCopyWithImpl<$Res, $Val extends DiagnosisStep>
    implements $DiagnosisStepCopyWith<$Res> {
  _$DiagnosisStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiagnosisStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepNumber = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? warnings = freezed,
  }) {
    return _then(
      _value.copyWith(
            stepNumber:
                null == stepNumber
                    ? _value.stepNumber
                    : stepNumber // ignore: cast_nullable_to_non_nullable
                        as int,
            title:
                freezed == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String?,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            warnings:
                freezed == warnings
                    ? _value.warnings
                    : warnings // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiagnosisStepImplCopyWith<$Res>
    implements $DiagnosisStepCopyWith<$Res> {
  factory _$$DiagnosisStepImplCopyWith(
    _$DiagnosisStepImpl value,
    $Res Function(_$DiagnosisStepImpl) then,
  ) = __$$DiagnosisStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int stepNumber,
    String? title,
    String? description,
    List<String>? warnings,
  });
}

/// @nodoc
class __$$DiagnosisStepImplCopyWithImpl<$Res>
    extends _$DiagnosisStepCopyWithImpl<$Res, _$DiagnosisStepImpl>
    implements _$$DiagnosisStepImplCopyWith<$Res> {
  __$$DiagnosisStepImplCopyWithImpl(
    _$DiagnosisStepImpl _value,
    $Res Function(_$DiagnosisStepImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiagnosisStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepNumber = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? warnings = freezed,
  }) {
    return _then(
      _$DiagnosisStepImpl(
        stepNumber:
            null == stepNumber
                ? _value.stepNumber
                : stepNumber // ignore: cast_nullable_to_non_nullable
                    as int,
        title:
            freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String?,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        warnings:
            freezed == warnings
                ? _value._warnings
                : warnings // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DiagnosisStepImpl implements _DiagnosisStep {
  const _$DiagnosisStepImpl({
    this.stepNumber = 0,
    this.title,
    this.description,
    final List<String>? warnings,
  }) : _warnings = warnings;

  factory _$DiagnosisStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiagnosisStepImplFromJson(json);

  @override
  @JsonKey()
  final int stepNumber;
  @override
  final String? title;
  @override
  final String? description;
  final List<String>? _warnings;
  @override
  List<String>? get warnings {
    final value = _warnings;
    if (value == null) return null;
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'DiagnosisStep(stepNumber: $stepNumber, title: $title, description: $description, warnings: $warnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagnosisStepImpl &&
            (identical(other.stepNumber, stepNumber) ||
                other.stepNumber == stepNumber) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    stepNumber,
    title,
    description,
    const DeepCollectionEquality().hash(_warnings),
  );

  /// Create a copy of DiagnosisStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagnosisStepImplCopyWith<_$DiagnosisStepImpl> get copyWith =>
      __$$DiagnosisStepImplCopyWithImpl<_$DiagnosisStepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiagnosisStepImplToJson(this);
  }
}

abstract class _DiagnosisStep implements DiagnosisStep {
  const factory _DiagnosisStep({
    final int stepNumber,
    final String? title,
    final String? description,
    final List<String>? warnings,
  }) = _$DiagnosisStepImpl;

  factory _DiagnosisStep.fromJson(Map<String, dynamic> json) =
      _$DiagnosisStepImpl.fromJson;

  @override
  int get stepNumber;
  @override
  String? get title;
  @override
  String? get description;
  @override
  List<String>? get warnings;

  /// Create a copy of DiagnosisStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiagnosisStepImplCopyWith<_$DiagnosisStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RepairStep _$RepairStepFromJson(Map<String, dynamic> json) {
  return _RepairStep.fromJson(json);
}

/// @nodoc
mixin _$RepairStep {
  int get stepNumber => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get difficulty =>
      throw _privateConstructorUsedError; // 'easy', 'medium', 'hard', 'expert'
  List<String>? get requiredTools => throw _privateConstructorUsedError;
  String? get estimatedTime => throw _privateConstructorUsedError;
  List<String>? get warnings => throw _privateConstructorUsedError;

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
    int stepNumber,
    String? title,
    String? description,
    String? difficulty,
    List<String>? requiredTools,
    String? estimatedTime,
    List<String>? warnings,
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
    Object? stepNumber = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? difficulty = freezed,
    Object? requiredTools = freezed,
    Object? estimatedTime = freezed,
    Object? warnings = freezed,
  }) {
    return _then(
      _value.copyWith(
            stepNumber:
                null == stepNumber
                    ? _value.stepNumber
                    : stepNumber // ignore: cast_nullable_to_non_nullable
                        as int,
            title:
                freezed == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String?,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            difficulty:
                freezed == difficulty
                    ? _value.difficulty
                    : difficulty // ignore: cast_nullable_to_non_nullable
                        as String?,
            requiredTools:
                freezed == requiredTools
                    ? _value.requiredTools
                    : requiredTools // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
            estimatedTime:
                freezed == estimatedTime
                    ? _value.estimatedTime
                    : estimatedTime // ignore: cast_nullable_to_non_nullable
                        as String?,
            warnings:
                freezed == warnings
                    ? _value.warnings
                    : warnings // ignore: cast_nullable_to_non_nullable
                        as List<String>?,
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
    int stepNumber,
    String? title,
    String? description,
    String? difficulty,
    List<String>? requiredTools,
    String? estimatedTime,
    List<String>? warnings,
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
    Object? stepNumber = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? difficulty = freezed,
    Object? requiredTools = freezed,
    Object? estimatedTime = freezed,
    Object? warnings = freezed,
  }) {
    return _then(
      _$RepairStepImpl(
        stepNumber:
            null == stepNumber
                ? _value.stepNumber
                : stepNumber // ignore: cast_nullable_to_non_nullable
                    as int,
        title:
            freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String?,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        difficulty:
            freezed == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                    as String?,
        requiredTools:
            freezed == requiredTools
                ? _value._requiredTools
                : requiredTools // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
        estimatedTime:
            freezed == estimatedTime
                ? _value.estimatedTime
                : estimatedTime // ignore: cast_nullable_to_non_nullable
                    as String?,
        warnings:
            freezed == warnings
                ? _value._warnings
                : warnings // ignore: cast_nullable_to_non_nullable
                    as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RepairStepImpl implements _RepairStep {
  const _$RepairStepImpl({
    this.stepNumber = 0,
    this.title,
    this.description,
    this.difficulty,
    final List<String>? requiredTools,
    this.estimatedTime,
    final List<String>? warnings,
  }) : _requiredTools = requiredTools,
       _warnings = warnings;

  factory _$RepairStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$RepairStepImplFromJson(json);

  @override
  @JsonKey()
  final int stepNumber;
  @override
  final String? title;
  @override
  final String? description;
  @override
  final String? difficulty;
  // 'easy', 'medium', 'hard', 'expert'
  final List<String>? _requiredTools;
  // 'easy', 'medium', 'hard', 'expert'
  @override
  List<String>? get requiredTools {
    final value = _requiredTools;
    if (value == null) return null;
    if (_requiredTools is EqualUnmodifiableListView) return _requiredTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? estimatedTime;
  final List<String>? _warnings;
  @override
  List<String>? get warnings {
    final value = _warnings;
    if (value == null) return null;
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'RepairStep(stepNumber: $stepNumber, title: $title, description: $description, difficulty: $difficulty, requiredTools: $requiredTools, estimatedTime: $estimatedTime, warnings: $warnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RepairStepImpl &&
            (identical(other.stepNumber, stepNumber) ||
                other.stepNumber == stepNumber) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            const DeepCollectionEquality().equals(
              other._requiredTools,
              _requiredTools,
            ) &&
            (identical(other.estimatedTime, estimatedTime) ||
                other.estimatedTime == estimatedTime) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    stepNumber,
    title,
    description,
    difficulty,
    const DeepCollectionEquality().hash(_requiredTools),
    estimatedTime,
    const DeepCollectionEquality().hash(_warnings),
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
    final int stepNumber,
    final String? title,
    final String? description,
    final String? difficulty,
    final List<String>? requiredTools,
    final String? estimatedTime,
    final List<String>? warnings,
  }) = _$RepairStepImpl;

  factory _RepairStep.fromJson(Map<String, dynamic> json) =
      _$RepairStepImpl.fromJson;

  @override
  int get stepNumber;
  @override
  String? get title;
  @override
  String? get description;
  @override
  String? get difficulty; // 'easy', 'medium', 'hard', 'expert'
  @override
  List<String>? get requiredTools;
  @override
  String? get estimatedTime;
  @override
  List<String>? get warnings;

  /// Create a copy of RepairStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RepairStepImplCopyWith<_$RepairStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
