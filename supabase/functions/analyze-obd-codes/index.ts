import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { 
  structureContentWithGPT4, 
  createEmbedding, 
  saveFullKnowledgeToDatabase,
  mapErrorCodeToDiagnosis,
  mapKnowledgeToDiagnosis
} from './helper-functions.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ErrorCode {
  code: string
  readAt: string
}

interface DiagnosisStep {
  stepNumber: number
  title: string
  description: string
  warnings?: string[]
}

interface RepairStep {
  stepNumber: number
  title: string
  description: string
  difficulty?: string
  requiredTools?: string[]
  estimatedTime?: string
  warnings?: string[]
}

interface DiagnosisResult {
  code: string
  title: string
  description: string
  detailedAnalysis: string
  diagnosticSteps: DiagnosisStep[]
  repairSteps: RepairStep[]
  severity?: string
  driveSafety?: boolean
  immediateActionRequired?: boolean
  requiredTools?: string[]
  estimatedCost?: string
  estimatedTime?: string
  sourceType: 'database' | 'web_research' | 'llm_fallback'
  createdAt: string
}

interface StructuredKnowledge {
  title: string
  description: string
  detailedAnalysis: string
  symptoms: string[]
  causes: string[]
  diagnosticSteps: DiagnosisStep[]
  repairSteps: RepairStep[]
  toolsRequired: string[]
  estimatedCostEur: string
  difficultyLevel: 'easy' | 'medium' | 'hard' | 'expert'
  severity: 'low' | 'medium' | 'high' | 'critical'
  driveSafety: boolean
  immediateActionRequired: boolean
  keywords: string[]
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Get user from JWT
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user } } = await supabaseClient.auth.getUser(token)

    if (!user) {
      throw new Error('Unauthorized')
    }

    const { errorCodes, language = 'de' } = await req.json() as { errorCodes: ErrorCode[], language?: string }

    if (!errorCodes || errorCodes.length === 0) {
      throw new Error('No error codes provided')
    }

    console.log(`🔍 Analyzing ${errorCodes.length} error codes for user ${user.id}`)

    const results: DiagnosisResult[] = []

    // Analyze each error code
    for (const errorCode of errorCodes) {
      console.log(`📊 Processing code: ${errorCode.code}`)

      // 1. Try to find in automotive_knowledge via vector search
      let diagnosis = await searchKnowledgeBase(supabaseClient, errorCode.code, language)

      if (diagnosis) {
        console.log(`✅ Found in knowledge base: ${errorCode.code}`)
        results.push(diagnosis)
        continue
      }

      // 2. Not found - use Perplexity for web research (PRIMARY)
      console.log(`🌐 Searching web with Perplexity: ${errorCode.code}`)
      try {
        diagnosis = await researchWithPerplexityAndStructure(supabaseClient, errorCode.code, language)
        
        if (diagnosis) {
          console.log(`✅ Web research successful: ${errorCode.code}`)
          results.push(diagnosis)
          continue
        }
      } catch (perplexityError) {
        console.warn(`⚠️ Perplexity research failed for ${errorCode.code}:`, perplexityError)
      }

      // 3. Fallback - use LLM knowledge (ONLY if web research fails)
      console.log(`🤖 Fallback to LLM knowledge: ${errorCode.code}`)
      diagnosis = await generateLLMFallbackDiagnosis(errorCode.code, language)

      if (diagnosis) {
        await saveToKnowledgeBase(supabaseClient, errorCode.code, diagnosis, language)
        results.push(diagnosis)
      } else {
        console.error(`❌ Failed to generate diagnosis for: ${errorCode.code}`)
      }
    }

    return new Response(
      JSON.stringify({ results }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('❌ Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})

/**
 * Search automotive_knowledge database for error code
 */
async function searchKnowledgeBase(
  supabase: any,
  errorCode: string,
  language: string
): Promise<DiagnosisResult | null> {
  try {
    // First, try exact match in error_codes table
    const { data: errorData, error: errorError } = await supabase
      .from('error_codes')
      .select('*')
      .eq('code', errorCode)
      .single()

    if (errorData && !errorError) {
      console.log(`✅ Found exact match in error_codes table`)
      return mapErrorCodeToDiagnosis(errorData, language)
    }

    // If not found, search in automotive_knowledge via topic/keywords
    const { data: knowledgeData, error: knowledgeError } = await supabase
      .from('automotive_knowledge')
      .select('*')
      .contains('keywords', [errorCode])
      .limit(1)

    if (knowledgeData && knowledgeData.length > 0 && !knowledgeError) {
      console.log(`✅ Found in automotive_knowledge via keywords`)
      return mapKnowledgeToDiagnosis(knowledgeData[0], errorCode, language)
    }

    return null
  } catch (error) {
    console.error('❌ Knowledge base search error:', error)
    return null
  }
}

/**
 * Research with Perplexity Web Search (Model: sonar - $1/1M)
 * Then structure with GPT-4, create embedding, and save to DB
 */
async function researchWithPerplexityAndStructure(
  supabaseClient: any,
  errorCode: string,
  language: string
): Promise<DiagnosisResult | null> {
  const perplexityApiKey = Deno.env.get('PERPLEXITY_API_KEY')
  
  if (!perplexityApiKey) {
    throw new Error('No Perplexity API key - skipping web research')
  }

  // STEP 1: Perplexity Web Research (Raw Data)
  console.log(`  🔍 Step 1: Perplexity web search for ${errorCode}`)
  
  const searchPrompt = language === 'de'
    ? `Recherchiere ausführlich den OBD2-Fehlercode ${errorCode}. Nutze aktuelle Quellen von Reparaturportalen (z.B. repairpal.com, obd-codes.com, motor.de), Herstellerwebseiten und Fachforen.

Sammle Informationen zu:
- Beschreibung und technische Bedeutung des Fehlers
- Häufige Symptome die der Fahrer bemerkt
- Typische Ursachen (Bauteile, Sensoren, etc.)
- Wie man das Problem diagnostiziert (Schritt für Schritt)
- Wie man es repariert (Schritt für Schritt)
- Benötigte Werkzeuge, Schwierigkeitsgrad, geschätzte Kosten und Zeit
- Kann man mit diesem Fehler noch weiterfahren?`
    : `Research the OBD2 error code ${errorCode} thoroughly. Use current sources from repair portals (e.g., repairpal.com, obd-codes.com, yourmechanic.com), manufacturer websites, and expert forums.

Gather information about:
- Description and technical meaning of the error
- Common symptoms the driver notices
- Typical causes (components, sensors, etc.)
- How to diagnose the problem (step by step)
- How to repair it (step by step)
- Required tools, difficulty level, estimated costs and time
- Is it safe to drive with this error?`

  const perplexityResponse = await fetch('https://api.perplexity.ai/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${perplexityApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'sonar',
      messages: [
        {
          role: 'system',
          content: 'You are an automotive expert. Search the web for accurate, current information about car diagnostics and repairs. Provide detailed, comprehensive information.',
        },
        {
          role: 'user',
          content: searchPrompt,
        },
      ],
      temperature: 0.2,
      max_tokens: 2000,
    }),
  })

  if (!perplexityResponse.ok) {
    const errorText = await perplexityResponse.text()
    throw new Error(`Perplexity API error: ${perplexityResponse.statusText} - ${errorText}`)
  }

  const perplexityData = await perplexityResponse.json()
  const rawWebContent = perplexityData.choices[0]?.message?.content

  if (!rawWebContent) {
    throw new Error('No content from Perplexity')
  }

  console.log(`  ✅ Step 1 complete: Gathered ${rawWebContent.length} chars of web data`)

  // STEP 2: GPT-4 Structure the raw data
  console.log(`  🧠 Step 2: Structuring with GPT-4`)
  const structuredData = await structureContentWithGPT4(rawWebContent, errorCode, language)
  
  if (!structuredData) {
    throw new Error('Failed to structure content')
  }

  console.log(`  ✅ Step 2 complete: Content structured`)

  // STEP 3: Create embedding
  console.log(`  📊 Step 3: Creating embedding`)
  const embedding = await createEmbedding(
    `${structuredData.title} ${structuredData.description} ${structuredData.detailedAnalysis}`,
    language
  )

  if (!embedding) {
    throw new Error('Failed to create embedding')
  }

  console.log(`  ✅ Step 3 complete: Embedding created`)

  // STEP 4: Save to automotive_knowledge (full)
  console.log(`  💾 Step 4: Saving to database`)
  await saveFullKnowledgeToDatabase(supabaseClient, errorCode, structuredData, embedding, language)
  console.log(`  ✅ Step 4 complete: Saved to database`)

  // Return diagnosis result for user
  return {
    code: errorCode,
    title: structuredData.title,
    description: structuredData.description,
    detailedAnalysis: structuredData.detailedAnalysis,
    diagnosticSteps: structuredData.diagnosticSteps,
    repairSteps: structuredData.repairSteps,
    severity: structuredData.severity,
    driveSafety: structuredData.driveSafety,
    immediateActionRequired: structuredData.immediateActionRequired,
    requiredTools: structuredData.toolsRequired,
    estimatedCost: structuredData.estimatedCostEur,
    estimatedTime: structuredData.repairSteps[0]?.estimatedTime || 'Unbekannt',
    sourceType: 'web_research',
    createdAt: new Date().toISOString(),
  }
}

