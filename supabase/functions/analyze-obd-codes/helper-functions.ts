/**
 * Helper functions for analyze-obd-codes Edge Function
 */

/**
 * Structure raw web content with GPT-4
 */
export async function structureContentWithGPT4(
  rawContent: string,
  errorCode: string,
  language: string
): Promise<any> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  
  if (!openaiApiKey) {
    throw new Error('No OpenAI API key')
  }

  const structurePrompt = language === 'de'
    ? `Du hast folgende Web-Recherche-Ergebnisse zum OBD2-Fehlercode ${errorCode} erhalten:

${rawContent}

Strukturiere diese Informationen in folgendes JSON-Format. Extrahiere und organisiere alle relevanten Daten:

{
  "title": "Kurze, prägnante Beschreibung des Fehlers",
  "description": "Detaillierte Beschreibung (2-3 Sätze)",
  "detailedAnalysis": "Ausführliche technische Analyse des Problems (Mindestens 4-5 Sätze)",
  "symptoms": ["Symptom 1", "Symptom 2", "Symptom 3"],
  "causes": ["Ursache 1", "Ursache 2", "Ursache 3"],
  "diagnosticSteps": [
    {
      "stepNumber": 1,
      "title": "Schritt-Titel",
      "description": "Detaillierte Anleitung was zu tun ist",
      "warnings": ["Optional: Warnung falls gefährlich"]
    }
  ],
  "repairSteps": [
    {
      "stepNumber": 1,
      "title": "Reparatur-Schritt",
      "description": "Detaillierte Reparaturanleitung",
      "difficulty": "easy|medium|hard|expert",
      "requiredTools": ["Werkzeug 1", "Werkzeug 2"],
      "estimatedTime": "30 Min",
      "warnings": ["Optional: Sicherheitshinweis"]
    }
  ],
  "toolsRequired": ["OBD2-Scanner", "Schraubenschlüssel", etc.],
  "estimatedCostEur": "100-500",
  "difficultyLevel": "easy|medium|hard|expert",
  "severity": "low|medium|high|critical",
  "driveSafety": true/false,
  "immediateActionRequired": true/false,
  "keywords": ["${errorCode}", "Keyword2", "Keyword3"]
}

WICHTIG: Antworte NUR mit dem JSON, kein zusätzlicher Text!`
    : `You have the following web research results for OBD2 error code ${errorCode}:

${rawContent}

Structure this information into the following JSON format. Extract and organize all relevant data:

{
  "title": "Brief, concise error description",
  "description": "Detailed description (2-3 sentences)",
  "detailedAnalysis": "Comprehensive technical analysis (At least 4-5 sentences)",
  "symptoms": ["Symptom 1", "Symptom 2", "Symptom 3"],
  "causes": ["Cause 1", "Cause 2", "Cause 3"],
  "diagnosticSteps": [
    {
      "stepNumber": 1,
      "title": "Step title",
      "description": "Detailed instructions",
      "warnings": ["Optional: Warning if dangerous"]
    }
  ],
  "repairSteps": [
    {
      "stepNumber": 1,
      "title": "Repair step",
      "description": "Detailed repair instructions",
      "difficulty": "easy|medium|hard|expert",
      "requiredTools": ["Tool 1", "Tool 2"],
      "estimatedTime": "30 min",
      "warnings": ["Optional: Safety note"]
    }
  ],
  "toolsRequired": ["OBD2 Scanner", "Wrench", etc.],
  "estimatedCostEur": "100-500",
  "difficultyLevel": "easy|medium|hard|expert",
  "severity": "low|medium|high|critical",
  "driveSafety": true/false,
  "immediateActionRequired": true/false,
  "keywords": ["${errorCode}", "Keyword2", "Keyword3"]
}

IMPORTANT: Respond ONLY with JSON, no additional text!`

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
          content: 'You are an expert at structuring automotive repair data. Always respond with valid JSON only.',
        },
        {
          role: 'user',
          content: structurePrompt,
        },
      ],
      temperature: 0.1,
      max_tokens: 3000,
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`GPT-4 structuring failed: ${response.statusText} - ${errorText}`)
  }

  const data = await response.json()
  const content = data.choices[0]?.message?.content

  if (!content) {
    throw new Error('No content from GPT-4')
  }

  return JSON.parse(content)
}

