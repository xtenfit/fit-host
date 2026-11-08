import { PostHog } from 'posthog-node';
import { NextRequest, NextResponse } from 'next/server';

interface IngredientDraft {
  name: string;
  estimatedGrams: number;
  proteinPer100g: number;
  carbsPer100g: number;
  fatsPer100g: number;
  caloriesPer100g: number;
}

interface AiParseResponse {
  mealName: string;
  confidence: number;
  isEstimate: boolean;
  ingredients: IngredientDraft[];
  rawText?: string;
}

// Built-in standard database values (ICMR-NIN & USDA benchmarks per 100g)
const FOOD_KNOWLEDGE_BASE: Record<
  string,
  { p: number; c: number; f: number; cal: number; defaultPortion: number }
> = {
  // Zero-Calorie & Hydration
  water: { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 250 },
  pani: { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 250 },
  paani: { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 250 },
  'mineral water': { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 500 },
  'sparkling water': { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 330 },
  'soda water': { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 330 },
  'club soda': { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 330 },
  'diet coke': { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 330 },
  'coke zero': { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 330 },
  'diet soda': { p: 0.0, c: 0.0, f: 0.0, cal: 0.0, defaultPortion: 330 },
  'black coffee': { p: 0.1, c: 0.2, f: 0.0, cal: 2.0, defaultPortion: 150 },
  espresso: { p: 0.1, c: 0.2, f: 0.0, cal: 2.0, defaultPortion: 30 },
  americano: { p: 0.1, c: 0.2, f: 0.0, cal: 2.0, defaultPortion: 200 },
  'green tea': { p: 0.0, c: 0.2, f: 0.0, cal: 1.0, defaultPortion: 150 },
  'black tea': { p: 0.1, c: 0.3, f: 0.0, cal: 2.0, defaultPortion: 150 },
  'lemon water': { p: 0.1, c: 1.2, f: 0.0, cal: 5.0, defaultPortion: 240 },
  'coconut water': { p: 0.7, c: 3.7, f: 0.2, cal: 19.0, defaultPortion: 240 },

  // High Protein Staples
  'whey protein': { p: 76.0, c: 6.0, f: 3.0, cal: 355.0, defaultPortion: 33 },
  'protein powder': { p: 75.0, c: 6.0, f: 3.0, cal: 351.0, defaultPortion: 33 },
  'protein shake': { p: 10.0, c: 4.0, f: 1.5, cal: 69.0, defaultPortion: 300 },
  'egg white': { p: 10.9, c: 0.7, f: 0.2, cal: 52.0, defaultPortion: 33 },
  'boiled egg': { p: 12.6, c: 0.7, f: 9.9, cal: 143.0, defaultPortion: 50 },
  egg: { p: 12.6, c: 0.7, f: 9.9, cal: 143, defaultPortion: 50 },
  'chicken breast': { p: 31.0, c: 0.0, f: 3.6, cal: 165.0, defaultPortion: 150 },
  chicken: { p: 31.0, c: 0.0, f: 3.6, cal: 165, defaultPortion: 120 },
  paneer: { p: 18.3, c: 2.5, f: 20.8, cal: 265, defaultPortion: 100 },
  tofu: { p: 8.0, c: 1.9, f: 4.8, cal: 76.0, defaultPortion: 100 },
  'soya chunks': { p: 52.0, c: 33.0, f: 0.5, cal: 345.0, defaultPortion: 50 },
  'soy chunks': { p: 52.0, c: 33.0, f: 0.5, cal: 345.0, defaultPortion: 50 },
  nutrela: { p: 52.0, c: 33.0, f: 0.5, cal: 345.0, defaultPortion: 50 },
  fish: { p: 22.0, c: 0.0, f: 6.0, cal: 142.0, defaultPortion: 150 },
  salmon: { p: 20.0, c: 0.0, f: 13.0, cal: 208.0, defaultPortion: 150 },
  tuna: { p: 28.0, c: 0.0, f: 1.0, cal: 130.0, defaultPortion: 120 },

  // Dairy & Plant Milks
  'greek yogurt': { p: 10.0, c: 3.6, f: 0.4, cal: 59.0, defaultPortion: 170 },
  curd: { p: 3.5, c: 4.4, f: 4.1, cal: 68, defaultPortion: 150 },
  dahi: { p: 3.5, c: 4.4, f: 4.1, cal: 68, defaultPortion: 150 },
  milk: { p: 3.2, c: 4.8, f: 3.5, cal: 64, defaultPortion: 250 },

  // Grains, Breads & Staples
  roti: { p: 7.8, c: 46.0, f: 1.5, cal: 230, defaultPortion: 35 },
  chapati: { p: 7.8, c: 46.0, f: 1.5, cal: 230, defaultPortion: 35 },
  paratha: { p: 6.5, c: 42.0, f: 12.0, cal: 302, defaultPortion: 65 },
  dal: { p: 5.5, c: 14.5, f: 2.8, cal: 105, defaultPortion: 180 },
  daal: { p: 5.5, c: 14.5, f: 2.8, cal: 105, defaultPortion: 180 },
  rice: { p: 2.7, c: 28.2, f: 0.3, cal: 130, defaultPortion: 150 },
  'brown rice': { p: 2.6, c: 25.6, f: 0.9, cal: 123.0, defaultPortion: 150 },
  oats: { p: 13.5, c: 68.0, f: 6.5, cal: 389, defaultPortion: 40 },
  bread: { p: 9.0, c: 49.0, f: 3.2, cal: 265.0, defaultPortion: 35 },
  'brown bread': { p: 9.5, c: 46.0, f: 3.0, cal: 250.0, defaultPortion: 35 },
  idli: { p: 6.0, c: 28.0, f: 0.5, cal: 140.0, defaultPortion: 60 },
  dosa: { p: 5.0, c: 32.0, f: 6.0, cal: 202.0, defaultPortion: 80 },
  sambar: { p: 3.2, c: 8.5, f: 1.8, cal: 63.0, defaultPortion: 180 },
  chole: { p: 8.9, c: 27.4, f: 2.6, cal: 164.0, defaultPortion: 180 },
  rajma: { p: 8.7, c: 22.8, f: 0.8, cal: 127.0, defaultPortion: 180 },
  khichdi: { p: 4.5, c: 20.0, f: 3.5, cal: 130.0, defaultPortion: 200 },
  poha: { p: 3.5, c: 28.0, f: 5.0, cal: 171.0, defaultPortion: 150 },
  upma: { p: 4.0, c: 23.0, f: 6.0, cal: 162.0, defaultPortion: 150 },
  biryani: { p: 8.0, c: 24.0, f: 7.0, cal: 191.0, defaultPortion: 250 },

  // Fruits & Vegetables
  banana: { p: 1.1, c: 22.8, f: 0.3, cal: 89, defaultPortion: 118 },
  apple: { p: 0.3, c: 13.8, f: 0.2, cal: 52, defaultPortion: 182 },
  orange: { p: 0.9, c: 11.8, f: 0.1, cal: 47.0, defaultPortion: 130 },
  mango: { p: 0.8, c: 15.0, f: 0.4, cal: 60.0, defaultPortion: 150 },
  cucumber: { p: 0.7, c: 3.6, f: 0.1, cal: 15.0, defaultPortion: 100 },
  tomato: { p: 0.9, c: 3.9, f: 0.2, cal: 18.0, defaultPortion: 100 },
  salad: { p: 1.2, c: 3.5, f: 0.2, cal: 20.0, defaultPortion: 150 },

  // Beverages with Calories
  tea: { p: 0.5, c: 4.0, f: 0.8, cal: 25.0, defaultPortion: 150 },
  coffee: { p: 0.8, c: 5.0, f: 1.0, cal: 32.0, defaultPortion: 150 },
  juice: { p: 0.5, c: 11.5, f: 0.2, cal: 50.0, defaultPortion: 240 },
  maaza: { p: 0.1, c: 13.5, f: 0.1, cal: 54.0, defaultPortion: 250 },
  maja: { p: 0.1, c: 13.5, f: 0.1, cal: 54.0, defaultPortion: 250 },

  // Fats & Nuts
  ghee: { p: 0.0, c: 0.0, f: 99.5, cal: 896.0, defaultPortion: 15 },
  butter: { p: 0.9, c: 0.1, f: 81.0, cal: 717.0, defaultPortion: 15 },
  oil: { p: 0.0, c: 0.0, f: 100.0, cal: 884.0, defaultPortion: 15 },
  'peanut butter': { p: 25.0, c: 20.0, f: 50.0, cal: 588.0, defaultPortion: 32 },
  almonds: { p: 21.0, c: 22.0, f: 50.0, cal: 579.0, defaultPortion: 28 },
  walnuts: { p: 15.0, c: 14.0, f: 65.0, cal: 654.0, defaultPortion: 28 },
};

