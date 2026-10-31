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
    ExerciseIdMappings,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    Routines,
    RoutineExercises,
    RoutineSets,
    PersonalRecords,
    ProgressionSettings,
    SyncQueue,
    NutritionLogs,
    HydrationLogs,
    StepDailyLogs,
    CalendarEvents,
    Reminders,
    FoodItems,
    DailyDiaryEntries,
    BodyMeasurements,
    ProgressPhotos,
    ExerciseSubmissions,
    ExerciseModerationLogs,
    NotificationInboxItems,
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
  int get schemaVersion => 13;

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
            "UPDATE sync_queue SET client_timestamp = created_at WHERE client_timestamp IS NULL;",
          );
          await customStatement(
            "UPDATE sync_queue SET user_id = 'guest' WHERE user_id IS NULL;",
          );
          await customStatement(
            "UPDATE sync_queue SET status = 'queued' WHERE status IS NULL OR status = 'pending';",
          );
          await customStatement(
            "CREATE INDEX IF NOT EXISTS idx_sync_queue_status_attempts ON sync_queue (status, attempts);",
          );
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
            "CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON food_items (barcode);",
          );
        } catch (_) {}
      }
      if (from < 7) {
        await m.createTable(dailyDiaryEntries);
      }
      if (from < 8) {
        await m.addColumn(exercises, exercises.canonicalId);
        await m.addColumn(exercises, exercises.source);
        await m.addColumn(exercises, exercises.originalSourceId);
        await m.addColumn(exercises, exercises.aliases);
        await m.addColumn(exercises, exercises.bodyPart);
        await m.addColumn(exercises, exercises.muscleGroup);
        await m.addColumn(exercises, exercises.secondaryMuscles);
        await m.addColumn(exercises, exercises.instructionSteps);
        await m.addColumn(exercises, exercises.exerciseType);
        await m.addColumn(exercises, exercises.movementType);
        await m.addColumn(exercises, exercises.difficultyLevel);
        await m.addColumn(exercises, exercises.audienceSuitability);
        await m.addColumn(exercises, exercises.mediaThumbnailUrl);
        await m.addColumn(exercises, exercises.mediaAnimationUrl);
        await m.addColumn(exercises, exercises.mediaLicense);
        await m.addColumn(exercises, exercises.mediaAttribution);
        await m.addColumn(exercises, exercises.contentLicense);
        await m.addColumn(exercises, exercises.contentAttribution);
        await m.addColumn(exercises, exercises.languagesAvailable);
        await m.addColumn(exercises, exercises.safetyNotes);
        await m.addColumn(exercises, exercises.publicationStatus);
        await m.createTable(exerciseIdMappings);
      }
      if (from < 9) {
        await m.addColumn(workoutExercises, workoutExercises.supersetId);
        await m.addColumn(workoutExercises, workoutExercises.isSkipped);

        await m.addColumn(workoutSets, workoutSets.targetReps);
        await m.addColumn(workoutSets, workoutSets.targetWeightKg);
        await m.addColumn(workoutSets, workoutSets.durationSeconds);
        await m.addColumn(workoutSets, workoutSets.distanceMeters);
        await m.addColumn(workoutSets, workoutSets.tempo);
        await m.addColumn(workoutSets, workoutSets.rpe);
        await m.addColumn(workoutSets, workoutSets.isSkipped);

        await m.createTable(routines);
        await m.createTable(routineExercises);
        await m.createTable(routineSets);
        await m.createTable(personalRecords);
        await m.createTable(progressionSettings);
      }
      if (from < 10) {
        await m.createTable(bodyMeasurements);
        await m.createTable(progressPhotos);
      }
      if (from < 11) {
        await m.createTable(exerciseSubmissions);
        await m.createTable(exerciseModerationLogs);
      }
      if (from < 12) {
        await m.createTable(notificationInboxItems);
      }
      if (from < 13) {
        await m.addColumn(reminders, reminders.deliveryMode);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      try {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_workouts_user_started ON workouts (user_id, started_at);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_workout_exercises_parent ON workout_exercises (workout_id, user_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_workout_sets_parent ON workout_sets (workout_exercise_id, user_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_routines_user ON routines (user_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_routine_exercises_parent ON routine_exercises (routine_id, user_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_routine_sets_parent ON routine_sets (routine_exercise_id, user_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise ON personal_records (user_id, exercise_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_progression_settings_user_exercise ON progression_settings (user_id, exercise_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_nutrition_user_date ON nutrition_logs (user_id, log_date);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_hydration_user_date ON hydration_logs (user_id, log_date);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_steps_user_date ON step_daily_logs (user_id, step_date);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_calendar_user_date ON calendar_events (user_id, scheduled_date);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_body_measurements_user ON body_measurements (user_id, measured_at);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_progress_photos_user ON progress_photos (user_id, taken_at);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_exercise_submissions_user ON exercise_submissions (submitted_by, status);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_exercise_submissions_hash ON exercise_submissions (duplicate_hash);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_exercise_moderation_sub ON exercise_moderation_logs (submission_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_exercises_audience ON exercises (audience_suitability);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_exercises_pub_status ON exercises (publication_status);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_exercises_body_part ON exercises (body_part);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_exercise_mappings_canonical ON exercise_id_mappings (canonical_exercise_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_reminders_user ON reminders (user_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notification_inbox_items (user_id, is_read, is_deleted);',
        );
      } catch (_) {}
      await _seedInitialFoodItems();
    },
  );

  Future<void> _seedInitialFoodItems() async {
    try {
      final countResult =
          await (selectOnly(foodItems)
                ..addColumns([foodItems.id.count()])
                ..where(foodItems.source.equals('seeded')))
              .getSingle();
      final seededCount = countResult.read(foodItems.id.count()) ?? 0;
      if (seededCount < kSeedFoods.length) {
        await batch((b) {
          b.insertAll(
            foodItems,
            kSeedFoods.map(
              (f) => FoodItemsCompanion.insert(
                id: f.id,
                barcode: Value(f.barcode),
                name: f.name,
                brand: Value(f.brand),
                proteinPer100g: Value(f.proteinPer100g),
                carbsPer100g: Value(f.carbsPer100g),
                fatsPer100g: Value(f.fatsPer100g),
                caloriesPer100g: Value(f.caloriesPer100g),
                servingPresetsJson: Value(
                  jsonEncode(f.servingPresets.map((p) => p.toJson()).toList()),
                ),
                source: const Value('seeded'),
                imageUrl: Value(f.imageUrl),
                createdAt: Value(f.createdAt),
                updatedAt: Value(f.createdAt),
                userId: const Value('system'),
              ),
            ),
            mode: InsertMode.insertOrReplace,
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
      await (delete(
        workoutSets,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        workoutExercises,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        workouts,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        routineSets,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        routineExercises,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        routines,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        personalRecords,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        progressionSettings,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        nutritionLogs,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        hydrationLogs,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        stepDailyLogs,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        calendarEvents,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        reminders,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        dailyDiaryEntries,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        bodyMeasurements,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        progressPhotos,
      )..where((t) => t.userId.equals(targetUserId))).go();
      await (delete(
        syncQueue,
      )..where((t) => t.userId.equals(targetUserId))).go();
    });
  }

  Future<void> clearAllLocalData() async {
    await transaction(() async {
      await delete(workoutSets).go();
      await delete(workoutExercises).go();
      await delete(workouts).go();
      await delete(routineSets).go();
      await delete(routineExercises).go();
      await delete(routines).go();
      await delete(personalRecords).go();
      await delete(progressionSettings).go();
      await delete(bodyMeasurements).go();
      await delete(progressPhotos).go();
      await delete(syncQueue).go();
      await delete(nutritionLogs).go();
      await delete(hydrationLogs).go();
      await delete(stepDailyLogs).go();
      await delete(calendarEvents).go();
      await delete(reminders).go();
      await (delete(
        foodItems,
      )..where((t) => t.source.isNotValue('seeded'))).go();
    });
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
