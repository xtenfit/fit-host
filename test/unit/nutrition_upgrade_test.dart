import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/domain/models/food_item.dart';
import 'package:fit_host/features/nutrition/data/seed_foods.dart';
import 'package:fit_host/features/nutrition/data/services/gemini_nutrition_service.dart';

void main() {
  group('Nutrition Engine & Advanced Food Calculator Tests', () {
    test('FoodSource.usda is properly labeled with icon and name', () {
      expect(FoodSource.usda.label, equals('USDA FoodData'));
    });

    test(
      'Formula conforms strictly to spec: calculated = per100g * portionGrams / 100',
      () {
        final food = FoodItem(
          id: 'test_food_1',
          name: 'Cooked Chicken Breast',
          proteinPer100g: 31.0,
          carbsPer100g: 0.0,
          fatsPer100g: 3.6,
          caloriesPer100g: 165.0,
          servingUnit: 'g',
          servingPresets: [
            const ServingPreset(label: '1 breast portion (150g)', grams: 150.0),
          ],
          source: FoodSource.usda,
        );

        // 150g portion:
        final portionGrams = food.servingPresets.first.grams;
        final calculatedProtein = (food.proteinPer100g * portionGrams) / 100.0;
        final calculatedCalories =
            (food.caloriesPer100g * portionGrams) / 100.0;

        expect(calculatedProtein, closeTo(46.5, 0.01));
        expect(calculatedCalories, closeTo(247.5, 0.01));
      },
    );

    test(
      'Expanded ICMR-NIN Indian food staples are present with accurate macros',
      () {
        // Find key Indian staple foods in kSeedFoods:
        final dalMakhani = kSeedFoods.firstWhere(
          (f) => f.name.contains('Dal Makhani'),
        );
        final khichdi = kSeedFoods.firstWhere(
          (f) => f.name.contains('Khichdi'),
        );
        final palakPaneer = kSeedFoods.firstWhere(
          (f) => f.name.contains('Palak Paneer'),
        );
        final sambar = kSeedFoods.firstWhere((f) => f.name.contains('Sambar'));
        final biryani = kSeedFoods.firstWhere(
          (f) => f.name.contains('Chicken Biryani'),
        );
        final paratha = kSeedFoods.firstWhere(
          (f) => f.name.contains('Plain Paratha'),
        );

        expect(dalMakhani.servingPresets.first.label, contains('katori'));
        expect(dalMakhani.proteinPer100g, greaterThan(4.0));

        expect(khichdi.servingPresets, isNotEmpty);
        expect(khichdi.servingPresets.first.grams, equals(150.0));
        expect(khichdi.caloriesPer100g, greaterThan(100.0));

        expect(palakPaneer.servingPresets.first.label, contains('bowl'));
        expect(sambar.servingPresets.first.label, contains('bowl'));
        expect(biryani.proteinPer100g, greaterThan(8.0));
        expect(paratha.servingPresets.first.label, contains('paratha'));
      },
    );

    test(
      'GeminiNutritionService parses natural language text description accurately',
      () async {
        final service = GeminiNutritionService();
        final draft = await service.analyzeMealText(
          'Two rotis, one bowl of dal, and 150g curd',
        );

        expect(draft.estimatedIngredients.length, equals(3));
        expect(
          draft.estimatedIngredients[0].name.toLowerCase(),
          contains('roti'),
        );
        expect(
          draft.estimatedIngredients[1].name.toLowerCase(),
          contains('dal'),
        );
        expect(
          draft.estimatedIngredients[2].name.toLowerCase(),
          contains('curd'),
        );

        // Check portion scaling from natural language units:
        // 2 rotis = 2 * 35g = 70g
        expect(draft.estimatedIngredients[0].estimatedGrams, equals(70.0));
        // 1 bowl of dal = 180g
        expect(draft.estimatedIngredients[1].estimatedGrams, equals(180.0));
        // 150g curd = 150g
        expect(draft.estimatedIngredients[2].estimatedGrams, equals(150.0));
      },
    );

    test(
      'GeminiNutritionService handles milk and banana text parsing',
      () async {
        final service = GeminiNutritionService();
        final draft = await service.analyzeMealText(
          'One banana and 250ml milk',
        );

        expect(draft.estimatedIngredients.length, equals(2));
        expect(
          draft.estimatedIngredients[0].name.toLowerCase(),
          contains('banana'),
        );
        expect(
          draft.estimatedIngredients[1].name.toLowerCase(),
          contains('milk'),
        );
        expect(draft.estimatedIngredients[1].estimatedGrams, equals(250.0));
      },
    );

    test(
      'Gemini response parser enforces 900 kcal/100g pure fat upper bound',
      () {
        final service = GeminiNutritionService();
        const suspiciousJson = '''
      {
        "meal_name": "Mysterious High Calorie Oil",
        "confidence": 0.95,
        "ingredients": [
          {
            "name": "Super Caloric Fat",
            "estimated_grams": 50.0,
            "protein_per_100g": 0.0,
            "carbs_per_100g": 0.0,
            "fats_per_100g": 100.0,
            "calories_per_100g": 1400.0
          }
        ]
      }
      ''';

        final draft = service.parseGeminiResponse(suspiciousJson);
        expect(draft.estimatedIngredients.first.caloriesPer100g, equals(900.0));
        expect(
          draft.confidence,
          lessThan(0.95),
        ); // Clamped confidence penalty applied
      },
    );

    test('GeminiNutritionService correctly parses water with 0 protein and 0 calories', () async {
      final service = GeminiNutritionService();

      // Test 1: Single glass of water
      final draft1 = await service.analyzeMealText('1 glass of water');
      expect(draft1.estimatedIngredients.length, equals(1));
      final water1 = draft1.estimatedIngredients.first;
      expect(water1.name.toLowerCase(), contains('water'));
      expect(water1.estimatedGrams, equals(240.0));
      expect(water1.proteinPer100g, equals(0.0));
      expect(water1.carbsPer100g, equals(0.0));
      expect(water1.fatsPer100g, equals(0.0));
      expect(water1.caloriesPer100g, equals(0.0));
      expect(water1.protein, equals(0.0));
      expect(water1.calories, equals(0.0));
      expect(draft1.totalProtein, equals(0.0));
      expect(draft1.totalCalories, equals(0.0));

      // Test 2: 500ml water
      final draft2 = await service.analyzeMealText('500ml water');
      expect(draft2.estimatedIngredients.length, equals(1));
      final water2 = draft2.estimatedIngredients.first;
      expect(water2.estimatedGrams, equals(500.0));
      expect(water2.proteinPer100g, equals(0.0));
      expect(water2.caloriesPer100g, equals(0.0));

      // Test 3: Pani / Paani
      final draft3 = await service.analyzeMealText('1 glass pani');
      expect(draft3.estimatedIngredients.first.proteinPer100g, equals(0.0));
      expect(draft3.estimatedIngredients.first.caloriesPer100g, equals(0.0));
    });

    test('GeminiNutritionService meal with rotis, dal, and water calculates accurate calories without protein in water', () async {
      final service = GeminiNutritionService();
      final draft = await service.analyzeMealText('Two rotis, one bowl of dal, and 1 glass of water');

      expect(draft.estimatedIngredients.length, equals(3));

      // Rotis: 70g (2 * 35g)
      final rotis = draft.estimatedIngredients[0];
      expect(rotis.name.toLowerCase(), contains('roti'));
      expect(rotis.estimatedGrams, equals(70.0));
      expect(rotis.proteinPer100g, equals(7.8));
      expect(rotis.protein, closeTo(5.46, 0.01));

      // Dal: 180g
      final dal = draft.estimatedIngredients[1];
      expect(dal.name.toLowerCase(), contains('dal'));
      expect(dal.estimatedGrams, equals(180.0));
      expect(dal.proteinPer100g, equals(5.5));
      expect(dal.protein, closeTo(9.9, 0.01));

      // Water: 240g
      final water = draft.estimatedIngredients[2];
      expect(water.name.toLowerCase(), contains('water'));
      expect(water.estimatedGrams, equals(240.0));
      expect(water.proteinPer100g, equals(0.0));
      expect(water.caloriesPer100g, equals(0.0));
      expect(water.protein, equals(0.0));
      expect(water.calories, equals(0.0));

      // Total Protein strictly equals roti protein + dal protein (water adds 0!)
      expect(draft.totalProtein, closeTo(rotis.protein + dal.protein, 0.01));
      expect(draft.totalCalories, closeTo(rotis.calories + dal.calories, 0.01));
    });

    test('parseGeminiResponse sanitizes hallucinated macros for water to 0.0', () {
      final service = GeminiNutritionService();
      const hallucinatedJson = '''
      {
        "meal_name": "Meal with Water",
        "confidence": 0.90,
        "ingredients": [
          {
            "name": "Glass of Water",
            "estimated_grams": 250.0,
            "protein_per_100g": 4.5,
            "carbs_per_100g": 10.0,
            "fats_per_100g": 2.0,
            "calories_per_100g": 80.0
          },
          {
            "name": "Grilled Chicken",
            "estimated_grams": 150.0,
            "protein_per_100g": 31.0,
            "carbs_per_100g": 0.0,
            "fats_per_100g": 3.6,
            "calories_per_100g": 165.0
          }
        ]
      }
      ''';

      final draft = service.parseGeminiResponse(hallucinatedJson);
      expect(draft.estimatedIngredients.length, equals(2));

      // Water was sanitized to 0
      final water = draft.estimatedIngredients[0];
      expect(water.proteinPer100g, equals(0.0));
      expect(water.carbsPer100g, equals(0.0));
      expect(water.fatsPer100g, equals(0.0));
      expect(water.caloriesPer100g, equals(0.0));
      expect(water.protein, equals(0.0));
      expect(water.calories, equals(0.0));

      // Chicken preserved
      final chicken = draft.estimatedIngredients[1];
      expect(chicken.proteinPer100g, equals(31.0));
      expect(chicken.caloriesPer100g, equals(165.0));
      expect(chicken.protein, closeTo(46.5, 0.01));
    });
  });
}
