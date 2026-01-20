import 'package:freezed_annotation/freezed_annotation.dart';

part 'obd_error_code.freezed.dart';
part 'obd_error_code.g.dart';

@freezed
class ObdErrorCode with _$ObdErrorCode {
  const factory ObdErrorCode({
    required String code,
    @JsonKey(name: 'code_type') String? codeType,
    @JsonKey(name: 'title_de') String? titleDe,
    @JsonKey(name: 'title_en') String? titleEn,
    @JsonKey(name: 'description_de') String? descriptionDe,
    @JsonKey(name: 'description_en') String? descriptionEn,
    @JsonKey(name: 'is_generic') @Default(true) bool isGeneric,
    List<String>? symptoms,
    @JsonKey(name: 'common_causes') List<String>? commonCauses,
    @JsonKey(name: 'diagnostic_steps') List<String>? diagnosticSteps,
    @JsonKey(name: 'repair_suggestions') List<String>? repairSuggestions,
    @JsonKey(name: 'affected_components') List<String>? affectedComponents,
    String? severity,
    @JsonKey(name: 'drive_safety') @Default(true) bool driveSafety,
    @JsonKey(name: 'immediate_action_required') @Default(false) bool immediateActionRequired,
    @JsonKey(name: 'related_codes') List<String>? relatedCodes,
    @JsonKey(name: 'typical_cost_range_eur') String? typicalCostRange,
    @JsonKey(name: 'occurrence_frequency') String? occurrenceFrequency,
  }) = _ObdErrorCode;

  factory ObdErrorCode.fromJson(Map<String, dynamic> json) =>
      _$ObdErrorCodeFromJson(json);
}

/// Einfache Klasse für ausgelesene Codes vom OBD2-Adapter
class RawObdCode {
  final String code;
  final DateTime readAt;

  RawObdCode({
    required this.code,
    DateTime? readAt,
  }) : readAt = readAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'code': code,
        'read_at': readAt.toIso8601String(),
      };
}
