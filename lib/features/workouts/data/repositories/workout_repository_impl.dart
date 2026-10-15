import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/domain/repositories/workout_repository.dart';
import 'package:fit_host/features/workouts/data/datasources/default_exercises.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final AppDatabase db;

  WorkoutRepositoryImpl(this.db);

  @override
  Future<void> seedDefaultExercises() async {
    final existing = await (db.select(db.exercises)..limit(1)).getSingleOrNull();
    if (existing == null) {
      await db.batch((batch) {
        batch.insertAll(
          db.exercises,
          defaultExercisesList.map(
            (e) => ExercisesCompanion.insert(
              id: e.id,
              name: e.name,
              category: e.category,
              targetMuscle: e.targetMuscle,
              instructions: e.instructions,
              equipment: e.equipment,
              isCustom: Value(e.isCustom),
              createdAt: e.createdAt,
            ),
          ),
        );
      });
    }
  }

  @override
  Future<List<ExerciseEntity>> getExercises({
    String? query,
    String? category,
  }) async {
    await seedDefaultExercises();
    final q = db.select(db.exercises);
    if (category != null && category.isNotEmpty && category != 'All') {
      q.where((t) => t.category.equals(category));
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
    );
  }

  @override
  Future<void> saveWorkout(WorkoutEntity workout) async {
    await db.transaction(() async {
      await db.into(db.workouts).insertOnConflictUpdate(
            WorkoutsCompanion.insert(
              id: workout.id,
              title: workout.title,
              note: Value(workout.note),
              startedAt: workout.startedAt,
              completedAt: Value(workout.completedAt),
              status: Value(workout.status),
              durationSeconds: Value(workout.durationSeconds),
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
      await db.into(db.syncQueue).insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: 'sync-workout-${workout.id}',
              entityType: 'workout',
              entityId: workout.id,
              operation: 'upsert',
              payload: jsonEncode({
                'id': workout.id,
                'title': workout.title,
                'note': workout.note,
                'startedAt': workout.startedAt.toIso8601String(),
                'completedAt': workout.completedAt?.toIso8601String(),
                'status': workout.status,
                'durationSeconds': workout.durationSeconds,
                'updatedAt': workout.updatedAt.toIso8601String(),
              }),
              createdAt: DateTime.now().toUtc(),
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
      await (db.delete(db.workouts)..where((w) => w.id.equals(id))).go();
      await db.into(db.syncQueue).insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: 'sync-delete-$id',
              entityType: 'workout',
              entityId: id,
              operation: 'delete',
              payload: jsonEncode({'id': id}),
              createdAt: DateTime.now().toUtc(),
            ),
          );
    });
  }

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) async {
    final wRow = await (db.select(db.workouts)..where((t) => t.id.equals(id)))
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
      syncStatus: wRow.syncStatus,
      updatedAt: wRow.updatedAt,
      exercises: exercises,
    );
  }

  @override
  Future<List<WorkoutEntity>> getWorkouts() async {
    final wRows = await (db.select(db.workouts)
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
