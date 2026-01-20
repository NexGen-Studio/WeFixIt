// ============================================================================
// Cleanup and Translate Titles - Title-Optimierung für automotive_knowledge
// ============================================================================
// Aufgabe:
// 1. Kürzt lange Titel (entfernt "P0420 OBD2-Fehlercode:" und "– Umfassende...")
// 2. Übersetzt Titel in alle 4 Sprachen (DE/EN/FR/ES)
// 3. Batch-Processing für Effizienz
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

interface TitleTranslations {
  de: string;
  en: string;
  fr: string;
  es: string;
}

Deno.serve(async (req) => {
  try {
    const { batch_size = 50, dry_run = false } = await req.json().catch(() => ({}));
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    console.log('🔍 Searching for titles to cleanup...');
    
    // 1. Hole alle Einträge mit langen oder deutschen title_en
    const { data: entries, error: fetchError } = await supabase
      .from('automotive_knowledge')
      .select('id, title_de, title_en, title_fr, title_es')
      .eq('category', 'fehlercode')
      .or('title_de.ilike.%OBD2%,title_en.ilike.%Fehlercode%,title_en.ilike.%OBD2%')
      .limit(batch_size);
    
    if (fetchError) throw fetchError;
    
    if (!entries || entries.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: 'No titles need cleanup',
        processed: 0
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    console.log(`📋 Found ${entries.length} titles to process`);
    
    // 2. Extrahiere und übersetze Titel batch-weise
    const updates: Array<{ id: string; translations: TitleTranslations }> = [];
    
    for (const entry of entries) {
      const rawTitle = entry.title_de || entry.title_en || '';
      
      if (!rawTitle) {
        console.log(`⚠️ Skipping entry ${entry.id} - no title found`);
        continue;
      }
      
      console.log(`🔄 Processing: "${rawTitle}"`);
      
      // GPT generiert komplett neue, verständliche Titel
      const translations = await generateUserFriendlyTitles(rawTitle);
      
      if (translations) {
        updates.push({ id: entry.id, translations });
      } else {
        console.log(`⚠️ Skipping entry ${entry.id} - GPT generated invalid titles`);
      }
    }
    
    console.log(`✅ Translated ${updates.length} titles`);
    
    // 3. Update Datenbank (wenn nicht dry_run)
    if (!dry_run && updates.length > 0) {
      let successCount = 0;
      
      for (const update of updates) {
        const { error: updateError } = await supabase
          .from('automotive_knowledge')
          .update({
            title_de: update.translations.de,
            title_en: update.translations.en,
            title_fr: update.translations.fr,
            title_es: update.translations.es,
            updated_at: new Date().toISOString()
          })
          .eq('id', update.id);
        
        if (updateError) {
          console.error(`❌ Failed to update ${update.id}:`, updateError);
        } else {
          successCount++;
        }
      }
      
      console.log(`💾 Updated ${successCount}/${updates.length} entries in database`);
      
      return new Response(JSON.stringify({
        success: true,
        processed: successCount,
        total: updates.length,
        sample: updates.slice(0, 3).map(u => u.translations)
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Dry run mode
    return new Response(JSON.stringify({
      success: true,
      dry_run: true,
      would_update: updates.length,
      samples: updates.slice(0, 5).map(u => ({
        id: u.id,
        translations: u.translations
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

/**
 * Generiert verständliche, kurze Titel in allen 4 Sprachen
 * OHNE "Fehlercode", "OBD", Code-Nummern etc.
 * NUR die Beschreibung des Problems für Laien
 */
async function generateUserFriendlyTitles(rawTitle: string): Promise<TitleTranslations | null> {
  try {
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
          content: `Du bist ein KFZ-Experte, der technische Fehlercode-Beschreibungen in verständliche, kurze Titel für Autobesitzer umwandelt.

KRITISCHE REGELN:
1. NIEMALS Code-Nummern (P0456, C0123, B1234, U0001)
2. NIEMALS "Fehlercode", "OBD", "OBD2", "Error Code", "Diagnostic"
3. NIEMALS Beschreibungen wie "Bedeutung", "Symptome", "Ursache", "Reparatur"
4. Sei SPEZIFISCH (3-5 Wörter) - vermeide allgemeine Begriffe
5. Behalte wichtige Details: Buchstaben (A/B/C/D), Nummern (Bank 1/2), Position
6. Für normale Autobesitzer verständlich

Gute Beispiele (SPEZIFISCH aber kurz):
✅ "Primärsteuerkreis Zündspule C" (NICHT nur "Zündspule defekt")
✅ "Lambdasonde Bank 1 Sensor 2" (NICHT nur "Lambdasonde defekt")
✅ "Leck im Verdunstungssystem klein"
✅ "Katalysator Wirkungsgrad Bank 1"
✅ "AGR-Ventil Position Sensor"

Schlechte Beispiele (zu allgemein!):
❌ "Zündspule defekt" → ❌ zu allgemein! Welche Zündspule?
❌ "Lambdasonde ausgefallen" → ❌ welche Bank? Welcher Sensor?
❌ "Katalysator defekt" → ❌ welche Bank?

Verbotene Beispiele (Code-Nummern!):
❌ "OBD-II Fehlercode P0456"
❌ "P2307 Primärsteuerkreis"
❌ "Bedeutung, Symptome, Ursache"`
        }, {
          role: 'user',
          content: `Erstelle einen kurzen, verständlichen Titel für diesen Fehlercode:

Roher Titel: "${rawTitle}"

Erstelle einen KURZEN (3-5 Wörter), VERSTÄNDLICHEN Titel, der NUR das Problem beschreibt.
Übersetze in alle 4 Sprachen.

WICHTIG:
- KEINE Code-Nummern (P0456, C0123, etc.)
- KEINE Wörter "Fehlercode", "OBD", "Diagnostic", "Error Code"
- NUR das Problem (z.B. "Katalysator defekt", "Lambdasonde ausgefallen")
- Max 5 Wörter, bevorzugt 3-4
- Für Laien verständlich

Antworte EXAKT in diesem JSON-Format:
{
  "de": "Kurzer deutscher Titel",
  "en": "Short English title",
  "fr": "Titre français court",
  "es": "Título español corto"
}

NUR JSON ausgeben!`
        }],
        temperature: 0.3,
        response_format: { type: "json_object" }
      })
    });
    
    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }
    
    const data = await response.json();
    const translations = JSON.parse(data.choices[0].message.content);
    
    // Validierung: Prüfe ob Titel wirklich sauber sind
    const hasInvalidWords = (title: string) => {
      const invalid = /\b(fehlercode|obd|p[0-9]{4}|c[0-9]{4}|b[0-9]{4}|u[0-9]{4}|error code|diagnostic|code d'erreur|código de error|bedeutung|symptome|ursache|reparatur|meaning|symptoms|cause|repair|signification|réparation|significado|reparación)\b/i;
      return invalid.test(title);
    };
    
    // Wenn GPT trotzdem ungültige Wörter verwendet, ablehnen
    if (hasInvalidWords(translations.de) || 
        hasInvalidWords(translations.en) ||
        hasInvalidWords(translations.fr) ||
        hasInvalidWords(translations.es)) {
      console.warn(`⚠️ GPT generated invalid titles for "${rawTitle}" - contains forbidden words`);
      console.warn(`  DE: ${translations.de}`);
      console.warn(`  EN: ${translations.en}`);
      return null;
    }
    
    return {
      de: translations.de || '',
      en: translations.en || '',
      fr: translations.fr || '',
      es: translations.es || ''
    };
    
  } catch (error) {
    console.error('❌ Title generation failed:', error);
    return null;
  }
}
