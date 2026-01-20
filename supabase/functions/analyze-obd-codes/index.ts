import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { 
  structureContentWithGPT4, 
  createEmbedding, 
  saveFullKnowledgeToDatabase,
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
    const backgroundTasks: Promise<void>[] = []

    // Analyze each error code
    for (const errorCode of errorCodes) {
      console.log(`📊 Processing code: ${errorCode.code}`)

      // 1. Try to find in automotive_knowledge
      const knowledgeResult = await searchKnowledgeBase(supabaseClient, errorCode.code, language)

      // SZENARIO C: Alles in DB vorhanden
      if (knowledgeResult && knowledgeResult.hasGuide === true) {
        console.log(`✅ SZENARIO C: ${errorCode.code} complete in DB - show immediately`)
        results.push(knowledgeResult)
        continue
      }

      // SZENARIO B: Fehler in DB, aber KEINE Anleitung
      if (knowledgeResult && knowledgeResult.hasGuide === false) {
        console.log(`⚠️ SZENARIO B: ${errorCode.code} in DB but no guide - show now, update in background`)
        results.push(knowledgeResult)
        
        // 🔥 Fire & Forget: Perplexity + GPT + Save im Hintergrund
        backgroundTasks.push(
          researchWithPerplexityAndStructure(supabaseClient, errorCode.code, language)
            .then(improvedDiagnosis => {
              if (improvedDiagnosis) {
                console.log(`✅ Background: Perplexity research completed for ${errorCode.code}, updating DB`)
              }
            })
            .catch(err => console.warn(`⚠️ Background update failed for ${errorCode.code}:`, err))
        )
        continue
      }

      // SZENARIO A: Fehler NICHT in DB - blockierend abrufen
      console.log(`🌐 SZENARIO A: ${errorCode.code} not in DB - blocking fetch with Perplexity`)
      let diagnosis
      try {
        diagnosis = await researchWithPerplexityAndStructure(supabaseClient, errorCode.code, language)
        
        if (diagnosis) {
          console.log(`✅ Web research successful: ${errorCode.code}`)
          results.push(diagnosis)
          continue
        }
      } catch (perplexityError) {
        console.error(`❌ Perplexity research error for ${errorCode.code}:`, perplexityError)
      }

      // 3. Fallback - use LLM knowledge (ONLY if web research fails)
      if (!diagnosis) {
        console.log(`🤖 Final Fallback to LLM knowledge: ${errorCode.code}`)
        try {
          diagnosis = await generateLLMFallbackDiagnosis(errorCode.code, language)

          if (diagnosis) {
            console.log(`💾 Saving diagnosis to database and generating repair guides...`)
            await saveToKnowledgeBase(supabaseClient, errorCode.code, diagnosis, language)
            
            // 🔥 Generate repair guides for all causes IMMEDIATELY (blocking)
            console.log(`🛠️ Generating repair guides for ${(diagnosis as any).causes?.length || 0} causes...`)
            try {
              await generateAndSaveRepairGuides(supabaseClient, errorCode.code, (diagnosis as any).causes || [], language)
              console.log(`✅ Repair guides generated and saved`)
            } catch (guideError) {
              console.error(`⚠️ Failed to generate repair guides (non-critical):`, guideError)
            }
            
            results.push(diagnosis)
          } else {
            console.error(`❌ Failed to generate diagnosis for: ${errorCode.code}`)
          }
        } catch (llmError) {
          console.error(`❌ LLM Fallback error for ${errorCode.code}:`, llmError)
        }
      }
    }

    // 🔄 Warte NICHT auf Background Tasks - gib sofort Response zurück
    if (backgroundTasks.length > 0) {
      console.log(`🔥 ${backgroundTasks.length} background tasks started (not waiting)`)
      Promise.all(backgroundTasks).catch(err => console.error('Background task error:', err))
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
 * Returns 3 Scenarios:
 * A) null = Fehler nicht in DB → Perplexity + GPT + DB speichern
 * B) { ...diagnosis, hasGuide: false } = Fehler in DB, aber KEINE Anleitung → User sieht sofort, Background Update
 * C) { ...diagnosis, hasGuide: true } = Beides vorhanden → User sieht alles sofort
 */
