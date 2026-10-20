import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/nutrition_repository.dart';
import 'package:fit_host/features/nutrition/domain/models/nutrition_models.dart';

void main() {
  group('Online-First Nutrition Repository Tests', () {
    late AppDatabase memoryDb;
    late CloudNutritionRepository repository;
    const testUserId = '11111111-2222-3333-4444-555555555555';

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      // Supabase is null, simulating offline/cloud unavailable
      repository = CloudNutritionRepository(
        db: memoryDb,
        supabase: null,
        userId: testUserId,
      );
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('getDailyNutrition returns cached data when cloud is unavailable', () async {
      final now = DateTime.now();

      // Seed local cache via repository
      final testMeal = MealItem(
        id: 'meal-cache-1',
        name: 'Whey Protein Shake',
        mealType: 'snack',
        dietType: 'balanced',
        calories: 140,
        proteinGrams: 25,
        carbsGrams: 3,
        fatGrams: 2,
        loggedAt: now,
      );

      await repository.logMeal(testMeal, date: now);

      // Read back via online-first repository
      final state = await repository.getDailyNutrition(now);

      expect(state.loggedMeals, hasLength(1));
      expect(state.loggedMeals.first.name, equals('Whey Protein Shake'));
      expect(state.totalCaloriesGained, equals(140));
    });

    test('Writes are committed locally and enqueued in outbox syncQueue', () async {
      final now = DateTime.now();

      // Log a meal
      final meal = MealItem(
        id: 'meal-outbox-test-1',
        name: 'Oatmeal & Berries',
        mealType: 'breakfast',
        dietType: 'vegan',
        calories: 320,
        proteinGrams: 12,
        carbsGrams: 55,
        fatGrams: 6,
        loggedAt: now,
      );

      await repository.logMeal(meal, date: now);

      // Verify that local nutritionLogs contains the saved record
      final logs = await memoryDb.select(memoryDb.nutritionLogs).get();
      expect(logs, isNotEmpty);
      expect(logs.first.userId, equals(testUserId));

      // Verify that syncQueue has pending mutations to be synced when online
      final queued = await memoryDb.select(memoryDb.syncQueue).get();
      expect(queued, isNotEmpty);
      expect(queued.first.entityType, equals('nutrition_logs'));
      expect(queued.first.status, equals('queued'));
    });

    test('Hydration tracking logs water and persists to local database and queue', () async {
      final now = DateTime.now();

      await repository.setWater(6, date: now);

      final state = await repository.getDailyNutrition(now);
      expect(state.waterGlasses, equals(6));

      // Verify queue has updated entry
      final queued = await memoryDb.select(memoryDb.syncQueue).get();
      expect(queued.any((item) => item.entityType == 'nutrition_logs'), isTrue);
    });
  });
}
