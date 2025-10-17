# Wartungserinnerungen - Setup Anleitung

## ✅ Was wurde implementiert:

### 1. **Datenbank (Supabase)**
- Migration erstellt: `supabase/migrations/20250116000001_create_maintenance_reminders.sql`
- Tabelle `maintenance_reminders` mit folgenden Features:
  - Datum-basierte Erinnerungen (due_date)
  - Kilometer-basierte Erinnerungen (due_mileage)
  - Wiederkehrende Erinnerungen (täglich/monatlich/jährlich oder km-basiert)
  - Status-Tracking (completed/pending)
  - RLS (Row Level Security) aktiviert

### 2. **Backend**
- `lib/src/models/maintenance_reminder.dart` - Freezed Model
- `lib/src/services/maintenance_service.dart` - CRUD Service

### 3. **UI Screens**
- `lib/src/features/maintenance/maintenance_screen.dart` - Hauptscreen mit Liste
- `lib/src/features/maintenance/add_reminder_dialog.dart` - Dialog zum Anlegen
- Home Screen Integration - Zeigt nächste anstehende Wartung

## 🔧 Setup Schritte:

### Schritt 1: Migration in Supabase ausführen

**Option A: Via Supabase Dashboard**
1. Gehe zu deinem Supabase Projekt: https://supabase.com/dashboard
2. Navigiere zu **SQL Editor**
3. Öffne die Datei `supabase/migrations/20250116000001_create_maintenance_reminders.sql`
4. Kopiere den gesamten Inhalt
5. Füge ihn im SQL Editor ein
6. Klicke auf **Run**

**Option B: Via Supabase CLI** (empfohlen)
```bash
cd c:\Users\Senkbeil\AndroidStudioProjects\wefixit
supabase db push
```

### Schritt 2: Freezed Code generieren

Der build_runner läuft bereits. Falls er fertig ist, prüfe:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Schritt 3: App testen

1. **Starte die App**
   ```bash
   flutter run --dart-define-from-file=env.example
   ```

2. **Teste Wartungserinnerungen:**
   - Navigiere zur Home Screen
   - Wenn eingeloggt: Klicke auf den FloatingActionButton (+) im Maintenance Screen
   - Erstelle eine Test-Erinnerung:
     - Titel: "Ölwechsel"
     - Typ: Datum
     - Datum: In 7 Tagen
   - Die Erinnerung sollte auf dem Home Screen als "Nächste Wartung" erscheinen

## 🎨 Design-Features:

### Wartungs-Card auf Home Screen
- **Farbcodierung:**
  - 🔴 Rot: Überfällig (daysUntil < 0)
  - 🟠 Orange: Bald fällig (daysUntil 0-7)
  - 🟢 Grün: Noch Zeit (daysUntil > 7)
  - 🔵 Blau: Kilometer-basiert

- **Status-Badge:** Zeigt verbleibende Zeit/Kilometer an
- **Gradient-Hintergrund:** Passt sich der Dringlichkeit an
- **Direct Link:** "Details" Button führt zu `/maintenance`

### Wartungs-Screen
- **Liste:** Alle Erinnerungen sortiert nach Fälligkeit
- **Toggle:** Erledigte Erinnerungen ein/ausblenden
- **Status-Icons:**
  - ✅ Erledigt
  - 📅 Datum-basiert
  - 🚗 Kilometer-basiert
- **Actions:**
  - ✓ Als erledigt markieren (Tap auf Card)
  - 🗑️ Löschen (mit Bestätigung)

### Add-Dialog
- **Moderne UI:** Zwei-Spalten Layout für Typ-Auswahl
- **Smart Forms:** Validation & Auto-Formatting
- **DatePicker:** Native Integration
- **Wiederkehrende Optionen:** 3/6/12 Monate als ChoiceChips

## 📝 Verwendung:

### Neue Erinnerung anlegen:
```dart
// Via Service
final service = MaintenanceService(Supabase.instance.client);
await service.createReminder(
  title: 'Ölwechsel',
  description: 'Motoröl wechseln',
  reminderType: ReminderType.date,
  dueDate: DateTime.now().add(Duration(days: 30)),
  isRecurring: true,
  recurrenceIntervalDays: 180, // Alle 6 Monate
);
```

### Nächste Wartung abrufen:
```dart
final nextReminder = await service.fetchNextReminder();
if (nextReminder != null) {
  print('Nächste Wartung: ${nextReminder.title}');
}
```

## 🔐 Sicherheit:

- **RLS aktiviert:** User sehen nur eigene Erinnerungen
- **Policies:**
  - SELECT: Eigene Erinnerungen
  - INSERT: Nur für eigenen user_id
  - UPDATE: Nur eigene Erinnerungen
  - DELETE: Nur eigene Erinnerungen

## ✨ Features:

✅ Datum-basierte Erinnerungen
✅ Kilometer-basierte Erinnerungen
✅ Wiederkehrende Erinnerungen
✅ Status-Tracking (erledigt/ausstehend)
✅ Home-Screen Integration
✅ Moderne UI im App-Design
✅ RLS & Sicherheit
✅ Kostenlos für alle User

## 🚀 Nächste Schritte:

1. ✅ **Wartungserinnerungen** - ERLEDIGT
2. ⏭️ **KFZ-Kosten Tracker** - Als nächstes
3. ⏭️ **RevenueCat & Paywall**
4. ⏭️ **AI Backend (KI-Diagnose & Chatbot)**
5. ⏭️ **OBD-Integration**

---

**Hinweis:** Die Wartungserinnerungen sind **kostenlos für ALLE User**! Eingeloggte User können Erinnerungen anlegen/bearbeiten, nicht-eingeloggte sehen eine Login-Aufforderung.