/**
 * Create OpenAI embedding for vector search
 */
export async function createEmbedding(
  text: string,
  language: string
): Promise<number[]> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  
  if (!openaiApiKey) {
    throw new Error('No OpenAI API key')
  }

  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: text,
      dimensions: 1536,
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`Embedding creation failed: ${response.statusText} - ${errorText}`)
  }

  const data = await response.json()
  return data.data[0].embedding
}

/**
 * Save complete structured knowledge to automotive_knowledge table
 */
export async function saveFullKnowledgeToDatabase(
  supabase: any,
  errorCode: string,
  knowledge: any,
  embedding: number[],
  language: string
): Promise<void> {
  const embeddingField = `embedding_${language}`
  const titleField = `title_${language}`
  const contentField = `content_${language}`

  // Prepare full content for storage
  const fullContent = `${knowledge.description}\n\n${knowledge.detailedAnalysis}\n\nSymptome: ${knowledge.symptoms.join(', ')}\n\nUrsachen: ${knowledge.causes.join(', ')}`

  const { error } = await supabase
    .from('automotive_knowledge')
    .insert({
      topic: errorCode,
      category: 'fehlercode',
      subcategory: 'obd2',
      [titleField]: knowledge.title,
      [contentField]: fullContent,
      symptoms: knowledge.symptoms,
      causes: knowledge.causes,
      diagnostic_steps: knowledge.diagnosticSteps.map((s: any) => s.description),
      repair_steps: knowledge.repairSteps.map((s: any) => s.description),
      tools_required: knowledge.toolsRequired,
      estimated_cost_eur: parseFloat(knowledge.estimatedCostEur.split('-')[0]) || null,
      difficulty_level: knowledge.difficultyLevel,
      [embeddingField]: JSON.stringify(embedding),
      keywords: knowledge.keywords,
      original_language: language,
      quality_score: 0.85,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })

  if (error) {
    console.error('❌ Failed to save to automotive_knowledge:', error)
    throw error
  }
}

/**
 * Map error_codes table entry to DiagnosisResult
 */
export function mapErrorCodeToDiagnosis(errorData: any, language: string): any {
  return {
    code: errorData.code,
    title: errorData[`description_${language}`] || errorData.description_en || errorData.code,
    description: errorData[`description_${language}`] || errorData.description_en || '',
    detailedAnalysis: '',
    diagnosticSteps: errorData.diagnostic_steps?.map((step: string, idx: number) => ({
      stepNumber: idx + 1,
      title: step,
      description: step,
    })) || [],
    repairSteps: errorData.repair_suggestions?.map((step: string, idx: number) => ({
      stepNumber: idx + 1,
      title: step,
      description: step,
    })) || [],
    severity: errorData.severity,
    driveSafety: errorData.drive_safety,
    immediateActionRequired: errorData.immediate_action_required,
    requiredTools: [],
    estimatedCost: errorData.typical_cost_range_eur,
    estimatedTime: '',
    sourceType: 'database',
    createdAt: errorData.created_at,
  }
}

/**
 * Map automotive_knowledge table entry to DiagnosisResult
 */
export function mapKnowledgeToDiagnosis(knowledgeData: any, errorCode: string, language: string): any {
  return {
    code: errorCode,
    title: knowledgeData[`title_${language}`] || knowledgeData.title_en || errorCode,
    description: knowledgeData[`content_${language}`]?.substring(0, 300) || '',
    detailedAnalysis: knowledgeData[`content_${language}`] || '',
    diagnosticSteps: knowledgeData.diagnostic_steps?.map((step: string, idx: number) => ({
      stepNumber: idx + 1,
      title: step,
      description: step,
    })) || [],
    repairSteps: knowledgeData.repair_steps?.map((step: string, idx: number) => ({
      stepNumber: idx + 1,
      title: step,
      description: step,
    })) || [],
    severity: knowledgeData.difficulty_level,
    driveSafety: true,
    immediateActionRequired: false,
    requiredTools: knowledgeData.tools_required || [],
    estimatedCost: knowledgeData.estimated_cost_eur ? `${knowledgeData.estimated_cost_eur}+` : '',
    estimatedTime: '',
    sourceType: 'database',
    createdAt: knowledgeData.created_at,
  }
}
