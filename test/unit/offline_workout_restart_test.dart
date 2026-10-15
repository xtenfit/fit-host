import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';

void main() {
  test('First Vertical Slice: create workout, save to SQLite, simulate app restart, verify offline persistence',
      () async {
    // 1. Create a persistent temporary SQLite database file on disk
    final tempDir = await Directory.systemTemp.createTemp('fit_host_test_');
    final dbFile = File('${tempDir.path}/offline_test.db');

    final workoutId = 'slice-workout-001';
    final now = DateTime.now().toUtc();

    // 2. Launch App Instance 1 (First Session)
    var dbSession1 = AppDatabase(NativeDatabase(dbFile));
    var repoSession1 = WorkoutRepositoryImpl(dbSession1);

    // Seed default library and create initial workout
    await repoSession1.seedDefaultExercises();

    final workout = WorkoutEntity(
      id: workoutId,
      title: 'Legs & Core Power',
      note: 'Focus on explosive squat depth',
      startedAt: now,
      completedAt: now.add(const Duration(minutes: 50)),
      status: 'completed',
      durationSeconds: 3000,
      syncStatus: 'pending',
      updatedAt: now,
      exercises: [
        WorkoutExerciseEntity(
          id: 'slice-we-001',
          workoutId: workoutId,
          exerciseId: 'ex-barbell-squat',
          exerciseName: 'Barbell Back Squat',
          category: 'Legs',
          orderIndex: 0,
          sets: [
            WorkoutSetEntity(
              id: 'slice-set-001',
              workoutExerciseId: 'slice-we-001',
              setNumber: 1,
              reps: 5,
              weightKg: 100.0,
              isCompleted: true,
            ),
            WorkoutSetEntity(
              id: 'slice-set-002',
              workoutExerciseId: 'slice-we-001',
              setNumber: 2,
              reps: 5,
              weightKg: 100.0,
              isCompleted: true,
            ),
          ],
        ),
      ],
    );

    // Save workout to disk
    await repoSession1.saveWorkout(workout);

    // Verify it is visible in session 1
    final session1Workouts = await repoSession1.getWorkouts();
    expect(session1Workouts.length, equals(1));
    expect(session1Workouts.first.title, equals('Legs & Core Power'));

    // 3. SIMULATE APP TERMINATION / RESTART
    // Close session 1 completely
    await dbSession1.close();

    // 4. Launch App Instance 2 (Simulating App Restart Offline)
    var dbSession2 = AppDatabase(NativeDatabase(dbFile));
    var repoSession2 = WorkoutRepositoryImpl(dbSession2);

    // Fetch history from fresh app instance
    final session2Workouts = await repoSession2.getWorkouts();
    expect(session2Workouts, isNotEmpty);
    expect(session2Workouts.length, equals(1));

    final persistedWorkout = session2Workouts.first;
    expect(persistedWorkout.id, equals(workoutId));
    expect(persistedWorkout.title, equals('Legs & Core Power'));
    expect(persistedWorkout.note, equals('Focus on explosive squat depth'));
    expect(persistedWorkout.status, equals('completed'));
    expect(persistedWorkout.durationSeconds, equals(3000));
    expect(persistedWorkout.exercises.length, equals(1));

    final persistedExercise = persistedWorkout.exercises.first;
    expect(persistedExercise.exerciseName, equals('Barbell Back Squat'));
    expect(persistedExercise.sets.length, equals(2));
    expect(persistedExercise.sets[0].weightKg, equals(100.0));
    expect(persistedExercise.sets[0].reps, equals(5));
    expect(persistedExercise.sets[0].isCompleted, isTrue);
    expect(persistedExercise.sets[1].weightKg, equals(100.0));
    expect(persistedExercise.sets[1].reps, equals(5));

    // Verify total calculated volume across restart
    // 100 * 5 + 100 * 5 = 1000 kg
    expect(persistedWorkout.totalVolumeKg, equals(1000.0));

    // Cleanup session 2
    await dbSession2.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
}
