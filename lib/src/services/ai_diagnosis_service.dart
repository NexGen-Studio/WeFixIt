import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/obd_error_code.dart';
import '../models/ai_diagnosis_models.dart';
import 'error_logging_service.dart';

class AiDiagnosisService {
  final _supabase = Supabase.instance.client;
  final _errorLogger = ErrorLoggingService();

  /// Analysiere einen einzelnen Fehlercode mit KI (Demo-Modus - nur Demo-Daten)
  Future<AiDiagnosis> analyzeSingleCodeDemo(
    String code,
    ObdErrorCode? basicDescription,
  ) async {
    // Im Demo-Modus: Keine API Calls, nur Demo-Daten
    await Future.delayed(const Duration(seconds: 2)); // Simuliere Analyse
    return _generateDemoAnalysis(code, basicDescription);
  }

  /// Analysiere einen einzelnen Fehlercode mit KI (Production)
  Future<AiDiagnosis> analyzeSingleCode(
    String code,
    ObdErrorCode? basicDescription,
  ) async {
    try {
      // Call bestehende Supabase Edge Function (analyze-obd-codes)
      // Diese nutzt: DB-Suche → Perplexity Web-Recherche → GPT-4 Fallback
      final response = await _supabase.functions.invoke(
        'analyze-obd-codes',
        body: {
          'errorCodes': [
            {
              'code': code,
              'readAt': DateTime.now().toIso8601String(),
            }
          ],
          'language': 'de',
        },
      );

      if (response.data == null) {
        throw Exception('Die KI-Analyse ist momentan nicht verfügbar. Bitte versuche es später erneut.');
      }

      final data = response.data as Map<String, dynamic>;
      
      // Edge Function gibt Array zurück, wir nehmen das erste Ergebnis
      if (data['results'] != null && (data['results'] as List).isNotEmpty) {
        final result = (data['results'] as List)[0] as Map<String, dynamic>;
        return _mapEdgeFunctionResultToDiagnosis(result, code, basicDescription);
      }

      // Keine Ergebnisse - Fehler werfen
      throw Exception('Für den Fehlercode $code konnte keine Analyse erstellt werden. Bitte kontaktiere den Support.');
    } catch (e, stackTrace) {
      // Logge Fehler in Supabase für Monitoring
      await _errorLogger.logAiDiagnosisError(
        errorMessage: e.toString(),
        errorCode: code,
        stackTrace: stackTrace.toString(),
      );

      // Exception weiterwerfen damit UI sie anzeigen kann
      rethrow;
    }
  }

  /// Konvertiere Edge Function Ergebnis zu AiDiagnosis Model
  AiDiagnosis _mapEdgeFunctionResultToDiagnosis(
    Map<String, dynamic> result,
    String code,
    ObdErrorCode? basicDescription,
  ) {
    // Edge Function gibt andere Struktur zurück, mappe zu unserem Model
    final diagnosticSteps = (result['diagnosticSteps'] as List?)
        ?.map((step) => RepairStep(
              step: step['stepNumber'] ?? 0,
              title: step['title'] ?? '',
              description: step['description'] ?? '',
              tools: (step['requiredTools'] as List?)?.cast<String>(),
              warning: (step['warnings'] as List?)?.isNotEmpty == true 
                  ? (step['warnings'] as List)[0] as String
                  : null,
            ))
        .toList() ?? [];

    final repairSteps = (result['repairSteps'] as List?)
        ?.map((step) => RepairStep(
              step: step['stepNumber'] ?? 0,
              title: step['title'] ?? '',
              description: step['description'] ?? '',
              tools: (step['requiredTools'] as List?)?.cast<String>(),
              warning: (step['warnings'] as List?)?.isNotEmpty == true 
                  ? (step['warnings'] as List)[0] as String
                  : null,
            ))
        .toList() ?? [];

    // Erstelle Ursachen basierend auf Reparaturschritte
    final causes = <PossibleCause>[
      PossibleCause(
        id: '1',
        title: result['title'] ?? 'Fehlerursache',
        description: result['description'] ?? '',
        fullDescription: result['detailedAnalysis'] ?? '',
        repairSteps: repairSteps,
        estimatedCost: _parseEstimatedCost(result['estimatedCost'] ?? '100-500'),
        probability: _mapSeverityToProbability(result['severity']),
        difficulty: result['difficultyLevel'] ?? 'medium',
      ),
    ];

    return AiDiagnosis(
      code: code,
      description: result['title'] ?? basicDescription?.description ?? code,
      detailedDescription: result['detailedAnalysis'] ?? result['description'] ?? '',
      possibleCauses: causes,
      severity: result['severity'],
      driveSafety: result['driveSafety'],
    );
  }

