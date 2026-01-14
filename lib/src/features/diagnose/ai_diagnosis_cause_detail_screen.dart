import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../models/ai_diagnosis_models.dart';

/// Screen 3: Ursache-Details + Schritt-für-Schritt Anleitung + Kosten
class AiDiagnosisCauseDetailScreen extends StatelessWidget {
  final RawObdCode code;
  final PossibleCause cause;

  const AiDiagnosisCauseDetailScreen({
    super.key,
    required this.code,
    required this.cause,
  });

  @override
  Widget build(BuildContext context) {
    final codeColor = _getCodeColor(code.code);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Reparaturanleitung',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Fehlercode + Ursache
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF151C23),
                border: Border(
                  bottom: BorderSide(color: codeColor.withOpacity(0.3)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fehlercode Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: codeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: codeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      code.code,
                      style: TextStyle(
                        color: codeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ursachen-Titel
                  Text(
                    cause.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vollständige Beschreibung
                  _buildSection(
                    icon: Icons.info_outline,
                    title: 'Beschreibung',
                    child: Text(
                      cause.fullDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Kostenvoranschlag
                  _buildSection(
                    icon: Icons.euro,
                    title: 'Geschätzte Kosten',
                    child: _buildCostEstimate(),
                  ),

                  const SizedBox(height: 24),

                  // Benötigte Werkzeuge (falls vorhanden)
                  if (_hasTools()) ...[
                    _buildSection(
                      icon: Icons.build,
                      title: 'Benötigte Werkzeuge',
                      child: _buildToolsList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reparaturanleitung
                  _buildSection(
                    icon: Icons.list_alt,
                    title: 'Schritt-für-Schritt Anleitung',
                    child: Column(
                      children: cause.repairSteps.map((step) {
                        return _buildRepairStep(step);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Warnung (falls vorhanden)
                  if (_hasWarnings())
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF57C00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF57C00).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Color(0xFFF57C00),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Wichtige Hinweise',
                                  style: TextStyle(
                                    color: Color(0xFFF57C00),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._buildWarnings(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
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
            Icon(
              icon,
              color: const Color(0xFFFFB129),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151C23),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildCostEstimate() {
    final cost = cause.estimatedCost;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gesamtkosten
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gesamtkosten:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${cost.minEur.toInt()} - ${cost.maxEur.toInt()} €',
              style: const TextStyle(
                color: Color(0xFFFFB129),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        
        if (cost.partsCost != null || cost.laborHours != null) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
        ],
        
        // Ersatzteile
        if (cost.partsCost != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ersatzteile:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '~${cost.partsCost!.toInt()} €',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        
        // Arbeitszeit
        if (cost.laborHours != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arbeitszeit:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Text(
                '~${cost.laborHours!.toStringAsFixed(1)} Std.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        
        // Hinweis
        if (cost.note != null) ...[
          const SizedBox(height: 12),
          Text(
            cost.note!,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToolsList() {
    final allTools = <String>{};
    
    for (var step in cause.repairSteps) {
      if (step.tools != null) {
        allTools.addAll(step.tools!);
      }
    }
    
    if (allTools.isEmpty) {
      return const Text(
        'Keine speziellen Werkzeuge erforderlich',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allTools.map((tool) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tool,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRepairStep(RepairStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Nummer
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB129).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFB129).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: const TextStyle(
                  color: Color(0xFFFFB129),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Step Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                
                // Werkzeuge für diesen Schritt
                if (step.tools != null && step.tools!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: step.tools!.map((tool) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F26),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          '🔧 $tool',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                // Warnung für diesen Schritt
                if (step.warning != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFF57C00),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step.warning!,
                          style: const TextStyle(
                            color: Color(0xFFF57C00),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasTools() {
    return cause.repairSteps.any((step) => step.tools != null && step.tools!.isNotEmpty);
  }

  bool _hasWarnings() {
    return cause.repairSteps.any((step) => step.warning != null);
  }

  List<Widget> _buildWarnings() {
    final warnings = cause.repairSteps
        .where((step) => step.warning != null)
        .map((step) => step.warning!)
        .toList();
    
    return warnings.map((warning) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          '• $warning',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF151C23),
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info
            Row(
              children: [
                Icon(
                  _getDifficultyIcon(),
                  color: const Color(0xFFFFB129),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Schwierigkeit: ${_getDifficultyLabel()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (cause.probability != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProbabilityColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getProbabilityColor().withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Wahrscheinlichkeit: ${_getProbabilityLabel()}',
                      style: TextStyle(
                        color: _getProbabilityColor(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Werkstatt finden oder als Wartungserinnerung speichern
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Werkstatt-Funktion folgt bald'),
                      backgroundColor: Color(0xFFFFB129),
                    ),
                  );
                },
                icon: const Icon(Icons.build_circle),
                label: const Text('Werkstatt finden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB129),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCodeColor(String code) {
    if (code.startsWith('P')) return const Color(0xFFE53935);
    if (code.startsWith('C')) return const Color(0xFFF57C00);
    if (code.startsWith('B')) return const Color(0xFF2196F3);
    if (code.startsWith('U')) return const Color(0xFF9C27B0);
    return const Color(0xFF757575);
  }

  IconData _getDifficultyIcon() {
    switch (cause.difficulty?.toLowerCase()) {
      case 'easy':
        return Icons.flash_on;
      case 'medium':
        return Icons.build;
      case 'hard':
        return Icons.factory;
      default:
        return Icons.build;
    }
  }

  String _getDifficultyLabel() {
    switch (cause.difficulty?.toLowerCase()) {
      case 'easy':
        return 'Einfach';
      case 'medium':
        return 'Mittel';
      case 'hard':
        return 'Schwierig';
      default:
        return 'Unbekannt';
    }
  }

  Color _getProbabilityColor() {
    switch (cause.probability?.toLowerCase()) {
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
        return const Color(0xFFF57C00);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return Colors.white54;
    }
  }

  String _getProbabilityLabel() {
    switch (cause.probability?.toLowerCase()) {
      case 'high':
        return 'Hoch';
      case 'medium':
        return 'Mittel';
      case 'low':
        return 'Niedrig';
      default:
        return 'Unbekannt';
    }
  }
}
