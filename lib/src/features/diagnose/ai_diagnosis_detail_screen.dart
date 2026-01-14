import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../models/ai_diagnosis_models.dart';
import '../../services/ai_diagnosis_service.dart';
import '../../i18n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen 2: Fehlerdetails + Ursachen-Liste
class AiDiagnosisDetailScreen extends StatefulWidget {
  final RawObdCode code;
  final ObdErrorCode? description;
  final bool isDemo;
  final bool simulateError;

  const AiDiagnosisDetailScreen({
    super.key,
    required this.code,
    this.description,
    this.isDemo = false,
    this.simulateError = false,
  });

  @override
  State<AiDiagnosisDetailScreen> createState() => _AiDiagnosisDetailScreenState();
}

class _AiDiagnosisDetailScreenState extends State<AiDiagnosisDetailScreen> {
  final _diagnosisService = AiDiagnosisService();
  bool _isAnalyzing = true;
  AiDiagnosis? _diagnosis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeCode();
  }

  Future<void> _analyzeCode() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      // Demo-Fehler simulieren (exakt wie echter Fehler)
      if (widget.simulateError) {
        await Future.delayed(const Duration(seconds: 2)); // Simuliere Analyse
        throw Exception('Die KI-Analyse ist momentan nicht verfügbar. Bitte versuche es später erneut.');
      }

      // Im Demo-Modus: Keine User-Prüfung, immer Demo-Daten
      if (widget.isDemo) {
        final diagnosis = await _diagnosisService.analyzeSingleCodeDemo(
          widget.code.code,
          widget.description,
        );

        if (!mounted) return;

        setState(() {
          _diagnosis = diagnosis;
          _isAnalyzing = false;
        });
        return;
      }

      // Production: Prüfe Credits/Pro Status
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Bitte melde dich an');
      }

      // Hole echte KI-Analyse (Edge Function)
      final diagnosis = await _diagnosisService.analyzeSingleCode(
        widget.code.code,
        widget.description,
      );

      if (!mounted) return;

      setState(() {
        _diagnosis = diagnosis;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  void _selectCause(PossibleCause cause) {
    // Navigiere zu Screen 3 (Ursache-Details)
    context.push('/diagnose/ai-cause-detail', extra: {
      'code': widget.code,
      'cause': cause,
    });
  }

  @override
  Widget build(BuildContext context) {
    final codeColor = _getCodeColor(widget.code.code);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'KI-Diagnose',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isAnalyzing
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildDiagnosisView(codeColor),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(
                  opacity: 0.5 + (value * 0.5),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB129).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      size: 50,
                      color: Color(0xFFFFB129),
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted && _isAnalyzing) {
                setState(() {}); // Restart animation
              }
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'KI analysiert Fehlercode...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dies kann einige Sekunden dauern',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE53935).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'KI-Analyse nicht verfügbar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151C23),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Text(
                    _error?.replaceAll('Exception: ', '') ?? 'Die KI-Analyse ist momentan nicht verfügbar.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB129).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFB129).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFFB129),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Wir werden den Fehler schnellstmöglich beheben.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Zurück'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _analyzeCode,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB129),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisView(Color codeColor) {
    if (_diagnosis == null) {
      return const Center(child: Text('Keine Diagnosedaten'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Fehlercode + Beschreibung
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: codeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: codeColor.withOpacity(0.5), width: 2),
                  ),
                  child: Text(
                    widget.code.code,
                    style: TextStyle(
                      color: codeColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Kurzbeschreibung
                Text(
                  _diagnosis!.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Detaillierte Beschreibung
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Was bedeutet dieser Fehler?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C23),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    _diagnosis!.detailedDescription,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Mögliche Ursachen Header
                Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFFFFB129),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Mögliche Ursachen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_diagnosis!.possibleCauses.length} Ursachen gefunden',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Ursachen-Liste
                ...(_diagnosis!.possibleCauses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cause = entry.value;
                  return _buildCauseCard(cause, index + 1);
                })),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCauseCard(PossibleCause cause, int number) {
    final probabilityColor = _getProbabilityColor(cause.probability);
    final difficultyIcon = _getDifficultyIcon(cause.difficulty);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCause(cause),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151C23),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: probabilityColor.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Nummer
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: probabilityColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: probabilityColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Titel
                  Expanded(
                    child: Text(
                      cause.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  
                  // Pfeil
                  Icon(
                    Icons.arrow_forward_ios,
                    color: probabilityColor.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Beschreibung
              Text(
                cause.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Badges
              Row(
                children: [
                  // Wahrscheinlichkeit
                  if (cause.probability != null)
                    _buildBadge(
                      _getProbabilityLabel(cause.probability!),
                      probabilityColor,
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Schwierigkeit
                  if (cause.difficulty != null)
                    _buildBadge(
                      '$difficultyIcon ${_getDifficultyLabel(cause.difficulty!)}',
                      Colors.white54,
                    ),
                  
                  const Spacer(),
                  
                  // Kosten
                  Text(
                    '${cause.estimatedCost.minEur.toInt()}-${cause.estimatedCost.maxEur.toInt()}€',
                    style: const TextStyle(
                      color: Color(0xFFFFB129),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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

  Color _getProbabilityColor(String? probability) {
    switch (probability?.toLowerCase()) {
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

  String _getProbabilityLabel(String probability) {
    switch (probability.toLowerCase()) {
      case 'high':
        return 'Hoch';
      case 'medium':
        return 'Mittel';
      case 'low':
        return 'Niedrig';
      default:
        return probability;
    }
  }

  String _getDifficultyIcon(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return '⚡';
      case 'medium':
        return '🔧';
      case 'hard':
        return '🏭';
      default:
        return '🔧';
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'Einfach';
      case 'medium':
        return 'Mittel';
      case 'hard':
        return 'Schwierig';
      default:
        return difficulty;
    }
  }
}
