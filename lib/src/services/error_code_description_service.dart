import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/obd_error_code.dart';
import '../state/locale_provider.dart';
import 'dart:convert';

class ErrorCodeDescriptionService {
  final _supabase = Supabase.instance.client;

  /// Hole Beschreibung für Fehlercode (3-Szenario-Flow)
  Future<ObdErrorCode?> getDescription(String code) async {
    try {
      // 1. Prüfe DB SOFORT (await) - exakte topic query!
      final dbResult = await _supabase
          .from('automotive_knowledge')
          .select('*, repair_guides')
          .eq('category', 'fehlercode')
          .eq('topic', '$code OBD2 diagnostic trouble code')
          .maybeSingle();

      // ===== SZENARIO C: Code komplett in DB =====
      if (dbResult != null && _hasRepairGuides(dbResult)) {
        print('✅ SZENARIO C: $code komplett in DB (keine API-Calls)');
        
        // Auto-Enrichment: Prüfe ob vehicle_specific fehlt
        _checkAndEnrichVehicleSpecific(code, dbResult);
        
        return _mapFromAutomotiveKnowledge(dbResult, code);
      }

      // ===== SZENARIO B: Code in DB, ABER KEINE Anleitung =====
      if (dbResult != null && !_hasRepairGuides(dbResult)) {
        print('⚡ SZENARIO B: $code in DB ohne Anleitungen');
        
        // Auto-Enrichment: Prüfe ob vehicle_specific fehlt
        _checkAndEnrichVehicleSpecific(code, dbResult);
        
        // User sieht sofort DB-Daten
        // fill-repair-guides wird nach OBD2-Scan in error_codes_list_screen.dart aufgerufen
        return _mapFromAutomotiveKnowledge(dbResult, code);
      }

      // ===== SZENARIO A: Code NICHT in DB =====
      print('🚀 SZENARIO A: $code nicht in DB, starte Quick GPT');
      final quickResult = await _getQuickGptResponse(code);
      
      // Trigger Background Enrichment (fire & forget)
      _triggerFullEnrichment(code);
      
      return quickResult;
    } catch (e) {
      print('❌ Fehler beim Laden der Beschreibung: $e');
      return null;
    }
  }

  /// Prüfe ob repair_guides vorhanden sind
  bool _hasRepairGuides(Map<String, dynamic> dbResult) {
    final guides = dbResult['repair_guides'] as Map<String, dynamic>?;
    return guides != null && guides.isNotEmpty;
  }

  /// SZENARIO A: Quick GPT Response (nicht in DB speichern)
  Future<ObdErrorCode?> _getQuickGptResponse(String code) async {
    try {
      print('📞 Rufe GPT für Quick Response...');
      final vehicle = await _getVehicleData();
      
      final response = await _supabase.functions.invoke(
        'enrich-error-code',
        body: {
          'code': code,
          'phase': 'quick',
          if (vehicle != null) 'vehicle': vehicle,
        },
      );

      if (response.data == null || response.data['success'] != true) {
        print('❌ GPT Quick Response fehlgeschlagen');
        return null;
      }

      final data = response.data['data'];
      
      // Background-Enrichment wird bereits in Zeile 46 getriggert!
      // KEIN DUPLICATE CALL HIER!
      
      // Auto-Enrichment wird bereits in Zeile 46 getriggert!
      // KEIN DUPLICATE CALL HIER!
      
      return ObdErrorCode(
        code: code,
        codeType: _getCodeType(code),
        titleDe: data['title_de'] as String?,
        titleEn: data['title_en'] as String?,
        descriptionDe: data['content_de'] as String?,
        descriptionEn: data['content_en'] as String?,
        symptoms: (data['symptoms'] as List<dynamic>?)?.cast<String>(),
        commonCauses: (data['causes'] as List<dynamic>?)?.cast<String>(),
        repairSuggestions: (data['repair_steps'] as List<dynamic>?)?.cast<String>(),
        isGeneric: false,
      );
    } catch (e) {
      print('❌ Quick GPT fehlgeschlagen: $e');
      return null;
    }
  }

  /// SZENARIO A: Trigger Full Enrichment (Perplexity + GPT + DB Save)
  void _triggerFullEnrichment(String code) async {
    print('🔄 Background: Starte Full Enrichment für $code');
    final vehicle = await _getVehicleData();
    
    _supabase.functions.invoke(
      'enrich-error-code',
      body: {
        'code': code,
        'phase': 'enrich',
        if (vehicle != null) 'vehicle': vehicle,
      },
    ).then((response) {
      if (response.data?['success'] == true) {
        print('✅ Background: $code enriched');
      }
    }).catchError((error) {
      print('⚠️ Background Enrichment Fehler: $error');
    });
  }

