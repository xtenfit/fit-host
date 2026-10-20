import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../sync/sync_utils.dart';
import '../../features/nutrition/domain/models/nutrition_models.dart';

abstract class NutritionRepository {
  Future<DailyNutritionState> getDailyNutrition(DateTime date);
  Future<void> saveDailyNutrition(DateTime date, DailyNutritionState state);
  Future<void> logMeal(MealItem meal, {DateTime? date});
  Future<void> removeMeal(String mealId, {DateTime? date});
  Future<void> setWater(int glasses, {DateTime? date});
  Future<void> logDrink(LiquidDrinkEntry drink, {DateTime? date});
  Future<void> removeDrink(String drinkId, {DateTime? date});
}

class LocalNutritionRepository implements NutritionRepository {
  final AppDatabase db;
  final String userId;

  LocalNutritionRepository(this.db, {this.userId = 'guest'});

  @override
  Future<DailyNutritionState> getDailyNutrition(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final row = await (db.select(db.nutritionLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(startOfDay) &
              t.logDate.isSmallerOrEqualValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();

    if (row == null) {
      return const DailyNutritionState();
    }

    List<MealItem> meals = [];
    try {
      final list = jsonDecode(row.loggedMeals) as List<dynamic>;
      meals = list.map((m) {
        final map = m as Map<String, dynamic>;
        return MealItem(
          id: map['id'] as String,
          name: map['name'] as String,
          mealType: map['meal_type'] as String? ?? 'snack',
          dietType: map['diet_type'] as String? ?? 'balanced',
          calories: map['calories'] as int? ?? 0,
          proteinGrams: (map['protein_grams'] as num?)?.toDouble() ?? 0.0,
          carbsGrams: (map['carbs_grams'] as num?)?.toDouble() ?? 0.0,
          fatGrams: (map['fat_grams'] as num?)?.toDouble() ?? 0.0,
          portion: map['portion'] as String? ?? '1 serving',
          loggedAt: map['logged_at'] != null
              ? DateTime.parse(map['logged_at'] as String)
              : DateTime.now(),
        );
      }).toList();
    } catch (_) {}

    List<LiquidDrinkEntry> drinks = [];
    try {
      final list = jsonDecode(row.loggedDrinks) as List<dynamic>;
      drinks = list.map((d) {
        final map = d as Map<String, dynamic>;
        return LiquidDrinkEntry(
          id: map['id'] as String,
          type: LiquidDrinkType.values.firstWhere(
            (t) => t.name == (map['type'] as String? ?? 'water'),
            orElse: () => LiquidDrinkType.water,
          ),
          name: map['name'] as String? ?? 'Water',
          volumeMl: map['volume_ml'] as int? ?? 250,
          loggedAt: map['logged_at'] != null
              ? DateTime.parse(map['logged_at'] as String)
              : DateTime.now(),
          note: map['note'] as String?,
        );
      }).toList();
    } catch (_) {}

    return DailyNutritionState(
      targetCalories: row.targetCalories,
      targetProtein: row.targetProtein,
      targetCarbs: row.targetCarbs,
      targetFat: row.targetFat,
      targetWater: row.targetWaterGlasses,
      waterGlasses: row.waterGlasses,
      loggedMeals: meals,
      loggedDrinks: drinks,
    );
  }

  @override
  Future<void> saveDailyNutrition(DateTime date, DailyNutritionState state) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final now = DateTime.now();

    final mealsJson = jsonEncode(state.loggedMeals.map((m) => {
          'id': m.id,
          'name': m.name,
          'meal_type': m.mealType,
          'diet_type': m.dietType,
          'calories': m.calories,
          'protein_grams': m.proteinGrams,
          'carbs_grams': m.carbsGrams,
          'fat_grams': m.fatGrams,
          'portion': m.portion,
          'logged_at': m.loggedAt.toIso8601String(),
        }).toList());

    final drinksJson = jsonEncode(state.loggedDrinks.map((d) => {
          'id': d.id,
          'name': d.name,
          'type': d.type.name,
          'volume_ml': d.volumeMl,
          'logged_at': d.loggedAt.toIso8601String(),
          'note': d.note,
        }).toList());

    final existing = await (db.select(db.nutritionLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(startOfDay) &
              t.logDate.isSmallerOrEqualValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();

    final rowId = existing?.id ?? 'nutrition_${userId}_${startOfDay.toIso8601String().substring(0, 10)}';

    await db.into(db.nutritionLogs).insertOnConflictUpdate(
          NutritionLogsCompanion.insert(
            id: rowId,
            userId: drift.Value(userId),
            logDate: startOfDay,
            targetCalories: drift.Value(state.targetCalories),
            targetProtein: drift.Value(state.targetProtein),
            targetCarbs: drift.Value(state.targetCarbs),
            targetFat: drift.Value(state.targetFat),
            targetWaterGlasses: drift.Value(state.targetWater),
            waterGlasses: drift.Value(state.waterGlasses),
            loggedMeals: drift.Value(mealsJson),
            loggedDrinks: drift.Value(drinksJson),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            syncStatus: const drift.Value('pending'),
          ),
        );
  }

  @override
  Future<void> logMeal(MealItem meal, {DateTime? date}) async {
    final current = await getDailyNutrition(date ?? meal.loggedAt);
    final updated = current.copyWith(
      loggedMeals: [...current.loggedMeals, meal],
    );
    await saveDailyNutrition(date ?? meal.loggedAt, updated);
  }

  @override
  Future<void> removeMeal(String mealId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final current = await getDailyNutrition(targetDate);
    final updated = current.copyWith(
      loggedMeals: current.loggedMeals.where((m) => m.id != mealId).toList(),
    );
    await saveDailyNutrition(targetDate, updated);
  }

  @override
  Future<void> setWater(int glasses, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final current = await getDailyNutrition(targetDate);
    final updated = current.copyWith(waterGlasses: glasses);
    await saveDailyNutrition(targetDate, updated);
  }

  @override
  Future<void> logDrink(LiquidDrinkEntry drink, {DateTime? date}) async {
    final targetDate = date ?? drink.loggedAt;
    final current = await getDailyNutrition(targetDate);
    final additionalGlasses = (drink.volumeMl / 250).round();
    final newGlasses =
        (current.waterGlasses + additionalGlasses).clamp(0, current.targetWater);
    final updated = current.copyWith(
      loggedDrinks: [drink, ...current.loggedDrinks],
      waterGlasses: newGlasses,
    );
    await saveDailyNutrition(targetDate, updated);
  }

  @override
  Future<void> removeDrink(String drinkId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final current = await getDailyNutrition(targetDate);
    final drink = current.loggedDrinks.firstWhere((d) => d.id == drinkId,
        orElse: () => LiquidDrinkEntry(
              id: '',
              type: LiquidDrinkType.water,
              name: '',
              volumeMl: 0,
              loggedAt: DateTime.now(),
            ));
    if (drink.id.isNotEmpty) {
      final deductGlasses = (drink.volumeMl / 250).round();
      final newGlasses = (current.waterGlasses - deductGlasses)
          .clamp(0, current.targetWater);
      final updated = current.copyWith(
        loggedDrinks:
            current.loggedDrinks.where((d) => d.id != drinkId).toList(),
        waterGlasses: newGlasses,
      );
      await saveDailyNutrition(targetDate, updated);
    }
  }
}

class CloudNutritionRepository implements NutritionRepository {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final String userId;
  final LocalNutritionRepository _local;

  CloudNutritionRepository({
    required this.db,
    required this.supabase,
    required this.userId,
  }) : _local = LocalNutritionRepository(db, userId: userId);

  @override
  Future<DailyNutritionState> getDailyNutrition(DateTime date) async {
    if (supabase != null) {
      try {
        await _fetchRemoteAndSave(date).timeout(const Duration(seconds: 4));
        return await _local.getDailyNutrition(date);
      } catch (e) {
        debugPrint('[CloudNutritionRepository] Remote fetch notice (using cache): $e');
      }
    }
    return await _local.getDailyNutrition(date);
  }

  @override
  Future<void> saveDailyNutrition(DateTime date, DailyNutritionState state) async {
    await _local.saveDailyNutrition(date, state);

    if (isValidUuid(userId)) {
      final dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final mealsJson = state.loggedMeals.map((m) => {
            'id': m.id,
            'name': m.name,
            'meal_type': m.mealType,
            'diet_type': m.dietType,
            'calories': m.calories,
            'protein_grams': m.proteinGrams,
            'carbs_grams': m.carbsGrams,
            'fat_grams': m.fatGrams,
            'portion': m.portion,
            'logged_at': m.loggedAt.toIso8601String(),
          }).toList();

      final drinksJson = state.loggedDrinks.map((d) => {
            'id': d.id,
            'name': d.name,
            'type': d.type.name,
            'volume_ml': d.volumeMl,
            'logged_at': d.loggedAt.toIso8601String(),
            'note': d.note,
          }).toList();

      // Confirmed user_id sent explicitly by client on every insert (Condition 6)
      final payload = {
        'id': 'nutrition_${userId}_$dateStr',
        'user_id': userId,
        'log_date': dateStr,
        'target_calories': state.targetCalories,
        'target_protein': state.targetProtein,
        'target_carbs': state.targetCarbs,
        'target_fat': state.targetFat,
        'target_water_glasses': state.targetWater,
        'water_glasses': state.waterGlasses,
        'logged_meals': mealsJson,
        'logged_drinks': drinksJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      bool remoteWriteSucceeded = false;
      if (supabase != null) {
        try {
          await supabase!.from('nutrition_logs').upsert(payload, onConflict: 'id');
          remoteWriteSucceeded = true;
        } catch (e) {
          debugPrint('[CloudNutritionRepository] Supabase write failed, queueing: $e');
        }
      }

      if (!remoteWriteSucceeded) {
        // Queue in sync_queue with valid userId
        await db.into(db.syncQueue).insertOnConflictUpdate(
              SyncQueueCompanion.insert(
                id: const Uuid().v4(),
                userId: drift.Value(userId),
                entityType: 'nutrition_logs',
                entityId: payload['id'] as String,
                operation: 'upsert',
                payload: jsonEncode(payload),
                createdAt: DateTime.now().toUtc(),
                clientTimestamp: drift.Value(DateTime.now().toUtc()),
                status: const drift.Value('queued'),
              ),
            );
      }
    }
  }

  @override
  Future<void> logMeal(MealItem meal, {DateTime? date}) async {
    final current = await getDailyNutrition(date ?? meal.loggedAt);
    final updated = current.copyWith(loggedMeals: [...current.loggedMeals, meal]);
    await saveDailyNutrition(date ?? meal.loggedAt, updated);
  }

  @override
  Future<void> removeMeal(String mealId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final current = await getDailyNutrition(targetDate);
    final updated = current.copyWith(
      loggedMeals: current.loggedMeals.where((m) => m.id != mealId).toList(),
    );
    await saveDailyNutrition(targetDate, updated);
  }

  @override
  Future<void> setWater(int glasses, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final current = await getDailyNutrition(targetDate);
    final updated = current.copyWith(waterGlasses: glasses);
    await saveDailyNutrition(targetDate, updated);
  }

  @override
  Future<void> logDrink(LiquidDrinkEntry drink, {DateTime? date}) async {
    final targetDate = date ?? drink.loggedAt;
    final current = await getDailyNutrition(targetDate);
    final additionalGlasses = (drink.volumeMl / 250).round();
    final newGlasses = (current.waterGlasses + additionalGlasses)
        .clamp(0, current.targetWater);
    final updated = current.copyWith(
      loggedDrinks: [drink, ...current.loggedDrinks],
      waterGlasses: newGlasses,
    );
    await saveDailyNutrition(targetDate, updated);
  }

  @override
  Future<void> removeDrink(String drinkId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final current = await getDailyNutrition(targetDate);
    final drink = current.loggedDrinks.firstWhere((d) => d.id == drinkId,
        orElse: () => LiquidDrinkEntry(
              id: '',
              type: LiquidDrinkType.water,
              name: '',
              volumeMl: 0,
              loggedAt: DateTime.now(),
            ));
    if (drink.id.isNotEmpty) {
      final deductGlasses = (drink.volumeMl / 250).round();
      final newGlasses =
          (current.waterGlasses - deductGlasses).clamp(0, current.targetWater);
      final updated = current.copyWith(
        loggedDrinks:
            current.loggedDrinks.where((d) => d.id != drinkId).toList(),
        waterGlasses: newGlasses,
      );
      await saveDailyNutrition(targetDate, updated);
    }
  }

  Future<void> _fetchRemoteAndSave(DateTime date) async {
    if (supabase == null) return;
    try {
      final dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final row = await supabase!
          .from('nutrition_logs')
          .select()
          .match({'user_id': userId, 'log_date': dateStr})
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (row != null) {
        final id = row['id'] as String;
        final targetCalories = row['target_calories'] as int? ?? 2250;
        final targetProtein = row['target_protein'] as int? ?? 145;
        final targetCarbs = row['target_carbs'] as int? ?? 250;
        final targetFat = row['target_fat'] as int? ?? 60;
        final targetWaterGlasses = row['target_water_glasses'] as int? ?? 10;
        final waterGlasses = row['water_glasses'] as int? ?? 0;
        final loggedMeals = jsonEncode(row['logged_meals'] ?? []);
        final loggedDrinks = jsonEncode(row['logged_drinks'] ?? []);
        final updatedAt = DateTime.parse(row['updated_at'] as String);

        await db.into(db.nutritionLogs).insertOnConflictUpdate(
              NutritionLogsCompanion.insert(
                id: id,
                userId: drift.Value(userId),
                logDate: DateTime(date.year, date.month, date.day),
                targetCalories: drift.Value(targetCalories),
                targetProtein: drift.Value(targetProtein),
                targetCarbs: drift.Value(targetCarbs),
                targetFat: drift.Value(targetFat),
                targetWaterGlasses: drift.Value(targetWaterGlasses),
                waterGlasses: drift.Value(waterGlasses),
                loggedMeals: drift.Value(loggedMeals),
                loggedDrinks: drift.Value(loggedDrinks),
                createdAt: DateTime.now(),
                updatedAt: updatedAt,
                syncStatus: const drift.Value('synced'),
              ),
            );
      }
    } catch (e) {
      debugPrint('[CloudNutritionRepository] Background refresh notice: $e');
    }
  }
}

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final auth = ref.watch(authProvider);
  final db = ref.watch(databaseProvider);

  if (auth.isAuthenticated && auth.user != null) {
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {}

    return CloudNutritionRepository(
      db: db,
      supabase: client,
      userId: auth.user!.id,
    );
  }

  return LocalNutritionRepository(db);
});
