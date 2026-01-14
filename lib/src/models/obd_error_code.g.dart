// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd_error_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ObdErrorCodeImpl _$$ObdErrorCodeImplFromJson(
  Map<String, dynamic> json,
) => _$ObdErrorCodeImpl(
  code: json['code'] as String,
  description: json['description'] as String?,
  descriptionDe: json['descriptionDe'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  codeType: json['code_type'] as String?,
  isGeneric: json['is_generic'] as bool? ?? true,
  symptoms:
      (json['symptoms'] as List<dynamic>?)?.map((e) => e as String).toList(),
  commonCauses:
      (json['common_causes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  diagnosticSteps:
      (json['diagnostic_steps'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  repairSuggestions:
      (json['repair_suggestions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  affectedComponents:
      (json['affected_components'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  severity: json['severity'] as String?,
  driveSafety: json['drive_safety'] as bool? ?? true,
  immediateActionRequired: json['immediate_action_required'] as bool? ?? false,
  relatedCodes:
      (json['related_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  typicalCostRange: json['typical_cost_range_eur'] as String?,
  occurrenceFrequency: json['occurrence_frequency'] as String?,
);

Map<String, dynamic> _$$ObdErrorCodeImplToJson(_$ObdErrorCodeImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'description': instance.description,
      'descriptionDe': instance.descriptionDe,
      'descriptionEn': instance.descriptionEn,
      'code_type': instance.codeType,
      'is_generic': instance.isGeneric,
      'symptoms': instance.symptoms,
      'common_causes': instance.commonCauses,
      'diagnostic_steps': instance.diagnosticSteps,
      'repair_suggestions': instance.repairSuggestions,
      'affected_components': instance.affectedComponents,
      'severity': instance.severity,
      'drive_safety': instance.driveSafety,
      'immediate_action_required': instance.immediateActionRequired,
      'related_codes': instance.relatedCodes,
      'typical_cost_range_eur': instance.typicalCostRange,
      'occurrence_frequency': instance.occurrenceFrequency,
    };