interface KnowledgeSearchResult extends DiagnosisResult {
  hasGuide?: boolean
}

async function searchKnowledgeBase(
  supabase: any,
  errorCode: string,
  language: string
): Promise<KnowledgeSearchResult | null> {
  try {
    // Search in automotive_knowledge via keywords
    console.log(`🔍 Searching automotive_knowledge for ${errorCode}...`)
    
    const { data: knowledgeData, error: knowledgeError } = await supabase
      .from('automotive_knowledge')
      .select('*')
      .eq('category', 'fehlercode')
      .or(`keywords.cs.{"${errorCode}"},topic.ilike.%${errorCode}%`)
      .limit(1)

    if (knowledgeError) {
      console.warn(`⚠️ Knowledge base search error:`, knowledgeError)
      return null
    }

    // SZENARIO A: Fehler nicht in DB
    if (!knowledgeData || knowledgeData.length === 0) {
      console.log(`❌ ${errorCode} not in database - will use Perplexity`)
      return null
    }

    const entry = knowledgeData[0]
    const hasGuide = entry.repair_guides_de && Object.keys(entry.repair_guides_de).length > 0

    // SZENARIO B: Fehler in DB, aber KEINE Anleitung
    if (!hasGuide) {
      console.log(`⚠️ ${errorCode} in DB but NO repair guide - User gets quick display, Background update starts`)
      const diagnosis = mapKnowledgeToDiagnosis(entry, errorCode, language)
      return { ...diagnosis, hasGuide: false } as KnowledgeSearchResult
    }

    // SZENARIO C: Fehler + Anleitung in DB
    console.log(`✅ ${errorCode} found with complete guides in DB`)
    const diagnosis = mapKnowledgeToDiagnosis(entry, errorCode, language)
    return { ...diagnosis, hasGuide: true } as KnowledgeSearchResult

  } catch (error) {
    console.error('❌ Knowledge base search error:', error)
    return null
  }
}

/**
 * Research with Perplexity Web Search (Model: sonar - $1/1M)
 * Then structure with GPT-4, create embedding, and save to DB
 * Falls Perplexity nicht konfiguriert/fehlschlägt → GPT Fallback
 */
