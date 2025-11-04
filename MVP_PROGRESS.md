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
- UI: Neues Grid-Dashboard mit Stats
, Kategorien-Grid, Vorschläge-Sektion und Quick Actions.
- Routing & Integration: Home-Link, neue Routen, i18n (de/en) für alle Texte.

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
  - Status: AUSSTEHEND (Gerüst vorhanden)
  - RevenueCat-Paket integriert, Flows/Paywall folgen (inkl. Credit-Logik, Pro-Bypass).
  - **Produkte definiert:**
    - Credits: 5 (1,29€), 10 (2,49€), 25 (5,49€)
    - KFZ-Kosten Lifetime: 1,99€ (wefixit_costs_lifetime)
    - Pro Basic: 4,99€/Monat oder 39,99€/Jahr
    - Pro Familie: 7,99€/Monat oder 59,99€/Jahr (Phase 3)

- **[Credits & Free-Quota Logic]**
  - Status: AUSSTEHEND

- **[Paywall (Multi-Page)]**
  - Status: AUSSTEHEND

- **[Profile & Privacy]**
  - Status: ERLEDIGT
  - Supabase `profiles` erweitert (display_name, nickname, vehicle_photo_url) + Trigger `on_auth_user_created`.
  - App: Profil-Formular (Name/Nickname, Avatar-/Fahrzeugfoto-Upload); Spracheinstellung ins Settings-Screen verlagert.
  - Fahrzeuge: Felder für Hubraum (cc/l) und Kilometerstand ergänzt (Schema vorhanden), UI und Save-Funktionalität implementiert.

- **[AI Backend Edge Functions / Systemprompt]**
  - Status: AUSSTEHEND (Stub-UI Ask Toni!)

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
  - Status: AUSSTEHEND (Schema wird ergänzt)
  - **Monetarisierungsstrategie:**
    - **Free User**: Nur Treibstoff/Kraftstoff-Kosten kostenlos erfassen
    - **Pro Basic/Familie Abo**: ALLE Kategorien (Wartung, Reparaturen, Versicherung, Steuer, Parken, Maut, Reinigung, etc.) + 12-Monate Historie + Charts + Budget-Alerts + CSV-Export
    - **Lifetime Unlock (1,99€)**: Einmalkauf schaltet ALLE KFZ-Kosten Kategorien für immer frei (Produkt-ID: wefixit_costs_lifetime)
  - Kategorien-Liste:
    - ✅ Treibstoff/Kraftstoff (immer kostenlos)
    - 🔒 Wartung (Ölwechsel, Inspektion, etc.)
    - 🔒 Reparaturen
    - 🔒 Versicherung
    - 🔒 KFZ-Steuer
    - 🔒 Parken/Maut
    - 🔒 Autowäsche/Reinigung
    - 🔒 TÜV/AU
    - 🔒 Sonstiges

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
