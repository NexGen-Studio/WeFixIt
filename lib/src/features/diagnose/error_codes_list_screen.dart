import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../i18n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/obd2_service.dart';
import '../../services/error_code_description_service.dart';
import '../../state/error_codes_provider.dart';
import '../../state/locale_provider.dart';

class ErrorCodesListScreen extends ConsumerStatefulWidget {
  final dynamic extra; // 'demo' oder Obd2Service

  const ErrorCodesListScreen({
    super.key,
    this.extra,
  });

  @override
  ConsumerState<ErrorCodesListScreen> createState() => _ErrorCodesListScreenState();
}

class _ErrorCodesListScreenState extends ConsumerState<ErrorCodesListScreen> {
  final _descriptionService = ErrorCodeDescriptionService();
  List<RawObdCode> _errorCodes = [];
  bool _isScanning = true;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  /// Background-Generierung: Für ALLE ausgelesenen Fehlercodes fehlende Anleitungen generieren
  void _startBackgroundRepairGuideGeneration(List<RawObdCode> codes) {
    Future.microtask(() async {
      try {
        final supabase = Supabase.instance.client;
        
        for (final errorCode in codes) {
          final code = errorCode.code;
          print('🔍 Background-Check für $code...');
          
          try {
            // Hole causes + repair_guides aus DB (exakte topic query!)
            final result = await supabase
              .from('automotive_knowledge')
              .select('causes, repair_guides_de, repair_guides_en')
              .eq('category', 'fehlercode')
              .eq('topic', '$code OBD2 diagnostic trouble code')
              .maybeSingle();
            
            if (result == null) {
              print('⚠️ $code nicht in DB gefunden - überspringe');
              continue;
            }
            
            final causes = (result['causes'] as List?)?.cast<String>() ?? [];
            final repairGuidesDe = result['repair_guides_de'] as Map<String, dynamic>?;
            final repairGuidesEn = result['repair_guides_en'] as Map<String, dynamic>?;
            final existingGuidesDe = repairGuidesDe ?? {};
            final existingGuidesEn = repairGuidesEn ?? {};
            
            // Prüfe ob ALLE Ursachen Anleitungen haben (DE + EN)
            int missingCount = 0;
            
            for (final cause in causes) {
              final causeKey = cause.toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                .replaceAll(RegExp(r'^_|_$'), '');
              
              if (!existingGuidesDe.containsKey(causeKey) || !existingGuidesEn.containsKey(causeKey)) {
                missingCount++;
              }
            }
            
            if (missingCount == 0) {
              print('✅ $code: Alle ${causes.length} Anleitungen (DE+EN) vorhanden');
              continue;
            }
            
            print('🚀 $code: Starte fill-repair-guides für $missingCount fehlende Anleitungen...');
            
            // EINFACHER CALL (KEINE RETRY LOOP!)
            // fill-repair-guides verarbeitet ALLE Causes + triggert translate-repair-guides
            try {
              final response = await supabase.functions.invoke(
                'fill-repair-guides',
                body: {
                  'error_codes': [code],
                  'trigger_source': 'error_codes_list_screen',
                  'language': currentLanguageCode
                },
              );
              
              if (response.data != null && response.data['success'] == true) {
                print('✅ $code: fill-repair-guides erfolgreich gestartet');
              } else {
                print('⚠️ $code: fill-repair-guides Fehler');
              }
            } catch (e) {
              print('❌ $code: Edge Function Fehler: $e');
            }
          } catch (e) {
            print('❌ Background-Check Fehler für $code: $e');
          }
        }
        
        print('✨ Background-Generierung für alle Codes abgeschlossen');
      } catch (e) {
        print('❌ Background-Generierung Fehler: $e');
      }
    });
  }

  Future<void> _startScan() async {
    // Check if demo mode
    if (widget.extra == 'demo') {
      setState(() => _isDemoMode = true);
      await _scanDemoMode();
    } else {
      await _scanRealMode();
    }
  }

