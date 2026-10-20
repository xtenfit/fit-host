import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/repositories/workout_repository_impl.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';

void main() {
  group('Workout Calories Burned & MET Formula Tests', () {
    test('Unit test: 60-min strength at 70kg ≈ 420 kcal (± 5)', () {
      // 60 minutes = 3600 seconds, weight = 70.0 kg, MET = 6.0
      final kcal = WorkoutEntity.computeCalories(
        category: 'strength',
        weightKg: 70.0,
        durationSeconds: 3600,
      );

      // Verify exact calculation: 6.0 * 70.0 * (3600 / 3600) = 420
      expect(kcal, closeTo(420, 5));
      expect(kcal, equals(420));
    });

    test('Verifies MET map: strength=6.0, cardio=8.0, yoga=3.0, default=5.0', () {
      const weight = 70.0;
      const oneHour = 3600;

      // Strength: 6.0 * 70 * 1 = 420 kcal
      final strengthKcal = WorkoutEntity.computeCalories(
        category: 'strength',
        weightKg: weight,
        durationSeconds: oneHour,
      );
      expect(strengthKcal, equals(420));

      // Cardio: 8.0 * 70 * 1 = 560 kcal
      final cardioKcal = WorkoutEntity.computeCalories(
        category: 'cardio',
        weightKg: weight,
        durationSeconds: oneHour,
      );
      expect(cardioKcal, equals(560));

      // Yoga: 3.0 * 70 * 1 = 210 kcal
      final yogaKcal = WorkoutEntity.computeCalories(
        category: 'yoga',
        weightKg: weight,
        durationSeconds: oneHour,
      );
      expect(yogaKcal, equals(210));

      // Default (e.g. general/other): 5.0 * 70 * 1 = 350 kcal
      final defaultKcal = WorkoutEntity.computeCalories(
        category: 'general mobility',
        weightKg: weight,
        durationSeconds: oneHour,
      );
      expect(defaultKcal, equals(350));
    });

    test('Drift v4 workouts schema: stores calories_burned and retrieves it correctly', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = WorkoutRepositoryImpl(db);

      final now = DateTime.now().toUtc();
      final workout = WorkoutEntity(
        id: 'workout-cal-test-01',
        title: 'Morning Strength Training',
        category: 'strength',
        startedAt: now.subtract(const Duration(hours: 1)),
        completedAt: now,
        status: 'completed',
        durationSeconds: 3600, // 60 minutes
        updatedAt: now,
      );

      // Save workout without pre-computed caloriesBurned -> repository computes 420 kcal
      await repo.saveWorkout(workout);

      // 1. Verify in Drift SQLite database row
      final row = await (db.select(db.workouts)..where((t) => t.id.equals('workout-cal-test-01'))).getSingle();
      expect(row.caloriesBurned, isNotNull);
      expect(row.caloriesBurned, equals(420));

      // 2. Verify repository getWorkoutById maps caloriesBurned back to WorkoutEntity
      final retrieved = await repo.getWorkoutById('workout-cal-test-01');
      expect(retrieved, isNotNull);
      expect(retrieved!.caloriesBurned, equals(420));

      // 3. Verify sync_queue mutation payload includes calories_burned
      final queueItem = await (db.select(db.syncQueue)..where((t) => t.entityId.equals('workout-cal-test-01'))).getSingle();
      final payload = jsonDecode(queueItem.payload) as Map<String, dynamic>;
      expect(payload['calories_burned'], equals(420));

      await db.close();
    });

    test('Workout save preserves explicitly passed caloriesBurned if provided', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = WorkoutRepositoryImpl(db);

      final now = DateTime.now().toUtc();
      final workout = WorkoutEntity(
        id: 'workout-custom-cal-02',
        title: 'Custom Outdoor Run',
        category: 'cardio',
        startedAt: now.subtract(const Duration(minutes: 30)),
        completedAt: now,
        status: 'completed',
        durationSeconds: 1800,
        caloriesBurned: 310, // Explicit reading from fitness wearable
        updatedAt: now,
      );

      await repo.saveWorkout(workout);

      final retrieved = await repo.getWorkoutById('workout-custom-cal-02');
      expect(retrieved!.caloriesBurned, equals(310));

      final queueItem = await (db.select(db.syncQueue)..where((t) => t.entityId.equals('workout-custom-cal-02'))).getSingle();
      final payload = jsonDecode(queueItem.payload) as Map<String, dynamic>;
      expect(payload['calories_burned'], equals(310));

      await db.close();
    });
  });
}
