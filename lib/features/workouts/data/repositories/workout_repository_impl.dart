import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/domain/repositories/workout_repository.dart';
import 'package:fit_host/features/workouts/data/datasources/default_exercises.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final AppDatabase db;
  final String userId;

  WorkoutRepositoryImpl(this.db, {this.userId = 'guest'});

  @override
  Future<void> seedDefaultExercises() async {
    for (final e in defaultExercisesList) {
      await db.into(db.exercises).insertOnConflictUpdate(
            ExercisesCompanion.insert(
              id: e.id,
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
            ),
          );
    }
  }

  @override
  Future<List<ExerciseEntity>> getExercises({
    String? query,
    String? category,
    String? genderFilter,
  }) async {
    await seedDefaultExercises();
    final q = db.select(db.exercises);
    if (category != null && category.isNotEmpty && category != 'All') {
      q.where((t) => t.category.equals(category));
    }
    if (genderFilter != null &&
        genderFilter.isNotEmpty &&
        genderFilter.toLowerCase() != 'all') {
      final isFemale = genderFilter.toLowerCase().contains('female');
      final isMale = !isFemale && genderFilter.toLowerCase().contains('male');
      if (isFemale) {
        q.where((t) =>
            t.recommendedFor.like('%female%') | t.recommendedFor.like('%all%'));
      } else if (isMale) {
        q.where((t) =>
            (t.recommendedFor.like('%male%') &
                t.recommendedFor.like('%female%').not()) |
            t.recommendedFor.like('%all%'));
      } else {
        final clean = genderFilter.toLowerCase();
        q.where((t) =>
            t.recommendedFor.like('%$clean%') | t.recommendedFor.like('%all%'));
      }
    }
    if (query != null && query.trim().isNotEmpty) {
      final pattern = '%${query.trim().toLowerCase()}%';
      q.where(
        (t) =>
            t.name.lower().like(pattern) |
            t.targetMuscle.lower().like(pattern) |
            t.equipment.lower().like(pattern),
      );
    }
    q.orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);

    final rows = await q.get();
    return rows
        .map(
          (r) => ExerciseEntity(
            id: r.id,
            name: r.name,
            category: r.category,
            targetMuscle: r.targetMuscle,
            instructions: r.instructions,
            equipment: r.equipment,
            isCustom: r.isCustom,
            createdAt: r.createdAt,
            imageAsset: r.imageAsset,
            anatomyAsset: r.anatomyAsset,
            recommendedFor: r.recommendedFor
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Future<ExerciseEntity?> getExerciseById(String id) async {
    final row = await (db.select(db.exercises)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return ExerciseEntity(
      id: row.id,
      name: row.name,
      category: row.category,
      targetMuscle: row.targetMuscle,
      instructions: row.instructions,
      equipment: row.equipment,
      isCustom: row.isCustom,
      createdAt: row.createdAt,
      imageAsset: row.imageAsset,
      anatomyAsset: row.anatomyAsset,
      recommendedFor: row.recommendedFor
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  @override
  Future<void> saveWorkout(WorkoutEntity workout) async {
    final computedCalories = workout.caloriesBurned ??
        WorkoutEntity.computeCalories(
          category: workout.category ?? workout.title,
          weightKg: 70.0,
          durationSeconds: workout.durationSeconds,
        );

    await db.transaction(() async {
      await db.into(db.workouts).insertOnConflictUpdate(
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
      final existingWe = await (db.select(db.workoutExercises)
            ..where((t) => t.workoutId.equals(workout.id)))
          .get();
      for (final we in existingWe) {
        await (db.delete(db.workoutSets)
              ..where((s) => s.workoutExerciseId.equals(we.id)))
            .go();
      }
      await (db.delete(db.workoutExercises)
            ..where((t) => t.workoutId.equals(workout.id)))
          .go();

      // Insert fresh workout exercises and their sets
      for (var i = 0; i < workout.exercises.length; i++) {
        final we = workout.exercises[i];
        await db.into(db.workoutExercises).insert(
              WorkoutExercisesCompanion.insert(
                id: we.id,
                workoutId: workout.id,
                exerciseId: we.exerciseId,
                userId: Value(userId),
                orderIndex: Value(i),
                notes: Value(we.notes),
              ),
            );

        for (var sIdx = 0; sIdx < we.sets.length; sIdx++) {
          final s = we.sets[sIdx];
          await db.into(db.workoutSets).insert(
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
                ),
              );
        }
      }

      // Add to sync queue for eventual cloud synchronization
      final nowUtc = DateTime.now().toUtc();
      await db.into(db.syncQueue).insertOnConflictUpdate(
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
    });
  }

  @override
  Future<void> deleteWorkout(String id) async {
    await db.transaction(() async {
      final existingWe = await (db.select(db.workoutExercises)
            ..where((t) => t.workoutId.equals(id)))
          .get();
      for (final we in existingWe) {
        await (db.delete(db.workoutSets)
              ..where((s) => s.workoutExerciseId.equals(we.id)))
            .go();
      }
      await (db.delete(db.workoutExercises)
            ..where((t) => t.workoutId.equals(id)))
          .go();
      await (db.delete(db.workouts)
            ..where((w) => w.id.equals(id) & w.userId.equals(userId)))
          .go();
      await db.into(db.syncQueue).insertOnConflictUpdate(
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
    });
  }

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) async {
    final wRow = await (db.select(db.workouts)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (wRow == null) return null;

    final weRows = await (db.select(db.workoutExercises)
          ..where((t) => t.workoutId.equals(id))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();

    final exercises = <WorkoutExerciseEntity>[];
    for (final we in weRows) {
      final exRow = await (db.select(db.exercises)
            ..where((t) => t.id.equals(we.exerciseId)))
          .getSingleOrNull();

      final sRows = await (db.select(db.workoutSets)
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
    final wRows = await (db.select(db.workouts)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.isDeleted.isNull() | t.isDeleted.equals(false)))
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
        result.add(fullWorkout);
      }
    }
    return result;
  }

  @override
  Stream<List<WorkoutEntity>> watchWorkouts() {
    return (db.select(db.workouts)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.isDeleted.isNull() | t.isDeleted.equals(false)))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.startedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch()
        .asyncMap((rows) async {
      final list = <WorkoutEntity>[];
      for (final r in rows) {
        final w = await getWorkoutById(r.id);
        if (w != null) list.add(w);
      }
      return list;
    });
  }
}
