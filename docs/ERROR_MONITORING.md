# 🚨 Error Monitoring & Benachrichtigungen

## Übersicht

Du möchtest bei Fehlern, die bei Usern auftreten, automatisch benachrichtigt werden. Hier sind die besten Optionen:

---

## ✅ Empfohlene Lösung: **Sentry**

### Warum Sentry?
- ✅ **Real-time Error Tracking** - Sofortige Benachrichtigungen
- ✅ **Flutter SDK** - Perfekte Integration
- ✅ **Kostenlos bis 5.000 Events/Monat**
- ✅ **Detaillierte Error Reports** (Stack Traces, Device Info, User Actions)
- ✅ **Email + Slack + Discord Benachrichtigungen**
- ✅ **Performance Monitoring** - Sieh langsame API Calls

### Installation:

```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.15.0
```

### Integration:

```dart
// main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'DEIN_SENTRY_DSN'; // Von sentry.io
      options.tracesSampleRate = 0.5; // 50% Performance Tracking
      options.environment = 'production'; // oder 'development'
      
      // Welche Events sollen getrackt werden?
      options.beforeSend = (event, hint) {
        // Filtere debug logs in development
        if (event.environment == 'development' && event.level == SentryLevel.debug) {
          return null;
        }
        return event;
      };
    },
    appRunner: () => runApp(const MyApp()),
  );

  // Fehler außerhalb von Flutter abfangen
  FlutterError.onError = (details) {
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };
}
```

### Verwendung im Code:

```dart
// Automatisch: Alle unhandled exceptions werden getrackt

// Manuell einen Fehler melden:
try {
  await _supabase.functions.invoke('analyze-obd-codes', ...);
} catch (e, stackTrace) {
  // Sende Fehler an Sentry
  await Sentry.captureException(
    e,
    stackTrace: stackTrace,
    hint: Hint.withMap({
      'errorCode': code,
      'userId': user?.id,
      'screen': 'ai_diagnosis_detail',
    }),
  );
  rethrow; // UI zeigt Fehler
}
```

### Benachrichtigungen einrichten:

