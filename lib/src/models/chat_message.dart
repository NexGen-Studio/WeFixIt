class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  // Metadata für Toni's Antworten
  final int? sources; // Anzahl DB-Quellen (null bei User-Messages)
  final int? errorCodes; // Anzahl erkannter OBD2-Codes
  final String? knowledgeSource; // 'database', 'general', oder 'hybrid'

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.errorCodes,
    this.knowledgeSource,
  });
  
  /// Gibt an ob Toni DB-Wissen genutzt hat
  bool get usedDatabaseKnowledge => sources != null && sources! > 0;
  
  /// Badge-Text für UI (zeigt Wissensquelle)
  String? get badgeText {
    if (isUser || sources == null) return null;
    if (sources! > 0) return '📚 $sources ${sources! == 1 ? 'Quelle' : 'Quellen'}';
    return '💡 Allgemeinwissen';
  }
}
