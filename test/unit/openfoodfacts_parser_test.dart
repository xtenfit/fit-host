import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/nutrition/data/services/openfoodfacts_service.dart';
import 'package:fit_host/features/nutrition/domain/models/food_item.dart';

void main() {
  group('OpenFoodFacts Parser Tests', () {
    final service = OpenFoodFactsService();

    test('Parses raw OFF json with energy in kcal directly', () {
      final json = {
        'code': '8901262010115',
        'product': {
          'product_name': 'Amul Gold Full Cream Milk',
          'brands': 'Amul',
          'serving_size': '200ml',
          'nutriments': {
            'proteins_100g': 3.1,
            'carbohydrates_100g': 4.7,
            'fat_100g': 6.0,
            'energy-kcal_100g': 87.0,
          },
        },
      };

      final food = service.parseProductJson(json);
      expect(food, isNotNull);
      expect(food!.name, equals('Amul Gold Full Cream Milk'));
      expect(food.brand, equals('Amul'));
      expect(food.proteinPer100g, equals(3.1));
      expect(food.carbsPer100g, equals(4.7));
      expect(food.fatsPer100g, equals(6.0));
      expect(food.caloriesPer100g, equals(87.0));
      expect(food.source, equals(FoodSource.openfoodfacts));
    });

    test('Converts energy in kJ to kcal when energy-kcal is missing', () {
      final json = {
        'code': '1234567890',
        'product': {
          'product_name': 'European Oat Bar',
          'nutriments': {
            'energy-kj_100g': 1673.6, // 1673.6 / 4.184 = 400.0 kcal
            'proteins_100g': 10.0,
            'carbohydrates_100g': 60.0,
            'fat_100g': 12.0,
          },
        },
      };

      final food = service.parseProductJson(json);
      expect(food, isNotNull);
      expect(food!.caloriesPer100g, closeTo(400.0, 0.5));
    });

    test('Missing nutriments defaults gracefully to 0.0 with no crash', () {
      final json = {
        'code': '99999999',
        'product': {
          'product_name': 'Mystery Snack',
          'nutriments': <String, dynamic>{},
        },
      };

      final food = service.parseProductJson(json);
      expect(food, isNotNull);
      expect(food!.name, equals('Mystery Snack'));
      expect(food.proteinPer100g, equals(0.0));
      expect(food.carbsPer100g, equals(0.0));
      expect(food.fatsPer100g, equals(0.0));
      expect(food.caloriesPer100g, equals(0.0));
    });

    test('Null or empty json returns null', () {
      expect(service.parseProductJson(null), isNull);
      expect(service.parseProductJson({}), isNull);
      expect(service.parseProductJson({'product': null}), isNull);
    });
  });
}
