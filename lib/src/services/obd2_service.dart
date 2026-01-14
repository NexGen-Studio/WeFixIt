import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/obd_error_code.dart';

class Obd2Service {
  static final Obd2Service _instance = Obd2Service._internal();
  factory Obd2Service() => _instance;
  Obd2Service._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription? _dataSubscription;
  
  final _responseController = StreamController<String>.broadcast();
  String _buffer = '';
  
  bool get isConnected => _connectedDevice != null;

  /// Scanne nach verfügbaren OBD2-Adaptern
  Stream<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async* {
    final devices = <BluetoothDevice>[];
    
    try {
      // Bluetooth einschalten (falls möglich)
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth wird auf diesem Gerät nicht unterstützt');
      }

      // Scan starten
      await FlutterBluePlus.startScan(timeout: timeout);
      
      // Scan-Ergebnisse streamen
      await for (final results in FlutterBluePlus.scanResults) {
        for (var result in results) {
          // Filtere OBD2-Adapter (typische Namen: OBDII, ELM327, OBD, etc.)
          final name = result.device.platformName.toLowerCase();
          if (name.contains('obd') || name.contains('elm') || name.contains('vlink')) {
            if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
              devices.add(result.device);
            }
          }
        }
        yield devices;
      }
    } catch (e) {
      print('❌ Fehler beim Scannen: $e');
      rethrow;
    } finally {
      await FlutterBluePlus.stopScan();
    }
  }

  /// Verbinde mit OBD2-Adapter
  Future<bool> connect(BluetoothDevice device) async {
    try {
      print('🔄 Verbinde mit ${device.platformName}...');
      
      // Disconnect falls bereits verbunden
      if (_connectedDevice != null) {
        await disconnect();
      }

      // Verbinden
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Services entdecken
      List<BluetoothService> services = await device.discoverServices();
      
      // Suche nach Serial Port Profile (SPP) Service
      // UUID: 00001101-0000-1000-8000-00805F9B34FB (klassisches SPP)
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Write-Characteristic
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
          // Notify-Characteristic
          if (characteristic.properties.notify) {
            _notifyCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
            
            // Daten empfangen
            _dataSubscription = characteristic.lastValueStream.listen((data) {
              _handleIncomingData(data);
            });
          }
        }
      }

      if (_writeCharacteristic == null) {
        throw Exception('Keine Write-Characteristic gefunden');
      }

      // ELM327 initialisieren
      await _initializeElm327();
      
      print('✅ Verbunden mit ${device.platformName}');
      return true;
    } catch (e) {
      print('❌ Verbindungsfehler: $e');
      await disconnect();
      return false;
    }
  }

  /// ELM327 Adapter initialisieren
  Future<void> _initializeElm327() async {
    // Reset
    await _sendCommand('ATZ');
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Echo aus
    await _sendCommand('ATE0');
    
    // Leerzeichen aus
    await _sendCommand('ATS0');
    
    // Headers aus
    await _sendCommand('ATH0');
    
    // Automatisches Protokoll
    await _sendCommand('ATSP0');
  }

  /// Sende AT-Command an ELM327
  Future<String?> _sendCommand(String command, {Duration timeout = const Duration(seconds: 3)}) async {
    if (_writeCharacteristic == null) {
      throw Exception('Nicht verbunden');
    }

    try {
      _buffer = ''; // Buffer leeren
      
      // Command senden (mit \r am Ende für ELM327)
      final data = utf8.encode('$command\r');
      await _writeCharacteristic!.write(data, withoutResponse: false);
      
      // Auf Antwort warten
      final response = await _responseController.stream
          .timeout(timeout, onTimeout: (sink) => sink.add('TIMEOUT'))
          .first;
      
      return response != 'TIMEOUT' ? response : null;
    } catch (e) {
      print('❌ Command-Fehler: $e');
      return null;
    }
  }

  /// Verarbeite eingehende Daten
  void _handleIncomingData(List<int> data) {
    final text = utf8.decode(data);
    _buffer += text;
    
    // Prüfe auf Prompt-Zeichen (>)
    if (_buffer.contains('>')) {
      // Antwort ist komplett
      final response = _buffer.replaceAll('>', '').trim();
      _buffer = '';
      _responseController.add(response);
    }
  }

  /// Lese alle Fehlercodes (DTC)
  Future<List<RawObdCode>> readErrorCodes() async {
    try {
      print('🔍 Lese Fehlercodes...');
      
      // Lese gespeicherte DTCs (Mode 03)
      final response = await _sendCommand('03');
      
      if (response == null || response.contains('NO DATA')) {
        print('✅ Keine Fehlercodes gefunden');
        return [];
      }

      // Parse DTCs
      final codes = _parseDtcResponse(response);
      print('✅ ${codes.length} Fehlercodes gefunden: ${codes.map((c) => c.code).join(', ')}');
      
      return codes;
    } catch (e) {
      print('❌ Fehler beim Auslesen: $e');
      rethrow;
    }
  }

  /// Parse DTC-Antwort von ELM327
  List<RawObdCode> _parseDtcResponse(String response) {
    final codes = <RawObdCode>[];
    
    // Entferne Whitespaces und Zeilenumbrüche
    final cleaned = response.replaceAll(RegExp(r'\s+'), '');
    
    // DTC-Format: 2 Bytes pro Code (z.B. 43 01 33 -> P0133)
    // Erste Byte: 43 bedeutet "3 Codes folgen"
    // Dann 2 Bytes pro Code
    
    // Einfache Regex für P-Codes (Powertrain)
    final regex = RegExp(r'[0-9A-F]{4}');
    final matches = regex.allMatches(cleaned);
    
    for (var match in matches) {
      final hex = match.group(0)!;
      if (hex == '0000') continue; // Skip empty codes
      
      // Konvertiere HEX zu DTC-Code
      final code = _hexToDtc(hex);
      if (code != null) {
        codes.add(RawObdCode(code: code));
      }
    }
    
    return codes;
  }

  /// Konvertiere HEX zu DTC-Code (z.B. 0133 -> P0133)
  String? _hexToDtc(String hex) {
    if (hex.length != 4) return null;
    
    // Ersten 2 Bits bestimmen den Code-Typ
    final firstByte = int.parse(hex.substring(0, 2), radix: 16);
    final secondByte = hex.substring(2, 4);
    
    // Bestimme Präfix (P, C, B, U)
    String prefix;
    int highNibble = (firstByte >> 6) & 0x03;
    int lowNibble = (firstByte >> 4) & 0x03;
    
    switch (highNibble) {
      case 0:
        prefix = 'P0'; // Powertrain SAE
        break;
      case 1:
        prefix = 'P1'; // Powertrain Manufacturer
        break;
      case 2:
        prefix = 'C0'; // Chassis
        break;
      case 3:
        prefix = 'B0'; // Body
        break;
      default:
        prefix = 'U0'; // Network
    }
    
    // Kombiniere mit restlichen Digits
    final lastDigit = (firstByte & 0x0F).toRadixString(16).toUpperCase();
    return '$prefix$lastDigit$secondByte';
  }

  /// Lösche einen einzelnen Fehlercode
  /// Hinweis: Manche OBD2-Adapter unterstützen nur das Löschen aller Codes
  Future<bool> clearSingleErrorCode(String code) async {
    try {
      print('🗑️ Lösche Fehlercode $code...');
      
      // WICHTIG: Die meisten OBD2-Adapter (ELM327) unterstützen NICHT das Löschen einzelner Codes!
      // Es gibt nur Mode 04, der ALLE Codes löscht.
      // Als Workaround: Nutzer informieren und alle Codes löschen
      
      // Für spätere Implementierung könnte man hier prüfen ob der Adapter
      // erweiterte Funktionen unterstützt
      
      print('⚠️ Hinweis: Die meisten OBD2-Adapter können nur alle Codes gleichzeitig löschen');
      print('ℹ️ Lösche alle Fehlercodes (inkl. $code)...');
      
      return await clearErrorCodes();
    } catch (e) {
      print('❌ Fehler beim Löschen von $code: $e');
      return false;
    }
  }

  /// Lösche alle Fehlercodes
  Future<bool> clearErrorCodes() async {
    try {
      print('🗑️ Lösche Fehlercodes...');
      
      // Mode 04: Clear DTCs
      final response = await _sendCommand('04');
      
      if (response == null) {
        return false;
      }
      
      print('✅ Fehlercodes gelöscht');
      return true;
    } catch (e) {
      print('❌ Fehler beim Löschen: $e');
      return false;
    }
  }

  /// Trenne Verbindung
  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
      
      _writeCharacteristic = null;
      _notifyCharacteristic = null;
      _buffer = '';
      
      print('🔌 Verbindung getrennt');
    } catch (e) {
      print('❌ Disconnect-Fehler: $e');
    }
  }

  void dispose() {
    disconnect();
    _responseController.close();
  }
}
