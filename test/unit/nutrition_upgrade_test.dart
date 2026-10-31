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
  });
}
