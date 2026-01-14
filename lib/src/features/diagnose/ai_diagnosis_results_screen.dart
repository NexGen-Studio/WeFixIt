import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../models/obd_diagnosis_result.dart';
import '../../i18n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiDiagnosisResultsScreen extends StatefulWidget {
  final List<RawObdCode> errorCodes;

  const AiDiagnosisResultsScreen({
    super.key,
    required this.errorCodes,
  });

  @override
  State<AiDiagnosisResultsScreen> createState() => _AiDiagnosisResultsScreenState();
}

class _AiDiagnosisResultsScreenState extends State<AiDiagnosisResultsScreen> {
  bool _isAnalyzing = true;
  List<ObdDiagnosisResult> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeErrorCodes();
  }

  Future<void> _analyzeErrorCodes() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Call Edge Function
      final response = await supabase.functions.invoke(
        'analyze-obd-codes',
        body: {
          'errorCodes': widget.errorCodes.map((c) => c.toJson()).toList(),
          'language': 'de',
        },
      );

      if (response.data == null) {
        throw Exception('Keine Antwort vom Server');
      }

      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List;

      if (!mounted) return;

      setState(() {
        _results = results
            .map((r) => ObdDiagnosisResult.fromJson(r as Map<String, dynamic>))
            .toList();
        _isAnalyzing = false;
      });
    } catch (e) {
      print('❌ Analysis error: $e');
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.tr('diagnose.ai_results_title'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isAnalyzing
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildResultsView(),
    );
  }

  Widget _buildLoadingView() {
    final t = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Color(0xFFFFB129),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.errorCodes.length > 1
                ? t.tr('diagnose.analyzing_codes_plural').replaceAll('{count}', widget.errorCodes.length.toString())
                : t.tr('diagnose.analyzing_codes').replaceAll('{count}', widget.errorCodes.length.toString()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.tr('diagnose.ai_searching_db'),
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final t = AppLocalizations.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE53935),
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              t.tr('diagnose.analysis_error_title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? t.tr('diagnose.unknown_error'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _analyzeErrorCodes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB129),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(t.tr('diagnose.retry_button')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _DiagnosisCard(
          result: result,
          isExpanded: index == 0, // First card expanded by default
        );
      },
    );
  }
}

class _DiagnosisCard extends StatefulWidget {
  final ObdDiagnosisResult result;
  final bool isExpanded;

  const _DiagnosisCard({
    required this.result,
    this.isExpanded = false,
  });

  @override
  State<_DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<_DiagnosisCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE53935);
      case 'high':
        return const Color(0xFFF57C00);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'low':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final severityColor = _getSeverityColor(widget.result.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Code Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: severityColor),
                    ),
                    child: Text(
                      widget.result.code,
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.result.title ?? widget.result.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              widget.result.driveSafety == true
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber,
                              color: widget.result.driveSafety == true
                                  ? const Color(0xFF66BB6A)
                                  : const Color(0xFFF57C00),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.result.driveSafety == true
                                  ? t.tr('diagnose.drive_safety_ok')
                                  : t.tr('diagnose.drive_safety_warning'),
                              style: TextStyle(
                                color: widget.result.driveSafety == true
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFFF57C00),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand Icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detailed Analysis
                  if (widget.result.detailedAnalysis != null)
                    _buildSection(
                      icon: Icons.analytics,
                      title: t.tr('diagnose.section_detailed_analysis'),
                      child: Text(
                        widget.result.detailedAnalysis!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),

                  if (widget.result.detailedAnalysis != null)
                    const SizedBox(height: 20),

                  // Diagnostic Steps
                  _buildSection(
                    icon: Icons.build,
                    title: t.tr('diagnose.section_diagnostic_steps'),
                    child: Column(
                      children: widget.result.diagnosticSteps.map((step) {
                        return _buildStepCard(
                          stepNumber: step.stepNumber,
                          title: step.title,
                          description: step.description,
                          warnings: step.warnings,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Repair Steps
                  _buildSection(
                    icon: Icons.construction,
                    title: t.tr('diagnose.section_repair_steps'),
                    child: Column(
                      children: widget.result.repairSteps.map((step) {
                        return _buildRepairStepCard(
                          stepNumber: step.stepNumber,
                          title: step.title,
                          description: step.description,
                          difficulty: step.difficulty,
                          tools: step.requiredTools,
                          time: step.estimatedTime,
                          warnings: step.warnings,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cost & Time Estimate
                  Row(
                    children: [
                      if (widget.result.estimatedCost != null)
                        Expanded(
                          child: _buildInfoBox(
                            icon: Icons.euro,
                            label: t.tr('diagnose.estimated_cost'),
                            value: widget.result.estimatedCost!,
                            color: const Color(0xFF66BB6A),
                          ),
                        ),
                      if (widget.result.estimatedCost != null &&
                          widget.result.estimatedTime != null)
                        const SizedBox(width: 12),
                      if (widget.result.estimatedTime != null)
                        Expanded(
                          child: _buildInfoBox(
                            icon: Icons.access_time,
                            label: t.tr('diagnose.estimated_time'),
                            value: widget.result.estimatedTime!,
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Source Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.result.sourceType == 'database'
                          ? const Color(0xFF2196F3).withOpacity(0.1)
                          : const Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.result.sourceType == 'database'
                            ? const Color(0xFF2196F3).withOpacity(0.3)
                            : const Color(0xFF9C27B0).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.result.sourceType == 'database'
                              ? Icons.storage
                              : Icons.psychology,
                          size: 16,
                          color: widget.result.sourceType == 'database'
                              ? const Color(0xFF2196F3)
                              : const Color(0xFF9C27B0),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.result.sourceType == 'database'
                              ? AppLocalizations.of(context).tr('diagnose.source_database')
                              : AppLocalizations.of(context).tr('diagnose.source_ai_generated'),
                          style: TextStyle(
                            color: widget.result.sourceType == 'database'
                                ? const Color(0xFF2196F3)
                                : const Color(0xFF9C27B0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB129), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    String? title,
    String? description,
    List<String>? warnings,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB129),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? 'Schritt $stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (warnings != null && warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map((warning) => Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFF57C00).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFF57C00),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(
                            color: Color(0xFFF57C00),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildRepairStepCard({
    required int stepNumber,
    String? title,
    String? description,
    String? difficulty,
    List<String>? tools,
    String? time,
    List<String>? warnings,
  }) {
    Color difficultyColor;
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        difficultyColor = const Color(0xFF66BB6A);
        break;
      case 'medium':
        difficultyColor = const Color(0xFFFFA726);
        break;
      case 'hard':
        difficultyColor = const Color(0xFFF57C00);
        break;
      case 'expert':
        difficultyColor = const Color(0xFFE53935);
        break;
      default:
        difficultyColor = const Color(0xFF757575);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: difficultyColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: difficultyColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? 'Reparaturschritt $stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (difficulty != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    difficulty.toUpperCase(),
                    style: TextStyle(
                      color: difficultyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (tools != null && tools.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tools.map((tool) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tool,
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 11,
                      ),
                    ),
                  )).toList(),
            ),
          ],
          if (time != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (warnings != null && warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map((warning) => Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFE53935),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
