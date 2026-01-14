import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../i18n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/obd2_service.dart';
import '../../state/error_codes_provider.dart';

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
  List<RawObdCode> _errorCodes = [];
  bool _isScanning = true;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _startScan();
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
      
      if (codes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Fehlercodes gefunden'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isScanning = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Auslesen: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  void _showCodeDetails(RawObdCode code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CodeDetailsBottomSheet(code: code),
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
        title: const Text(
          'Fehlercodes',
          style: TextStyle(
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
          const Text(
            'Lese Fehlercodes aus...',
            style: TextStyle(
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
        // Statistik Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF151C23),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.error_outline,
                  label: 'Gefunden',
                  value: _errorCodes.length.toString(),
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber,
                  label: 'Kritisch',
                  value: _criticalCount.toString(),
                  color: const Color(0xFFF57C00),
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
                onTap: () => _showCodeDetails(code),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCodeCard extends StatelessWidget {
  final RawObdCode code;
  final VoidCallback onTap;

  const _ErrorCodeCard({required this.code, required this.onTap});

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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getCodeType(code.code, context),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
class _CodeDetailsBottomSheet extends StatelessWidget {
  final RawObdCode code;

  const _CodeDetailsBottomSheet({required this.code});

  Color _getCodeColor(String code) {
    if (code.startsWith('P')) return const Color(0xFFE53935);
    if (code.startsWith('C')) return const Color(0xFFF57C00);
    if (code.startsWith('B')) return const Color(0xFF2196F3);
    if (code.startsWith('U')) return const Color(0xFF9C27B0);
    return const Color(0xFF757575);
  }

  @override
  Widget build(BuildContext context) {
    final codeColor = _getCodeColor(code.code);

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
                code.code,
                style: TextStyle(
                  color: codeColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Aktionen
            _ActionItem(
              icon: Icons.delete_outline,
              iconColor: const Color(0xFFE53935),
              title: 'Fehlercode löschen',
              onTap: () {
                Navigator.pop(context);
                // Navigiere zum Delete Screen
                context.push('/diagnose/delete-codes');
              },
            ),

            const SizedBox(height: 12),

            _ActionItem(
              icon: Icons.psychology_outlined,
              iconColor: const Color(0xFFFFB129),
              title: 'KI-Diagnose starten',
              onTap: () {
                Navigator.pop(context);
                // Navigiere zur KI-Diagnose mit diesem Code
                context.push('/diagnose/ai-results', extra: [code]);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
