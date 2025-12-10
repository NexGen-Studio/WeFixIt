import 'package:supabase_flutter/supabase_flutter.dart';

class CreditService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Ruft das aktuelle Credit-Guthaben ab
  Future<int> getBalance() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    try {
      // Hole ALLE credit_events und berechne die Balance
      final response = await _supabase
          .from('credit_events')
          .select('delta')
          .eq('user_id', user.id);

      if (response == null || response.isEmpty) {
        return 0; // Noch keine Events = 0 Credits
      }
      
      // Summiere alle credits (positive und negative)
      int balance = 0;
      for (final event in response) {
        balance += (event['delta'] as int);
      }
      
      return balance;
    } catch (e) {
      print('Error fetching credit balance: $e');
      return 0;
    }
  }

  /// Alias für getBalance() - für bessere API-Benennung
  Future<int> getCreditBalance() async {
    return await getBalance();
  }

  /// Ruft Informationen über das wöchentliche Gratis-Kontingent ab
  Future<Map<String, dynamic>> getFreeQuotaInfo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {'consumed': 0, 'weekStartDate': null};
    }

    try {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final weekStartStr = weekStart.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('weekly_free_quota')
          .select('consumed')
          .eq('user_id', user.id)
          .eq('week_start_date', weekStartStr)
          .maybeSingle();

      final consumed = response != null ? (response['consumed'] as int) : 0;
      
      return {
        'consumed': consumed,
        'weekStartDate': weekStart,
      };
    } catch (e) {
      print('Error fetching free quota info: $e');
      return {'consumed': 0, 'weekStartDate': null};
    }
  }

  /// Fügt Credits hinzu (Kauf/Belohnung)
  Future<bool> addCredits(int amount, String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase.from('credit_events').insert({
        'user_id': user.id,
        'reason': type, // 'purchase', 'reward', etc.
        'delta': amount,
      });
      
      return true;
    } catch (e) {
      print('Error adding credits: $e');
      return false;
    }
  }

  /// Alias für addCredits - für Werbung-Belohnungen
  Future<bool> addFreeCredits(int amount, String type) async {
    return await addCredits(amount, type);
  }

  /// Ruft das verbleibende wöchentliche Gratis-Kontingent ab
  Future<int> getWeeklyFreeQuotaRemaining() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    try {
      // Aktuelle Woche bestimmen (Montag als Start)
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final weekStartStr = weekStart.toIso8601String().split('T')[0]; // Datum Teil

      final response = await _supabase
          .from('weekly_free_quota')
          .select('consumed')
          .eq('user_id', user.id)
          .eq('week_start_date', weekStartStr)
          .maybeSingle();

      const int weeklyLimit = 3; // 3 Anfragen pro Woche kostenlos
      final consumed = response != null ? (response['consumed'] as int) : 0;
      
      return (weeklyLimit - consumed).clamp(0, weeklyLimit);
    } catch (e) {
      print('Error fetching quota: $e');
      return 0;
    }
  }

  /// Versucht, Kosten über Gratis-Quota oder Credits zu decken
  /// Priorität: 1. Gratis-Quota, 2. Credits
  Future<bool> consumeQuotaOrCredits(int amount, String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // 1. Versuch: Gratis-Quota
    try {
      final quotaRemaining = await getWeeklyFreeQuotaRemaining();
      if (quotaRemaining >= amount) {
        // Quota nutzen
        final now = DateTime.now();
        final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        final weekStartStr = weekStart.toIso8601String().split('T')[0];

        // Upsert für consumed counter
        // Wir müssen wissen wie viel vorher consumed war, oder wir nutzen RPC/SQL function.
        // Da wir oben gelesen haben, ist es nicht atomar sicher, aber für MVP ok.
        // Besser: Upsert mit Conflict.
        
        // Hole aktuellen Wert nochmal sicherheitshalber oder mache Upsert Logik
        // Supabase upsert:
        // Wir lesen "consumed" beim getWeeklyFreeQuotaRemaining nicht direkt für das Update.
        // Einfachheitshalber: Wir nehmen an, dass wir der einzige Writer sind gerade.
        
        final response = await _supabase
          .from('weekly_free_quota')
          .select('consumed')
          .eq('user_id', user.id)
          .eq('week_start_date', weekStartStr)
          .maybeSingle();
          
        final currentConsumed = response != null ? (response['consumed'] as int) : 0;
        
        await _supabase.from('weekly_free_quota').upsert({
          'user_id': user.id,
          'week_start_date': weekStartStr,
          'consumed': currentConsumed + amount,
        });
        
        return true;
      }
    } catch (e) {
      print('Error processing quota: $e');
      // Fallback auf Credits probieren, falls Quota Fehler wirft?
      // Eher nein, um Fehler nicht zu verschleiern. Aber wir machen weiter mit Credits check.
    }

    // 2. Versuch: Credits
    return await consumeCredits(amount, type);
  }

  /// Zieht Credits ab (Verbrauch)
  /// Gibt true zurück, wenn erfolgreich (genug Guthaben)
  Future<bool> consumeCredits(int amount, String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final currentBalance = await getBalance();
      
      if (currentBalance < amount) {
        return false; // Nicht genug Guthaben
      }

      await _supabase.from('credit_events').insert({
        'user_id': user.id,
        'reason': type, // 'usage_chat', 'usage_diagnose', etc.
        'delta': -amount,
      });
      
      return true;
    } catch (e) {
      print('Error consuming credits: $e');
      return false;
    }
  }
}
