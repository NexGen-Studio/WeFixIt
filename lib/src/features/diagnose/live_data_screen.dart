import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../i18n/app_localizations.dart';
import '../../services/obd2_service.dart';

class LiveDataScreenData {
  final String parameterName;
  final String value;
  final String unit;
  final Color statusColor;
  final bool isAlert;

  LiveDataScreenData({
    required this.parameterName,
    required this.value,
    required this.unit,
    required this.statusColor,
    this.isAlert = false,
  });
}

class LiveDataScreen extends ConsumerStatefulWidget {
  final dynamic extra; // Obd2Service im echten Modus, 'demo' im Demo-Modus

  const LiveDataScreen({
    super.key,
    this.extra,
  });

  @override
  ConsumerState<LiveDataScreen> createState() => _LiveDataScreenState();
}

class _LiveDataScreenState extends ConsumerState<LiveDataScreen>
    with AutomaticKeepAliveClientMixin {
  late final Obd2Service _obd2Service;
  bool _isLoading = true;
  String? _connectionStatus;
  List<LiveDataScreenData> _liveDataList = [];
  bool _isStreaming = false;
  bool _isDemoMode = false;

  // Daten für den aktuellen Session
  Map<String, dynamic> _currentValues = {
    'rpm': 0,
    'temperature': 0,
    'speed': 0,
    'lambda_bank1_s1': 0.0,
    'lambda_bank1_s2': 0.0,
    'fuel_pressure': 0,
    'air_intake_temp': 0,
    'throttle_position': 0,
    'engine_load': 0,
    'fuel_trim_short': 0,
    'fuel_trim_long': 0,
    'ignition_advance': 0,
    'manifold_pressure': 0,
  };

  @override
  void initState() {
    super.initState();
    // Nutze übergebene Obd2Service oder Singleton
    if (widget.extra is Obd2Service) {
      _obd2Service = widget.extra as Obd2Service;
      _isDemoMode = false;
    } else if (widget.extra == 'demo') {
      _obd2Service = Obd2Service();
      _isDemoMode = true;
    } else {
      _obd2Service = Obd2Service();
      _isDemoMode = false;
    }
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    if (_isDemoMode) {
      // Demo-Modus: Keine Loading-Animation, starte direkt Live-Daten
      try {
        // Schalte Loading sofort aus
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        
        // Starte sofort Live-Stream mit realistischen Mock-Daten
        await _startLiveDataStream();
      } catch (e) {
        if (mounted) {
          setState(() {
            _connectionStatus = AppLocalizations.of(context).tr('live_data.initialization_error').replaceAll('{error}', e.toString());
            _isLoading = false;
          });
        }
      }
    } else {
      // Echter Modus: Prüfe Adapter-Verbindung
      // Wenn nicht verbunden, zeige Error und User kann Bluetooth-Dialog öffnen
      if (!_obd2Service.isConnected) {
        if (mounted) {
          setState(() {
            _connectionStatus = AppLocalizations.of(context).tr('live_data.no_adapter_connected');
            _isLoading = false;
          });
        }
        return;
      }

      try {
        if (mounted) setState(() => _isLoading = true);
        
        // Versuche Verbindung mit Timeout (max 8 Sekunden)
        // Wenn es länger dauert, zeige Fehler
        await _testAdapterConnection().timeout(
          const Duration(seconds: 8),
          onTimeout: () async {
            throw Exception(AppLocalizations.of(context).tr('live_data.adapter_timeout'));
          },
        );
        
        if (mounted) setState(() => _isLoading = false);
        
        // Starte Live-Stream
        await _startLiveDataStream();
      } catch (e) {
        if (mounted) {
          setState(() {
            _connectionStatus = AppLocalizations.of(context).tr('live_data.initialization_error').replaceAll('{error}', e.toString());
            _isLoading = false;
            _isStreaming = false;
          });
        }
      }
    }
  }

  /// Teste OBD2-Adapter mit einfachem Befehl
  Future<void> _testAdapterConnection() async {
    // Sende einfachen AT-Befehl zum Testen
    final response = await _obd2Service.sendCommand('0100');
    
    if (response == null || response.isEmpty) {
      throw Exception('Keine Antwort vom Adapter');
    }
    
    print('✅ OBD2-Adapter antwortet: $response');
  }

  Future<void> _startLiveDataStream() async {
    // Demo-Modus: Keine echte Verbindungs-Prüfung, einfach streamen
    if (!_isDemoMode && !_obd2Service.isConnected) {
      throw Exception(AppLocalizations.of(context).tr('live_data.adapter_not_connected'));
    }

    if (mounted) setState(() => _isStreaming = true);

    try {
      // Starte kontinuierliches Auslesen von Live-Daten
      // Diese Daten werden alle 200ms aktualisiert
      while (_isStreaming && mounted) {
        await _readLiveData();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = AppLocalizations.of(context).tr('live_data.stream_error').replaceAll('{error}', e.toString());
          _isStreaming = false;
        });
      }
    }
  }

  Future<void> _readLiveData() async {
    try {
      if (_isDemoMode) {
        // Demo-Modus: Keine echten OBD2-Befehle senden, nur Test-Werte setzen
        _setTestValue('rpm', 'RPM');
        _setTestValue('temperature', '°C');
        _setTestValue('speed', 'km/h');
        _setTestValue('lambda_bank1_s1', 'λ');
        _setTestValue('lambda_bank1_s2', 'λ');
        _setTestValue('air_intake_temp', '°C');
        _setTestValue('throttle_position', '%');
        _setTestValue('engine_load', '%');
        _setTestValue('fuel_trim_short', '%');
        _setTestValue('fuel_trim_long', '%');
        _setTestValue('ignition_advance', '°');
        _setTestValue('manifold_pressure', 'kPa');
      } else {
        // Echter Modus: Lese wichtige PIDs (Parameter IDs) aus dem Fahrzeug
        // Diese sind Standard-OBD2-PIDs nach SAE J1979

        // PID 0x0C - Engine RPM (Motordrehzahl)
        await _readAndUpdatePid('0C', 'rpm', 'RPM', (a, b) => ((a * 256) + b) / 4, true);

        // PID 0x05 - Engine Coolant Temperature
        await _readAndUpdatePid('05', 'temperature', '°C', (a, b) => a - 40, true);

        // PID 0x0D - Vehicle Speed
        await _readAndUpdatePid('0D', 'speed', 'km/h', (a, b) => a.toDouble(), true);

        // PIDs für Lambda (Bank 1, Sensor 1 und 2)
        // PID 0x14 (Bank 1, Sensor 1)
        await _readAndUpdatePid('14', 'lambda_bank1_s1', 'λ', (a, b) => a / 200, false);

        // PID 0x15 (Bank 1, Sensor 2)
        await _readAndUpdatePid('15', 'lambda_bank1_s2', 'λ', (a, b) => a / 200, false);

        // PID 0x0F - Intake Air Temperature
        await _readAndUpdatePid('0F', 'air_intake_temp', '°C', (a, b) => a - 40, false);

        // PID 0x11 - Throttle Position
        await _readAndUpdatePid('11', 'throttle_position', '%', (a, b) => (a / 255) * 100, true);

        // PID 0x04 - Engine Load
        await _readAndUpdatePid('04', 'engine_load', '%', (a, b) => (a / 255) * 100, true);

        // PID 0x07/0x08 - Fuel Trim (Short Term)
        await _readAndUpdatePid(
          '07',
          'fuel_trim_short',
          '%',
          (a, b) => (a / 128) * 100 - 100,
          true,
        );

        // PID 0x09 - Fuel Trim (Long Term)
        await _readAndUpdatePid(
          '09',
          'fuel_trim_long',
          '%',
          (a, b) => (a / 128) * 100 - 100,
          true,
        );

        // PID 0x0E - Ignition Timing Advance
        await _readAndUpdatePid('0E', 'ignition_advance', '°', (a, b) => (a / 2) - 64, false);

        // PID 0x0B - Intake Manifold Absolute Pressure
        await _readAndUpdatePid('0B', 'manifold_pressure', 'kPa', (a, b) => a.toDouble(), false);
      }

      // Update UI mit aktuellen Daten
      if (mounted) {
        _updateLiveDataList();
      }
    } catch (e) {
      print('⚠️ Error reading live data: $e');
    }
  }

  Future<void> _readAndUpdatePid(
    String pid,
    String key,
    String unit,
    dynamic Function(int, int) converter,
    bool isImportant,
  ) async {
    try {
      // Sende PID-Abfrage an OBD2-Adapter mit Timeout (3 Sekunden pro Befehl)
      // Format: "01 [PID]" - Service 01, Parameter ID
      final response = await _obd2Service.sendCommand('01 $pid').timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⏱️ Timeout beim Auslesen von PID $pid');
          return null;
        },
      );

      if (response == null || response.contains('NO DATA') || response.isEmpty) {
        print('⚠️ Keine Daten für PID $pid');
        // Setze Default-Wert um nicht hängen zu bleiben
        _currentValues[key] = 0;
        return;
      }

      // Parse OBD2-Response
      // Response-Format: "41 [PID] [Byte1] [Byte2] ..."
      // z.B. "41 0C 1A F4" für RPM (Byte1=26, Byte2=244)
      final parts = response.split(' ').where((p) => p.isNotEmpty).toList();
      
      if (parts.length < 3) {
        print('⚠️ Ungültige Response für PID $pid: $response');
        _currentValues[key] = 0;
        return;
      }

      // Prüfe ob es eine gültige Mode-01 Response ist (41)
      if (parts[0] != '41') {
        print('⚠️ Falsche Service-Response für PID $pid');
        _currentValues[key] = 0;
        return;
      }

      // Prüfe ob die PID stimmt
      if (parts[1] != pid) {
        print('⚠️ PID-Mismatch: erwartete $pid, erhielt ${parts[1]}');
        _currentValues[key] = 0;
        return;
      }

      // Extrahiere Daten-Bytes (ab Index 2)
      int? dataByte1;
      int? dataByte2;
      
      if (parts.length > 2) {
        try {
          dataByte1 = int.parse(parts[2], radix: 16);
        } catch (e) {
          print('⚠️ Fehler beim Parsen von Byte1 für PID $pid: ${parts[2]}');
          _currentValues[key] = 0;
          return;
        }
      }
      
      if (parts.length > 3) {
        try {
          dataByte2 = int.parse(parts[3], radix: 16);
        } catch (e) {
          print('⚠️ Fehler beim Parsen von Byte2 für PID $pid: ${parts[3]}');
          dataByte2 = 0;
        }
      } else {
        dataByte2 = 0;
      }

      // Konvertiere Roh-Daten zu echtem Wert mittels Converter-Funktion
      if (dataByte1 != null) {
        final value = converter(dataByte1, dataByte2 ?? 0);
        _currentValues[key] = value;
        print('✅ PID $pid ($key): $value $unit');
      }
    } catch (e) {
      print('⚠️ Fehler beim Auslesen von PID $pid: $e');
      _currentValues[key] = 0;
    }
  }

  void _setTestValue(String key, String unit) {
    // Realistische Demo-Werte basierend auf der aktuellen Zeit
    // Simuliert ein Fahrzeug im normalen Betriebszustand
    final now = DateTime.now();
    final milliseconds = now.millisecondsSinceEpoch;
    
    // Basis-Variation für sanfte Bewegungen (nicht zu wild)
    final sineWave = ((sin(milliseconds / 1000.0) + 1) / 2); // 0-1 range
    final smallNoise = (milliseconds % 50) / 50; // kleine zufällige Schwankungen

    switch (key) {
      case 'rpm':
        // Realistische RPM: 800-3500 mit Oszillation
        _currentValues[key] = 1200.0 + (sineWave * 1800) + (smallNoise * 100);
        break;
        
      case 'temperature':
        // Kühlmittel: ca. 90°C im Betrieb, sehr stabil
        _currentValues[key] = 88.0 + (smallNoise * 4);
        break;
        
      case 'speed':
        // Geschwindigkeit: 0-120 km/h mit realistischen Änderungen
        _currentValues[key] = 25.0 + (sineWave * 80) + (smallNoise * 10);
        break;
        
      case 'lambda_bank1_s1':
      case 'lambda_bank1_s2':
        // Lambda: ideal bei 1.0, kleine Schwankungen ±0.03
        _currentValues[key] = 0.98 + (smallNoise * 0.04);
        break;
        
      case 'air_intake_temp':
        // Ansauglufttemperatur: ca. 30-50°C
        _currentValues[key] = 35.0 + (sineWave * 10) + (smallNoise * 5);
        break;
        
      case 'throttle_position':
        // Drosselklappe: 0-100%, folgt Motor-Last
        _currentValues[key] = (sineWave * 60) + (smallNoise * 15);
        break;
        
      case 'engine_load':
        // Motor-Last: 0-100%, folgt Drehzahl
        _currentValues[key] = (sineWave * 50) + 15 + (smallNoise * 10);
        break;
        
      case 'fuel_trim_short':
        // Short-Term Fuel Trim: -5 bis +5% (normal ist ~0%)
        _currentValues[key] = -2.0 + (smallNoise * 4);
        break;
        
      case 'fuel_trim_long':
        // Long-Term Fuel Trim: -5 bis +5%
        _currentValues[key] = 1.0 + (smallNoise * 2);
        break;
        
      case 'ignition_advance':
        // Zündzeitpunkt: ca. 10-35°
        _currentValues[key] = 15.0 + (sineWave * 12) + (smallNoise * 2);
        break;
        
      case 'manifold_pressure':
        // Ansaugkrümmerdruck: 30-95 kPa (abhängig von Last)
        _currentValues[key] = 45.0 + (sineWave * 35) + (smallNoise * 5);
        break;
    }
  }

  void _updateLiveDataList() {
    final t = AppLocalizations.of(context);
    
    _liveDataList = [
      // Motor-Parameter (kritisch)
      _buildLiveDataItem(
        t.tr('live_data.engine_rpm'),
        _currentValues['rpm']?.toStringAsFixed(0) ?? '0',
        'RPM',
        _checkRpmStatus(_currentValues['rpm']),
        isAlert: _currentValues['rpm'] > 3000,
      ),
      _buildLiveDataItem(
        t.tr('live_data.coolant_temperature'),
        _currentValues['temperature']?.toStringAsFixed(1) ?? '0',
        '°C',
        _checkTempStatus(_currentValues['temperature']),
      ),
      _buildLiveDataItem(
        t.tr('live_data.vehicle_speed'),
        _currentValues['speed']?.toStringAsFixed(1) ?? '0',
        'km/h',
        Colors.green,
      ),
      _buildLiveDataItem(
        t.tr('live_data.engine_load'),
        _currentValues['engine_load']?.toStringAsFixed(1) ?? '0',
        '%',
        Colors.blue,
      ),

      // Lambdawerte (sehr wichtig für Diagnose)
      _buildLiveDataItem(
        t.tr('live_data.lambda_bank1_sensor1'),
        _currentValues['lambda_bank1_s1']?.toStringAsFixed(3) ?? '0',
        'λ',
        _checkLambdaStatus(_currentValues['lambda_bank1_s1']),
        isAlert: _checkLambdaAlert(_currentValues['lambda_bank1_s1']),
      ),
      _buildLiveDataItem(
        t.tr('live_data.lambda_bank1_sensor2'),
        _currentValues['lambda_bank1_s2']?.toStringAsFixed(3) ?? '0',
        'λ',
        _checkLambdaStatus(_currentValues['lambda_bank1_s2']),
        isAlert: _checkLambdaAlert(_currentValues['lambda_bank1_s2']),
      ),

      // Luft- und Kraftstoffsystem
      _buildLiveDataItem(
        'Ansauglufttemperatur',
        _currentValues['air_intake_temp']?.toStringAsFixed(0) ?? '0',
        '°C',
        Colors.blue,
      ),
      _buildLiveDataItem(
        'Drosselklappenposition',
        _currentValues['throttle_position']?.toStringAsFixed(1) ?? '0',
        '%',
        Colors.green,
      ),
      _buildLiveDataItem(
        'Kraftstoff-Trim (Kurz)',
        _currentValues['fuel_trim_short']?.toStringAsFixed(1) ?? '0',
        '%',
        _checkFuelTrimStatus(_currentValues['fuel_trim_short']),
        isAlert: (_currentValues['fuel_trim_short'] as num).abs() > 10,
      ),
      _buildLiveDataItem(
        'Kraftstoff-Trim (Lang)',
        _currentValues['fuel_trim_long']?.toStringAsFixed(1) ?? '0',
        '%',
        _checkFuelTrimStatus(_currentValues['fuel_trim_long']),
        isAlert: (_currentValues['fuel_trim_long'] as num).abs() > 10,
      ),

      // Zündsystem
      _buildLiveDataItem(
        'Zündzeitpunkt',
        _currentValues['ignition_advance']?.toStringAsFixed(1) ?? '0',
        '°',
        Colors.green,
      ),
      _buildLiveDataItem(
        'Ansaugkrümmerdruck',
        _currentValues['manifold_pressure']?.toStringAsFixed(0) ?? '0',
        'kPa',
        Colors.blue,
      ),
    ];

    setState(() {});
  }

  LiveDataScreenData _buildLiveDataItem(
    String name,
    String value,
    String unit,
    Color statusColor, {
    bool isAlert = false,
  }) {
    return LiveDataScreenData(
      parameterName: name,
      value: value,
      unit: unit,
      statusColor: statusColor,
      isAlert: isAlert,
    );
  }

  Color _checkRpmStatus(dynamic rpm) {
    final rpmVal = (rpm ?? 0) as num;
    if (rpmVal > 3000) return const Color(0xFFE53935); // Zu hoch
    if (rpmVal < 500) return const Color(0xFFF57C00); // Zu niedrig
    return const Color(0xFF4CAF50); // Normal
  }

  Color _checkTempStatus(dynamic temp) {
    final tempVal = (temp ?? 0) as num;
    if (tempVal > 110) return const Color(0xFFE53935); // Zu heiss
    if (tempVal < 70) return const Color(0xFF4CAF50); // Noch nicht warm
    return const Color(0xFF4CAF50); // Optimal
  }

  bool _checkLambdaAlert(dynamic value) {
    final val = (value ?? 1.0) as num;
    return val < 0.90 || val > 1.10; // Warnung wenn zu fett/mager
  }

  Color _checkLambdaStatus(dynamic value) {
    final val = (value ?? 1.0) as num;
    if (val < 0.90 || val > 1.10) return const Color(0xFFE53935); // Kritisch
    if (val < 0.95 || val > 1.05) return const Color(0xFFF57C00); // Warnung
    return const Color(0xFF4CAF50); // Optimal
  }

  Color _checkFuelTrimStatus(dynamic value) {
    final val = (value ?? 0) as num;
    if (val.abs() > 15) return const Color(0xFFE53935); // Zu stark korrigiert
    if (val.abs() > 10) return const Color(0xFFF57C00); // Warnung
    return const Color(0xFF4CAF50); // Normal
  }

  void _stopStreaming() {
    setState(() => _isStreaming = false);
  }

  @override
  void dispose() {
    _stopStreaming();
    _obd2Service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context);

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
          'Live Daten',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isStreaming
                      ? const Color(0xFF4CAF50).withOpacity(0.2)
                      : const Color(0xFFE53935).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isStreaming
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isStreaming
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isStreaming ? 'Live' : 'Offline',
                      style: TextStyle(
                        color: _isStreaming
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _connectionStatus != null
              ? _buildConnectionErrorView()
              : _buildLiveDataView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB129)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Verbinde mit OBD2-Adapter...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.bluetooth_disabled,
              color: Color(0xFFE53935),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Keine Verbindung',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _connectionStatus ?? 'OBD2-Adapter nicht verbunden',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Bluetooth-Verbindungs-Button
          SizedBox(
            width: 280,
            child: ElevatedButton.icon(
              onPressed: () => _showBluetoothDialog(),
              icon: const Icon(Icons.bluetooth),
              label: const Text('Mit Adapter verbinden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Zurück-Button
          SizedBox(
            width: 280,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFB129),
                side: const BorderSide(color: Color(0xFFFFB129)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Zurück',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Zeige Bluetooth-Scan-Dialog zum Verbinden mit Adapter
  void _showBluetoothDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151C23),
        title: const Text(
          'OBD2-Adapter suchen',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 20),
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB129)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Suche nach OBD2-Adaptern...',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      // Starte Bluetooth-Scan nach Adaptern
      // Dies sollte den gleichen Flow wie error_codes_list_screen verwenden
      final obd2Service = Obd2Service();
      
      // Suche nach verfügbaren Adaptern
      await for (final devices in obd2Service.scanForDevices(timeout: const Duration(seconds: 10))) {
        if (devices.isNotEmpty && mounted) {
          // Finde OBD2-Adapter
          for (final device in devices) {
            final name = device.platformName.toLowerCase();
            if (name.contains('obd') || name.contains('elm') || name.contains('vlink')) {
              // Versuche zu verbinden
              if (mounted) Navigator.pop(context); // Schließe Loading-Dialog
              
              final connected = await obd2Service.connect(device);
              if (connected && mounted) {
                // Verbindung erfolgreich! Versuche neu zu initialisieren
                setState(() {
                  _isLoading = true;
                  _connectionStatus = null;
                });
                await _initializeConnection();
              } else if (mounted) {
                // Verbindung fehlgeschlagen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verbindung zu Adapter fehlgeschlagen'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }
        }
      }
      
      // Kein Adapter gefunden
      if (mounted) {
        Navigator.pop(context); // Schließe Loading-Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kein OBD2-Adapter gefunden'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLiveDataView() {
    final t = AppLocalizations.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demo-Modus Hinweis
          if (_isDemoMode)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo-Modus: Diese Daten werden simuliert.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Hinweis für Benutzer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB129).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFB129).withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFFFB129),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Diese Daten werden alle 200ms aktualisiert. Lambda-Werte sollten um 1.0 liegen.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kritische Parameter (oben)
          Text(
            t.tr('live_data.critical_parameters'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._liveDataList
              .where((item) =>
                  item.parameterName.contains('Drehzahl') ||
                  item.parameterName.contains('Temperatur') ||
                  item.parameterName.contains('Lambda'))
              .map((item) => _buildDataCard(item))
              .toList(),

          const SizedBox(height: 24),

          // Weitere Parameter
          Text(
            t.tr('live_data.additional_parameters'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._liveDataList
              .where((item) =>
                  !item.parameterName.contains('Drehzahl') &&
                  !item.parameterName.contains('Temperatur') &&
                  !item.parameterName.contains('Lambda'))
              .map((item) => _buildDataCard(item))
              .toList(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDataCard(LiveDataScreenData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.statusColor.withOpacity(0.3),
          width: data.isAlert ? 2 : 1,
        ),
        boxShadow: data.isAlert
            ? [
                BoxShadow(
                  color: data.statusColor.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Status Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.statusColor,
              boxShadow: [
                BoxShadow(
                  color: data.statusColor.withOpacity(0.5),
                  blurRadius: 4,
                )
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Parameter Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.parameterName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Value + Unit
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    data.value,
                    style: TextStyle(
                      color: data.statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.unit,
                    style: TextStyle(
                      color: data.statusColor.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
