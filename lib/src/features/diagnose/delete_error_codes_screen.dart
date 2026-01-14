import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../services/obd2_service.dart';
import '../../services/error_code_description_service.dart';
import '../../state/error_codes_provider.dart';
import '../../i18n/app_localizations.dart';

class DeleteErrorCodesScreen extends ConsumerStatefulWidget {
  const DeleteErrorCodesScreen({super.key});

  @override
  ConsumerState<DeleteErrorCodesScreen> createState() => _DeleteErrorCodesScreenState();
}

class _DeleteErrorCodesScreenState extends ConsumerState<DeleteErrorCodesScreen> {
  final _obd2Service = Obd2Service();
  final _descriptionService = ErrorCodeDescriptionService();
  final Map<String, ObdErrorCode?> _descriptions = {};
  bool _isLoadingDescriptions = false;
  bool _isDeletingAll = false;

  @override
  void initState() {
    super.initState();
    _loadDescriptions();
  }

  Future<void> _loadDescriptions() async {
    setState(() => _isLoadingDescriptions = true);
    
    final codes = ref.read(errorCodesProvider);
    for (var code in codes) {
      final description = await _descriptionService.getDescription(code.code);
      if (mounted) {
        setState(() => _descriptions[code.code] = description);
      }
    }
    
    setState(() => _isLoadingDescriptions = false);
  }

  Future<void> _deleteCode(String code) async {
    final t = AppLocalizations.of(context);
    
    // Bestätigungs-Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        title: Text(
          'Fehlercode löschen?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Möchtest du den Fehlercode $code wirklich aus dem Steuergerät löschen?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Aus Steuergerät löschen
      await _obd2Service.clearSingleErrorCode(code);
      
      // Aus State entfernen
      ref.read(errorCodesProvider.notifier).removeCode(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehlercode $code gelöscht'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  Future<void> _deleteAllCodes() async {
    final t = AppLocalizations.of(context);
    
    // Bestätigungs-Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        title: const Text(
          'Alle Codes löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Möchtest du wirklich ALLE Fehlercodes aus dem Steuergerät löschen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Alle löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeletingAll = true);

    try {
      // Alle Codes aus Steuergerät löschen
      await _obd2Service.clearErrorCodes();
      
      // State leeren
      ref.read(errorCodesProvider.notifier).clearAll();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alle Fehlercodes gelöscht'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      setState(() => _isDeletingAll = false);
    }
  }

  void _startAiDiagnosis(RawObdCode code) {
    context.go('/diagnose/ai-results', extra: [code]);
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
          '2. Fehlercodes löschen',
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
                _buildDeleteAllButton(codes.length),
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
            Icons.info_outline,
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
              backgroundColor: const Color(0xFFE53935),
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
    final isLoading = _isLoadingDescriptions && description == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: codeColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Fehlercode Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: codeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: codeColor.withOpacity(0.5)),
            ),
            child: Text(
              code.code,
              style: TextStyle(
                color: codeColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          
          const SizedBox(width: 12),
          
          // Aktionen
          Row(
            children: [
              // Löschen
              IconButton(
                onPressed: () => _deleteCode(code.code),
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFE53935),
                iconSize: 22,
              ),
              
              // KI-Diagnose
              IconButton(
                onPressed: () => _startAiDiagnosis(code),
                icon: const Icon(Icons.psychology_outlined),
                color: const Color(0xFFFFB129),
                iconSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAllButton(int count) {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isDeletingAll ? null : _deleteAllCodes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isDeletingAll
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_sweep, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Alle Codes löschen ($count)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
