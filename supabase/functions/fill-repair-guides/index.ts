// ============================================================================
// Fill Repair Guides - Orchestrator (NUR Delegation, keine OpenAI Calls!)
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

Deno.serve(async (req) => {
  try {
    const { error_codes, trigger_source, language = 'de' } = await req.json().catch(() => ({}));
    
    if (!error_codes || !Array.isArray(error_codes)) {
      return new Response(JSON.stringify({
        error: 'Missing error_codes array'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    console.log(`🔧 Triggered by ${trigger_source || 'external'} for codes: ${error_codes.join(', ')} [${language.toUpperCase()}]`);
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    let processedCount = 0;
    const MAX_PARALLEL = 1; // Max 1 Call gleichzeitig (gegen WORKER_LIMIT!)
    const DELAY_BETWEEN_BATCHES = 10000; // 10 Sekunden Pause (translate-repair-guides speichert jetzt incremental!)
    
    for (const code of error_codes) {
      // Lade sprachabhängige causes und repair_guides Spalten
      const isEnglish = language === 'en';
      const causesColumn = isEnglish ? 'causes_en' : 'causes';
      const guidesColumn = isEnglish ? 'repair_guides_en' : 'repair_guides_de';
      
      const { data: entry } = await supabase
        .from('automotive_knowledge')
        .select(`id, topic, ${causesColumn}, ${guidesColumn}`)
        .eq('topic', `${code} OBD2 diagnostic trouble code`)
        .maybeSingle();
      
      if (!entry) {
        console.error(`❌ ${code} not found in DB`);
        continue;
      }
      
      const causes = entry[causesColumn] || [];
      const existingGuides = entry[guidesColumn] || {};
      
      console.log(`🔧 ${code}: ${causes.length} causes, ${Object.keys(existingGuides).length} guides exist`);
      
      // Finde fehlende Guides
      const missingCauses = [];
      for (const causeTitle of causes) {
        const causeKey = causeTitle.toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .replace(/^_|_$/g, '');
        
        if (!existingGuides[causeKey]) {
          missingCauses.push({ causeTitle, causeKey });
        }
      }
      
      console.log(`📝 ${code}: ${missingCauses.length} guides to generate`);
      
      // Generiere NUR wenn es fehlende Guides gibt
      if (missingCauses.length > 0) {
        // Generiere in Batches von MAX_PARALLEL
        for (let i = 0; i < missingCauses.length; i += MAX_PARALLEL) {
        const batch = missingCauses.slice(i, i + MAX_PARALLEL);
        
        console.log(`🔄 ${code}: Batch ${Math.floor(i / MAX_PARALLEL) + 1}/${Math.ceil(missingCauses.length / MAX_PARALLEL)} (${batch.length} guides)`);
        
        // Verarbeite Batch parallel
        const promises = batch.map(async ({ causeTitle, causeKey }) => {
          try {
            console.log(`📝 ${code} - ${causeKey}: Calling generate-repair-guides`);
            
            const response = await fetch(`${SUPABASE_URL}/functions/v1/generate-repair-guides`, {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                code,
                cause_key: causeKey,
                cause_title: causeTitle,
                language
              })
            });
            
            if (response.ok) {
              console.log(`✅ ${code} - ${causeKey}: Generated`);
              return true;
            } else {
              const error = await response.text();
              console.error(`❌ ${code} - ${causeKey}: ${error}`);
              return false;
            }
          } catch (error) {
            console.error(`❌ ${code} - ${causeKey}:`, error);
            return false;
          }
        });
        
        const results = await Promise.all(promises);
        processedCount += results.filter(r => r).length;
        
        // Pause zwischen Batches
        if (i + MAX_PARALLEL < missingCauses.length) {
          console.log(`⏸️  Pause ${DELAY_BETWEEN_BATCHES}ms...`);
          await new Promise(resolve => setTimeout(resolve, DELAY_BETWEEN_BATCHES));
        }
        }
      } else {
        console.log(`⏭️ ${code}: All guides already exist, skipping generation`);
      }
      
      // Trigger Translation (auch wenn keine neuen Guides generiert wurden!)
      // Damit werden bestehende DE Guides übersetzt
      try {
        console.log(`🌍 Starting translation for ${code}...`);
        
        const translationResponse = await fetch(`${SUPABASE_URL}/functions/v1/translate-repair-guides`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            codes: [code],
            dry_run: false
          }),
          signal: AbortSignal.timeout(90000) // 90s Timeout (translate-repair-guides speichert jetzt nach jedem Guide)
        });
        
        if (translationResponse.ok) {
          const result = await translationResponse.json();
          console.log(`✅ Translation for ${code} completed:`, result);
          if (result.guides_translated) {
            console.log(`📊 ${result.guides_translated} guides translated`);
          }
        } else {
          const status = translationResponse.status;
          const error = await translationResponse.text();
          console.error(`❌ Translation for ${code} failed (${status}):`, error);
        }
      } catch (err: any) {
        if (err.name === 'AbortError') {
          console.error(`⏱️ Translation for ${code} timed out after 120s`);
        } else {
          console.error(`⚠️ Translation trigger failed for ${code}:`, err.message || err);
        }
      }
    }
    
    return new Response(JSON.stringify({
      success: true,
      processed: processedCount
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
});