1. **Gehe zu [sentry.io](https://sentry.io)** → Kostenloses Konto erstellen
2. **Projekt erstellen** → "Flutter" auswählen
3. **Settings → Alerts**:
   - **Email**: Sofortige Benachrichtigung bei neuen Errors
   - **Slack**: Webhook für Slack-Channel
   - **Discord**: Webhook für Discord-Channel
4. **Alert Rules erstellen**:
   - "Notify me when ANY error occurs"
   - "Notify me when error rate > 10/min"
   - "Notify me for specific error types"

---

## 🔥 Alternative: **Firebase Crashlytics**

### Warum Firebase?
- ✅ Wenn du bereits Firebase nutzt (du hast Supabase, aber Firebase geht trotzdem)
- ✅ **Komplett kostenlos** (unbegrenzt)
- ✅ Gute Google Analytics Integration
- ✅ Push Notifications bei Crashes

### Installation:

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_crashlytics: ^3.4.0
```

### Integration:

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Crashlytics aktivieren
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const MyApp());
}
```

### Verwendung:

```dart
try {
  await _supabase.functions.invoke('analyze-obd-codes', ...);
} catch (e, stackTrace) {
  // Sende an Firebase Crashlytics
  await FirebaseCrashlytics.instance.recordError(
    e,
    stackTrace,
    reason: 'AI Diagnosis failed for code: $code',
    information: [
      DiagnosticsProperty('userId', user?.id),
      DiagnosticsProperty('errorCode', code),
    ],
  );
  rethrow;
}
```

---

## 🆚 Vergleich

| Feature | **Sentry** | **Firebase Crashlytics** |
|---------|-----------|-------------------------|
| **Kosten** | Kostenlos bis 5K/Monat | Komplett kostenlos |
| **Real-time Alerts** | ✅ Email, Slack, Discord | ✅ Email, Push |
| **Error Details** | ⭐⭐⭐⭐⭐ Sehr detailliert | ⭐⭐⭐⭐ Gut |
| **Performance Monitoring** | ✅ Ja | ⚠️ Begrenzt |
| **User Context** | ✅ Automatisch | ✅ Automatisch |
| **Integration** | 5 Minuten | 10 Minuten |
| **Dashboard** | Sehr übersichtlich | Gut |

---

## 📊 Was wird getrackt?

### Automatisch:
- ✅ **Alle unhandled exceptions**
- ✅ **Device Info** (OS, Modell, App Version)
- ✅ **User ID** (wenn eingeloggt)
- ✅ **Stack Traces**
- ✅ **Breadcrumbs** (letzte User-Aktionen)

### Mit Kontext (du kannst hinzufügen):
```dart
Sentry.configureScope((scope) {
  scope.setUser(SentryUser(
    id: user.id,
    email: user.email,
    username: user.name,
  ));
  scope.setTag('feature', 'ai_diagnosis');
  scope.setExtra('errorCode', code);
});
```

---

## 🔔 Benachrichtigungs-Beispiele

### Email (Sentry):
```
🚨 New Error in WeFixIt

Exception: Die KI-Analyse ist momentan nicht verfügbar

Screen: ai_diagnosis_detail
User: user_123
Error Code: P0420
Stack Trace: ...

[View in Sentry] [Mark as Resolved]
```

### Slack (Sentry Webhook):
```
🔴 Production Error
WeFixIt | ai_diagnosis_detail
Exception: Die KI-Analyse ist momentan nicht verfügbar
Affected users: 3
First seen: 2 min ago
```

---

## 🎯 Empfehlung für dich:

### Start mit **Sentry** (5 Minuten Setup):

1. **Konto erstellen**: [sentry.io/signup](https://sentry.io/signup)
2. **Flutter Projekt** erstellen
3. **DSN kopieren** (wird dir angezeigt)
4. **Installation** wie oben beschrieben
5. **Alerts einrichten**:
   - Email bei jedem Error
   - Slack/Discord Webhook (optional)
   - Alert wenn > 10 Errors/Stunde

### Teste es:

```dart
// Trigger einen Test-Error
Sentry.captureException(
  Exception('Test Error - Please ignore'),
  hint: Hint.withMap({'test': true}),
);
```

Du bekommst sofort eine Email! 📧

---

## 🛡️ Best Practices

### 1. **Filtere Sensitive Daten:**
```dart
options.beforeSend = (event, hint) {
  // Entferne Passwörter, Tokens, etc.
  event.request?.headers.remove('Authorization');
  return event;
};
```

### 2. **Release Tracking:**
```dart
options.release = 'wefixit@1.0.0+1';
```

### 3. **User Feedback:**
```dart
// User kann direkt Feedback zu einem Crash geben
Sentry.captureUserFeedback(SentryUserFeedback(
  eventId: eventId,
  name: 'Max Mustermann',
  email: 'max@example.com',
  comments: 'App crashte beim AI Diagnose',
));
```

---

## ✅ Was du jetzt tun solltest:

1. **Sentry Account erstellen** (5 Min)
2. **Integration in WeFixIt** (5 Min)
3. **Email Alert aktivieren** (1 Min)
4. **Test-Error senden** (1 Min)
5. **Optional: Slack/Discord Webhook** (3 Min)

**Total: ~15 Minuten für komplettes Error Monitoring!** 🚀

---

## 📱 Bonus: Supabase Error Logging

Du kannst zusätzlich Errors in eine Supabase-Tabelle loggen:

```sql
-- Supabase SQL Editor
CREATE TABLE error_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users,
  error_type TEXT NOT NULL,
  error_message TEXT,
  stack_trace TEXT,
  context JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

```dart
// In deinem Service
try {
  // ...
} catch (e, stackTrace) {
  // Logge in Supabase
  await _supabase.from('error_logs').insert({
    'user_id': user?.id,
    'error_type': e.runtimeType.toString(),
    'error_message': e.toString(),
    'stack_trace': stackTrace.toString(),
    'context': {
      'screen': 'ai_diagnosis_detail',
      'errorCode': code,
    },
  });
  
  rethrow;
}
```

Dann kannst du im Supabase Dashboard alle Errors sehen!
