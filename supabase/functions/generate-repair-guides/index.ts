import { createClient } from 'jsr:@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!

Deno.serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  try {
    const { code, cause_key, cause_title, language = 'de' } = await req.json()
    
    if (!code || !cause_key || !cause_title) {
      return new Response(JSON.stringify({
        error: 'Missing required fields: code, cause_key, cause_title'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    console.log(`🔧 Generating repair guide for ${code} - ${cause_title} [${language.toUpperCase()}]`);
    
    // 1. Lade Entry aus DB
    const columnName = language === 'en' ? 'repair_guides_en' : 'repair_guides_de';
    const { data: entry, error: fetchError } = await supabase
      .from('automotive_knowledge')
      .select(`id, ${columnName}`)
      .eq('topic', `${code} OBD2 diagnostic trouble code`)
      .maybeSingle();
    
    if (fetchError) {
      throw fetchError;
    }
    
    if (!entry) {
      return new Response(JSON.stringify({
        error: `No entry found for code ${code}`
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const existingGuides = entry[columnName] || {};
    
    // 2. Prüfe ob bereits vorhanden
    if (existingGuides[cause_key]) {
      console.log(`⏭️  Guide already exists for ${code} - ${cause_key}`);
      return new Response(JSON.stringify({
        success: true,
        message: 'Guide already exists',
        guide: existingGuides[cause_key]
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // 3. Generiere Guide
    console.log(`📝 Generating new guide for ${code} - ${cause_title} [${language.toUpperCase()}]`);
    const guide = await generateSingleCauseRepairGuide(code, cause_title, language);
    
    if (!guide) {
      throw new Error('Failed to generate guide');
    }
    
    // 4. Update DB
    const updatedGuides = {
      ...existingGuides,
      [cause_key]: guide
    };
    
    const updateData: any = {};
    updateData[columnName] = updatedGuides;
    
    const { error: updateError } = await supabase
      .from('automotive_knowledge')
      .update(updateData)
      .eq('id', entry.id);
    
    if (updateError) {
      throw updateError;
    }
    
    console.log(`✅ Generated and saved guide for ${code} - ${cause_key}`);
    
    return new Response(JSON.stringify({
      success: true,
      guide
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('❌ generate-repair-guides error:', error);
    return new Response(JSON.stringify({ 
      error: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
})

/**
 * Generiert eine Reparaturanleitung für EINE EINZELNE Ursache
 */
async function generateSingleCauseRepairGuide(code: string, causeTitle: string, language: string = 'de'): Promise<any> {
  const isEnglish = language === 'en';
  const systemPrompt = isEnglish 
    ? 'You are an experienced automotive master technician. Create EXTREMELY DETAILED step-by-step instructions for absolute beginners.'
    : 'Du bist ein erfahrener KFZ-Meister. Erstelle EXTREM DETAILLIERTE Schritt-für-Schritt Anleitungen für absolute Anfänger.';
  
  const userPrompt = isEnglish 
    ? `Create a VERY DETAILED repair guide for:
- Error code: ${code}
- Cause: ${causeTitle}

Create 10-20 very easy to understand steps. EACH step needs:
- Clear title
- VERY detailed description (3-5 sentences, explain WHERE, WHAT, HOW, WHY)
- Required tools
- Duration in minutes
- Safety warnings if relevant

🚨 EXTREMELY IMPORTANT - CORRECT PART POSITIONS:
- Catalytic converter/Exhaust system: ALWAYS under the vehicle (NEVER in engine bay!)
- Lambda sensor: On exhaust pipe under vehicle (before/after catalytic converter)
- Mass air flow sensor: In intake tract between air filter and throttle body
- Throttle body: On intake manifold in engine bay
- Camshaft sensor: On camshaft in engine bay (usually top of engine)
- Crankshaft sensor: Bottom of engine near flywheel
- Fuel pump: In fuel tank (often accessible under rear seat)
- Turbocharger: In engine bay on exhaust system
- EGR valve: On engine in area of intake manifold
- DPF (Diesel Particulate Filter): In exhaust system under vehicle
- Describe EXACT position (left/right of engine, top/bottom, front/rear)
- Use reference points (e.g., "on driver side", "near wheel well", "behind engine")

🚨 EXTREMELY IMPORTANT - OBD2 READING:
- The user HAS ALREADY read the error code - that's why they know it!
- NEVER "Connect OBD2 diagnostic tool" in first steps!
- NEVER "Read error code" at the beginning!
- The guide begins DIRECTLY with the repair (Step 1)
- Steps 1-10+: ONLY repair steps (turn off engine, open hood, remove part, etc.)
- ONLY THE VERY LAST STEP: "Clear error code and verify repair"
- The last step must be:
  "Clear error code and verify repair: Connect the OBD2 diagnostic tool, clear the error code and read it again to verify if the repair was successful."

🚨 IMPORTANT - NO REFERENCES:
- NEVER write numbers in square brackets like [1], [2], [3], [4], [5], [6], [7] etc.
- NO source references or footnotes in text!
- Write flowing text WITHOUT any reference markers!
- Example WRONG: "Clean sensor[1][2][3]" 
- Example RIGHT: "Clean sensor"

JSON format:
{
  "cause_title": "${causeTitle}",
  "difficulty_level": "easy|medium|hard",
  "estimated_time_hours": 2.0,
  "estimated_cost_eur": [100, 300],
  "for_beginners": true,
  "steps": [
    {
      "step": 1,
      "title": "Step title",
      "description": "VERY DETAILED description (3-5 sentences)",
      "duration_minutes": 10,
      "safety_warning": "If relevant",
      "tools": ["List"],
      "tips": "Helpful tips"
    }
  ],
  "tools_required": ["Complete tool list"],
  "safety_warnings": ["All safety warnings"],
  "when_to_call_mechanic": ["When to go to workshop"]
}

ONLY output JSON!`
    : `Erstelle eine SEHR DETAILLIERTE Reparaturanleitung für:
- Fehlercode: ${code}
- Ursache: ${causeTitle}

Erstelle 10-20 kinderleicht verständliche Schritte. JEDER Schritt braucht:
- Klaren Titel
- SEHR ausführliche Beschreibung (3-5 Sätze, erkläre WO, WAS, WIE, WARUM)
- Benötigte Werkzeuge
- Dauer in Minuten
- Sicherheitshinweise falls relevant

🚨 EXTREM WICHTIG - KORREKTE BAUTEIL-POSITIONEN:
- Katalysator/Abgasanlage: IMMER unter dem Fahrzeug (NIEMALS im Motorraum!)
- Lambdasonde: Am Abgasstrang unter dem Fahrzeug (vor/nach Katalysator)
- Luftmassenmesser: Im Ansaugtrakt zwischen Luftfilter und Drosselklappe
- Drosselklappe: Am Ansaugkrümmer im Motorraum
- Nockenwellensensor: An der Nockenwelle im Motorraum (meist oben am Motor)
- Kurbelwellensensor: Unten am Motor nahe Schwungrad
- Kraftstoffpumpe: Im Kraftstofftank (oft unter Rücksitzbank zugänglich)
- Turbolader: Im Motorraum an der Abgasanlage
- AGR-Ventil: Am Motor im Bereich des Ansaugkrümmers
- DPF (Dieselpartikelfilter): In der Abgasanlage unter dem Fahrzeug
- Beschreibe EXAKTE Position (links/rechts vom Motor, oben/unten, vorne/hinten)
- Nutze Orientierungspunkte (z.B. "auf Fahrerseite", "nahe Radkasten", "hinter Motor")

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

NUR JSON ausgeben!`;
  
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
      temperature: 0.3,
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
  
  const parsed = JSON.parse(content);
  console.log(`📊 Generated ${parsed.steps?.length || 0} steps`);
  return parsed;
}
