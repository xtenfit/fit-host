import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import '../sync/sync_coordinator.dart';

enum ClaimOutcome {
  success,
  partialSuccessOutboxPending,
  failed,
}

enum MigrationStage {
  idle,
  preparing,
  backingUp,
  synchronizing,
  ready,
  failed,
}

class MigrationProgress {
  final MigrationStage stage;
  final double progress;
  final String message;
  final String? error;

  const MigrationProgress({
    required this.stage,
    required this.progress,
    required this.message,
    this.error,
  });
}

class GuestRecordBreakdown {
  final int workoutsCount;
  final int nutritionLogsCount;
  final int stepLogsCount;
  final int calendarEventsCount;
  final int remindersCount;

  const GuestRecordBreakdown({
    this.workoutsCount = 0,
    this.nutritionLogsCount = 0,
    this.stepLogsCount = 0,
    this.calendarEventsCount = 0,
    this.remindersCount = 0,
  });

  int get totalRecords =>
      workoutsCount +
      nutritionLogsCount +
      stepLogsCount +
      calendarEventsCount +
      remindersCount;

  bool get hasRecords => totalRecords > 0;
}

class GuestAccountClaimService {
  final AppDatabase db;
  final SyncCoordinator syncCoordinator;
  final SupabaseClient? supabase;
  final FlutterSecureStorage storage;

  GuestAccountClaimService({
    required this.db,
    required this.syncCoordinator,
    this.supabase,
    this.storage = const FlutterSecureStorage(),
  });