  /// Parse Kosten-String zu CostEstimate
  CostEstimate _parseEstimatedCost(String costString) {
    // Format: "100-500" oder "100-500 €"
    final numbers = RegExp(r'\d+').allMatches(costString).map((m) => m.group(0)!).toList();
    
    if (numbers.length >= 2) {
      return CostEstimate(
        minEur: double.parse(numbers[0]),
        maxEur: double.parse(numbers[1]),
        note: 'Geschätzte Gesamtkosten inkl. Ersatzteile und Arbeitszeit',
      );
    }
    
    // Fallback
    return const CostEstimate(
      minEur: 100,
      maxEur: 500,
      note: 'Kosten variieren je nach Fahrzeugmodell',
    );
  }

  /// Mappe Severity zu Probability
  String _mapSeverityToProbability(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
      case 'high':
        return 'high';
      case 'medium':
        return 'medium';
      case 'low':
        return 'low';
      default:
        return 'medium';
    }
  }

  /// Demo-Analyse für Entwicklung (bis Edge Function fertig ist)
  AiDiagnosis _generateDemoAnalysis(String code, ObdErrorCode? basicDescription) {
    // Realistische Demo-Daten basierend auf Code-Typ
    
    if (code == 'P0420') {
      return AiDiagnosis(
        code: code,
        description: basicDescription?.description ?? 'Katalysator - Wirkungsgrad unter Schwellenwert',
        detailedDescription: 
          'Der Fehlercode P0420 deutet darauf hin, dass die Effizienz des Katalysators unter dem erforderlichen Schwellenwert liegt. '
          'Dies wird durch die Lambda-Sonden vor und nach dem Katalysator überwacht. Wenn beide Sensoren ähnliche Werte anzeigen, '
          'bedeutet dies, dass der Katalysator die Abgase nicht mehr ausreichend reinigt.',
        possibleCauses: [
          PossibleCause(
            id: '1',
            title: 'Defekter Katalysator',
            description: 'Der Katalysator ist verschlissen oder thermisch beschädigt',
            fullDescription: 
              'Der Katalysator kann durch verschiedene Faktoren beschädigt werden: Überhitzung durch Fehlzündungen, '
              'mechanische Beschädigungen, Verwendung von bleihaltigem Kraftstoff oder Ölverbrauch. '
              'Bei einem defekten Katalysator nimmt die Konvertierungseffizienz ab, und die Abgaswerte verschlechtern sich.',
            repairSteps: [
              RepairStep(
                step: 1,
                title: 'Diagnose durchführen',
                description: 'OBD-Scanner anschließen und Fehlerspeicher auslesen. Lambda-Sonden-Werte im Live-Modus prüfen.',
                tools: ['OBD2-Scanner'],
              ),
              RepairStep(
                step: 2,
                title: 'Sichtprüfung',
                description: 'Fahrzeug aufbocken und Katalysator sowie Auspuffanlage auf Beschädigungen untersuchen.',
                tools: ['Hebebühne', 'Taschenlampe'],
                warning: 'Motor vollständig abkühlen lassen - Verbrennungsgefahr!',
              ),
              RepairStep(
                step: 3,
                title: 'Katalysator ausbauen',
                description: 'Befestigungsschrauben lösen und alten Katalysator entfernen. Dichtungen entfernen.',
                tools: ['Ratsche', '13mm & 15mm Steckschlüssel', 'Rostlöser'],
                warning: 'Schrauben können festgerostet sein - vorher mit Rostlöser behandeln',
              ),
              RepairStep(
                step: 4,
                title: 'Neuen Katalysator einbauen',
                description: 'Neue Dichtungen verwenden. Katalysator einsetzen und festschrauben. Anzugsdrehmoment beachten.',
                tools: ['Drehmomentschlüssel', 'Neue Dichtungen'],
              ),
              RepairStep(
                step: 5,
                title: 'Fehlerspeicher löschen',
                description: 'Mit OBD-Scanner Fehlerspeicher löschen und Probefahrt durchführen.',
                tools: ['OBD2-Scanner'],
              ),
            ],
            estimatedCost: CostEstimate(
              minEur: 400,
              maxEur: 1200,
              partsCost: 350,
              laborHours: 2.0,
              note: 'Kosten variieren je nach Fahrzeugmodell und Katalysator-Typ',
            ),
            probability: 'high',
            difficulty: 'medium',
          ),
          PossibleCause(
            id: '2',
            title: 'Defekte Lambda-Sonde',
            description: 'Lambda-Sonde nach Katalysator liefert fehlerhafte Werte',
            fullDescription: 
              'Eine defekte Lambda-Sonde kann falsche Messwerte liefern und so einen Katalysator-Fehler vortäuschen. '
              'Die Lambda-Sonde nach dem Katalysator überwacht die Katalysator-Effizienz. Wenn diese Sonde defekt ist, '
              'kann das Steuergerät die tatsächliche Leistung des Katalysators nicht korrekt beurteilen.',
            repairSteps: [
              RepairStep(
                step: 1,
                title: 'Lambda-Sonden-Werte prüfen',
                description: 'Mit Scanner Live-Daten abrufen und beide Lambda-Sonden (vor und nach Kat) vergleichen.',
                tools: ['OBD2-Scanner'],
              ),
              RepairStep(
                step: 2,
                title: 'Lambda-Sonde ausbauen',
                description: 'Fahrzeug aufbocken, Stecker der Lambda-Sonde trennen und Sonde mit Spezialschlüssel ausbauen.',
                tools: ['Lambda-Sonden-Schlüssel', 'Ratsche'],
                warning: 'Sensor nur im kalten Zustand ausbauen',
              ),
              RepairStep(
                step: 3,
                title: 'Neue Sonde einbauen',
                description: 'Neue Lambda-Sonde einschrauben und elektrischen Stecker anschließen.',
                tools: ['Lambda-Sonden-Schlüssel', 'Montagepaste'],
              ),
              RepairStep(
                step: 4,
                title: 'System testen',
                description: 'Fehlerspeicher löschen und Testfahrt durchführen. Werte überwachen.',
                tools: ['OBD2-Scanner'],
              ),
            ],
            estimatedCost: CostEstimate(
              minEur: 120,
              maxEur: 350,
              partsCost: 80,
              laborHours: 1.0,
              note: 'Deutlich günstiger als Katalysator-Tausch',
            ),
            probability: 'medium',
            difficulty: 'easy',
          ),
          PossibleCause(
            id: '3',
            title: 'Undichte Auspuffanlage',
            description: 'Falschluft durch undichte Stellen vor Lambda-Sonde',
            fullDescription: 
              'Undichte Stellen in der Auspuffanlage vor der Lambda-Sonde können Falschluft ansaugen. '
              'Dies verfälscht die Messwerte der Lambda-Sonde und kann einen Katalysator-Fehler vortäuschen. '
              'Häufige Ursachen sind beschädigte Dichtungen, Risse im Krümmer oder lockere Verbindungen.',
            repairSteps: [
              RepairStep(
                step: 1,
                title: 'Sichtprüfung der Auspuffanlage',
                description: 'Komplette Auspuffanlage auf Risse, Löcher und beschädigte Dichtungen untersuchen.',
                tools: ['Hebebühne', 'Taschenlampe'],
              ),
              RepairStep(
                step: 2,
                title: 'Dichtigkeitsprüfung',
                description: 'Auspuff mit Lappen abdichten und auf ausströmende Abgase achten.',
                tools: ['Lappen', 'ggf. Rauchprüfgerät'],
              ),
              RepairStep(
                step: 3,
                title: 'Undichte Stelle reparieren',
                description: 'Je nach Position: Dichtung erneuern, Rohr schweißen oder Komponente austauschen.',
                tools: ['Schweißgerät', 'Neue Dichtungen', 'Schraubenschlüssel'],
              ),
              RepairStep(
                step: 4,
                title: 'Fehler löschen und testen',
                description: 'Fehlerspeicher löschen und Probefahrt durchführen.',
                tools: ['OBD2-Scanner'],
              ),
            ],
            estimatedCost: CostEstimate(
              minEur: 80,
              maxEur: 400,
              partsCost: 30,
              laborHours: 1.5,
              note: 'Je nach Umfang der Reparatur',
            ),
            probability: 'low',
            difficulty: 'medium',
          ),
        ],
        severity: 'medium',
        driveSafety: true,
      );
    }
    
    // Generic Fallback für andere Codes
    return AiDiagnosis(
      code: code,
      description: basicDescription?.description ?? 'Fehlercode-Beschreibung',
      detailedDescription: 
        'Für diesen Fehlercode wird derzeit noch eine detaillierte Analyse erstellt. '
        'Bitte kontaktiere eine Werkstatt für eine professionelle Diagnose.',
      possibleCauses: [
        PossibleCause(
          id: '1',
          title: 'Allgemeine Diagnose erforderlich',
          description: 'Professionelle Werkstattdiagnose empfohlen',
          fullDescription: 
            'Dieser Fehlercode erfordert eine detaillierte Fahrzeugdiagnose durch eine Fachwerkstatt. '
            'Die genaue Ursache kann nur durch spezielle Diagnosegeräte und Tests ermittelt werden.',
          repairSteps: [
            RepairStep(
              step: 1,
              title: 'Werkstatt aufsuchen',
              description: 'Vereinbare einen Termin mit einer qualifizierten Werkstatt für eine Fehlerdiagnose.',
            ),
            RepairStep(
              step: 2,
              title: 'Diagnose durchführen lassen',
              description: 'Die Werkstatt wird mit speziellen Diagnosegeräten die genaue Ursache ermitteln.',
            ),
            RepairStep(
              step: 3,
              title: 'Reparatur durchführen',
              description: 'Nach der Diagnose wird die Werkstatt die notwendigen Reparaturen durchführen.',
            ),
          ],
          estimatedCost: CostEstimate(
            minEur: 100,
            maxEur: 500,
            note: 'Diagnosekosten ca. 50-100€, Reparaturkosten abhängig vom Befund',
          ),
          probability: 'high',
          difficulty: 'hard',
        ),
      ],
      severity: 'medium',
      driveSafety: true,
    );
  }

  /// Batch-Analyse mehrerer Codes (für zukünftige Verwendung)
  Future<List<AiDiagnosis>> analyzeMultipleCodes(List<String> codes) async {
    final results = <AiDiagnosis>[];
    
    for (var code in codes) {
      try {
        final diagnosis = await analyzeSingleCode(code, null);
        results.add(diagnosis);
      } catch (e) {
        print('❌ Error analyzing $code: $e');
      }
    }
    
    return results;
  }
}
