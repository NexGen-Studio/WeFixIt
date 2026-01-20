import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';
import '../../models/ai_diagnosis_models.dart';

/// Vollbild Schritt-für-Schritt Reparaturanleitung
/// Nutzt VORHANDENE DB-Felder: causes, diagnostic_steps, repair_steps, tools_required, etc.
class RepairGuideDetailScreen extends StatefulWidget {
  final String errorCode;
  final String causeKey;
  final PossibleCause? cause; // Optional: Kostendetails aus KI-Diagnose
  
  const RepairGuideDetailScreen({
    super.key,
    required this.errorCode,
    required this.causeKey,
    this.cause,
  });

  @override
  State<RepairGuideDetailScreen> createState() => _RepairGuideDetailScreenState();
}

class _RepairGuideDetailScreenState extends State<RepairGuideDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _repairGuide;
  final Set<int> _completedSteps = {};
  
  @override
  void initState() {
    super.initState();
    _loadRepairGuide();
  }
  
  Future<void> _loadRepairGuide() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      // Lade repair_guides_de + causes aus DB
      final result = await _supabase
        .from('automotive_knowledge')
        .select('title_de, causes, repair_guides_de')
        .eq('category', 'fehlercode')
        .ilike('topic', '%${widget.errorCode}%')
        .single();
      
      final repairGuideDe = result['repair_guides_de'] as Map<String, dynamic>?;
      final causes = (result['causes'] as List?)?.cast<String>() ?? [];
      
      // ✅ WICHTIG: Nutze widget.causeKey DIREKT (bereits korrekt berechnet im Service!)
      final causeKey = widget.causeKey;
      
      // Prüfe ob repair_guide für diese cause existiert
      if (repairGuideDe != null && repairGuideDe.containsKey(causeKey)) {
        final guide = repairGuideDe[causeKey] as Map<String, dynamic>;
        setState(() {
          _repairGuide = guide;
          _loading = false;
        });
      } else {
        // FALLBACK: Generiere Anleitung mit GPT und speichere in DB
        print('🤖 Keine Anleitung gefunden für key: $causeKey - generiere mit GPT...');
        
        // Finde causeTitle aus causes-Array durch Matching
        String causeTitle = 'Unbekannte Ursache';
        for (final cause in causes) {
          final testKey = cause.toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');
          if (testKey == causeKey) {
            causeTitle = cause;
            break;
          }
        }
        
        await _generateAndSaveRepairGuide(widget.errorCode, causeTitle, causeKey);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  
  /// Generiere Reparaturanleitung mit GPT und speichere in DB
  Future<void> _generateAndSaveRepairGuide(String errorCode, String causeTitle, String causeKey) async {
    try {
      // Rufe Edge Function auf um Anleitung zu generieren
      final response = await _supabase.functions.invoke(
        'fill-repair-guides',
        body: {
          'error_code': errorCode,
          'cause_title': causeTitle,
          'cause_key': causeKey,
          'generate_single': true, // Flag für einzelne Ursache
        },
      );
      
      if (response.data == null || response.data['success'] != true) {
        throw Exception('Anleitung konnte nicht generiert werden');
      }
      
      // Hole die generierte Anleitung
      final guide = response.data['repair_guide'] as Map<String, dynamic>;
      
      setState(() {
        _repairGuide = guide;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Anleitung konnte nicht generiert werden: $e';
        _loading = false;
      });
    }
  }
  
  void _toggleStep(int stepNumber) {
    setState(() {
      if (_completedSteps.contains(stepNumber)) {
        _completedSteps.remove(stepNumber);
      } else {
        _completedSteps.add(stepNumber);
      }
    });
  }
  
  Future<void> _markAsSolved() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151C23),
        title: const Text(
          'Problem behoben?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'War diese Reparaturanleitung hilfreich und hat dein Problem gelöst?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nein'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Ja, behoben!'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      // Speichere Feedback in DB
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          await _supabase.from('error_code_feedback').insert({
            'user_id': userId,
            'error_code': widget.errorCode,
            'cause_key': widget.causeKey,
            'was_helpful': true,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Super! Wir freuen uns, dass wir helfen konnten.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        
        // Zurück zur Übersicht
        context.go('/diagnose');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.errorCode,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadRepairGuide,
            tooltip: 'Neu laden',
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? _buildErrorView()
          : _buildGuideView(),
      bottomNavigationBar: _loading || _error != null
        ? null
        : _buildBottomBar(),
    );
  }
  
  Widget _buildErrorView() {
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
            const SizedBox(height: 16),
            Text(
              _error ?? 'Ein Fehler ist aufgetreten',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRepairGuide,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB129),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGuideView() {
    if (_repairGuide == null) return const SizedBox();
    
    final lang = Localizations.localeOf(context).languageCode;
    final steps = (_repairGuide!['steps'] as List<dynamic>?) ?? [];
    final totalSteps = steps.length;
    final completedCount = _completedSteps.length;
    final progressPercent = totalSteps > 0 ? (completedCount / totalSteps * 100).round() : 0;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Titel + Fortschritt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF151C23),
              border: Border(
                bottom: BorderSide(color: Colors.white12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ursachen-Titel
                Text(
                  _getLocalizedText('cause_title', lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Fortschrittsbalken
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fortschritt',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$completedCount/$totalSteps Schritte',
                          style: const TextStyle(
                            color: Color(0xFFFFB129),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalSteps > 0 ? completedCount / totalSteps : 0,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schwierigkeit + Zeit + Kosten
                _buildInfoBadges(),
                
                const SizedBox(height: 24),
                
                // Benötigte Werkzeuge
                if (_hasTools()) ...[
                  _buildSection(
                    icon: Icons.build,
                    title: 'Benötigte Werkzeuge',
                    child: _buildToolsList(lang),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Sicherheitshinweise
                if (_hasSafetyWarnings()) ...[
                  _buildSafetyWarnings(lang),
                  const SizedBox(height: 24),
                ],
                
                // Schritt-für-Schritt Anleitung
                _buildSection(
                  icon: Icons.list_alt,
                  title: 'Schritt-für-Schritt Anleitung',
                  child: Column(
                    children: steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value as Map<String, dynamic>;
                      final stepNumber = step['step'] as int;
                      return _buildRepairStep(step, stepNumber, lang);
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Wann zur Werkstatt?
                if (_hasWhenToCallMechanic()) ...[
                  _buildWhenToCallMechanic(lang),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoBadges() {
    final difficulty = _repairGuide!['difficulty_level'] as String? ?? widget.cause?.difficulty;
    final timeHours = _repairGuide!['estimated_time_hours'] as num?;
    final costRange = _repairGuide!['estimated_cost_eur'] as List<dynamic>?;
    
    // Falls keine DB-Kosten vorhanden aber cause vorhanden, nutze cause.estimatedCost
    final finalCostRange = costRange ?? (widget.cause != null 
      ? [widget.cause!.estimatedCost.minEur.toInt(), widget.cause!.estimatedCost.maxEur.toInt()]
      : null);
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (difficulty != null)
          _buildInfoBadge(
            icon: _getDifficultyIcon(difficulty),
            label: 'Schwierigkeit',
            value: _getDifficultyLabel(difficulty),
            color: const Color(0xFFFFB129),
          ),
        if (timeHours != null)
          _buildInfoBadge(
            icon: Icons.schedule,
            label: 'Zeit',
            value: '~${timeHours.toStringAsFixed(1)} Std.',
            color: const Color(0xFF2196F3),
          ),
        if (finalCostRange != null && (finalCostRange is List && finalCostRange.length == 2))
          _buildInfoBadge(
            icon: Icons.euro,
            label: 'Kosten',
            value: '${finalCostRange[0]}-${finalCostRange[1]}€',
            color: const Color(0xFF4CAF50),
          ),
      ],
    );
  }
  
  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
  
  Widget _buildToolsList(String lang) {
    final tools = _getLocalizedList('tools_required', lang);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tools.map((tool) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tool,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildSafetyWarnings(String lang) {
    final warnings = _getLocalizedList('safety_warnings', lang);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF57C00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF57C00).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFF57C00), size: 24),
              SizedBox(width: 12),
              Text(
                'Sicherheitshinweise',
                style: TextStyle(
                  color: Color(0xFFF57C00),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map((warning) {
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
          }),
        ],
      ),
    );
  }
  
  Widget _buildRepairStep(Map<String, dynamic> step, int stepNumber, String lang) {
    final isCompleted = _completedSteps.contains(stepNumber);
    final title = _getStepText(step, 'title', lang) ?? '';
    final description = _getStepText(step, 'description', lang) ?? '';
    final safetyWarning = _getStepText(step, 'safety_warning', lang);
    final tools = (step['tools'] as List<dynamic>?)?.cast<String>() ?? [];
    
    // Prüfe ob dies der ERSTE Schritt UND OBD2-Diagnose Schritt ist
    final isObd2AtStart = stepNumber == 1 && (
      title.toLowerCase().contains('obd') || 
      description.toLowerCase().contains('diagnosegerät anschließen')
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleStep(stepNumber),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : const Color(0xFF151C23),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.white12,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFFB129).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '$stepNumber',
                          style: const TextStyle(
                            color: Color(0xFFFFB129),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                          decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        ),
                      ),
                      
                      // Hinweis NUR für OBD2-Schritt am Anfang
                      if (isObd2AtStart) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF2196F3),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Du hast diesen Schritt bereits durchgeführt, um diese Diagnose zu erhalten. Du kannst ihn überspringen!',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (tools.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tools.map((tool) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      
                      if (safetyWarning != null) ...[
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
                                safetyWarning,
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
          ),
        ),
      ),
    );
  }
  
  Widget _buildWhenToCallMechanic(String lang) {
    final items = _getLocalizedList('when_to_call_mechanic', lang);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent, color: Color(0xFF2196F3), size: 24),
              SizedBox(width: 12),
              Text(
                'Wann zur Werkstatt?',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    final steps = (_repairGuide!['steps'] as List<dynamic>?) ?? [];
    final allCompleted = steps.isNotEmpty && _completedSteps.length == steps.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF151C23),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: allCompleted ? _markAsSolved : null,
          icon: const Icon(Icons.check_circle),
          label: Text(
            allCompleted
              ? 'Problem behoben?'
              : 'Alle Schritte abschließen',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: allCompleted
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFFB129), // Gelb wie gewünscht
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size.fromHeight(48),
            disabledBackgroundColor: const Color(0xFFFFB129).withOpacity(0.5),
            disabledForegroundColor: Colors.black54,
          ),
        ),
      ),
    );
  }
  
  // Helper Methods
  
  String _getLocalizedText(String key, String lang) {
    final localizedKey = '${key}_$lang';
    return _repairGuide![localizedKey] as String? ?? _repairGuide![key] as String? ?? '';
  }
  
  List<String> _getLocalizedList(String key, String lang) {
    final localizedKey = '${key}_$lang';
    final list = _repairGuide![localizedKey] as List<dynamic>?;
    if (list != null) return list.cast<String>();
    
    final fallback = _repairGuide![key] as List<dynamic>?;
    return fallback?.cast<String>() ?? [];
  }
  
  String? _getStepText(Map<String, dynamic> step, String key, String lang) {
    final localizedKey = '${key}_$lang';
    return step[localizedKey] as String? ?? step[key] as String?;
  }
  
  bool _hasTools() {
    final lang = Localizations.localeOf(context).languageCode;
    return _getLocalizedList('tools_required', lang).isNotEmpty;
  }
  
  bool _hasSafetyWarnings() {
    final lang = Localizations.localeOf(context).languageCode;
    return _getLocalizedList('safety_warnings', lang).isNotEmpty;
  }
  
  bool _hasWhenToCallMechanic() {
    final lang = Localizations.localeOf(context).languageCode;
    return _getLocalizedList('when_to_call_mechanic', lang).isNotEmpty;
  }
  
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return Icons.flash_on;
      case 'medium': return Icons.build;
      case 'hard': return Icons.factory;
      default: return Icons.build;
    }
  }
  
  String _getDifficultyLabel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return 'Einfach';
      case 'medium': return 'Mittel';
      case 'hard': return 'Schwierig';
      default: return difficulty;
    }
  }
}
