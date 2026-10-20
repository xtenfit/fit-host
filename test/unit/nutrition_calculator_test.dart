import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/domain/models/meal_entry.dart';
import 'package:fit_host/features/nutrition/domain/models/food_item.dart';

void main() {
  group('Nutrition Calculator Tests', () {
    final pintola = FoodItem(
      id: 'pintola-pb',
      name: 'Pintola Peanut Butter (Crunchy)',
      proteinPer100g: 25.0,
      carbsPer100g: 20.0,
      fatsPer100g: 50.0,
      caloriesPer100g: 630.0,
    );

    test('100g Pintola peanut butter matches per-100g base values', () {
      final entry = MealEntry(
        id: '1',
        foodName: pintola.name,
        quantityGrams: 100.0,
        mealType: MealType.snack,
        consumedAt: DateTime.now(),
        proteinPer100g: pintola.proteinPer100g,
        carbsPer100g: pintola.carbsPer100g,
        fatsPer100g: pintola.fatsPer100g,
        caloriesPer100g: pintola.caloriesPer100g,
      );

      expect(entry.protein, equals(25.0));
      expect(entry.carbs, equals(20.0));
      expect(entry.fats, equals(50.0));
      expect(entry.calories, equals(630.0));
      expect(entry.caloriesInt, equals(630));
    });

    test('50g portion produces exactly half of all macronutrients and calories', () {
      final entry = MealEntry(
        id: '2',
        foodName: pintola.name,
        quantityGrams: 50.0,
        mealType: MealType.breakfast,
        consumedAt: DateTime.now(),
        proteinPer100g: pintola.proteinPer100g,
        carbsPer100g: pintola.carbsPer100g,
        fatsPer100g: pintola.fatsPer100g,
        caloriesPer100g: pintola.caloriesPer100g,
      );

      expect(entry.protein, equals(12.5));
      expect(entry.carbs, equals(10.0));
      expect(entry.fats, equals(25.0));
      expect(entry.calories, equals(315.0));
      expect(entry.caloriesInt, equals(315));
    });

    test('0g portion safely returns zeros with zero NaN or Infinity', () {
      final entry = MealEntry(
        id: '3',
        foodName: pintola.name,
        quantityGrams: 0.0,
        mealType: MealType.lunch,
        consumedAt: DateTime.now(),
        proteinPer100g: pintola.proteinPer100g,
        carbsPer100g: pintola.carbsPer100g,
        fatsPer100g: pintola.fatsPer100g,
        caloriesPer100g: pintola.caloriesPer100g,
      );

      expect(entry.protein, equals(0.0));
      expect(entry.carbs, equals(0.0));
      expect(entry.fats, equals(0.0));
      expect(entry.calories, equals(0.0));
      expect(entry.calories.isNaN, isFalse);
      expect(entry.calories.isInfinite, isFalse);
    });

    test('Negative grams throws an error and prevents invalid state', () {
      expect(
        () => MealEntry(
          id: '4',
          foodName: pintola.name,
          quantityGrams: -10.0,
          mealType: MealType.dinner,
          consumedAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
