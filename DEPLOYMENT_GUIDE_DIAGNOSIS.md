# 🚀 Deployment-Guide: Error Code Enrichment Feature

## ✅ Was wurde implementiert?

### **1. Backend (Supabase Edge Functions)**

#### **cleanup-and-translate-titles**
📁 `supabase/functions/cleanup-and-translate-titles/index.ts`
- Kürzt lange Titel (entfernt "P0420 OBD2-Fehlercode:" etc.)
- Übersetzt Titel in DE/EN/FR/ES
- Batch-Processing (50 Titel pro Call)

#### **fill-repair-guides**
📁 `supabase/functions/fill-repair-guides/index.ts`
- Generiert fehlende `repair_guides` für bestehende Einträge
- Mehrsprachig (DE/EN/FR/ES)
- Detaillierte Schritt-für-Schritt Anleitungen

#### **enrich-error-code (erweitert)**
📁 `supabase/functions/enrich-error-code/index.ts`
- ✅ **Fahrzeugdaten-Support**: Sendet Make/Model/Year/Engine an Perplexity
- ✅ **vehicle_specific Cache**: Erweitert JSONB bei neuen Fahrzeugen
- ✅ **4 Sprachen**: repair_guides in DE/EN/FR/ES
- ✅ **Smart Caching**: 1 Zeile pro Code, vehicle_specific wächst organisch

### **2. Flutter App**

#### **ErrorCodeDescriptionService (erweitert)**
📁 `lib/src/services/error_code_description_service.dart`
- Lädt Fahrzeugdaten aus Profil
- Prüft `share_vehicle_data_with_ai` Flag
- Sendet an Phase 1 + Phase 2

#### **RepairGuideDetailScreen (NEU)**
📁 `lib/src/features/diagnose/repair_guide_detail_screen.dart`
- Vollbild Schritt-für-Schritt Anleitung
- Checkboxen für erledigte Schritte
- Fortschrittsanzeige
- "Problem behoben?" Button am Ende
- Mehrsprachig (DE/EN/FR/ES)

#### **AiDiagnosisDetailScreen (erweitert)**
📁 `lib/src/features/diagnose/ai_diagnosis_detail_screen.dart`
- Ursachen-Liste jetzt klickbar
- Bottom Sheet mit Preview
- "Zur Anleitung" Button → RepairGuideDetailScreen

### **3. Datenbank**

#### **Migration: repair_guides**
📁 `supabase/migrations/20250115000002_add_repair_guides.sql`
- JSONB Spalte für mehrsprachige Reparaturanleitungen

#### **Migration: error_code_feedback**
📁 `supabase/migrations/20250215000001_error_code_feedback.sql`
- User-Feedback Tabelle
- "Problem behoben?" Tracking
- RLS Policies

---

## 📋 Deployment-Schritte

### **1. Datenbank-Migrationen anwenden**

```bash
cd c:\Users\Senkbeil\AndroidStudioProjects\wefixit

# Via Supabase Dashboard (empfohlen):
# 1. Öffne: https://supabase.com/dashboard/project/zbrlhswafnlpfwqikapu/sql/new
# 2. Kopiere Inhalt von: supabase/migrations/20250215000001_error_code_feedback.sql
# 3. Führe aus
```

### **2. Edge Functions deployen**

```bash
# 1. Cleanup Titles Function
supabase functions deploy cleanup-and-translate-titles

# 2. Fill Repair Guides Function
supabase functions deploy fill-repair-guides

# 3. Enrich Error Code Function (erweitert)
supabase functions deploy enrich-error-code
```

### **3. Environment Variables setzen**

Stelle sicher, dass folgende Secrets in Supabase gesetzt sind:

```bash
# Via Supabase Dashboard → Settings → Edge Functions → Secrets
OPENAI_API_KEY=sk-...
PERPLEXITY_API_KEY=pplx-...
```

---

## 🧪 Testing