  /// Lade Fahrzeugdaten aus Profil (falls User Freigabe erteilt hat)
  Future<Map<String, dynamic>?> _getVehicleData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      final vehicleData = await _supabase
        .from('vehicles')
        .select('make, model, year, engine_code, displacement_cc, power_kw, mileage_km, share_vehicle_data_with_ai')
        .eq('user_id', userId)
        .maybeSingle();
      
      if (vehicleData == null) return null;
      
      // Prüfe ob User Datenfreigabe aktiviert hat
      final shareWithAI = (vehicleData['share_vehicle_data_with_ai'] as bool?) ?? true;
      
      if (!shareWithAI) {
        print('⚠️ User hat Fahrzeugdaten-Freigabe deaktiviert');
        return null;
      }
      
      // Konvertiere zu Edge Function Format
      return {
        'make': vehicleData['make'] as String?,
        'model': vehicleData['model'] as String?,
        'year': vehicleData['year'] as int?,
        'engine': _formatEngine(vehicleData),
        'mileage': vehicleData['mileage_km'] as int?,
      };
    } catch (e) {
      print('⚠️ Fehler beim Laden der Fahrzeugdaten: $e');
      return null;
    }
  }
  
  /// Formatiere Engine-String (z.B. "2.0L Diesel")
  String? _formatEngine(Map<String, dynamic> vehicle) {
    final cc = vehicle['displacement_cc'] as int?;
    final code = vehicle['engine_code'] as String?;
    
    if (cc == null && code == null) return null;
    
    final liters = cc != null ? (cc / 1000).toStringAsFixed(1) : null;
    return [if (liters != null) '${liters}L', code].where((e) => e != null).join(' ');
  }

  /// Auto-Enrichment: Prüfe ob vehicle_specific UND vehicle_specific_en für aktuelles Fahrzeug fehlt
  void _checkAndEnrichVehicleSpecific(String code, Map<String, dynamic> dbResult) async {
    try {
      final vehicle = await _getVehicleData();
      if (vehicle == null) return; // Keine Fahrzeugdaten oder Freigabe deaktiviert
      
      final vehicleSpecificDE = dbResult['vehicle_specific'] as Map<String, dynamic>?;
      final vehicleSpecificEN = dbResult['vehicle_specific_en'] as Map<String, dynamic>?;
      final vehicleKey = '${vehicle['make']}_${vehicle['model']}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      
      // Prüfe ob BEIDE Sprachen bereits vorhanden sind
      final hasDE = vehicleSpecificDE != null && vehicleSpecificDE.containsKey(vehicleKey);
      final hasEN = vehicleSpecificEN != null && vehicleSpecificEN.containsKey(vehicleKey);
      
      if (hasDE && hasEN) {
        print('✅ Vehicle-specific für $vehicleKey bereits vorhanden (DE+EN)');
        return;
      }
      
      if (!hasDE) {
        print('🔄 Auto-Enrichment: Lade vehicle_specific (DE) für $code ($vehicleKey)');
      }
      if (!hasEN) {
        print('🔄 Auto-Enrichment: Lade vehicle_specific_en (EN) für $code ($vehicleKey)');
      }
      
      // Trigger Edge Function - generiert automatisch fehlende Sprachen
      _supabase.functions.invoke(
        'enrich-vehicle-specific',
        body: {
          'code': code,
          'vehicle': vehicle,
        },
      ).then((response) {
        if (response.data?['success'] == true) {
          final generated = response.data?['generated'] as Map<String, dynamic>?;
          if (generated != null) {
            final genDE = generated['de'] == true;
            final genEN = generated['en'] == true;
            print('✅ Vehicle-specific für $vehicleKey hinzugefügt (DE=$genDE, EN=$genEN)');
          } else {
            print('✅ Vehicle-specific für $vehicleKey hinzugefügt');
          }
        }
      }).catchError((error) {
        print('⚠️ Auto-Enrichment Fehler: $error');
      });
    } catch (e) {
      print('⚠️ Fehler beim Auto-Enrichment: $e');
    }
  }

  /// DEPRECATED: Speicherung erfolgt jetzt durch Phase 2 der Edge Function
  /// Diese Methode wird nicht mehr verwendet, da die Edge Function
  /// nach Perplexity-Recherche die vollständigen Daten speichert
  @Deprecated('Use Edge Function Phase 2 instead')
  Future<void> _saveToDatabase(ObdErrorCode code) async {
    // Nicht mehr verwendet - Edge Function übernimmt Speicherung
  }

  /// Mappe automotive_knowledge Daten auf ObdErrorCode Model
  ObdErrorCode _mapFromAutomotiveKnowledge(Map<String, dynamic> data, String code) {
    // Prüfe App-Sprache: Wenn EN, nutze _en Spalten
    final isEnglish = currentLanguageCode == 'en';
    
    return ObdErrorCode(
      code: code,
      codeType: _getCodeType(code),
      titleDe: data['title_de'] as String?,
      titleEn: data['title_en'] as String?,
      descriptionDe: data['content_de'] as String?,
      descriptionEn: data['content_en'] as String?,
      symptoms: isEnglish 
        ? (data['symptoms_en'] as List<dynamic>?)?.cast<String>()
        : (data['symptoms'] as List<dynamic>?)?.cast<String>(),
      commonCauses: isEnglish
        ? (data['causes_en'] as List<dynamic>?)?.cast<String>()
        : (data['causes'] as List<dynamic>?)?.cast<String>(),
      diagnosticSteps: (data['diagnostic_steps'] as List<dynamic>?)?.cast<String>(),
      repairSuggestions: (data['repair_steps'] as List<dynamic>?)?.cast<String>(),
      typicalCostRange: data['estimated_cost_eur']?.toString(),
      vehicleSpecificIssues: _extractVehicleSpecificIssues(data),
      isGeneric: false,
    );
  }

  /// Extrahiere vehicle_specific Daten für aktuelles Fahrzeug
  List<String>? _extractVehicleSpecificIssues(Map<String, dynamic> data) {
    final vehicleSpecific = data['vehicle_specific'] as Map<String, dynamic>?;
    if (vehicleSpecific == null || vehicleSpecific.isEmpty) return null;

    // Hole Fahrzeugdaten synchron aus Cache (wurde bereits in _checkAndEnrichVehicleSpecific geladen)
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    // Versuche vehicle_specific für alle möglichen Fahrzeugvarianten zu finden
    // Da wir nicht async sind, nehmen wir die erste gefundene
    for (var entry in vehicleSpecific.entries) {
      final vehicleData = entry.value as Map<String, dynamic>?;
      if (vehicleData == null) continue;

      final issues = vehicleData['issues'] as List<dynamic>?;
      if (issues != null && issues.isNotEmpty) {
        return issues.cast<String>();
      }
    }

    return null;
  }

  String _getCodeType(String code) {
    if (code.startsWith('P')) return 'Powertrain';
    if (code.startsWith('C')) return 'Chassis';
    if (code.startsWith('B')) return 'Body';
    if (code.startsWith('U')) return 'Network';
    return 'Unknown';
  }

  String _generateGenericTitle(String code, String codeType) {
    // Kurzer Titel (max 3-4 Wörter) basierend auf Code-Muster
    // Bekannte Code-Muster
    if (code.startsWith('P04')) return '$code Katalysator';
    if (code.startsWith('P01')) return '$code Gemisch';
    if (code.startsWith('P02')) return '$code Einspritzung';
    if (code.startsWith('P03')) return '$code Zündung';
    if (code.startsWith('P00')) return '$code Sensor';
    if (code.startsWith('C0')) return '$code Fahrwerk';
    if (code.startsWith('B0')) return '$code Karosserie';
    if (code.startsWith('U0')) return '$code Netzwerk';
    
    // Fallback nach Typ
    switch (codeType) {
      case 'Powertrain':
        return '$code Motor';
      case 'Chassis':
        return '$code Fahrwerk';
      case 'Body':
        return '$code Karosserie';
      case 'Network':
        return '$code Netzwerk';
      default:
        return '$code Unbekannt';
    }
  }

  String _generateGenericDescription(String code, String codeType) {
    // Längere Beschreibung für Details
    switch (codeType) {
      case 'Powertrain':
        return 'Ein Fehler im Antriebsstrang (Motor, Getriebe) wurde erkannt.';
      case 'Chassis':
        return 'Ein Fehler im Fahrwerk (ABS, ESP, Lenkung) wurde erkannt.';
      case 'Body':
        return 'Ein Fehler in der Karosserie-Elektronik wurde erkannt.';
      case 'Network':
        return 'Ein Fehler im Netzwerk/CAN-Bus wurde erkannt.';
      default:
        return 'Ein unbekannter Fehlercode wurde erkannt.';
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

  /// Hole kurzen Titel für Listen-Anzeige (max 3 Wörter)
  /// Bevorzugt title aus DB, sonst Fallback-Generierung
  String getShortDescription(String code, ObdErrorCode? fullDescription) {
    final isEnglish = currentLanguageCode == 'en';
    
    // 1. Priorität: title aus DB (EN oder DE)
    final title = isEnglish ? fullDescription?.titleEn : fullDescription?.titleDe;
    if (title != null && title.isNotEmpty) {
      return title;
    }

    // 2. Fallback: Erste 3 Wörter der Beschreibung
    final description = isEnglish ? fullDescription?.descriptionEn : fullDescription?.descriptionDe;
    if (description != null && description.isNotEmpty) {
      final words = description.split(' ');
      if (words.length <= 3) {
        return description;
      }
      return words.take(3).join(' ');
    }

    // 3. Letzter Fallback: Generischer Titel basierend auf Code-Typ
    final codeType = _getCodeType(code);
    return _generateGenericTitle(code, codeType);
  }
}
