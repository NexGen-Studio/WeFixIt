import 'package:freezed_annotation/freezed_annotation.dart';
import 'obd_error_code.dart';

part 'obd_diagnosis_result.freezed.dart';
part 'obd_diagnosis_result.g.dart';

@freezed
class ObdDiagnosisResult with _$ObdDiagnosisResult {
  const factory ObdDiagnosisResult({
    required String code,
    String? title,
    String? description,
    String? detailedAnalysis,
    @Default([]) List<DiagnosisStep> diagnosticSteps,
    @Default([]) List<RepairStep> repairSteps,
    String? severity,
    @Default(true) bool driveSafety,
    @Default(false) bool immediateActionRequired,
    List<String>? requiredTools,
    String? estimatedCost,
    String? estimatedTime,
    @JsonKey(name: 'source_type') String? sourceType, // 'database', 'ai_generated'
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ObdDiagnosisResult;

  factory ObdDiagnosisResult.fromJson(Map<String, dynamic> json) =>
      _$ObdDiagnosisResultFromJson(json);
}

@freezed
class DiagnosisStep with _$DiagnosisStep {
  const factory DiagnosisStep({
    @Default(0) int stepNumber,
    String? title,
    String? description,
    List<String>? warnings,
  }) = _DiagnosisStep;

  factory DiagnosisStep.fromJson(Map<String, dynamic> json) =>
      _$DiagnosisStepFromJson(json);
}

@freezed
class RepairStep with _$RepairStep {
  const factory RepairStep({
    @Default(0) int stepNumber,
    String? title,
    String? description,
    String? difficulty, // 'easy', 'medium', 'hard', 'expert'
    List<String>? requiredTools,
    String? estimatedTime,
    List<String>? warnings,
  }) = _RepairStep;

  factory RepairStep.fromJson(Map<String, dynamic> json) =>
      _$RepairStepFromJson(json);
}