### **1. Demo-Modus testen**

```dart
// In App:
// 1. Navigiere zu "Diagnose" → "Demo starten"
// 2. Wähle einen Fehlercode (z.B. P0420)
// 3. Klicke auf eine Ursache
// 4. Bottom Sheet sollte erscheinen
// 5. Klicke "Zur Anleitung"
// 6. Schritt-für-Schritt Anleitung wird geladen
```

### **2. Produktions-Test (mit echten Daten)**

```bash
# 1. Stelle sicher, dass Fahrzeugdaten im Profil vorhanden sind
# 2. Aktiviere "Fahrzeugdaten für KI-Diagnose freigeben"
# 3. Starte OBD2-Diagnose
# 4. Prüfe Console-Logs: "🚗 Fahrzeugdaten gefunden: ..."
```

### **3. Edge Function manuell testen**

```bash
# Cleanup Titles (Dry Run)
curl -X POST https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/cleanup-and-translate-titles \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"dry_run": true, "batch_size": 5}'

# Fill Repair Guides (Dry Run)
curl -X POST https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/fill-repair-guides \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"dry_run": true, "batch_size": 2}'
```

---

## 🔄 Backfill bestehender Daten (optional)

### **Schritt 1: Titel kürzen + übersetzen**

```bash
# Dry Run (zeigt Preview)
curl -X POST https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/cleanup-and-translate-titles \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"dry_run": true, "batch_size": 10}'

# Echter Run
curl -X POST https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/cleanup-and-translate-titles \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"dry_run": false, "batch_size": 50}'
```

### **Schritt 2: Repair Guides generieren**

```bash
# Dry Run
curl -X POST https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/fill-repair-guides \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"dry_run": true, "batch_size": 5}'

# Echter Run (langsam, GPT-intensiv!)
curl -X POST https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/fill-repair-guides \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"dry_run": false, "batch_size": 10}'
```

**⚠️ Kosten-Warnung:**
- GPT-4o-mini: ~$0.15 pro 1M Input-Tokens
- Pro Fehlercode: ~20k Tokens (Übersetzungen)
- 10 Codes ≈ $0.03
- 100 Codes ≈ $0.30

---

## 📊 User-Flow

```
1. User scannt OBD2-Code (z.B. P0402)
   ↓
2. Phase 1: Schnelle GPT-Antwort (2-3 Sek)
   → User sieht sofort Basis-Infos
   ↓
3. Phase 2: Background Enrichment
   → Perplexity Web-Search
   → GPT generiert repair_guides (DE/EN/FR/ES)
   → Fahrzeugdaten werden integriert (falls freigegeben)
   → vehicle_specific JSONB wird erweitert
   ↓
4. User klickt auf Ursache
   → Bottom Sheet zeigt Preview
   ↓
5. "Zur Anleitung" Button
   → RepairGuideDetailScreen
   → Schritt-für-Schritt mit Checkboxen
   ↓
6. Alle Schritte erledigt?
   → "Problem behoben?" Button
   → Feedback in DB gespeichert
```

---

## 🎯 Architektur: vehicle_specific Cache

### **Datenbank-Struktur:**

```sql
SELECT * FROM automotive_knowledge WHERE topic LIKE 'P0402%';

┌────┬─────────────────────────┬──────────────────┬─────────────────────────┐
│ id │ topic                   │ title_de         │ vehicle_specific        │
├────┼─────────────────────────┼──────────────────┼─────────────────────────┤
│ 42 │ P0402 OBD2 diagnostic.. │ AGR-Ventil       │ {                       │
│    │                         │ Fehlfunktion     │   "mercedes_w201": {    │
│    │                         │                  │     "common_causes":[...],
│    │                         │                  │     "typical_mileage_km":"120k-180k"
│    │                         │                  │   },                    │
│    │                         │                  │   "bmw_e46_320d": {    │
│    │                         │                  │     "common_causes":[...],
│    │                         │                  │   }                     │
│    │                         │                  │ }                       │
└────┴─────────────────────────┴──────────────────┴─────────────────────────┘
```

