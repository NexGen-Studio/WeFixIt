import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_diagnosis_models.freezed.dart';
part 'ai_diagnosis_models.g.dart';

/// Vollständige KI-Diagnose für einen Fehlercode
@freezed
class AiDiagnosis with _$AiDiagnosis {
  const factory AiDiagnosis({
    required String code,
    required String description,
    required String detailedDescription,
    @JsonKey(name: 'possible_causes') required List<PossibleCause> possibleCauses,
    String? severity,
    @JsonKey(name: 'drive_safety') bool? driveSafety,
  }) = _AiDiagnosis;

  factory AiDiagnosis.fromJson(Map<String, dynamic> json) =>
      _$AiDiagnosisFromJson(json);
}

/// Mögliche Ursache eines Fehlers
@freezed
class PossibleCause with _$PossibleCause {
  const factory PossibleCause({
    required String id,
    required String title,
    required String description,
    required String fullDescription,
    @JsonKey(name: 'repair_steps') required List<RepairStep> repairSteps,
    @JsonKey(name: 'estimated_cost') required CostEstimate estimatedCost,
    @JsonKey(name: 'probability') String? probability, // 'high', 'medium', 'low'
    @JsonKey(name: 'difficulty') String? difficulty, // 'easy', 'medium', 'hard'
  }) = _PossibleCause;

  factory PossibleCause.fromJson(Map<String, dynamic> json) =>
      _$PossibleCauseFromJson(json);
}

/// Reparatur-Schritt
@freezed
class RepairStep with _$RepairStep {
  const factory RepairStep({
    required int step,
    required String title,
    required String description,
    List<String>? tools,
    String? warning,
  }) = _RepairStep;

  factory RepairStep.fromJson(Map<String, dynamic> json) =>
      _$RepairStepFromJson(json);
}

/// Kostenvoranschlag
@freezed
class CostEstimate with _$CostEstimate {
  const factory CostEstimate({
    @JsonKey(name: 'min_eur') required double minEur,
    @JsonKey(name: 'max_eur') required double maxEur,
    @JsonKey(name: 'parts_cost') double? partsCost,
    @JsonKey(name: 'labor_hours') double? laborHours,
    String? note,
  }) = _CostEstimate;

  factory CostEstimate.fromJson(Map<String, dynamic> json) =>
      _$CostEstimateFromJson(json);
}
