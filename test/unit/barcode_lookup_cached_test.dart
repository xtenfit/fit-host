import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/nutrition/data/repositories/food_repository_impl.dart';
import 'package:fit_host/features/nutrition/data/services/openfoodfacts_service.dart';
import 'package:fit_host/features/nutrition/domain/models/food_item.dart';

class MockOpenFoodFactsService extends OpenFoodFactsService {
  int fetchCallCount = 0;
  final Map<String, FoodItem> mockProducts = {};

  @override
  Future<FoodItem?> fetchProductByBarcode(String barcode) async {
    fetchCallCount++;
    return mockProducts[barcode];
  }
}

void main() {
  group('Barcode Lookup Caching Tests', () {
    late AppDatabase db;
    late MockOpenFoodFactsService mockOffService;
    late FoodRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      mockOffService = MockOpenFoodFactsService();
      repository = FoodRepositoryImpl(
        db: db,
        offService: mockOffService,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('First scan calls OpenFoodFacts; second scan hits local Drift cache with 0 API calls', () async {
      const barcode = '8901234567890';
      final remoteFood = FoodItem(
        id: 'remote-1',
        barcode: barcode,
        name: 'Organic Rolled Oats',
        brand: 'Healthy Co',
        proteinPer100g: 13.0,
        carbsPer100g: 65.0,
        fatsPer100g: 7.0,
        caloriesPer100g: 380.0,
        source: FoodSource.openfoodfacts,
      );

      mockOffService.mockProducts[barcode] = remoteFood;

      // 1. First scan: missing in local DB -> calls OpenFoodFacts
      final firstResult = await repository.getFoodByBarcode(barcode);
      expect(firstResult, isNotNull);
      expect(firstResult!.name, equals('Organic Rolled Oats'));
      expect(mockOffService.fetchCallCount, equals(1));

      // 2. Second scan: already cached in Drift -> return from local DB with 0 new API calls
      final secondResult = await repository.getFoodByBarcode(barcode);
      expect(secondResult, isNotNull);
      expect(secondResult!.name, equals('Organic Rolled Oats'));
      expect(secondResult.barcode, equals(barcode));
      expect(mockOffService.fetchCallCount, equals(1),
          reason: 'OpenFoodFacts should not be called on subsequent barcode scans (cache hit)');
    });

    test('Seeded item with barcode is returned locally with zero OFF calls', () async {
      // Insert seeded food into local database directly
      final seededFood = FoodItem(
        id: 'seeded-pb',
        barcode: '8906000000001',
        name: 'Pintola Peanut Butter',
        brand: 'Pintola',
        proteinPer100g: 25.0,
        carbsPer100g: 20.0,
        fatsPer100g: 50.0,
        caloriesPer100g: 630.0,
        source: FoodSource.seeded,
      );
      await repository.saveFood(seededFood);

      final result = await repository.getFoodByBarcode('8906000000001');
      expect(result, isNotNull);
      expect(result!.name, equals('Pintola Peanut Butter'));
      expect(mockOffService.fetchCallCount, equals(0),
          reason: 'Seeded items in Drift must never trigger external API calls');
    });
  });
}
