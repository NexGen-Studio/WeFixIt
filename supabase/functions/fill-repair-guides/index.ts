// ============================================================================
// Fill Repair Guides - Nachträgliche Generierung für bestehende Einträge
// ============================================================================
// Aufgabe:
// 1. Findet alle automotive_knowledge Einträge mit leeren repair_guides
// 2. Generiert detaillierte Schritt-für-Schritt Anleitungen (4 Sprachen)
// 3. Batch-Processing für Effizienz
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

Deno.serve(async (req) => {
  try {
    const { 
      batch_size = 1, 
      dry_run = false, 
      entry_id = null,
      generate_single = false,
      error_code = null,
      cause_title = null,
      cause_key = null,
      error_codes = null,
      trigger_source = null
    } = await req.json().catch(() => ({}));
    
    // Fallback: Flutter App will EINE Ursache generieren
    if (generate_single && error_code && cause_title && cause_key) {
      return await generateSingleCauseGuide(error_code, cause_title, cause_key);
    }
    
    // Direkt von enrich-error-code getriggert mit spezifischen Codes
    if (error_codes && Array.isArray(error_codes)) {
      console.log(`🔧 Triggered by ${trigger_source || 'external'} for codes: ${error_codes.join(', ')}`);
      return await processSpecificCodes(error_codes);
    }
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    console.log('🔍 Searching for entries without repair guides...');
    
    // 1. Hole Einträge mit leeren repair_guides_de (neue Spaltenstruktur!)
    // Lade nur batch_size * 3 Einträge, um Memory/Timeout zu vermeiden
    const fetchLimit = entry_id ? 1 : Math.min(batch_size * 3, 50);
    
    const { data: allEntries, error: fetchError1 } = await supabase
      .from('automotive_knowledge')
      .select('id, topic, causes, repair_steps, repair_guides_de')
      .eq('category', 'fehlercode')
      .limit(fetchLimit);
    
    if (fetchError1) throw fetchError1;
    
    console.log(`📊 Loaded ${allEntries?.length || 0} entries from DB`);
    
    // Filter: repair_guides_de IS NULL oder leer
    const emptyEntries = (allEntries || []).filter(e => 
      !e.repair_guides_de || Object.keys(e.repair_guides_de).length === 0
    );
    
    console.log(`📊 Found ${emptyEntries.length} entries with empty repair_guides`);
    
    // Falls spezifische ID angegeben
    let entries = emptyEntries;
    if (entry_id) {
      entries = emptyEntries.filter(e => e.id === entry_id);
    } else {
      entries = emptyEntries.slice(0, batch_size);
    }
    
    console.log(`📊 Processing ${entries.length} entries`);
    
    const fetchError = null;
    
    if (fetchError) throw fetchError;
    
    if (!entries || entries.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: 'No entries need repair guides',
        processed: 0
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    console.log(`📋 Found ${entries.length} entries to process`);
    
    // 2. Generiere repair_guides für jeden Eintrag (PRO URSACHE EINZELN!)
    const updates = [];
    
    for (const entry of entries) {
      const code = extractCodeFromTopic(entry.topic);
      const causes = entry.causes || [];
      
      console.log(`🔧 Processing ${code} with ${causes.length} causes...`);
      
      // Bestehende repair_guides_de/en laden (falls vorhanden)
      const existingGuidesDe = entry.repair_guides_de || {};
      const existingGuidesEn = entry.repair_guides_en || {};
      const newGuidesDe: Record<string, any> = { ...existingGuidesDe };
      const newGuidesEn: Record<string, any> = { ...existingGuidesEn };
      
      // Iteriere durch ALLE Ursachen
      for (let i = 0; i < causes.length; i++) {
        const causeTitle = causes[i];
        const causeKey = causeTitle.toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .replace(/^_|_$/g, '');
        
        // Skip wenn bereits vorhanden (DE UND EN)
        if (existingGuidesDe[causeKey] && existingGuidesEn[causeKey]) {
          console.log(`⏭️  Skipping ${code} cause ${i + 1}/${causes.length}: Already exists (DE+EN)`);
          continue;
        }
        
        try {
          console.log(`📝 Generating guide for ${code} cause ${i + 1}/${causes.length}: ${causeTitle.substring(0, 50)}...`);
          
          // Generiere Anleitung für DIESE EINE Ursache (DE)
          const guideDe = await generateSingleCauseRepairGuide(code, causeTitle);
          
          if (guideDe) {
            newGuidesDe[causeKey] = guideDe;
            console.log(`✅ Generated DE guide for ${code} cause ${i + 1} (${guideDe.steps?.length || 0} steps)`);
            
            // Übersetze zu EN
            const guideEn = await translateSingleGuide(guideDe);
            if (guideEn) {
              newGuidesEn[causeKey] = guideEn;
              console.log(`✅ Translated to EN for ${code} cause ${i + 1}`);
            }
          }
          
        } catch (error) {
          console.error(`❌ Failed to generate guide for ${code} cause ${i + 1}:`, error);
        }
      }
      
      // Speichere alle generierten Guides für diesen Code
      if (Object.keys(newGuidesDe).length > Object.keys(existingGuidesDe).length) {
        updates.push({
          id: entry.id,
          code,
          repair_guides_de: newGuidesDe,
          repair_guides_en: newGuidesEn
        });
        console.log(`✅ Completed ${code}: ${Object.keys(newGuidesDe).length}/${causes.length} causes have guides (DE+EN)`);
      }
    }
    
    // 3. Update Datenbank
    if (!dry_run && updates.length > 0) {
      let successCount = 0;
      
      for (const update of updates) {
        const { error: updateError } = await supabase
          .from('automotive_knowledge')
          .update({ 
            repair_guides_de: update.repair_guides_de,
            repair_guides_en: update.repair_guides_en
          })
          .eq('id', update.id);
        
        if (updateError) {
          console.error(`❌ Failed to update ${update.code}:`, updateError);
        } else {
          successCount++;
        }
      }
      
      console.log(`💾 Updated ${successCount}/${updates.length} entries`);
      
      return new Response(JSON.stringify({
        success: true,
        processed: successCount,
        total: updates.length
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Dry run
    return new Response(JSON.stringify({
      success: true,
      dry_run: true,
      would_update: updates.length,
      samples: updates.slice(0, 2).map(u => ({
        code: u.code,
        repair_guides_keys_de: Object.keys(u.repair_guides_de || {}),
        total_causes_with_guides: Object.keys(u.repair_guides_de || {}).length
      }))
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    });
  }
});

function extractCodeFromTopic(topic: string): string {
  const match = topic.match(/^([A-Z][0-9]{4})/);
  return match ? match[1] : topic;
}

/**
 * Generiert SEHR DETAILLIERTE Reparaturanleitungen in EINER Sprache (10-20 Steps!)
 * Fokus: MAXIMALE QUALITÄT statt Geschwindigkeit
 */
async function generateDetailedRepairGuides(code: string, causes: string[], lang: string): Promise<any> {
  const langNames: any = {
    de: 'Deutsch',
    en: 'English',
    fr: 'Français',
    es: 'Español'
  };
  
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{
        role: 'system',
        content: `Du bist ein erfahrener KFZ-Meister mit 30 Jahren Erfahrung. Du erstellst EXTREM DETAILLIERTE Schritt-für-Schritt Reparaturanleitungen für absolute Anfänger ohne jegliche Vorkenntnisse - als würdest du es einem 10-jährigen Kind erklären.`
      }, {
        role: 'user',
        content: `Erstelle eine SEHR DETAILLIERTE Reparaturanleitung für Fehlercode ${code} in ${langNames[lang]}.

Ursachen: ${JSON.stringify(causes)}

Für JEDE Ursache erstelle eine EXTREM AUSFÜHRLICHE Anleitung mit 10-20 Schritten.

WICHTIGE ANFORDERUNGEN:
- JEDER Schritt muss kinderleicht verständlich sein
- Erkläre JEDEN Handgriff als würdest du es einem Laien zeigen
- Verwende einfache, alltägliche Sprache (keine Fachbegriffe ohne Erklärung)
- Beschreibe genau WO etwas ist und WIE man es findet
- SICHERHEIT hat oberste Priorität - warne vor allen Gefahren
- Mindestens 10, besser 15-20 Schritte pro Ursache
- Letzter Schritt: IMMER OBD2-Scanner anschließen zur Verifikation

JSON-Format:
{
  "ursache_schluessel": {
    "cause_title": "Klarer, verständlicher Titel der Ursache",
    "difficulty_level": "easy|medium|hard",
    "estimated_time_hours": 2.5,
    "estimated_cost_eur": [200, 500],
    "for_beginners": true,
    "steps": [
      {
        "step": 1,
        "title": "Kurzer Schritt-Titel",
        "description": "SEHR AUSFÜHRLICHE Beschreibung (3-5 Sätze). Erkläre genau WAS zu tun ist, WO es ist, WIE man es macht, WARUM es wichtig ist. Als würdest du es einem Kind erklären.",
        "duration_minutes": 15,
        "safety_warning": "Konkreter Sicherheitshinweis falls relevant",
        "tools": ["Liste der für DIESEN Schritt benötigten Werkzeuge"],
        "tips": "Hilfreiche Tipps und Tricks für diesen Schritt"
      }
    ],
    "tools_required": ["Komplette Liste aller benötigten Werkzeuge mit Details"],
    "safety_warnings": ["Alle Sicherheitshinweise für die gesamte Reparatur"],
    "when_to_call_mechanic": ["Klare Anzeichen wann besser zur Werkstatt"]
  }
}

BEISPIEL für kinderleichte Beschreibung:
❌ SCHLECHT: "Sensor ausbauen"
✅ GUT: "Schaue unter der Motorhaube auf der Fahrerseite. Dort siehst du einen schwarzen, etwa daumengroßen Sensor mit einem Kabel dran. Folge dem Kabel bis zum Stecker. Drücke die kleine Plastiklasche am Stecker und ziehe vorsichtig - der Stecker löst sich. Jetzt siehst du eine Schraube am Sensor..."

NUR JSON ausgeben - keine zusätzlichen Texte!`
      }],
      temperature: 0.3,
      max_tokens: 8000, // Viele Tokens für SEHR detaillierte Anleitungen
      response_format: { type: "json_object" }
    })
  });
  
  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status}`);
  }
  
  const data = await response.json();
  const content = data.choices[0].message.content;
  
  if (!content || content.length === 0) {
    throw new Error('GPT returned empty response');
  }
  
  try {
    const parsed = JSON.parse(content);
    console.log(`📊 Generated ${Object.keys(parsed).length} causes with avg ${Object.values(parsed).map((c: any) => c.steps?.length || 0).reduce((a: number, b: number) => a + b, 0) / Object.keys(parsed).length} steps`);
    return parsed;
  } catch (parseError) {
    console.error('❌ JSON Parse Error:', parseError);
    console.error('Response length:', content?.length);
    throw parseError;
  }
}

/**
 * Übersetzt bestehende deutsche Reparaturanleitungen in andere Sprachen
 * Behält die Struktur und Detailtiefe EXAKT bei
 */
async function translateRepairGuides(guidesDe: any, targetLang: string): Promise<any> {
  const langNames: any = {
    en: 'English',
    fr: 'Français',
    es: 'Español'
  };
  
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{
        role: 'system',
        content: `Du bist ein professioneller Übersetzer für technische KFZ-Anleitungen. Du übersetzt EXTREM GENAU und behältst die Detailtiefe und Verständlichkeit bei.`
      }, {
        role: 'user',
        content: `Übersetze diese deutschen Reparaturanleitungen nach ${langNames[targetLang]}.

WICHTIG:
- Behalte die JSON-Struktur EXAKT bei
- Übersetze ALLE Texte (Titel, Beschreibungen, Tipps, Warnungen, etc.)
- Behalte die kinderleichte, ausführliche Sprache bei
- Verwende alltagsnahe Begriffe (keine Fachsprache)
- Behalte die Länge und Detailtiefe der Beschreibungen bei

Deutsche Anleitungen:
${JSON.stringify(guidesDe, null, 2)}

Antworte mit der EXAKT gleichen JSON-Struktur, aber alle Texte in ${langNames[targetLang]}.
NUR JSON ausgeben!`
      }],
      temperature: 0.3,
      max_tokens: 8000,
      response_format: { type: "json_object" }
    })
  });
  
  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status}`);
  }
  
  const data = await response.json();
  const content = data.choices[0].message.content;
  
  if (!content || content.length === 0) {
    throw new Error('GPT returned empty response');
  }
  
  return JSON.parse(content);
}

