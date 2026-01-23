import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const PERPLEXITY_API_KEY = Deno.env.get('PERPLEXITY_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (req) => {
  try {
    const { code, vehicle } = await req.json();
    
    if (!code || !vehicle) {
      return new Response(JSON.stringify({ error: 'Missing code or vehicle' }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    console.log(`🚗 Generating vehicle_specific for ${code} - ${vehicle.year} ${vehicle.make} ${vehicle.model}`);
    
    // 1. Generiere Vehicle Key
    const vehicleKey = `${vehicle.make}_${vehicle.model}`.toLowerCase().replace(/\s+/g, '_');
    
    // 2. Prüfe ob bereits vorhanden
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: existing } = await supabase
      .from('automotive_knowledge')
      .select('vehicle_specific, vehicle_specific_en')
      .eq('topic', `${code} OBD2 diagnostic trouble code`)
      .eq('category', 'fehlercode')
      .maybeSingle();
    
    // Wenn BEIDE (DE + EN) bereits vorhanden, skip
    const hasDE = existing?.vehicle_specific?.[vehicleKey]?.issues?.length > 0;
    const hasEN = existing?.vehicle_specific_en?.[vehicleKey]?.issues?.length > 0;
    
    if (hasDE && hasEN) {
      console.log(`✅ Vehicle_specific (DE+EN) für ${vehicleKey} bereits vorhanden`);
      return new Response(JSON.stringify({ 
        success: true, 
        skipped: true,
        vehicleKey 
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    console.log(`🔄 Generating: DE=${!hasDE}, EN=${!hasEN}`);
    
    // 3. Helper Function: Call Perplexity + Parse
    async function callPerplexity(language: 'de' | 'en') {
      const systemPrompt = language === 'de' 
        ? 'Du bist ein KFZ-Experte. Antworte IMMER NUR mit VALIDEM JSON, keine Erklärungen.'
        : 'You are an automotive expert. ALWAYS respond with VALID JSON ONLY, no explanations.';
      
      const userPrompt = language === 'de'
        ? `Recherchiere Fehlercode ${code} SPEZIFISCH für ${vehicle.year} ${vehicle.make} ${vehicle.model} ${vehicle.engine || ''}.

Antworte NUR mit diesem JSON (kein Markdown, keine Erklärungen):
{
  "issues": ["Bekanntes Problem 1 bei diesem Modell", "Bekanntes Problem 2", "Bekanntes Problem 3"],
  "most_likely_cause": "Die wahrscheinlichste Ursache bei diesem Modell",
  "typical_mileage_km": "120000-180000",
  "part_numbers": {"Bauteil": "Teilenummer"},
  "cost_estimate_eur": [150, 350],
  "specific_notes_de": "Fahrzeugspezifische Hinweise zu bekannten Schwachstellen"
}

WICHTIG: Falls keine spezifischen Infos verfügbar sind, gib allgemeines KFZ-Wissen zu diesem Code zurück. IMMER valides JSON zurückgeben!`
        : `Research error code ${code} SPECIFICALLY for ${vehicle.year} ${vehicle.make} ${vehicle.model} ${vehicle.engine || ''}.

Respond ONLY with this JSON (no markdown, no explanations):
{
  "issues": ["Known issue 1 for this model", "Known issue 2", "Known issue 3"],
  "most_likely_cause": "The most likely cause for this model",
  "typical_mileage_km": "120000-180000",
  "part_numbers": {"part_name": "part_number"},
  "cost_estimate_eur": [150, 350],
  "specific_notes_de": "Vehicle-specific notes about known weaknesses"
}

IMPORTANT: If no specific info is available, provide general automotive knowledge. ALWAYS return valid JSON!`;
      
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
            content: systemPrompt
          }, {
            role: 'user',
            content: userPrompt
          }],
          temperature: 0.3,
          return_citations: false,
          max_tokens: 2000
        })
      });
      
      if (!response.ok) {
        throw new Error(`Perplexity API failed (${language}): ${response.status}`);
      }
      
      const data = await response.json();
      let text = data.choices[0].message.content;
      
      console.log(`📝 [${language.toUpperCase()}] Response length: ${text.length} chars`);
      
      // Strip Markdown
      text = text.replace(/^```(?:json)?\s*/gm, '').replace(/\s*```$/gm, '').trim();
      
      // Parse JSON
      let result;
      try {
        result = JSON.parse(text);
        console.log(`✅ [${language.toUpperCase()}] JSON parsed`);
      } catch (e) {
        const match = text.match(/\{[\s\S]*\}/);
        if (match) {
          result = JSON.parse(match[0]);
          console.log(`✅ [${language.toUpperCase()}] Regex extraction`);
        } else {
          throw new Error(`JSON parsing failed for ${language}`);
        }
      }
      
      // Clean citations
      if (result.issues) result.issues = result.issues.map((i: string) => i.replace(/\[\d+\]/g, '').trim());
      if (result.most_likely_cause) result.most_likely_cause = result.most_likely_cause.replace(/\[\d+\]/g, '').trim();
      if (result.specific_notes_de) result.specific_notes_de = result.specific_notes_de.replace(/\[\d+\]/g, '').trim();
      
      // Validate
      if (!result.issues || result.issues.length === 0) {
        throw new Error(`No valid issues in ${language} response`);
      }
      
      return result;
    }
    
    // 4. Generate DE + EN
    let resultDE = null;
    let resultEN = null;
    
    if (!hasDE) {
      console.log('🇩🇪 Generating GERMAN vehicle_specific...');
      try {
        resultDE = await callPerplexity('de');
        console.log(`✅ DE: ${resultDE.issues.length} issues`);
      } catch (err: any) {
        console.error('❌ DE generation failed:', err.message);
      }
    }
    
    if (!hasEN) {
      console.log('🇬🇧 Generating ENGLISH vehicle_specific_en...');
      try {
        resultEN = await callPerplexity('en');
        console.log(`✅ EN: ${resultEN.issues.length} issues`);
      } catch (err: any) {
        console.error('❌ EN generation failed:', err.message);
      }
    }
    
    // Wenn beide fehlschlagen → Error
    if (!resultDE && !resultEN && !hasDE && !hasEN) {
      return new Response(JSON.stringify({ 
        error: 'Failed to generate vehicle-specific data in both languages',
        vehicleKey
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // 5. Update DB
    const updatePayload: any = { updated_at: new Date().toISOString() };
    
    if (resultDE) {
      const currentDE = existing?.vehicle_specific || {};
      updatePayload.vehicle_specific = {
        ...currentDE,
        [vehicleKey]: resultDE
      };
    }
    
    if (resultEN) {
      const currentEN = existing?.vehicle_specific_en || {};
      updatePayload.vehicle_specific_en = {
        ...currentEN,
        [vehicleKey]: resultEN
      };
    }
    
    const { error: updateError } = await supabase
      .from('automotive_knowledge')
      .update(updatePayload)
      .eq('topic', `${code} OBD2 diagnostic trouble code`)
      .eq('category', 'fehlercode');
    
    if (updateError) throw updateError;
    
    console.log(`✅ Saved: DE=${!!resultDE}, EN=${!!resultEN}`);
    
    return new Response(JSON.stringify({ 
      success: true, 
      vehicleKey,
      generated: {
        de: !!resultDE,
        en: !!resultEN
      }
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error: any) {
    console.error('❌ Error:', error.message || error);
    return new Response(JSON.stringify({ 
      error: error.message || 'Unknown error' 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
});