/**
 * LLM Fallback: Generate diagnosis using GPT-4o-mini (ONLY if web research fails)
 */
async function generateLLMFallbackDiagnosis(
  errorCode: string,
  language: string
): Promise<DiagnosisResult | null> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  
  if (!openaiApiKey) {
    console.warn('⚠️ No OpenAI API key - skipping AI generation')
    return null
  }

  try {
    const prompt = language === 'de'
      ? `Analysiere den OBD2-Fehlercode ${errorCode} für ein Fahrzeug. Der Code wurde bereits ausgelesen.

WICHTIG: 
- Die "description" soll eine kurze, einfache Erklärung sein (2-3 Sätze)
- Die "detailedAnalysis" soll eine ausführliche technische Analyse sein (deutlich länger und detaillierter als description)
- Die diagnosticSteps sollen NICHT "OBD2-Scanner anschließen" enthalten - der Code wurde bereits ausgelesen!
- Beginne die Diagnoseschritte direkt mit der eigentlichen Fehlersuche (z.B. Sichtprüfung, Messungen, Tests)

Gib folgende Informationen an:
1. Titel (kurz und prägnant)
2. Kurze Beschreibung des Problems (2-3 Sätze)
3. Ausführliche technische Analyse (mehrere Absätze mit Details zu Ursachen, Auswirkungen, betroffenen Systemen)
4. Diagnoseschritte zur Fehlereingrenzung - OHNE "Scanner anschließen" (mindestens 4 Schritte)
5. Reparaturanleitung (mindestens 4 Schritte)
6. Benötigte Werkzeuge (außer OBD2-Scanner)
7. Geschätzte Kosten und Dauer

Formatiere die Antwort als JSON:
{
  "title": "Kurzer prägnanter Titel",
  "description": "Kurze Erklärung in 2-3 Sätzen für Laien",
  "detailedAnalysis": "Ausführliche technische Analyse mit Details zu Ursachen, Symptomen, betroffenen Systemen und möglichen Folgeschäden. Mehrere Absätze.",
  "diagnosticSteps": [{"stepNumber": 1, "title": "Sichtprüfung durchführen", "description": "Detaillierte Anleitung", "warnings": ["Warnung falls nötig"]}],
  "repairSteps": [{"stepNumber": 1, "title": "Schritt Titel", "description": "Detaillierte Anleitung", "difficulty": "medium", "requiredTools": ["Werkzeug"], "estimatedTime": "30 Min", "warnings": ["Warnung"]}],
  "severity": "medium",
  "driveSafety": true,
  "immediateActionRequired": false,
  "requiredTools": ["Multimeter", "Schraubenschlüssel-Satz"],
  "estimatedCost": "50-200 €",
  "estimatedTime": "1-2 Stunden"
}`
      : `Analyze the OBD2 error code ${errorCode} for a vehicle. The code has already been read.

IMPORTANT: 
- The "description" should be a brief, simple explanation (2-3 sentences)
- The "detailedAnalysis" should be a comprehensive technical analysis (much longer and more detailed than description)
- The diagnosticSteps should NOT include "connect OBD2 scanner" - the code has already been read!
- Start diagnostic steps directly with actual troubleshooting (e.g., visual inspection, measurements, tests)

Provide:
1. Title (short and concise)
2. Brief problem description (2-3 sentences)
3. Comprehensive technical analysis (multiple paragraphs with details about causes, effects, affected systems)
4. Diagnostic steps for troubleshooting - WITHOUT "connect scanner" (minimum 4 steps)
5. Repair instructions (minimum 4 steps)
6. Required tools (excluding OBD2 scanner)
7. Estimated costs and duration

Format as JSON:
{
  "title": "Brief concise title",
  "description": "Short explanation in 2-3 sentences for laypeople",
  "detailedAnalysis": "Comprehensive technical analysis with details about causes, symptoms, affected systems and potential consequential damage. Multiple paragraphs.",
  "diagnosticSteps": [{"stepNumber": 1, "title": "Perform visual inspection", "description": "Detailed instructions", "warnings": ["Warning if needed"]}],
  "repairSteps": [{"stepNumber": 1, "title": "Step title", "description": "Detailed instructions", "difficulty": "medium", "requiredTools": ["Tool"], "estimatedTime": "30 min", "warnings": ["Warning"]}],
  "severity": "medium",
  "driveSafety": true,
  "immediateActionRequired": false,
  "requiredTools": ["Multimeter", "Wrench set"],
  "estimatedCost": "50-200 €",
  "estimatedTime": "1-2 hours"
}`

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content: 'You are an expert automotive diagnostic technician. Provide accurate, detailed, and safe repair information. Always respond with valid JSON only, no additional text.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.2,
        max_tokens: 2000,
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`OpenAI API error: ${response.statusText} - ${errorText}`)
    }

    const data = await response.json()
    const content = data.choices[0]?.message?.content

    if (!content) {
      throw new Error('No content in OpenAI response')
    }

    // Parse JSON response
    const jsonMatch = content.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      throw new Error('No JSON found in response')
    }

    const aiData = JSON.parse(jsonMatch[0])

    return {
      code: errorCode,
      title: aiData.title,
      description: aiData.description,
      detailedAnalysis: aiData.detailedAnalysis,
      diagnosticSteps: aiData.diagnosticSteps,
      repairSteps: aiData.repairSteps,
      severity: aiData.severity,
      driveSafety: aiData.driveSafety,
      immediateActionRequired: aiData.immediateActionRequired,
      requiredTools: aiData.requiredTools,
      estimatedCost: aiData.estimatedCost,
      estimatedTime: aiData.estimatedTime,
      sourceType: 'llm_fallback',
      createdAt: new Date().toISOString(),
    }
  } catch (error) {
    console.error('❌ AI generation error:', error)
    return null
  }
}

