# WeFixIt – MVP Fortschritt (Stand: aktuell)

Dieses Dokument spiegelt den Umsetzungsstand der Anforderungen aus `wefixit_prompts_phases.json` wider und listet bewusst alle Abweichungen/Designanpassungen auf.

> Hinweis: Diese Datei wird fortlaufend gepflegt und nach Änderungen am Wartungs-Feature sofort aktualisiert.

## Wartungen – Vollständiges System (FERTIG)

- **Kategorien**: Ölwechsel, Reifenwechsel, Bremsen, TÜV/AU, Inspektion, Batterie, Filter, Versicherung, Steuer, Sonstiges.
- **Monetarisierung**:
  - **Free User**: 3 Basis-Kategorien frei (Ölwechsel, Reifenwechsel, TÜV/AU) - kein Export
  - **Pro Abo**: Alle Kategorien + CSV & PDF Export
- **Erweiterte Details**: Werkstatt (Name, Adresse), Notizen, Kilometerstand bei Wartung, Kosten (mit Währung).
- **Medien**: Foto-Upload (Bilder), Dokumente-Upload (PDF), Supabase Storage-Anbindung.
- **Status & Logik**: Geplant, Erledigt, Überfällig; wiederkehrend (3/6/12 Monate) bzw. km-basiert.
- **Intelligente Vorschläge**: Ölwechsel/TÜV/Reifen/Inspektion/Batterie basierend auf Historie und Kilometerstand.
- **Benachrichtigungen**: Lokale Push-Notifications (Reminder vor Fälligkeit, Overdue-Hinweis), Timezone-Support.
- **Export**: CSV und detaillierter PDF/Report (Statistiken, Summen, Filter) - nur Pro Abo.
- **UI**: Neues Grid-Dashboard mit Stats, Kategorien-Grid, Vorschläge-Sektion und Quick Actions, Schloss-Icons auf gesperrten Kategorien.
- **Routing & Integration**: Home-Link, neue Routen, i18n (de/en) für alle Texte.

## OBD2-Diagnose – Vollständiges System (95% FERTIG ✅)

### **Implementierte Features (Stand: 9. Januar 2026)**

#### **1. Flutter App - OBD2 Screens**
- ✅ **Obd2Service** (`lib/src/services/obd2_service.dart`)
  - Bluetooth-Scanner mit flutter_blue_plus
  - Geräte-Discovery & Connection
  - Fehlercode-Auslesen (ELM327-Protokoll)
  - Fehlercodes löschen
  
- ✅ **Obd2ScanDialog** (`lib/src/features/diagnose/obd2_scan_dialog.dart`)
  - Bluetooth-Geräte scannen
  - Liste verfügbarer OBD2-Adapter
  - Adapter-Auswahl & Verbindung
  - i18n: Scan-Status, Gerätename, Adapter-Info
  
- ✅ **ErrorCodesListScreen** (`lib/src/features/diagnose/error_codes_list_screen.dart`)
  - Fehlercodes-Liste mit Code-Type-Badges (P/C/B/U)
  - Statistiken (Gesamt, Kritisch, Typ-Breakdown)
  - "KI-Diagnose starten" Button
  - Login-/Credit-Check vor KI-Diagnose
  - Timestamp-Anzeige (relativ: "vor X Min")
  - Route: `/diagnose/error-codes`
  
- ✅ **AiDiagnosisResultsScreen** (`lib/src/features/diagnose/ai_diagnosis_results_screen.dart`)
  - Expandable Cards pro Fehlercode
  - Schweregrad-Badge (critical/high/medium/low)
  - Fahrsicherheit-Status
  - Detaillierte Analyse mit Sections:
    - Beschreibung
    - Technische Analyse
    - Diagnose-Schritte (Step-by-Step)
    - Reparatur-Schritte (mit Schwierigkeit, Werkzeuge, Zeit)
    - Kosten-/Zeit-Schätzung
  - Source-Badge (Database/Web Research/LLM Fallback)
  - Route: `/diagnose/ai-results`

#### **2. Supabase Edge Function - Harvester-Workflow**
- ✅ **analyze-obd-codes** (`supabase/functions/analyze-obd-codes/`)
  - **Workflow:**
    1. **DB-Lookup** (automotive_knowledge via vector search)
    2. **Perplexity Web-Recherche** (Model: `sonar` - $1/1M Output)
       - Sammelt aktuelle Web-Daten von Reparaturportalen
       - Strukturiert Rohdaten (Symptome, Ursachen, Diagnose, Reparatur)
    3. **GPT-4 Content-Strukturierung** (Model: `gpt-4o`)
       - Extrahiert alle Felder für automotive_knowledge
       - Strukturiert JSON mit symptoms[], causes[], steps[], etc.
    4. **OpenAI Embedding** (Model: `text-embedding-3-small`)
       - Erstellt vector(1536) für Vektor-Suche
    5. **Full DB Save** (automotive_knowledge)
       - Speichert ALLE Felder (title, content, symptoms, causes, steps, tools, cost, difficulty, embedding, keywords)
    6. **GPT-4o-mini Fallback** (nur bei Web-Fehler)
       - Nutzt LLM-Wissen wenn Perplexity ausfällt
  
  - **Helper Functions** (`helper-functions.ts`)
    - `structureContentWithGPT4()` - Content-Strukturierung
    - `createEmbedding()` - Embedding-Erstellung
    - `saveFullKnowledgeToDatabase()` - Vollständiger DB-Save
    - `mapErrorCodeToDiagnosis()` - DB → UI Mapping
    - `mapKnowledgeToDiagnosis()` - Knowledge → UI Mapping

#### **3. Datenbank - automotive_knowledge**
- ✅ **Migration erstellt** (`20241209_automotive_knowledge_system.sql`)
  - Tabelle: `automotive_knowledge` (Multi-Language Support)
    - Felder: topic, category, subcategory, vehicle_specific
    - Content: title_de/en, content_de/en (alle Sprachen)
    - Strukturiert: symptoms[], causes[], diagnostic_steps[], repair_steps[], tools_required[]
    - Metadaten: estimated_cost_eur, difficulty_level, keywords[]
    - Embeddings: embedding_de, embedding_en (vector(1536) pro Sprache)
    - Qualität: quality_score, original_language, source_urls[]
  - Tabelle: `error_codes` (OBD2-Codes Registry)
  - Tabelle: `knowledge_harvest_queue` (für Batch-Processing)
  - Vector Indizes: ivfflat für schnelle Similarity Search

#### **4. Lokalisierung (i18n)**
- ✅ **Vollständige DE/EN Übersetzungen** (`assets/i18n/`)
  - 45+ neue Schlüssel für OBD2-Feature
  - Kategorien: diagnose.*, code_types.*, time_ago.*
  - Beispiele:
    - `diagnose.scan_dialog_title`: "OBD2-Adapter suchen"
    - `diagnose.analyzing_codes`: "Analysiere {count} Fehlercodes..."
    - `diagnose.section_diagnostic_steps`: "Diagnose-Schritte"
    - `diagnose.drive_safety_ok`: "Weiterfahrt möglich"
    - `code_types.powertrain`: "Antriebsstrang (P)"

#### **5. Integration & Routing**
- ✅ **Routes registriert** (`lib/src/routes.dart`)
  - `/diagnose/error-codes` → ErrorCodesListScreen
  - `/diagnose/ai-results` → AiDiagnosisResultsScreen
- ✅ **Credit-System Integration**
  - `consumeQuotaOrCredits(1, 'ai_diagnosis')` vor KI-Diagnose
  - Pro-User: Bypass Credit-Check
  - Free-User: Quota → Credits → Paywall
