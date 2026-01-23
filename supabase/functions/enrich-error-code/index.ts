// ============================================================================
// Enrich Error Code - 3-Szenario OBD2 Fehlercode Enrichment
// ============================================================================
// Phase "quick": Schnelle GPT-Antwort (2-3 Sek) - NICHT in DB speichern!
//                Flutter prüft DB vorher, diese Phase nur für neue Codes
// Phase "enrich": Perplexity Web-Search + GPT + DB-Speicherung
//                 + Fahrzeugspezifischer Cache (vehicle_specific JSONB)
//                 + Mehrsprachige repair_guides (DE/EN/FR/ES)
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY') || '';
const PERPLEXITY_API_KEY = Deno.env.get('PERPLEXITY_API_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

interface QuickResponse {
  code: string;
  title_de: string;
  title_en: string;
  content_de: string;
  content_en: string;
  symptoms: string[];
  causes: string[];
  repair_steps: string[];
}

Deno.serve(async (req) => {
  try {
    const { code, phase, vehicle } = await req.json();
    
    // vehicle = { make: "BMW", model: "320d", series: "E46", year: 2005, engine: "2.0L Diesel" }

    if (!code) {
      return new Response(JSON.stringify({ error: 'Missing error code' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // ========================================================================
    // PHASE "quick": Schnelle GPT-Antwort (wird NICHT in DB gespeichert)
    // ========================================================================
    if (phase === 'quick') {
      console.log(`📞 Quick GPT: Generating temporary response for ${code}`);

      const quickResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [{
            role: 'system',
            content: `Du bist ein KFZ-Experte. Erstelle schnelle, präzise Basis-Informationen zu OBD2-Fehlercodes.`
          }, {
            role: 'user',
            content: `Erstelle Basis-Informationen für OBD2-Fehlercode ${code}.

Antworte EXAKT in folgendem JSON-Format:

{
  "title_de": "Kurzer deutscher Titel (max 3-4 Wörter)",
  "title_en": "Short English title (max 3-4 words)",
  "content_de": "Deutsche Beschreibung (2-3 Sätze, was dieser Fehlercode bedeutet)",
  "content_en": "English description (2-3 sentences, what this error code means)",
  "symptoms": ["Symptom 1", "Symptom 2", "Symptom 3"],
  "causes": ["Ursache 1", "Ursache 2", "Ursache 3"],
  "repair_steps": ["Reparaturschritt 1", "Reparaturschritt 2", "Reparaturschritt 3"]
}

WICHTIG: Nur JSON ausgeben, kein zusätzlicher Text!`
          }],
          temperature: 0.3,
          response_format: { type: "json_object" }
        })
      });

      if (!quickResponse.ok) {
        throw new Error(`OpenAI API error: ${quickResponse.status}`);
      }

      const quickData = await quickResponse.json();
      const result = JSON.parse(quickData.choices[0].message.content);

      console.log(`✅ Quick GPT: Temporary response for ${code} (NOT saved to DB)`);
      return new Response(JSON.stringify({
        success: true,
        data: {
          code,
          ...result
        }
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      });
    }

    // ========================================================================
    // PHASE "enrich": Perplexity Web-Search + Vollständige GPT-Verarbeitung
    // ========================================================================
    if (phase === 'enrich') {
      console.log(`🔍 Enrich: Starting full enrichment for ${code}`);
      if (vehicle) {
        console.log(`🚗 Vehicle: ${vehicle.year} ${vehicle.make} ${vehicle.model}`);
      }

      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

      // 1. Prüfe DB: Existiert Code bereits vollständig?
      const { data: existing } = await supabase
        .from('automotive_knowledge')
        .select('id, topic, vehicle_specific, repair_guides_de, repair_guides_en, causes')
        .eq('category', 'fehlercode')
        .ilike('topic', `%${code}%`)
        .maybeSingle();

      // 2. Prüfe: Hat Code repair_guides_de/en UND causes?
      const hasCompleteData = existing && 
                              existing.repair_guides_de && 
                              Object.keys(existing.repair_guides_de).length > 0 &&
                              existing.repair_guides_en && 
                              Object.keys(existing.repair_guides_en).length > 0 &&
                              existing.causes &&
                              existing.causes.length > 0;

      // 3. Falls komplett vorhanden UND Fahrzeugdaten → Nur Vehicle-specific enrichment
      if (hasCompleteData && vehicle) {
        const vehicleKey = `${vehicle.make}_${vehicle.model}`.toLowerCase().replace(/[^a-z0-9_]/g, '_');
        
        if (existing.vehicle_specific?.[vehicleKey]) {
          console.log(`✅ Skip: ${code} already complete with vehicle data`);
          return new Response(JSON.stringify({
            success: true,
            skipped: true,
            reason: 'Complete with vehicle data'
          }), {
            headers: { 'Content-Type': 'application/json' },
            status: 200
          });
        }
        
        console.log(`🚗 Adding vehicle-specific data for ${vehicleKey}`);
        const vehicleSpecificData = await generateVehicleSpecificData(code, vehicle);
        
        const { error: updateError } = await supabase
          .from('automotive_knowledge')
          .update({
            vehicle_specific: {
              ...(existing.vehicle_specific || {}),
              [vehicleKey]: vehicleSpecificData
            },
            updated_at: new Date().toISOString()
          })
          .eq('id', existing.id);
        
        if (updateError) throw updateError;
        
        console.log(`✅ Vehicle data added for ${vehicleKey}`);
        return new Response(JSON.stringify({
          success: true,
          vehicle_enriched: true
        }), {
          headers: { 'Content-Type': 'application/json' },
          status: 200
        });
      }
      
      // 4. Falls komplett vorhanden OHNE Fahrzeugdaten → Skip
      if (hasCompleteData && !vehicle) {
        console.log(`✅ Skip: ${code} already complete in DB`);
        return new Response(JSON.stringify({
          success: true,
          skipped: true,
          reason: 'Already complete'
        }), {
          headers: { 'Content-Type': 'application/json' },
          status: 200
        });
      }
      
      // 5. Code existiert NICHT oder ist unvollständig → Full Enrichment

      // 6. Perplexity Web-Search (IMMER allgemein für Content)
      const searchPrompt = `Recherchiere umfassende Informationen über den OBD2-Fehlercode ${code}.`;
      
      console.log(`🔍 Perplexity: Searching for ${code}`);
      const searchResponse = await fetch('https://api.perplexity.ai/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${PERPLEXITY_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'sonar',
          messages: [{
            role: 'system',
            content: `Du bist ein KFZ-Experte. Recherchiere umfassende Informationen zu OBD2-Fehlercodes aus dem Web.`
          }, {
            role: 'user',
            content: `${searchPrompt}

Erstelle einen strukturierten Artikel und antworte EXAKT in folgendem JSON-Format:

{
  "title": "KURZER deutscher Titel (NUR das System/Bauteil, z.B. 'Katalysatorsystem' oder 'Lambdasonde' - OHNE 'OBD2-Fehlercode P0420:' oder ähnliches)",
  "content": "Ausführliche deutsche Beschreibung (mindestens 300 Wörter)",
  "symptoms": ["Symptom 1", "Symptom 2", "Symptom 3", "Symptom 4", "Symptom 5", "Symptom 6"],
  "causes": ["Ursache 1", "Ursache 2", "Ursache 3", "Ursache 4", "Ursache 5", "Ursache 6", "Ursache 7", "Ursache 8"],
  "diagnostic_steps": ["Diagnoseschritt 1", "Diagnoseschritt 2", "Diagnoseschritt 3"],
  "repair_steps": ["Reparaturschritt 1", "Reparaturschritt 2", "Reparaturschritt 3"],
  "tools_required": ["Werkzeug 1", "Werkzeug 2", "Werkzeug 3"],
  "estimated_cost_eur": 250.00,
  "difficulty_level": "medium"
}

Nur JSON ausgeben, kein zusätzlicher Text!`
          }],
          temperature: 0.7,
          return_citations: true,
          return_images: false,
        })
      });

      if (!searchResponse.ok) {
        throw new Error(`Perplexity API error: ${searchResponse.status}`);
      }

      const searchData = await searchResponse.json();
      const responseText = searchData.choices[0].message.content;
      const sources = searchData.citations || [];

      // Parse JSON aus Perplexity Response
      let webData;
      try {
        webData = JSON.parse(responseText);
      } catch (e) {
        const jsonMatch = responseText.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          webData = JSON.parse(jsonMatch[0]);
        } else {
          throw new Error(`Invalid JSON from Perplexity: ${responseText.substring(0, 200)}`);
        }
      }

      // Entferne Citation-Markers [1], [2], [3] etc. aus allen Textfeldern
      if (webData.title) {
        webData.title = webData.title.replace(/\[\d+\]/g, '').trim();
      }
      if (webData.content) {
        webData.content = webData.content.replace(/\[\d+\]/g, '').trim();
      }
      if (webData.symptoms && Array.isArray(webData.symptoms)) {
        webData.symptoms = webData.symptoms.map((s: string) => s.replace(/\[\d+\]/g, '').trim());
      }
      if (webData.causes && Array.isArray(webData.causes)) {
        webData.causes = webData.causes.map((c: string) => c.replace(/\[\d+\]/g, '').trim());
      }
      if (webData.diagnostic_steps && Array.isArray(webData.diagnostic_steps)) {
        webData.diagnostic_steps = webData.diagnostic_steps.map((d: string) => d.replace(/\[\d+\]/g, '').trim());
      }
      if (webData.repair_steps && Array.isArray(webData.repair_steps)) {
        webData.repair_steps = webData.repair_steps.map((r: string) => r.replace(/\[\d+\]/g, '').trim());
      }

      console.log(`✅ Perplexity: Found ${sources.length} sources`);

      // 7. Vehicle-specific Daten laden
      // vehicle_specific wird jetzt von separater Edge Function generiert (enrich-vehicle-specific)
      const vehicleSpecificData = existing?.vehicle_specific || {};
      
      // 8. Merge vehicle_specific issues in causes (für Anleitungen)
      let allCauses = webData.causes || [];
      if (vehicle) {
        const vehicleKey = generateVehicleKey(vehicle);
        if (vehicleSpecificData[vehicleKey]?.issues) {
          const vehicleIssues = vehicleSpecificData[vehicleKey].issues;
          // Nur Issues hinzufügen die noch nicht in causes sind
          vehicleIssues.forEach((issue: string) => {
            if (!allCauses.some((c: string) => c.toLowerCase().includes(issue.toLowerCase().substring(0, 20)))) {
              allCauses.push(issue);
            }
          });
          console.log(`✅ Merged ${vehicleIssues.length} vehicle-specific issues into causes`);
        }
      }
      
      // 9. GPT: Übersetze title, content, symptoms, causes ins Englische
      console.log(`🌐 Translating to EN (title, content, symptoms, causes)...`);
      const translateResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [{
            role: 'system',
            content: `Du bist ein professioneller Übersetzer für KFZ-Fachterminologie.`
          }, {
            role: 'user',
            content: `Übersetze folgenden Text nach Englisch:

Titel: ${webData.title}
Inhalt: ${webData.content}
Symptome: ${JSON.stringify(webData.symptoms || [])}
Ursachen: ${JSON.stringify(allCauses)}

Antworte im JSON-Format: {"title": "...", "content": "...", "symptoms": [...], "causes": [...]}`
          }],
          temperature: 0.3,
          response_format: { type: "json_object" }
        })
      });

      const translateData = await translateResponse.json();
      const translationEn = JSON.parse(translateData.choices[0].message.content);
      
      // 10. Embeddings erstellen (DE + EN)
      console.log(`🧮 Creating embeddings (DE + EN)...`);
      const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'text-embedding-3-small',
          input: `${webData.title}\n\n${webData.content}`,
        })
      });

      const embeddingData = await embeddingResponse.json();
      const embeddingDe = embeddingData.data[0].embedding;
      const embeddingEn = await createEmbedding(`${translationEn.title}\n\n${translationEn.content}`);
      
      // 11. UPSERT in DB
      console.log(`💾 Upserting ${code}${vehicle ? ' WITH vehicle_specific' : ''}`);
      
      const upsertData = {
        topic: `${code} OBD2 diagnostic trouble code`,
        category: 'fehlercode',
        title_de: webData.title,
        title_en: translationEn.title,
        content_de: webData.content,
        content_en: translationEn.content,
        symptoms: webData.symptoms || [],
        symptoms_en: translationEn.symptoms || [],
        causes: allCauses,
        causes_en: translationEn.causes || [],
        diagnostic_steps: webData.diagnostic_steps || [],
        repair_steps: webData.repair_steps || [],
        tools_required: webData.tools_required || [],
        estimated_cost_eur: webData.estimated_cost_eur || null,
        difficulty_level: webData.difficulty_level || 'medium',
        vehicle_specific: vehicleSpecificData,
        embedding_de: embeddingDe,
        embedding_en: embeddingEn,
        keywords: [code, ...allCauses.map((c: string) => c.toLowerCase())],
        original_language: 'de',
        source_urls: sources.length > 0 ? sources : null,
        quality_score: 0.9,
        updated_at: new Date().toISOString()
      };

      const { error: upsertError } = await supabase
        .from('automotive_knowledge')
        .upsert(upsertData, {
          onConflict: 'topic,category',
          ignoreDuplicates: false
        });

      if (upsertError) throw upsertError;
      console.log(`✅ Upserted ${code}`);
      const wasExisting = existing !== null;

      // Trigger fill-repair-guides NACH dem UPSERT (nicht parallel!)
      console.log(`🔧 Triggering fill-repair-guides for ${code}...`);
      try {
        const triggerResponse = await fetch(`${SUPABASE_URL}/functions/v1/fill-repair-guides`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            error_codes: [code],
            trigger_source: 'enrich-error-code'
          })
        });
        
        if (triggerResponse.ok) {
          console.log(`✅ fill-repair-guides triggered for ${code}`);
        } else {
          console.error(`⚠️ fill-repair-guides trigger failed: ${triggerResponse.status}`);
        }
      } catch (err) {
        console.error(`⚠️ Failed to trigger fill-repair-guides:`, err);
      }

      return new Response(JSON.stringify({
        success: true,
        code,
        sources: sources.length,
        action: wasExisting ? 'updated' : 'created'
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      });
    }

    // Ungültige Phase
    return new Response(JSON.stringify({ error: 'Invalid phase. Use "quick" or "enrich"' }), {
      status: 400,
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

// ============================================================================
// Helper Functions
// ============================================================================

function generateVehicleKey(vehicle: any): string {
  return `${vehicle.make}_${vehicle.model}`.toLowerCase().replace(/[^a-z0-9_]/g, '_');
}

async function generateVehicleSpecificData(code: string, vehicle: any): Promise<any> {
  const response = await fetch('https://api.perplexity.ai/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${PERPLEXITY_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'sonar',
      messages: [{
        role: 'system',
        content: 'Du bist ein KFZ-Experte mit Fokus auf fahrzeugspezifische Diagnose.'
      }, {
        role: 'user',
        content: `Recherchiere ${code} SPEZIFISCH für ${vehicle.year} ${vehicle.make} ${vehicle.model} ${vehicle.engine || ''}.

Antworte im JSON-Format:
{
  "issues": ["Bekanntes Problem 1 bei diesem Fahrzeugmodell", "Bekanntes Problem 2", "Bekanntes Problem 3"],
  "most_likely_cause": "Die wahrscheinlichste Ursache bei diesem Fahrzeugmodell",
  "typical_mileage_km": "120.000 - 180.000",
  "part_numbers": {"teil": "Teilenummer"},
  "cost_estimate_eur": [150, 350],
  "specific_notes_de": "Fahrzeugspezifische Hinweise zu bekannten Schwachstellen"
}`
      }],
      temperature: 0.7,
      return_citations: true
    })
  });
  
  const data = await response.json();
  const text = data.choices[0].message.content;
  
  let result;
  try {
    result = JSON.parse(text);
  } catch (e) {
    const match = text.match(/\{[\s\S]*\}/);
    result = match ? JSON.parse(match[0]) : {};
  }
  
  // Entferne Citations aus vehicle_specific Daten
  if (result.issues && Array.isArray(result.issues)) {
    result.issues = result.issues.map((issue: string) => issue.replace(/\[\d+\]/g, '').trim());
  }
  if (result.most_likely_cause) {
    result.most_likely_cause = result.most_likely_cause.replace(/\[\d+\]/g, '').trim();
  }
  if (result.specific_notes_de) {
    result.specific_notes_de = result.specific_notes_de.replace(/\[\d+\]/g, '').trim();
  }
  
  return result;
}

async function translateContent(title: string, content: string, lang: string): Promise<any> {
  const langNames: any = { en: 'English', fr: 'Français', es: 'Español' };
  
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
        content: `Du bist ein professioneller Übersetzer für KFZ-Fachterminologie.`
      }, {
        role: 'user',
        content: `Übersetze nach ${langNames[lang]}:\n\nTitel: ${title}\nInhalt: ${content}\n\nJSON: {"title": "...", "content": "..."}`
      }],
      temperature: 0.3,
      response_format: { type: "json_object" }
    })
  });
  
  const data = await response.json();
  return JSON.parse(data.choices[0].message.content);
}

async function createEmbedding(text: string): Promise<any> {
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: text,
    })
  });
  
  const data = await response.json();
  return data.data[0].embedding;
}
