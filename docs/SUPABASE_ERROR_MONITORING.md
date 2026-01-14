# 🚨 Error Monitoring: Sentry + Supabase

## Übersicht

**Hybrid-Lösung für bestes Error Tracking:**
- ✅ **Sentry** → Automatische Benachrichtigungen bei allen Fehlern
- ✅ **Supabase** → Custom Analytics & SQL Queries

**Keine Zapier Webhooks nötig!**

---

## ✅ Setup (4 Schritte)

### **Schritt 1: Sentry Account erstellen**

1. **Gehe zu [sentry.io](https://sentry.io/signup/)**
2. **Kostenloses Konto erstellen**
3. **Neues Projekt: Flutter**
4. **DSN kopieren** (z.B. `https://abc123@o123456.ingest.sentry.io/7890123`)
5. **In `main.dart` einfügen:**
   ```dart
   options.dsn = 'DEIN_SENTRY_DSN_HIER';
   ```

**Fertig!** Sentry fängt jetzt automatisch alle Fehler ab.

---

### **Schritt 2: Migration ausführen**

```bash
# Im Projekt-Ordner
cd supabase

# Migration anwenden
supabase db push
```

**Oder im Supabase Dashboard:**
- SQL Editor öffnen
- Migration `20260114_create_error_logs.sql` ausführen

**Was wird erstellt:**
- ✅ `error_logs` Tabelle
- ✅ `error_statistics` View
- ✅ Policies für RLS
- ✅ Trigger für kritische Fehler

---

### **Schritt 3: Sentry Alerts konfigurieren**

1. **Sentry Dashboard** → Dein Projekt → **Alerts**
2. **Create Alert Rule**
3. **Alert Conditions:**
   - "An event is seen"
   - "more than 1 time"
   - "in 1 minute"
4. **Actions:**
   - ✅ **Send a notification via Email**
   - ✅ Optional: Slack, Discord
5. **Save Rule**

**Du bekommst jetzt bei jedem Fehler eine Email!** 📧

---

### **Schritt 4: Flutter Packages installieren**

```bash
flutter pub get
```

**Fertig!** Error Monitoring ist aktiv.

---

## 🎯 Wie es funktioniert

### **Sentry (Automatisch):**

**ALLE Fehler werden automatisch gefangen:**
- ✅ Unhandled Exceptions
- ✅ Flutter Errors
- ✅ Async Errors
- ✅ Network Errors (gefiltert)

**Du bekommst automatisch:**
- Stack Traces
- Device Info (OS, Version, Model)
- User ID (falls eingeloggt)
- Breadcrumbs (letzte User-Aktionen)
- Email-Benachrichtigung

**Kein Code nötig!** Sentry macht alles automatisch.

---

### **Supabase (Custom Analytics):**

**Für spezielle Fehler mit Business Context:**

```dart
// Bei AI Diagnose Fehler
await _errorLogger.logAiDiagnosisError(
  errorMessage: e.toString(),
  errorCode: 'P0420',
  stackTrace: stackTrace.toString(),
);
```

**Vorteile:**
- ✅ Custom SQL Queries
- ✅ Error Statistics Dashboard
- ✅ Langzeit-Speicherung
- ✅ Business Context (z.B. welcher OBD2 Code)

---

## 📊 Error Logs ansehen

### **Sentry Dashboard:**

1. **Issues** → Alle Fehler gruppiert
2. **Performance** → Langsame API Calls
3. **Releases** → Fehler pro App-Version
4. **Email-Benachrichtigungen** bei neuen Fehlern

### **Supabase Dashboard:**

**Option A: Supabase Database Webhooks (VERALTET - Sentry nutzen!)**

1. **Gehe zu Supabase Dashboard** → Database → Webhooks
2. **Neuen Webhook erstellen**:
   - **Name**: `critical_error_notification`
   - **Table**: `error_logs`
   - **Events**: `INSERT`
   - **Type**: `HTTP Request`
   - **HTTP Method**: `POST`
   - **URL**: `https://hooks.zapier.com/...` (siehe unten)

3. **Conditions** (nur kritische Fehler):
   ```sql
   severity = 'critical'
   ```

4. **Payload**:
   ```json
   {
     "error_id": "{{ record.id }}",
     "user_id": "{{ record.user_id }}",
     "error_message": "{{ record.error_message }}",
     "screen": "{{ record.screen }}",
     "error_code": "{{ record.error_code }}",
     "created_at": "{{ record.created_at }}"
   }
   ```

---

#### **Option B: Zapier (für Email/Slack/Discord)**

**Zapier verbindet Supabase → Email/Slack/Discord**

1. **Gehe zu [zapier.com](https://zapier.com)** → Kostenloses Konto
2. **Neuen Zap erstellen**:

**Trigger:**
- App: **Webhooks by Zapier**
- Event: **Catch Hook**
- Kopiere die Webhook URL (z.B. `https://hooks.zapier.com/hooks/catch/123456/abcdef/`)

**Action:**
- **Option 1 - Email:**
  - App: **Email by Zapier**
  - Event: **Send Outbound Email**
  - To: `deine-email@example.com`
  - Subject: `🚨 WeFixIt Critical Error: {{error_message}}`
  - Body:
    ```
    Error Details:
    - Message: {{error_message}}
    - Screen: {{screen}}
    - Error Code: {{error_code}}
    - User ID: {{user_id}}
    - Time: {{created_at}}
    
    View in Supabase: https://supabase.com/dashboard/project/YOUR_PROJECT/editor/error_logs
    ```

- **Option 2 - Slack:**
  - App: **Slack**
  - Event: **Send Channel Message**
  - Channel: `#wefixit-errors`
  - Message:
    ```
    🚨 *Critical Error in WeFixIt*
    
    *Message:* {{error_message}}
    *Screen:* {{screen}}
    *Error Code:* {{error_code}}
    *User:* {{user_id}}
    *Time:* {{created_at}}
    ```

- **Option 3 - Discord:**
  - App: **Discord**
  - Event: **Send Channel Message**
  - Webhook URL: (Discord Channel Settings → Integrations → Webhooks)
  - Content: Wie Slack

3. **Test den Zap** (sendet Test-Email)
4. **Zapier URL in Supabase Webhook einfügen** (Schritt 2, Option A)

---

#### **Option C: Supabase Edge Function (fortgeschritten)**

Für mehr Kontrolle kannst du eine Edge Function erstellen:

```typescript
// supabase/functions/notify-error/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { record } = await req.json()
  
  // Nur kritische Fehler
  if (record.severity !== 'critical') {
    return new Response('OK', { status: 200 })
  }
  
  // Email via SendGrid/Mailgun/etc.
  await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SENDGRID_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{
        to: [{ email: 'deine-email@example.com' }],
      }],
      from: { email: 'alerts@wefixit.app' },
      subject: `🚨 WeFixIt Critical Error: ${record.error_message}`,
      content: [{
        type: 'text/plain',
        value: `
Error Details:
- Message: ${record.error_message}
- Screen: ${record.screen}
- Error Code: ${record.error_code}
- User ID: ${record.user_id}
- Time: ${record.created_at}
        `,
      }],
    }),
  })
  
  return new Response('OK', { status: 200 })
})
```

Deploy: `supabase functions deploy notify-error`

Webhook URL: `https://YOUR_PROJECT.supabase.co/functions/v1/notify-error`

---

### **Schritt 3: Test**

Im Demo-Modus auf "Demo-Fehler testen" klicken:

1. Fehler wird in `error_logs` gespeichert
2. Webhook wird getriggert (falls kritisch)
3. Du bekommst Email/Slack/Discord Benachrichtigung
4. Check Supabase Dashboard → Database → error_logs

---

## 📊 Error Logs ansehen

### **Im Supabase Dashboard:**

1. **Database** → **Table Editor** → `error_logs`
2. Siehe alle Fehler mit Details
3. Filter nach:
   - User ID
   - Severity (critical, high, medium, low)
   - Screen
   - Datum

### **Error Statistics View:**

```sql
SELECT * FROM error_statistics
WHERE date >= NOW() - INTERVAL '7 days'
ORDER BY error_count DESC;
```

Zeigt:
- Fehler pro Tag
- Betroffene User
- Häufigste Fehler
- Pro Screen

---

## 🎯 Was wird geloggt?

### **Automatisch bei jedem Fehler:**
- ✅ User ID (wer war betroffen?)
- ✅ Error Type (`ai_diagnosis_error`, `obd2_connection_error`, etc.)
- ✅ Error Message
- ✅ Stack Trace
- ✅ Screen Name
- ✅ Error Code (z.B. OBD2 Code)
- ✅ Device Info (OS, Version)
- ✅ Context (zusätzliche Daten)
- ✅ Severity (low, medium, high, critical)
- ✅ Timestamp

### **Severity Levels:**

| Level | Wann | Benachrichtigung |
|-------|------|------------------|
| `low` | Unwichtige Fehler | Nein |
| `medium` | Standard Fehler | Nein |
| `high` | Wichtige Fehler (z.B. AI) | Optional |
| `critical` | Kritische Fehler | **JA** ✅ |

---

## 💡 Best Practices

### **1. Fehler kategorisieren:**

```dart
// AI Diagnose Fehler
await _errorLogger.logAiDiagnosisError(
  errorMessage: e.toString(),
  errorCode: code,
  stackTrace: stackTrace.toString(),
);

// OBD2 Connection Fehler
await _errorLogger.logObd2Error(
  errorMessage: e.toString(),
  stackTrace: stackTrace.toString(),
);

// Kritische Fehler (bekommt Benachrichtigung!)
await _errorLogger.logCriticalError(
  errorMessage: 'Payment system down',
  screen: 'checkout',
  stackTrace: stackTrace.toString(),
);
```

### **2. Sensitive Daten filtern:**

```dart
// NIEMALS:
await _errorLogger.logError(
  errorMessage: 'Login failed for ${email} with password ${password}', // ❌
);

// STATTDESSEN:
await _errorLogger.logError(
  errorMessage: 'Login failed',
  context: {
    'email_domain': email.split('@').last, // ✅ Nur Domain
    // KEIN Passwort!
  },
);
```

### **3. Error Resolution tracken:**

```sql
-- Im Supabase Dashboard
UPDATE error_logs 
SET resolved = true, resolved_at = NOW()
WHERE id = 'error-id-hier';
```

---

## 📧 Email-Beispiel

**Bei kritischem Fehler bekommst du:**

```
Von: WeFixIt Alerts <alerts@wefixit.app>
An: deine-email@example.com
Betreff: 🚨 WeFixIt Critical Error: Die KI-Analyse ist momentan nicht verfügbar

Error Details:
- Message: Die KI-Analyse ist momentan nicht verfügbar. Bitte versuche es später erneut.
- Screen: ai_diagnosis_detail
- Error Code: P0420
- User ID: abc-123-def
- Time: 2026-01-14 09:45:32+00

View in Supabase:
https://supabase.com/dashboard/project/YOUR_PROJECT/editor/error_logs

Device Info:
- Platform: android
- Version: Android 13

Stack Trace:
[... stack trace ...]
```

---

## 🔄 Testing

### **1. Demo-Fehler testen:**
- App öffnen → Demo-Modus
- "Demo-Fehler testen" klicken
- Prüfen:
  - Fehler-Screen erscheint ✅
  - Supabase → error_logs → Neuer Eintrag ✅
  - Email erhalten (falls Webhook eingerichtet) ✅

### **2. Webhook testen (Zapier):**
```bash
curl -X POST https://hooks.zapier.com/hooks/catch/YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "error_message": "Test Error",
    "screen": "test",
    "error_code": "TEST",
    "user_id": "test-user",
    "created_at": "2026-01-14T09:00:00Z"
  }'
```

Du solltest sofort eine Email bekommen!

---

## 🚀 Vorteile gegenüber Sentry

| Feature | **Supabase** | Sentry |
|---------|-------------|--------|
| **Kosten** | ✅ Kostenlos (in deinem Plan) | Limit 5K/Monat |
| **Kein Extra-Account** | ✅ Alles in Supabase | Extra Account |
| **Eigene Daten** | ✅ In deiner DB | Externe Server |
| **Custom Queries** | ✅ SQL direkt | API nur |
| **Dashboard** | ✅ Supabase Dashboard | Sentry Dashboard |
| **Webhooks** | ✅ Ja | Ja |
| **Email-Alerts** | ✅ Via Zapier/Edge Function | ✅ Built-in |

---

## 📝 Quick Setup Checklist

- [ ] Migration `20260114_create_error_logs.sql` ausführen
- [ ] Zapier Account erstellen (kostenlos)
- [ ] Webhook Catch Hook in Zapier erstellen
- [ ] Email Action in Zapier konfigurieren
- [ ] Webhook URL kopieren
- [ ] Supabase Database Webhook erstellen
- [ ] Condition `severity = 'critical'` setzen
- [ ] Webhook URL einfügen
- [ ] Test: Demo-Fehler in App auslösen
- [ ] Prüfen: Email erhalten? ✅

**Setup Zeit: ~10 Minuten** 🚀

---

## 🔧 Troubleshooting

**Problem: Keine Email erhalten?**
- ✅ Check Supabase → error_logs → Fehler vorhanden?
- ✅ Check Webhook → Logs (Database → Webhooks → View Logs)
- ✅ Check Zapier → Task History
- ✅ Severity auf `critical` gesetzt?

**Problem: Zu viele Emails?**
- ✅ Severity nur auf `critical` setzen
- ✅ Webhook Condition anpassen
- ✅ Rate Limiting in Edge Function

**Problem: Fehler werden nicht geloggt?**
- ✅ RLS Policies prüfen
- ✅ User eingeloggt?
- ✅ Service aufgerufen? (`await _errorLogger.logError(...)`)

---

**Du hast jetzt ein komplettes Error Monitoring System - alles in Supabase!** 🎉
