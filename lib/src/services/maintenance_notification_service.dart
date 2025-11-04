import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/maintenance_reminder.dart';

/// Service für Push-Benachrichtigungen bei Wartungen
class MaintenanceNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const _nativeChannel = MethodChannel('com.example.wefixit/notifications');
  static bool _initialized = false;

  /// Initialisiert den Notification Service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Notification Channel MUSS vor dem Scheduling erstellt werden
    await _createNotificationChannel();

    tz.initializeTimeZones();
    
    // Setze lokale Zeitzone basierend auf System-DateTime
    try {
      // Ermittle Zeitzonenoffset vom System
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetHours = offset.inHours;
      
      // Wähle passende Zeitzone basierend auf Offset
      String locationName = 'Europe/Berlin'; // Default für Deutschland (UTC+1/+2)
      if (offsetHours == 1 || offsetHours == 2) {
        locationName = 'Europe/Berlin'; // Deutschland, Österreich, Schweiz
      } else if (offsetHours == 0) {
        locationName = 'Europe/London';
      } else if (offsetHours == -5) {
        locationName = 'America/New_York';
      }
      
      tz.setLocalLocation(tz.getLocation(locationName));
      print('🕒 [Notification] Lokale Zeitzone gesetzt: $locationName (Offset: ${offset.inHours}h)');
    } catch (e) {
      print('⚠️ [Notification] Fehler beim Setzen der Zeitzone: $e');
      tz.setLocalLocation(tz.getLocation('Europe/Berlin')); // Fallback
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Fordere Berechtigungen an
    try {
      if (Platform.isAndroid) {
        final android = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
        
        // Fordere auch Berechtigung für exakte Alarme an (Android 12+)
        final canSchedule = await android?.canScheduleExactNotifications() ?? false;
        if (!canSchedule) {
          print('⚠️ [Notification] Exakte Alarme nicht erlaubt - fordere Berechtigung an');
          await android?.requestExactAlarmsPermission();
        } else {
          print('✅ [Notification] Exakte Alarme bereits erlaubt');
        }
      }
    } catch (e) {
      print('⚠️ [Notification] Fehler bei Berechtigung: $e');
    }

    _initialized = true;
    print('✅ Notification Service initialisiert');
  }

  /// Erstellt den Notification Channel explizit mit allen Einstellungen
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'maintenance_reminders',
      'Wartungserinnerungen',
      description: 'Benachrichtigungen für anstehende Wartungen',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    print('🔔 [Notification] Channel erstellt: ${androidChannel.id}');
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap (z.B. zur Wartungs-Detail-Seite navigieren)
    // Dies kann mit einem GlobalKey<NavigatorState> oder einem Stream gelöst werden
  }

  /// Plant eine Benachrichtigung für eine Wartung
  static Future<void> scheduleMaintenanceReminder(
    MaintenanceReminder reminder, {
    int? offsetMinutes,
    bool? notifyEnabledOverride,
  }) async {
    if (!_initialized) await initialize();
    
    final now = DateTime.now();
    print('📅 [Notification] ========================================');
    print('📅 [Notification] Plane für: "${reminder.title}"');
    print('📅 [Notification] Due Date: ${reminder.dueDate}');
    print('📅 [Notification] Offset Minutes: ${offsetMinutes ?? "nicht gesetzt (Standard 1440)"}');
    print('📅 [Notification] Jetzt: $now');
    
    final prefs = await SharedPreferences.getInstance();
    final globalEnabled = prefs.getBool('notifications_enabled_global') ?? true;
    if (!globalEnabled) {
      print('⚠️ [Notification] Übersprungen - global deaktiviert');
      return;
    }

    final enabled = notifyEnabledOverride ?? reminder.notificationEnabled;
    if (!enabled) {
      print('⚠️ [Notification] Übersprungen - notification_enabled=false für diese Wartung');
      return;
    }

    // Berechne Notification-Zeit
    DateTime? notificationTime;
    
    if (reminder.dueDate != null) {
      // Konvertiere zu lokaler Zeit für korrekten Vergleich
      final due = reminder.dueDate!.toLocal();
      
      // Berechne Notification-Zeit (Due Date/Time - Offset)
      final minutes = offsetMinutes ?? 1440; // Standard 1 Tag (1440 Minuten) vorher
      notificationTime = due.subtract(Duration(minutes: minutes));
      
      print('📅 [Notification] Due Date/Time (lokal): $due');
      print('📅 [Notification] Offset: $minutes Minuten');
      print('📅 [Notification] Berechnete Notification-Zeit: $notificationTime');
      print('📅 [Notification] Jetzt: $now');
      print('📅 [Notification] Differenz: ${notificationTime.difference(now).inMinutes} Minuten');
      
      // Fall 1: Due Date/Time ist bereits vorbei → Sofort benachrichtigen
      if (due.isBefore(now)) {
        print('⚡ [Notification] Due Date/Time ist vorbei - sende SOFORT!');
        await _notifications.show(
          reminder.id.hashCode,
          '🔧 Wartung überfällig!',
          '${reminder.title} war fällig!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'maintenance_reminders',
              'Wartungserinnerungen',
              channelDescription: 'Benachrichtigungen für anstehende Wartungen',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
        print('✅ [Notification] SOFORT gesendet (überfällig)');
        return;
      }
      
      // Fall 2: Notification-Zeit ist vorbei, aber Due Date/Time noch in Zukunft
      // → Sofort benachrichtigen (wir sind im Benachrichtigungszeitraum)
      if (notificationTime.isBefore(now)) {
        print('⚡ [Notification] Notification-Zeit ist vorbei, aber Due Date/Time noch in Zukunft');
        print('⚡ [Notification] → Benachrichtigungszeitraum! Sende SOFORT!');
        
        await _notifications.show(
          reminder.id.hashCode,
          '🔧 Wartung fällig',
          '${reminder.title} ist bald fällig!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'maintenance_reminders',
              'Wartungserinnerungen',
              channelDescription: 'Benachrichtigungen für anstehende Wartungen',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
        print('✅ [Notification] SOFORT gesendet (Benachrichtigungszeitraum)');
        return;
      }
      
      // Fall 3: Notification-Zeit liegt in der Zukunft → Planen
      print('⏰ [Notification] Notification-Zeit liegt in der Zukunft - plane für: $notificationTime');
    } else {
      print('⚠️ [Notification] Übersprungen - Kilometer-basierte Wartung');
      return;
    }
    
    print('⏰ [Notification] Plane Notification für: $notificationTime');

    // Generiere eindeutige ID basierend auf Reminder-ID und Offset
    // Damit können mehrere Notifications für dieselbe Wartung geplant werden
    final minutes = offsetMinutes ?? 1440;
    final id = (reminder.id.hashCode + minutes).abs();

    // Bestehende Notification vermeiden
    await _notifications.cancel(id);

    // Konvertiere zu TZDateTime in lokaler Zeitzone
    final scheduledTime = tz.TZDateTime.from(notificationTime, tz.local);
    print('⏰ [Notification] Geplante Zeit (lokal): $scheduledTime');

    // Channel VOR jedem Scheduling neu erstellen (wichtig für Background-Execution)
    await _createNotificationChannel();

    try {
      // Verwende NATIVE AlarmManager für GARANTIERTE Zustellung
      if (Platform.isAndroid) {
        await _nativeChannel.invokeMethod('scheduleNotification', {
          'id': id,
          'title': '🔧 Wartung fällig',
          'body': reminder.title,
          'scheduledTime': scheduledTime.millisecondsSinceEpoch,
        });
        print('✅ [Notification] Native Notification geplant für ${reminder.title}');
      } else {
        // iOS: Verwende flutter_local_notifications
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        await _notifications.zonedSchedule(
          id,
          '🔧 Wartung fällig',
          reminder.title,
          scheduledTime,
          const NotificationDetails(iOS: iosDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('✅ [Notification] iOS Notification geplant für ${reminder.title}');
      }
    } catch (e) {
      print('❌ [Notification] FEHLER beim Planen: $e');
    }
  }

  /// Plant Benachrichtigungen für überfällige Wartungen
  static Future<void> scheduleOverdueNotification(MaintenanceReminder reminder) async {
    if (!_initialized) await initialize();
    if (!reminder.notificationEnabled) return;
    if (reminder.status != MaintenanceStatus.overdue) return;

    final id = 'overdue_${reminder.id}'.hashCode;

    await _notifications.show(
      id,
      '⚠️ Wartung überfällig!',
      '${reminder.title} ist überfällig!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_overdue',
          'Überfällige Wartungen',
          channelDescription: 'Benachrichtigungen für überfällige Wartungen',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Storniert alle geplanten Benachrichtigungen für eine Wartung
  /// Storniert mehrere mögliche Offset-Varianten, da eine Wartung mehrere Benachrichtigungen haben kann
  static Future<void> cancelNotification(String reminderId) async {
    if (!_initialized) await initialize();
    
    // Storniere Notifications für häufige Offsets
    // Da wir nicht wissen, welche Offsets ursprünglich gesetzt waren, 
    // stornieren wir die häufigsten Kombinationen
    final commonOffsets = [1, 5, 10, 15, 30, 60, 120, 180, 360, 720, 1440, 2880, 4320, 10080];
    
    for (final offset in commonOffsets) {
      final id = (reminderId.hashCode + offset).abs();
      try {
        await _notifications.cancel(id);
      } catch (e) {
        // Ignoriere Fehler - Notification existiert möglicherweise nicht
      }
    }
    
    // Auch die alte ID-Variante stornieren (für Rückwärtskompatibilität)
    try {
      await _notifications.cancel(reminderId.hashCode);
    } catch (e) {
      // Ignoriere Fehler
    }
  }

  /// Storniert alle Benachrichtigungen
  static Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Prüft ob Benachrichtigungen erlaubt sind
  static Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();
    
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled() ?? false;
      
      // Prüfe auch ob exakte Alarme erlaubt sind (Android 12+)
      try {
        final canSchedule = await android?.canScheduleExactNotifications() ?? false;
        print('📱 [Notification] Benachrichtigungen erlaubt: $enabled, Exakte Alarme: $canSchedule');
        return enabled && canSchedule;
      } catch (e) {
        print('⚠️ [Notification] Fehler bei Berechtigungsprüfung: $e');
        return enabled;
      }
    }
    
    return true; // iOS fragt beim ersten Mal automatisch
  }
  
  /// Fordert Berechtigung für exakte Alarme an (Android 12+)
  static Future<void> requestExactAlarmPermission() async {
    if (!_initialized) await initialize();
    
    if (Platform.isAndroid) {
      try {
        final android = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestExactAlarmsPermission();
        print('✅ [Notification] Exakte Alarm-Berechtigung angefordert');
      } catch (e) {
        print('❌ [Notification] Fehler beim Anfordern der Berechtigung: $e');
      }
    }
  }

  /// Fordert Benachrichtigungs-Berechtigung an (iOS)
  static Future<bool> requestPermission() async {
    if (!_initialized) await initialize();
    
    final ios = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    final result = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    return result ?? true;
  }

  /// Sendet eine Willkommens-Benachrichtigung beim ersten App-Start
  /// Damit erscheint die App in der Benachrichtigungsliste und Kanäle werden registriert
  static Future<void> sendWelcomeNotification() async {
    if (!_initialized) await initialize();
    
    // Prüfe ob bereits gesendet wurde
    final prefs = await SharedPreferences.getInstance();
    final alreadySent = prefs.getBool('welcome_notification_sent') ?? false;
    if (alreadySent) return;
    
    // Sende Willkommens-Notification
    await _notifications.show(
      888888,
      '🔧 WeFixIt',
      'Wartungserinnerungen sind jetzt aktiv! Du wirst rechtzeitig an anstehende Wartungen erinnert.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_reminders',
          'Wartungserinnerungen',
          channelDescription: 'Benachrichtigungen für anstehende Wartungen',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    // Markiere als gesendet
    await prefs.setBool('welcome_notification_sent', true);
  }

  /// Sendet eine Test-Benachrichtigung
  static Future<void> sendTestNotification() async {
    if (!_initialized) await initialize();
    
    await _notifications.show(
      999999,
      '🔧 WeFixIt Test',
      'Benachrichtigungen funktionieren! ✅',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_reminders',
          'Wartungserinnerungen',
          channelDescription: 'Benachrichtigungen für anstehende Wartungen',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    print('📢 [Notification] Test-Benachrichtigung gesendet');
  }

  /// Plant alle Benachrichtigungen für eine Liste von Wartungen neu
  static Future<void> rescheduleAll(List<MaintenanceReminder> reminders) async {
    await cancelAllNotifications();
    
    for (var reminder in reminders) {
      if (reminder.status == MaintenanceStatus.planned) {
        await scheduleMaintenanceReminder(reminder);
      } else if (reminder.status == MaintenanceStatus.overdue) {
        await scheduleOverdueNotification(reminder);
      }
    }
  }
}
