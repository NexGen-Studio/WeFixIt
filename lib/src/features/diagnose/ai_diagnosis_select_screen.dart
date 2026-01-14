import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../state/error_codes_provider.dart';
import '../../services/error_code_description_service.dart';
import '../../i18n/app_localizations.dart';

/// Screen 1: Fehlercode-Auswahl für KI-Diagnose
class AiDiagnosisSelectScreen extends ConsumerStatefulWidget {
  final bool isDemo;
  
  const AiDiagnosisSelectScreen({super.key, this.isDemo = false});

  @override
  ConsumerState<AiDiagnosisSelectScreen> createState() => _AiDiagnosisSelectScreenState();
}

class _AiDiagnosisSelectScreenState extends ConsumerState<AiDiagnosisSelectScreen> {
  final _descriptionService = ErrorCodeDescriptionService();
  final Map<String, ObdErrorCode?> _descriptions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDescriptions();
  }

  Future<void> _loadDescriptions() async {
    setState(() => _isLoading = true);
    
    final codes = ref.read(errorCodesProvider);
    for (var code in codes) {
      final description = await _descriptionService.getDescription(code.code);
      if (mounted) {
        setState(() => _descriptions[code.code] = description);
      }
    }
    
    setState(() => _isLoading = false);
  }

  void _selectCode(RawObdCode code, ObdErrorCode? description) {
    // Navigiere zu Screen 2 (Detail + Ursachen)
    context.push('/diagnose/ai-detail', extra: {
      'code': code,
      'description': description,
      'isDemo': widget.isDemo,
    });
  }

  @override
  Widget build(BuildContext context) {
    final codes = ref.watch(errorCodesProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        title: const Text(
          '3. KI-Diagnose starten',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: codes.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF151C23),
                    border: Border(
                      bottom: BorderSide(color: Colors.white12),
                    ),
                  ),
                  child: const Text(
                    'Wähle einen Fehlercode für die Analyse',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // Fehlercode Liste
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: codes.length,
                    itemBuilder: (context, index) {
                      final code = codes[index];
                      final description = _descriptions[code.code];
                      return _buildCodeCard(code, description);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 20),
          const Text(
            'Keine Fehlercodes vorhanden',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Lese zuerst Fehlercodes aus',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/diagnose'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB129),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Zur Diagnose'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(RawObdCode code, ObdErrorCode? description) {
    final codeColor = _getCodeColor(code.code);
    final isLoading = _isLoading && description == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCode(code, description),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF151C23),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: codeColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
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
                  code.code,
                  style: TextStyle(
                    color: codeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Beschreibung
              Expanded(
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      )
                    : Text(
                        description?.description ?? 'Keine Beschreibung verfügbar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Pfeil
              Icon(
                Icons.arrow_forward_ios,
                color: codeColor.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
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
}
