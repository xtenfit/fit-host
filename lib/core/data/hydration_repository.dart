import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../sync/sync_outbox_worker.dart';
import '../../features/nutrition/domain/models/nutrition_models.dart';

abstract class HydrationRepository {
  Future<int> getWaterGlasses(DateTime date);
  Future<void> setWaterGlasses(DateTime date, int glasses, {int targetGlasses = 10});
  Future<List<LiquidDrinkEntry>> getLoggedDrinks(DateTime date);
  Future<void> logDrink(LiquidDrinkEntry drink, {DateTime? date});
  Future<void> removeDrink(String drinkId);
}

class LocalHydrationRepository implements HydrationRepository {
  final AppDatabase db;
  final String userId;

  LocalHydrationRepository(this.db, {this.userId = 'guest'});

  @override
  Future<int> getWaterGlasses(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final row = await (db.select(db.hydrationLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(startOfDay) &
              t.logDate.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.updatedAt, mode: drift.OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    return row?.waterGlasses ?? 0;
  }

  @override
  Future<void> setWaterGlasses(DateTime date, int glasses, {int targetGlasses = 10}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final now = DateTime.now();

    final existing = await (db.select(db.hydrationLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(startOfDay) &
              t.logDate.isSmallerOrEqualValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.hydrationLogs)..where((t) => t.id.equals(existing.id))).write(
        HydrationLogsCompanion(
          waterGlasses: drift.Value(glasses),
          targetGlasses: drift.Value(targetGlasses),
          updatedAt: drift.Value(now),
        ),
      );
    } else {
      await db.into(db.hydrationLogs).insert(
            HydrationLogsCompanion.insert(
              id: const Uuid().v4(),
              userId: drift.Value(userId),
              logDate: startOfDay,
              waterGlasses: drift.Value(glasses),
              targetGlasses: drift.Value(targetGlasses),
              loggedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  @override
  Future<List<LiquidDrinkEntry>> getLoggedDrinks(DateTime date) async {
    return [];
  }

  @override
  Future<void> logDrink(LiquidDrinkEntry drink, {DateTime? date}) async {
    final now = DateTime.now();
    await db.into(db.hydrationLogs).insert(
          HydrationLogsCompanion.insert(
            id: drink.id,
            userId: drift.Value(userId),
            logDate: date ?? drink.loggedAt,
            totalMl: drift.Value(drink.volumeMl),
            drinkType: drift.Value(drink.name),
            note: drift.Value(drink.note),
            loggedAt: drink.loggedAt,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> removeDrink(String drinkId) async {
    await (db.update(db.hydrationLogs)..where((t) => t.id.equals(drinkId))).write(
      HydrationLogsCompanion(
        deletedAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }
}

class CloudHydrationRepository implements HydrationRepository {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final SyncOutboxWorker outboxWorker;
  final String userId;
  final LocalHydrationRepository _local;

  CloudHydrationRepository({
    required this.db,
    required this.supabase,
    required this.outboxWorker,
    required this.userId,
  }) : _local = LocalHydrationRepository(db, userId: userId);

  @override
  Future<int> getWaterGlasses(DateTime date) async {
    final cached = await _local.getWaterGlasses(date);
    _backgroundRefreshHydration(date).ignore();
    return cached;
  }

  @override
  Future<void> setWaterGlasses(DateTime date, int glasses, {int targetGlasses = 10}) async {
    await _local.setWaterGlasses(date, glasses, targetGlasses: targetGlasses);

    final dateStr =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final payload = {
      'id': 'hydration_${userId}_$dateStr',
      'user_id': userId,
      'log_date': dateStr,
      'water_glasses': glasses,
      'target_glasses': targetGlasses,
      'total_ml': glasses * 250,
      'logged_at': DateTime.now().toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (supabase != null) {
      try {
        await supabase!.from('hydration_logs').upsert(payload);
        return;
      } catch (e) {
        debugPrint('[CloudHydrationRepository] Cloud write error: $e');
      }
    }

    await outboxWorker.enqueueMutation(
      userId: userId,
      entityType: 'hydration_logs',
      entityId: payload['id'] as String,
      operation: 'INSERT',
      payload: payload,
    );
  }

  @override
  Future<List<LiquidDrinkEntry>> getLoggedDrinks(DateTime date) =>
      _local.getLoggedDrinks(date);

  @override
  Future<void> logDrink(LiquidDrinkEntry drink, {DateTime? date}) async {
    await _local.logDrink(drink, date: date);
    final dateVal = date ?? drink.loggedAt;
    final dateStr =
        "${dateVal.year.toString().padLeft(4, '0')}-${dateVal.month.toString().padLeft(2, '0')}-${dateVal.day.toString().padLeft(2, '0')}";

    final payload = {
      'id': drink.id,
      'user_id': userId,
      'log_date': dateStr,
      'total_ml': drink.volumeMl,
      'drink_type': drink.name,
      'note': drink.note,
      'logged_at': drink.loggedAt.toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (supabase != null) {
      try {
        await supabase!.from('hydration_logs').upsert(payload);
        return;
      } catch (e) {
        debugPrint('[CloudHydrationRepository] Drink cloud write error: $e');
      }
    }

    await outboxWorker.enqueueMutation(
      userId: userId,
      entityType: 'hydration_logs',
      entityId: drink.id,
      operation: 'INSERT',
      payload: payload,
    );
  }

  @override
  Future<void> removeDrink(String drinkId) async {
    await _local.removeDrink(drinkId);

    if (supabase != null) {
      try {
        await supabase!.from('hydration_logs').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).match({'id': drinkId, 'user_id': userId});
        return;
      } catch (e) {
        debugPrint('[CloudHydrationRepository] Drink cloud delete error: $e');
      }
    }

    await outboxWorker.enqueueMutation(
      userId: userId,
      entityType: 'hydration_logs',
      entityId: drinkId,
      operation: 'DELETE',
      payload: {
        'id': drinkId,
        'user_id': userId,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _backgroundRefreshHydration(DateTime date) async {
    if (supabase == null) return;
    try {
      final dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final rows = await supabase!
          .from('hydration_logs')
          .select()
          .match({'user_id': userId, 'log_date': dateStr})
          .isFilter('deleted_at', null);

      for (final r in rows) {
        final id = r['id'] as String;
        final waterGlasses = r['water_glasses'] as int? ?? 0;
        final targetGlasses = r['target_glasses'] as int? ?? 10;
        final totalMl = r['total_ml'] as int? ?? 0;
        final drinkType = r['drink_type'] as String? ?? 'water';
        final note = r['note'] as String?;
        final loggedAt = DateTime.parse(r['logged_at'] as String);
        final createdAt = DateTime.parse(r['created_at'] as String);
        final updatedAt = DateTime.parse(r['updated_at'] as String);

        await db.into(db.hydrationLogs).insertOnConflictUpdate(
              HydrationLogsCompanion.insert(
                id: id,
                userId: drift.Value(userId),
                logDate: DateTime(date.year, date.month, date.day),
                waterGlasses: drift.Value(waterGlasses),
                targetGlasses: drift.Value(targetGlasses),
                totalMl: drift.Value(totalMl),
                drinkType: drift.Value(drinkType),
                note: drift.Value(note),
                loggedAt: loggedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: const drift.Value('synced'),
              ),
            );
      }
    } catch (e) {
      debugPrint('[CloudHydrationRepository] Refresh error: $e');
    }
  }
}

final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  final auth = ref.watch(authProvider);
  final db = ref.watch(databaseProvider);

  if (auth.isAuthenticated && auth.user != null) {
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {}

    final outbox = ref.watch(syncOutboxWorkerProvider);
    return CloudHydrationRepository(
      db: db,
      supabase: client,
      outboxWorker: outbox,
      userId: auth.user!.id,
    );
  }

  return LocalHydrationRepository(db);
});