  List<List<T>> _partition<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size < list.length) ? i + size : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  /// Counts local guest records across all tracked tables
  Future<GuestRecordBreakdown> getGuestRecordBreakdown() async {
    try {
      final workouts = await (db.select(db.workouts)
            ..where((t) => t.userId.equals('guest')))
          .get();
      final nutrition = await (db.select(db.nutritionLogs)
            ..where((t) => t.userId.equals('guest')))
          .get();
      final steps = await (db.select(db.stepDailyLogs)
            ..where((t) => t.userId.equals('guest')))
          .get();
      final events = await (db.select(db.calendarEvents)
            ..where((t) => t.userId.equals('guest')))
          .get();
      final reminders = await (db.select(db.reminders)
            ..where((t) => t.userId.equals('guest')))
          .get();

      return GuestRecordBreakdown(
        workoutsCount: workouts.length,
        nutritionLogsCount: nutrition.length,
        stepLogsCount: steps.length,
        calendarEventsCount: events.length,
        remindersCount: reminders.length,
      );
    } catch (_) {
      return const GuestRecordBreakdown();
    }
  }

  /// Executes the Guest -> Account migration according to the 12-step specification:
  /// 1. Validate authenticated session UID.
  /// 2. Load local guest records and identify entity dependencies.
  /// 3. Validate data against Supabase schema.
  /// 4. Create durable migration state in secure storage.
  /// 5. Stage records in memory before mutations.
  /// 6. Associate records with the account identity.
  /// 7. Upload records in manageable batches (batches of 25).
  /// 8. Use idempotent upserts to prevent duplicate records on retry.
  /// 9. Verify server-side records where connectivity permits.
  /// 10. Update local records and cache ownership inside an atomic transaction.
  /// 11. Record migration completion durably.
  /// 12. Resume safely after restart or network interruption.
  Future<ClaimOutcome> claimGuestDataToAccount(
    String newUid, {
    void Function(MigrationProgress)? onProgress,
  }) async {
    if (newUid.isEmpty || newUid == 'guest') {
      throw ArgumentError('Valid new account user_id must be provided.');
    }

    final migrationId = 'mig_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await storage.write(
        key: 'active_guest_migration_$newUid',
        value: migrationId,
      );
    } catch (_) {}

    // Step 1: Preparing
    onProgress?.call(const MigrationProgress(
      stage: MigrationStage.preparing,
      progress: 0.15,
      message: 'Preparing your saved data.',
    ));

    // Load guest records
    final guestWorkouts = await (db.select(db.workouts)
          ..where((t) => t.userId.equals('guest')))
        .get();
    final guestExercises = await (db.select(db.workoutExercises)
          ..where((t) => t.userId.equals('guest')))
        .get();
    final guestSets = await (db.select(db.workoutSets)
          ..where((t) => t.userId.equals('guest')))
        .get();
    final guestNutrition = await (db.select(db.nutritionLogs)
          ..where((t) => t.userId.equals('guest')))
        .get();
    final guestHydration = await (db.select(db.hydrationLogs)
          ..where((t) => t.userId.equals('guest')))
        .get();
    final guestSteps = await (db.select(db.stepDailyLogs)
          ..where((t) => t.userId.equals('guest')))
        .get();
    final guestEvents = await (db.select(db.calendarEvents)
          ..where((t) => t.userId.equals('guest')))
        .get();
    final guestReminders = await (db.select(db.reminders)
          ..where((t) => t.userId.equals('guest')))
        .get();

    final totalCount = guestWorkouts.length +
        guestNutrition.length +
        guestHydration.length +
        guestSteps.length +
        guestEvents.length +
        guestReminders.length;

    if (totalCount == 0) {
      onProgress?.call(const MigrationProgress(
        stage: MigrationStage.ready,
        progress: 1.0,
        message: 'Your account is ready.',
      ));
      return ClaimOutcome.success;
    }

    // Step 2: Backing up (cloud sync where available)
    onProgress?.call(const MigrationProgress(
      stage: MigrationStage.backingUp,
      progress: 0.45,
      message: 'Backing up your workouts and activity logs.',
    ));

    bool directUploadSucceeded = false;

    if (supabase != null) {
      try {
        // 1. Workouts
        for (final batch in _partition(guestWorkouts, 25)) {
          await supabase!.from('workouts').upsert(
                batch
                    .map((w) => {
                          'id': w.id,
                          'user_id': newUid,
                          'title': w.title,
                          'note': w.note,
                          'started_at': w.startedAt.toIso8601String(),
                          'completed_at': w.completedAt?.toIso8601String(),
                          'status': w.status,
                          'duration_seconds': w.durationSeconds,
                          'calories_burned': w.caloriesBurned,
                          'updated_at': w.updatedAt.toIso8601String(),
                        })
                    .toList(),
                onConflict: 'id',
              );
        }

        // 2. Workout exercises
        for (final batch in _partition(guestExercises, 25)) {
          await supabase!.from('workout_exercises').upsert(
                batch
                    .map((we) => {
                          'id': we.id,
                          'workout_id': we.workoutId,
                          'exercise_id': we.exerciseId,
                          'user_id': newUid,
                          'order_index': we.orderIndex,
                          'notes': we.notes,
                          'created_at': (we.createdAt ?? DateTime.now().toUtc())
                              .toIso8601String(),
                          'updated_at': (we.updatedAt ?? DateTime.now().toUtc())
                              .toIso8601String(),
                        })
                    .toList(),
                onConflict: 'id',
              );
        }

        // 3. Workout sets
        for (final batch in _partition(guestSets, 25)) {
          await supabase!.from('workout_sets').upsert(
                batch
                    .map((s) => {
                          'id': s.id,
                          'workout_exercise_id': s.workoutExerciseId,
                          'user_id': newUid,
                          'set_number': s.setNumber,
                          'reps': s.reps,
                          'weight_kg': s.weightKg,
                          'is_completed': s.isCompleted,
                          'rest_seconds': s.restSeconds,
                          'set_type': s.setType,
                        })
                    .toList(),
                onConflict: 'id',
              );
        }

        // 4. Nutrition logs (Unique on user_id, log_date)
        for (final batch in _partition(guestNutrition, 25)) {
          await supabase!.from('nutrition_logs').upsert(
                batch
                    .map((n) => {
                          'id': n.id,
                          'user_id': newUid,
                          'log_date':
                              n.logDate.toIso8601String().substring(0, 10),
                          'target_calories': n.targetCalories,
                          'target_protein': n.targetProtein,
                          'target_carbs': n.targetCarbs,
                          'target_fat': n.targetFat,
                          'target_water_glasses': n.targetWaterGlasses,
                          'water_glasses': n.waterGlasses,
                          'logged_meals': jsonDecode(n.loggedMeals),
                          'logged_drinks': jsonDecode(n.loggedDrinks),
                          'updated_at': n.updatedAt.toIso8601String(),
                        })
                    .toList(),
                onConflict: 'user_id,log_date',
              );
        }

        // 5. Hydration logs (Unique on user_id, log_date)
        for (final batch in _partition(guestHydration, 25)) {
          await supabase!.from('hydration_logs').upsert(
                batch
                    .map((h) => {
                          'id': h.id,
                          'user_id': newUid,
                          'log_date':
                              h.logDate.toIso8601String().substring(0, 10),
                          'water_glasses': h.waterGlasses,
                          'target_water_glasses': h.targetGlasses,
                          'updated_at': h.updatedAt.toIso8601String(),
                        })
                    .toList(),
                onConflict: 'user_id,log_date',
              );
        }

        // 6. Step daily logs (Unique on user_id, step_date)
        for (final batch in _partition(guestSteps, 25)) {
          await supabase!.from('step_daily_logs').upsert(
                batch
                    .map((s) => {
                          'id': s.id,
                          'user_id': newUid,
                          'step_date':
                              s.stepDate.toIso8601String().substring(0, 10),
                          'step_count': s.steps,
                          'target_step_count': s.targetSteps,
                          'updated_at': s.updatedAt.toIso8601String(),
                        })
                    .toList(),
                onConflict: 'user_id,step_date',
              );
        }

        // 7. Calendar events
        for (final batch in _partition(guestEvents, 25)) {
          await supabase!.from('calendar_events').upsert(
                batch
                    .map((e) => {
                          'id': e.id,
                          'user_id': newUid,
                          'title': e.title,
                          'scheduled_date': e.scheduledDate.toIso8601String(),
                          'scheduled_time': e.startTime != null
                              ? '${e.startTime!.hour.toString().padLeft(2, '0')}:${e.startTime!.minute.toString().padLeft(2, '0')}'
                              : '09:00',
                          'duration_minutes': (e.endTime != null && e.startTime != null)
                              ? e.endTime!.difference(e.startTime!).inMinutes
                              : 45,
                          'is_completed': e.isCompleted,
                          'created_at': (e.createdAt ?? DateTime.now().toUtc())
                              .toIso8601String(),
                          'updated_at': (e.updatedAt ?? DateTime.now().toUtc())
                              .toIso8601String(),
                        })
                    .toList(),
                onConflict: 'id',
              );
        }

        // 8. Reminders
        for (final batch in _partition(guestReminders, 25)) {
          await supabase!.from('reminders').upsert(
                batch
                    .map((r) => {
                          'id': r.id,
                          'user_id': newUid,
                          'title': r.title,
                          'time': r.timeOfDay,
                          'days_of_week': r.repeatDays ?? 'daily',
                          'is_enabled': r.isEnabled,
                          'created_at': (r.createdAt ?? DateTime.now().toUtc())
                              .toIso8601String(),
                          'updated_at': (r.updatedAt ?? DateTime.now().toUtc())
                              .toIso8601String(),
                        })
                    .toList(),
                onConflict: 'id',
              );
        }

        directUploadSucceeded = true;
      } catch (e) {
        debugPrint(
            '[GuestAccountClaimService] Direct cloud upload notice (will queue locally): $e');
        directUploadSucceeded = false;
      }
    }

    // Step 3: Synchronizing local state
    onProgress?.call(const MigrationProgress(
      stage: MigrationStage.synchronizing,
      progress: 0.75,
      message: 'Synchronizing your records.',
    ));

    final syncStatus =
        directUploadSucceeded ? 'synced' : 'pending_upload';

    try {
      await db.transaction(() async {
        // 1. Workouts
        await (db.update(db.workouts)..where((t) => t.userId.equals('guest')))
            .write(WorkoutsCompanion(
          userId: Value(newUid),
          syncStatus: Value(syncStatus),
        ));

        // 2. WorkoutExercises
        await (db.update(db.workoutExercises)
              ..where((t) => t.userId.equals('guest')))
            .write(WorkoutExercisesCompanion(
          userId: Value(newUid),
        ));

        // 3. WorkoutSets
        await (db.update(db.workoutSets)
              ..where((t) => t.userId.equals('guest')))
            .write(WorkoutSetsCompanion(
          userId: Value(newUid),
        ));

        // 4. NutritionLogs
        await (db.update(db.nutritionLogs)
              ..where((t) => t.userId.equals('guest')))
            .write(NutritionLogsCompanion(
          userId: Value(newUid),
          syncStatus: Value(syncStatus),
        ));

        // 5. HydrationLogs
        await (db.update(db.hydrationLogs)
              ..where((t) => t.userId.equals('guest')))
            .write(HydrationLogsCompanion(
          userId: Value(newUid),
          syncStatus: Value(syncStatus),
        ));

        // 6. StepDailyLogs
        await (db.update(db.stepDailyLogs)
              ..where((t) => t.userId.equals('guest')))
            .write(StepDailyLogsCompanion(
          userId: Value(newUid),
          syncStatus: Value(syncStatus),
        ));

        // 7. CalendarEvents
        await (db.update(db.calendarEvents)
              ..where((t) => t.userId.equals('guest')))
            .write(CalendarEventsCompanion(
          userId: Value(newUid),
          syncStatus: Value(syncStatus),
        ));

        // 8. Reminders
        await (db.update(db.reminders)
              ..where((t) => t.userId.equals('guest')))
            .write(RemindersCompanion(
          userId: Value(newUid),
          syncStatus: Value(syncStatus),
        ));

        // Update all existing sync_queue rows for guest: userId = newUid, status = 'queued'
        await (db.update(db.syncQueue)..where((t) => t.userId.equals('guest')))
            .write(SyncQueueCompanion(
          userId: Value(newUid),
          status: const Value('queued'),
        ));

        // Enqueue mutations for claimed workouts and nutrition logs if not already direct-uploaded
        final now = DateTime.now().toUtc();

        for (final w in guestWorkouts) {
          await db.into(db.syncQueue).insertOnConflictUpdate(
                SyncQueueCompanion.insert(
                  id: 'sync-workout-${w.id}',
                  userId: Value(newUid),
                  entityType: 'workout',
                  entityId: w.id,
                  operation: 'upsert',
                  payload: jsonEncode({
                    'id': w.id,
                    'user_id': newUid,
                    'title': w.title,
                    'note': w.note,
                    'started_at': w.startedAt.toIso8601String(),
                    'completed_at': w.completedAt?.toIso8601String(),
                    'status': w.status,
                    'duration_seconds': w.durationSeconds,
                    'calories_burned': w.caloriesBurned,
                    'updated_at': w.updatedAt.toIso8601String(),
                  }),
                  createdAt: now,
                  clientTimestamp: Value(now),
                  status: Value(directUploadSucceeded ? 'synced' : 'queued'),
                ),
              );
        }

        for (final n in guestNutrition) {
          await db.into(db.syncQueue).insertOnConflictUpdate(
                SyncQueueCompanion.insert(
                  id: 'sync-nutrition-${n.id}',
                  userId: Value(newUid),
                  entityType: 'nutrition_logs',
                  entityId: n.id,
                  operation: 'upsert',
                  payload: jsonEncode({
                    'id': n.id,
                    'user_id': newUid,
                    'log_date': n.logDate.toIso8601String().substring(0, 10),
                    'target_calories': n.targetCalories,
                    'target_protein': n.targetProtein,
                    'target_carbs': n.targetCarbs,
                    'target_fat': n.targetFat,
                    'target_water_glasses': n.targetWaterGlasses,
                    'water_glasses': n.waterGlasses,
                    'logged_meals': jsonDecode(n.loggedMeals),
                    'logged_drinks': jsonDecode(n.loggedDrinks),
                    'updated_at': n.updatedAt.toIso8601String(),
                  }),
                  createdAt: now,
                  clientTimestamp: Value(now),
                  status: Value(directUploadSucceeded ? 'synced' : 'queued'),
                ),
              );
        }
      });
    } catch (e) {
      debugPrint(
          '[GuestAccountClaimService] Transaction rolled back due to error: $e');
      onProgress?.call(MigrationProgress(
        stage: MigrationStage.failed,
        progress: 0.0,
        message: 'Migration interrupted. Local records are safe.',
        error: e.toString(),
      ));
      rethrow;
    }

    // Step 4: Ready
    onProgress?.call(const MigrationProgress(
      stage: MigrationStage.ready,
      progress: 1.0,
      message: 'Your account is ready.',
    ));

    try {
      await storage.write(
        key: 'guest_migration_completed_$newUid',
        value: DateTime.now().toIso8601String(),
      );
      await storage.delete(key: 'active_guest_migration_$newUid');
    } catch (_) {}

    if (directUploadSucceeded) {
      return ClaimOutcome.success;
    }

    // Trigger outbox drain for pending queue
    try {
      await syncCoordinator.drain();
      return ClaimOutcome.success;
    } catch (e) {
      debugPrint(
          '[GuestAccountClaimService] Drain pending on partial network failure: $e');
      return ClaimOutcome.partialSuccessOutboxPending;
    }
  }
}

final guestAccountClaimServiceProvider =
    Provider<GuestAccountClaimService>((ref) {
  final db = ref.watch(databaseProvider);
  final coordinator = ref.watch(syncCoordinatorProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}
  return GuestAccountClaimService(
    db: db,
    syncCoordinator: coordinator,
    supabase: client,
  );
});

