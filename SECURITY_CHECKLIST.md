# 🔒 Sicherheits-Checkliste für WeFixIt

## ✅ Vor dem Deployment / Git Commit

### 1. **API Keys & Secrets**
- [ ] `env.example` enthält **KEINE** echten API Keys
- [ ] `.env` ist in `.gitignore` enthalten
- [ ] Alle API Keys werden über Environment Variables geladen
- [ ] RevenueCat Keys sind NICHT hardcoded
- [ ] Supabase Keys sind NICHT im Code sichtbar

### 2. **Git Repository**
```bash
# Überprüfe, was committed wird:
git status

# Stelle sicher, dass diese Dateien NICHT getrackt werden:
# - env.example (mit echten Keys)
# - .env
# - Jegliche Dateien mit API Keys
```

### 3. **Supabase Sicherheit**
- [x] Row Level Security (RLS) ist für ALLE Tabellen aktiviert
- [x] RLS Policies verwenden `auth.uid()` für User-Isolation
- [x] Storage Policies sind korrekt konfiguriert
- [x] Keine direkten SQL Queries (nur Supabase Client)

### 4. **Code Review**
```bash
# Suche nach exponierten Secrets:
grep -r "SUPABASE_URL\|ANON_KEY\|apiKey.*=" lib/

# Suche nach hardcodierten URLs/Tokens:
grep -r "http://\|https://" lib/ | grep -v "github.com"
```

## 🚨 WICHTIGE SICHERHEITSREGELN

### ❌ NIEMALS committen:
1. `env.example` mit echten API Keys
2. `.env` Dateien
3. Hardcodierte API Keys im Code
4. Supabase Service Role Keys (nur Anon Key ist ok)
5. Private Keys, Zertifikate
6. Datenbank-Passwörter

### ✅ IMMER verwenden:
1. Environment Variables für alle Secrets
2. `.gitignore` für sensible Dateien
3. RLS Policies für alle User-Daten
4. `auth.uid()` in allen Policies
5. Supabase Client (keine raw SQL Queries)

## 📋 Deployment Checkliste

### Vor Produktions-Release:
- [ ] Alle Test-API-Keys durch Production-Keys ersetzen
- [ ] AdMob Test-IDs durch echte IDs ersetzen
- [ ] RevenueCat Keys für Production setzen
- [ ] Supabase RLS Policies testen
- [ ] Storage Policies verifizieren
- [ ] Input Validation überprüfen

## 🔐 Supabase RLS Status

### ✅ Aktivierte Tabellen:
- `profiles` - ✅ RLS mit self-policies
- `vehicles` - ✅ RLS mit owner-policies  
- `maintenance_reminders` - ✅ RLS mit owner-policies
- `vehicle_costs` - ✅ RLS mit owner-policies
- `threads` - ✅ RLS mit read-all, write-owner
- `posts` - ✅ RLS mit read-all, write-owner
- `private_messages` - ✅ RLS mit participants-only
- `notifications` - ✅ RLS mit owner-policies
- `credit_events` - ✅ RLS mit owner-policies
- `storage.objects` - ✅ RLS mit bucket-policies

## 📞 Bei Sicherheitsproblemen

1. **API Key kompromittiert?**
   - Supabase Dashboard → Settings → API → Regenerate Keys
   - RevenueCat Dashboard → API Keys → Regenerate
   - Alle Apps mit neuen Keys neu deployen

2. **Verdächtige Aktivität?**
   - Supabase Dashboard → Logs überprüfen
   - RLS Policies überprüfen
   - User-Zugriffe analysieren

3. **Daten-Leak verhindern:**
   ```sql
   -- Teste RLS Policies:
   SELECT * FROM maintenance_reminders; -- Sollte nur eigene Daten zeigen
   ```

## 🛡️ Best Practices

1. **Regelmäßige Security Audits**
   - Monatlich RLS Policies überprüfen
   - Supabase Security Advisor nutzen
   - Logs auf verdächtige Aktivitäten prüfen

2. **Code Reviews**
   - Vor jedem Merge: Security Review
   - Keine hardcodierten Secrets
   - Alle User-Inputs validieren

3. **Updates**
   - Supabase Client regelmäßig updaten
   - Flutter & Dependencies aktuell halten
   - Security Patches sofort einspielen
