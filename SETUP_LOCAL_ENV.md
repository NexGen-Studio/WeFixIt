# 🔧 Lokale .env Datei einrichten

## 📋 Warum brauchst du .env?

- ✅ Speichert deine **echten** API Keys lokal
- ✅ Wird **NICHT** in Git committed (.gitignore schützt sie)
- ✅ Jeder Entwickler hat seine eigenen Keys
- ✅ Sicherer als hardcoded Keys

---

## 🚀 Schnell-Setup (Copy & Paste)

### Windows (PowerShell):
```powershell
# Erstelle .env mit echten Keys
@"
# Supabase Configuration
SUPABASE_URL=https://zbrlhswafnlpfwqikapu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpicmxoc3dhZm5scGZ3cWlrYXB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2MDkyMjEsImV4cCI6MjA3NDE4NTIyMX0.UZVKgCtV0j5MCpPymNnL1RkV_JQLQKwidOUud6Asn7M

# RevenueCat Configuration
REVENUECAT_PUBLIC_SDK_KEY_ANDROID=test_NZPOpTUffQhhAuREEDZaFvdGWvK
REVENUECAT_PUBLIC_SDK_KEY_IOS=YOUR_IOS_SDK_KEY

# AdMob Test IDs
ADMOB_APP_ID_ANDROID=ca-app-pub-3940256099942544~3347511713
ADMOB_BANNER_320x50_ANDROID=ca-app-pub-3940256099942544/6300978111
ADMOB_BANNER_300x250_ANDROID=ca-app-pub-3940256099942544/6300978111
ADMOB_REWARDED_ANDROID=ca-app-pub-3940256099942544/5224354917

# Optional
FCM_SENDER_ID=
FIREBASE_ANDROID_APP_ID=
FIREBASE_IOS_APP_ID=
AI_BASE_URL=
"@ | Out-File -FilePath .env -Encoding UTF8

Write-Host "✅ .env erstellt!"
```

### macOS / Linux (bash):
```bash
cat > .env << 'EOF'
# Supabase Configuration
SUPABASE_URL=https://zbrlhswafnlpfwqikapu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpicmxoc3dhZm5scGZ3cWlrYXB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2MDkyMjEsImV4cCI6MjA3NDE4NTIyMX0.UZVKgCtV0j5MCpPymNnL1RkV_JQLQKwidOUud6Asn7M

# RevenueCat Configuration
REVENUECAT_PUBLIC_SDK_KEY_ANDROID=test_NZPOpTUffQhhAuREEDZaFvdGWvK
REVENUECAT_PUBLIC_SDK_KEY_IOS=YOUR_IOS_SDK_KEY

# AdMob Test IDs
ADMOB_APP_ID_ANDROID=ca-app-pub-3940256099942544~3347511713
ADMOB_BANNER_320x50_ANDROID=ca-app-pub-3940256099942544/6300978111
ADMOB_BANNER_300x250_ANDROID=ca-app-pub-3940256099942544/6300978111
ADMOB_REWARDED_ANDROID=ca-app-pub-3940256099942544/5224354917

# Optional
FCM_SENDER_ID=
FIREBASE_ANDROID_APP_ID=
FIREBASE_IOS_APP_ID=
AI_BASE_URL=
EOF

echo "✅ .env erstellt!"
```

---

## 📝 Manuelle Erstellung

### Option 1: Notepad (Windows)
```bash
notepad .env
```

### Option 2: VS Code
```bash
code .env
```

### Option 3: Windows Explorer
1. Rechtsklick → Neu → Textdokument
2. Umbennen zu `.env` (ohne .txt!)
3. Öffnen & Keys einfügen

**Wichtig:** Dateiname muss **EXAKT** `.env` sein (MIT Punkt am Anfang!)

---

## 🔐 Backup-System (Empfohlen)

### 1. Erstelle verschlüsseltes Backup:

