import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../sync/sync_outbox_worker.dart';
import '../sync/sync_utils.dart';
import '../../features/workouts/domain/models/workout_models.dart';
import '../../features/workouts/domain/repositories/workout_repository.dart';
import '../../features/workouts/data/repositories/workout_repository_impl.dart';

export '../../features/workouts/domain/repositories/workout_repository.dart';

/// Local implementation: Drift database only (Guest mode).
/// No network calls made when in guest mode.
class LocalWorkoutRepository implements WorkoutRepository {
  final AppDatabase db;
  final WorkoutRepositoryImpl _impl;

  LocalWorkoutRepository(this.db)
      : _impl = WorkoutRepositoryImpl(db, userId: 'guest');

  @override
  Stream<List<WorkoutEntity>> watchWorkouts() => _impl.watchWorkouts();

  @override
  Future<List<WorkoutEntity>> getWorkouts() => _impl.getWorkouts();

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) => _impl.getWorkoutById(id);

  @override
  Future<void> saveWorkout(WorkoutEntity workout) => _impl.saveWorkout(workout);

  @override
  Future<void> deleteWorkout(String id) => _impl.deleteWorkout(id);

  @override
  Future<List<ExerciseEntity>> getExercises(
          {String? query, String? category, String? genderFilter}) =>
      _impl.getExercises(
          query: query, category: category, genderFilter: genderFilter);

  @override
  Future<ExerciseEntity?> getExerciseById(String id) => _impl.getExerciseById(id);

  @override
  Future<void> seedDefaultExercises() => _impl.seedDefaultExercises();
}

/// Cloud implementation: Supabase + Drift cache (Write-through: write cloud, update cache; read: read cache, background refresh).
class CloudWorkoutRepository implements WorkoutRepository {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final SyncOutboxWorker outboxWorker;
  final String userId;
  final WorkoutRepositoryImpl _localImpl;

  CloudWorkoutRepository({
    required this.db,
    required this.supabase,
    required this.outboxWorker,
    required this.userId,
  }) : _localImpl = WorkoutRepositoryImpl(db, userId: userId);

  @override
  Stream<List<WorkoutEntity>> watchWorkouts() {
    // Return cache stream immediately for snappy UI
    _backgroundRefreshWorkouts().ignore();
    return _localImpl.watchWorkouts();
  }

