import { NextRequest, NextResponse } from 'next/server';

interface UsdaNutrient {
  nutrientId: number;
  nutrientName: string;
  value: number;
  unitName: string;
}

interface UsdaFoodMeasure {
  gramWeight: number;
  disseminationText?: string;
  householdMeasure?: string;
}

interface UsdaFood {
  fdcId: number;
  description: string;
  brandOwner?: string;
  foodNutrients: UsdaNutrient[];
  foodMeasures?: UsdaFoodMeasure[];
  servingSize?: number;
  servingSizeUnit?: string;
}

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const query = searchParams.get('q')?.trim();
  const limit = Math.min(Number(searchParams.get('limit') || 25), 50);

  if (!query) {
    return NextResponse.json({ error: 'Query parameter q is required' }, { status: 400 });
  }

  // Use server-side USDA API Key if available, or official public DEMO_KEY
  const apiKey = process.env.USDA_API_KEY || 'DEMO_KEY';
  const url = `https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${apiKey}&query=${encodeURIComponent(
    query
  )}&pageSize=${limit}&dataType=Foundation,SR%20Legacy,Branded`;

  try {
    const response = await fetch(url, {
      headers: {
        Accept: 'application/json',
      },
      next: { revalidate: 3600 }, // Cache on Edge for 1 hour
    });

    if (!response.ok) {
      return NextResponse.json(
        { error: `USDA API returned status ${response.status}`, items: [] },
        { status: response.status }
      );
    }

    const data = await response.json();
    const foods: UsdaFood[] = data.foods || [];

    const mappedItems = foods.map((food) => {
      // Find standard nutrients by USDA nutrient ID
      // 1008: Energy (kcal)
      // 1003: Protein (g)
      // 1005: Carbohydrate, by difference (g)
      // 1004: Total lipid (fat) (g)
      // 1079: Fiber, total dietary (g)
      // 2000: Total Sugars (g)
      let calories = 0;
      let protein = 0;
      let carbs = 0;
      let fats = 0;
      let fiber = 0;
      let sugar = 0;

      for (const n of food.foodNutrients) {
        if (n.nutrientId === 1008 || n.nutrientName?.toLowerCase().includes('energy')) {
          calories = n.value || calories;
        } else if (n.nutrientId === 1003 || n.nutrientName?.toLowerCase().includes('protein')) {
          protein = n.value || protein;
        } else if (n.nutrientId === 1005 || n.nutrientName?.toLowerCase().includes('carbohydrate')) {
          carbs = n.value || carbs;
        } else if (n.nutrientId === 1004 || n.nutrientName?.toLowerCase().includes('total lipid')) {
          fats = n.value || fats;
        } else if (n.nutrientId === 1079 || n.nutrientName?.toLowerCase().includes('fiber')) {
          fiber = n.value || fiber;
        } else if (n.nutrientId === 2000 || n.nutrientName?.toLowerCase().includes('sugars')) {
          sugar = n.value || sugar;
        }
      }

      // Build serving presets
      const servingPresets: Array<{ label: string; grams: number }> = [
        { label: '100g', grams: 100 },
      ];

      if (food.foodMeasures && food.foodMeasures.length > 0) {
        for (const m of food.foodMeasures) {
          const label = m.disseminationText || m.householdMeasure || `${m.gramWeight}g portion`;
          if (m.gramWeight > 0 && !servingPresets.some((p) => p.label === label)) {
            servingPresets.unshift({
              label: `${label} (${Math.round(m.gramWeight)}g)`,
              grams: Number(m.gramWeight.toFixed(1)),
            });
          }
        }
      } else if (food.servingSize && food.servingSize > 0) {
        const unit = food.servingSizeUnit || 'g';
        servingPresets.unshift({
          label: `1 serving (${food.servingSize}${unit})`,
          grams: Number(food.servingSize.toFixed(1)),
        });
      }

      return {
        id: `usda_${food.fdcId}`,
        name: food.description,
        brand: food.brandOwner || 'USDA FoodData Central',
        servingUnit: 'g',
        proteinPer100g: Number(protein.toFixed(2)),
        carbsPer100g: Number(carbs.toFixed(2)),
        fatsPer100g: Number(fats.toFixed(2)),
        caloriesPer100g: Number(calories.toFixed(1)),
        fiberPer100g: Number(fiber.toFixed(2)),
        sugarPer100g: Number(sugar.toFixed(2)),
        servingPresets,
        source: 'usda',
      };
    });

    return NextResponse.json({
      query,
      totalCount: data.totalHits || mappedItems.length,
      items: mappedItems,
    });
  } catch (error) {
    return NextResponse.json(
      { error: `Internal nutrition search error: ${String(error)}`, items: [] },
      { status: 500 }
    );
  }
}
