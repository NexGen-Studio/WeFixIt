# WeFixIt – MVP Fortschritt (Stand: aktuell)

Dieses Dokument spiegelt den Umsetzungsstand der Anforderungen aus `wefixit_prompts_phases.json` wider und listet bewusst alle Abweichungen/Designanpassungen auf.

> Hinweis: Diese Datei wird fortlaufend gepflegt und nach Änderungen am Wartungs-Feature sofort aktualisiert.

## Wartungen – Vollständiges System (FERTIG)

- Kategorien: Ölwechsel, Reifenwechsel, Bremsen, TÜV/AU, Inspektion, Batterie, Filter, Versicherung, Steuer, Sonstiges.
- Erweiterte Details: Werkstatt (Name, Adresse), Notizen, Kilometerstand bei Wartung, Kosten (mit Währung).
- Medien: Foto-Upload (Bilder), Dokumente-Upload (PDF), Supabase Storage-Anbindung.
- Status & Logik: Geplant, Erledigt, Überfällig; wiederkehrend (3/6/12 Monate) bzw. km-basiert.
- Intelligente Vorschläge: Ölwechsel/TÜV/Reifen/Inspektion/Batterie basierend auf Historie und Kilometerstand.
- Benachrichtigungen: Lokale Push-Notifications (Reminder vor Fälligkeit, Overdue-Hinweis), Timezone-Support.
- Export: CSV und detaillierter PDF/Report (Statistiken, Summen, Filter).
- UI: Neues Grid-Dashboard mit Stats, Kategorien-Grid, Vorschläge-Sektion und Quick Actions.
- Routing & Integration: Home-Link, neue Routen, i18n (de/en) für alle Texte.

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
    - KFZ-Kosten Lifetime: 1,99€ (wefixit_costs_lifetime)
    - Pro Basic: 4,99€/Monat oder 39,99€/Jahr
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
  - Status: TEILWEISE ERLEDIGT ✅
  - Chatbot-UI (Ask Toni!) vollständig implementiert
  - Credit-Gating: Pro-User Bypass + Gratis-Quota/Credits-Check vor jeder Nachricht
  - Chat-Verlauf mit Nachrichten-Bubbles (User/Bot)
  - Suggestion-Cards für schnelle Fragen
  - Stub-Antworten (2s Delay simuliert AI-Verarbeitung)
  - **TODO:** Echte AI Edge Function mit OpenAI/Anthropic Integration

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
  - Status: IN UMSETZUNG ✅
  - **Monetarisierungsstrategie:**
    - **Free User**: Nur Treibstoff/Kraftstoff-Kosten kostenlos erfassen
    - **Pro Basic Abo (4,99€/Monat)**: ALLE Kategorien + 1 Fahrzeug + CSV-Export
    - **Lifetime Unlock (1,99€)**: Einmalkauf schaltet ALLE KFZ-Kosten Kategorien für 1 Fahrzeug für immer frei (Produkt-ID: wefixit_costs_lifetime)
  
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

## Heute erledigte Arbeiten (16. Oktober 2025)

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

## Nächste Aufgaben (Kurzfristige Roadmap)

- **[Dokumentation & Pflege]**
  - Status: LAUFEND
  - `MVP_PROGRESS.md` wird bei jeder Änderung am Wartungsmodul aktualisiert (Quelle: `WARTUNGSERINNERUNGEN_SETUP.md`, `WARTUNGEN_FEATURES_ROADMAP.md`).

