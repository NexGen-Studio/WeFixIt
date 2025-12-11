import 'package:supabase_flutter/supabase_flutter.dart';

/// Service für "Ask Toni!" - KI-gestützter Chat-Assistent
class AskToniService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sende eine Nachricht an Toni und erhalte eine Antwort
  /// 
  /// [message] - Die Nachricht des Users
  /// [language] - Sprache (de, en, fr, es)
  /// [conversationHistory] - Optional: Bisherige Konversation für Kontext
  /// [vehicleContext] - Optional: Fahrzeugdaten des Users (Marke, Modell, Baujahr, etc.)
  Future<AskToniResponse> sendMessage({
    required String message,
    String language = 'de',
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? vehicleContext,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'chat-completion',
        body: {
          'message': message,
          'language': language,
          if (conversationHistory != null)
            'conversationHistory': conversationHistory,
          if (vehicleContext != null)
            'vehicleContext': vehicleContext,
        },
      );

      if (response.data == null) {
        throw Exception('Keine Antwort von Toni erhalten');
      }

      final data = response.data as Map<String, dynamic>;

      // Handle both 'reply' (normal) and 'response' (off-topic) field names
      final replyText = (data['reply'] ?? data['response']) as String?;
      if (replyText == null) {
        throw Exception('Keine Antwort von Toni erhalten (reply/response ist null)');
      }

      return AskToniResponse(
        reply: replyText,
        sources: data['sources'] as int? ?? 0,
        errorCodes: data['errorCodes'] as int? ?? 0,
        knowledgeSource: data['knowledgeSource'] as String? ?? 'general',
        success: data['success'] as bool? ?? true,
      );
    } catch (e) {
      throw Exception('Fehler beim Chat mit Toni: $e');
    }
  }

  /// Prüfe ob der Chat-Service verfügbar ist
  Future<bool> checkAvailability() async {
    try {
      final response = await _supabase.functions.invoke(
        'chat-completion',
        body: {
          'message': 'test',
          'language': 'de',
        },
      );
      return response.data != null;
    } catch (e) {
      return false;
    }
  }
}

/// Response-Model für Toni's Antworten
class AskToniResponse {
  /// Die Antwort von Toni
  final String reply;

  /// Anzahl der genutzten DB-Quellen (0 = nur allgemeines Wissen)
  final int sources;

  /// Anzahl erkannter OBD2-Fehlercodes
  final int errorCodes;

  /// Wissensquelle: 'database', 'general', oder 'hybrid'
  final String knowledgeSource;

  /// Erfolg der Anfrage
  final bool success;

  AskToniResponse({
    required this.reply,
    required this.sources,
    required this.errorCodes,
    required this.knowledgeSource,
    required this.success,
  });

  /// Gibt an ob Toni DB-Wissen genutzt hat
  bool get usedDatabaseKnowledge => sources > 0;

  /// Gibt an ob OBD2-Codes erkannt wurden
  bool get detectedErrorCodes => errorCodes > 0;

  /// Benutzerfreundliche Beschreibung der Wissensquelle
  String get knowledgeSourceLabel {
    switch (knowledgeSource) {
      case 'database':
        return 'Datenbank-Wissen';
      case 'hybrid':
        return 'Datenbank + Allgemeines Wissen';
      case 'general':
        return 'Allgemeines KFZ-Wissen';
      default:
        return 'Unbekannt';
    }
  }
}
