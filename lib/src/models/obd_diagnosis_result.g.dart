// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd_diagnosis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ObdDiagnosisResultImpl _$$ObdDiagnosisResultImplFromJson(
  Map<String, dynamic> json,
) => _$ObdDiagnosisResultImpl(
  code: json['code'] as String,
  title: json['title'] as String?,
  description: json['description'] as String?,
  detailedAnalysis: json['detailedAnalysis'] as String?,
  diagnosticSteps:
      (json['diagnosticSteps'] as List<dynamic>?)
          ?.map((e) => DiagnosisStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  repairSteps:
      (json['repairSteps'] as List<dynamic>?)
          ?.map((e) => RepairStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  severity: json['severity'] as String?,
  driveSafety: json['driveSafety'] as bool? ?? true,
  immediateActionRequired: json['immediateActionRequired'] as bool? ?? false,
  requiredTools:
      (json['requiredTools'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  estimatedCost: json['estimatedCost'] as String?,
  estimatedTime: json['estimatedTime'] as String?,
  sourceType: json['source_type'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$ObdDiagnosisResultImplToJson(
  _$ObdDiagnosisResultImpl instance,
) => <String, dynamic>{
  'code': instance.code,
  'title': instance.title,
  'description': instance.description,
  'detailedAnalysis': instance.detailedAnalysis,
  'diagnosticSteps': instance.diagnosticSteps,
  'repairSteps': instance.repairSteps,
  'severity': instance.severity,
  'driveSafety': instance.driveSafety,
  'immediateActionRequired': instance.immediateActionRequired,
  'requiredTools': instance.requiredTools,
  'estimatedCost': instance.estimatedCost,
  'estimatedTime': instance.estimatedTime,
  'source_type': instance.sourceType,
  'created_at': instance.createdAt?.toIso8601String(),
};

_$DiagnosisStepImpl _$$DiagnosisStepImplFromJson(Map<String, dynamic> json) =>
    _$DiagnosisStepImpl(
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      description: json['description'] as String?,
      warnings:
          (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$$DiagnosisStepImplToJson(_$DiagnosisStepImpl instance) =>
    <String, dynamic>{
      'stepNumber': instance.stepNumber,
      'title': instance.title,
      'description': instance.description,
      'warnings': instance.warnings,
    };

_$RepairStepImpl _$$RepairStepImplFromJson(Map<String, dynamic> json) =>
    _$RepairStepImpl(
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      requiredTools:
          (json['requiredTools'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      estimatedTime: json['estimatedTime'] as String?,
      warnings:
          (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$$RepairStepImplToJson(_$RepairStepImpl instance) =>
    <String, dynamic>{
      'stepNumber': instance.stepNumber,
      'title': instance.title,
      'description': instance.description,
      'difficulty': instance.difficulty,
      'requiredTools': instance.requiredTools,
      'estimatedTime': instance.estimatedTime,
      'warnings': instance.warnings,
    };
