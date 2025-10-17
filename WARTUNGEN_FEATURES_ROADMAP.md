# Wartungs-Feature Roadmap

## ✅ PHASE 1: MVP - FERTIG!

### Grundfunktionen
- [x] Wartungseintrag anlegen (Datum)
- [x] Art der Wartung (freier Text: "Titel")
- [x] Wiederkehrende Wartungen (alle X Tage oder km)
- [x] Status: "Geplant", "Erledigt"
- [x] Dashboard mit Statistiken
- [x] Liste aller Wartungen
- [x] Farbcodierung nach Dringlichkeit (Rot/Orange/Grün/Blau)
- [x] Home Screen Integration (Orange Card)

### Technisch
- [x] Supabase Backend
- [x] RLS Policies (user_id)
- [x] Datum & Kilometer Support
- [x] CRUD Operations
- [x] Freezed Models

---

## 🔄 PHASE 2: Erweiterte Funktionen (IN ARBEIT)

### Wartungsdetails erweitern
- [ ] **Kilometerstand** zum Zeitpunkt der Wartung (Feld hinzufügen)
- [ ] **Wartungstyp-Dropdown** statt Freitext
  - Ölwechsel
  - Reifenwechsel  
  - Bremsen
  - TÜV
  - Inspektion
  - Batterie
  - Filter
  - Sonstiges (Custom)
- [ ] **Werkstatt-Informationen**
  - Name
  - Adresse
  - Telefon (optional)
- [ ] **Notizen-Feld** erweitern (mehrzeilig)

### Dokumente & Fotos
- [ ] **PDF/Foto-Upload**
  - Rechnungen hochladen
  - TÜV-Berichte
  - Versicherungspapiere
  - Fotos vom Zustand
- [ ] **Cloud-Speicherung** (Supabase Storage)
- [ ] **Bildergalerie** pro Wartung
- [ ] **PDF-Vorschau** im Detail-Screen

### Kosten-Integration
- [ ] **Kosten-Feld** bei Wartung
  - Preis eingeben
  - Währung (€)
- [ ] **Verknüpfung mit KFZ-Kosten-Tracker**
  - Automatisch Kosteneintrag erstellen
  - Kategorie: "Wartung"
  - Sync zwischen beiden Features

---

## 🔔 PHASE 3: Erinnerungen & Notifications

### Push-Benachrichtigungen
- [ ] **Erinnerung X Tage vorher**
  - 1 Woche vor Fälligkeit
  - 1 Tag vor Fälligkeit
  - Am Tag der Fälligkeit
- [ ] **Kilometerzähler-Benachrichtigung**
  - "Noch 500 km bis Ölwechsel"
  - Basierend auf aktuellem Kilometerstand
- [ ] **Überfällig-Warnung**
  - Täglich erinnern wenn überfällig

### Kalender-Integration
- [ ] **Kalendereintrag erstellen**
  - iOS/Android Kalender
  - Automatisch bei Anlage
  - Optional: Google Calendar Sync

### Intelligente Vorschläge
- [ ] **Nächste Wartung vorschlagen**
  - Basierend auf Historie
  - "Letzter Ölwechsel vor 14.500 km"
  - "Fällig in ca. 500 km"
- [ ] **Wartungsintervalle lernen**
  - Durchschnitt berechnen
  - Muster erkennen

---

## 📊 PHASE 4: Erweiterte Features

### Spezielle Wartungen
- [ ] **TÜV-Modul**
  - Nächster TÜV-Termin prominent
  - Countdown-Widget
  - TÜV-Bericht hochladen
- [ ] **Reifenwechsel Sommer/Winter**
  - Erinnerung März/Oktober
  - Welche Reifen aktuell montiert?
  - Profiltiefe tracken
- [ ] **Versicherung & Steuer**
  - Fälligkeitsdatum
  - Automatische Jahres-Erinnerung
  - Dokumente hinterlegen

### Export & Backup
- [ ] **Export als PDF**
  - Komplette Wartungshistorie
  - Für Werkstatt oder Verkauf
  - Mit Fotos & Rechnungen
- [ ] **Export als CSV**
  - Excel-Import
  - Datenanalyse
- [ ] **Cloud-Synchronisierung**
  - Automatisches Backup
  - Multi-Device Sync
- [ ] **Datenübernahme auf neues Gerät**
  - QR-Code Transfer
  - Backup-Restore

### Statistiken & Analysen
- [ ] **Wartungskosten-Analyse**
  - Kosten pro Jahr
  - Kosten pro Kategorie
  - Durchschnittskosten
- [ ] **Wartungsintervall-Tracking**
  - Durchschnittliche Intervalle
  - Abweichungen erkennen
- [ ] **Jahresvergleich**
  - 2024 vs 2025
  - Kostenentwicklung

---

## 🎨 PHASE 5: UX-Verbesserungen

### Benutzerfreundlichkeit
- [ ] **Quick-Add Shortcuts**
  - "Ölwechsel" mit einem Tap
  - Template-basiert
- [ ] **Wartungs-Templates**
  - Vordefinierte Wartungstypen
  - Mit Standard-Intervallen
- [ ] **Barcode-Scanner**
  - Rechnung scannen
  - Automatisch Preis erkennen (OCR)
- [ ] **Sprachassistent**
  - "Hey Toni, erstelle Ölwechsel-Erinnerung"

### Widgets
- [ ] **Home Screen Widget**
  - Nächste Wartung
  - TÜV-Countdown
  - iOS & Android

---

## 🔧 Technische Todos

### Backend
- [ ] Supabase Storage für Dokumente
- [ ] Image-Upload-API
- [ ] PDF-Generation Server-Side
- [ ] Push-Notification Service

### Database
- [ ] `maintenance_documents` Tabelle
- [ ] `maintenance_types` Tabelle (Wartungsarten)
- [ ] `workshops` Tabelle (Werkstätten)
- [ ] Foreign Keys & Relations

### Frontend
- [ ] Image Picker Integration
- [ ] PDF Viewer Package
- [ ] File Upload UI
- [ ] Local Notifications Package
- [ ] Calendar Integration Package

---

## 📝 Notizen

### Priorität
1. **PHASE 2** (Erweiterte Details) → Nächste Aufgabe
2. **PHASE 3** (Notifications) → Wichtig für UX
3. **PHASE 4** (Export & Backup) → Nice-to-have
4. **PHASE 5** (UX-Verbesserungen) → Langfristig

### Monetarisierung
- ✅ Grundfunktionen: **KOSTENLOS für alle**
- 🔒 PDF-Upload: **Pro-Feature** (Pro Abo oder Lifetime)
- 🔒 Cloud-Backup: **Pro-Feature**
- 🔒 Erweiterte Statistiken: **Pro-Feature**

### Integration mit anderen Features
- **KFZ-Kosten**: Wartungskosten automatisch übertragen
- **Ask Toni**: "Wann war mein letzter Ölwechsel?"
- **Fahrzeugprofil**: Kilometerstand synchronisieren
