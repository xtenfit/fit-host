import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/domain/models/meal_entry.dart';

void main() {
  group('Meal Type Autoselect Tests', () {
    test('Hour 5..10 autoselects Breakfast', () {
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 5, 0)), equals(MealType.breakfast));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 8, 30)), equals(MealType.breakfast));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 10, 59)), equals(MealType.breakfast));
    });

    test('Hour 11..15 autoselects Lunch', () {
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 11, 0)), equals(MealType.lunch));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 13, 15)), equals(MealType.lunch));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 15, 59)), equals(MealType.lunch));
    });

    test('Hour 16..20 autoselects Dinner', () {
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 16, 0)), equals(MealType.dinner));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 19, 45)), equals(MealType.dinner));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 20, 59)), equals(MealType.dinner));
    });

    test('Late night and early morning hours (< 5 or >= 21) autoselect Snack', () {
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 21, 0)), equals(MealType.snack));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 23, 30)), equals(MealType.snack));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 2, 0)), equals(MealType.snack));
      expect(MealType.fromCurrentHour(DateTime(2026, 10, 16, 4, 59)), equals(MealType.snack));
    });

    test('MealType.fromString parses case-insensitively', () {
      expect(MealType.fromString('BREAKFAST'), equals(MealType.breakfast));
      expect(MealType.fromString('Lunch'), equals(MealType.lunch));
      expect(MealType.fromString('dinner'), equals(MealType.dinner));
      expect(MealType.fromString('snacks'), equals(MealType.snack));
      expect(MealType.fromString('custom'), equals(MealType.custom));
      expect(MealType.fromString('unknown'), equals(MealType.snack));
    });
  });
}
