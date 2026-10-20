import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/food_item.dart';
import '../../domain/repositories/food_repository.dart';
import '../services/openfoodfacts_service.dart';
export '../services/gemini_nutrition_service.dart';

class FoodRepositoryImpl implements FoodRepository {
  final AppDatabase db;
  final OpenFoodFactsService offService;
  final String userId;
  final SupabaseClient? supabaseClient;

  FoodRepositoryImpl({
    required this.db,
    OpenFoodFactsService? offService,
    this.userId = 'guest',
    this.supabaseClient,
  }) : offService = offService ?? OpenFoodFactsService();

  FoodItem _mapRowToFoodItem(FoodItemData row) {
    List<ServingPreset> presets = [];
    try {
      final list = jsonDecode(row.servingPresetsJson) as List<dynamic>;
      presets = list
          .map((p) => ServingPreset.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    return FoodItem(
      id: row.id,
      barcode: row.barcode,
      name: row.name,
      brand: row.brand,
      proteinPer100g: row.proteinPer100g,
      carbsPer100g: row.carbsPer100g,
      fatsPer100g: row.fatsPer100g,
      caloriesPer100g: row.caloriesPer100g,
      servingPresets: presets,
      source: FoodSource.values.firstWhere(
        (s) => s.name == row.source,
        orElse: () => FoodSource.seeded,
      ),
      imageUrl: row.imageUrl,
      createdAt: row.createdAt,
    );
  }

  FoodItemsCompanion _mapFoodItemToCompanion(FoodItem food) {
    return FoodItemsCompanion.insert(
      id: food.id,
      barcode: drift.Value(food.barcode),
      name: food.name,
      brand: drift.Value(food.brand),
      proteinPer100g: drift.Value(food.proteinPer100g),
      carbsPer100g: drift.Value(food.carbsPer100g),
      fatsPer100g: drift.Value(food.fatsPer100g),
      caloriesPer100g: drift.Value(food.caloriesPer100g),
      servingPresetsJson: drift.Value(
          jsonEncode(food.servingPresets.map((p) => p.toJson()).toList())),
      source: drift.Value(food.source.name),
      imageUrl: drift.Value(food.imageUrl),
      createdAt: drift.Value(food.createdAt),
      updatedAt: drift.Value(DateTime.now()),
      userId: drift.Value(userId),
    );
  }

  @override
  Future<List<FoodItem>> searchFoods(String query, {int limit = 30}) async {
    final cleanQuery = query.trim().toLowerCase();

    // 1. Search local Drift database
    final localRows = await (db.select(db.foodItems)
          ..where((t) {
            final notDeleted = t.isDeleted.equals(0);
            if (cleanQuery.isEmpty) return notDeleted;
            return notDeleted &
                (t.name.lower().like('%$cleanQuery%') |
                    t.brand.lower().like('%$cleanQuery%') |
                    t.barcode.equals(cleanQuery));
          })
          ..limit(limit))
        .get();

    final results = localRows.map(_mapRowToFoodItem).toList();

    // 2. If fewer than 5 results and query has at least 3 characters, query OpenFoodFacts
    if (results.length < 5 && cleanQuery.length >= 3) {
      try {
        final offResults = await offService.searchProducts(cleanQuery, limit: 15);
        for (final offItem in offResults) {
          if (!results.any((r) => r.id == offItem.id || (r.barcode != null && r.barcode == offItem.barcode))) {
            // Cache locally in Drift
            try {
              await db.into(db.foodItems).insertOnConflictUpdate(
                    _mapFoodItemToCompanion(offItem),
                  );
            } catch (_) {}
            results.add(offItem);
          }
        }
      } catch (e) {
        debugPrint('[FoodRepository] OFF search fallback error: $e');
      }
    }

    return results;
  }

  @override
  Future<FoodItem?> getFoodByBarcode(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    // 1. Check local Drift cache first
    final localRow = await (db.select(db.foodItems)
          ..where((t) => t.barcode.equals(clean) & t.isDeleted.equals(0))
          ..limit(1))
        .getSingleOrNull();

    if (localRow != null) {
      return _mapRowToFoodItem(localRow);
    }

    // 2. Query OpenFoodFacts
    final offProduct = await offService.fetchProductByBarcode(clean);
    if (offProduct != null) {
      // Cache in local Drift database for future fast offline access
      try {
        await db.into(db.foodItems).insertOnConflictUpdate(
              _mapFoodItemToCompanion(offProduct),
            );
      } catch (e) {
        debugPrint('[FoodRepository] Cache insertion error: $e');
      }
      return offProduct;
    }

    return null;
  }

  @override
  Future<void> saveFood(FoodItem food) async {
    await db.into(db.foodItems).insertOnConflictUpdate(
          _mapFoodItemToCompanion(food),
        );

    // If authenticated user and food is user_custom or gemini, push to Supabase & outbox
    if (userId != 'guest' &&
        supabaseClient != null &&
        (food.source == FoodSource.user_custom || food.source == FoodSource.gemini)) {
      try {
        await supabaseClient!.from('food_items').upsert({
          'id': food.id,
          'barcode': food.barcode,
          'name': food.name,
          'brand': food.brand,
          'protein_per_100g': food.proteinPer100g,
          'carbs_per_100g': food.carbsPer100g,
          'fats_per_100g': food.fatsPer100g,
          'calories_per_100g': food.caloriesPer100g,
          'serving_presets_json':
              jsonEncode(food.servingPresets.map((p) => p.toJson()).toList()),
          'source': food.source.name,
          'image_url': food.imageUrl,
          'user_id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[FoodRepository] Cloud upsert error: $e');
        // Enqueue into SyncQueue for retry
        try {
          await db.into(db.syncQueue).insert(
                SyncQueueCompanion.insert(
                  id: const Uuid().v4(),
                  userId: drift.Value(userId),
                  entityType: 'food_items',
                  entityId: food.id,
                  operation: 'upsert',
                  payload: jsonEncode(food.toJson()),
                  createdAt: DateTime.now(),
                  status: const drift.Value('queued'),
                ),
              );
        } catch (_) {}
      }
    }
  }

  @override
  Future<List<FoodItem>> getRecentFoods({int limit = 8}) async {
    try {
      // Query recent 14 days of nutrition logs
      final now = DateTime.now();
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));

      final logs = await (db.select(db.nutritionLogs)
            ..where((t) =>
                t.userId.equals(userId) &
                t.deletedAt.isNull() &
                t.logDate.isBiggerOrEqualValue(fourteenDaysAgo))
            ..orderBy([(t) => drift.OrderingTerm.desc(t.logDate)])
            ..limit(14))
          .get();

      final recentNames = <String>{};
      final recentList = <FoodItem>[];

      for (final log in logs) {
        try {
          final list = jsonDecode(log.loggedMeals) as List<dynamic>;
          for (final m in list.reversed) {
            if (m is Map<String, dynamic>) {
              final name = (m['name'] as String?)?.trim() ?? '';
              if (name.isNotEmpty && !recentNames.contains(name)) {
                recentNames.add(name);

                // Try to find matching food in Drift
                final match = await (db.select(db.foodItems)
                      ..where((t) => t.name.equals(name))
                      ..limit(1))
                    .getSingleOrNull();

                if (match != null) {
                  recentList.add(_mapRowToFoodItem(match));
                } else {
                  // Synthesize food item from logged meal
                  recentList.add(
                    FoodItem(
                      id: m['id'] as String? ?? const Uuid().v4(),
                      name: name,
                      proteinPer100g:
                          (m['protein_grams'] as num?)?.toDouble() ?? 10.0,
                      carbsPer100g:
                          (m['carbs_grams'] as num?)?.toDouble() ?? 20.0,
                      fatsPer100g: (m['fat_grams'] as num?)?.toDouble() ?? 5.0,
                      caloriesPer100g: (m['calories'] as num?)?.toDouble() ?? 150.0,
                      source: FoodSource.user_custom,
                      createdAt: DateTime.now(),
                      servingPresets: const [
                        ServingPreset(label: '1 serving (100g)', grams: 100),
                        ServingPreset(label: '1 portion (150g)', grams: 150),
                      ],
                    ),
                  );
                }

                if (recentList.length >= limit) return recentList;
              }
            }
          }
        } catch (_) {}
      }

      // If fewer than limit, pad with top seeded items
      if (recentList.length < limit) {
        final seeded = await (db.select(db.foodItems)
              ..where((t) => t.source.equals('seeded'))
              ..limit(limit - recentList.length))
            .get();
        for (final row in seeded) {
          final item = _mapRowToFoodItem(row);
          if (!recentNames.contains(item.name)) {
            recentNames.add(item.name);
            recentList.add(item);
          }
        }
      }

      return recentList;
    } catch (e) {
      debugPrint('[FoodRepository] getRecentFoods error: $e');
      return [];
    }
  }
}

final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  return OpenFoodFactsService();
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final offService = ref.watch(openFoodFactsServiceProvider);
  final authStatus = ref.watch(authStatusProvider);
  final user = ref.watch(currentUserProvider);
  final userId = authStatus == AuthStatus.authenticated && user != null
      ? user.id
      : 'guest';
  SupabaseClient? supabase;
  try {
    supabase = Supabase.instance.client;
  } catch (_) {}

  return FoodRepositoryImpl(
    db: db,
    offService: offService,
    userId: userId,
    supabaseClient: supabase,
  );
});
