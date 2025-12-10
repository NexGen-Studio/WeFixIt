# 🔑 API Keys & Configuration Guide

## 📍 Wo bekomme ich welche Keys?

### 1. **Supabase Keys** (ERFORDERLICH)

**Wo:** [Supabase Dashboard](https://supabase.com/dashboard)

1. Öffne dein Projekt
2. Gehe zu: **Settings** → **API**
3. Kopiere:
   - **URL**: `Project URL`
   - **ANON KEY**: `anon public` (NICHT service_role!)

**In .env:**
```env
SUPABASE_URL=https://DEIN-PROJECT.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
```

⚠️ **WICHTIG:** 
- Verwende **NUR** den `anon` Key (öffentlich)
- **NIEMALS** den `service_role` Key (hat Admin-Rechte!)

---

### 2. **RevenueCat Keys** (ERFORDERLICH für In-App Käufe)

**Wo:** [RevenueCat Dashboard](https://app.revenuecat.com/)

1. Gehe zu deiner App
2. **Settings** → **API Keys**
3. Kopiere:
   - Android: **Public SDK Key**
   - iOS: **Public SDK Key**

**In .env:**
```env
REVENUECAT_PUBLIC_SDK_KEY_ANDROID=test_XXXXXXXXXXXXXXXXXX
REVENUECAT_PUBLIC_SDK_KEY_IOS=test_YYYYYYYYYYYYYYYYYY
```

**Test-Keys (für Development):**
- Die App verwendet aktuell Test-Keys
- Für Production: Ersetze mit echten Keys

---

### 3. **AdMob IDs** (OPTIONAL - für Werbung)

**Wo:** [Google AdMob Console](https://apps.admob.com/)

1. Wähle deine App
2. **App Settings** → **App Info**
3. Kopiere **App ID**
4. Gehe zu **Ad Units**
5. Kopiere IDs für:
   - Banner (320x50)
   - Banner (300x250)
   - Rewarded Ad

**In .env:**
```env
# Production IDs (wenn du echte Ads schalten willst)
ADMOB_APP_ID_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
ADMOB_BANNER_320x50_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
ADMOB_BANNER_300x250_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
ADMOB_REWARDED_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```

**Test-IDs (für Development):**
```env
# Google's offizielle Test-IDs (immer verwenden während Entwicklung!)
ADMOB_APP_ID_ANDROID=ca-app-pub-3940256099942544~3347511713
ADMOB_BANNER_320x50_ANDROID=ca-app-pub-3940256099942544/6300978111
ADMOB_BANNER_300x250_ANDROID=ca-app-pub-3940256099942544/6300978111
ADMOB_REWARDED_ANDROID=ca-app-pub-3940256099942544/5224354917
```

⚠️ **WICHTIG:**
- **Development:** Verwende Test-IDs
- **Production:** Ersetze mit echten IDs
- Sonst: Account-Sperrung durch Google!

---

### 4. **Firebase** (OPTIONAL - für Push Notifications)

**Wo:** [Firebase Console](https://console.firebase.google.com/)

1. Wähle dein Projekt
2. **Project Settings** → **Cloud Messaging**
3. Kopiere **Sender ID**

**In .env:**
```env
FCM_SENDER_ID=123456789012
FIREBASE_ANDROID_APP_ID=1:123456789012:android:abc123
FIREBASE_IOS_APP_ID=1:123456789012:ios:xyz789
```

---

### 5. **AI Configuration** (OPTIONAL - für Custom AI)

Falls du einen eigenen AI-Service verwendest:

**In .env:**
```env
AI_BASE_URL=https://your-ai-service.com/api
```

---

## 🔄 Keys rotieren (erneuern)

### Wann Keys ändern?

- ✅ Bei Verdacht auf Kompromittierung
- ✅ Regelmäßig (z.B. alle 6 Monate)
- ✅ Bei Team-Wechsel (Mitarbeiter verlässt Projekt)

### Wie Keys rotieren?

#### Supabase:
1. Dashboard → **Settings** → **API**
2. **Regenerate** bei "anon public"
3. Neuen Key in `.env` eintragen
4. App neu deployen

#### RevenueCat:
1. Dashboard → **Settings** → **API Keys**
2. **Regenerate** Public SDK Key
3. Neuen Key in `.env` eintragen
4. App neu deployen

#### AdMob:
- AdMob IDs ändern sich normalerweise nicht
- Bei Problemen: Neue Ad Unit erstellen

---

## ⚠️ Sicherheits-Richtlinien

### DO's ✅

| Action | Beschreibung |
|--------|--------------|
| **Anon Key verwenden** | Supabase `anon` Key ist sicher für Client |
| **Test-IDs nutzen** | AdMob Test-IDs während Development |
| **Keys in .env** | Alle Keys in lokaler `.env` Datei |
| **.env in .gitignore** | `.env` wird NICHT committed |
| **Regelmäßig rotieren** | Keys alle 6 Monate erneuern |

### DON'Ts ❌

| Action | Warum? |
|--------|--------|
| **Service Role Key** | Hat Admin-Rechte, NIEMALS im Client! |
| **Production AdMob in Dev** | Google sperrt Account bei Test-Traffic |
| **Keys hardcoded** | Jeder kann sie aus APK extrahieren |
| **.env committen** | Keys werden öffentlich auf GitHub |
| **Keys teilen** | Jeder Entwickler eigene Keys |

---

## 🧪 Testing

### Test ob Keys funktionieren:

**Supabase:**
```bash
# Starte App
flutter run --dart-define-from-file=.env

# Versuche Login
# Sollte funktionieren wenn Keys korrekt
```

**RevenueCat:**
```bash
# Öffne Paywall in der App
# Sollte Angebote laden
# Im Debug: "RevenueCat configured successfully"
```

**AdMob:**
```bash
# App starten
# Ads sollten laden (Test-Ads wenn Test-IDs)
# Echte Ads nur mit Production-IDs
```

---

## 🎯 Quick Reference

### Minimal-Setup (nur Pflicht-Keys):

```env
# Pflicht für App-Funktionalität
SUPABASE_URL=https://dein-projekt.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...

# Pflicht für Käufe
REVENUECAT_PUBLIC_SDK_KEY_ANDROID=test_xxx

# Optional (App funktioniert auch ohne)
ADMOB_APP_ID_ANDROID=ca-app-pub-3940256099942544~3347511713
```

### Full-Setup (alle Keys):

```env
# Supabase (Pflicht)
SUPABASE_URL=...
SUPABASE_ANON_KEY=...

# RevenueCat (Pflicht)
REVENUECAT_PUBLIC_SDK_KEY_ANDROID=...
REVENUECAT_PUBLIC_SDK_KEY_IOS=...

# AdMob (Optional)
ADMOB_APP_ID_ANDROID=...
ADMOB_BANNER_320x50_ANDROID=...
ADMOB_BANNER_300x250_ANDROID=...
ADMOB_REWARDED_ANDROID=...

# Firebase (Optional)
FCM_SENDER_ID=...
FIREBASE_ANDROID_APP_ID=...
FIREBASE_IOS_APP_ID=...

# AI (Optional)
AI_BASE_URL=...
```

---

## 📞 Support

### Keys funktionieren nicht?

1. **Überprüfe Format:**
   - Keine Leerzeichen vor/nach `=`
   - Keine Anführungszeichen um Werte
   - Korrekte Key-Namen (case-sensitive!)

2. **Flutter Clean:**
   ```bash
   flutter clean
   flutter pub get
   flutter run --dart-define-from-file=.env
   ```

3. **Logs checken:**
   ```bash
   # Supabase Fehler?
   # -> Dashboard → Logs

   # RevenueCat Fehler?
   # -> Dashboard → Customer Lists → Debugger
   ```

---

**Bei weiteren Fragen: Siehe `SETUP_LOCAL_ENV.md`** 📖
