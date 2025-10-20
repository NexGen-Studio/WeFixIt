import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/maintenance_reminder.dart';

/// Service für Push-Benachrichtigungen bei Wartungen
class MaintenanceNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialisiert den Notification Service
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

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

    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap (z.B. zur Wartungs-Detail-Seite navigieren)
    // Dies kann mit einem GlobalKey<NavigatorState> oder einem Stream gelöst werden
  }

  /// Plant eine Benachrichtigung für eine Wartung
  static Future<void> scheduleMaintenanceReminder(MaintenanceReminder reminder) async {
    if (!_initialized) await initialize();
    if (!reminder.notificationEnabled) return;

    // Berechne Notification-Zeit (1 Tag vor Fälligkeit)
    DateTime? notificationTime;
    
    if (reminder.dueDate != null) {
      notificationTime = reminder.dueDate!.subtract(const Duration(days: 1));
      
      // Nur planen wenn in der Zukunft
      if (notificationTime.isBefore(DateTime.now())) {
        notificationTime = reminder.dueDate!.subtract(const Duration(hours: 2));
      }
      
      // Wenn immer noch in der Vergangenheit, überspringe
      if (notificationTime.isBefore(DateTime.now())) return;
    } else {
      // Für Kilometer-basierte Wartungen: Keine automatische Benachrichtigung
      // Diese sollten manuell ausgelöst werden wenn Kilometerstand aktualisiert wird
      return;
    }

    final id = reminder.id.hashCode;

    await _notifications.zonedSchedule(
      id,
      '🔧 Wartung fällig',
      '${reminder.title} ist morgen fällig!',
      tz.TZDateTime.from(notificationTime, tz.local),
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
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

  /// Storniert eine geplante Benachrichtigung
  static Future<void> cancelNotification(String reminderId) async {
    if (!_initialized) await initialize();
    final id = reminderId.hashCode;
    await _notifications.cancel(id);
  }

  /// Storniert alle Benachrichtigungen
  static Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Prüft ob Benachrichtigungen erlaubt sind
  static Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();
    
    final android = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    
    return android ?? true;
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

  /// Sendet eine Test-Benachrichtigung
  static Future<void> sendTestNotification() async {
    if (!_initialized) await initialize();
    
    await _notifications.show(
      999999,
      '🔧 WeFixIt Test',
      'Benachrichtigungen funktionieren! ✅',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          'Test Notifications',
          channelDescription: 'Test notification channel',
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
