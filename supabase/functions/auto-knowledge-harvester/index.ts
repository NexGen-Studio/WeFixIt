// ============================================================================
// Auto Knowledge Harvester - Web-Crawling + Multi-Language Translation
// ============================================================================
// Crawlt automatisch KFZ-Wissen aus dem Internet, übersetzt in 4 Sprachen,
// erstellt Embeddings und speichert alles in der Datenbank.
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY') || '';
const PERPLEXITY_API_KEY = Deno.env.get('PERPLEXITY_API_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

interface HarvestQueueItem {
  id: string;
  topic: string;
  search_language: string;
  category: string;
  priority: number;
  attempts?: number;
  status?: string;
  error_message?: string;
  last_attempt_at?: string;
}

interface KnowledgeArticle {
  topic: string;
  category: string;
  subcategory?: string;
  title_de?: string;
  title_en?: string;
  title_fr?: string;
  title_es?: string;
  content_de?: string;
  content_en?: string;
  content_fr?: string;
  content_es?: string;
  symptoms?: string[];
  causes?: string[];
  diagnostic_steps?: string[];
  repair_steps?: string[];
  tools_required?: string[];
  estimated_cost_eur?: number;
  difficulty_level?: string;
  keywords?: string[];
  original_language: string;
  quality_score: number;
}

Deno.serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Hole nächstes Thema aus der Queue
    const { data: queueItems, error: queueError } = await supabase
      .from('knowledge_harvest_queue')
      .select('*')
      .eq('status', 'pending')
      .order('priority', { ascending: false })
      .limit(1);

    if (queueError || !queueItems || queueItems.length === 0) {
      return new Response(JSON.stringify({ 
        message: 'No pending items in queue',
        error: queueError 
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      });
    }

    const item: HarvestQueueItem = queueItems[0];

    // 2. Status auf "processing" setzen
    await supabase
      .from('knowledge_harvest_queue')
      .update({ 
        status: 'processing',
        last_attempt_at: new Date().toISOString(),
        attempts: item.attempts ? item.attempts + 1 : 1
      })
      .eq('id', item.id);

    console.log(`Processing: ${item.topic} (${item.search_language})`);

    // 3. Web-Search via Perplexity.ai (native Web-Recherche!)
    const searchResponse = await fetch('https://api.perplexity.ai/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${PERPLEXITY_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'sonar-pro', // sonar-pro für beste Qualität, sonar für günstiger
        messages: [{
          role: 'system',
          content: `You are an automotive expert assistant. Research comprehensive automotive information from the web and create structured, helpful articles.

IMPORTANT:
- Use only legal, freely available sources
- Never copy content 1:1, always reformulate in your own words
- Structure information clearly
- Cite sources when possible
- Focus on practical, actionable information`
        }, {
          role: 'user',
          content: `Research comprehensive information about: "${item.topic}"
          
Erstelle einen strukturierten Artikel und antworte EXAKT in folgendem JSON-Format:

{
  "title": "Dein Titel hier",
  "content": "Ausführliche Beschreibung (mindestens 500 Wörter)",
  "symptoms": ["Symptom 1", "Symptom 2", "Symptom 3"],
  "causes": ["Ursache 1", "Ursache 2"],
  "diagnostic_steps": ["Schritt 1", "Schritt 2", "Schritt 3"],
  "repair_steps": ["Reparaturschritt 1", "Reparaturschritt 2"],
  "tools_required": ["Werkzeug 1", "Werkzeug 2"],
  "estimated_cost_eur": 150.00,
  "difficulty_level": "medium",
  "keywords": ["Keyword1", "Keyword2", "Keyword3"]
}

WICHTIG: Verwende genau diese Feldnamen!

Output ONLY valid JSON, no additional text.`
        }],
        temperature: 0.7,
        return_citations: true, // Perplexity: Quellenangaben zurückgeben
        return_images: false,
      })
    });

    if (!searchResponse.ok) {
      const errorText = await searchResponse.text();
      throw new Error(`Perplexity API error (${searchResponse.status}): ${errorText}`);
    }

    const searchData = await searchResponse.json();
    const responseText = searchData.choices[0].message.content;
    
    // Perplexity: Extrahiere JSON aus Response (manchmal mit Text drumherum)
    let originalContent;
    try {
      // Versuche direktes JSON-Parsing
      originalContent = JSON.parse(responseText);
    } catch (e) {
      // Falls Text drumherum ist, extrahiere JSON mit Regex
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        originalContent = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error(`Invalid JSON response from Perplexity: ${responseText.substring(0, 200)}`);
      }
    }
    
    // Perplexity: Extrahiere Quellen (citations)
    const sources = searchData.citations || [];
    console.log(`📚 Sources found: ${sources.length}`);

    console.log('=== DEBUG: Original Content ===');
    console.log(`Title: ${originalContent.title}`);
    console.log(`Content length: ${originalContent.content?.length || 0} chars`);
    console.log(`Symptoms: ${originalContent.symptoms?.length || 0}`);
    console.log(`Full JSON keys: ${Object.keys(originalContent).join(', ')}`);

    // Validierung: Title und Content müssen vorhanden sein
    if (!originalContent.title || !originalContent.content) {
      throw new Error(`Invalid response from Perplexity: Missing title or content. Keys: ${Object.keys(originalContent).join(', ')}`);
    }

    console.log(`✅ Original content harvested: ${originalContent.title}`);
    console.log(`📰 Sources: ${sources.join(', ')}`);

    // 4. Übersetzung in andere Sprachen (falls nicht bereits in Zielsprache)
    const targetLanguages = ['de', 'en', 'fr', 'es'];
    const translations: any = {};

    for (const lang of targetLanguages) {
      if (lang === item.search_language) {
        // Original-Sprache: direkt übernehmen
        translations[lang] = {
          title: originalContent.title,
          content: originalContent.content
        };
      } else {
        // Übersetzen
        console.log(`Translating to ${lang}...`);
        
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
              content: `Du bist ein professioneller Übersetzer für KFZ-Fachterminologie. Übersetze präzise und behalte Fachbegriffe bei.`
            }, {
              role: 'user',
              content: `Übersetze folgenden Text nach ${lang === 'de' ? 'Deutsch' : lang === 'fr' ? 'Französisch' : lang === 'es' ? 'Spanisch' : 'Englisch'}:

Titel: ${originalContent.title}

Inhalt: ${originalContent.content}

Antworte im JSON-Format mit: {"title": "...", "content": "..."}`
            }],
            response_format: { type: "json_object" },
            temperature: 0.3,
          })
        });

        if (translateResponse.ok) {
          const translateData = await translateResponse.json();
          translations[lang] = JSON.parse(translateData.choices[0].message.content);
        } else {
          console.warn(`Translation to ${lang} failed, using original`);
          translations[lang] = {
            title: originalContent.title,
            content: originalContent.content
          };
        }
      }
    }

    // 5. Embeddings erstellen (pro Sprache)
    const embeddings: any = {};
    
    for (const lang of targetLanguages) {
      const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'text-embedding-3-small',
          input: `${translations[lang].title}\n\n${translations[lang].content}`,
        })
      });

      if (embeddingResponse.ok) {
        const embeddingData = await embeddingResponse.json();
        embeddings[lang] = embeddingData.data[0].embedding;
        console.log(`Embedding created for ${lang}`);
      }
    }

    // 6. DUPLIKAT-CHECK: Prüfe ob Topic schon existiert
    const { data: existingArticle } = await supabase
      .from('automotive_knowledge')
      .select('id, topic')
      .eq('topic', item.topic)
      .single();

    if (existingArticle) {
      console.log(`⚠️ Artikel bereits vorhanden: ${item.topic} (ID: ${existingArticle.id})`);
      
      // Queue-Item trotzdem auf completed setzen
      await supabase
        .from('knowledge_harvest_queue')
        .update({ status: 'completed' })
        .eq('id', item.id);
      
      return new Response(JSON.stringify({ 
        success: true,
        skipped: true,
        reason: 'Article already exists',
        topic: item.topic
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      });
    }

    // 7. NULL-SCHUTZ: Validiere alle Felder, setze Fallbacks
    const safeTitle = (translations.de?.title || translations.en?.title || item.topic).substring(0, 200);
    const safeContent = translations.de?.content || translations.en?.content || 'No content available';
    
    if (!safeTitle || safeTitle === 'undefined') {
      throw new Error(`Invalid title for topic: ${item.topic}`);
    }

    // 8. In Datenbank speichern
    const article: KnowledgeArticle = {
      topic: item.topic,
      category: item.category,
      subcategory: originalContent.subcategory || null,
      
      // Titel mit Fallback (niemals NULL!)
      title_de: translations.de?.title || safeTitle,
      title_en: translations.en?.title || safeTitle,
      title_fr: translations.fr?.title || safeTitle,
      title_es: translations.es?.title || safeTitle,
      
      // Content mit Fallback (niemals NULL!)
      content_de: translations.de?.content || safeContent,
      content_en: translations.en?.content || safeContent,
      content_fr: translations.fr?.content || safeContent,
      content_es: translations.es?.content || safeContent,
      
      // Arrays (immer leer statt NULL)
      symptoms: Array.isArray(originalContent.symptoms) ? originalContent.symptoms : [],
      causes: Array.isArray(originalContent.causes) ? originalContent.causes : [],
      diagnostic_steps: Array.isArray(originalContent.diagnostic_steps) ? originalContent.diagnostic_steps : [],
      repair_steps: Array.isArray(originalContent.repair_steps) ? originalContent.repair_steps : [],
      tools_required: Array.isArray(originalContent.tools_required) ? originalContent.tools_required : [],
      
      // Numerische Felder
      estimated_cost_eur: originalContent.estimated_cost_eur || null,
      difficulty_level: originalContent.difficulty_level || 'medium',
      
      // Metadaten
      keywords: Array.isArray(originalContent.keywords) ? originalContent.keywords : [],
      original_language: item.search_language,
      source_urls: sources.length > 0 ? sources : null, // Perplexity Citations!
      quality_score: 0.85,
    };

    console.log('=== FINAL VALIDATION ===');
    console.log(`Title DE: ${article.title_de?.substring(0, 50)}...`);
    console.log(`Title EN: ${article.title_en?.substring(0, 50)}...`);
    console.log(`Content DE length: ${article.content_de?.length || 0}`);
    console.log(`Content EN length: ${article.content_en?.length || 0}`);

    const { error: insertError } = await supabase
      .from('automotive_knowledge')
      .insert({
        ...article,
        embedding_de: embeddings.de,
        embedding_en: embeddings.en,
        embedding_fr: embeddings.fr,
        embedding_es: embeddings.es,
      });

    if (insertError) {
      throw insertError;
    }

    // 7. Queue-Item auf "completed" setzen
    await supabase
      .from('knowledge_harvest_queue')
      .update({ status: 'completed' })
      .eq('id', item.id);

    console.log(`✅ Successfully harvested: ${item.topic}`);

    return new Response(JSON.stringify({ 
      success: true,
      topic: item.topic,
      translations: Object.keys(translations),
      embeddings: Object.keys(embeddings)
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    });

  } catch (error) {
    console.error('❌ Harvester error:', error);
    
    // Queue-Item mit Retry-Logik behandeln
    try {
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
      const { data: queueItems } = await supabase
        .from('knowledge_harvest_queue')
        .select('*')
        .eq('status', 'processing')
        .order('last_attempt_at', { ascending: false })
        .limit(1);
      
      if (queueItems && queueItems.length > 0) {
        const item = queueItems[0];
        const attempts = item.attempts || 0;
        const maxRetries = 3;
        
        // Bestimme Error-Code
        let errorCode = '500';
        let errorMessage = error.message || 'Unknown error';
        
        if (error.message?.includes('timeout') || error.message?.includes('504')) {
          errorCode = '504';
        } else if (error.message?.includes('502')) {
          errorCode = '502';
        } else if (error.message?.includes('546')) {
          errorCode = '546';
        }
        
        if (attempts < maxRetries) {
          // Retry: Zurück auf "pending" setzen
          console.log(`⚠️ Retry ${attempts + 1}/${maxRetries} für: ${item.topic}`);
          await supabase
            .from('knowledge_harvest_queue')
            .update({ 
              status: 'pending',
              error_message: errorMessage,
              attempts: attempts + 1
            })
            .eq('id', item.id);
        } else {
          // Max retries erreicht: Failed Topics speichern
          console.log(`❌ Max retries erreicht für: ${item.topic}`);
          
          // In failed_topics speichern
          await supabase
            .from('failed_topics')
            .insert({
              topic: item.topic,
              error_code: errorCode,
              error_message: errorMessage,
              retry_count: attempts,
              status: 'failed'
            });
          
          // Queue-Item als "failed" markieren
          await supabase
            .from('knowledge_harvest_queue')
            .update({ 
              status: 'failed',
              error_message: `Failed after ${attempts} attempts: ${errorMessage}`
            })
            .eq('id', item.id);
        }
      }
    } catch (updateError) {
      console.error('Failed to update queue status:', updateError);
    }
    
    return new Response(JSON.stringify({ 
      success: false,
      error: error.message,
      retry: true
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/auto-knowledge-harvester' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
