import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/domain/repositories/workout_repository.dart';
import 'package:fit_host/features/workouts/data/datasources/default_exercises.dart';
import 'package:fit_host/features/workouts/data/datasources/unified_exercise_catalog_data.dart';

import 'package:fit_host/core/sync/sync_utils.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final AppDatabase db;
  final String userId;

  WorkoutRepositoryImpl(this.db, {this.userId = 'guest'});

  @override
  Future<void> seedDefaultExercises() async {
    // Check if canonical catalog has already been seeded
    final count =
        await (db.selectOnly(db.exercises)
              ..addColumns([db.exercises.id.count()]))
            .map((row) => row.read(db.exercises.id.count()) ?? 0)
            .getSingle();

    if (count >= 1000) {
      return; // Already seeded
    }

    await db.transaction(() async {
      // 1. Seed 1,324 canonical exercises
      await db.batch((batch) {
        for (final e in kUnifiedExerciseCatalog) {
          batch.insert(
            db.exercises,
            ExercisesCompanion.insert(
              id: e.id,
              canonicalId: Value(e.canonicalId ?? e.id),
              source: Value(e.source),
              originalSourceId: Value(e.originalSourceId),
              name: e.name,
              aliases: Value(jsonEncode(e.aliases)),
              category: e.category,
              bodyPart: Value(e.bodyPart),
              targetMuscle: e.targetMuscle,
              muscleGroup: Value(e.muscleGroup),
              secondaryMuscles: Value(jsonEncode(e.secondaryMuscles)),
              instructions: e.instructions,
              instructionSteps: Value(jsonEncode(e.instructionSteps)),
              equipment: e.equipment,
              exerciseType: Value(e.exerciseType),
              movementType: Value(e.movementType),
              difficultyLevel: Value(e.difficultyLevel),
              audienceSuitability: Value(e.audienceSuitability),
              isCustom: const Value(false),
              createdAt: e.createdAt,
              mediaThumbnailUrl: Value(e.mediaThumbnailUrl),
              mediaAnimationUrl: Value(e.mediaAnimationUrl),
              mediaLicense: Value(e.mediaLicense),
              mediaAttribution: Value(e.mediaAttribution),
              contentLicense: Value(e.contentLicense),
              contentAttribution: Value(e.contentAttribution),
              languagesAvailable: Value(jsonEncode(e.languagesAvailable)),
              safetyNotes: Value(e.safetyNotes),
              publicationStatus: Value(e.publicationStatus),
              recommendedFor: const Value('all'),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

      // 2. Safe archiving of legacy exercises (prevents orphaned FKs in existing routines & workouts)
      await db.batch((batch) {
        for (final e in defaultExercisesList) {
          batch.insert(
            db.exercises,
            ExercisesCompanion.insert(
              id: e.id,
              canonicalId: Value(kLegacyExerciseMappings[e.id] ?? e.id),
              source: const Value('legacy'),
              name: e.name,
              category: e.category,
              targetMuscle: e.targetMuscle,
              instructions: e.instructions,
              equipment: e.equipment,
              isCustom: Value(e.isCustom),
              createdAt: e.createdAt,
              imageAsset: Value(e.imageAsset),
              anatomyAsset: Value(e.anatomyAsset),
              recommendedFor: Value(e.recommendedFor.join(',')),
              publicationStatus: const Value('archived'),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

      // 3. Seed ID mappings table
      final now = DateTime.now().toUtc();
      await db.batch((batch) {
        for (final entry in kLegacyExerciseMappings.entries) {
          batch.insert(
            db.exerciseIdMappings,
            ExerciseIdMappingsCompanion.insert(
              oldExerciseId: entry.key,
              canonicalExerciseId: entry.value,
              confidence: const Value('high'),
              mappedAt: now,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  @override
  Future<List<ExerciseEntity>> getExercises({
    String? query,
    String? category,
    String? genderFilter,
    String? bodyPart,
    String? equipment,
    bool includeArchived = false,
    int? limit,
    int offset = 0,
  }) async {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }
    if (limit != null && limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }

    await seedDefaultExercises();
    final q = db.select(db.exercises);

    if (!includeArchived) {
      q.where((t) => t.publicationStatus.equals('published'));
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      q.where((t) => t.category.equals(category));
    }

    if (bodyPart != null && bodyPart.isNotEmpty && bodyPart != 'All') {
      q.where((t) => t.bodyPart.equals(bodyPart.toLowerCase()));
    }

    if (equipment != null && equipment.isNotEmpty && equipment != 'All') {
      q.where((t) => t.equipment.equals(equipment));
    }

    if (genderFilter != null &&
        genderFilter.isNotEmpty &&
        genderFilter.toLowerCase() != 'all') {
      final clean = genderFilter.toLowerCase();
      if (clean == 'universal') {
        q.where((t) => t.audienceSuitability.equals('universal'));
      } else if (clean.contains('female')) {
        // Universal exercises are ALWAYS included; gender-specific is never restrictive
        q.where(
          (t) =>
              t.audienceSuitability.equals('universal') |
              t.audienceSuitability.equals('female') |
              t.recommendedFor.like('%female%') |
              t.recommendedFor.like('%all%'),
        );
      } else if (clean.contains('male')) {
        q.where(
          (t) =>
              t.audienceSuitability.equals('universal') |
              t.audienceSuitability.equals('male') |
              (t.recommendedFor.like('%male%') &
                  t.recommendedFor.like('%female%').not()) |
              t.recommendedFor.like('%all%'),
        );
      }
    }

    if (query != null && query.trim().isNotEmpty) {
      final pattern = '%${query.trim().toLowerCase()}%';
      q.where(
        (t) =>
            t.name.lower().like(pattern) |
            t.aliases.lower().like(pattern) |
            t.category.lower().like(pattern) |
            t.bodyPart.lower().like(pattern) |
            t.targetMuscle.lower().like(pattern) |
            t.muscleGroup.lower().like(pattern) |
            t.secondaryMuscles.lower().like(pattern) |
            t.equipment.lower().like(pattern),
      );
    }

    q.orderBy([
      (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
    ]);
    if (limit != null) {
      q.limit(limit, offset: offset);
    } else if (offset > 0) {
      q.limit(-1, offset: offset);
    }

    final rows = await q.get();
    return rows.map(_mapRowToEntity).toList();
  }

  @override
  Future<ExerciseEntity?> getExerciseById(String id) async {
    // 1. First try direct lookup by ID
    var row = await (db.select(
      db.exercises,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    // 2. If not found or if row is archived, check legacy mapping
    if (row == null) {
      final mapping = await (db.select(
        db.exerciseIdMappings,
      )..where((t) => t.oldExerciseId.equals(id))).getSingleOrNull();
      if (mapping != null) {
        row =
            await (db.select(db.exercises)
                  ..where((t) => t.id.equals(mapping.canonicalExerciseId)))
                .getSingleOrNull();
      }
    }

    if (row == null) return null;
    return _mapRowToEntity(row);
  }

  ExerciseEntity _mapRowToEntity(Exercise r) {
    List<String> parseJsonList(String? raw) {
      if (raw == null || raw.isEmpty) return const [];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return const [];
    }

    return ExerciseEntity(
      id: r.id,
      canonicalId: r.canonicalId,
      source: r.source,
      originalSourceId: r.originalSourceId,
      name: r.name,
      aliases: parseJsonList(r.aliases),
      category: r.category,
      bodyPart: r.bodyPart,
      targetMuscle: r.targetMuscle,
      muscleGroup: r.muscleGroup,
      secondaryMuscles: parseJsonList(r.secondaryMuscles),
      instructions: r.instructions,
      instructionSteps: parseJsonList(r.instructionSteps),
      equipment: r.equipment,
      exerciseType: r.exerciseType,
      movementType: r.movementType,
      difficultyLevel: r.difficultyLevel,
      audienceSuitability: r.audienceSuitability,
      isCustom: r.isCustom,
      createdAt: r.createdAt,
      imageAsset: r.imageAsset,
      anatomyAsset: r.anatomyAsset,
      mediaThumbnailUrl: r.mediaThumbnailUrl,
      mediaAnimationUrl: r.mediaAnimationUrl,
      mediaLicense: r.mediaLicense,
      mediaAttribution: r.mediaAttribution,
      contentLicense: r.contentLicense,
      contentAttribution: r.contentAttribution,
      languagesAvailable: parseJsonList(r.languagesAvailable),
      safetyNotes: r.safetyNotes,
      publicationStatus: r.publicationStatus,
      recommendedFor: r.recommendedFor
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  @override
  Future<void> saveWorkout(WorkoutEntity workout) async {
    final computedCalories =
        workout.caloriesBurned ??
        WorkoutEntity.computeCalories(
          category: workout.category ?? workout.title,
          weightKg: 70.0,
          durationSeconds: workout.durationSeconds,
        );

    await db.transaction(() async {
      await db
          .into(db.workouts)
          .insertOnConflictUpdate(
            WorkoutsCompanion.insert(
              id: workout.id,
              userId: Value(userId),
              title: workout.title,
              note: Value(workout.note),
              startedAt: workout.startedAt,
              completedAt: Value(workout.completedAt),
              status: Value(workout.status),
              durationSeconds: Value(workout.durationSeconds),
              caloriesBurned: Value(computedCalories),
              syncStatus: Value(workout.syncStatus),
              updatedAt: workout.updatedAt,
            ),
          );

      // Clean up existing workout exercises and sets for this workout
      final existingWe = await (db.select(
        db.workoutExercises,
      )..where((t) => t.workoutId.equals(workout.id))).get();
      for (final we in existingWe) {
        await (db.delete(
          db.workoutSets,
        )..where((s) => s.workoutExerciseId.equals(we.id))).go();
      }
      await (db.delete(
        db.workoutExercises,
      )..where((t) => t.workoutId.equals(workout.id))).go();

      // Insert fresh workout exercises and their sets
      for (var i = 0; i < workout.exercises.length; i++) {
        final we = workout.exercises[i];
        await db
            .into(db.workoutExercises)
            .insert(
              WorkoutExercisesCompanion.insert(
                id: we.id,
                workoutId: workout.id,
                exerciseId: we.exerciseId,
                userId: Value(userId),
                orderIndex: Value(i),
                notes: Value(we.notes),
                supersetId: Value(we.supersetId),
                isSkipped: Value(we.isSkipped),
              ),
            );

        for (var sIdx = 0; sIdx < we.sets.length; sIdx++) {
          final s = we.sets[sIdx];
          await db
              .into(db.workoutSets)
              .insert(
                WorkoutSetsCompanion.insert(
                  id: s.id,
                  workoutExerciseId: we.id,
                  userId: Value(userId),
                  setNumber: sIdx + 1,
                  reps: Value(s.reps),
                  weightKg: Value(s.weightKg),
                  isCompleted: Value(s.isCompleted),
                  restSeconds: Value(s.restSeconds),
                  setType: Value(s.type),
                  targetReps: Value(s.targetReps),
                  targetWeightKg: Value(s.targetWeightKg),
                  durationSeconds: Value(s.durationSeconds),
                  distanceMeters: Value(s.distanceMeters),
                  tempo: Value(s.tempo),
                  rpe: Value(s.rpe),
                  isSkipped: Value(s.isSkipped),
                ),
              );
        }
      }

      // Add to sync queue for eventual cloud synchronization
      final nowUtc = DateTime.now().toUtc();
      await db
          .into(db.syncQueue)
          .insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: 'sync-workout-${workout.id}',
              userId: Value(userId),
              entityType: 'workout',
              entityId: workout.id,
              operation: 'upsert',
              payload: jsonEncode({
                'id': workout.id,
                'user_id': userId,
                'title': workout.title,
                'note': workout.note,
                'started_at': workout.startedAt.toIso8601String(),
                'completed_at': workout.completedAt?.toIso8601String(),
                'status': workout.status,
                'duration_seconds': workout.durationSeconds,
                'calories_burned': computedCalories,
                'updated_at': workout.updatedAt.toIso8601String(),
              }),
              createdAt: nowUtc,
              clientTimestamp: Value(nowUtc),
              status: const Value('queued'),
            ),
          );

      for (var i = 0; i < workout.exercises.length; i++) {
        final we = workout.exercises[i];
        await db
            .into(db.syncQueue)
            .insertOnConflictUpdate(
              SyncQueueCompanion.insert(
                id: 'sync-we-${we.id}',
                userId: Value(userId),
                entityType: 'workout_exercises',
                entityId: we.id,
                operation: 'upsert',
                payload: jsonEncode({
                  'id': we.id,
                  'workout_id': workout.id,
                  'user_id': userId,
                  'exercise_id': we.exerciseId,
                  'order_index': i,
                  'notes': we.notes,
                  'superset_id': we.supersetId,
                  'is_skipped': we.isSkipped,
                  'updated_at': nowUtc.toIso8601String(),
                }),
                createdAt: nowUtc,
                clientTimestamp: Value(nowUtc),
                status: const Value('queued'),
              ),
            );

        for (var sIdx = 0; sIdx < we.sets.length; sIdx++) {
          final s = we.sets[sIdx];
          await db
              .into(db.syncQueue)
              .insertOnConflictUpdate(
                SyncQueueCompanion.insert(
                  id: 'sync-ws-${s.id}',
                  userId: Value(userId),
                  entityType: 'workout_sets',
                  entityId: s.id,
                  operation: 'upsert',
                  payload: jsonEncode({
                    'id': s.id,
                    'workout_exercise_id': we.id,
                    'user_id': userId,
                    'set_number': sIdx + 1,
                    'reps': s.reps,
                    'weight_kg': s.weightKg,
                    'is_completed': s.isCompleted,
                    'rest_seconds': s.restSeconds,
                    'set_type': s.type,
                    'target_reps': s.targetReps,
                    'target_weight_kg': s.targetWeightKg,
                    'duration_seconds': s.durationSeconds,
                    'distance_meters': s.distanceMeters,
                    'tempo': s.tempo,
                    'rpe': s.rpe,
                    'is_skipped': s.isSkipped,
                    'updated_at': nowUtc.toIso8601String(),
                  }),
                  createdAt: nowUtc,
                  clientTimestamp: Value(nowUtc),
                  status: const Value('queued'),
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> deleteWorkout(String id) async {
    await db.transaction(() async {
      final existingWe = await (db.select(
        db.workoutExercises,
      )..where((t) => t.workoutId.equals(id))).get();
      for (final we in existingWe) {
        await (db.delete(
          db.workoutSets,
        )..where((s) => s.workoutExerciseId.equals(we.id))).go();
      }
      await (db.delete(
        db.workoutExercises,
      )..where((t) => t.workoutId.equals(id))).go();
      await (db.delete(
        db.workouts,
      )..where((w) => w.id.equals(id) & w.userId.equals(userId))).go();

      if (userId != 'guest' && isValidUuid(userId)) {
        await db
            .into(db.syncQueue)
            .insertOnConflictUpdate(
              SyncQueueCompanion.insert(
                id: 'sync-delete-$id',
                userId: Value(userId),
                entityType: 'workout',
                entityId: id,
                operation: 'delete',
                payload: jsonEncode({'id': id, 'user_id': userId}),
                createdAt: DateTime.now().toUtc(),
              ),
            );
      } else {
        // Clean up any pending sync queue item for this guest workout
        await (db.delete(
          db.syncQueue,
        )..where((t) => t.entityId.equals(id) & t.userId.equals('guest'))).go();
      }
    });
  }

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) async {
    final wRow =
        await (db.select(db.workouts)
              ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
            .getSingleOrNull();
    if (wRow == null) return null;

    final weRows =
        await (db.select(db.workoutExercises)
              ..where((t) => t.workoutId.equals(id))
              ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
            .get();

    final exercises = <WorkoutExerciseEntity>[];
    for (final we in weRows) {
      final exRow = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals(we.exerciseId))).getSingleOrNull();

      final sRows =
          await (db.select(db.workoutSets)
                ..where((t) => t.workoutExerciseId.equals(we.id))
                ..orderBy([(t) => OrderingTerm(expression: t.setNumber)]))
              .get();

      final sets = sRows
          .map(
            (s) => WorkoutSetEntity(
              id: s.id,
              workoutExerciseId: s.workoutExerciseId,
              setNumber: s.setNumber,
              reps: s.reps,
              weightKg: s.weightKg,
              isCompleted: s.isCompleted,
              restSeconds: s.restSeconds,
              type: s.setType,
              targetReps: s.targetReps,
              targetWeightKg: s.targetWeightKg,
              durationSeconds: s.durationSeconds,
              distanceMeters: s.distanceMeters,
              tempo: s.tempo,
              rpe: s.rpe,
              isSkipped: s.isSkipped,
            ),
          )
          .toList();

      exercises.add(
        WorkoutExerciseEntity(
          id: we.id,
          workoutId: we.workoutId,
          exerciseId: we.exerciseId,
          exerciseName: exRow?.name ?? 'Unknown Exercise',
          category: exRow?.category ?? 'General',
          orderIndex: we.orderIndex,
          notes: we.notes,
          supersetId: we.supersetId,
          isSkipped: we.isSkipped,
          sets: sets,
        ),
      );
    }

    return WorkoutEntity(
      id: wRow.id,
      title: wRow.title,
      note: wRow.note,
      startedAt: wRow.startedAt,
      completedAt: wRow.completedAt,
      status: wRow.status,
      durationSeconds: wRow.durationSeconds,
      caloriesBurned: wRow.caloriesBurned,
      syncStatus: wRow.syncStatus ?? 'synced',
      updatedAt: wRow.updatedAt,
      exercises: exercises,
    );
  }

  @override
  Future<List<WorkoutEntity>> getWorkouts() async {
    final wRows =
        await (db.select(db.workouts)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    (t.isDeleted.isNull() | t.isDeleted.equals(false)),
              )
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.startedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    final result = <WorkoutEntity>[];
    for (final wRow in wRows) {
      final fullWorkout = await getWorkoutById(wRow.id);
      if (fullWorkout != null) {
        final title = fullWorkout.title.toLowerCase();
        final id = fullWorkout.id.toLowerCase();
        if (!title.contains('popup test') &&
            !title.contains('fit host test') &&
            !id.startsWith('test_')) {
          result.add(fullWorkout);
        }
      }
    }
    return result;
  }

  @override
  Stream<List<WorkoutEntity>> watchWorkouts() {
    return (db.select(db.workouts)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                (t.isDeleted.isNull() | t.isDeleted.equals(false)),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .asyncMap((rows) async {
          final list = <WorkoutEntity>[];
          for (final r in rows) {
            final w = await getWorkoutById(r.id);
            if (w != null) {
              final title = w.title.toLowerCase();
              final id = w.id.toLowerCase();
              if (!title.contains('popup test') &&
                  !title.contains('fit host test') &&
                  !id.startsWith('test_')) {
                list.add(w);
              }
            }
          }
          return list;
        });
  }
}