function isWaterOrZeroCalorie(name: string): boolean {
  const lower = name.toLowerCase().trim();
  if (!lower) return false;
  if (
    lower === 'water' ||
    lower === 'pani' ||
    lower === 'paani' ||
    lower === 'aqua' ||
    lower === 'h2o' ||
    lower === 'plain water' ||
    lower.includes('drinking water') ||
    lower.includes('mineral water') ||
    lower.includes('tap water') ||
    lower.includes('ice water') ||
    lower.includes('boiled water') ||
    lower.includes('warm water') ||
    lower.includes('cold water') ||
    lower.includes('sparkling water') ||
    lower.includes('soda water') ||
    lower.includes('club soda') ||
    lower.includes('diet coke') ||
    lower.includes('coke zero') ||
    lower.includes('diet pepsi') ||
    lower.includes('diet soda') ||
    lower.includes('zero calorie') ||
    lower.includes('zero sugar')
  ) {
    return true;
  }
  const tokens = lower.split(/[\s,_\-\/\(\)]+/);
  return tokens.includes('water') || tokens.includes('pani') || tokens.includes('paani');
}

function sanitizeMacros(
  name: string,
  rawP: number,
  rawC: number,
  rawF: number,
  rawCal: number
): { p: number; c: number; f: number; cal: number } {
  if (isWaterOrZeroCalorie(name)) {
    return { p: 0.0, c: 0.0, f: 0.0, cal: 0.0 };
  }

  let p = Math.max(0, rawP);
  let c = Math.max(0, rawC);
  let f = Math.max(0, rawF);
  let cal = Math.max(0, rawCal);

  const macroSum = p + c + f;
  if (macroSum > 100.0) {
    const factor = 98.0 / macroSum;
    p = Number((p * factor).toFixed(1));
    c = Number((c * factor).toFixed(1));
    f = Number((f * factor).toFixed(1));
  }

  if (cal > 900.0) {
    cal = 900.0;
  }

  const atwater = p * 4.0 + c * 4.0 + f * 9.0;
  const theoreticalMin = p * 4.0 + f * 9.0;

  if (cal <= 0) {
    cal = atwater;
  } else if (cal > atwater * 1.15 + 5.0 || cal < theoreticalMin * 0.8 - 5.0) {
    cal = atwater;
  }

  return {
    p: Number(p.toFixed(1)),
    c: Number(c.toFixed(1)),
    f: Number(f.toFixed(1)),
    cal: Number(cal.toFixed(1)),
  };
}

