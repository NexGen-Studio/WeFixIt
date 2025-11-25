import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_reminder.dart';
import 'maintenance_notification_service.dart';
import 'costs_service.dart';
import 'category_service.dart';

class MaintenanceService {
  final SupabaseClient _client;

  MaintenanceService(this._client);

  /// Einzelne Wartungserinnerung abrufen
  Future<MaintenanceReminder?> getReminder(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await _client
          .from('maintenance_reminders')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .single();
      return MaintenanceReminder.fromJson(res);
    } catch (e) {
      print('Fehler beim Abrufen der Wartung: $e');
      return null;
    }
  }

  /// Alle Wartungserinnerungen des Users abrufen
  Future<List<MaintenanceReminder>> fetchReminders(
    String? vehicleId,
    MaintenanceStatus? status,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('maintenance_reminders')
        .select()
        .eq('user_id', user.id);

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    if (status != null) {
      final statusStr = status == MaintenanceStatus.planned
          ? 'planned'
          : status == MaintenanceStatus.completed
              ? 'completed'
              : 'overdue';
      query = query.eq('status', statusStr);
    }

    final res = await query.order('due_date', ascending: true);
    return (res as List)
        .map((json) => MaintenanceReminder.fromJson(json))
        .toList();
  }

  /// Wartungen nach Kategorie filtern
  Future<List<MaintenanceReminder>> fetchRemindersByCategory(
    MaintenanceCategory category,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final categoryStr = category.toJsonValue();
    final res = await _client
        .from('maintenance_reminders')
        .select()
        .eq('user_id', user.id)
        .eq('category', categoryStr)
        .order('due_date', ascending: true);

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
        .eq('status', 'planned');

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final res = await query.order('due_date', ascending: true).limit(1);
    if (res.isEmpty) return null;
    return MaintenanceReminder.fromJson(res.first);
  }

  /// Mehrere anstehende Wartungen abrufen
  Future<List<MaintenanceReminder>> fetchUpcomingReminders({
    String? vehicleId,
    int limit = 10,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('maintenance_reminders')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'planned');

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final res = await query.order('due_date', ascending: true).limit(limit);
    return res.map((json) => MaintenanceReminder.fromJson(json)).toList();
  }

  /// Statistiken abrufen
  Future<Map<String, int>> fetchStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return {'planned': 0, 'overdue': 0, 'completed': 0};

    final res = await _client
        .from('maintenance_reminders')
        .select('status')
        .eq('user_id', user.id);

    int planned = 0, overdue = 0, completed = 0;
    for (var item in res) {
      final status = item['status'];
      if (status == 'planned') planned++;
      else if (status == 'overdue') overdue++;
      else if (status == 'completed') completed++;
    }

    return {'planned': planned, 'overdue': overdue, 'completed': completed};
  }

  /// Neue Wartungserinnerung erstellen
  Future<MaintenanceReminder> createReminder({
    String? vehicleId,
    required String title,
    String? description,
    MaintenanceCategory? category,
    required ReminderType reminderType,
    DateTime? dueDate,
    int? dueMileage,
    int? mileageAtMaintenance,
    String? workshopName,
    String? workshopAddress,
    double? cost,
    String? notes,
    List<String>? photos,
    List<String>? documents,
    bool isRecurring = false,
    int? recurrenceIntervalDays,
    int? recurrenceIntervalKm,
    Map<String, dynamic>? recurrenceRule,
    bool notificationEnabled = true,
    int? notifyOffsetMinutes,
    
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an, um Wartungen anzulegen');
    }

    final categoryStr = category?.toJsonValue();

    final data = {
      'user_id': user.id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      'title': title,
      if (description != null) 'description': description,
      if (categoryStr != null) 'category': categoryStr,
      'reminder_type': reminderType == ReminderType.date ? 'date' : 'mileage',
      if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      if (dueMileage != null) 'due_mileage': dueMileage,
      if (mileageAtMaintenance != null) 'mileage_at_maintenance': mileageAtMaintenance,
      if (workshopName != null) 'workshop_name': workshopName,
      if (workshopAddress != null) 'workshop_address': workshopAddress,
      if (cost != null) 'cost': cost,
      if (notes != null) 'notes': notes,
      if (photos != null) 'photos': photos,
      if (documents != null) 'documents': documents,
      'is_recurring': isRecurring,
      if (recurrenceIntervalDays != null)
        'recurrence_interval_days': recurrenceIntervalDays,
      if (recurrenceIntervalKm != null)
        'recurrence_interval_km': recurrenceIntervalKm,
      if (recurrenceRule != null)
        'recurrence_rule': recurrenceRule,
      'notification_enabled': notificationEnabled,
      'notify_offset_minutes': notifyOffsetMinutes,
      'status': 'planned',
    };

    final res = await _client
        .from('maintenance_reminders')
        .insert(data)
        .select()
        .single();

    final reminder = MaintenanceReminder.fromJson(res);
    
    // Plane Benachrichtigung
    if (notificationEnabled && dueDate != null) {
      await MaintenanceNotificationService.scheduleMaintenanceReminder(
        reminder,
        offsetMinutes: notifyOffsetMinutes,
        notifyEnabledOverride: notificationEnabled,
      );
    }

    // Auto-Sync: Kosteneintrag erstellen wenn Kosten angegeben
    if (cost != null && cost > 0) {
      try {
        final CostsService costsService = CostsService();
        final CategoryService categoryService = CategoryService();
        
        // Kategorie-Mapping: Wartungskategorie → Kostenkategorie
        final categoryName = category?.toJsonValue() ?? 'maintenance';
        final costCategory = await categoryService.findSystemCategoryByName(categoryName);
        
        if (costCategory != null) {
          await costsService.createCostFromMaintenance(
            maintenanceReminderId: reminder.id,
            categoryId: costCategory.id,
            title: title,
            amount: cost,
            date: dueDate ?? DateTime.now(),
            mileage: mileageAtMaintenance,
          );
        }
      } catch (e) {
        print('Error creating cost entry from maintenance: $e');
        // Fehler beim Kosten-Sync nicht propagieren
      }
    }

    return reminder;
  }

  /// Wartungserinnerung aktualisieren
  Future<void> updateReminder({
    required String id,
    String? title,
    String? description,
    MaintenanceCategory? category,
    DateTime? dueDate,
    int? dueMileage,
    int? mileageAtMaintenance,
    String? workshopName,
    String? workshopAddress,
    double? cost,
    String? notes,
    List<String>? photos,
    List<String>? documents,
    bool? isRecurring,
    int? recurrenceIntervalDays,
    int? recurrenceIntervalKm,
    Map<String, dynamic>? recurrenceRule,
    bool? notificationEnabled,
    MaintenanceStatus? status,
    int? notifyOffsetMinutes,
    
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an');
    }

    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category.toJsonValue();
    if (dueDate != null) data['due_date'] = dueDate.toIso8601String();
    if (dueMileage != null) data['due_mileage'] = dueMileage;
    if (mileageAtMaintenance != null) data['mileage_at_maintenance'] = mileageAtMaintenance;
    if (workshopName != null) data['workshop_name'] = workshopName;
    if (workshopAddress != null) data['workshop_address'] = workshopAddress;
    if (cost != null) data['cost'] = cost;
    if (notes != null) data['notes'] = notes;
    if (photos != null) data['photos'] = photos;
    if (documents != null) data['documents'] = documents;
    if (isRecurring != null) data['is_recurring'] = isRecurring;
    if (recurrenceIntervalDays != null)
      data['recurrence_interval_days'] = recurrenceIntervalDays;
    if (recurrenceIntervalKm != null)
      data['recurrence_interval_km'] = recurrenceIntervalKm;
    if (recurrenceRule != null) data['recurrence_rule'] = recurrenceRule;
    if (notificationEnabled != null) data['notification_enabled'] = notificationEnabled;
    if (status != null) {
      final statusStr = status == MaintenanceStatus.planned
          ? 'planned'
          : status == MaintenanceStatus.completed
              ? 'completed'
              : 'overdue';
      data['status'] = statusStr;
    }
    if (notifyOffsetMinutes != null) data['notify_offset_minutes'] = notifyOffsetMinutes;

    await _client
        .from('maintenance_reminders')
        .update(data)
        .eq('id', id)
        .eq('user_id', user.id);

    // Update Benachrichtigung wenn nötig
    if (notificationEnabled == false) {
      await MaintenanceNotificationService.cancelNotification(id);
    } else if (dueDate != null || notificationEnabled == true) {
      // Hole aktualisierte Daten und plane neu
      final updated = await _client
          .from('maintenance_reminders')
          .select()
          .eq('id', id)
          .single();
      final reminder = MaintenanceReminder.fromJson(updated);
      await MaintenanceNotificationService.cancelNotification(id);
      if ((notificationEnabled ?? reminder.notificationEnabled) && reminder.dueDate != null) {
        await MaintenanceNotificationService.scheduleMaintenanceReminder(
          reminder,
          offsetMinutes: notifyOffsetMinutes,
          notifyEnabledOverride: notificationEnabled ?? reminder.notificationEnabled,
        );
      }
    }
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
          'status': 'completed',
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id);

    // Storniere Benachrichtigung
    await MaintenanceNotificationService.cancelNotification(id);
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
          'status': 'planned',
          'is_completed': false,
          'completed_at': null,
        })
        .eq('id', id)
        .eq('user_id', user.id);

    // Plane Benachrichtigung neu
    final updated = await _client
        .from('maintenance_reminders')
        .select()
        .eq('id', id)
        .single();
    final reminder = MaintenanceReminder.fromJson(updated);
    if (reminder.notificationEnabled && reminder.dueDate != null) {
      await MaintenanceNotificationService.scheduleMaintenanceReminder(reminder);
    }
  }

  /// Wartungserinnerung löschen
  Future<void> deleteReminder(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bitte melde dich an');
    }

    final reminder = await getReminder(id);

    // Storniere Benachrichtigung
    await MaintenanceNotificationService.cancelNotification(id);

    await _client
        .from('maintenance_reminders')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);

    if (reminder != null) {
      final filesToRemove = <String>[]
        ..addAll(reminder.photos)
        ..addAll(reminder.documents);

      if (filesToRemove.isNotEmpty) {
        try {
          await _client.storage.from('maintenance-files').remove(filesToRemove);
        } catch (e) {
          print('⚠️ Fehler beim Löschen von Anhängen: $e');
        }
      }
    }
  }

  /// Foto hochladen
  Future<String?> uploadPhoto(String filePath) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final fileName = 'maintenance_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '${user.id}/$fileName';

      await _client.storage.from('maintenance-files').upload(
            storagePath,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );

      return storagePath;
    } catch (e) {
      return null;
    }
  }

  /// Dokument hochladen
  Future<String?> uploadDocument(String filePath) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final fileName = 'maintenance_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storagePath = '${user.id}/$fileName';

      await _client.storage.from('maintenance-files').upload(
            storagePath,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );

      return storagePath;
    } catch (e) {
      return null;
    }
  }

  /// Signierte URL für Foto/Dokument abrufen
  Future<String?> getSignedUrl(String key) async {
    try {
      if (key.startsWith('http://') || key.startsWith('https://')) {
        return key;
      }
      final signed = await _client.storage.from('maintenance-files').createSignedUrl(key, 60 * 60);
      return signed;
    } catch (_) {
      return null;
    }
  }
}