/**
 * Generiert eine Reparaturanleitung für EINE EINZELNE Ursache
 */
async function generateSingleCauseRepairGuide(code: string, causeTitle: string): Promise<any> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{
        role: 'system',
        content: `Du bist ein erfahrener KFZ-Meister. Erstelle EXTREM DETAILLIERTE Schritt-für-Schritt Anleitungen für absolute Anfänger.`
      }, {
        role: 'user',
        content: `Erstelle eine SEHR DETAILLIERTE Reparaturanleitung für:
- Fehlercode: ${code}
- Ursache: ${causeTitle}

Erstelle 10-20 kinderleicht verständliche Schritte. JEDER Schritt braucht:
- Klaren Titel
- SEHR ausführliche Beschreibung (3-5 Sätze, erkläre WO, WAS, WIE, WARUM)
- Benötigte Werkzeuge
- Dauer in Minuten
- Sicherheitshinweise falls relevant

🚨 EXTREM WICHTIG - OBD2-AUSLESEN:
- Der User HAT BEREITS den Fehlercode ausgelesen - deshalb kennt er ihn!
- NIEMALS "OBD2-Diagnosegerät anschließen" in den ersten Schritten!
- NIEMALS "Fehlercode auslesen" am Anfang!
- Die Anleitung beginnt DIREKT mit der Reparatur (Schritt 1)
- Schritte 1-10+: NUR Reparaturschritte (Motor ausschalten, Motorhaube öffnen, Teil ausbauen, etc.)
- ERST DER ALLERLETZTE SCHRITT: "Fehlercode löschen und Reparatur prüfen"
- Der letzte Schritt muss sein:
  "Fehlercode löschen und Reparatur prüfen: Schließen Sie das OBD2-Diagnosegerät an, löschen Sie den Fehlercode und lesen Sie ihn erneut aus, um zu prüfen, ob die Reparatur erfolgreich war."

🚨 WICHTIG - KEINE REFERENZEN:
- Schreibe NIEMALS Zahlen in eckigen Klammern wie [1], [2], [3], [4], [5], [6], [7] etc.
- KEINE Quellen-Referenzen oder Fußnoten im Text!
- Schreibe fließenden Text OHNE jegliche Referenz-Marker!
- Beispiel FALSCH: "Sensor reinigen[1][2][3]" 
- Beispiel RICHTIG: "Sensor reinigen"

JSON-Format:
{
  "cause_title": "${causeTitle}",
  "difficulty_level": "easy|medium|hard",
  "estimated_time_hours": 2.0,
  "estimated_cost_eur": [100, 300],
  "for_beginners": true,
  "steps": [
    {
      "step": 1,
      "title": "Schritt-Titel",
      "description": "SEHR DETAILLIERTE Beschreibung (3-5 Sätze)",
      "duration_minutes": 10,
      "safety_warning": "Falls relevant",
      "tools": ["Liste"],
      "tips": "Hilfreiche Tipps"
    }
  ],
  "tools_required": ["Komplette Werkzeugliste"],
  "safety_warnings": ["Alle Sicherheitshinweise"],
  "when_to_call_mechanic": ["Wann zur Werkstatt"]
}

NUR JSON ausgeben!`
      }],
      temperature: 0.3,
      max_tokens: 6000,
      response_format: { type: "json_object" }
    })
  });
  
  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status}`);
  }
  
  const data = await response.json();
  const content = data.choices[0].message.content;
  
  return JSON.parse(content);
}

/**
 * Übersetzt eine einzelne deutsche Anleitung nach Englisch
 */
async function translateSingleGuide(guideDe: any): Promise<any> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{
        role: 'system',
        content: 'Du bist ein professioneller Übersetzer für technische KFZ-Anleitungen.'
      }, {
        role: 'user',
        content: `Übersetze diese deutsche Reparaturanleitung nach Englisch.