async function researchWithPerplexityAndStructure(
  supabaseClient: any,
  errorCode: string,
  language: string
): Promise<DiagnosisResult | null> {
  const perplexityApiKey = Deno.env.get('PERPLEXITY_API_KEY')
  
  if (!perplexityApiKey) {
    console.warn(`⚠️ PERPLEXITY_API_KEY not configured - falling back to LLM`)
    return await generateLLMFallbackDiagnosis(errorCode, language)
  }

  try {
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
      const errorMsg = `Perplexity API error: ${perplexityResponse.status} ${perplexityResponse.statusText}`
      console.error(`❌ ${errorMsg}`)
      console.log(`⚠️ Falling back to LLM knowledge instead`)
      return await generateLLMFallbackDiagnosis(errorCode, language)
    }

    const perplexityData = await perplexityResponse.json()
    const rawWebContent = perplexityData.choices[0]?.message?.content

    if (!rawWebContent) {
      console.warn(`⚠️ No content from Perplexity - falling back to LLM`)
      return await generateLLMFallbackDiagnosis(errorCode, language)
    }

    console.log(`  ✅ Step 1 complete: Gathered ${rawWebContent.length} chars of web data`)

    // STEP 2: GPT-4 Structure the raw data
    console.log(`  🧠 Step 2: Structuring with GPT-4`)
    const structuredData = await structureContentWithGPT4(rawWebContent, errorCode, language)
    
    if (!structuredData) {
      console.warn(`⚠️ Failed to structure content - falling back to LLM`)
      return await generateLLMFallbackDiagnosis(errorCode, language)
    }

    console.log(`  ✅ Step 2 complete: Content structured`)

    // STEP 3: Create embedding
    console.log(`  📊 Step 3: Creating embedding`)
    const embedding = await createEmbedding(
      `${structuredData.title} ${structuredData.description} ${structuredData.detailedAnalysis}`,
      language
    )

    if (!embedding) {
      console.warn(`⚠️ Failed to create embedding - saving without embedding`)
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
  } catch (error) {
    console.error(`❌ Error in Perplexity research pipeline for ${errorCode}:`, error)
    console.log(`⚠️ Final fallback: Using LLM knowledge`)
    return await generateLLMFallbackDiagnosis(errorCode, language)
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
      ? `Du bist ein erfahrener KFZ-Meister mit 30 Jahren Erfahrung. Analysiere den OBD2-Fehlercode ${errorCode} UMFASSEND und DETAILLIERT.

KRITISCH: Generiere MINDESTENS 7-10 VERSCHIEDENE MÖGLICHE URSACHEN, nicht nur 2-3!

Der Code wurde bereits ausgelesen - Die diagnosticSteps sollten NICHT "OBD2-Scanner anschließen" enthalten.

Gib folgende Struktur zurück (als VALIDES JSON):

{
  "title": "Titel des Fehlers",
  "description": "Kurze Erklärung in 2-3 Sätzen für Laien",
  "detailedAnalysis": "AUSFÜHRLICHE technische Analyse (5-8 Absätze!). Erkläre detailliert: Was bedeutet dieser Code? Welche Fahrzeugsysteme sind betroffen? Welche Langzeitfolgen sind möglich? Ist es gefährlich zu fahren?",
  "symptoms": ["Symptom 1", "Symptom 2", "Symptom 3", "Symptom 4", "Symptom 5"],
  "causes": [
    "Ursache 1: Detaillierte Erklärung",
    "Ursache 2: Detaillierte Erklärung",
    "Ursache 3: Detaillierte Erklärung",
    "Ursache 4: Detaillierte Erklärung",
    "Ursache 5: Detaillierte Erklärung",
    "Ursache 6: Detaillierte Erklärung",
    "Ursache 7: Detaillierte Erklärung",
    "Ursache 8: Detaillierte Erklärung",
    "Ursache 9: Detaillierte Erklärung",
    "Ursache 10: Detaillierte Erklärung"
  ],
  "diagnosticSteps": [
    {"stepNumber": 1, "title": "Sichtprüfung durchführen", "description": "Sehr detaillierte Anleitung (3-5 Sätze)", "warnings": ["Sicherheitshinweis"]},
    {"stepNumber": 2, "title": "Nächster Diagnoseschritt", "description": "Sehr detaillierte Anleitung", "warnings": []},
    {"stepNumber": 3, "title": "Messung durchführen", "description": "Sehr detaillierte Anleitung", "warnings": []},
    {"stepNumber": 4, "title": "Test durchführen", "description": "Sehr detaillierte Anleitung", "warnings": []}
  ],
  "repairSteps": [
    {"stepNumber": 1, "title": "Vorbereitung", "description": "Detaillierte Anleitung (3-5 Sätze)", "difficulty": "medium", "requiredTools": ["Werkzeug 1"], "estimatedTime": "15 Min", "warnings": ["Warnung"]},
    {"stepNumber": 2, "title": "Hauptreparatur", "description": "Detaillierte Anleitung", "difficulty": "medium", "requiredTools": [], "estimatedTime": "30 Min", "warnings": []},
    {"stepNumber": 3, "title": "Überprüfung", "description": "Detaillierte Anleitung", "difficulty": "easy", "requiredTools": [], "estimatedTime": "10 Min", "warnings": []}
  ],
  "toolsRequired": ["Werkzeug 1", "Werkzeug 2", "Werkzeug 3"],
  "estimatedCostEur": "50-200",
  "difficultyLevel": "medium",
  "severity": "medium",
  "driveSafety": true,
  "immediateActionRequired": false,
  "keywords": ["${errorCode}", "OBD2", "Fehlercode"]
}

WICHTIG: 
- MINIMUM 7-10 Ursachen - keine Kompromisse!
- DetailedAnalysis muss 5-8 Absätze sein (nicht nur 2-3 Sätze!)
- Jede Ursache hat DETAIL-Erklärung
- Jeder Schritt hat 3-5 Sätze Beschreibung
- JSON muss VALIDE sein - keine Syntax-Fehler!`
      : `You are an expert automotive technician with 30 years of experience. Analyze OBD2 error code ${errorCode} COMPREHENSIVELY and IN DETAIL.

CRITICAL: Generate MINIMUM 7-10 DIFFERENT POSSIBLE CAUSES, not just 2-3!

The code has already been read - diagnosticSteps should NOT include "connect OBD2 scanner".

Return this structure (as VALID JSON):

{
  "title": "Error title",
  "description": "Brief explanation in 2-3 sentences for laypeople",
  "detailedAnalysis": "COMPREHENSIVE technical analysis (5-8 paragraphs!). Explain in detail: What does this code mean? Which vehicle systems are affected? What long-term consequences are possible? Is it dangerous to drive?",
  "symptoms": ["Symptom 1", "Symptom 2", "Symptom 3", "Symptom 4", "Symptom 5"],
  "causes": [
    "Cause 1: Detailed explanation",
    "Cause 2: Detailed explanation",
    "Cause 3: Detailed explanation",
    "Cause 4: Detailed explanation",
    "Cause 5: Detailed explanation",
    "Cause 6: Detailed explanation",
    "Cause 7: Detailed explanation",
    "Cause 8: Detailed explanation",
    "Cause 9: Detailed explanation",
    "Cause 10: Detailed explanation"
  ],
  "diagnosticSteps": [
    {"stepNumber": 1, "title": "Perform visual inspection", "description": "Very detailed instructions (3-5 sentences)", "warnings": ["Safety note"]},
    {"stepNumber": 2, "title": "Next diagnostic step", "description": "Very detailed instructions", "warnings": []},
    {"stepNumber": 3, "title": "Perform measurement", "description": "Very detailed instructions", "warnings": []},
    {"stepNumber": 4, "title": "Perform test", "description": "Very detailed instructions", "warnings": []}
  ],
  "repairSteps": [
    {"stepNumber": 1, "title": "Preparation", "description": "Detailed instructions (3-5 sentences)", "difficulty": "medium", "requiredTools": ["Tool 1"], "estimatedTime": "15 min", "warnings": ["Warning"]},
    {"stepNumber": 2, "title": "Main repair", "description": "Detailed instructions", "difficulty": "medium", "requiredTools": [], "estimatedTime": "30 min", "warnings": []},
    {"stepNumber": 3, "title": "Verification", "description": "Detailed instructions", "difficulty": "easy", "requiredTools": [], "estimatedTime": "10 min", "warnings": []}
  ],
  "toolsRequired": ["Tool 1", "Tool 2", "Tool 3"],
  "estimatedCostEur": "50-200",
  "difficultyLevel": "medium",
  "severity": "medium",
  "driveSafety": true,
  "immediateActionRequired": false,
  "keywords": ["${errorCode}", "OBD2", "Error code"]
}

IMPORTANT:
- MINIMUM 7-10 causes - no compromises!
- DetailedAnalysis must be 5-8 paragraphs (not just 2-3 sentences!)
- Each cause has DETAILED explanation
- Each step has 3-5 sentences description
- JSON must be VALID - no syntax errors!`

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content: 'You are an expert automotive diagnostic technician with deep knowledge of OBD2 codes. ALWAYS respond with VALID, complete JSON only - no additional text, no markdown, just pure JSON. Generate comprehensive, detailed responses with minimum 7-10 causes.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.2,
        max_tokens: 4000,
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`OpenAI API error: ${response.statusText}`)
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

/**
 * Generate and save repair guides for all causes of an error code
 */
async function generateAndSaveRepairGuides(
  supabase: any,
  errorCode: string,
  causes: string[],
  language: string
): Promise<void> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  
  if (!openaiApiKey) {
    console.warn('⚠️ Cannot generate repair guides - no OpenAI API key')
    return
  }

  try {
    // Generate repair guides for each cause
    const repairGuidesDe: Record<string, any> = {}
    
    for (const cause of causes) {
      const causeKey = cause
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/^_|_$/g, '')
      
      console.log(`  📖 Generating repair guide for: ${cause}`)
      
      const prompt = language === 'de'
        ? `Erstelle eine SEHR DETAILLIERTE Reparaturanleitung für:
- Fehlercode: ${errorCode}
- Ursache: ${cause}

Erstelle 10-20 kinderleicht verständliche Schritte. JEDER Schritt braucht:
- Klaren Titel
- SEHR ausführliche Beschreibung (3-5 Sätze, erkläre WO, WAS, WIE, WARUM)
- Benötigte Werkzeuge
- Dauer in Minuten
- Sicherheitshinweise falls relevant

⚠️ WICHTIG - DYNAMISCHE OBD-PLATZIERUNG:
- In den ERSTEN 8 SCHRITTEN: KEIN "OBD auslesen", "Fehlercode auslesen", "Diagnosegerät anschließen"
- Die Reparaturschritte kommen ZUERST
- ERST DANACH (als letzter Schritt): "Fehlercode löschen und erneut auslesen"

JSON-Format:
{
  "cause_title": "${cause}",
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

NUR JSON ausgeben!`
        : `Create a VERY DETAILED repair guide for:
- Error code: ${errorCode}
- Cause: ${cause}

Create 10-20 child-easy-to-understand steps. EACH step needs:
- Clear title
- VERY detailed description (3-5 sentences, explain WHERE, WHAT, HOW, WHY)
- Required tools
- Duration in minutes
- Safety warnings if relevant

⚠️ IMPORTANT - DYNAMIC OBD PLACEMENT:
- In the FIRST 8 STEPS: NO "OBD read", "error code read", "connect diagnostic device"
- Repair steps come FIRST
- THEN (as last step): "Delete error code and read again"

JSON format:
{
  "cause_title": "${cause}",
  "difficulty_level": "easy|medium|hard",
  "estimated_time_hours": 2.0,
  "estimated_cost_eur": [100, 300],
  "for_beginners": true,
  "steps": [...],
  "tools_required": [...],
  "safety_warnings": [...],
  "when_to_call_mechanic": [...]
}

JSON ONLY!`
      
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${openaiApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          response_format: { type: 'json_object' },
          messages: [{
            role: 'system',
            content: 'You are an expert KFZ mechanic. Create EXTREMELY DETAILED step-by-step repair guides for absolute beginners. ALWAYS respond with VALID JSON only.'
          }, {
            role: 'user',
            content: prompt
          }],
          temperature: 0.3,
          max_tokens: 4000,
        })
      })
      
      if (response.ok) {
        const data = await response.json()
        const content = data.choices[0]?.message?.content
        if (content) {
          try {
            const guide = JSON.parse(content)
            repairGuidesDe[causeKey] = guide
            console.log(`    ✅ Generated guide for ${causeKey}`)
          } catch (parseError) {
            console.warn(`    ⚠️ Failed to parse guide JSON for ${causeKey}`)
          }
        }
      } else {
        console.warn(`    ⚠️ API error generating guide for ${causeKey}`)
      }
    }
    
    // Save all guides to database
    if (Object.keys(repairGuidesDe).length > 0) {
      const { data: entries } = await supabase
        .from('automotive_knowledge')
        .select('id, repair_guides_de')
        .eq('category', 'fehlercode')
        .ilike('topic', `%${errorCode}%`)
        .limit(1)
      
      if (entries && entries.length > 0) {
        const entry = entries[0]
        const updatedGuides = { ...(entry.repair_guides_de || {}), ...repairGuidesDe }
        
        await supabase
          .from('automotive_knowledge')
          .update({ repair_guides_de: updatedGuides })
          .eq('id', entry.id)
        
        console.log(`  💾 Saved ${Object.keys(repairGuidesDe).length} repair guides to DB`)
      }
    }
  } catch (error) {
    console.error('❌ Repair guide generation error:', error)
  }
}