/**
 * Save AI-generated diagnosis to knowledge base
 */
async function saveToKnowledgeBase(
  supabase: any,
  errorCode: string,
  diagnosis: DiagnosisResult,
  language: string
): Promise<void> {
  try {
    // Insert into error_codes table
    const { error } = await supabase
      .from('error_codes')
      .upsert({
        code: errorCode,
        description_de: language === 'de' ? diagnosis.description : null,
        description_en: language === 'en' ? diagnosis.description : null,
        severity: diagnosis.severity,
        drive_safety: diagnosis.driveSafety,
        immediate_action_required: diagnosis.immediateActionRequired,
        typical_cost_range_eur: diagnosis.estimatedCost,
        diagnostic_steps: diagnosis.diagnosticSteps.map(s => s.description),
        repair_suggestions: diagnosis.repairSteps.map(s => s.description),
        is_generic: !errorCode.includes('1'), // P1xxx = manufacturer specific
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'code'
      })

    if (error) {
      console.error('❌ Error saving to knowledge base:', error)
    } else {
      console.log(`✅ Saved ${errorCode} to knowledge base`)
    }
  } catch (error) {
    console.error('❌ Save error:', error)
  }
}

/**
 * Create fallback diagnosis when nothing else works
 */
function createFallbackDiagnosis(errorCode: string): DiagnosisResult {
  const codeType = errorCode[0]
  let description = 'Unbekannter Fehlercode'

  if (codeType === 'P') {
    description = 'Fehlercode im Antriebsstrang-System'
  } else if (codeType === 'C') {
    description = 'Fehlercode im Fahrwerk-System'
  } else if (codeType === 'B') {
    description = 'Fehlercode im Karosserie-System'
  } else if (codeType === 'U') {
    description = 'Fehlercode im Netzwerk-System'
  }

  return {
    code: errorCode,
    title: `Fehlercode ${errorCode}`,
    description: description,
    detailedAnalysis: `Der Fehlercode ${errorCode} wurde erkannt. Für eine detaillierte Diagnose konsultieren Sie bitte einen Fachmann oder recherchieren Sie den spezifischen Code in einer Fahrzeug-Datenbank.`,
    diagnosticSteps: [
      { stepNumber: 1, title: 'Code verifizieren', description: 'Lesen Sie den Code erneut aus, um sicherzustellen, dass er korrekt ist.' },
      { stepNumber: 2, title: 'Online-Recherche', description: 'Suchen Sie nach dem spezifischen Code online für Ihr Fahrzeugmodell.' },
      { stepNumber: 3, title: 'Fachmann konsultieren', description: 'Wenden Sie sich an einen qualifizierten Mechaniker für eine professionelle Diagnose.' },
    ],
    repairSteps: [
      { stepNumber: 1, title: 'Werkstatt aufsuchen', description: 'Lassen Sie das Fahrzeug von einem Fachmann überprüfen.', difficulty: 'expert' },
    ],
    severity: 'medium',
    driveSafety: true,
    immediateActionRequired: false,
    requiredTools: ['OBD2-Scanner'],
    estimatedCost: 'Variabel',
    estimatedTime: 'Variabel',
    sourceType: 'ai_generated',
    createdAt: new Date().toISOString(),
  }
}
