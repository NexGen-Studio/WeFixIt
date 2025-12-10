// ============================================================================
// Chat Completion - Ask Toni! mit RAG (Retrieval Augmented Generation)
// ============================================================================
// Verwendet Vector Similarity Search um relevante KFZ-Infos zu finden,
// und generiert dann präzise Antworten basierend auf der Wissensdatenbank.
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ChatRequest {
  message: string;
  language?: string; // 'de', 'en', 'fr', 'es'
  userId?: string;
  conversationHistory?: Array<{role: string, content: string}>;
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { message, language = 'de', userId, conversationHistory = [] }: ChatRequest = await req.json();

    if (!message) {
      return new Response(JSON.stringify({ error: 'Message is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      });
    }

    console.log(`Chat request: "${message}" (lang: ${language})`);

    // 1. User-Message in Embedding umwandeln
    const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'text-embedding-3-small',
        input: message,
      })
    });

    if (!embeddingResponse.ok) {
      throw new Error('Failed to create embedding');
    }

    const embeddingData = await embeddingResponse.json();
    const queryEmbedding = embeddingData.data[0].embedding;

    // 2. Vector Similarity Search (RAG)
    const { data: relevantDocs, error: searchError } = await supabase
      .rpc(`match_documents_${language}`, {
        query_embedding: queryEmbedding,
        match_threshold: 0.70, // Gesenkt von 0.75 auf 0.70 für mehr Treffer
        match_count: 5
      });

    if (searchError) {
      console.error('❌ Vector search error:', searchError);
    }

    console.log(`🔍 Vector Search Results:`);
    console.log(`  - Language: ${language}`);
    console.log(`  - Function called: match_documents_${language}`);
    console.log(`  - Documents found: ${relevantDocs?.length || 0}`);
    
    if (relevantDocs && relevantDocs.length > 0) {
      relevantDocs.forEach((doc: any, idx: number) => {
        console.log(`  - Doc ${idx + 1}: ${doc.title} (similarity: ${(doc.similarity * 100).toFixed(1)}%)`);
      });
    } else {
      console.log(`  ⚠️ No documents found above threshold 0.70`);
    }

    // 3. OBD2-Fehlercode Check
    let errorCodeInfo = null;
    const obd2Pattern = /[PCBU]\d{4}/gi;
    const codes = message.match(obd2Pattern);
    
    if (codes && codes.length > 0) {
      console.log(`Detected error codes: ${codes.join(', ')}`);
      
      const { data: errorCodes } = await supabase
        .from('error_codes')
        .select('*')
        .in('code', codes.map(c => c.toUpperCase()));
      
      if (errorCodes && errorCodes.length > 0) {
        errorCodeInfo = errorCodes;
      }
    }

    // 4. Kontext für GPT aufbauen
    let contextText = '';
    
    if (relevantDocs && relevantDocs.length > 0) {
      contextText += '=== WISSENSDATENBANK ===\n\n';
      relevantDocs.forEach((doc: any, idx: number) => {
        contextText += `[Dokument ${idx + 1}]\n`;
        contextText += `Titel: ${doc.title}\n`;
        contextText += `Kategorie: ${doc.category}\n`;
        contextText += `Inhalt: ${doc.content}\n`;
        contextText += `Relevanz: ${(doc.similarity * 100).toFixed(1)}%\n\n`;
      });
    }

    if (errorCodeInfo && errorCodeInfo.length > 0) {
      contextText += '=== FEHLERCODES ===\n\n';
      errorCodeInfo.forEach((code: any) => {
        const descKey = `description_${language}`;
        contextText += `Code: ${code.code}\n`;
        contextText += `Beschreibung: ${code[descKey] || code.description_en}\n`;
        contextText += `Schweregrad: ${code.severity}\n`;
        contextText += `Fahrsicherheit: ${code.drive_safety ? 'Ja' : 'Nein, NICHT weiterfahren!'}\n`;
        if (code.symptoms) contextText += `Symptome: ${code.symptoms.join(', ')}\n`;
        if (code.common_causes) contextText += `Häufige Ursachen: ${code.common_causes.join(', ')}\n`;
        if (code.diagnostic_steps) contextText += `Diagnose: ${code.diagnostic_steps.join('; ')}\n`;
        contextText += '\n';
      });
    }

    // 5. Hybrid-Modus: DB-Wissen + allgemeines KI-Wissen
    const hasDbKnowledge = relevantDocs && relevantDocs.length > 0;
    const hasErrorCodeInfo = errorCodeInfo && errorCodeInfo.length > 0;
    
    let knowledgeSource = 'hybrid'; // 'database', 'general', oder 'hybrid'
    
    if (!hasDbKnowledge && !hasErrorCodeInfo) {
      knowledgeSource = 'general';
      contextText = '⚠️ KEINE DATEN IN DATENBANK GEFUNDEN - Nutze allgemeines Automotive-Wissen';
    } else if (hasDbKnowledge || hasErrorCodeInfo) {
      knowledgeSource = 'hybrid';
      // Context ist bereits gefüllt
    }

    // 6. System-Prompt für Toni (Hybrid-Modus!)
    const systemPrompt = `Du bist Toni, der freundliche KFZ-Assistent von WeFixIt! 🚗

DEINE PERSÖNLICHKEIT:
- Freundlich, hilfsbereit und geduldig
- Erkläre komplexe Dinge einfach und verständlich
- Nutze Emojis sparsam aber passend (🔧, ⚠️, ✅, 🚗)
- Bleib professionell aber nicht steif

🎯 HYBRID-WISSENS-MODUS:
Du hast Zugriff auf ZWEI Wissensquellen:
1. **Unsere Datenbank** (spezialisierte, kuratierte KFZ-Infos) → BEVORZUGE DIESE!
2. **Dein allgemeines Wissen** (GPT-Training bis 2023) → Als ERGÄNZUNG

WICHTIGE REGELN:
✅ Wenn Datenbank-Infos vorhanden → PRIORISIERE DIESE und erwähne es ("Laut unserer Datenbank...")
✅ Wenn KEINE DB-Infos → Nutze allgemeines Wissen, aber sage es klar ("Basierend auf allgemeinem KFZ-Wissen...")
✅ KOMBINIERE BEIDES wenn sinnvoll: "Unsere Datenbank zeigt... Generell gilt auch..."
❌ DU DARFST NIEMALS sagen "Ich habe keine Informationen" - du hast IMMER Wissen!
❌ Erfinde KEINE Daten, wenn nicht sicher

DEINE AUFGABEN:
- Beantworte JEDE KFZ-Frage (Reparatur, Diagnose, Wartung, Codes)
- Gib praktische, umsetzbare Ratschläge
- Weise auf Sicherheitsrisiken hin (⚠️)
- **WICHTIG:** Empfehle NICHT die Werkstatt, sondern die **Diagnose-Funktion in der WeFixIt-App**!
- Sage z.B.: "Nutze die Diagnose-Funktion in der App, um professionelle Fehleranalyse zu erhalten"

FORMAT:
- Antworte auf ${language === 'de' ? 'Deutsch' : language === 'fr' ? 'Französisch' : language === 'es' ? 'Spanisch' : 'Englisch'}
- Strukturiere mit Überschriften (###) und Listen (-)
- Bei Fehlercodes: Ursachen, Symptome, Lösungen
- Bei Reparaturen: Schritt-für-Schritt + Schwierigkeitsgrad + Kosten

=== KONTEXT AUS UNSERER DATENBANK ===
${contextText}

AKTUELLE WISSENSQUELLE: ${knowledgeSource}
${knowledgeSource === 'general' ? '⚠️ Keine DB-Einträge gefunden - Nutze allgemeines Automotive-Wissen!' : ''}
${knowledgeSource === 'hybrid' ? '✅ DB-Wissen vorhanden - Kombiniere mit allgemeinem Wissen wenn hilfreich!' : ''}
`;

    // 6. Chat-Anfrage an OpenAI
    const messages = [
      { role: 'system', content: systemPrompt },
      ...conversationHistory.slice(-10), // Letzte 10 Nachrichten
      { role: 'user', content: message }
    ];

    const chatResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: messages,
        temperature: 0.7,
        max_tokens: 1000,
      })
    });

    if (!chatResponse.ok) {
      throw new Error(`OpenAI API error: ${chatResponse.statusText}`);
    }

    const chatData = await chatResponse.json();
    const reply = chatData.choices[0].message.content;

    // 7. Response zurück an App
    return new Response(JSON.stringify({ 
      success: true,
      reply: reply,
      sources: relevantDocs?.length || 0,
      errorCodes: errorCodeInfo?.length || 0,
      knowledgeSource: knowledgeSource, // 'hybrid', 'general', oder 'database'
      usage: chatData.usage
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    });

  } catch (error) {
    console.error('Chat completion error:', error);
    
    return new Response(JSON.stringify({ 
      success: false,
      error: error.message,
      reply: 'Entschuldigung, es gab ein Problem. Bitte versuche es später erneut.'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/chat-completion' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