- **[Profil vervollständigen]**: Formular (Anzeigename, Nickname), Avatar-/Fahrzeugfoto-Upload; Sprache ist in Settings verschoben (de/en) – Supabase-Anbindung vorhanden.
- **[Home personalisieren]**: „Hallo {Name}!“, kleines Fahrzeugfoto anzeigen.
- **[Komponenten-Kit]**: Buttons, Cards, Badge, Modal, PaywallCarousel, AdBanner 320x50 & 300x250 (Platzhalter → echte AdMob-IDs später).
- **[Screens refactoren]**: Bestehende Screens auf neues Komponenten-Kit umstellen (`PrimaryButton`, `SecondaryButton`, `GlassCard`, `Badge`, `showAppModal`, `PaywallCarousel`, `AdBannerPlaceholder` mit Größen).
  - Schritte:
    - Profil (`lib/src/features/profile/profile_screen.dart`): `_GlassCard`/`_GlassButton` entfernen und durch `GlassCard`/`PrimaryButton` ersetzen; `AdBannerPlaceholder(size: ...)` gezielt setzen.
    - Home (`lib/src/features/home/home_screen.dart`): kleines Badge-Beispiel integrieren; `showAppModal()` Beispiel (z. B. Info-Overlay) hinzufügen.
    - Settings (`lib/src/features/settings/settings_screen.dart`): Cards auf `GlassCard` konsolidieren; Overlays mit `showAppModal()`.
    - Paywall-Stub: optionalen `paywall_screen.dart` mit `PaywallCarousel` und CTAs (`PrimaryButton`/`SecondaryButton`) anlegen; Route `/paywall` hinter Feature-Flag.
    - Importe konsolidieren: `widgets/buttons.dart`, `widgets/glass_card.dart`, `widgets/badge.dart`, `widgets/modal.dart`, `widgets/paywall_carousel.dart` verwenden.
  - Akzeptanzkriterien:
    - Build läuft ohne Fehler/Warnings; keine privaten Duplikate (`_GlassCard`, `_GlassButton`).
    - Optische Parität oder Verbesserung im Dark-Design.
    - Ads: 320x50 im Shell-Footer, 300x250 (MREC) dort, wo vorgesehen.
    - Modal: Öffnen/Schließen funktioniert (ein Beispiel in Home oder Settings).
- **[Wartungserinnerungen & Kosten]**: Tabellen + RLS, einfache Screens (Listen/Forms), Home-Anbindung.
- **[Splash mit Logo]**: Generierungsbefehle ausführen und testen.
- **[Monetarisierung]**: Paywall + RevenueCat-Flows + Credit-Logik.

## Technische Hinweise/ToDos außerhalb der App

- **[Supabase]**: Schema angewendet. Bitte Bucket `vehicle_photos` (public) im Storage anlegen (für Fahrzeugfotos).
- **[Routen]**: `/settings` Route hinzugefügt; Zahnrad im Profil navigiert dorthin.
- **[Branding]**: Icon/Splash-Konfigurationen/Assets entfernt (Rollback). Neue Umsetzung wird separat geplant.
- **[Android Studio Run]**: App immer mit Defines starten: `--dart-define-from-file=env.example`.
- **[RevenueCat/AdMob]**: Produkt-/App-IDs in den nächsten Schritten hinterlegen.

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

## 📊 Supabase Datenbank-Schema Übersicht

Diese Tabelle dokumentiert alle Supabase-Tabellen und Views mit ihrer genauen Funktion. **WICHTIG: Bei jeder neuen Tabelle/View diese Liste aktualisieren!**

| Tabelle/View | Typ | Funktion | Wichtige Felder |
|--------------|-----|----------|-----------------|
| **brands** | Tabelle | Automarken-Katalog für Fahrzeug-Auswahl | `id`, `name`, `logo_url` |
| **cost_categories** | Tabelle | Kategorien für Fahrzeugkosten (System + Benutzer) | `id`, `user_id`, `name`, `icon_name`, `color_hex`, `is_system` |
| **cost_stats_by_category** | View | Materialisierte View für Kostenstatistiken gruppiert nach Kategorie | `category_id`, `total_amount`, `avg_amount`, `count` |
| **credit_events** | Tabelle | Credit-System: Tracks Käufe, Verbrauch und Guthaben der Nutzer | `user_id`, `event_type` (purchase/usage), `credits`, `balance`, `created_at` |
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
