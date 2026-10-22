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
  roti: { p: 7.8, c: 46.0, f: 1.5, cal: 230, defaultPortion: 35 },
  chapati: { p: 7.8, c: 46.0, f: 1.5, cal: 230, defaultPortion: 35 },
  paratha: { p: 6.5, c: 42.0, f: 12.0, cal: 302, defaultPortion: 65 },
  dal: { p: 5.5, c: 14.5, f: 2.8, cal: 105, defaultPortion: 180 },
  curd: { p: 3.5, c: 4.4, f: 4.1, cal: 68, defaultPortion: 150 },
  dahi: { p: 3.5, c: 4.4, f: 4.1, cal: 68, defaultPortion: 150 },
  milk: { p: 3.2, c: 4.8, f: 3.5, cal: 64, defaultPortion: 250 },
  banana: { p: 1.1, c: 22.8, f: 0.3, cal: 89, defaultPortion: 118 },
  apple: { p: 0.3, c: 13.8, f: 0.2, cal: 52, defaultPortion: 182 },
  egg: { p: 12.6, c: 0.7, f: 9.9, cal: 143, defaultPortion: 50 },
  rice: { p: 2.7, c: 28.2, f: 0.3, cal: 130, defaultPortion: 150 },
  paneer: { p: 18.3, c: 2.5, f: 20.8, cal: 265, defaultPortion: 100 },
  chicken: { p: 31.0, c: 0.0, f: 3.6, cal: 165, defaultPortion: 120 },
  oats: { p: 13.5, c: 68.0, f: 6.5, cal: 389, defaultPortion: 40 },
};

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
      try {
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

        const prompt = text
          ? `Parse this meal text description: "${text}". ` +
            `Identify all food items, estimate quantity in grams (or ml for liquids), and provide per-100g macros: protein, carbs, fats, and calories. ` +
            `Return ONLY valid JSON matching: {"meal_name": "string", "confidence": 0.0-1.0, "ingredients": [{"name": "string", "estimated_grams": number, "protein_per_100g": number, "carbs_per_100g": number, "fats_per_100g": number, "calories_per_100g": number}]}`
          : `Analyze this meal photo. Identify each visible ingredient separately. ` +
            `For each ingredient, estimate quantity in grams and provide per-100g: protein, carbohydrates, fats, and calories. ` +
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
            let clean = rawOutput.trim();
            if (clean.startsWith('```json')) clean = clean.substring(7);
            if (clean.startsWith('```')) clean = clean.substring(3);
            if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
            clean = clean.trim();

            const parsed = JSON.parse(clean);
            const ingredients: IngredientDraft[] = (parsed.ingredients || []).map(
              (ing: Record<string, unknown>) => ({
                name: String(ing.name || 'Food Item'),
                estimatedGrams: Number(ing.estimated_grams || 100),
                proteinPer100g: Number(Math.max(0, Number(ing.protein_per_100g) || 0).toFixed(1)),
                carbsPer100g: Number(Math.max(0, Number(ing.carbs_per_100g) || 0).toFixed(1)),
                fatsPer100g: Number(Math.max(0, Number(ing.fats_per_100g) || 0).toFixed(1)),
                // Safety clamp: Pure fat is max 900 kcal / 100g
                caloriesPer100g: Number(Math.min(900, Math.max(0, Number(ing.calories_per_100g) || 0)).toFixed(1)),
              })
            );

            return NextResponse.json({
              mealName: parsed.meal_name || (text ? 'Logged Meal' : 'Detected Meal'),
              confidence: Number(parsed.confidence ?? 0.85),
              isEstimate: true,
              ingredients,
            });
          }
        }
      } catch (geminiErr) {
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

        // Find match in benchmark food knowledge base
        const matchedKey = Object.keys(FOOD_KNOWLEDGE_BASE).find((k) =>
          foodName.includes(k)
        );

        let grams = 100;
        let p = 5.0;
        let c = 15.0;
        let f = 3.0;
        let cal = 107.0;

        if (matchedKey) {
          const info = FOOD_KNOWLEDGE_BASE[matchedKey];
          p = info.p;
          c = info.c;
          f = info.f;
          cal = info.cal;

          if (unit === 'g' || unit === 'grams' || unit === 'ml') {
            grams = count;
          } else if (unit === 'bowl' || unit === 'katori') {
            grams = count * 180;
          } else if (unit === 'glass' || unit === 'cup') {
            grams = count * 240;
          } else {
            grams = count * info.defaultPortion;
          }
        } else {
          // If numeric grams/ml was specified directly: e.g. "150g something"
          const gramMatch = seg.match(/(\d+)\s*(g|grams|ml)\b/i);
          if (gramMatch) {
            grams = parseFloat(gramMatch[1]) || 100;
          }
        }

        parsedIngredients.push({
          name: seg.charAt(0).toUpperCase() + seg.slice(1),
          estimatedGrams: Math.round(grams),
          proteinPer100g: Number(p.toFixed(1)),
          carbsPer100g: Number(c.toFixed(1)),
          fatsPer100g: Number(f.toFixed(1)),
          caloriesPer100g: Number(cal.toFixed(1)),
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
