import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_reminder.dart';

class MaintenanceService {
  final SupabaseClient _client;

  MaintenanceService(this._client);

  /// Alle Wartungserinnerungen des Users abrufen
  Future<List<MaintenanceReminder>> fetchReminders({
    String? vehicleId,
    bool? isCompleted,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('maintenance_reminders')
        .select()
        .eq('user_id', user.id);

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    if (isCompleted != null) {
      query = query.eq('is_completed', isCompleted);
    }

    final res = await query.order('due_date', ascending: true);
    return (res as List)
        .map((json) => MaintenanceReminder.fromJson(json))
        .toList();
  }

  /// Nächste anstehende Wartung
  Future<MaintenanceReminder?> fetchNextReminder({String? vehicleId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    var query = _client
        .from('maintenance_reminders')
        .select()
        .eq('user_id', user.id)
        .eq('is_completed', false);

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final res = await query.order('due_date', ascending: true).limit(1);
    if (res.isEmpty) return null;
    return MaintenanceReminder.fromJson(res.first);
  }

  /// Neue Wartungserinnerung erstellen
  Future<MaintenanceReminder> createReminder({
    String? vehicleId,
    required String title,
    String? description,
    required ReminderType reminderType,
    DateTime? dueDate,
    int? dueMileage,
    bool isRecurring = false,
    int? recurrenceIntervalDays,
    int? recurrenceIntervalKm,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an, um Wartungen anzulegen');
    }

    final data = {
      'user_id': user.id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      'title': title,
      if (description != null) 'description': description,
      'reminder_type': reminderType == ReminderType.date ? 'date' : 'mileage',
      if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      if (dueMileage != null) 'due_mileage': dueMileage,
      'is_recurring': isRecurring,
      if (recurrenceIntervalDays != null)
        'recurrence_interval_days': recurrenceIntervalDays,
      if (recurrenceIntervalKm != null)
        'recurrence_interval_km': recurrenceIntervalKm,
    };

    final res = await _client
        .from('maintenance_reminders')
        .insert(data)
        .select()
        .single();

    return MaintenanceReminder.fromJson(res);
  }

  /// Wartungserinnerung aktualisieren
  Future<void> updateReminder({
    required String id,
    String? title,
    String? description,
    DateTime? dueDate,
    int? dueMileage,
    bool? isRecurring,
    int? recurrenceIntervalDays,
    int? recurrenceIntervalKm,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an');
    }

    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (dueDate != null) data['due_date'] = dueDate.toIso8601String();
    if (dueMileage != null) data['due_mileage'] = dueMileage;
    if (isRecurring != null) data['is_recurring'] = isRecurring;
    if (recurrenceIntervalDays != null)
      data['recurrence_interval_days'] = recurrenceIntervalDays;
    if (recurrenceIntervalKm != null)
      data['recurrence_interval_km'] = recurrenceIntervalKm;

    await _client
        .from('maintenance_reminders')
        .update(data)
        .eq('id', id)
        .eq('user_id', user.id);
  }

  /// Wartung als erledigt markieren
  Future<void> completeReminder(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an');
    }

    await _client
        .from('maintenance_reminders')
        .update({
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id);
  }

  /// Wartung wieder als anstehend markieren
  Future<void> uncompleteReminder(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an');
    }

    await _client
        .from('maintenance_reminders')
        .update({
          'is_completed': false,
          'completed_at': null,
        })
        .eq('id', id)
        .eq('user_id', user.id);
  }

  /// Wartungserinnerung löschen
  Future<void> deleteReminder(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an');
    }

    await _client
        .from('maintenance_reminders')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
