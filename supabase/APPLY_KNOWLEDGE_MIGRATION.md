# 🚀 Automotive Knowledge System - Migration Anleitung

Diese Anleitung führt dich durch die Installation der KI-Wissensdatenbank.

---

## ✅ **Was wird installiert?**

1. **pgvector Extension** - Für Vector Embeddings
2. **automotive_knowledge** Tabelle - Multi-Language Wissensdatenbank
3. **error_codes** Tabelle - OBD2 & Hersteller-Fehlercodes
4. **knowledge_harvest_queue** Tabelle - Automatisches Web-Crawling
5. **Helper Functions** - Vector Similarity Search
6. **Indizes** - Schnelle Suche & Vector Search
7. **Initial Data** - 11 Test-Themen zum Starten

---

## 📋 **Schritt-für-Schritt Anleitung**

### **Option 1: Supabase Dashboard (Empfohlen)**

1. **Öffne Supabase Dashboard**
   - Gehe zu: https://supabase.com/dashboard
   - Wähle dein Projekt "WeFixIt"

2. **SQL Editor öffnen**
   - Linke Sidebar → **SQL Editor**
   - Klicke auf **New query**

3. **Migration-Code einfügen**
   - Öffne die Datei: `supabase/migrations/20241209_automotive_knowledge_system.sql`
   - Kopiere den KOMPLETTEN Inhalt
   - Füge ihn in den SQL Editor ein

4. **Migration ausführen**
   - Klicke unten rechts auf **Run** (oder Strg+Enter)
   - Warte ~10-15 Sekunden
   - Erfolgs-Meldung sollte erscheinen! ✅

---

### **Option 2: Supabase CLI (Fortgeschritten)**

```bash
# Im Projekt-Root-Verzeichnis:
cd C:\Users\Senkbeil\AndroidStudioProjects\wefixit

# Migration anwenden:
supabase db push

# Oder direkt ausführen:
supabase db execute -f supabase/migrations/20241209_automotive_knowledge_system.sql
```

---

## ✅ **Überprüfung: Hat es funktioniert?**

### **Test 1: Tabellen prüfen**

Führe im SQL Editor aus:

```sql
-- Zeige alle neuen Tabellen
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('automotive_knowledge', 'error_codes', 'knowledge_harvest_queue');
```

**Erwartetes Ergebnis:** 3 Tabellen sollten angezeigt werden

---

### **Test 2: pgvector Extension prüfen**

```sql
-- Zeige installierte Extensions
SELECT * FROM pg_extension WHERE extname = 'vector';
```

**Erwartetes Ergebnis:** 1 Zeile mit `vector` Extension

---

### **Test 3: Indizes prüfen**

```sql
-- Zeige Vector-Indizes
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'automotive_knowledge' 
  AND indexname LIKE '%embedding%';
```

**Erwartetes Ergebnis:** 4 Indizes (de, en, fr, es)

---

### **Test 4: Initial Data prüfen**

```sql
-- Zeige Warteschlange
SELECT topic, search_language, category, priority
FROM knowledge_harvest_queue
ORDER BY priority DESC;
```

**Erwartetes Ergebnis:** 11 Einträge (OBD2-Codes, Diagnosen, Reparaturen)

---

### **Test 5: Helper Functions prüfen**

```sql
-- Zeige Funktionen
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE 'match_documents%';
```

**Erwartetes Ergebnis:** 2 Funktionen (match_documents_de, match_documents_en)

---

## 🎯 **Nächste Schritte**

Nach erfolgreicher Migration:

1. ✅ **Edge Functions erstellen**
   - `auto_knowledge_harvester` (Web-Crawling)
   - `chat_completion` (Ask Toni! mit RAG)

2. ✅ **Harvesting starten**
   - 100 Test-Artikel sammeln
   - Übersetzen in 4 Sprachen
   - Embeddings erzeugen

3. ✅ **App-Integration**
   - ChatbotScreen → API Call
   - DiagnoseScreen → Fehlercode-Analyse

---

## 🐛 **Troubleshooting**

### **Fehler: "extension vector does not exist"**

**Lösung:**
```sql
-- pgvector manuell installieren:
CREATE EXTENSION IF NOT EXISTS vector;
```

Wenn das nicht funktioniert:
- Kontaktiere Supabase Support
- pgvector ist in allen neueren Supabase-Projekten verfügbar

---

### **Fehler: "permission denied for schema public"**

**Lösung:**
- Du musst als **Admin** oder mit **Service Role Key** angemeldet sein
- Im Dashboard solltest du automatisch Admin sein

---

### **Fehler: "index method ivfflat does not exist"**

**Lösung:**
```sql
-- pgvector neu laden:
DROP EXTENSION IF EXISTS vector CASCADE;
CREATE EXTENSION vector;
```

---

## 📊 **Datenbank-Struktur Überblick**

```
automotive_knowledge (Multi-Language Wissensdatenbank)
├─ id, topic, category, subcategory
├─ title_de, title_en, title_fr, title_es
├─ content_de, content_en, content_fr, content_es
├─ symptoms[], causes[], diagnostic_steps[], repair_steps[]
├─ embedding_de, embedding_en, embedding_fr, embedding_es
└─ quality_score, view_count, helpful_count

error_codes (OBD2 & Hersteller-Codes)
├─ code, code_type, is_generic, manufacturer[]
├─ description_de, description_en, description_fr, description_es
├─ symptoms[], common_causes[], diagnostic_steps[]
└─ severity, drive_safety, related_codes[]

knowledge_harvest_queue (Crawling-Warteschlange)
├─ topic, search_language, category, priority
└─ status, attempts, error_message
```

---

## 📞 **Support**

Bei Problemen:
1. Prüfe die Tests oben
2. Checke Supabase Dashboard → Logs
3. Stelle sicher, dass du Admin-Rechte hast

---

**Status:** ⏳ Bereit zur Ausführung
**Dauer:** ~10-15 Sekunden
**Risiko:** Niedrig (nur neue Tabellen, keine bestehenden Änderungen)
