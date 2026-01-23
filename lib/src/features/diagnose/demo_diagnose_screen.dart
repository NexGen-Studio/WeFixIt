import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/obd_error_code.dart';
import '../../state/error_codes_provider.dart';
import '../../i18n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Demo-Modus Diagnose Screen - Identisch zum echten Screen
class DemoDiagnoseScreen extends ConsumerStatefulWidget {
  const DemoDiagnoseScreen({super.key});

  @override
  ConsumerState<DemoDiagnoseScreen> createState() => _DemoDiagnoseScreenState();
}

class _DemoDiagnoseScreenState extends ConsumerState<DemoDiagnoseScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Diagnose',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB129).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFB129).withOpacity(0.5)),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: Color(0xFFFFB129),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo-Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB129).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB129).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFB129),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.tr('diagnose.demo_mode'),
                            style: TextStyle(
                              color: Color(0xFFFFB129),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.tr('diagnose.demo_description'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Die 3 Hauptfunktionen
              _buildDiagnosisButton(
                number: '1',
                title: t.tr('diagnose.read_error_codes'),
                description: t.tr('diagnose.read_codes_description'),
                icon: Icons.search,
                color: const Color(0xFFE53935),
                onTap: _readErrorCodes,
              ),

              const SizedBox(height: 16),

              _buildDiagnosisButton(
                number: '2',
                title: t.tr('diagnose.delete_error_codes'),
                description: t.tr('diagnose.delete_codes_description'),
                icon: Icons.delete_outline,
                color: const Color(0xFFF57C00),
                onTap: _clearErrorCodes,
              ),

              const SizedBox(height: 16),

              _buildDiagnosisButton(
                number: '2.5',
                title: t.tr('diagnose.live_data_read'),
                description: t.tr('diagnose.live_data_description'),
                icon: Icons.show_chart,
                color: const Color(0xFF2196F3),
                onTap: _readLiveData,
              ),

              const SizedBox(height: 16),

              _buildDiagnosisButton(
                number: '3',
                title: t.tr('diagnose.ai_diagnosis'),
                description: t.tr('diagnose.ai_diagnosis_description'),
                icon: Icons.psychology,
                color: const Color(0xFFFFB129),
                onTap: _startAiDiagnosis,
              ),

              const SizedBox(height: 32),

              // Info-Sektion
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF151C23),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFFFB129),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.tr('diagnose.example_codes'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      'P0420',
                      t.tr('diagnose.catalyst_efficiency'),
                      const Color(0xFFE53935),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      'P0171',
                      t.tr('diagnose.fuel_system_lean'),
                      const Color(0xFFE53935),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      'C0035',
                      t.tr('diagnose.wheel_speed_sensor'),
                      const Color(0xFFF57C00),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisButton({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF151C23),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              // Nummer Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Icon
              Icon(
                icon,
                color: color,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String code, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            code,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  /// Fehlercodes auslesen - Demo mit realistischen Beispiel-Codes
  Future<void> _readErrorCodes() async {
    // ✅ WICHTIG: Navigiere direkt zum Error-Codes-Screen mit 'demo' flag
    // Der Screen zeigt automatisch die Loading-Animation und verarbeitet die Demo-Codes
    if (!mounted) return;
    context.push('/diagnose/error-codes', extra: 'demo');
  }

  /// Fehlercodes löschen - Demo
  Future<void> _clearErrorCodes() async {
    final codes = ref.read(errorCodesProvider);
    
    if (codes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Fehlercodes vorhanden. Bitte lese zuerst Codes aus.'),
          backgroundColor: Color(0xFFFFB129),
        ),
      );
      return;
    }
    
    // Navigiere zum Delete Screen (wie im echten Modus)
    context.push('/diagnose/delete-codes');
  }

  /// Live Daten auslesen - Demo
  Future<void> _readLiveData() async {
    // ✅ Navigiere zu Live-Data-Screen im Demo-Modus
    if (!mounted) return;
    context.push('/diagnose/live-data', extra: 'demo');
  }

  /// KI-Diagnose starten - Demo
  Future<void> _startAiDiagnosis() async {
    final codes = ref.read(errorCodesProvider);
    final t = AppLocalizations.of(context);
    
    if (codes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.tr('diagnose.no_codes_to_delete')),
          backgroundColor: const Color(0xFFFFB129),
        ),
      );
      return;
    }
    
    // Navigiere zur KI-Diagnose Auswahl im Demo-Modus
    context.push('/diagnose/ai-select', extra: true);
  }
}
