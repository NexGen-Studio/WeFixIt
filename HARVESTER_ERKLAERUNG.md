# 🤖 Auto-Knowledge-Harvester - Erklärt für Anfänger

## 📚 WAS MACHT DER HARVESTER?

Der Harvester ist ein automatischer Bot, der:
1. **Web-Suche durchführt** (via Perplexity AI)
2. **Content extrahiert** und strukturiert
3. **In 4 Sprachen übersetzt** (DE, EN, FR, ES)
4. **Embeddings erstellt** für Vektor-Suche
5. **In Datenbank speichert** (automotive_knowledge)

---

## 🔄 WIE FUNKTIONIERT ES? (Schritt-für-Schritt)

### **1. QUEUE (Warteschlange)**
```
Topic: "P2327 OBD2 diagnostic trouble code"
Status: PENDING 📋
Priority: 77
```
→ **Warten auf Verarbeitung**

### **2. HARVESTER STARTET**
```
Status: PROCESSING ⚙️
Attempt: 1 / 3
```
→ **Wird bearbeitet**

#### Was passiert:
- **Perplexity API**: Web-Recherche durchführen
- **OpenAI GPT-4**: Content strukturieren
- **OpenAI Embedding**: Vektor erstellen
- **Supabase**: In DB speichern

### **3a. ERFOLG ✅**
```
Status: COMPLETED ✅
Gespeichert in: automotive_knowledge
```
→ **Fertig! Kann in Ask Toni verwendet werden**

### **3b. FEHLER ❌**
```
Fehler: 502 Bad Gateway
Status: PROCESSING ⚙️  ← BLEIBT HÄNGEN!
```
→ **PROBLEM: Wird nicht automatisch aufgeräumt!**

---

## ❌ DEINE FEHLER & WAS SIE BEDEUTEN

### **546 - Rate Limit**
```
❌ Zu viele Anfragen!
```
**Ursache:** Perplexity/OpenAI API-Limit erreicht  
**Lösung:** 30+ Sekunden warten zwischen Calls

### **502 Bad Gateway**
```
❌ Server antwortet nicht!
```
**Ursache:** Perplexity API überlastet/Timeout  
**Lösung:** Retry nach 30 Sekunden

### **504 Gateway Timeout**
```
❌ Anfrage zu lange!
```
**Ursache:** Komplexer Content, dauert >30 Sek  
**Lösung:** Retry mit kürzerem Prompt

---

## 🐛 DAS HAUPTPROBLEM

### **Items "hängen" in PROCESSING**

#### Warum?

```typescript
// 1. Status wird gesetzt
status = "processing"

// 2. API-Call schlägt fehl
throw new Error("502 Bad Gateway")

// 3. Code crasht BEVOR Status geändert werden kann!
// Item bleibt in "processing" hängen! 🐛
```

#### Resultat (aus deinen Logs):
- ✅ **57 completed** (erfolgreich)
- ⚠️ **44 processing** (HÄNGEN!)
- 📋 **49 pending** (warten)
- ❌ **1 failed** (nur 1 statt 44!)

---

## 🔧 DIE LÖSUNG

### **1. CLEANUP-SKRIPT**

Ich habe `cleanup_stuck_items.ps1` erstellt:

```powershell
.\cleanup_stuck_items.ps1
```

#### Was macht es?

```
1. Sucht Items in "processing" älter als 10 Min
2. Prüft Retry-Counter:
   
   attempts < 3:
   └─→ Zurück auf "pending" ♻️
       (Wird nochmal versucht)
   
   attempts >= 3:
   └─→ Nach "failed_topics" ❌
       (Endgültig fehlgeschlagen)
```

#### Beispiel-Output:
```
🔍 Suche hängende Items...
📊 Gefunden: 44 hängende Items

Topic: P2327 OBD2 diagnostic trouble code
Attempts: 2 / 3
♻️  Retry möglich → pending

Topic: P2345 OBD2 diagnostic trouble code
Attempts: 3 / 3
❌ Max Retries erreicht → failed_topics

============================================
✅ CLEANUP ABGESCHLOSSEN
============================================
♻️  Zurückgesetzt (pending): 28
❌ Nach failed_topics verschoben: 16
```

---

### **2. HARVESTER VERBESSERT**

#### Besseres Error-Logging:
```typescript
console.log('📋 Starting: P2327...')
console.log('⚙️ Processing...')
console.log('✅ Successfully harvested!')
// ODER
console.log('❌ Max retries erreicht')
console.log('✅ Saved to failed_topics')
```