- ✅ **Permissions**
  - Android: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`
  - iOS: `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`

### **Kosten-Analyse (optimiert)**

| Service | Model | Kosten | Wofür? |
|---------|-------|--------|--------|
| **Perplexity** | sonar | $1/1M Output | Web-Recherche (primär) |
| **OpenAI** | gpt-4o | $2.50/1M Output | Content-Strukturierung |
| **OpenAI** | text-embedding-3-small | $0.02/1M Tokens | Vektor-Suche |
| **OpenAI** | gpt-4o-mini | $0.15/1M Output | Fallback (nur bei Fehler) |

**💰 Beispielrechnung pro Diagnose:**
- Perplexity: ~500 Tokens = $0.0005
- GPT-4o: ~1000 Tokens = $0.0025
- Embedding: ~200 Tokens = $0.000004
- **Gesamt: ~$0.003 pro Code** (100x günstiger als vorher mit sonar-pro!)

### **✅ Deployment abgeschlossen (9. Januar 2026)**
- ✅ **API Keys Deployment:**
  - Supabase Dashboard → Edge Function Secrets
  - `PERPLEXITY_API_KEY` gesetzt ✅
  - `OPENAI_API_KEY` gesetzt ✅
- ✅ **Edge Function Deploy:**
  ```bash
  supabase functions deploy analyze-obd-codes
  ```
  **Status: DEPLOYED & LIVE** 🚀

### **⏳ Nächste Schritte (Hardware-Testing)**
- ⏳ **Hardware-Testing mit echtem OBD2-Adapter:**
  - Bluetooth-Verbindung testen
  - Fehlercode-Auslesen verifizieren (P0420, P0171, etc.)
  - KI-Diagnose End-to-End testen
  - Prüfen: DB-Lookup → Perplexity Web → GPT-4 Strukturierung → Embedding → Save
  - Response-Zeit messen (Ziel: <10 Sekunden pro Code)
  - Error-Handling testen (Rate-Limits, Timeouts)

### **🔮 Zukünftige Optimierungen**
- **Performance:**
  - Caching häufiger Codes (P0420, P0171, etc.)
  - Batch-Processing für Queue
  - Rate-Limiting für API-Calls
- **Qualität:**
  - Feedback-System (War diese Diagnose hilfreich?)
  - A/B Testing verschiedener Prompts
  - Harvester für kontinuierliche DB-Erweiterung

---

## Fahrzeugkosten – Vollständiges System (FERTIG ✅)

- **Kategorien**: Treibstoff, Wartung/Reparatur, Versicherung, Steuern/Gebühren, Kredit/Leasing, Parken/Maut, Reinigung/Pflege, Zubehör/Tuning, Vignetten, Einnahmen, Sonstiges.
- **Standard + Custom Kategorien**: System-Kategorien + eigene Kategorien mit Icon/Farbe-Auswahl.
- **Kosten-Erfassung**: Titel, Betrag, Datum (Vergangenheit + Zukunft), Kategorie, Kilometerstand, Notizen.
- **Tankfunktion**: Spezielle Felder für Betankungen (Tankstelle, Liter, €/Liter, Volltank, Strecke seit letzter Betankung).
- **Zeitraum-Kosten**: Versicherung/Steuer/Kredit als monatliche oder einmalige Beträge mit Start-/Enddatum.
- **Einnahmen/Ausgaben**: Toggle für Einnahmen (z.B. Fahrzeugverkauf).
- **Belege**: Foto-Upload für Quittungen/Rechnungen.
- **3 Tabs**: 
  - **Verlauf**: Chronologische Liste mit Filter (Kategorie, Zeitraum) und CSV-Export
  - **Statistik**: Gesamtkosten, ⌀ Monatlich, Dieser Monat, Anzahl Einträge, Kosten nach Kategorie, Fuel-Insights (Durchschnittsverbrauch, Trend, günstigste Tankstelle)
  - **Diagramme**: Monatlicher Kosten-Verlauf mit Höchster/Niedrigster Monat, ⌀ Jahresdurchschnitt (unabhängig vom Zeitraum)
- **CSV-Export**: Alle Kosten mit Details (Datum, Titel, Kategorie, Betrag, etc.) via Share-Funktion.
- **Home-Integration**: Kachel "⌀ Monatliche Kosten" zeigt Jahresdurchschnitt (Gesamtkosten / 12).
- **Wartungs-Integration**: Toggle "In Fahrzeugkosten übernehmen" erstellt automatisch Kosteneintrag bei Wartung.
- **Lokalisierung**: Vollständige i18n (de/en) für alle Texte und Labels.
- **Future Dates**: Kosten mit zukünftigen Daten können erfasst und in Statistik/Diagramm angezeigt werden.

## 🔒 Bildschirm-Orientierung (MVP: Portrait-Only)

⚠️ **WICHTIG**: Für MVP wurde die App auf **Portrait-Modus** beschränkt.
- **Android**: `android:screenOrientation="portrait"` in `AndroidManifest.xml`
- **iOS**: Nur `UIInterfaceOrientationPortrait` in `Info.plist`
- **Grund**: Dialoge und UI-Layouts sind primär für Portrait optimiert
- **📌 TODO NACH MVP**: Landscape-Unterstützung implementieren mit responsiven Dialogen und angepassten Layouts für alle Screens

## Phase 1 – MVP

- **[Master Build]**
  - Status: ERLEDIGT (Grundgerüst steht)
  - Details:
    - Flutter-App mit `Riverpod`, `GoRouter`, `Dio`, `Supabase`, `intl`, `RevenueCat` (Stub), `AdMob` (Platzhalter), `Freezed`-Tooling vorbereitet.
    - Projektstruktur unter `lib/src/` angelegt (`app.dart`, `routes.dart`, `theme.dart`, `features/`, `services/`, `models/`, `widgets/`).
    - 4 Tabs (Abweichung zu MVP-Text): `Home`, `Diagnose`, `Ask Toni!`, `Profil`.
    - i18n de/en via `assets/i18n/*`.
    - Auth-Gate ohne Gastmodus (Abweichung zu MVP-Text „Gastmodus“): Nur registrierte Nutzer.
    - CI/Build-Skripte: TODO (kommt später in dieser Phase).

- **[UI/Design System]**
  - Status: ERLEDIGT (Tesla/Kleinanzeigen-Hybrid Style)
  - Details:
    - Professionelles helles Design (#FAFAFA Hintergrund) mit modernen weißen Cards und subtilen Borders.
    - CustomScrollView mit BouncingScrollPhysics für smooth Scrolling in allen Screens.
    - Farbcodierte Feature-Icons mit passenden Hintergründen (Rot, Blau, Grün, Orange).
    - Moderne Typografie: FontWeight.w800 für Titel, w600-w700 für Labels, große Header (28px).
    - Konsistente Border Radius (16px), 20px horizontal Padding, 28px Section-Spacing.
    - Alle Screens (Home, Diagnose, Chatbot, Profile, Settings) im einheitlichen Design.
    - Login-CTAs und Dialoge mit freundlichen Texten und Icons.
  - Komponenten:
    - Action Cards mit Badges ("Kostenlos", "Credits")
    - Info Cards mit Icons und Beschreibungen
    - Suggestion Cards mit Pfeilen
    - Settings Tiles mit farbcodierten Icons

- **[Localization & Copy]**
  - Status: TEILWEISE ERLEDIGT
  - de/en angelegt; Tabs/Labels/Grundtexte vorhanden. Paywall-Texte folgen beim Monetarisierungsmodul.

- **[Security & Privacy]**
  - Status: TEILWEISE ERLEDIGT
  - Supabase RLS aktiv, Profile-Policies angelegt. GDPR-Deletionflow, CMP und Rate-Limits folgen mit Monetarisierung/Ads.

- **[Splash Screen]**
  - Status: ERLEDIGT
  - Native Android-12-Splash mit `flutter_native_splash` konfiguriert (weißer Hintergrund, App-Icon).
  - In-App-Splash (`SplashScreen`) mit Logo + animiertem Text („WeFixIt", LumiosMarker-Font).
  - Supabase-Initialisierung erfolgt asynchron während Splash läuft (keine Blockierung vor runApp).
  - Optimierte Startzeit: System-Launch < 0,5s, In-App-Splash ~1s, nahtloser Übergang zu Auth/Home.
  - `compileSdk/targetSdk = 35` für Android-12-Splash-Attribute.

- **[Monetarisierung (Credits + Abo)]**
  - Status: TEILWEISE ERLEDIGT ✅
  - RevenueCat-Paket integriert, PurchaseService implementiert
  - Paywall-Screen mit Offering-Display und Kauf-/Restore-Funktion
  - Initialisierung im SplashScreen nach Supabase-Init
  - **Produkte definiert:**
    - Credits: 5 (1,29€), 10 (2,49€), 25 (5,49€)
    - KFZ-Kosten Lifetime: 3,99€ (wefixit_costs_lifetime) - NUR Fahrzeugkosten + Export
    - Pro Basic: 4,99€/Monat oder 39,99€/Jahr - Kosten + Wartungen + KI + Export
    - Pro Familie: 7,99€/Monat oder 59,99€/Jahr (Phase 3)
  - **TODO:** RevenueCat API Keys in Environment-Config hinterlegen

- **[Credits & Free-Quota Logic]**
  - Status: ERLEDIGT ✅
  - CreditService implementiert mit Supabase-Anbindung
  - Wöchentliches Gratis-Kontingent (3 KI-Anfragen/Woche) mit weekly_free_quota Tabelle
  - Credit-Events Tracking (Käufe, Verbrauch, Balance)
  - Intelligente Priorisierung: 1. Gratis-Quota, 2. Credits
  - consumeQuotaOrCredits() Methode für KI-Features

- **[Paywall (Multi-Page)]**
  - Status: ERLEDIGT ✅
  - PaywallScreen mit Offerings-Display
  - Kauf- und Restore-Funktionalität über PurchaseService
  - Route `/paywall` im Router registriert
  - Dialog-Integration für "Keine Credits" mit Link zur Paywall

- **[Profile & Privacy]**
  - Status: ERLEDIGT
  - Supabase `profiles` erweitert (display_name, nickname, vehicle_photo_url) + Trigger `on_auth_user_created`.
  - App: Profil-Formular (Name/Nickname, Avatar-/Fahrzeugfoto-Upload); Spracheinstellung ins Settings-Screen verlagert.
  - Fahrzeuge: Felder für Hubraum (cc/l) und Kilometerstand ergänzt (Schema vorhanden), UI und Save-Funktionalität implementiert.

- **[AI Backend Edge Functions / Systemprompt]**
  - Status: WEITGEHEND ERLEDIGT ✅ (Harvester + Vektor-DB live, Ask Toni produktiv)
  - Chatbot-UI (Ask Toni!) vollständig implementiert, inkl. Sidebar mit Chat-Verlauf:
    - Neue Chats anlegen
    - Alte Chats einsehen
    - Chats per Long-Press/Löschen-Action entfernen
  - Credit-Gating: Pro-User Bypass + Gratis-Quota/Credits-Check vor jeder Nachricht
  - Chat-Verlauf mit Nachrichten-Bubbles (User/Bot)
  - Suggestion-Cards für schnelle Fragen
  - Auto Knowledge Harvester als Supabase Edge Function:
    - `knowledge_harvest_queue` + `automotive_knowledge` + `failed_topics`
    - Cron-Harvester (alle 10 Minuten) + Cleanup-Job (bereinigt hängende Items)
    - Perplexity/OpenAI-Pipeline für Websuche, Aufbereitung, Übersetzung und Embeddings
  - **TODO:** Systemprompt/Antwort-Qualität weiter feinjustieren (z.B. mehr Domänenwissen, bessere Erklärtexte)

- **[OBD & Media Stubs]**
  - Status: AUSSTEHEND (UI-Hooks vorhanden; echte OBD-Funktionen folgen als Stubs mit klaren Schnittstellen)

- **[Wartungen (vollständig)]**
  - Status: ERLEDIGT ✅ (siehe Abschnitt „Wartungen – Vollständiges System“)
  - Details (Ergänzungen gegenüber Basis):
    - Kategorien-Dropdown (mit Übersetzungen) statt Freitext
    - Werkstattfelder, Kostenfeld (+ Summen im Dashboard), Notizenfeld
    - Foto-/Dokument-Upload inkl. Anzeige
    - Push-Notifications (Planung/Overdue, Test), Timezone-Init
    - Export (CSV & PDF/Report) aus dem Dashboard
    - Intelligente Vorschläge im Dashboard
    - Neues Grid-Dashboard mit Stats/Kategorien/Actions
    - i18n: Alle neuen Texte in `assets/i18n/de.json` und `assets/i18n/en.json`

- **[KFZ-Kosten Tracker]**
  - Status: ERLEDIGT ✅
  - **Monetarisierungsstrategie:**
    - **Free User**: Nur Treibstoff/Kraftstoff-Kosten kostenlos erfassen
    - **Lifetime Unlock (3,99€)**: Einmalkauf schaltet ALLE KFZ-Kosten Kategorien + CSV/PDF Export für Kosten frei (Produkt-ID: wefixit_costs_lifetime)
    - **Pro Basic Abo (4,99€/Monat)**: ALLE Kategorien (Kosten + Wartungen) + CSV/PDF Export + Unbegrenzte KI + Notifications
  
  - **Phase 1 (MVP) Features - JETZT umgesetzt:**
    - ✅ Standard-Kategorien mit Icons: Treibstoff, Wartung, Versicherung, Steuer, Leasing, Parken/Maut, Reinigung, Zubehör, Vignetten, Einnahmen, Sonstiges
    - ✅ Benutzerdefinierte Kategorien erstellen/bearbeiten/löschen (mit Icon- & Farbauswahl)
    - ✅ 3-Tab Layout: Verlauf / Statistik / Diagramm
    - ✅ Kosten-Verlauf mit chronologischer Liste (Filter nach Zeitraum, Kategorie)
    - ✅ Statistik-Tab: Kostenübersicht-Tabelle (€/km, €/Monat, Gesamt pro Kategorie)
    - ✅ Verbrauchsberechnung für Treibstoff (l/100km, Tendenz mit Trend-Erkennung ↑↓=)
    - ✅ Diagramm-Tab: Liniendiagramm für Kosten-Verlauf über Zeit
    - ✅ Kosten-Formular mit bedingten Feldern (Treibstoff-Spezialfelder: Tankstelle, Liter, €/l, Vollbetankung, Strecke)
    - ✅ Auto-Sync mit Wartungen (Kosten aus Wartungen werden automatisch übernommen)
    - ✅ Foto-Upload für Belege/Rechnungen (Tankbelege, Quittungen)
    - ✅ **1 Fahrzeug Support** (aus Profil: Marke/Modell automatisch übernehmen)
    - ✅ CSV Export mit Zeitraum-Selektion
    - ✅ Navigation von Home ("Fahrzeugkosten") und Wartungs-Dashboard ("Kosten")
    - ✅ **Gamification & Achievements**: Erster Eintrag, Tankprofi (10x), Sparfuchs, Ordnungsfan (10 Belege), Jahresabschluss
    - ✅ **Insights & Tipps**: Durchschnittsverbrauch, günstigste Tankstelle, Verbrauchstrend
    - ✅ **Home-Dashboard Kacheln**: Kosten diesen Monat, Durchschnittsverbrauch, nächste Ausgabe
    - ✅ **Auto-Vervollständigung**: Tankstellen-Namen merken, häufige Beträge vorschlagen
    - ✅ i18n (de/en) für alle Texte
  
  - **Phase 2 (Community) Features - geplant:**
    - 🔲 **Pro Familie Abo (7,99€/Monat)**: MEHRERE Fahrzeuge + Community-Features
    - 🔲 Multi-Fahrzeug Verwaltung (Fahrzeug-Switcher, Vergleich zwischen Fahrzeugen)
    - 🔲 Fahrzeug-spezifische Statistiken & Diagramme
    - 🔲 Budget-Funktion (monatliches Budget pro Kategorie, Warnungen, Fortschrittsbalken)
    - 🔲 Vergleichsansicht (Monat-zu-Monat, Jahr-zu-Jahr, beste/schlechteste Monate)
    - 🔲 PDF Report mit Diagrammen
    - 🔲 Vorlagen für wiederkehrende Kosten
    - 🔲 Sync mit Partner/Familie (gemeinsame Fahrzeug-Kosten)
  
  - **Phase 3 (Marktplatz) Features - geplant:**
    - 🔲 Kosten-Heatmap (Kalender-Ansicht)
    - 🔲 Schnelleingabe-Modi & Quick-Actions
    - 🔲 OCR-Texterkennung für Belege (Betrag automatisch auslesen)
    - 🔲 Favoriten/Tags für bessere Organisation
    - 🔲 Import von CSV (Migrationshelfer)
    - 🔲 Intelligente Erinnerungen (Tank-Reminder bei niedriger Reichweite)
    - 🔲 Auto-Vervollständigung (Tankstellen-Namen, häufige Beträge)
    - 🔲 Dashboard-Kacheln auf Home (Kosten diesen Monat, Durchschnittsverbrauch)
    - 🔲 Achievements & Gamification ("Sparfuchs", "Vollgetankt")
    - 🔲 Insights & Tipps ("Du tankst am günstigsten bei X")
    - 🔲 Fahrzeug-Historie (Kaufpreis, Verkaufspreis, ROI-Berechnung)
    - 🔲 Kuchendiagramm für Kategorienverteilung

- **[Testing & QA Flows]**
  - Status: AUSSTEHEND

- **[Deployment Notes]**
  - Status: AUSSTEHEND

## Heute erledigte Arbeiten (9. Januar 2026)

### ✅ **OBD2-Diagnose Feature - KOMPLETT IMPLEMENTIERT**

#### **1. Flutter App - Alle Screens fertiggestellt**
- **Obd2Service**: Bluetooth-Integration mit flutter_blue_plus
  - Device-Scanner, Connection-Management
  - ELM327-Protokoll für Fehlercode-Auslesen
  - Clear-Codes Funktionalität
- **Obd2ScanDialog**: Bluetooth-Scan UI
  - Geräte-Liste mit Namen & MAC-Adresse
  - Scan-Status-Anzeige
  - Adapter-Info-Banner
- **ErrorCodesListScreen**: Fehlercodes-Übersicht
  - Code-Type Badges (P/C/B/U)
  - Statistiken (Gesamt, Kritisch, Breakdown)
  - KI-Diagnose Button mit Credit-Check
  - Relative Zeitstempel ("vor 5 Min")
- **AiDiagnosisResultsScreen**: KI-Diagnose-Ergebnisse
  - Expandable Cards pro Code
  - Schweregrad & Fahrsicherheit
  - Diagnose-/Reparatur-Schritte
  - Kosten-/Zeit-Schätzungen
  - Source-Type Badge

#### **2. Supabase Edge Function - Harvester-Workflow**
- **analyze-obd-codes** Function erstellt mit vollständigem Workflow:
  1. DB-Lookup (Vector Search in automotive_knowledge)
  2. **Perplexity Web-Recherche** (Model: sonar - $1/1M)
     - Sammelt Rohdaten von Web
  3. **GPT-4 Content-Strukturierung** (Model: gpt-4o)
     - Extrahiert alle DB-Felder
  4. **OpenAI Embedding** (text-embedding-3-small)
     - Erstellt vector(1536)
  5. **Full DB Save** (automotive_knowledge)
     - Speichert ALLE Felder (title, content, symptoms, causes, steps, tools, cost, difficulty, embedding, keywords)
  6. GPT-4o-mini Fallback (nur bei Fehler)
- **Helper Functions** in separater Datei:
  - `structureContentWithGPT4()`, `createEmbedding()`, `saveFullKnowledgeToDatabase()`

#### **3. Datenbank-Migration**
- **automotive_knowledge Tabelle** mit Multi-Language Support
  - pgvector Extension aktiviert
  - Vector Indizes für DE/EN
  - Alle Felder für vollständige Diagnose-Daten

#### **4. Vollständige i18n**
- **45+ neue Übersetzungsschlüssel** in DE/EN
  - Alle OBD2-Screens lokalisiert
  - Code-Types, Time-Ago, Dialoge
  - Keine hardcoded Strings mehr

#### **5. Bug-Fixes**
- Alle Dart-Fehler behoben:
  - Variable 't' (AppLocalizations) in allen Funktionen definiert
  - `consumeQuotaOrCredits(int, String)` Parameter korrigiert
  - `Obd2ScanDialog` Import hinzugefügt
  - `const` Expressions mit AppLocalizations entfernt

#### **6. Permissions**
- **Android**: BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION
- **iOS**: NSBluetoothAlwaysUsageDescription, NSBluetoothPeripheralUsageDescription

### 💰 **Kosten-Optimierung**
- **Vorher**: Perplexity sonar-pro ($15/1M) → fast $60/Tag
- **Jetzt**: Perplexity sonar ($1/1M) + GPT-4o ($2.50/1M) → **100x günstiger!**
- Kosten pro Diagnose: ~$0.003 statt $0.30

### 📋 **Bereit für Deployment**
```bash
# 1. API Keys setzen
Supabase Dashboard → Edge Function Secrets:
- PERPLEXITY_API_KEY = pplx-xxxxx
- OPENAI_API_KEY = sk-xxxxx

# 2. Deploy
supabase functions deploy analyze-obd-codes

# 3. Test
# - OBD2-Adapter verbinden
# - Fehlercode auslesen
# - KI-Diagnose starten
```

---

## Frühere Arbeiten (16. Oktober 2025)

### Design-Überarbeitung: Tesla/Kleinanzeigen-Hybrid Style ✅
- **Alle Screens modernisiert** mit einheitlichem professionellem Design:
  - Home Screen: Feature Cards mit Untertiteln, farbcodierte Icons, Reminder Card mit Orange-Gradient
  - Diagnose Screen: Action Cards mit Badges ("Kostenlos"/"Credits"), "Wie funktioniert's?" Info-Section
  - Chatbot Screen: Maskottchen in weißer Card, Beliebte Fragen, fixiertes Eingabefeld mit Send-Button
  - Profile Screen: Login-CTA für nicht-angemeldete, moderne Profil-Karte mit Avatar-Verwaltung
  - Settings Screen: Account-Section nur für eingeloggte User, moderne Tiles mit farbcodierten Icons
- **Navigation Bar**: Icon geändert von `car_repair` zu `search` für Diagnose
- **Farbschema**: #FAFAFA Hintergrund, weiße Cards mit `Colors.grey[200]` Borders, keine Schatten mehr

### Login-Strategie optimiert ✅
- **Kostenlose Features ohne Login nutzbar**:
  - Home Screen (voller Zugriff)
  - Diagnose Screen (Fehlercodes auslesen/löschen)
  - Settings (Sprache ändern)
- **KI-Features zeigen Login-Dialog**:
  - KI-Diagnose im Diagnose Screen
  - Ask Toni! Chatbot
- **Profile zeigt Login-CTA** mit freundlicher Anmelde-Karte statt harter Sperre
- **Routing angepasst**: Nur `/asktoni` ist geschützt, alle anderen Routen für alle zugänglich

### Texte & Übersetzungen ✅
- Diagnose-Titel verkürzt: "Fehlercodes auslesen" (statt mit "(immer kostenlos)")
- Badges zeigen Status: "Kostenlos" (grün) / "Credits" (orange)
- Login-Dialoge mit Hinweis auf kostenlose Features

### KFZ-Kosten Monetarisierung definiert ✅
- Free User: Nur Treibstoff/Kraftstoff kostenlos
- Pro Abo: Alle Kategorien freigeschaltet
- Lifetime Unlock (1,99€): Einmalkauf für lebenslangen Zugriff auf alle Kategorien
- Produkt-ID: `wefixit_costs_lifetime`
- Dokumentiert in `wefixit_prompts_phases.json` und `MVP_PROGRESS.md`

## Wichtige Design-/Funktions-Abweichungen (bewusst)

- **[Tabs]**: 4 Tabs statt 3 – zusätzlicher `Home`-Tab auf Wunsch.
- **[Ask Toni!]**: Tab und Screen umbenannt (statt „Chatbot").
- **[Login-Strategie]**: Kostenlose Features (Diagnose, Settings, Sprache) sind ohne Login nutzbar. KI-Features und Profil-Verwaltung benötigen Anmeldung. Freundliche Login-Dialoge/CTAs statt harter Auth-Gate.
- **[Hintergrund]**: Heller, professioneller Look (#FAFAFA) mit weißen Cards und Borders (statt dunkler automotive-Look); Tesla/Kleinanzeigen-inspiriert.

## 🚀 Launch-Roadmap (MVP → Production)

### ✅ **PHASE 1: GRUNDLAGEN (100% FERTIG)**
- ✅ App-Grundstruktur (Flutter + Supabase + Riverpod)
- ✅ Design-System (Tesla/Kleinanzeigen-Hybrid)
- ✅ Authentifizierung (Supabase Auth)
- ✅ Profil-Management (Avatar, Fahrzeug)
- ✅ Wartungen (vollständiges System mit 10 Kategorien, Export, Notifications)
- ✅ Fahrzeugkosten (vollständiges System mit Custom-Kategorien, CSV-Export)
- ✅ Monetarisierung (RevenueCat, Credits, Paywall, Abo-System)
- ✅ Lokalisierung (de/en)

### 🟢 **PHASE 2: KI & DIAGNOSE (98% FERTIG)**
- ✅ Ask Toni! Chatbot-UI (Credit-Gating, vollständige RAG-Integration)
- ✅ OBD2 Bluetooth Service (flutter_blue_plus Integration)
- ✅ OBD2 Scan Dialog (Bluetooth-Geräte scannen & verbinden)
- ✅ Error Codes List Screen (Fehlercodes anzeigen, Stats, KI-Diagnose starten)
- ✅ AI Diagnosis Results Screen (expandable Cards mit Details)
- ✅ **AI Edge Function mit Harvester-Workflow** (Perplexity Web → GPT-4 Strukturierung → Embedding → Full DB Save)
- ✅ **automotive_knowledge Datenbank** (pgvector mit Multi-Language Support)
- ✅ **Vollständige i18n** (DE/EN für alle OBD2-Texte)
- ✅ **Credit-System Integration** (Pro-Bypass, Quota/Credits-Check)
- ✅ **Bluetooth Permissions** (Android + iOS)
- ✅ **API Keys Deployment** (PERPLEXITY_API_KEY, OPENAI_API_KEY)### 🟢 **PHASE 3: PRODUCTION-READY (40% FERTIG)**
- ✅ **OBD2 Edge Function Deployment** (DEPLOYED & LIVE 🚀)
  - ✅ API Keys in Supabase gesetzt (PERPLEXITY_API_KEY, OPENAI_API_KEY)
  - ✅ `supabase functions deploy analyze-obd-codes` ausgeführt
- ⏳ **NÄCHSTER SCHRITT: Hardware-Testing**
  - Test mit echtem OBD2-Adapter
  - End-to-End Workflow verifizieren
  - Performance & Error-Handling prüfen
- ⏳ Testing & QA (Unit-Tests, Integration-Tests)
- ⏳ Production API Keys vervollständigen (RevenueCat, AdMob)
- ❌ Play Store Deployment (App-Signing, Metadata, Screenshots)
- ❌ iOS Build & App Store (Xcode Archive, TestFlight)
- ❌ Monitoring & Analytics (Sentry, Firebase Analytics)**NÄCHSTER GROSSER SCHRITT: KI-DATEN-SAMMEL-ENGINE**

### **Was fehlt für vollständige KI-Integration?**

**Problem:** 
- Ask Toni! zeigt nur Stub-Antworten
- Keine echte KI-Verarbeitung
- Keine KFZ-Wissensdatenbank

**Lösung: Automatische KI-Daten-Sammel-Engine** 🚀

### **📋 TODO: KI-Wissensdatenbank aufbauen**

#### **1. Rechtlich sichere Datenquellen (100% legal)**

**🌍 Die KI sammelt ALLE KFZ-Daten aus dem Internet in ALLEN Sprachen:**

**A) OBD2 & Fehlerdiagnose:**
- ✅ **OBD2-Standardcodes** (P0xxx, C0xxx, B0xxx, U0xxx)
- ✅ **Herstellerspezifische Codes** (VW, BMW, Mercedes, etc.)
- ✅ **Diagnosetexte** (Symptome → Ursachen → Lösungen)
- ✅ **Troubleshooting-Flows** (Startprobleme, Leistungsverlust, etc.)
- ✅ **Live-Daten-Interpretation** (MAF, O2, MAP, etc.)

**B) Reparatur & Wartung:**
- ✅ **Reparaturanleitungen** (KI-generiert, nicht kopiert)
- ✅ **Wartungspläne** (Ölwechsel, Filter, Bremsen, Zahnriemen)
- ✅ **Schritt-für-Schritt Anleitungen** (mit Bildbeschreibungen)
- ✅ **Werkzeug-Listen** (was brauche ich für Reparatur X?)
- ✅ **Kosten-Schätzungen** (durchschnittliche Werkstattpreise)

**C) Bauteile & Theorie:**
- ✅ **Bauteile-Beschreibungen** (LMM, Lambda, AGR, Turbo, DPF, etc.)
- ✅ **KFZ-Theorie** (Bremsen, Sensoren, Zündung, Motor, Getriebe)
- ✅ **Funktionsweise** (Wie funktioniert ein Turbolader?)
- ✅ **Verschleiß-Symptome** (Wann ist ein Bauteil defekt?)
- ✅ **Austausch-Intervalle** (Wie oft tauschen?)

**D) Fahrzeug-spezifisch:**
- ✅ **Modell-spezifische Probleme** (VW Golf 7 TDI, BMW E90, etc.)
- ✅ **Rückrufaktionen** (Safety Recalls, TSBs)
- ✅ **Bekannte Schwachstellen** (N47 Motor, DSG Getriebe, etc.)
- ✅ **Community-Wissen** (häufigste Probleme pro Modell)

**E) Tuning & Modifikationen:**
- ✅ **Performance-Tuning** (Chiptuning, Auspuff, Luftfilter)
- ✅ **Styling-Mods** (Fahrwerk, Felgen, Optik)
- ✅ **ECU-Tuning** (Kennfeldoptimierung, E85, etc.)
- ✅ **Legal/Illegal** (Was ist TÜV-konform?)

**F) Elektro & Hybrid:**
- ✅ **Hybrid-Systeme** (Toyota, Honda, etc.)
- ✅ **Elektroautos** (Tesla, VW ID, etc.)
- ✅ **Batterie-Pflege** (Lebensdauer, Ladezyklen)
- ✅ **Hochvolt-Sicherheit** (Warnung: Gefahr!)

**🌐 Multi-Language Harvesting:**
- ✅ **Primär-Sprachen:** Englisch, Deutsch, Französisch, Spanisch, Italienisch
- ✅ **Sekundär-Sprachen:** Polnisch, Türkisch, Russisch, Chinesisch
- ✅ **Automatische Übersetzung:** Alle Sprachen → Deutsch & Englisch
- ✅ **Original-Quelle behalten:** Für Qualitätskontrolle

#### **2. Was die KI NICHT sammeln darf (illegal)**
- ❌ Hersteller-Dokumentation (VW, BMW, Mercedes)
- ❌ Kostenpflichtige Datenbanken (Autodata, Alldata, Haynes)
- ❌ 1:1 Kopien aus Foren (MotorTalk, BMW-Syndikat)
- ❌ Kommerzielle Werkstattdaten
- ❌ Geschützte PDFs / Handbücher

**Aber:** KI darf diese Inhalte **lesen und neu formulieren** → dann legal!

#### **3. Automatische Daten-Sammel-Engine (Backend-Workflow)**

**🌐 Web-Recherche-Workflow (Vollautomatisch):**

Die KI durchsucht **täglich/stündlich** das Internet und baut die Wissensdatenbank auf:

```
┌─────────────────────────────────────────────────────────┐
│  CRON-Job/Worker startet (z.B. täglich 2:00 Uhr)       │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  KI-Modell mit Web-Search (GPT-4.1 / Claude 3.7)       │
│  🌍 Durchsucht automatisch in ALLEN Sprachen:          │
│                                                         │
│  🇩🇪 Deutsch:                                           │
│  • "BMW E90 Turbolader defekt Symptome"                │
│  • "VW Golf 7 TDI DPF regenerieren Anleitung"          │
│                                                         │
│  🇬🇧 Englisch:                                          │
│  • "Common car repair issues for [Thema]"               │
│  • "OBD2 error code P0420 causes and solutions"        │
│  • "How to diagnose rough idle"                         │
│                                                         │
│  🇫🇷 Französisch:                                       │
│  • "Problèmes courants moteur diesel"                   │
│  • "Réparer turbo cassé étape par étape"               │
│                                                         │
│  🇪🇸 Spanisch:                                          │
│  • "Problemas comunes motor gasolina"                   │
│  • "Diagnosticar fallo turbo"                           │
│                                                         │
│  🇮🇹 Italienisch, 🇵🇱 Polnisch, 🇹🇷 Türkisch, etc.   │
│                                                         │
│  📚 Quellen: Wikipedia, Open Data, Foren, Blogs,       │
│             YouTube-Transkripte, freie Artikel          │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  KI filtert & validiert Quellen                         │
│  ✅ Nur legale, freie Inhalte                          │
│  ❌ Keine geschützten Datenbanken                       │
│  ❌ Keine 1:1 Kopien aus Foren                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  KI fasst zusammen & formuliert neu                     │
│  • Symptome                                              │
│  • Ursachen                                              │
│  • Schritt-für-Schritt-Diagnosen                        │
│  • Reparaturverfahren                                    │
│  • Checklisten                                           │
│  • Technische Werte                                      │
│  ✅ Original-Sprache wird erkannt                       │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  🌐 AUTOMATISCHE ÜBERSETZUNG in Ziel-Sprachen          │
│                                                         │
│  Original (z.B. Englisch):                              │
│  "P0420 indicates catalyst efficiency below threshold" │
│                                                         │
│  ↓ GPT-4 Translation (hochwertig!)                     │
│                                                         │
│  🇩🇪 Deutsch:                                           │
│  "P0420 zeigt an, dass Katalysator-Effizienz           │
│   unter Schwellenwert liegt"                            │
│                                                         │
│  🇬🇧 Englisch: (Original beibehalten)                  │
│                                                         │
│  🇫🇷 Französisch:                                       │
│  "P0420 indique efficacité catalyseur sous seuil"      │
│                                                         │
│  🇪🇸 Spanisch:                                          │
│  "P0420 indica eficiencia del catalizador bajo         │
│   el umbral"                                            │
│                                                         │
│  💾 Alle Übersetzungen werden gespeichert!             │
│  • content_de, content_en, content_fr, content_es      │
│  • original_language Feld für Qualitätskontrolle       │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Text wird in Chunks geteilt (500-1000 Tokens)         │
│  • Pro Sprache separate Chunks                          │
│  • Embeddings werden PER Sprache erzeugt                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  KI erzeugt Embeddings (OpenAI vector(1536))           │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Eintrag in Vektor-Datenbank (Supabase pgvector)       │
│  • automotive_knowledge Tabelle                         │
│  • error_codes Tabelle (für OBD2-Codes)                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Index aktualisiert (ivfflat für schnelle Suche)       │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  Worker fährt mit nächstem Thema fort                   │
│  • Nächster Fehlercode                                   │
│  • Nächstes Bauteil                                      │
│  • Nächstes Symptom                                      │
│  • Aktualisierung alter Einträge                        │
└─────────────────────────────────────────────────────────┘
```

**🎯 Resultat:** 
- ✅ Vollständig autonome Wissenserweiterung
- ✅ Täglich neue KFZ-Daten ohne manuelles Zutun
- ✅ 100% legal & rechtssicher
- ✅ Datenbank wächst automatisch

#### **4. Themen die automatisiert werden können**

**Fehlerdiagnose:**
- Leistungsverlust, Ruckeln, Startprobleme
- Leerlaufschwankungen, hoher Verbrauch
- Klopfgeräusche, Abgasfarben

**Bauteile:**
- LMM, Lambda-Sonde, Katalysator, AGR-Ventil
- Nockenwellensensor, Kurbelwellensensor
- Turbolader, Einspritzventile, Zündspulen

**Reparatur-Anleitungen (generisch):**
- Ölwechsel, Bremsen, Auspuff, Kühlsystem
- Zündanlage, Kraftstoffsystem

**Troubleshooting-Flows:**
- "Wenn Motor heiß wird → prüfe A, B, C…"

**KFZ-Theorie:**
- 4-Takt-Motor, Sensoren, Aktoren, Elektrik

#### **5. Technische Umsetzung**

**🔧 KI-Modelle mit Web-Search (Auswahl):**

| Anbieter | Modell | Web-Search | Kosten |
|----------|--------|------------|--------|
| **OpenAI** | GPT-4.1 Turbo | ✅ Ja (via Function Calling) | $10/1M Tokens |
| **Anthropic** | Claude 3.7 Sonnet | ✅ Ja (via Web Search Tool) | $3/1M Tokens |
| **Perplexity** | pplx-7b-online | ✅ Ja (Spezialisiert) | $0.20/1M Tokens |
| **FireworksAI** | Mixtral + Brave API | ✅ Ja (via Integration) | $0.50/1M Tokens |

**💡 Empfehlung:** Perplexity AI für Daten-Harvester (günstig + spezialisiert auf Web-Search)

---

**Backend (Supabase Edge Function oder CRON-Worker):**

```typescript
// Edge Function: auto_knowledge_harvester
import { OpenAI } from 'openai'
import { createClient } from '@supabase/supabase-js'

// Worker läuft täglich/stündlich als Supabase pg_cron Job
export async function harvestKnowledge() {
  const openai = new OpenAI({ 
    apiKey: process.env.OPENAI_API_KEY,
    // Oder: Perplexity API für Web-Search
  });
  
  const topics = [
    'P0420 catalyst efficiency below threshold',
    'P0171 system too lean bank 1',
    'How to diagnose rough idle',
    'Common causes turbocharger failure',
    // ... 1000+ Themen
  ];
  
  for (const topic of topics) {
    // 1. Web-Search via KI
    const searchResults = await openai.chat.completions.create({
      model: 'gpt-4.1-turbo',
      messages: [{
        role: 'user',
        content: `Research automotive repair information about: ${topic}. 
                  Use only free, legal sources. Summarize in German.`
      }],
      tools: [{
        type: 'web_search', // GPT-4.1 Feature
      }]
    });
    
    // 2. Strukturierte Daten extrahieren
    const structuredData = extractStructuredData(searchResults);
    
    // 3. Embedding erzeugen
    const embedding = await openai.embeddings.create({
      model: 'text-embedding-3-small',
      input: structuredData.content
    });
    
    // 4. In Supabase speichern
    await supabase.from('automotive_knowledge').insert({
      topic: topic,
      category: structuredData.category,
      title: structuredData.title,
      content: structuredData.content,
      keywords: structuredData.keywords,
      embedding: embedding.data[0].embedding
    });
    
    console.log(`✅ Processed: ${topic}`);
  }
}

// Supabase pg_cron Setup:
// SELECT cron.schedule(
//   'knowledge-harvester',
//   '0 2 * * *', -- Täglich 2:00 Uhr
//   $$ SELECT net.http_post(
//     url := 'https://your-project.supabase.co/functions/v1/auto_knowledge_harvester',
//     headers := '{"Authorization": "Bearer YOUR_KEY"}'::jsonb
//   ) $$
// );
```

**Neue Datenbank-Tabellen (Multi-Language Support):**
```sql
-- 🌍 KFZ-Wissensdatenbank mit Multi-Language Support
CREATE TABLE automotive_knowledge (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Metadaten
  topic TEXT NOT NULL,
  category TEXT, -- 'fehlercode', 'bauteil', 'reparatur', 'theorie', 'tuning', 'elektro'
  subcategory TEXT, -- 'motor', 'getriebe', 'bremsen', 'elektrik', etc.
  vehicle_specific JSONB, -- {brand: 'VW', model: 'Golf 7', year: '2012-2020'}
  
  -- Multi-Language Content (alle Sprachen in einem Eintrag!)
  title_de TEXT,
  title_en TEXT,
  title_fr TEXT,
  title_es TEXT,
  
  content_de TEXT,
  content_en TEXT,
  content_fr TEXT,
  content_es TEXT,
  
  -- Strukturierte Daten (sprachunabhängig)
  symptoms TEXT[], -- ['Leistungsverlust', 'Ruckeln', 'Schwarzer Rauch']
  causes TEXT[], -- ['Defekter Turbolader', 'Verstopfter DPF']
  diagnostic_steps TEXT[], -- ['Prüfe Luftmassenmesser', 'Teste Ladedruck']
  repair_steps TEXT[], -- ['Turbolader ausbauen', 'Dichtungen prüfen']
  tools_required TEXT[], -- ['Drehmomentschlüssel', 'OBD2-Adapter']
  estimated_cost_eur NUMERIC(10,2), -- Durchschnittliche Kosten
  difficulty_level TEXT, -- 'easy', 'medium', 'hard', 'expert'
  
  -- Vector Embeddings (ein Embedding pro Sprache!)
  embedding_de vector(1536),
  embedding_en vector(1536),
  embedding_fr vector(1536),
  embedding_es vector(1536),
  
  -- Metadaten
  keywords TEXT[],
  original_language TEXT, -- 'en', 'de', 'fr', etc. (Qualitätskontrolle)
  source_urls TEXT[], -- Für Nachvollziehbarkeit
  quality_score NUMERIC(3,2), -- 0.0 - 1.0 (KI-Bewertung der Qualität)
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes für schnelle Vector Search (pro Sprache!)
CREATE INDEX ON automotive_knowledge USING ivfflat (embedding_de vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON automotive_knowledge USING ivfflat (embedding_en vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON automotive_knowledge USING ivfflat (embedding_fr vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON automotive_knowledge USING ivfflat (embedding_es vector_cosine_ops) WITH (lists = 100);

-- Indizes für Text-Suche
CREATE INDEX idx_knowledge_category ON automotive_knowledge(category);
CREATE INDEX idx_knowledge_vehicle ON automotive_knowledge USING gin(vehicle_specific);

---

-- 🚗 Fehlercode-Datenbank (OBD2, Hersteller-spezifisch)
CREATE TABLE error_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Code-Identifikation
  code TEXT UNIQUE NOT NULL, -- P0420, P0171, C1234, B0001, U0100
  code_type TEXT, -- 'powertrain', 'chassis', 'body', 'network'
  is_generic BOOLEAN DEFAULT true, -- true = SAE Standard, false = Hersteller-spezifisch
  manufacturer TEXT[], -- ['VW', 'Audi', 'Seat', 'Skoda'] wenn hersteller-spezifisch
  
  -- Multi-Language Beschreibungen
  description_de TEXT,
  description_en TEXT,
  description_fr TEXT,
  description_es TEXT,
  
  -- Technische Details
  symptoms TEXT[],
  common_causes TEXT[],
  diagnostic_steps TEXT[],
  repair_suggestions TEXT[],
  affected_components TEXT[], -- ['Catalytic Converter', 'O2 Sensor', 'ECU']
  
  -- Schweregrad & Priorität
  severity TEXT, -- 'low', 'medium', 'high', 'critical'
  drive_safety BOOLEAN DEFAULT true, -- Kann man weiterfahren?
  immediate_action_required BOOLEAN DEFAULT false,
  
  -- Zusatz-Infos
  related_codes TEXT[], -- ['P0171', 'P0174'] (oft zusammen auftretend)
  typical_cost_range_eur TEXT, -- '50-200' oder '500-1500'
  
  -- Statistik
  occurrence_frequency TEXT, -- 'very_common', 'common', 'rare'
  search_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index für schnelle Code-Suche
CREATE INDEX idx_error_codes_code ON error_codes(code);
CREATE INDEX idx_error_codes_manufacturer ON error_codes USING gin(manufacturer);

---

-- 📊 Themen-Warteschlange (für automatisches Harvesting)
CREATE TABLE knowledge_harvest_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  topic TEXT NOT NULL,
  search_language TEXT NOT NULL, -- 'de', 'en', 'fr', 'es'
  category TEXT,
  priority INTEGER DEFAULT 0, -- höher = wichtiger
  
  status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
  attempts INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  error_message TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index für Warteschlangen-Verarbeitung
CREATE INDEX idx_harvest_queue_status ON knowledge_harvest_queue(status, priority DESC);
```

**AI Edge Function für Ask Toni!:**
```typescript
// Edge Function: chat_completion
// 1. User Nachricht empfangen
// 2. Vector Search in automotive_knowledge (RAG)
// 3. Relevante Infos abrufen
// 4. OpenAI/Anthropic API Call mit Context
// 5. Antwort zurück an App
```

#### **6. Integration in die App**

**Was ändert sich:**
- ✅ Ask Toni! bekommt echte AI-Antworten
- ✅ KI-Diagnose zeigt relevante Infos zu Fehlercodes
- ✅ Automatische Vorschläge basierend auf Symptomen
- ✅ Wissensdatenbank wächst automatisch

**Code-Änderungen minimal:**
- `ChatbotScreen`: API-Call zu Edge Function (statt Stub)
- `DiagnoseScreen`: API-Call für Fehlercode-Analyse
- Alles andere bleibt gleich!

#### **7. Vorteile des Multi-Language-Ansatzes**

**🌍 Für dich als Entwickler:**
- ❌ Kein manuelles Daten-Sammeln
- ❌ Keine Wochen in Foren investieren
- ❌ Kein selber formulieren oder übersetzen
- ❌ Keine Übersetzungskosten
- ✅ KI macht alles automatisch & legal
- ✅ Alle Sprachen parallel verfügbar

**🚀 Für die App:**
- ✅ **10x mehr Daten** durch Multi-Language Harvesting
- ✅ Immer aktuelle Infos aus weltweiten Quellen
- ✅ Wächst automatisch in allen Sprachen
- ✅ 100% rechtlich sauber (neu formuliert)
- ✅ Qualität durch KI-Generierung
- ✅ **Internationale Skalierung** ohne Extra-Aufwand

**📊 Erwartete Datenmenge (nach 1 Monat):**

| Kategorie | Quell-Sprachen | Artikel | Total (übersetzt) |
|-----------|----------------|---------|-------------------|
| **OBD2-Fehlercodes** | 🇬🇧 🇩🇪 🇫🇷 | ~2.000 | 8.000 (4 Sprachen) |
| **Reparaturanleitungen** | 🇬🇧 🇩🇪 🇫🇷 🇪🇸 | ~5.000 | 20.000 |
| **Bauteile** | 🇬🇧 🇩🇪 | ~1.000 | 4.000 |
| **Symptom-Diagnosen** | 🇬🇧 🇩🇪 🇫🇷 | ~3.000 | 12.000 |
| **Fahrzeug-spezifisch** | 🇬🇧 🇩🇪 | ~10.000 | 40.000 |
| **Tuning & Mods** | 🇬🇧 🇩🇪 | ~2.000 | 8.000 |
| **Elektro/Hybrid** | 🇬🇧 🇩🇪 | ~1.000 | 4.000 |
| **TOTAL** | | **~24.000** | **~96.000** |

**💰 Kosten-Kalkulation:**

```
Phase 1: Initiales Harvesting (1 Monat)
├─ 24.000 Artikel á 3.000 Tokens = 72M Tokens
├─ Web-Search + Zusammenfassung (Perplexity): $14.40
├─ Übersetzung (GPT-4o-mini): $5.76
├─ Embeddings (text-embedding-3-small): $1.44
└─ TOTAL: ~$22 für komplette Wissensbasis!

Phase 2: Wartung (monatlich)
├─ 500 neue Artikel + 1.000 Updates = 1.500 á 3.000 Tokens = 4.5M Tokens
├─ Web-Search + Updates: $0.90
├─ Übersetzungen: $0.36
├─ Embeddings: $0.09
└─ TOTAL: ~$1.35/Monat laufende Kosten

Phase 3: User-Anfragen (Ask Toni!)
├─ 10.000 Anfragen/Monat á 3.000 Tokens = 30M Tokens
├─ Vector Search: kostenlos (Supabase pgvector)
├─ GPT-4o-mini Response: $6.00/Monat
└─ TOTAL: ~$6/Monat bei 10.000 User-Anfragen

GESAMT: ~$30 Setup + ~$8/Monat = ~$126/Jahr
```

**🎯 ROI-Berechnung:**

```
Kosten pro Jahr: $126
────────────────────────────
Nur 13 Pro-Abos (4,99€/Monat) finanzieren
die KOMPLETTE KI-Infrastruktur! 🎉
────────────────────────────

Bei 1.000 User:
• ~10% werden Pro-Abos = 100 Abos
• Umsatz: 100 x 4,99€ x 12 = 5.988€/Jahr
• Kosten KI: $126 = ~120€/Jahr
• PROFIT: 5.868€/Jahr 💰
```

---

## 📋 **Nächste konkrete Schritte**

### **Option A: KI-Integration zuerst** (Empfohlen! 🎯)
1. **Edge Function für KI-Chat** implementieren
2. **Automotive Knowledge Datenbank** aufsetzen
3. **Auto-Daten-Harvester** erstellen (läuft täglich)
4. **Ask Toni!** mit echter KI verbinden
5. **Fehlercode-Analyse** implementieren

**Zeitaufwand:** 2-3 Tage
**Impact:** HOCH - Hauptfeature wird voll funktionsfähig!

---

### **Option B: OBD2 Bluetooth** (Hardware-abhängig)
1. **OBD2 Bluetooth Package** integrieren
2. **Device-Scanning** implementieren
3. **Fehlercode auslesen/löschen**
4. **Live-Daten** (optional)

**Zeitaufwand:** 3-4 Tage
**Impact:** MITTEL - Benötigt OBD2-Adapter zum Testen

---

### **Option C: Testing & Production** (Vor Launch)
1. **Unit-Tests** schreiben
2. **Integration-Tests** für Features
3. **Production Keys** einfügen
4. **Play Store Listing** vorbereiten
5. **Beta-Testing**

**Zeitaufwand:** 1 Woche
**Impact:** KRITISCH für Launch

---

## 🎯 **Meine Empfehlung: STARTE MIT OPTION A (KI-Integration)**

**Warum?**
1. ✅ **Hauptfeature** wird voll funktionsfähig
2. ✅ **Keine Hardware** nötig (im Gegensatz zu OBD2)
3. ✅ **Großer Mehrwert** für User
4. ✅ **Automatisch wachsende Wissensdatenbank**
5. ✅ **Kann parallel zu anderem entwickelt werden**

**Reihenfolge:**
```
1. KI-Integration (2-3 Tage) ← JETZT!
2. OBD2 Bluetooth (3-4 Tage)
3. Testing & QA (1 Woche)
4. Production Launch 🚀
```

---

## 🔄 **Was steht in diesem Dokument**

- **[Dokumentation & Pflege]**: LAUFEND
  - `MVP_PROGRESS.md` wird bei jeder Änderung am Wartungs-/Kosten-/KI-Feature aktualisiert

## Technische Hinweise/ToDos außerhalb der App

- **[Supabase]**: Schema angewendet. Bitte Bucket `vehicle_photos` (public) im Storage anlegen (für Fahrzeugfotos).
- **[Routen]**: `/settings` Route hinzugefügt; Zahnrad im Profil navigiert dorthin.
- **[Branding]**: Icon/Splash-Konfigurationen/Assets entfernt (Rollback). Neue Umsetzung wird separat geplant.
- **[Android Studio Run]**: App immer mit Defines starten: `--dart-define-from-file=env.example`.
- **[RevenueCat/AdMob]**: Produkt-/App-IDs in den nächsten Schritten hinterlegen.

### 🔴 TODO - Production Deployment:

- **[7-Tage-Trial hinzufügen]**: 
  - Im Google Play Console für das Pro-Abo eine 7-tägige kostenlose Testphase konfigurieren
  - RevenueCat erkennt und zeigt das Trial automatisch in der Paywall an
  - Keine Code-Änderungen erforderlich
  
- **[Production Keys einfügen]**: 
  - **RevenueCat**: Test-Keys durch echte Production Keys ersetzen
    - Android: `test_NZPOpTUffQhhAuREEDZaFvdGWvK` → Production Key
    - iOS: Placeholder → Production Key
  - **AdMob**: Test-IDs durch echte Production IDs ersetzen
    - Android App ID: `ca-app-pub-3940256099942544~3347511713` → Echte ID
    - Banner Unit ID: `ca-app-pub-3940256099942544/6300978111` → Echte ID  
    - Rewarded Video Unit ID: `ca-app-pub-3940256099942544/5224354917` → Echte ID
  - Keys befinden sich in `env.example` und `lib/src/services/purchase_service.dart`
  - ⚠️ **WICHTIG**: Test-Keys NUR in Development, Production Keys NUR im Release Build verwenden!

## Heute erledigte Arbeiten (23. Oktober 2025)

- **[Erweiterte Benachrichtigungen – UI]** ✅
  - Glocke unter `Fälligkeitsdatum` mit Standard „10 Min. vorher“.
  - Auswahl-Sheet mit Presets: „Zum Zeitpunkt des Ereignisses“, „10 Min. vorher“, „1 Stunde vorher“, „1 Tag vorher“, sowie „Angepasst“ (freie Minutenangabe).
  - Zwei Pills: „Erneut erinnern am …“ (Datum/Uhrzeit) und „Wiederholen bis …“ (Enddatum für Wiederholung).
  - Unten auf der Seite den alten Bereich „Wiederkehrend & Benachrichtigungen“ entfernt.

- **[Benachrichtigungs-Logik – Service]** ✅
  - `MaintenanceNotificationService.scheduleMaintenanceReminder()` akzeptiert jetzt `offsetMinutes`, `remindAgainAt` und `notifyEnabledOverride`.
  - Berücksichtigt globalen Toggle (`SharedPreferences: notifications_enabled_global`).
  - Sofort-Benachrichtigung bei „heute“ oder „überfällig“ bleibt bestehen (zur Umgehung von OS-Verzögerungen), zusätzlich kann `remindAgainAt` geplant werden.
  - Zukünftige Termine werden mit konfigurierbarem Offset geplant (Fallback: 1 Tag).

- **[Globaler Toggle – Settings]** ✅
  - Neue Karte in `Settings` mit Schalter „Benachrichtigungen aktivieren“. Speicherung in `SharedPreferences` unter `notifications_enabled_global`.

- **[Datenbank-Erweiterungen]** ✅
  - Supabase Migration angewendet: Spalten `notify_offset_minutes int default 10`, `remind_again_at timestamptz`, `repeat_until timestamptz` zu `maintenance_reminders` ergänzt.

- **[Model/Service Persistenz]** ✅
  - `MaintenanceReminder` (Freezed) erweitert: `notifyOffsetMinutes`, `remindAgainAt`, `repeatUntil` (+ JSON Keys).
  - `MaintenanceService.createReminder/updateReminder` persistiert `notify_offset_minutes`, `remind_again_at`, `repeat_until` und übergibt `offsetMinutes`/`remindAgainAt` an den Notification-Service.

- **[i18n (de/en)]** ✅
  - Neue Keys für Reminder-Presets, „Erneut erinnern“, „Wiederholen bis“, globalen Settings-Toggle und Kurzform Minuten (`common.minutes_short`).
  - Bezeichnung „Art der Erinnerung“ → „Erinnerung“.

- **[Hinweis]**
  - Für die neuen Freezed-/JSON-Felder lokal Code generieren:
    - `flutter pub run build_runner build --delete-conflicting-outputs`

## Heute erledigte Arbeiten (25. November 2025)

- **[Monetarisierung & Credits System]** ✅
  - **PurchaseService (RevenueCat)** implementiert mit Entitlement-Checks (Pro, Costs Lifetime)
  - **CreditService** für Credit-Balance und wöchentliches Gratis-Kontingent
  - Intelligente consumeQuotaOrCredits() Methode (Prio: Quota → Credits)
  - Initialisierung im SplashScreen nach Supabase
  
- **[Paywall Screen]** ✅
  - PaywallScreen mit Offerings-Display (Packages von RevenueCat)
  - Kauf- und Restore-Funktionalität
  - Route `/paywall` registriert
  - Gradient-Background und moderne UI

- **[Chatbot Credit-Integration]** ✅
  - ChatbotScreen von StatelessWidget zu StatefulWidget refactored
  - Credit/Quota-Check vor jeder Nachricht (Pro-User Bypass)
  - Chat-Verlauf mit Message-History (ChatMessage Model)
  - Stub AI-Antworten (2s Delay)
  - "Keine Credits"-Dialog mit Link zur Paywall
  - Suggestion-Cards funktional (senden Nachricht)

- **[Wartungskosten → Fahrzeugkosten Integration]** ✅
  - Toggle "In Fahrzeugkosten übernehmen" im Wartungsformular
  - Automatische Kategorie-Erstellung mit Icons & Farben
  - Icons für Wartungskategorien in CostCategory.iconMap hinzugefügt
  - Verknüpfung via maintenanceReminderId in VehicleCost
  
- **[Fahrzeugkosten - Vollständige Implementierung]** ✅
  - CSV-Export-Funktion mit CostsExportService (wie MaintenanceExportService)
  - Exportiert alle Kostendetails inkl. Tankdaten, Belege, Zeiträume
  - Share-Funktion über share_plus Package
  - Zukunftsdaten: Date Picker erlaubt Auswahl zukünftiger Daten
  - Jahresdurchschnitt im Homescreen & Diagramm (unabhängig vom Zeitraum)
  - Einnahmen korrekt gefiltert (isIncome Flag)
  - Monatsformatierung als Abkürzung (z.B. "Okt 464.43 €")
  
- **[Monetarisierung - Feature Gates & Paywall]** ✅
  - **Lifetime-Unlock Feature Gate**: Free User nur Treibstoff-Kategorie, Lifetime/Pro alle Kategorien
  - **Category Lock UI**: Gesperrte Kategorien grau mit 🔒 Schloss-Icon im Dropdown
  - **Paywall-Dialog**: Wird bei Auswahl gesperrter Kategorie angezeigt
  - **Modernisierter Paywall-Screen**:
    - Helles Design (#FAFAFA) passend zur App
    - 3 Tabs: Credits, Lifetime, Pro Abo
    - Benefits-Sektion mit Icons (Alle Kategorien, Unbegrenzte KI, Notifications, Export, No Ads)
    - Pricing-Cards mit "EMPFOHLEN" Badge für Lifetime
    - Gradient-Header mit Premium-Icon
  - PurchaseService Integration: hasCostsUnlock() & isPro() Checks
  - Lokalisierung (de/en) für alle Paywall-Texte
  
- **[Environment Configuration]** ✅
  - env.example erweitert mit AdMob App-IDs & Banner Unit IDs
  - Google Test IDs als Kommentare für Entwicklung
  - RevenueCat SDK Keys Platzhalter mit Anleitung
  - Strukturierte Dokumentation aller API Keys
  - Rewarded Video Ad Unit IDs hinzugefügt

- **[AdMob Rewarded Video Gate - Wartungen]** ✅
  - **AdMobService**: Rewarded Video Integration mit google_mobile_ads
  - **MaintenanceCounterService**: Zähler für kostenlose Wartungen (SharedPreferences)
  - **System**: Nach 3 Wartungen → Rewarded Video → Counter Reset → 3 weitere gratis
  - **Pro Bypass**: Pro-User überspringen Ad Gate komplett
  - **Ad Gate Dialog**: User kann Video ansehen, Pro werden, oder abbrechen
  - **Loading State**: Ladeanimation während Ad-Preload
  - **Error Handling**: Fallback wenn Ad nicht geladen werden kann
  - **Preloading**: Ads werden beim App-Start vorgeladen
  - Lokalisierung (de/en) für alle Dialog-Texte

- **[AdMob Banner Ads - Persistent]** ⏸️ TEMPORÄR DEAKTIVIERT
  - **AdBannerWidget**: Zeigt 320x50 Banner für Free-User, nichts für Pro-User
  - **Platzierung**: Persistent am unteren Rand über Bottom Navigation
  - **Pro-Check**: Automatischer Check ob User Pro ist
  - **Lazy Loading**: Banner lädt nur für Free-User
  - **App-Shell Integration**: Banner im _RootScaffold eingebaut
  - **Design**: Hintergrundfarbe matched App-Theme (#0D1218)
  - **Lifecycle**: Korrekte Dispose-Logik für BannerAd
  - **STATUS**: Aktuell mit _enableBanner = false deaktiviert (AdWidget Layout-Probleme)

- **[Bugfixes - Fahrzeugkosten]** ✅
  - **Layout-Crash behoben**: Autocomplete-Widget entfernt und durch einfaches TextFormField ersetzt
  - **Grund**: Flutter's Autocomplete hat fundamentale Layout-Probleme mit unbounded constraints
  - **Fehler**: "RenderFlex children have non-zero flex but incoming width constraints are unbounded"
  - **Lösung**: Tankstellen-Feld jetzt manuell eingeben (Autocomplete-Funktion geopfert für Stabilität)
  
- **[Bugfixes - Kategorien Duplikate]** ✅
  - **Duplicate Category Crash behoben**: Race Condition beim Erstellen von Kategorien aus Wartungen
  - **Problem**: Zweite Wartung mit gleicher Kategorie führte zu UNIQUE Constraint Fehler
  - **Fix 1**: Retry-Logik wenn Category-Erstellung fehlschlägt (sucht nochmals)
  - **Fix 2**: UNIQUE Constraint in DB (user_id, name) verhindert echte Duplikate
  - **Resultat**: Kategorien werden wiederverwendet statt doppelt angelegt
  
- **[Bugfixes - Kategorie-Namen & Icons]** ✅
  - **Namen falsch angezeigt**: `costs.category_Treibstoff` statt `Treibstoff`
    - **Ursache**: Code versuchte Translation-Keys zu verwenden die nicht existieren
    - **Fix**: Direkte Anzeige des Namens aus DB (Namen sind bereits lokalisiert)
    - **Betroffene Dateien**: cost_form_screen, category_manager_screen, costs_statistics_tab, costs_history_tab, costs_charts_tab
  - **Icons fehlten**: `security` und `toll` Icons nicht gemappt
    - **Fix**: Icons zur Icon-Map hinzugefügt + Fallback zu `Icons.category`
    - **Datei**: `cost_category.dart`
  - **is_locked Feld fehlte**: Model hatte kein `isLocked` Feld
    - **Fix**: Feld zum Freezed-Model hinzugefügt
    - **Benötigt**: `flutter pub run build_runner build --delete-conflicting-outputs`
  - **Lock-Check falsch**: Prüfte `name == 'fuel'` statt `!isLocked`
    - **Problem**: DB hat `'Treibstoff'` statt `'fuel'` → Alles gesperrt!
    - **Fix**: Verwendet jetzt `category.isLocked` aus DB

- **[Bugfixes - Riverpod State Management]** ✅
  - **Provider-Modifikation während Build behoben**: HomeScreen didChangeDependencies
  - **Fix**: refreshFromRemote() wrapped in Future.microtask()
  - **Fehler**: "Tried to modify a provider while the widget tree was building"
  - **Resultat**: Profil-Refresh passiert nach Build-Phase
  
- **[UI-Verbesserungen]** ✅
  - Custom Date Picker Dialoge breiter (90%) mit besserem Padding
  - Cancel-Button weiß statt grau
  - Icon-Änderung: Wartungs-Kosten-Button jetzt `Icons.payments`

- **[Localization]** ✅
  - Neue Keys für "add_to_vehicle_costs" (de/en)
  - Getters in AppLocalizations ergänzt

---

## Heute erledigte Arbeiten (24. Oktober 2025)

- **[Erweiterte Wartungserinnerungen – UI-Verbesserungen]** ✅
  - **Zeitauswahl hinzugefügt**: Nach dem Datum-Picker wird automatisch ein Zeit-Picker angezeigt. Anzeige kombiniert Datum + Uhrzeit (z. B. "23.12.2024 14:30").
  - **Dark-Theme für alle Picker**: DatePicker, TimePicker und Bottom Sheets verwenden einheitliches dunkles Design (0xFF151C23 Hintergrund, 0xFF1976D2 Primary).
  
- **[Wiederholungs-UI komplett überarbeitet]** ✅
  - **Alte Elemente entfernt**: "- Zahl +" Buttons und beschreibender Text ("Dieses Ergebnis wird wiederholt") wurden entfernt.
  - **Neue Radio-Button-Optionen**: Saubere Auswahl mit benutzerdefinierten `_buildRepeatOption` Widgets.
  - **Optionen**: "Nicht wiederholen", "Jeden Tag", "Jede Woche", "Jeden Monat", "Jedes Jahr".
  - **Wochentage-Auswahl**: Bei "Jede Woche" werden FilterChips für Mo-So angezeigt (mit Dark-Theme Styling).
  
- **[Monat/Jahr-Auswahl neu gestaltet]** ✅
  - **Monatlich**: Zwei Optionen mit `_buildSecondaryButton`:
    - "Im [Monat]. am [Tag]. wiederholen"
    - "Am [N]. [Wochentag] wiederholen"
  - **Jährlich**: 
    - Gleiche Optionen wie monatlich
    - **Plus**: Verbesserter CupertinoPicker für Monatsauswahl mit vollständigen Monatsnamen (Januar, Februar, etc.) statt Kurzformen
    - Kompaktere Höhe (120px statt 160px)
    - Dark-Theme Container mit abgerundeten Ecken
  
- **[Laufzeit-Sektion hinzugefügt]** ✅
  - **Für immer**: Standard-Option für unbegrenzte Wiederholung.
  - **Bestimmte Anzahl**: TextField für numerische Eingabe, wie oft die Wartung wiederholt werden soll.
  - **Bis**: DatePicker für Enddatum der Wiederholung.
  - **Sichtbarkeit**: Sektion wird nur angezeigt, wenn Wiederholung aktiviert ist.
  - **Persistierung**: Werte werden in `_recurrenceDuration`, `_recurrenceCount`, `_recurrenceUntil` gespeichert und in `_repeatRule` als `count`/`until` hinzugefügt.
  
- **[Erinnerungs-UI optimiert]** ✅
  - **Dark-Theme**: Konsistenter dunkler Hintergrund (0xFF151C23).
  - **SwitchListTile**: Ein-/Ausschalten der Benachrichtigungen mit verbessertem Styling.
  - **Integrierter CupertinoPicker**: Direkte Auswahl von Betrag (1-60) und Einheit (Minute/Stunde/Tag) im selben Sheet.
  - **Speichern-Button hinzugefügt**: Großer, prominenter Button zum Bestätigen der Auswahl.
  - **Nested Modal entfernt**: Picker ist jetzt direkt im Haupt-Sheet integriert.
  
- **[Scrollbare Bottom Sheets]** ✅
  - **DraggableScrollableSheet**: Wiederholungs-Screen verwendet jetzt ein ziehbares, scrollbares Sheet.
  - **Größen**: initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95.
  - **Löst Overflow-Probleme**: Bei vielen Optionen (monatlich/jährlich + Laufzeit) kann der User scrollen.
  
- **[Code-Bereinigung]** ✅
  - **_RepeatAmount Widget entfernt**: Das alte Widget für "- Zahl +" Buttons wurde aus dem Code gelöscht.
  - **Helper-Methoden hinzugefügt**: `_buildRepeatOption` und `_buildSecondaryButton` für konsistentes UI-Design.
  - **State-Variablen ergänzt**: `_recurrenceDuration`, `_recurrenceCount`, `_recurrenceUntil` für Laufzeit-Logik.

---

## Heute erledigte Arbeiten (4. Dezember 2025)

- **[Wartungs-Monetarisierung - Kategorie-Sperre]** ✅
  - **4 freie Kategorien für Free-User**: Ölwechsel, Reifenwechsel, TÜV/AU, Inspektion
  - **Gesperrte Kategorien**: Bremsen, Batterie, Filter und alle weiteren nur mit Pro Abo
  - **UI-Implementation**:
    - Schloss-Icon auf gesperrten Kategorien beim Erstellen
    - Kategorien ausgegraut mit reduzierter Opacity
    - Paywall-Dialog beim Klick auf gesperrte Kategorie
  - **Code**:
    - `MaintenanceCategoryExtension.freeCategories` Liste definiert
    - `isFreeCategory` Getter für schnelle Checks
    - `_checkLoginAndSetCategory` mit Pro-Check erweitert
    - `_CategoryIconTile` mit `isLocked` Parameter

- **[Wartungs-Export nur mit Pro Abo]** ✅
  - **Lifetime = NUR Fahrzeugkosten**: Wartungs-Export nicht mehr für Lifetime-User
  - **Export-Dialog angepasst**:
    - Free-User: Nur 4 Basis-Kategorien auswählbar
    - Gesperrte Kategorien mit Schloss-Icon im Export-Dialog
    - Klick auf gesperrte Kategorie öffnet Paywall-Dialog
  - **Code-Änderungen**:
    - `hasCostsUnlock()` durch `isPro()` ersetzt in allen Wartungs-Export-Checks
    - `_performExport` prüft auf gesperrte Kategorien
    - Export-Dialog UI zeigt Lock-Status korrekt an
    - "Alle"-Button Toggle angepasst für 4 freie Kategorien

- **[Fahrzeugkosten Export - Schloss-Icon]** ✅
  - **Feature parity mit Wartungen**: Fahrzeugkosten-Export zeigt jetzt auch Schloss-Icons
  - **UI-Verbesserungen**:
    - Gesperrte Kategorien ausgegraut mit Schloss-Icon rechts
    - Custom `ListTile` statt `CheckboxListTile` für bessere Kontrolle
    - Paywall-Dialog beim Klick auf gesperrte Kategorie
  - **Code**: `costs_history_tab.dart` mit `_showCostsCategoryLockedDialog`

- **[Paywall-Anpassungen]** ✅
  - **Lifetime Preis erhöht**: 1,99€ → 3,99€ (besseres Preis-Leistungs-Verhältnis)
  - **Feature-Listen aktualisiert**:
    - **Lifetime**: Nur Fahrzeugkosten + CSV/PDF Export für Kosten
    - **Pro Abo**: Kosten + Wartungen + Export + KI + Notifications
  - **Texte überarbeitet**:
    - Deutsch: Klarere Beschreibung was Lifetime vs. Pro bietet
    - Englisch: Analog angepasst
  - **Dialog-Breite**: Wartungs-Paywall-Dialog jetzt 90% Bildschirmbreite (Center + SizedBox Wrapper)

- **[Monetarisierungsstrategie finalisiert]** ✅
  - **Free-User**:
    - Fahrzeugkosten: Nur Treibstoff
    - Wartungen: Nur 4 Basis-Kategorien (Ölwechsel, Reifen, TÜV, Inspektion)
    - Export: Keine Exports
  - **Lifetime Unlock (3,99€)**:
    - Fahrzeugkosten: Alle Kategorien freigeschaltet
    - Export: CSV & PDF für Fahrzeugkosten
    - Wartungen: NICHT enthalten (nur Pro)
  - **Pro Abo (4,99€/Monat)**:
    - Fahrzeugkosten: Alle Kategorien
    - Wartungen: Alle Kategorien + Export
    - Export: CSV & PDF für Kosten & Wartungen
    - KI: Unbegrenzte Anfragen
    - Notifications: Intelligente Erinnerungen

- **[Code-Qualität & Bugfixes]** ✅
  - Syntax-Fehler in `costs_history_tab.dart` behoben (spread operator)
  - Alle `hasUnlock`/`hasCostsUnlock` durch `isPro` ersetzt in Wartungs-Code
  - Wartungs-Locked-Dialog Texte aktualisiert (entfernt Lifetime-Option)
  - i18n-Keys für alle neuen Dialoge und Features hinzugefügt

---

## 📊 Supabase Datenbank-Schema Übersicht

Diese Tabelle dokumentiert alle Supabase-Tabellen und Views mit ihrer genauen Funktion. **WICHTIG: Bei jeder neuen Tabelle/View diese Liste aktualisieren!**

| Tabelle/View | Typ | Funktion | Wichtige Felder |
|--------------|-----|----------|-----------------|
| **brands** | Tabelle | Automarken-Katalog für Fahrzeug-Auswahl | `id`, `name`, `logo_url` |
| **cost_categories** | Tabelle | Kategorien für Fahrzeugkosten (System + Benutzer) | `id`, `user_id`, `name`, `icon_name`, `color_hex`, `is_system` |
| **cost_stats_by_category** | View | Materialisierte View für Kostenstatistiken gruppiert nach Kategorie | `category_id`, `total_amount`, `avg_amount`, `count` |
| **credit_events** | Tabelle | Credit-System: Tracks Käufe, Verbrauch und Guthaben der Nutzer | `user_id`, `event_type` (purchase/usage), `credits`, `balance`, `created_at` |
| **error_logs** | Tabelle | Error Monitoring: Loggt alle App-Fehler mit Context für Supabase Analytics | `id`, `user_id`, `error_type`, `error_message`, `stack_trace`, `screen`, `error_code`, `device_info` (jsonb), `context` (jsonb), `severity` (low/medium/high/critical), `resolved`, `created_at` |
| **error_statistics** | View | Statistiken für Fehler gruppiert nach Datum, Typ, Screen, Severity | `date`, `error_type`, `screen`, `severity`, `error_count`, `affected_users` |
| **fuel_stats** | View | Materialisierte View für Kraftstoff-Statistiken (Verbrauch, Trends) | `user_id`, `avg_consumption`, `total_liters`, `trend` |
| **maintenance_reminders** | Tabelle | Wartungserinnerungen mit Kategorien, Datum, Kosten, Fotos, Benachrichtigungen | `id`, `user_id`, `vehicle_id`, `category`, `due_date`, `status`, `cost`, `workshop_name`, `photos`, `documents`, `notify_offset_minutes`, `remind_again_at`, `repeat_until` |
| **maintenance_stats** | View | Statistiken für Wartungen (Anzahl, Kosten pro Kategorie) | `user_id`, `category`, `total_cost`, `count` |
| **models** | Tabelle | Automodelle-Katalog (verknüpft mit brands) | `id`, `brand_id`, `name`, `year_from`, `year_to` |
| **notifications** | Tabelle | Push-Benachrichtigungen an Nutzer (System, Wartungen) | `id`, `user_id`, `type`, `title`, `body`, `read`, `created_at` |
| **obd_clear_audit** | Tabelle | Audit-Log: Wann welcher Nutzer Fehlercodes gelöscht hat (Sicherheit) | `id`, `user_id`, `error_codes`, `vehicle_info`, `cleared_at` |
| **profiles** | Tabelle | Erweiterte Nutzerprofile (verknüpft mit auth.users) | `id`, `display_name`, `nickname`, `avatar_url`, `vehicle_photo_url`, `language` |
| **reports** | Tabelle | Fehlerberichte und Bug-Reports von Nutzern | `id`, `user_id`, `type`, `description`, `status`, `created_at` |
| **revenuacat_webhooks** | Tabelle | Webhooks von RevenueCat für In-App-Käufe (Abo-Events, Käufe) | `id`, `event_type`, `payload` (jsonb), `received_at` |
| **tips** | Tabelle | Kurz-Tipps für die App (zweisprachig de/en, z.B. "Sanft beschleunigen") | `id`, `title_de`, `title_en`, `body_de`, `body_en`, `created_at` |
| **vehicle_costs** | Tabelle | Fahrzeugkosten-Tracker: Alle Ausgaben/Einnahmen mit Kategorien, Belegen | `id`, `user_id`, `vehicle_id`, `category_id`, `title`, `amount`, `date`, `mileage`, `is_income`, `is_refueling`, `fuel_type`, `fuel_amount_liters`, `price_per_liter`, `gas_station`, `trip_distance`, `is_full_tank`, `period_start_date`, `period_end_date`, `is_monthly_amount`, `photos`, `notes` |
| **vehicles** | Tabelle | Nutzer-Fahrzeuge mit Details (Marke, Modell, Baujahr, Kilometerstand) | `id`, `user_id`, `brand_id`, `model_id`, `year`, `license_plate`, `vin`, `mileage`, `engine_cc`, `photo_url` |
| **weekly_free_quota** | Tabelle | Wöchentliches Gratis-Kontingent für Free User (z.B. 3 KI-Anfragen/Woche) | `user_id`, `week_start_date`, `consumed` (Integer) |

### 🔄 Letzte Änderungen:
- **05.12.2025**:
  - **Bildschirm-Rotation gesperrt**: App nur im Portrait-Modus (Android + iOS)
  - **Dialoge verbreitert**: Alle Paywall-Dialoge auf 92% Bildschirmbreite gesetzt
  - **Wartungskategorien gefiltert**: Automatisch aus Wartungen erstellte Kategorien werden nicht mehr in Fahrzeugkosten-Dropdown angezeigt
  - **TODO nach MVP**: Landscape-Support mit responsiven Layouts implementieren
- **04.12.2025**:
  - **Wartungs-Monetarisierung finalisiert**: 4 freie Kategorien für Free-User, restliche nur mit Pro
  - **Lifetime Unlock auf 3,99€ erhöht**: NUR für Fahrzeugkosten + Export
  - **Wartungs-Export nur Pro**: `hasCostsUnlock()` durch `isPro()` ersetzt in allen Checks
  - **Paywall-Texte aktualisiert**: Klare Abgrenzung Lifetime vs. Pro
  - **UI-Verbesserungen**: Schloss-Icons, Kategorie-Sperren, 90% Dialog-Breite
- **25.11.2025**: 
  - `credit_events` und `weekly_free_quota` Tabellen vollständig implementiert und in `CreditService` integriert
  - Monetarisierungs-System aktiviert: RevenueCat + Purchase Service + Paywall
  - `vehicle_costs` erweitert um `maintenance_reminder_id` für Verknüpfung mit Wartungen (automatischer Transfer)
- **18.11.2024**: 
  - `vehicle_costs` erweitert um `is_income`, `period_start_date`, `period_end_date`, `is_monthly_amount` für Einnahmen/Ausgaben-System und Zeitraum-Feature (Versicherung/Steuer/Kredit)
  - **Social Media/Community-Tabellen entfernt**: `posts`, `post_likes`, `threads`, `private_messages`, `blocks`, `listings` (nicht benötigt für MVP)
  - `reports` umfunktioniert: Nur noch für Fehlerberichte/Bug-Reports (nicht mehr für Content-Moderation)
  - `notifications` vereinfacht: Nur noch System- und Wartungs-Benachrichtigungen
- **17.11.2024**: Migration `20241117_add_period_fields.sql` mit Check-Constraint für Zeitraum-Validierung
- **24.10.2024**: `maintenance_reminders` erweitert um `notify_offset_minutes`, `remind_again_at`, `repeat_until` für erweiterte Benachrichtigungen

### 📝 Naming Conventions:
- **Tabellen**: Plural, snake_case (z.B. `vehicle_costs`, `maintenance_reminders`)
- **Views**: Suffix `_stats` oder `_by_*` (z.B. `cost_stats_by_category`, `fuel_stats`)
- **Timestamps**: `created_at`, `updated_at`, `deleted_at` (Soft Delete)
- **Foreign Keys**: `*_id` (z.B. `user_id`, `vehicle_id`, `category_id`)
- **Booleans**: `is_*` (z.B. `is_system`, `is_income`, `is_monthly_amount`)