function parseNumberWords(text: string): number {
  const map: Record<string, number> = {
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
    a: 1,
    an: 1,
  };
  return map[text.toLowerCase()] || parseFloat(text) || 1;
}

interface AiGenerationCapture {
  distinctId: string;
  traceId: string;
  sessionId: string | null;
  prompt: string;
  latency: number;
  httpStatus?: number;
  output?: string;
  isError?: boolean;
  error?: string;
}

async function captureGeminiGeneration({
  distinctId,
  traceId,
  sessionId,
  prompt,
  latency,
  httpStatus,
  output,
  isError = false,
  error,
}: AiGenerationCapture): Promise<void> {
  const projectToken = process.env.POSTHOG_PROJECT_TOKEN;
  const host = process.env.POSTHOG_HOST;

  if (!projectToken || !host) {
    const missingVariable = projectToken ? 'POSTHOG_HOST' : 'POSTHOG_PROJECT_TOKEN';
    if (process.env.NODE_ENV !== 'production') {
      console.error(
        `${missingVariable} variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once ${missingVariable} is configured`
      );
    }
    return;
  }

  const posthog = new PostHog(projectToken, {
    host,
    flushAt: 1,
    flushInterval: 0,
    enableExceptionAutocapture: true,
    privacyMode: false,
  });

  posthog.capture({
    distinctId,
    event: '$ai_generation',
    properties: {
      $ai_trace_id: traceId,
      $ai_session_id: sessionId,
      $ai_span_name: 'nutrition_meal_analysis',
      $ai_model: 'gemini-1.5-flash',
      $ai_provider: 'gemini',
      $ai_input: [{ role: 'user', content: prompt }],
      $ai_output_choices: output
        ? [{ role: 'assistant', content: output }]
        : undefined,
      $ai_latency: latency,
      $ai_temperature: 0.2,
      $ai_http_status: httpStatus,
      $ai_is_error: isError,
      $ai_error: error,
    },
  });
  await posthog.shutdown();
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const text: string | undefined = body.text?.trim();
    const imageBase64: string | undefined = body.imageBase64?.trim();

    if (!text && !imageBase64) {
      return NextResponse.json(
        { error: 'Either text description or imageBase64 is required.' },
        { status: 400 }
      );
    }

    // Security & Privacy rule: Limit image size to 4MB base64 (~3MB raw)
    if (imageBase64 && imageBase64.length > 5 * 1024 * 1024) {
      return NextResponse.json(
        { error: 'Image size exceeds maximum 4MB limit.' },
        { status: 413 }
      );
    }

    const apiKey = process.env.GEMINI_API_KEY;

    // If Gemini API Key is configured on the server, call Gemini 1.5 Flash
    if (apiKey) {
      const traceId = crypto.randomUUID();
      const sessionId = request.headers.get('x-posthog-ai-session-id');
      const distinctId = request.headers.get('x-posthog-distinct-id') || 'anonymous';
      const generationStartedAt = Date.now();
      let generationCaptured = false;

      try {
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

        const prompt = text
          ? `Parse this meal text description: "${text}".\n` +
            `CRITICAL NUTRITIONAL ACCURACY RULES:\n` +
            `1. WATER & HYDRATION: Water (plain water, tap water, mineral water, ice, sparkling water) has EXACTLY 0 protein, 0 carbohydrates, 0 fats, and 0 calories. NEVER report non-zero macros or calories for water.\n` +
            `2. NON-CALORIC ITEMS: Black coffee, unsweetened tea, and diet sodas have 0-2 calories and 0g protein.\n` +
            `3. REAL CALORIES: For all other foods, calories must accurately equal the physical Atwater formula: (4 * protein) + (4 * carbs) + (9 * fats) kcal per 100g.\n` +
            `4. MACRO BOUNDS: For 100g of any ingredient, (protein + carbs + fats) cannot exceed 100g. Calories per 100g cannot exceed 900 kcal.\n` +
            `5. REALISTIC PORTIONS: Estimate accurate portion weights in grams (for liquids, 1ml ≈ 1g; 1 glass/cup ≈ 240g).\n` +
            `Return ONLY valid JSON matching: {"meal_name": "string", "confidence": 0.0-1.0, "ingredients": [{"name": "string", "estimated_grams": number, "protein_per_100g": number, "carbs_per_100g": number, "fats_per_100g": number, "calories_per_100g": number}]}`
          : `Analyze this meal photo. Identify each visible ingredient separately.\n` +
            `CRITICAL NUTRITIONAL ACCURACY RULES:\n` +
            `1. WATER & HYDRATION: Water (plain water, tap water, mineral water, ice, sparkling water) has EXACTLY 0 protein, 0 carbohydrates, 0 fats, and 0 calories. NEVER report non-zero macros or calories for water.\n` +
            `2. NON-CALORIC ITEMS: Black coffee, unsweetened tea, and diet sodas have 0-2 calories and 0g protein.\n` +
            `3. REAL CALORIES: For all other foods, calories must accurately equal the physical Atwater formula: (4 * protein) + (4 * carbs) + (9 * fats) kcal per 100g.\n` +
            `4. MACRO BOUNDS: For 100g of any ingredient, (protein + carbs + fats) cannot exceed 100g. Calories per 100g cannot exceed 900 kcal.\n` +
            `5. REALISTIC PORTIONS: Estimate accurate portion weights in grams (for liquids, 1ml ≈ 1g; 1 glass/cup ≈ 240g).\n` +
            `Return ONLY valid JSON matching: {"meal_name": "string", "confidence": 0.0-1.0, "ingredients": [{"name": "string", "estimated_grams": number, "protein_per_100g": number, "carbs_per_100g": number, "fats_per_100g": number, "calories_per_100g": number}]}`;

        const parts: Array<{ text: string } | { inline_data: { mime_type: string; data: string } }> = [{ text: prompt }];
        if (imageBase64) {
          parts.push({
            inline_data: {
              mime_type: 'image/jpeg',
              data: imageBase64.replace(/^data:image\/[a-z]+;base64,/, ''),
            },
          });
        }

        const geminiResponse = await fetch(geminiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts }],
            generationConfig: {
              temperature: 0.2,
              responseMimeType: 'application/json',
            },
          }),
        });

        if (geminiResponse.ok) {
          const geminiData = await geminiResponse.json();
          const rawOutput =
            geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
          if (rawOutput) {
            await captureGeminiGeneration({
              distinctId,
              traceId,
              sessionId,
              prompt,
              output: rawOutput,
              latency: (Date.now() - generationStartedAt) / 1000,
              httpStatus: geminiResponse.status,
            });
            generationCaptured = true;

            let clean = rawOutput.trim();
            if (clean.startsWith('```json')) clean = clean.substring(7);
            if (clean.startsWith('```')) clean = clean.substring(3);
            if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
            clean = clean.trim();

            const parsed = JSON.parse(clean);
            const ingredients: IngredientDraft[] = (parsed.ingredients || []).map(
              (ing: Record<string, unknown>) => {
                const name = String(ing.name || 'Food Item').trim();
                const estimatedGrams = Math.max(1, Number(ing.estimated_grams || 100));
                const p = Number(ing.protein_per_100g || 0);
                const c = Number(ing.carbs_per_100g || 0);
                const f = Number(ing.fats_per_100g || 0);
                const cal = Number(ing.calories_per_100g || 0);

                const sanitized = sanitizeMacros(name, p, c, f, cal);

                return {
                  name,
                  estimatedGrams: Number(estimatedGrams.toFixed(1)),
                  proteinPer100g: sanitized.p,
                  carbsPer100g: sanitized.c,
                  fatsPer100g: sanitized.f,
                  caloriesPer100g: sanitized.cal,
                };
              }
            );

            return NextResponse.json({
              mealName: parsed.meal_name || (text ? 'Logged Meal' : 'Detected Meal'),
              confidence: Number(parsed.confidence ?? 0.85),
              isEstimate: true,
              ingredients,
            });
          }
        }

        await captureGeminiGeneration({
          distinctId,
          traceId,
          sessionId,
          prompt,
          latency: (Date.now() - generationStartedAt) / 1000,
          httpStatus: geminiResponse.status,
          isError: true,
          error: 'Gemini response did not contain generated content',
        });
      } catch (geminiErr) {
        if (!generationCaptured) {
          await captureGeminiGeneration({
            distinctId,
            traceId,
            sessionId,
            prompt: text ? `Parse this meal text description: "${text}".` : 'Analyze this meal photo.',
            latency: (Date.now() - generationStartedAt) / 1000,
            isError: true,
            error: 'Gemini request failed',
          });
        }
        console.warn('[AI Parse] Gemini API call failed, falling back to deterministic parser:', geminiErr);
      }
    }

    // High-fidelity fallback / natural language parser (runs when Gemini is offline or text is provided)
    if (text) {
      const parsedIngredients: IngredientDraft[] = [];
      // Split text on commas, 'and', '+', '&'
      const segments = text.split(/,|\band\b|\+|\&/i).map((s) => s.trim()).filter(Boolean);

      for (const seg of segments) {
        // Match patterns like: "2 rotis", "1 bowl of dal", "150 g curd", "250 ml milk", "1 banana"
        const match = seg.match(
          /^(?:(\w+|\d+)\s+)?(?:(bowl|katori|cup|glass|slice|piece|serving|tbsp|tsp|g|grams|ml)\s+(?:of\s+)?)?(.+)$/i
        );

        let count = 1;
        let unit = '';
        let foodName = seg.toLowerCase();

        if (match) {
          count = parseNumberWords(match[1] || '1');
          unit = (match[2] || '').toLowerCase();
          foodName = (match[3] || '').toLowerCase().trim();
        }

        const explicitGramMatch = seg.match(/(\d+(?:\.\d+)?)\s*(g|grams|ml)\b/i);
        if (explicitGramMatch) {
          count = parseFloat(explicitGramMatch[1]) || 1;
          unit = explicitGramMatch[2].toLowerCase();
        }

        const isWater = isWaterOrZeroCalorie(foodName);

        // Sort keys by length descending so multi-word keys match first
        const sortedKeys = Object.keys(FOOD_KNOWLEDGE_BASE).sort(
          (a, b) => b.length - a.length
        );

        let matchedKey: string | undefined;
        if (!isWater) {
          matchedKey = sortedKeys.find((k) => foodName.includes(k));
        }

        let grams = 100;
        let p = 0.0;
        let c = 0.0;
        let f = 0.0;
        let cal = 0.0;

        if (isWater) {
          p = 0.0;
          c = 0.0;
          f = 0.0;
          cal = 0.0;
          if (unit === 'l' || unit === 'litre' || unit === 'litres' || unit === 'liter' || unit === 'liters') {
            grams = count * 1000;
          } else if (unit === 'ml' || unit === 'millilitre' || unit === 'millilitres' || unit === 'milliliter' || unit === 'milliliters') {
            grams = count;
          } else if (unit === 'glass' || unit === 'cup') {
            grams = count * 240;
          } else {
            grams = count * 250;
          }
        } else if (matchedKey) {
          const info = FOOD_KNOWLEDGE_BASE[matchedKey];
          p = info.p;
          c = info.c;
          f = info.f;
          cal = info.cal;

          if (unit === 'g' || unit === 'grams') {
            grams = count;
          } else if (unit === 'ml' || unit === 'millilitre' || unit === 'millilitres' || unit === 'milliliter' || unit === 'milliliters') {
            grams = count;
          } else if (unit === 'l' || unit === 'litre' || unit === 'litres' || unit === 'liter' || unit === 'liters') {
            grams = count * 1000;
          } else if (unit === 'bowl' || unit === 'katori') {
            grams = count * 180;
          } else if (unit === 'glass' || unit === 'cup') {
            grams = count * 240;
          } else {
            grams = count * info.defaultPortion;
          }
        } else {
          // Unknown food item: check if beverage or solid food
          const isBeverage =
            unit === 'ml' ||
            unit === 'l' ||
            unit === 'litre' ||
            unit === 'litres' ||
            unit === 'liter' ||
            unit === 'liters' ||
            unit === 'glass' ||
            unit === 'cup' ||
            foodName.includes('drink') ||
            foodName.includes('beverage') ||
            foodName.includes('shake') ||
            foodName.includes('sip');

          if (isBeverage) {
            p = 0.2;
            c = 5.0;
            f = 0.2;
            cal = 22.6;
            grams = (unit === 'glass' || unit === 'cup') ? count * 240 : count * 200;
          } else {
            p = 3.0;
            c = 15.0;
            f = 3.0;
            cal = 99.0;
            const gramMatch = seg.match(/(\d+)\s*(g|grams|ml)\b/i);
            if (gramMatch) {
              grams = parseFloat(gramMatch[1]) || 100;
            } else {
              grams = count * 100;
            }
          }
        }

        const sanitized = sanitizeMacros(seg, p, c, f, cal);

        parsedIngredients.push({
          name: seg.charAt(0).toUpperCase() + seg.slice(1),
          estimatedGrams: Math.round(grams),
          proteinPer100g: sanitized.p,
          carbsPer100g: sanitized.c,
          fatsPer100g: sanitized.f,
          caloriesPer100g: sanitized.cal,
        });
      }

      const response: AiParseResponse = {
        mealName: text.length > 30 ? `${text.slice(0, 27)}...` : text,
        confidence: parsedIngredients.length > 0 ? 0.8 : 0.4,
        isEstimate: true,
        ingredients: parsedIngredients,
      };

      return NextResponse.json(response);
    }

    return NextResponse.json(
      { error: 'Unable to parse meal input.' },
      { status: 422 }
    );
  } catch (err: unknown) {
    const errMsg = err instanceof Error ? err.message : String(err);
    return NextResponse.json(
      { error: `Internal meal parse error: ${errMsg}` },
      { status: 500 }
    );
  }
}
