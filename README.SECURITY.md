# 🔒 WeFixIt - Sicherheits-Dokumentation

## ⚠️ WICHTIG: Vor dem ersten Git Commit!

### 🚨 SOFORT ERLEDIGEN:

1. **Entferne deine echten API Keys aus `env.example`:**
```bash
# Sichere deine echten Keys (lokal, NICHT in Git!)
cp env.example env.example.backup

# Ersetze env.example mit dem Template
cp env.example.template env.example
```

2. **Überprüfe .gitignore:**
```bash
# Diese Dateien sollten NIEMALS committed werden:
cat .gitignore | grep -E "\.env|env\.example"
```

3. **Prüfe Git History:**
```bash
# Falls du bereits committed hast:
git log --all --full-history -- env.example

# Falls env.example in der History ist, musst du die History bereinigen!
# ACHTUNG: Das ändert die Git-History!
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch env.example" \
  --prune-empty --tag-name-filter cat -- --all
```

---

## 📋 Sicherheits-Übersicht

### ✅ Was ist SICHER:

#### 1. **Datenbank (Supabase)**
- ✅ **Row Level Security (RLS)** ist auf ALLEN Tabellen aktiviert
- ✅ **Policies** verwenden `auth.uid()` für User-Isolation
- ✅ Kein User kann Daten anderer User sehen/ändern

**Beispiel:**
```sql
-- Nur eigene Wartungen sichtbar
CREATE POLICY "maintenance_owner_all" 
ON maintenance_reminders 
FOR ALL USING (auth.uid() = user_id);
```

#### 2. **API Zugriff**
- ✅ Nur **Anon Key** wird verwendet (kein Service Role Key im Code)
- ✅ Alle Queries gehen durch Supabase Client
- ✅ Keine SQL Injection möglich

#### 3. **Authentifizierung**
- ✅ Supabase Auth mit Email/Passwort
- ✅ Session Management durch Supabase
- ✅ JWT Tokens werden sicher gespeichert

#### 4. **Storage**
- ✅ **Bucket Policies** für vehicle_photos & avatars
- ✅ Nur authentifizierte User können hochladen
- ✅ User können nur ihre eigenen Files löschen

---

### ⚠️ Was du BEACHTEN musst:

#### 1. **API Keys schützen**

**❌ FALSCH:**
```dart
// NIEMALS so!
const apiKey = 'test_NZPOpTUffQhhAuREEDZaFvdGWvK';
```

**✅ RICHTIG:**
```dart
// Immer aus Environment laden
const apiKey = String.fromEnvironment('REVENUECAT_PUBLIC_SDK_KEY_ANDROID');
```

#### 2. **Environment Variables verwenden**

**Lokale Entwicklung:**
```bash
flutter run --dart-define-from-file=env.example
```

**Android Studio:**
1. Run → Edit Configurations
2. Additional run args: `--dart-define-from-file=env.example`

**VS Code (launch.json):**
```json
{
  "configurations": [
    {
      "args": [
        "--dart-define-from-file=env.example"
      ]
    }
  ]
}
```

#### 3. **Git Commits überprüfen**

**Vor JEDEM Commit:**
```bash
# 1. Prüfe was committed wird
git status

# 2. Suche nach API Keys im Code
grep -r "SUPABASE_URL\|ANON_KEY\|apiKey.*=" lib/

# 3. Überprüfe env.example
cat env.example | grep -i "key\|url"

# 4. Nur committen wenn KEINE echten Keys drin sind!
git add .
git commit -m "Your message"
```

---

## 🛡️ Supabase RLS Policies

### Wie RLS funktioniert:

```sql
-- 1. RLS aktivieren
ALTER TABLE maintenance_reminders ENABLE ROW LEVEL SECURITY;

-- 2. Policy erstellen
CREATE POLICY "owner_access" ON maintenance_reminders
FOR ALL                              -- SELECT, INSERT, UPDATE, DELETE
USING (auth.uid() = user_id)        -- User kann nur seine Daten sehen
WITH CHECK (auth.uid() = user_id);  -- User kann nur für sich Daten erstellen
```