  @override
  Future<List<WorkoutEntity>> getWorkouts() async {
    if (supabase != null && isValidUuid(userId)) {
      try {
        await _fetchRemoteAndSaveWorkouts().timeout(const Duration(seconds: 4));
        return await _localImpl.getWorkouts();
      } catch (e) {
        debugPrint('[CloudWorkoutRepository] Remote fetch notice (using cache): $e');
      }
    }
    return await _localImpl.getWorkouts();
  }

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) async {
    return _localImpl.getWorkoutById(id);
  }

  @override
  Future<void> saveWorkout(WorkoutEntity workout) async {
    // 1. Optimistic write-through to local Drift cache first
    await _localImpl.saveWorkout(workout);

    final computedCalories = workout.caloriesBurned ??
        WorkoutEntity.computeCalories(
          category: workout.category ?? workout.title,
          weightKg: 70.0,
          durationSeconds: workout.durationSeconds,
        );

    // 2. Prepare payload with EXPLICIT user_id (Condition 6)
    final workoutPayload = {
      'id': workout.id,
      'user_id': userId,
      'title': workout.title,
      'note': workout.note,
      'started_at': workout.startedAt.toUtc().toIso8601String(),
      'completed_at': workout.completedAt?.toUtc().toIso8601String(),
      'status': workout.status,
      'duration_seconds': workout.durationSeconds,
      'calories_burned': computedCalories,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    // 2. Only perform remote cloud sync if user is authenticated with a valid UUID
    if (!isValidUuid(userId)) {
      return;
    }

    if (supabase != null) {
      try {
        await supabase!.from('workouts').upsert(workoutPayload);

        // Upsert child exercises and sets
        for (final ex in workout.exercises) {
          await supabase!.from('workout_exercises').upsert({
            'id': ex.id,
            'workout_id': workout.id,
            'user_id': userId,
            'exercise_id': ex.exerciseId,
            'order_index': ex.orderIndex,
            'notes': ex.notes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });

          for (final s in ex.sets) {
            await supabase!.from('workout_sets').upsert({
              'id': s.id,
              'workout_exercise_id': ex.id,
              'user_id': userId,
              'set_number': s.setNumber,
              'reps': s.reps,
              'weight_kg': s.weightKg,
              'is_completed': s.isCompleted,
              'rest_seconds': s.restSeconds,
              'set_type': s.type,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
          }
        }
        return;
      } catch (e) {
        debugPrint('[CloudWorkoutRepository] Network write failed, enqueueing to outbox: $e');
      }
    }

    // Fallback: enqueue mutation in sync_queue with explicit user_id
    await outboxWorker.enqueueMutation(
      userId: userId,
      entityType: 'workouts',
      entityId: workout.id,
      operation: 'INSERT',
      payload: workoutPayload,
    );
  }

  @override
  Future<void> deleteWorkout(String id) async {
    // 1. Soft-delete locally in Drift
    await _localImpl.deleteWorkout(id);

    // 2. Only attempt cloud deletion if user is authenticated with a valid UUID
    if (!isValidUuid(userId)) {
      return;
    }

    if (supabase != null) {
      try {
        await supabase!.from('workouts').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).match({'id': id, 'user_id': userId});
        return;
      } catch (e) {
        debugPrint('[CloudWorkoutRepository] Cloud delete failed, queueing: $e');
      }
    }

    await outboxWorker.enqueueMutation(
      userId: userId,
      entityType: 'workouts',
      entityId: id,
      operation: 'DELETE',
      payload: {
        'id': id,
        'user_id': userId,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<List<ExerciseEntity>> getExercises(
          {String? query, String? category, String? genderFilter}) =>
      _localImpl.getExercises(
          query: query, category: category, genderFilter: genderFilter);

  @override
  Future<ExerciseEntity?> getExerciseById(String id) => _localImpl.getExerciseById(id);

  @override
  Future<void> seedDefaultExercises() => _localImpl.seedDefaultExercises();

  Future<void> _backgroundRefreshWorkouts() => _fetchRemoteAndSaveWorkouts();

  Future<void> _fetchRemoteAndSaveWorkouts() async {
    if (supabase == null) return;
    try {
      final rows = await supabase!
          .from('workouts')
          .select()
          .match({'user_id': userId})
          .isFilter('deleted_at', null)
          .order('started_at', ascending: false);

      for (final r in rows) {
        final id = r['id'] as String;
        final title = r['title'] as String;
        final note = r['note'] as String?;
        final startedAt = DateTime.parse(r['started_at'] as String);
        final completedAt = r['completed_at'] != null
            ? DateTime.parse(r['completed_at'] as String)
            : null;
        final status = r['status'] as String? ?? 'in_progress';
        final durationSeconds = r['duration_seconds'] as int? ?? 0;
        final updatedAt = DateTime.parse(r['updated_at'] as String);

        await db.into(db.workouts).insertOnConflictUpdate(
              WorkoutsCompanion.insert(
                id: id,
                userId: drift.Value(userId),
                title: title,
                note: drift.Value(note),
                startedAt: startedAt,
                completedAt: drift.Value(completedAt),
                status: drift.Value(status),
                durationSeconds: drift.Value(durationSeconds),
                caloriesBurned: drift.Value((r['calories_burned'] as num?)?.toInt()),
                updatedAt: updatedAt,
                syncStatus: const drift.Value('synced'),
              ),
            );
      }
    } catch (e) {
      debugPrint('[CloudWorkoutRepository] Background refresh notice: $e');
    }
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final auth = ref.watch(authProvider);
  final db = ref.watch(databaseProvider);

  if (auth.isAuthenticated && auth.user != null) {
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {}

    final outbox = ref.watch(syncOutboxWorkerProvider);
    return CloudWorkoutRepository(
      db: db,
      supabase: client,
      outboxWorker: outbox,
      userId: auth.user!.id,
    );
  }

  return LocalWorkoutRepository(db);
});
