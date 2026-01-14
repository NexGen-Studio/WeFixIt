import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/obd_error_code.dart';

class ErrorCodeDescriptionService {
  final _supabase = Supabase.instance.client;

  /// Hole Beschreibung für Fehlercode (DB oder Web-Suche)
  Future<ObdErrorCode?> getDescription(String code) async {
    try {
      // 1. Versuche aus DB zu laden
      final dbResult = await _supabase
          .from('obd_error_codes')
          .select()
          .eq('code', code)
          .maybeSingle();

      if (dbResult != null) {
        return ObdErrorCode.fromJson(dbResult);
      }

      // 2. Falls nicht in DB: Web-Suche
      print('🔍 Code $code nicht in DB gefunden, starte Web-Suche...');
      final webResult = await _searchCodeOnWeb(code);
      
      if (webResult != null) {
        // 3. In DB speichern
        await _saveToDatabase(webResult);
        return webResult;
      }

      return null;
    } catch (e) {
      print('❌ Fehler beim Laden der Beschreibung: $e');
      return null;
    }
  }

  /// Suche Fehlercode im Web (vereinfachte Version)
  Future<ObdErrorCode?> _searchCodeOnWeb(String code) async {
    try {
      // Hier würde normalerweise eine richtige API-Anfrage stattfinden
      // z.B. zu einer OBD2-Datenbank API
      // Für jetzt: Fallback mit generischer Beschreibung
      
      final codeType = _getCodeType(code);
      final description = _generateGenericDescription(code, codeType);
      
      return ObdErrorCode(
        code: code,
        description: description,
        descriptionDe: description,
        codeType: codeType,
        isGeneric: true,
        severity: 'medium',
        driveSafety: true,
        immediateActionRequired: false,
      );
    } catch (e) {
      print('❌ Web-Suche fehlgeschlagen: $e');
      return null;
    }
  }

  /// Speichere Fehlercode in Datenbank
  Future<void> _saveToDatabase(ObdErrorCode code) async {
    try {
      await _supabase.from('obd_error_codes').upsert(code.toJson());
      print('✅ Code ${code.code} in DB gespeichert');
    } catch (e) {
      print('❌ Fehler beim Speichern in DB: $e');
    }
  }

  String _getCodeType(String code) {
    if (code.startsWith('P')) return 'Powertrain';
    if (code.startsWith('C')) return 'Chassis';
    if (code.startsWith('B')) return 'Body';
    if (code.startsWith('U')) return 'Network';
    return 'Unknown';
  }

  String _generateGenericDescription(String code, String type) {
    // Generiere eine einfache Beschreibung basierend auf Code-Typ
    switch (type) {
      case 'Powertrain':
        return 'Antriebsstrang-Fehler: Motor, Getriebe oder Abgas-System';
      case 'Chassis':
        return 'Fahrwerk-Fehler: ABS, ESP oder Lenkung';
      case 'Body':
        return 'Karosserie-Fehler: Airbag, Klimaanlage oder Komfort-Systeme';
      case 'Network':
        return 'Kommunikations-Fehler: CAN-Bus oder Netzwerk';
      default:
        return 'Unbekannter Fehlercode';
    }
  }

  /// Batch-Laden mehrerer Codes
  Future<Map<String, ObdErrorCode?>> getMultipleDescriptions(List<String> codes) async {
    final results = <String, ObdErrorCode?>{};
    
    for (var code in codes) {
      results[code] = await getDescription(code);
    }
    
    return results;
  }
}