### Aktuelle Policies:

| Tabelle | Policy | Beschreibung |
|---------|--------|--------------|
| `profiles` | `profiles_self_*` | User kann nur sein eigenes Profil sehen/ändern |
| `vehicles` | `vehicles_owner_all` | User kann nur seine Fahrzeuge verwalten |
| `maintenance_reminders` | `maintenance_owner_all` | User kann nur seine Wartungen sehen |
| `vehicle_costs` | `costs_owner_all` | User kann nur seine Kosten sehen |
| `storage.objects` | `vehicle_photos_*` | User kann nur seine Fotos verwalten |

### RLS testen:

```sql
-- Teste als User A:
SELECT * FROM maintenance_reminders;
-- Sollte nur Wartungen von User A zeigen

-- Teste als User B:
SELECT * FROM maintenance_reminders WHERE user_id = 'USER_A_ID';
-- Sollte LEER sein (keine Daten von User A)!
```

---

## 🔐 Secrets Management

### Wo werden Secrets gespeichert?

1. **Lokal (Development):**
   - `env.example` (NICHT in Git committen!)
   - Wird geladen via `--dart-define-from-file`

2. **CI/CD (GitHub Actions):**
   - Repository Settings → Secrets and Variables → Actions
   - Secrets als Environment Variables setzen

3. **Production (App Store / Play Store):**
   - Android: `android/local.properties` (in .gitignore!)
   - iOS: Xcode Build Settings

### Secrets rotieren:

**Falls ein Key kompromittiert wurde:**

1. **Supabase:**
   - Dashboard → Settings → API → Regenerate Anon Key
   - Neue Keys in env.example eintragen
   - App neu bauen und deployen

2. **RevenueCat:**
   - Dashboard → API Keys → Regenerate
   - Neue Keys in env.example eintragen
   - App neu bauen

---

## 📊 Security Monitoring

### Supabase Logs überwachen:

1. **Dashboard → Logs**
   - API Requests
   - Failed Auth Attempts
   - Rate Limits

2. **Security Advisor nutzen:**
   - Dashboard → Advisors
   - RLS Warnings beachten
   - Performance Issues beheben

### Verdächtige Aktivitäten:

```sql
-- Ungewöhnlich viele Requests von einer IP?
SELECT 
  ip_address, 
  COUNT(*) as requests 
FROM auth.audit_log_entries 
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY ip_address 
ORDER BY requests DESC;
```

---

## ⚡ Quick Security Audit

### 5-Minuten Check:

```bash
# 1. API Keys im Code?
grep -r "SUPABASE_URL\|ANON_KEY" lib/ --exclude-dir=.dart_tool

# 2. Hardcoded Secrets?
grep -r "apiKey.*=.*['\"]" lib/ | grep -v "fromEnvironment"

# 3. .gitignore korrekt?
git check-ignore env.example .env

# 4. Git History sauber?
git log --all --full-history -- env.example

# 5. RLS aktiviert?
# → Supabase Dashboard → Database → Tables → Prüfe "RLS enabled"
```

---

## 📞 Support & Hilfe

### Bei Sicherheitsproblemen:

1. **Supabase Support:** https://supabase.com/support
2. **RevenueCat Docs:** https://docs.revenuecat.com/
3. **Flutter Security:** https://docs.flutter.dev/security

### Melde Sicherheitslücken:

- **NIEMALS** öffentlich posten
- Kontaktiere den Entwickler direkt
- Nutze Supabase Security Reporting

---

## ✅ Zusammenfassung

### DO's ✅
- Environment Variables für alle Secrets
- RLS auf allen User-Tabellen
- Supabase Client für DB-Zugriffe
- .gitignore für sensible Dateien
- Regelmäßige Security Audits

### DON'Ts ❌
- Hardcoded API Keys
- env.example mit echten Keys committen
- Service Role Key im App-Code
- SQL Queries ohne Supabase Client
- Ungeschützte Storage Buckets

---

**Bei Fragen zur Sicherheit: Lies zuerst SECURITY_CHECKLIST.md!**
