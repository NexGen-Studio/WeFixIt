// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_diagnosis_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiDiagnosisImpl _$$AiDiagnosisImplFromJson(Map<String, dynamic> json) =>
    _$AiDiagnosisImpl(
      code: json['code'] as String,
      description: json['description'] as String,
      detailedDescription: json['detailedDescription'] as String,
      possibleCauses:
          (json['possible_causes'] as List<dynamic>)
              .map((e) => PossibleCause.fromJson(e as Map<String, dynamic>))
              .toList(),
      severity: json['severity'] as String?,
      driveSafety: json['drive_safety'] as bool?,
    );

Map<String, dynamic> _$$AiDiagnosisImplToJson(_$AiDiagnosisImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'description': instance.description,
      'detailedDescription': instance.detailedDescription,
      'possible_causes': instance.possibleCauses,
      'severity': instance.severity,
      'drive_safety': instance.driveSafety,
    };

_$PossibleCauseImpl _$$PossibleCauseImplFromJson(Map<String, dynamic> json) =>
    _$PossibleCauseImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      fullDescription: json['fullDescription'] as String,
      repairSteps:
          (json['repair_steps'] as List<dynamic>)
              .map((e) => RepairStep.fromJson(e as Map<String, dynamic>))
              .toList(),
      estimatedCost: CostEstimate.fromJson(
        json['estimated_cost'] as Map<String, dynamic>,
      ),
      probability: json['probability'] as String?,
      difficulty: json['difficulty'] as String?,
    );

Map<String, dynamic> _$$PossibleCauseImplToJson(_$PossibleCauseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'fullDescription': instance.fullDescription,
      'repair_steps': instance.repairSteps,
      'estimated_cost': instance.estimatedCost,
      'probability': instance.probability,
      'difficulty': instance.difficulty,
    };

_$RepairStepImpl _$$RepairStepImplFromJson(Map<String, dynamic> json) =>
    _$RepairStepImpl(
      step: (json['step'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      tools:
          (json['tools'] as List<dynamic>?)?.map((e) => e as String).toList(),
      warning: json['warning'] as String?,
    );

Map<String, dynamic> _$$RepairStepImplToJson(_$RepairStepImpl instance) =>
    <String, dynamic>{
      'step': instance.step,
      'title': instance.title,
      'description': instance.description,
      'tools': instance.tools,
      'warning': instance.warning,
    };

_$CostEstimateImpl _$$CostEstimateImplFromJson(Map<String, dynamic> json) =>
    _$CostEstimateImpl(
      minEur: (json['min_eur'] as num).toDouble(),
      maxEur: (json['max_eur'] as num).toDouble(),
      partsCost: (json['parts_cost'] as num?)?.toDouble(),
      laborHours: (json['labor_hours'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$CostEstimateImplToJson(_$CostEstimateImpl instance) =>
    <String, dynamic>{
      'min_eur': instance.minEur,
      'max_eur': instance.maxEur,
      'parts_cost': instance.partsCost,
      'labor_hours': instance.laborHours,
      'note': instance.note,
    };
