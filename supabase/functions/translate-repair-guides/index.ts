import { createClient } from 'jsr:@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!

Deno.serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  try {
    const { codes, dry_run, source_language = 'auto' } = await req.json()
    
    console.log(`🌍 translate-repair-guides gestartet`);
    console.log(`📋 Codes: ${codes?.join(', ') || 'ALL'}`);
    console.log(`🧪 Dry Run: ${dry_run ? 'YES' : 'NO'}`);
    console.log(`🌐 Source Language: ${source_language}`);
    console.log(`⏰ Timestamp: ${new Date().toISOString()}`);
    
    // 1. Finde Einträge die übersetzt werden müssen
    // Auto-detect: Wenn DE existiert aber EN fehlt → DE→EN
    //              Wenn EN existiert aber DE fehlt → EN→DE
    let query = supabase
      .from('automotive_knowledge')
      .select('id, topic, repair_guides_de, repair_guides_en')
      .eq('category', 'fehlercode');
    
    if (codes && codes.length > 0) {
      const topics = codes.map((c: string) => `${c} OBD2 diagnostic trouble code`);
      query = query.in('topic', topics);
    }
    
    const { data: entries, error: fetchError } = await query;
    
    if (fetchError) {
      throw fetchError;
    }
    
    if (!entries || entries.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: 'No entries to translate',
        processed: 0
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    console.log(`📋 Found ${entries.length} entries to check`);
    
    // 2. Übersetze fehlende EN Guides - SEQUENTIELL um Timeouts zu vermeiden
    console.log(`🔄 Processing ${entries.length} error codes sequentially...`);
    let totalProcessed = 0;
    let totalTranslated = 0;
    
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const code = extractCodeFromTopic(entry.topic);
      console.log(`\n📦 [${i+1}/${entries.length}] Processing ${code}...`);
      
      const guidesDe = entry.repair_guides_de || {};
      const guidesEn = entry.repair_guides_en || {};
      
      const deKeys = Object.keys(guidesDe);
      const enKeys = Object.keys(guidesEn);
      
      // Auto-detect: Welche Richtung übersetzen?
      const missingInEn = deKeys.filter(key => !enKeys.includes(key));
      const missingInDe = enKeys.filter(key => !deKeys.includes(key));
      const missingKeys = missingInEn.length > 0 ? missingInEn : missingInDe;
      const translateDirection = missingInEn.length > 0 ? 'de-to-en' : 'en-to-de';
      
      if (missingKeys.length === 0) {
        console.log(`⏭️  ${code}: All guides already translated (DE+EN complete)`);
        totalProcessed++;
        continue;
      }
      
      console.log(`🔄 ${code}: Translating ${missingKeys.length} guides [${translateDirection}]`);
      
      const newGuidesEn: Record<string, any> = { ...guidesEn };
      const newGuidesDe: Record<string, any> = { ...guidesDe };
      let translatedCount = 0;
      
      // WICHTIG: Speichere NACH JEDEM Guide in DB (nicht am Ende!)
      // Grund: 60s Deno Timeout - bei 8 Guides würde es sonst abbrechen
      for (const key of missingKeys) {
        try {
          console.log(`📝 ${code} - ${key} [${translateDirection}]...`);
          
          let translatedGuide;
          if (translateDirection === 'de-to-en') {
            translatedGuide = await translateSingleGuide(guidesDe[key], 'de', 'en');
            newGuidesEn[key] = translatedGuide;
          } else {
            translatedGuide = await translateSingleGuide(guidesEn[key], 'en', 'de');
            newGuidesDe[key] = translatedGuide;
          }
          
          translatedCount++;
          console.log(`✅ ${code} - ${key} translated (${translatedCount}/${missingKeys.length})`);
          
          // SOFORT IN DB SPEICHERN (nach jedem Guide!)
          if (!dry_run) {
            try {
              const updateData: any = { updated_at: new Date().toISOString() };
              
              if (translateDirection === 'de-to-en') {
                updateData.repair_guides_en = newGuidesEn;
              } else {
                updateData.repair_guides_de = newGuidesDe;
              }
              
              const { error: updateError } = await supabase
                .from('automotive_knowledge')
                .update(updateData)
                .eq('id', entry.id);
              
              if (updateError) {
                console.error(`❌ Save failed:`, updateError.message);
              } else {
                console.log(`💾 ${code} - ${key} saved to DB`);
              }
            } catch (saveErr: any) {
              console.error(`❌ Save exception:`, saveErr.message);
            }
          }
        } catch (error: any) {
          console.error(`❌ ${code} - ${key} failed:`, error.message || error);
        }
      }
      
      // Summary
      if (translatedCount > 0) {
        console.log(`✅ ${code} complete: ${translatedCount}/${missingKeys.length} translations`);
        totalProcessed++;
        totalTranslated += translatedCount;
      }
    }
    
    // 3. Return Summary
    console.log(`\n✅ Translation complete!`);
    console.log(`📊 Processed: ${totalProcessed}/${entries.length} codes`);
    console.log(`📊 Translated: ${totalTranslated} guides`);
    
    return new Response(JSON.stringify({
      success: true,
      processed: totalProcessed,
      total: entries.length,
      guides_translated: totalTranslated
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('❌ translate-repair-guides error:', error);
    return new Response(JSON.stringify({ 
      error: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
})

/**
 * Übersetzt eine einzelne Reparaturanleitung (DE↔EN bidirektional)
 */
async function translateSingleGuide(guide: any, fromLang: string, toLang: string): Promise<any> {
  const langNames: Record<string, string> = {
    'de': 'German',
    'en': 'English'
  };
  
  const systemPrompt = `You are a professional translator for technical automotive repair guides. Translate EXACTLY and keep all technical details, structure, and clarity.`;
  
  const userPrompt = `Translate this ${langNames[fromLang]} repair guide to ${langNames[toLang]}. Keep the EXACT same JSON structure and field names. Keep all technical details and measurements.

${langNames[fromLang]} guide:
${JSON.stringify(guide, null, 2)}

Return ONLY the translated JSON - no additional text!`;
  
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
        content: systemPrompt
      }, {
        role: 'user',
        content: userPrompt
      }],
      temperature: 0.1,
      max_tokens: 4000,
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
 * Extrahiert Fehlercode aus topic string
 */
function extractCodeFromTopic(topic: string): string {
  const match = topic.match(/^([A-Z]\d{4})/);
  return match ? match[1] : topic;
}
