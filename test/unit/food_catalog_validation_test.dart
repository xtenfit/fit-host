import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/nutrition/data/seed_foods.dart';

void main() {
  group('Phase 3 — Verified Food Catalog Validation Suite', () {
    test('Catalog contains at least 500 distinct, verified food entries', () {
      expect(
        kSeedFoods.length,
        greaterThanOrEqualTo(500),
        reason: 'Phase 3 requires at least 500 verified food entries',
      );
      // Print verified count for audit report
      // ignore: avoid_print
      print(
        '[Audit] Total verified food catalog entries: ${kSeedFoods.length}',
      );
    });

    test('All food IDs are unique, valid strings, and properly formatted', () {
      final seenIds = <String>{};
      for (final food in kSeedFoods) {
        expect(food.id, isNotEmpty, reason: 'Food ID cannot be empty');
        expect(
          seenIds.contains(food.id),
          isFalse,
          reason: 'Duplicate food ID found: ${food.id}',
        );
        seenIds.add(food.id);
        expect(
          food.id.startsWith('seed_'),
          isTrue,
          reason: 'Seeded food ID must have seed_ prefix: ${food.id}',
        );
      }
      expect(seenIds.length, equals(kSeedFoods.length));
    });

    test('All names and brands are non-empty, clean strings', () {
      for (final food in kSeedFoods) {
        expect(
          food.name.trim(),
          isNotEmpty,
          reason: 'Food name must not be blank',
        );
        expect(food.name.length, greaterThanOrEqualTo(2));
        if (food.brand != null) {
          expect(food.brand!.trim(), isNotEmpty);
        }
      }
    });

    test('Nutritional values adhere to physical constraints per 100g', () {
      for (final food in kSeedFoods) {
        // Non-negative
        expect(
          food.proteinPer100g,
          greaterThanOrEqualTo(0.0),
          reason: 'Negative protein in ${food.id}',
        );
        expect(
          food.carbsPer100g,
          greaterThanOrEqualTo(0.0),
          reason: 'Negative carbs in ${food.id}',
        );
        expect(
          food.fatsPer100g,
          greaterThanOrEqualTo(0.0),
          reason: 'Negative fats in ${food.id}',
        );
        expect(
          food.caloriesPer100g,
          greaterThanOrEqualTo(0.0),
          reason: 'Negative calories in ${food.id}',
        );

        // Finite numbers
        expect(food.proteinPer100g.isFinite, isTrue);
        expect(food.carbsPer100g.isFinite, isTrue);
        expect(food.fatsPer100g.isFinite, isTrue);
        expect(food.caloriesPer100g.isFinite, isTrue);

        // Sum of macro mass per 100g cannot exceed ~100.5g (water/ash/minerals fill the remainder)
        final macroSum =
            food.proteinPer100g + food.carbsPer100g + food.fatsPer100g;
        expect(
          macroSum,
          lessThanOrEqualTo(100.5),
          reason: 'Macro mass exceeds 100g in ${food.name}: $macroSum g',
        );

        // Standard pure fat is 9 kcal/g, so max possible calories per 100g is ~900 kcal
        expect(
          food.caloriesPer100g,
          lessThanOrEqualTo(920.0),
          reason:
              'Physically impossible calorie density in ${food.name}: ${food.caloriesPer100g}',
        );
      }
    });

    test(
      'All items have valid, non-zero serving presets with positive grams',
      () {
        for (final food in kSeedFoods) {
          expect(
            food.servingPresets,
            isNotEmpty,
            reason: 'Food ${food.name} must have at least one serving preset',
          );
          for (final preset in food.servingPresets) {
            expect(preset.label.trim(), isNotEmpty);
            expect(
              preset.grams,
              greaterThan(0.0),
              reason:
                  'Serving preset ${preset.label} in ${food.name} has non-positive grams',
            );
          }
        }
      },
    );

    test('All barcodes are unique among items that specify them', () {
      final seenBarcodes = <String>{};
      for (final food in kSeedFoods) {
        if (food.barcode != null && food.barcode!.isNotEmpty) {
          expect(
            seenBarcodes.contains(food.barcode),
            isFalse,
            reason: 'Duplicate barcode ${food.barcode} on food ${food.name}',
          );
          seenBarcodes.add(food.barcode!);
        }
      }
    });

    test('Catalog covers required staple categories and regional cuisines', () {
      final names = kSeedFoods.map((f) => f.name.toLowerCase()).toList();

      // Indian Dal staples
      expect(names.any((n) => n.contains('moong dal')), isTrue);
      expect(
        names.any((n) => n.contains('toor dal') || n.contains('arhar dal')),
        isTrue,
      );
      expect(names.any((n) => n.contains('chana dal')), isTrue);
      expect(names.any((n) => n.contains('masoor dal')), isTrue);
      expect(names.any((n) => n.contains('rajma')), isTrue);
      expect(
        names.any((n) => n.contains('chole') || n.contains('chickpeas')),
        isTrue,
      );

      // Indian Breads & Rotis
      expect(
        names.any((n) => n.contains('roti') || n.contains('phulka')),
        isTrue,
      );
      expect(names.any((n) => n.contains('chapati')), isTrue);
      expect(names.any((n) => n.contains('paratha')), isTrue);
      expect(names.any((n) => n.contains('naan')), isTrue);

      // Indian Dairy & Curries
      expect(names.any((n) => n.contains('paneer')), isTrue);
      expect(
        names.any((n) => n.contains('curd') || n.contains('dahi')),
        isTrue,
      );
      expect(
        names.any((n) => n.contains('chaas') || n.contains('buttermilk')),
        isTrue,
      );
      expect(names.any((n) => n.contains('ghee')), isTrue);

      // Non-veg
      expect(names.any((n) => n.contains('chicken breast')), isTrue);
      expect(names.any((n) => n.contains('chicken curry')), isTrue);
      expect(names.any((n) => n.contains('boiled egg')), isTrue);
      expect(names.any((n) => n.contains('fish')), isTrue);
      expect(names.any((n) => n.contains('mutton')), isTrue);

      // South Indian
      expect(names.any((n) => n.contains('idli')), isTrue);
      expect(names.any((n) => n.contains('dosa')), isTrue);
      expect(names.any((n) => n.contains('sambar')), isTrue);
      expect(names.any((n) => n.contains('rasam')), isTrue);

      // Indian Brand items
      final brands = kSeedFoods
          .map((f) => f.brand?.toLowerCase() ?? '')
          .toSet();
      expect(brands.contains('amul'), isTrue);
      expect(brands.contains('epigamia'), isTrue);
      expect(brands.contains('pintola'), isTrue);
    });

    test(
      'Drift in-memory AppDatabase initializes and seeds entire 600+ catalog',
      () async {
        final db = AppDatabase(NativeDatabase.memory());

        // Query seeded items
        final seededRows = await (db.select(
          db.foodItems,
        )..where((t) => t.source.equals('seeded'))).get();

        expect(
          seededRows.length,
          equals(kSeedFoods.length),
          reason: 'Database should seed all ${kSeedFoods.length} items',
        );

        // Test search query
        final rotiSearch = await (db.select(
          db.foodItems,
        )..where((t) => t.name.like('%Roti%') | t.name.like('%roti%'))).get();
        expect(rotiSearch, isNotEmpty);

        final paneerSearch =
            await (db.select(db.foodItems)..where(
                  (t) => t.name.like('%Paneer%') | t.name.like('%paneer%'),
                ))
                .get();
        expect(paneerSearch, isNotEmpty);

        await db.close();
      },
    );
  });
}
