# 🚀 Sentry Setup - 5 Minuten Guide

## ✅ Was du bekommst:
- 📧 **Automatische Email-Benachrichtigungen** bei jedem Fehler
- 📊 **Professionelles Dashboard** mit Stack Traces, Device Info, User Context
- 🔍 **Breadcrumbs** - Sieh was der User vor dem Fehler gemacht hat
- 📈 **Performance Monitoring** - Langsame API Calls erkennen
- 💰 **Kostenlos** bis 5.000 Events/Monat

---

## 🎯 Setup (5 Minuten)

### **Schritt 1: Sentry Account erstellen (2 Min)**

1. Gehe zu **[sentry.io/signup](https://sentry.io/signup/)**
2. Registriere mit Email
3. **Create Project** → Platform: **Flutter**
4. Projekt-Name: `WeFixIt`
5. **Kopiere den DSN** (sieht aus wie: `https://abc123@o123456.ingest.sentry.io/7890123`)

---

### **Schritt 2: DSN in Code einfügen (1 Min)**

Öffne `lib/main.dart` und ersetze:

```dart
options.dsn = 'DEIN_SENTRY_DSN_HIER';
```

Mit deinem DSN:

```dart
options.dsn = 'https://abc123@o123456.ingest.sentry.io/7890123';
```

---

### **Schritt 3: Packages installieren (1 Min)**

```bash
flutter pub get
```

---

### **Schritt 4: Email-Alerts konfigurieren (1 Min)**

1. **Sentry Dashboard** → Dein Projekt → **Alerts**
2. **Create Alert Rule**
3. **Alert Conditions:**
   - "An event is seen"
   - "more than 1 time"
   - "in 1 minute"
4. **Actions:**
   - ✅ **Send a notification via Email**
5. **Save Rule**

**Fertig!** Du bekommst jetzt bei jedem Fehler eine Email 📧

---

### **Schritt 5: Testen (< 1 Min)**

```bash
flutter run
```

1. App öffnen → **Demo-Modus**
2. **"Demo-Fehler testen"** klicken
3. **Prüfen:** 
   - Sentry Dashboard → **Issues** → Neuer Fehler sollte da sein
   - Email erhalten? ✅

---

## 🎯 User Context setzen (Optional)

Damit du siehst **welcher User** den Fehler hatte:

### **Bei Login:**

```dart
// In deinem Login-Service
import 'package:wefixit/src/services/error_logging_service.dart';

// Nach erfolgreichem Login
ErrorLoggingService.setUser(
  userId: user.id,
  email: user.email,
);
```

### **Bei Logout:**

```dart
ErrorLoggingService.clearUser();
```

**Jetzt zeigt Sentry bei jedem Fehler die User-ID!**

---

## 📧 Email-Beispiel

**Bei Fehler bekommst du:**

```
Von: Sentry <alerts@sentry.io>
An: deine-email@example.com
Betreff: [WeFixIt] Exception: Die KI-Analyse ist momentan nicht verfügbar

New issue in WeFixIt:

Exception: Die KI-Analyse ist momentan nicht verfügbar. 
Bitte versuche es später erneut.

Environment: production
User: abc-123-def
Device: Android 13 (Pixel 6)
Screen: ai_diagnosis_detail

Stack Trace:
[... vollständiger Stack Trace ...]

View on Sentry:
https://sentry.io/organizations/your-org/issues/12345/
```

---

## 🔧 Was wird automatisch geloggt?

**Sentry fängt automatisch ab:**
- ✅ Alle Exceptions (auch async!)
- ✅ Flutter Errors
- ✅ Network Errors (gefiltert)
- ✅ Stack Traces
- ✅ Device Info (OS, Model, Version)
- ✅ User ID (falls gesetzt)
- ✅ Breadcrumbs (letzte User-Aktionen)

**Kein manueller Code nötig!** Alles automatisch.

---

## 🚫 Was wird NICHT geloggt?

**Network Errors werden gefiltert:**
```dart
// In main.dart - bereits eingebaut
options.beforeSend = (event, hint) {
  if (event.throwable != null && 
      ErrorHandler.isNetworkError(event.throwable!)) {
    return null; // Nicht senden
  }
  return event;
};
```

**Warum?** Zu viele Events, nicht hilfreich.

---

## 📊 Zusätzlich: Supabase Analytics

**Supabase error_logs** speichert zusätzlich:
- ✅ Business Context (z.B. OBD2 Error Code)
- ✅ Custom SQL Queries möglich
- ✅ Langzeit-Speicherung
- ✅ Error Statistics Dashboard

**Best of Both Worlds:** 
- **Sentry** → Benachrichtigungen & automatisches Tracking
- **Supabase** → Custom Analytics & SQL

---

## 💰 Kosten

**Sentry Free Tier:**
- ✅ 5.000 Events/Monat
- ✅ 1 Projekt
- ✅ 30 Tage Error Retention
- ✅ Email Alerts
- ✅ Performance Monitoring

**Realistisch für WeFixIt:**
- Selbst mit 1.000 aktiven Usern bleibst du unter 5.000 Events
- Die meisten Apps haben ~2-5 Errors pro User pro Monat
- **Du brauchst kein Paid Plan!**

---

## 🎉 Fertig!

**Setup-Zeit: 5 Minuten**

**Du hast jetzt:**
- ✅ Automatisches Error Tracking
- ✅ Email bei jedem Fehler
- ✅ Professionelles Dashboard
- ✅ Stack Traces & Device Info
- ✅ User Context

**Teste jetzt mit dem Demo-Fehler Button!** 🚀