  Future<void> _scanDemoMode() async {
    // Simuliere Scan-Verzögerung
    await Future.delayed(const Duration(seconds: 2));
    
    // Generiere Demo-Fehlercodes
    final testCodes = [
      RawObdCode(
        code: 'P0420',
        readAt: DateTime.now(),
      ),
      RawObdCode(
        code: 'P0171',
        readAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RawObdCode(
        code: 'C0035',
        readAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    
    if (!mounted) return;
    
    setState(() {
      _errorCodes = testCodes;
      _isScanning = false;
    });
    
    // Speichere Codes im Provider
    ref.read(errorCodesProvider.notifier).setCodes(testCodes);
    
    // ✅ SOFORT nach Auslesen: Background-Generierung starten
    _startBackgroundRepairGuideGeneration(testCodes);
    
    // Wenn KEINE Codes gefunden, zeige Dialog
    if (testCodes.isEmpty && mounted) {
      _showNoCodesFoundDialog();
    }
  }

  Future<void> _scanRealMode() async {
    if (widget.extra is! Obd2Service) {
      setState(() => _isScanning = false);
      return;
    }
    
    final obd2Service = widget.extra as Obd2Service;
    
    try {
      final codes = await obd2Service.readErrorCodes();
      
      if (!mounted) return;
      
      setState(() {
        _errorCodes = codes;
        _isScanning = false;
      });
      
      // Speichere Codes im Provider
      ref.read(errorCodesProvider.notifier).setCodes(codes);
      
      // ✅ SOFORT nach Auslesen: Background-Generierung starten
      if (codes.isNotEmpty) {
        _startBackgroundRepairGuideGeneration(codes);
      } else if (mounted) {
        // Wenn KEINE Codes gefunden, zeige Dialog
        _showNoCodesFoundDialog();
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isScanning = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tr('error_codes.read_error').replaceAll('{error}', e.toString())),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  void _showNoCodesFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon mit Animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF4CAF50),
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).tr('error_codes.no_codes_found'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).tr('error_codes.no_codes_message'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Zurück zur Diagnose Screen
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Zurück zur Diagnose',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCodeDetails(RawObdCode code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CodeDetailsBottomSheet(
        code: code,
        descriptionService: _descriptionService,
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

  int get _criticalCount {
    return _errorCodes.where((code) => code.code.startsWith('P') || code.code.startsWith('C')).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context).tr('error_codes.title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isScanning
          ? _buildScanningView()
          : _buildResultsView(),
    );
  }

  Widget _buildScanningView() {
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
                      color: const Color(0xFFE53935).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 50,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted && _isScanning) {
                setState(() {}); // Restart animation
              }
            },
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).tr('error_codes.reading_codes'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        // Vereinfachter Header - nur Anzahl
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF151C23),
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                _errorCodes.length == 1
                    ? AppLocalizations.of(context).tr('error_codes.found_single')
                    : AppLocalizations.of(context).tr('error_codes.found_multiple').replaceAll('{count}', '${_errorCodes.length}'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Fehlercodes Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _errorCodes.length,
            itemBuilder: (context, index) {
              final code = _errorCodes[index];
              return _ErrorCodeCard(
                code: code,
                descriptionService: _descriptionService,
                onTap: () => _showCodeDetails(code),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorCodeCard extends StatelessWidget {
  final RawObdCode code;
  final ErrorCodeDescriptionService descriptionService;
  final VoidCallback onTap;

  const _ErrorCodeCard({
    required this.code,
    required this.descriptionService,
    required this.onTap,
  });

  Color _getCodeColor(String code) {
    if (code.startsWith('P')) return const Color(0xFFE53935); // Powertrain - Rot
    if (code.startsWith('C')) return const Color(0xFFF57C00); // Chassis - Orange
    if (code.startsWith('B')) return const Color(0xFF2196F3); // Body - Blau
    if (code.startsWith('U')) return const Color(0xFF9C27B0); // Network - Lila
    return const Color(0xFF757575); // Default - Grau
  }

  String _getCodeType(String code, BuildContext context) {
    final t = AppLocalizations.of(context);
    if (code.startsWith('P')) return t.tr('diagnose.code_type_powertrain');
    if (code.startsWith('C')) return t.tr('diagnose.code_type_chassis');
    if (code.startsWith('B')) return t.tr('diagnose.code_type_body');
    if (code.startsWith('U')) return t.tr('diagnose.code_type_network');
    return t.tr('diagnose.code_type_unknown');
  }

  @override
  Widget build(BuildContext context) {
    final codeColor = _getCodeColor(code.code);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151C23),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: codeColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: codeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: codeColor.withOpacity(0.5)),
                ),
                child: Text(
                  code.code,
                  style: TextStyle(
                    color: codeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<ObdErrorCode?>(
                  future: descriptionService.getDescription(code.code),
                  builder: (context, snapshot) {
                    final description = snapshot.data;
                    return Text(
                      descriptionService.getShortDescription(code.code, description),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: codeColor.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppLocalizations.of(context).tr('diagnose.read_at')} ${_formatTimestamp(code.readAt, context)}',
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
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, BuildContext context) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return t.tr('diagnose.time_just_now');
    } else if (difference.inHours < 1) {
      return t.tr('diagnose.time_minutes_ago').replaceAll('{count}', difference.inMinutes.toString());
    } else if (difference.inDays < 1) {
      return t.tr('diagnose.time_hours_ago').replaceAll('{count}', difference.inHours.toString());
    } else {
      final key = difference.inDays > 1 ? 'diagnose.time_days_ago_plural' : 'diagnose.time_days_ago';
      return t.tr(key).replaceAll('{count}', difference.inDays.toString());
    }
  }
}

// Bottom Sheet für Fehlercode-Details
class _CodeDetailsBottomSheet extends StatefulWidget {
  final RawObdCode code;
  final ErrorCodeDescriptionService descriptionService;

  const _CodeDetailsBottomSheet({
    required this.code,
    required this.descriptionService,
  });

  @override
  State<_CodeDetailsBottomSheet> createState() => _CodeDetailsBottomSheetState();
}

class _CodeDetailsBottomSheetState extends State<_CodeDetailsBottomSheet> {
  String? _shortDescription;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDescription();
  }

  Future<void> _loadDescription() async {
    final description = await widget.descriptionService.getDescription(widget.code.code);
    if (mounted) {
      // Verwende sprachabhängige Beschreibung basierend auf currentLanguageCode
      final isEnglish = currentLanguageCode == 'en';
      final descriptionText = isEnglish 
        ? (description?.descriptionEn ?? description?.descriptionDe)
        : (description?.descriptionDe ?? description?.descriptionEn);
      
      setState(() {
        _shortDescription = _extractShortDescription(descriptionText);
        _isLoading = false;
      });
    }
  }

  String _extractShortDescription(String? fullDescription) {
    if (fullDescription == null || fullDescription.isEmpty) {
      return 'Keine Beschreibung';
    }
    
    // Verwende die vollständige Beschreibung (nicht mehr auf 8 Wörter begrenzt)
    return fullDescription;
  }

  Future<void> _deleteCode() async {
    // Bestätigungs-Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        title: Text(
          AppLocalizations.of(context).tr('error_codes.delete_code_title'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppLocalizations.of(context).tr('error_codes.delete_code_message').replaceAll('{code}', widget.code.code),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).tr('diagnose.cancel'), style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: Text(AppLocalizations.of(context).tr('error_codes.delete_button')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      // Aus Steuergerät löschen
      final obd2Service = Obd2Service();
      await obd2Service.clearSingleErrorCode(widget.code.code);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tr('error_codes.code_deleted').replaceAll('{code}', widget.code.code)),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).tr('error_codes.delete_error')}: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  Color _getCodeColor(String code) {
    if (code.startsWith('P')) return const Color(0xFFE53935);
    if (code.startsWith('C')) return const Color(0xFFF57C00);
    if (code.startsWith('B')) return const Color(0xFF2196F3);
    if (code.startsWith('U')) return const Color(0xFF9C27B0);
    return const Color(0xFF757575);
  }

  @override
  Widget build(BuildContext context) {
    final codeColor = _getCodeColor(widget.code.code);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F26),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Fehlercode Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: codeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: codeColor.withOpacity(0.5), width: 2),
              ),
              child: Text(
                widget.code.code,
                style: TextStyle(
                  color: codeColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kurzbeschreibung (max 8 Wörter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    )
                  : Text(
                      _shortDescription ?? 'Keine Beschreibung',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
            ),

            const SizedBox(height: 32),

            // Löschen Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isDeleting ? null : _deleteCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDeleting
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
                            const Icon(Icons.delete_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).tr('error_codes.delete_code_title'),
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

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
