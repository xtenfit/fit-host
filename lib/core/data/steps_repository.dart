import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../sync/sync_outbox_worker.dart';
import '../../features/steps/domain/daily_step_record.dart';

abstract class StepsRepository {
  Future<int> getDailySteps(DateTime date);
  Future<DailyStepRecord?> getDailyStepRecord(DateTime date);
  Future<List<DailyStepRecord>> getStepsHistory({int days = 7});
  Future<void> setDailySteps(
    DateTime date,
    int steps, {
    int target = 10000,
    double distance = 0.0,
    int calories = 0,
    int activeMinutes = 0,
    String tzOffset = '+00:00',
  });
}

class LocalStepsRepository implements StepsRepository {
  final AppDatabase db;
  final String userId;

  LocalStepsRepository(this.db, {this.userId = 'guest'});

  @override
  Future<int> getDailySteps(DateTime date) async {
    final record = await getDailyStepRecord(date);
    return record?.steps ?? 0;
  }

  @override
  Future<DailyStepRecord?> getDailyStepRecord(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final row = await (db.select(db.stepDailyLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.stepDate.isBiggerOrEqualValue(startOfDay) &
              t.stepDate.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.updatedAt, mode: drift.OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    if (row == null) return null;

    final distanceKm = row.distanceMeters / 1000.0;
    final activeMinutes = row.steps ~/ 100;

    return DailyStepRecord(
      id: row.id,
      userId: row.userId,
      date: row.stepDate,
      steps: row.steps,
      targetSteps: row.targetSteps,
      distanceKm: distanceKm,
      activeCalories: row.activeCalories,
      activeMinutes: activeMinutes,
      timezoneOffset: '+00:00',
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<List<DailyStepRecord>> getStepsHistory({int days = 7}) async {
    final now = DateTime.now();
    final List<DailyStepRecord> history = [];

    // Guests only get today's step count in history (Deliverable A)
    final effectiveDays = userId == 'guest' ? 1 : days;

    for (int i = effectiveDays - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final rec = await getDailyStepRecord(d);
      if (rec != null) {
        history.add(rec);
      } else {
        history.add(DailyStepRecord(
          id: 'step_empty_${d.year}_${d.month}_${d.day}',
          userId: userId,
          date: DateTime(d.year, d.month, d.day),
          steps: 0,
          targetSteps: 10000,
          distanceKm: 0.0,
          activeCalories: 0,
          activeMinutes: 0,
          updatedAt: DateTime.now(),
        ));
      }
    }

    return history;
  }

  @override
  Future<void> setDailySteps(
    DateTime date,
    int steps, {
    int target = 10000,
    double distance = 0.0,
    int calories = 0,
    int activeMinutes = 0,
    String tzOffset = '+00:00',
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final now = DateTime.now();

    final existing = await (db.select(db.stepDailyLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.stepDate.isBiggerOrEqualValue(startOfDay) &
              t.stepDate.isSmallerOrEqualValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.stepDailyLogs)..where((t) => t.id.equals(existing.id))).write(
        StepDailyLogsCompanion(
          steps: drift.Value(steps),
          targetSteps: drift.Value(target),
          distanceMeters: drift.Value(distance),
          activeCalories: drift.Value(calories),
          updatedAt: drift.Value(now),
        ),
      );
    } else {
      await db.into(db.stepDailyLogs).insert(
            StepDailyLogsCompanion.insert(
              id: const Uuid().v4(),
              userId: drift.Value(userId),
              stepDate: startOfDay,
              steps: drift.Value(steps),
              targetSteps: drift.Value(target),
              distanceMeters: drift.Value(distance),
              activeCalories: drift.Value(calories),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }
}

class CloudStepsRepository implements StepsRepository {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final SyncOutboxWorker outboxWorker;
  final String userId;
  final LocalStepsRepository _local;

  CloudStepsRepository({
    required this.db,
    required this.supabase,
    required this.outboxWorker,
    required this.userId,
  }) : _local = LocalStepsRepository(db, userId: userId);

  @override
  Future<int> getDailySteps(DateTime date) async {
    final cached = await _local.getDailySteps(date);
    _backgroundRefreshSteps(date).ignore();
    return cached;
  }

  @override
  Future<DailyStepRecord?> getDailyStepRecord(DateTime date) async {
    final cached = await _local.getDailyStepRecord(date);
    _backgroundRefreshSteps(date).ignore();
    return cached;
  }

  @override
  Future<List<DailyStepRecord>> getStepsHistory({int days = 7}) async {
    final cached = await _local.getStepsHistory(days: days);
    return cached;
  }

  @override
  Future<void> setDailySteps(
    DateTime date,
    int steps, {
    int target = 10000,
    double distance = 0.0,
    int calories = 0,
    int activeMinutes = 0,
    String tzOffset = '+00:00',
  }) async {
    await _local.setDailySteps(
      date,
      steps,
      target: target,
      distance: distance,
      calories: calories,
      activeMinutes: activeMinutes,
      tzOffset: tzOffset,
    );

    final dateStr =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final payload = {
      'id': 'step_${userId}_$dateStr',
      'user_id': userId,
      'step_date': dateStr,
      'steps': steps,
      'target_steps': target,
      'distance_meters': distance,
      'active_calories': calories,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (supabase != null) {
      try {
        await supabase!.from('step_daily_logs').upsert(payload, onConflict: 'user_id, step_date');
        return;
      } catch (e) {
        debugPrint('[CloudStepsRepository] Cloud steps write failed: $e');
      }
    }

    await outboxWorker.enqueueMutation(
      userId: userId,
      entityType: 'step_daily_logs',
      entityId: payload['id'] as String,
      operation: 'INSERT',
      payload: payload,
    );
  }

  Future<void> _backgroundRefreshSteps(DateTime date) async {
    if (supabase == null) return;
    try {
      final dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final rows = await supabase!
          .from('step_daily_logs')
          .select()
          .match({'user_id': userId, 'step_date': dateStr})
          .isFilter('deleted_at', null);

      for (final r in rows) {
        final id = r['id'] as String;
        final steps = r['steps'] as int? ?? 0;
        final targetSteps = r['target_steps'] as int? ?? 10000;
        final distanceMeters = (r['distance_meters'] as num?)?.toDouble() ?? 0.0;
        final activeCalories = r['active_calories'] as int? ?? 0;
        final createdAt = DateTime.parse(r['created_at'] as String);
        final updatedAt = DateTime.parse(r['updated_at'] as String);

        await db.into(db.stepDailyLogs).insertOnConflictUpdate(
              StepDailyLogsCompanion.insert(
                id: id,
                userId: drift.Value(userId),
                stepDate: DateTime(date.year, date.month, date.day),
                steps: drift.Value(steps),
                targetSteps: drift.Value(targetSteps),
                distanceMeters: drift.Value(distanceMeters),
                activeCalories: drift.Value(activeCalories),
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: const drift.Value('synced'),
              ),
            );
      }
    } catch (e) {
      debugPrint('[CloudStepsRepository] Background refresh notice: $e');
    }
  }
}

final stepsRepositoryProvider = Provider<StepsRepository>((ref) {
  final auth = ref.watch(authProvider);
  final db = ref.watch(databaseProvider);

  if (auth.isAuthenticated && auth.user != null) {
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {}

    final outbox = ref.watch(syncOutboxWorkerProvider);
    return CloudStepsRepository(
      db: db,
      supabase: client,
      outboxWorker: outbox,
      userId: auth.user!.id,
    );
  }

  return LocalStepsRepository(db);
});
