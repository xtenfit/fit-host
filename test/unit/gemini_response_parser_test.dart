import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/data/services/gemini_nutrition_service.dart';

void main() {
  group('Gemini Response Parser Tests', () {
    final service = GeminiNutritionService();

    test('Parses valid JSON from Gemini correctly', () {
      const rawJson = '''
      {
        "meal_name": "Paneer Tikka with Mint Chutney",
        "confidence": 0.92,
        "ingredients": [
          {
            "name": "Grilled Paneer",
            "estimated_grams": 150.0,
            "protein_per_100g": 18.0,
            "carbs_per_100g": 3.4,
            "fats_per_100g": 20.0,
            "calories_per_100g": 265.0
          },
          {
            "name": "Mint Coriander Chutney",
            "estimated_grams": 30.0,
            "protein_per_100g": 1.5,
            "carbs_per_100g": 4.0,
            "fats_per_100g": 1.0,
            "calories_per_100g": 35.0
          }
        ]
      }
      ''';

      final draft = service.parseGeminiResponse(rawJson, imagePath: '/path/test.jpg');
      expect(draft.mealName, equals('Paneer Tikka with Mint Chutney'));
      expect(draft.confidence, closeTo(0.92, 0.01));
      expect(draft.estimatedIngredients.length, equals(2));
      expect(draft.estimatedIngredients.first.name, equals('Grilled Paneer'));
      expect(draft.estimatedIngredients.first.estimatedGrams, equals(150.0));
      expect(draft.totalCalories, greaterThan(300.0));
    });

    test('Parses JSON wrapped in markdown fences gracefully', () {
      const rawMarkdown = '''
      ```json
      {
        "meal_name": "Boiled Eggs & Toast",
        "confidence": 0.88,
        "ingredients": [
          {
            "name": "Boiled Eggs",
            "estimated_grams": 100.0,
            "protein_per_100g": 13.0,
            "carbs_per_100g": 1.1,
            "fats_per_100g": 11.0,
            "calories_per_100g": 155.0
          }
        ]
      }
      ```
      ''';

      final draft = service.parseGeminiResponse(rawMarkdown);
      expect(draft.mealName, equals('Boiled Eggs & Toast'));
      expect(draft.confidence, closeTo(0.88, 0.01));
      expect(draft.estimatedIngredients.length, equals(1));
    });

    test('Invalid JSON returns empty ingredients with 0.0 confidence', () {
      const badJson = 'Sorry, I am an AI and cannot identify this image properly.';
      final draft = service.parseGeminiResponse(badJson);
      expect(draft.estimatedIngredients, isEmpty);
      expect(draft.confidence, equals(0.0));
    });

    test('Task 13 Safety Check: Suspiciously high calories are clamped to max 900 kcal/100g', () {
      const suspiciousJson = '''
      {
        "meal_name": "Magic Chicken",
        "confidence": 0.9,
        "ingredients": [
          {
            "name": "Chicken Breast",
            "estimated_grams": 100.0,
            "protein_per_100g": 31.0,
            "carbs_per_100g": 0.0,
            "fats_per_100g": 3.6,
            "calories_per_100g": 5500.0
          }
        ]
      }
      ''';

      final draft = service.parseGeminiResponse(suspiciousJson);
      expect(draft.estimatedIngredients.first.caloriesPer100g, lessThanOrEqualTo(900.0));
      expect(draft.estimatedIngredients.first.caloriesPer100g, equals(900.0));
    });

    test('Negative macros and non-positive grams are sanitized safely', () {
      const dirtyJson = '''
      {
        "meal_name": "Corrupted Data",
        "confidence": 0.7,
        "ingredients": [
          {
            "name": "Test Item",
            "estimated_grams": -50.0,
            "protein_per_100g": -5.0,
            "carbs_per_100g": -10.0,
            "fats_per_100g": -2.0,
            "calories_per_100g": -100.0
          }
        ]
      }
      ''';

      final draft = service.parseGeminiResponse(dirtyJson);
      final ing = draft.estimatedIngredients.first;
      expect(ing.estimatedGrams, greaterThan(0.0));
      expect(ing.proteinPer100g, greaterThanOrEqualTo(0.0));
      expect(ing.carbsPer100g, greaterThanOrEqualTo(0.0));
      expect(ing.fatsPer100g, greaterThanOrEqualTo(0.0));
      expect(ing.caloriesPer100g, greaterThanOrEqualTo(0.0));
    });
  });
}
