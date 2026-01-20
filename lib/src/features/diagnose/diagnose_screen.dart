import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../i18n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../services/obd2_service.dart';
import '../../models/obd_error_code.dart';
import '../../state/error_codes_provider.dart';
import 'obd2_scan_dialog.dart';

class DiagnoseScreen extends ConsumerStatefulWidget {
  const DiagnoseScreen({super.key});

  @override
  ConsumerState<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends ConsumerState<DiagnoseScreen> {
  final _obd2Service = Obd2Service();
  bool _isScanning = false;

  /// KI-Diagnose starten
  Future<void> _startAiDiagnosis() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showLoginRequired(context);
      return;
    }
    
    // Prüfe ob Codes vorhanden sind
    final codes = ref.read(errorCodesProvider);
    if (codes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte lese zuerst Fehlercodes aus'),
          backgroundColor: Color(0xFFFFB129),
        ),
      );
      return;
    }
    
    // Navigiere zur KI-Diagnose Auswahl (Screen 1)
    context.push('/diagnose/ai-select');
  }

  /// Demo-Modus: Öffne Demo-Diagnose Screen mit allen Funktionen
  Future<void> _startDemoMode() async {
    // Navigiere zum Demo-Diagnose Screen (identisch zum echten mit 3 Buttons)
    context.push('/diagnose/demo');
  }

  /// Fehlercodes auslesen - Öffne Scan-Screen
  Future<void> _readErrorCodes() async {
    setState(() => _isScanning = true);
    
    try {
      // Zeige OBD2-Scan-Dialog
      final device = await showDialog<BluetoothDevice>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Obd2ScanDialog(obd2Service: _obd2Service),
      );
      
      if (device == null) {
        setState(() => _isScanning = false);
        return;
      }
      
      // Verbinde mit Gerät
      final success = await _obd2Service.connect(device);
      
      if (!mounted) return;
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verbindung fehlgeschlagen'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        setState(() => _isScanning = false);
        return;
      }

      // ✅ WICHTIG: Navigiere zum Error-Codes-Screen der macht das Auslesen selbst
      // Der Screen zeigt automatisch die Loading-Animation und verarbeitet die Codes
      if (!mounted) return;
      await context.push('/diagnose/error-codes', extra: _obd2Service);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  /// Fehlercodes löschen - Navigiere zum Delete Screen
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
    
    // Navigiere zum Delete Screen
    context.push('/diagnose/delete-codes');
  }

  /// Live Daten auslesen - Öffne Live Data Screen
  Future<void> _readLiveData() async {
    // Prüfe ob Adapter verbunden ist (persistent über Screens)
    if (!_obd2Service.isConnected) {
      // Nicht verbunden → zeige Scan-Dialog
      setState(() => _isScanning = true);
      
      try {
        final device = await showDialog<BluetoothDevice>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Obd2ScanDialog(obd2Service: _obd2Service),
        );
        
        if (device == null) {
          setState(() => _isScanning = false);
          return;
        }
        
        // Verbinde mit Gerät
        final success = await _obd2Service.connect(device);
        
        if (!mounted) return;
        
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verbindung fehlgeschlagen'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
          setState(() => _isScanning = false);
          return;
        }

        setState(() => _isScanning = false);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $e'),
              backgroundColor: const Color(0xFFE53935),
            ),
          );
        }
        setState(() => _isScanning = false);
        return;
      }
    }

    // ✅ Adapter ist jetzt verbunden → navigiere zu Live Data Screen
    if (!mounted) return;
    context.push('/diagnose/live-data', extra: _obd2Service);
  }

  @override
  void dispose() {
    // ❌ NICHT dispose() aufrufen - das würde die Verbindung trennen!
    // Die Verbindung bleibt bis zum App-Exit oder bis der Adapter entfernt wird
    super.dispose();
  }

  static void _showLoginRequired(BuildContext context) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anmeldung erforderlich', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Für KI-Diagnosen musst du dich anmelden. Fehlercodes auslesen und löschen ist immer kostenlos!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.tr('common.cancel'), style: const TextStyle(color: Color(0xFFF8AD20))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8AD20),
            ),
            child: const Text('Jetzt anmelden', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                t.tr('diagnose.title'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.tr('diagnose.subtitle'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Button 1: Fehlercodes auslesen
              _buildMainActionButton(
                icon: Icons.search,
                iconColor: const Color(0xFFE53935),
                iconBg: const Color(0xFFFFEBEE),
                title: 'Fehlercodes\nauslesen',
                badge: 'Kostenlos',
                badgeColor: const Color(0xFF4CAF50),
                onTap: _isScanning ? null : _readErrorCodes,
              ),
              
              const SizedBox(height: 16),
              
              // Button 2: Fehlercodes löschen
              _buildMainActionButton(
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFFFB129),
                iconBg: const Color(0xFFFFF8E1),
                title: 'Fehlercodes\nlöschen',
                badge: 'Kostenlos',
                badgeColor: const Color(0xFF4CAF50),
                onTap: _clearErrorCodes,
              ),
              
              const SizedBox(height: 16),
              
              // Button 2.5: Live Daten auslesen
              _buildMainActionButton(
                icon: Icons.show_chart,
                iconColor: const Color(0xFF2196F3),
                iconBg: const Color(0xFFE3F2FD),
                title: 'Live Daten\nauslesen',
                badge: 'Kostenlos',
                badgeColor: const Color(0xFF4CAF50),
                onTap: _readLiveData,
              ),
              
              const SizedBox(height: 16),
              
              // Button 3: KI-Diagnose starten
              _buildMainActionButton(
                icon: Icons.psychology_outlined,
                iconColor: const Color(0xFFFFB129),
                iconBg: const Color(0xFFFFF8E1),
                title: 'KI-Diagnose\nstarten',
                badge: 'Credits',
                badgeColor: const Color(0xFFFFB129),
                onTap: _startAiDiagnosis,
              ),
              
              const SizedBox(height: 40),
              
              // Info Section - Wie funktioniert's?
              Text(
                t.diagnose_how_it_works,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.cable,
                title: t.diagnose_connect_adapter,
                description: t.diagnose_connect_adapter_desc,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.bluetooth,
                title: t.diagnose_activate_bluetooth,
                description: t.diagnose_activate_bluetooth_desc,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.play_arrow,
                title: t.diagnose_start_diagnosis,
                description: t.diagnose_start_diagnosis_desc,
              ),
              
              const SizedBox(height: 24),
              
              // Demo-Modus Button (unten)
              Material(
                color: const Color(0xFF151C23),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _startDemoMode,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFB129).withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB129).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.science_outlined,
                            color: Color(0xFFFFB129),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🧪 Demo-Modus (ohne Adapter)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Teste mit Beispiel-Fehlercodes',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFFFFB129),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String badge,
    required Color badgeColor,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFF151C23),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFF8AD20), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