#### Robustere Fehlerbehandlung:
```typescript
let currentItem = null;  // Globale Variable

try {
  currentItem = queueItems[0];
  // ... Verarbeitung ...
} catch (error) {
  // currentItem ist noch verfügbar!
  if (currentItem.attempts >= 3) {
    saveToFailedTopics(currentItem);
  }
}
```

---

## 📊 DEINE TABELLEN ERKLÄRT

### **1. knowledge_harvest_queue** (Job-Queue)
```sql
SELECT 
  topic,              -- "P2327 OBD2 code"
  status,             -- pending/processing/completed/failed
  attempts,           -- 0-3 Versuche
  priority,           -- 77 = hoch
  error_message       -- "502 Bad Gateway"
FROM knowledge_harvest_queue;
```
**Zweck:** Job-Management & Status-Tracking

### **2. automotive_knowledge** (Vektor-DB)
```sql
SELECT 
  title_de,           -- "P2327: Zündsystem"
  content_de,         -- Langer Text...
  embedding_de,       -- [0.123, 0.456, ...]
  keywords            -- ["OBD2", "Zündung"]
FROM automotive_knowledge;
```
**Zweck:** Finale Wissensbasis für Ask Toni

### **3. failed_topics** (Fehler-Log)
```sql
SELECT 
  topic,              -- "P2327 OBD2 code"
  error_code,         -- "502"
  error_message,      -- "Bad Gateway"
  retry_count,        -- 3
  status              -- "failed"
FROM failed_topics;
```
**Zweck:** Tracking von dauerhaft fehlgeschlagenen Items

---

## 🚀 WIE NUTZE ICH ES?

### **SCHRITT 1: Cleanup durchführen**
```powershell
cd C:\Users\Senkbeil\AndroidStudioProjects\wefixit
.\cleanup_stuck_items.ps1
```

### **SCHRITT 2: Harvester normal starten**
```powershell
.\run_harvester.ps1
```

### **SCHRITT 3: Fehler prüfen**
```sql
-- In Supabase Dashboard
SELECT * FROM failed_topics 
ORDER BY created_at DESC 
LIMIT 10;
```

### **SCHRITT 4: Bei zu vielen Fehlern**
```powershell
# Wartezeit zwischen Calls erhöhen
# In run_harvester.ps1:
Start-Sleep -Seconds 60  # Statt 30
```

---

## 💡 BEST PRACTICES

### ✅ **DO:**
- Cleanup-Skript **täglich** laufen lassen
- Wartezeit **60 Sek** bei Rate-Limits
- failed_topics **regelmäßig prüfen**
- Harvester **nachts** laufen lassen (weniger Last)

### ❌ **DON'T:**
- Harvester **zu schnell** aufrufen (<30 Sek)
- **Zu viele parallele Calls**
- Hängende Items **ignorieren**
- failed_topics **nicht prüfen**

---

## 🔍 MONITORING

### **Dashboard-Queries:**

```sql
-- Status-Übersicht
SELECT status, COUNT(*) 
FROM knowledge_harvest_queue 
GROUP BY status;

-- Fehlgeschlagene Items
SELECT topic, error_code, retry_count 
FROM failed_topics 
ORDER BY created_at DESC 
LIMIT 20;

-- Hängende Items finden
SELECT topic, attempts, last_attempt_at
FROM knowledge_harvest_queue
WHERE status = 'processing'
  AND last_attempt_at < NOW() - INTERVAL '10 minutes';
```

---

## 🆘 TROUBLESHOOTING

### **Problem: Zu viele 546-Fehler**
```powershell
# Lösung: Mehr Wartezeit
.\run_harvester.ps1 -WaitSeconds 90
```

### **Problem: Alle Items hängen**
```powershell
# Lösung: Cleanup + Harvester neu starten
.\cleanup_stuck_items.ps1
.\run_harvester.ps1
```

### **Problem: failed_topics wächst stark**
```sql
-- Prüfe häufigste Fehler
SELECT error_code, COUNT(*) 
FROM failed_topics 
GROUP BY error_code;

-- 546 = Rate Limit → Langsamer machen
-- 502/504 = Timeout → OK, Retry hilft
```

---

## 📞 SUPPORT

Bei Problemen:
1. Cleanup-Skript laufen lassen
2. Logs prüfen (Supabase Dashboard)
3. failed_topics analysieren
4. Wartezeit erhöhen wenn nötig

**Alles klar? 😊**