**Windows (7-Zip mit Passwort):**
```powershell
# Erstelle verschlüsseltes Archiv
7z a -p -mhe=on env_backup.7z .env

# Speichere an sicherem Ort (z.B. OneDrive, USB-Stick)
# NICHT im Projekt-Ordner!
```

**macOS / Linux:**
```bash
# Verschlüssel mit GPG
gpg -c .env
# Erstellt: .env.gpg

# Entschlüsseln:
gpg .env.gpg
```

### 2. Oder: Passwort-Manager verwenden
- **1Password**, **Bitwarden**, **LastPass**
- Speichere Keys als "Secure Note"
- Bei Bedarf Copy & Paste in neue `.env`

---

## ✅ Verifizierung

### Prüfe ob .env korrekt ist:

```bash
# 1. Existiert die Datei?
dir .env          # Windows
ls -la .env       # macOS/Linux

# 2. Ist sie in .gitignore?
git check-ignore .env
# Output sollte sein: .env

# 3. Inhalt anzeigen
type .env         # Windows
cat .env          # macOS/Linux

# 4. Teste App-Start
flutter run --dart-define-from-file=.env
```

---

## 🔄 Keys aktualisieren

### Wenn sich Keys ändern:

1. **Öffne .env:**
   ```bash
   notepad .env    # Windows
   code .env       # VS Code
   ```

2. **Aktualisiere Keys:**
   - Ersetze alte Keys mit neuen
   - Speichern

3. **Flutter neu starten:**
   ```bash
   flutter clean
   flutter pub get
   flutter run --dart-define-from-file=.env
   ```

---

## 🆘 Troubleshooting

### ".env nicht gefunden" Error?

**Check 1: Bist du im richtigen Ordner?**
```bash
pwd                           # Aktueller Pfad
cd C:\Users\Senkbeil\AndroidStudioProjects\wefixit
```

**Check 2: Existiert .env?**
```bash
dir .env
# Sollte die Datei anzeigen
```

**Check 3: Versteckte Dateien anzeigen?**
- Windows Explorer → Ansicht → Versteckte Elemente aktivieren

### "Keys werden nicht geladen"?

**Lösung:**
```bash
# 1. Clean
flutter clean

# 2. Pub get
flutter pub get

# 3. Mit korrektem Flag starten
flutter run --dart-define-from-file=.env

# NICHT:
flutter run --dart-define-from-file env    # ❌ Falsch!
flutter run --dart-define-from-file=env.example  # ❌ Falsch!
```

### "BOM encoding" Error?

**.env darf KEINE BOM haben!**

**Fix (VS Code):**
1. .env öffnen
2. Unten rechts auf "UTF-8 with BOM" klicken
3. "Save with Encoding" → "UTF-8" (ohne BOM)

---

## 📱 Für Team-Entwicklung

### Wenn mehrere Entwickler am Projekt arbeiten:

1. **Jeder hat seine eigene `.env`**
   - Nicht teilen! (jeder hat ggf. andere Keys)

2. **Template bereitstellen:**
   - `env.example.template` in Git (ohne echte Keys)
   - Andere Entwickler kopieren und füllen aus

3. **Dokumentation:**
   - README mit Setup-Anleitung
   - Wo bekomme ich Keys? → Links zu Dashboards

---

## 🎯 Zusammenfassung

### Was du brauchst:
```
Projektordner/
├── .env                    ← Deine echten Keys (LOKAL, nicht in Git!)
├── .gitignore              ← Schützt .env
├── env.example.template    ← Template ohne Keys (in Git)
└── README_START_APP.md     ← Anleitung zum Starten
```

### Workflow:
1. `.env` erstellen (einmalig)
2. Keys eintragen
3. App starten: `flutter run --dart-define-from-file=.env`
4. **NIEMALS** `.env` in Git committen!

✅ **Fertig!** Deine Keys sind jetzt sicher! 🔒