### **Was passiert:**

```
User 1 (Mercedes W201) liest P0402 aus:
  → DB-Zeile existiert bereits
  → vehicle_specific.mercedes_w201 existiert NICHT
  → Perplexity + GPT generieren Daten
  → UPDATE: vehicle_specific = { ...existing, "mercedes_w201": {...} }
  ✅ Keine neue Zeile erstellt!

User 2 (BMW E46) liest P0402 aus:
  → Selbe DB-Zeile
  → vehicle_specific.bmw_e46 existiert NICHT
  → Perplexity + GPT generieren Daten
  → UPDATE: vehicle_specific = { ...existing, "mercedes_w201": {...}, "bmw_e46": {...} }
  ✅ Keine neue Zeile erstellt!

User 3 (Mercedes W201) liest P0402 aus:
  → Selbe DB-Zeile
  → vehicle_specific.mercedes_w201 existiert BEREITS ✅
  → Cache-Hit! Keine API-Calls
  ✅ Keine neue Zeile erstellt!
```

---

## 🐛 Troubleshooting

### **1. "Keine Reparaturanleitung verfügbar"**
- Prüfe: Ist `repair_guides` JSONB in DB vorhanden?
- Lösung: Migration `20250115000002_add_repair_guides.sql` anwenden

### **2. "Fahrzeugdaten nicht gefunden"**
- Prüfe: Hat User Fahrzeug im Profil hinterlegt?
- Prüfe: Ist `share_vehicle_data_with_ai = true`?
- Lösung: In Profil Fahrzeugdaten eingeben + Checkbox aktivieren

### **3. Edge Function Timeout**
- Perplexity kann 20-30 Sekunden dauern
- Lösung: Ist normal, User bekommt Phase 1 Response sofort

### **4. "Problem behoben?" Button disabled**
- User muss erst alle Schritte abhaken
- Sonst bleibt Button grau

---

## 📈 Monitoring

### **Console Logs beachten:**

```
🚀 Phase 1: Schnelle GPT-Antwort für P0402
🚗 Fahrzeugdaten gefunden: Mercedes W201
✅ Phase 2: Background Enrichment für P0402 gestartet
🔍 Generating vehicle-specific data for mercedes_w201
✅ Vehicle-specific data added for mercedes_w201
```

### **Supabase Logs:**

```bash
# Edge Function Logs
https://supabase.com/dashboard/project/zbrlhswafnlpfwqikapu/logs/edge-functions

# Datenbank Performance
https://supabase.com/dashboard/project/zbrlhswafnlpfwqikapu/reports/database
```

---

## ✅ Checkliste vor Go-Live

- [ ] Migrationen angewendet (`repair_guides`, `error_code_feedback`)
- [ ] Edge Functions deployed (3 Funktionen)
- [ ] Environment Variables gesetzt (OpenAI, Perplexity)
- [ ] Demo-Modus getestet
- [ ] Produktions-Test mit echtem OBD2-Code
- [ ] Backfill-Skript für bestehende Codes ausgeführt (optional)
- [ ] Fahrzeugdaten-Freigabe im Profil getestet
- [ ] User-Feedback Flow getestet
- [ ] Console Logs geprüft

---

## 🎉 Fertig!

Die komplette Error Code Enrichment Feature ist nun einsatzbereit:
- ✅ 2-Phasen AI-Diagnose
- ✅ Fahrzeugspezifische Empfehlungen
- ✅ Mehrsprachige Reparaturanleitungen (DE/EN/FR/ES)
- ✅ Schritt-für-Schritt UI mit Fortschritt
- ✅ User-Feedback System
- ✅ Intelligentes Caching (vehicle_specific)

**Viel Erfolg! 🚀**
