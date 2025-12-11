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
  vehicleContext?: {
    make?: string;
    model?: string;
    year?: number;
    engine?: string;
    mileage?: number;
    vin?: string;
    power_kw?: number;
    displacement_cc?: number;
  };
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { message, language = 'de', userId, conversationHistory = [], vehicleContext }: ChatRequest = await req.json();

    if (!message) {
      return new Response(JSON.stringify({ error: 'Message is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      });
    }

    console.log(`Chat request: "${message}" (lang: ${language})`);

    // 0. Pre-Check: Ist die Frage KFZ-bezogen?
    const topicCheckResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: `Du bist ein Themen-Klassifizierer. Prüfe ob die folgende Frage mit Fahrzeugen, Autos, KFZ, Reparaturen, Wartung oder Automobilthemen zu tun hat.
            
Antworte NUR mit "YES" oder "NO".

YES = Frage ist KFZ-bezogen (z.B. Ölwechsel, Fehlercodes, Reparaturen, Fahrzeugmodelle, Wartung, Diagnose, Reifen, Bremsen, etc.)
NO = Frage ist NICHT KFZ-bezogen (z.B. Wetter, Kochen, Fußboden, allgemeine Wissensfragen, etc.)`
          },
          { role: 'user', content: message }
        ],
        temperature: 0,
        max_tokens: 5
      })
    });

    if (!topicCheckResponse.ok) {
      console.error('Topic check failed, proceeding anyway');
    } else {
      const topicCheckData = await topicCheckResponse.json();
      const isCarRelated = topicCheckData.choices[0]?.message?.content?.trim().toUpperCase() === 'YES';
      
      console.log(`🔍 Topic check: ${isCarRelated ? 'YES (KFZ-bezogen)' : 'NO (off-topic)'}`);
      
      if (!isCarRelated) {
        // Freundliche Ablehnung
        const offTopicResponses = {
          de: `Es scheint, dass du nach Informationen zum ${message.includes('Wetter') ? 'Wetter' : message.includes('Fußboden') || message.includes('reinig') ? 'Reinigen' : message.includes('Vorhang') ? 'Aufhängen eines Vorhangs' : 'etwas anderem'} suchst. Leider kann ich dir dabei nicht direkt helfen, da ich auf KFZ-Themen spezialisiert bin. 😊

Wenn du Fragen rund ums Auto, Reparaturen, Wartung oder Diagnose hast, stehe ich dir jedoch gerne zur Verfügung! 🚗🔧

Falls du dennoch Unterstützung beim ${message.includes('Wetter') ? 'Wetter' : message.includes('Fußboden') || message.includes('reinig') ? 'Reinigen' : message.includes('Vorhang') ? 'Aufhängen' : 'Thema'} benötigst, empfehle ich dir, einen Experten zu Rate zu ziehen oder eine Anleitung online zu suchen. 🏠`,
          en: `It seems like you're asking about ${message.toLowerCase().includes('weather') ? 'the weather' : message.toLowerCase().includes('floor') || message.toLowerCase().includes('clean') ? 'cleaning' : 'something else'}. Unfortunately, I can't directly help with that, as I'm specialized in automotive topics. 😊

If you have questions about cars, repairs, maintenance, or diagnostics, I'm happy to assist! 🚗🔧

If you still need help with ${message.toLowerCase().includes('weather') ? 'weather' : message.toLowerCase().includes('floor') || message.toLowerCase().includes('clean') ? 'cleaning' : 'this topic'}, I recommend consulting an expert or finding a guide online. 🏠`,
          fr: `Il semble que tu cherches des informations sur ${message.toLowerCase().includes('météo') ? 'la météo' : message.toLowerCase().includes('sol') || message.toLowerCase().includes('nettoy') ? 'le nettoyage' : 'autre chose'}. Malheureusement, je ne peux pas t'aider directement, car je suis spécialisé dans les thèmes automobiles. 😊

Si tu as des questions sur les voitures, les réparations, l'entretien ou le diagnostic, je suis là pour t'aider! 🚗🔧`,
          es: `Parece que buscas información sobre ${message.toLowerCase().includes('tiempo') ? 'el tiempo' : message.toLowerCase().includes('suelo') || message.toLowerCase().includes('limpi') ? 'la limpieza' : 'otra cosa'}. Lamentablemente, no puedo ayudarte directamente, ya que estoy especializado en temas automotrices. 😊

Si tienes preguntas sobre autos, reparaciones, mantenimiento o diagnósticos, ¡estoy aquí para ayudarte! 🚗🔧`
        };
        
        const offTopicReply = offTopicResponses[language as keyof typeof offTopicResponses] || offTopicResponses.de;
        
        return new Response(JSON.stringify({ 
          success: true,
          reply: offTopicReply,
          sources: 0,
          errorCodes: 0,
          knowledgeSource: 'off-topic',
          isOffTopic: true 
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }

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

    // 6. Fahrzeugkontext (falls vorhanden)
    let vehicleInfo = '';
    if (vehicleContext && (vehicleContext.make || vehicleContext.model)) {
      vehicleInfo = `\n\n=== FAHRZEUG DES NUTZERS ===\n`;
      if (vehicleContext.make) vehicleInfo += `Marke: ${vehicleContext.make}\n`;
      if (vehicleContext.model) vehicleInfo += `Modell: ${vehicleContext.model}\n`;
      if (vehicleContext.year) vehicleInfo += `Baujahr: ${vehicleContext.year}\n`;
      if (vehicleContext.engine) vehicleInfo += `Motorcode: ${vehicleContext.engine}\n`;
      if (vehicleContext.displacement_cc) vehicleInfo += `Hubraum: ${vehicleContext.displacement_cc} ccm\n`;
      if (vehicleContext.power_kw) vehicleInfo += `Leistung: ${vehicleContext.power_kw} kW (${Math.round(vehicleContext.power_kw * 1.36)} PS)\n`;
      if (vehicleContext.mileage) vehicleInfo += `Kilometerstand: ${vehicleContext.mileage} km\n`;
      if (vehicleContext.vin) vehicleInfo += `FIN/VIN: ${vehicleContext.vin}\n`;
      vehicleInfo += '\n⚠️ WICHTIG: Berücksichtige IMMER diese Fahrzeugdaten bei deinen Antworten!\nGib spezifische Ratschläge die zu diesem Fahrzeug passen (z.B. passende Ölsorte, typische Probleme dieses Modells, spezifische Wartungsintervalle).';
    }

    // 7. System-Prompt für Toni (Hybrid-Modus!)
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

🔧 GENAUIGKEIT & DETAILS:
- **Positionsangaben:** Erkläre IMMER wo Teile zu finden sind (z.B. "unter der Motorhaube links", "hinter dem Stoßfänger rechts", "unter dem Fahrzeug mittig")
- **Werkzeug:** Nenne benötigtes Werkzeug konkret (z.B. "17mm Ringschlüssel", "Torx T30")
- **Zeitaufwand:** Gib realistische Zeitschätzung (z.B. "30-45 Minuten")
- **Schwierigkeit:** Bewerte Schwierigkeitsgrad (Einfach / Mittel / Schwierig)

💰 KOSTEN & ERSPARNIS:
- **Materialkosten:** Gib IMMER eine realistische Preisspanne an (z.B. "50-100 Euro")
- **Werkstattkosten:** Schätze die Werkstattkosten inklusive Arbeitszeit (z.B. "Werkstatt: 200-300 Euro")
- **ERSPARNIS:** Berechne und zeige EXPLIZIT die Ersparnis bei DIY!
  Beispiel: "💰 Ersparnis gegenüber Werkstatt: ca. 150-200 Euro (Material + eigene Arbeitszeit)"
- Format: "**Kosten:** ca. X-Y Euro (Material) | Werkstatt: Z Euro | **Ersparnis: ~A Euro**"

FORMAT:
- Antworte auf ${language === 'de' ? 'Deutsch' : language === 'fr' ? 'Französisch' : language === 'es' ? 'Spanisch' : 'Englisch'}
- Strukturiere mit Überschriften (###) und Listen (-)
- Bei Fehlercodes: Ursachen, Symptome, Lösungen
- Bei Reparaturen: Schritt-für-Schritt + Position + Werkzeug + Zeit + Kosten + Ersparnis

=== KONTEXT AUS UNSERER DATENBANK ===
${contextText}
${vehicleInfo}

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
