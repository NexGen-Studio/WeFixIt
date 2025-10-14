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
  - Status: IN ARBEIT
  - Bisher:
    - Globaler, dezenter automotive-Hintergrund (dunkle Blau-/Petroltöne) statt bunter Verlauf – professioneller Look (Abweichung: Hintergrundfarbe/-optik).
    - Transparente AppBars, „Glass“-Buttons/Karten, abgerundete Ecken.
    - BottomNavigation halbtransparent, größere Icons/Labels.
    - Diagnose/Ask Toni: Blaue Sektionen entfernt; Eingabefelder/Buttons in dunklen Grautönen (#3A3A3A / #4A4A4A), Text Weiß.
    - Settings: Modernes Dark-Design mit grauen Kacheln (#2F2F2F), weiße Typo, stilisiertes Locale-Dropdown.
  - Nächste Schritte:
    - Komponenten-Kit (Primary/Secondary Button, Card, Badge, Modal/Overlay, PaywallCarousel) finalisieren.

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
  - Status: AUSSTEHEND (nächster Block; Schema wird ergänzt)

- **[Einfacher Kosten-Tracker]**
  - Status: AUSSTEHEND (nächster Block; Schema wird ergänzt)

- **[Testing & QA Flows]**
  - Status: AUSSTEHEND

- **[Deployment Notes]**
  - Status: AUSSTEHEND

## Wichtige Design-/Funktions-Abweichungen (bewusst)

- **[Tabs]**: 4 Tabs statt 3 – zusätzlicher `Home`-Tab auf Wunsch.
- **[Ask Toni!]**: Tab und Screen umbenannt (statt „Chatbot“).
- **[Kein Gastmodus]**: Anmeldung verpflichtend (gewünscht), ursprünglicher MVP vorsah optionalen Gastmodus.
- **[Hintergrund]**: Dunkler automotive-Look (statt bunter Verlauf); erhöht Professionalität.

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
