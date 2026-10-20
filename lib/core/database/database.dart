import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables.dart';
import '../../features/nutrition/data/seed_foods.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    SyncQueue,
    NutritionLogs,
    HydrationLogs,
    StepDailyLogs,
    CalendarEvents,
    Reminders,
    FoodItems,
    DailyDiaryEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(
          e ??
              driftDatabase(
                name: 'fit_host_db',
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(calendarEvents);
            await m.createTable(reminders);
          }
          if (from < 3) {
            await m.createTable(nutritionLogs);
            await m.createTable(hydrationLogs);
            await m.createTable(stepDailyLogs);

            await m.addColumn(workouts, workouts.userId);
            await m.addColumn(workouts, workouts.deletedAt);
            await m.addColumn(workouts, workouts.isDeleted);
            await m.addColumn(workouts, workouts.serverUpdatedAt);
            await m.addColumn(workouts, workouts.clientMutationId);
            await m.addColumn(workouts, workouts.syncStatus);

            await m.addColumn(workoutExercises, workoutExercises.userId);
            await m.addColumn(workoutExercises, workoutExercises.deletedAt);
            await m.addColumn(workoutExercises, workoutExercises.isDeleted);
            await m.addColumn(workoutExercises, workoutExercises.createdAt);
            await m.addColumn(workoutExercises, workoutExercises.updatedAt);

            await m.addColumn(workoutSets, workoutSets.userId);
            await m.addColumn(workoutSets, workoutSets.deletedAt);
            await m.addColumn(workoutSets, workoutSets.isDeleted);
            await m.addColumn(workoutSets, workoutSets.createdAt);
            await m.addColumn(workoutSets, workoutSets.updatedAt);

            await m.addColumn(syncQueue, syncQueue.userId);
            await m.addColumn(syncQueue, syncQueue.clientTimestamp);
            await m.addColumn(syncQueue, syncQueue.status);
            await m.addColumn(syncQueue, syncQueue.errorLog);
            await m.addColumn(syncQueue, syncQueue.attemptCount);
            await m.addColumn(syncQueue, syncQueue.lastAttemptAt);

            await m.addColumn(calendarEvents, calendarEvents.userId);
            await m.addColumn(calendarEvents, calendarEvents.deletedAt);
            await m.addColumn(calendarEvents, calendarEvents.isDeleted);
            await m.addColumn(calendarEvents, calendarEvents.serverUpdatedAt);
            await m.addColumn(calendarEvents, calendarEvents.syncStatus);

            await m.addColumn(reminders, reminders.userId);
            await m.addColumn(reminders, reminders.deletedAt);
            await m.addColumn(reminders, reminders.isDeleted);
            await m.addColumn(reminders, reminders.syncStatus);

            // Backfill existing rows
            try {
              await customStatement(
                  "UPDATE sync_queue SET client_timestamp = created_at WHERE client_timestamp IS NULL;");
              await customStatement(
                  "UPDATE sync_queue SET user_id = 'guest' WHERE user_id IS NULL;");
              await customStatement(
                  "UPDATE sync_queue SET status = 'queued' WHERE status IS NULL OR status = 'pending';");
              await customStatement(
                  "CREATE INDEX IF NOT EXISTS idx_sync_queue_status_attempts ON sync_queue (status, attempts);");
            } catch (_) {}
          }
          if (from < 4) {
            await m.addColumn(workouts, workouts.caloriesBurned);
          }
          if (from < 5) {
            await m.addColumn(exercises, exercises.recommendedFor);
          }
          if (from < 6) {
            await m.createTable(foodItems);
            try {
              await customStatement(
                  "CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON food_items (barcode);");
            } catch (_) {}
          }
          if (from < 7) {
            await m.createTable(dailyDiaryEntries);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          try {
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_workouts_user_started ON workouts (user_id, started_at);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_workout_exercises_parent ON workout_exercises (workout_id, user_id);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_workout_sets_parent ON workout_sets (workout_exercise_id, user_id);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_nutrition_user_date ON nutrition_logs (user_id, log_date);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_hydration_user_date ON hydration_logs (user_id, log_date);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_steps_user_date ON step_daily_logs (user_id, step_date);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_calendar_user_date ON calendar_events (user_id, scheduled_date);');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_reminders_user ON reminders (user_id);');
          } catch (_) {}
          await _seedInitialFoodItems();
        },
      );

  Future<void> _seedInitialFoodItems() async {
    try {
      final existing = await (select(foodItems)
            ..where((t) => t.source.equals('seeded'))
            ..limit(1))
          .get();
      if (existing.isEmpty) {
        await batch((b) {
          b.insertAll(
            foodItems,
            kSeedFoods.map((f) => FoodItemsCompanion.insert(
                  id: f.id,
                  barcode: Value(f.barcode),
                  name: f.name,
                  brand: Value(f.brand),
                  proteinPer100g: Value(f.proteinPer100g),
                  carbsPer100g: Value(f.carbsPer100g),
                  fatsPer100g: Value(f.fatsPer100g),
                  caloriesPer100g: Value(f.caloriesPer100g),
                  servingPresetsJson: Value(jsonEncode(
                      f.servingPresets.map((p) => p.toJson()).toList())),
                  source: const Value('seeded'),
                  imageUrl: Value(f.imageUrl),
                  createdAt: Value(f.createdAt),
                  updatedAt: Value(f.createdAt),
                  userId: const Value('system'),
                )),
          );
        });
      }
    } catch (_) {}
  }

  /// Clears only the authenticated user's private cached data,
  /// preserving guest records (userId == 'guest') intact.
  Future<void> clearAccountCache(String targetUserId) async {
    if (targetUserId.isEmpty || targetUserId == 'guest') return;
    await transaction(() async {
      await (delete(workoutSets)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(workoutExercises)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(workouts)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(nutritionLogs)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(hydrationLogs)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(stepDailyLogs)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(calendarEvents)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(reminders)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(dailyDiaryEntries)..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(syncQueue)..where((t) => t.userId.equals(targetUserId))).go();
    });
  }

  Future<void> clearAllLocalData() async {
    await transaction(() async {
      await delete(workoutSets).go();
      await delete(workoutExercises).go();
      await delete(workouts).go();
      await delete(syncQueue).go();
      await delete(nutritionLogs).go();
      await delete(hydrationLogs).go();
      await delete(stepDailyLogs).go();
      await delete(calendarEvents).go();
      await delete(reminders).go();
      await (delete(foodItems)..where((t) => t.source.isNotValue('seeded'))).go();
    });
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