WICHTIG:
- Behalte die JSON-Struktur EXAKT bei
- Übersetze ALLE Texte
- Behalte die kinderleichte, ausführliche Sprache bei

Deutsche Anleitung:
${JSON.stringify(guideDe, null, 2)}

Antworte mit der EXAKT gleichen JSON-Struktur in Englisch.
NUR JSON ausgeben!`
      }],
      temperature: 0.3,
      max_tokens: 6000,
      response_format: { type: "json_object" }
    })
  });
  
  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status}`);
  }
  
  const data = await response.json();
  return JSON.parse(data.choices[0].message.content);
}

/**
 * Verarbeitet spezifische Error Codes (von enrich-error-code getriggert)
 */
async function processSpecificCodes(errorCodes: string[]): Promise<Response> {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    console.log(`🔍 Processing ${errorCodes.length} specific codes...`);
    let successCount = 0;
    
    for (const code of errorCodes) {
      // Hole Entry aus DB (exakte topic query!)
      const { data: entry, error: fetchError } = await supabase
        .from('automotive_knowledge')
        .select('id, topic, causes, repair_guides_de, repair_guides_en')
        .eq('category', 'fehlercode')
        .eq('topic', `${code} OBD2 diagnostic trouble code`)
        .maybeSingle();
      
      if (fetchError || !entry) {
        console.error(`❌ Code ${code} not found in DB`);
        continue;
      }
      
      const causes = entry.causes || [];
      let currentGuidesDe = entry.repair_guides_de || {};
      let currentGuidesEn = entry.repair_guides_en || {};
      
      console.log(`🔧 Processing ${code} with ${causes.length} causes...`);
      let updatedInThisRun = false;
      let processedInThisCall = 0;
      const MAX_CAUSES_PER_CALL = 3; // ← Timeout-Schutz: Max 3 Causes pro Call
      
      for (let i = 0; i < causes.length; i++) {
        const causeTitle = causes[i];
        const causeKey = causeTitle.toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .replace(/^_|_$/g, '');
        
        if (currentGuidesDe[causeKey] && currentGuidesEn[causeKey]) {
          console.log(`⏭️  ${code} cause ${i + 1}/${causes.length}: Already exists`);
          continue;
        }
        
        // Timeout-Schutz: Wenn bereits 3 Causes generiert, stoppe
        if (processedInThisCall >= MAX_CAUSES_PER_CALL) {
          console.log(`⏸️  ${code}: Pause nach ${processedInThisCall} Causes (Timeout-Schutz). Weiter beim nächsten Call.`);
          break;
        }
        
        try {
          console.log(`📝 ${code} cause ${i + 1}/${causes.length}: ${causeTitle.substring(0, 50)}...`);
          
          const guideDe = await generateSingleCauseRepairGuide(code, causeTitle);
          if (!guideDe) {
            console.error(`❌ ${code} cause ${i + 1}: No guide generated`);
            continue;
          }
          
          currentGuidesDe[causeKey] = guideDe;
          console.log(`✅ DE guide (${guideDe.steps?.length || 0} steps)`);
          
          const guideEn = await translateSingleGuide(guideDe);
          if (!guideEn) {
            console.error(`❌ ${code} cause ${i + 1}: Translation failed`);
            continue;
          }
          
          currentGuidesEn[causeKey] = guideEn;
          console.log(`✅ EN translation`);
          
          // SOFORT in DB speichern nach JEDER erfolgreichen Generation
          const { error: updateError } = await supabase
            .from('automotive_knowledge')
            .update({ 
              repair_guides_de: currentGuidesDe,
              repair_guides_en: currentGuidesEn
            })
            .eq('id', entry.id);
          
          if (updateError) {
            console.error(`❌ ${code} cause ${i + 1}: DB update failed:`, updateError.message);
          } else {
            console.log(`💾 ${code} cause ${i + 1}: Saved to DB`);
            updatedInThisRun = true;
            processedInThisCall++; // ← Zähle erfolgreiche Generierungen
          }
          
        } catch (error: any) {
          console.error(`❌ ${code} cause ${i + 1} ERROR:`, error.message || error);
        }
      }
      
      if (updatedInThisRun) {
        successCount++;
      }
    }
    
    return new Response(JSON.stringify({
      success: true,
      processed: successCount,
      total: errorCodes.length
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error: any) {
    console.error('❌ processSpecificCodes Error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    });
  }
}

/**
 * Flutter Fallback: Generiert EINE Anleitung on-demand und speichert sie in DB
 */
async function generateSingleCauseGuide(errorCode: string, causeTitle: string, causeKey: string): Promise<Response> {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    console.log(`🤖 Flutter Fallback: Generating guide for ${errorCode} - ${causeTitle}`);
    
    // Generiere Anleitung
    const guide = await generateSingleCauseRepairGuide(errorCode, causeTitle);
    
    if (!guide) {
      throw new Error('Failed to generate guide');
    }
    
    // Hole bestehende repair_guides_de
    const { data: entry, error: fetchError } = await supabase
      .from('automotive_knowledge')
      .select('id, repair_guides_de')
      .eq('category', 'fehlercode')
      .ilike('topic', `%${errorCode}%`)
      .single();
    
    if (fetchError) throw fetchError;
    
    // Füge neue Anleitung hinzu
    const updatedGuides = { ...(entry.repair_guides_de || {}), [causeKey]: guide };
    
    // Speichere in DB
    const { error: updateError } = await supabase
      .from('automotive_knowledge')
      .update({ repair_guides_de: updatedGuides })
      .eq('id', entry.id);
    
    if (updateError) throw updateError;
    
    console.log(`✅ Saved guide for ${errorCode} - ${causeKey}`);
    
    return new Response(JSON.stringify({
      success: true,
      repair_guide: guide
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error: any) {
    console.error('❌ Flutter Fallback Error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    });
  }
}
