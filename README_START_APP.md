# 🚀 App Starten mit lokalen Keys

## Option 1: Terminal / Command Line

```bash
# Mit .env Datei
flutter run --dart-define-from-file=.env

# Oder für Release Build
flutter build apk --release --dart-define-from-file=.env
```

---

## Option 2: Android Studio

### Setup (einmalig):

1. **Öffne Run-Konfiguration:**
   - Menü: `Run` → `Edit Configurations...`

2. **Füge Argument hinzu:**
   - Finde: `Additional run args`
   - Trage ein: `--dart-define-from-file=.env`

3. **Speichern & Anwenden**

### Starten:
- Einfach auf "Run" klicken (grüner Play-Button)
- Die App lädt automatisch Keys aus `.env`

---

## Option 3: VS Code

### Setup in `launch.json`:

1. **Erstelle/Öffne:** `.vscode/launch.json`

2. **Füge hinzu:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "WeFixIt (Development)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define-from-file=.env"
      ]
    },
    {
      "name": "WeFixIt (Release)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define-from-file=.env",
        "--release"
      ]
    }
  ]
}
```

3. **Starten:**
   - `F5` oder Debug-Icon
   - Wähle Konfiguration aus Dropdown

---

## ⚠️ Wichtig:

### Was passiert:
- Flutter liest `.env` beim Start
- Lädt alle Keys als Environment Variables
- Code greift mit `String.fromEnvironment()` darauf zu

### Sicherheit:
- ✅ `.env` ist in `.gitignore` → wird NICHT committed
- ✅ Keys bleiben lokal auf deinem PC
- ✅ Jeder Entwickler hat seine eigene `.env`

---

## 🔍 Troubleshooting:

### "Missing Supabase URL/Key" Error?

**Prüfe:**
```bash
# 1. Existiert .env?
dir .env

# 2. Ist .env korrekt?
type .env

# 3. Startest du mit richtigem Befehl?
flutter run --dart-define-from-file=.env
```

### Keys werden nicht geladen?

**Lösung:**
```bash
# Flutter Clean & Rebuild
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env
```

---

## 📱 Production Build:

### Android APK:
```bash
flutter build apk --release --dart-define-from-file=.env
```

### Android App Bundle (Play Store):
```bash
flutter build appbundle --release --dart-define-from-file=.env
```

### iOS (macOS):
```bash
flutter build ios --release --dart-define-from-file=.env
```

---

## 🎯 Quick Start:

```bash
# 1. Stelle sicher, dass .env existiert
echo "Checking .env..."
type .env

# 2. Starte App
flutter run --dart-define-from-file=.env
```
