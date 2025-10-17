# WeFixIt – MVP Fortschritt (Stand: aktuell)

Dieses Dokument spiegelt den Umsetzungsstand der Anforderungen aus `wefixit_prompts_phases.json` wider und listet bewusst alle Abweichungen/Designanpassungen auf.

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

- **[Einfache Wartungserinnerungen]**
  - Status: ERLEDIGT ✅
  - Details:
    - Supabase Schema erstellt (`maintenance_reminders` Tabelle mit RLS)
    - Freezed Model (`MaintenanceReminder`) mit Date & Mileage Support
    - `MaintenanceService` für CRUD Operations
    - Moderner Wartungs-Screen im Tesla/Kleinanzeigen-Design:
      - Liste aller Erinnerungen (anstehend/erledigt)
      - Farbcodierte Status-Badges (Rot: überfällig, Orange: bald fällig, Grün: noch Zeit, Blau: kilometer-basiert)
      - Toggle für erledigte Erinnerungen
      - FloatingActionButton für neue Erinnerungen
    - Professioneller Add-Dialog:
      - Typ-Auswahl: Datum oder Kilometer
      - Wiederkehrende Erinnerungen (3/6/12 Monate oder km-basiert)
      - DatePicker Integration
      - Moderne Form Validation
    - Home-Screen Integration:
      - Nächste anstehende Wartung prominent angezeigt
      - Gradient-Card mit Status-Indikator
      - Direct Navigation zu Details
    - Route `/maintenance` hinzugefügt
    - Kostenlos für ALLE User (kein Login required für Liste, Login nur für Anlegen/Bearbeiten)

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
