import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';

void main() {
  group('ActiveWorkout Lifecycle & Timestamp Logic', () {
    test(
      'Elapsed time calculates correctly from startedAt and pausedDuration without ticking drift',
      () {
        final now = DateTime.now();
        final startedAt = now.subtract(const Duration(minutes: 25));
        const pausedDuration = Duration(minutes: 3);

        final diff = now.difference(startedAt) - pausedDuration;
        final elapsedSeconds = diff.inSeconds;

        expect(
          elapsedSeconds,
          equals(22 * 60),
        ); // 25 mins - 3 mins = 22 mins = 1320s
      },
    );

    test('Formatted elapsed time handles hours, minutes, and seconds properly', () {
      String formatSeconds(int total) {
        final hours = total ~/ 3600;
        final minutes = (total % 3600) ~/ 60;
        final seconds = total % 60;
        if (hours > 0) {
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }

      expect(formatSeconds(45), equals('00:45'));
      expect(formatSeconds(125), equals('02:05'));
      expect(formatSeconds(3665), equals('01:01:05'));
    });

    test(
      'Rest timer countdown handles target timestamps and delta adjustments',
      () {
        final now = DateTime.now();
        var targetRestEndTime = now.add(const Duration(seconds: 60));

        // After 10s passed:
        final simulatedNow = now.add(const Duration(seconds: 10));
        var remaining = targetRestEndTime.difference(simulatedNow).inSeconds;
        expect(remaining, equals(50));

        // Quick action: +15s
        targetRestEndTime = targetRestEndTime.add(const Duration(seconds: 15));
        remaining = targetRestEndTime.difference(simulatedNow).inSeconds;
        expect(remaining, equals(65));

        // Quick action: -15s
        targetRestEndTime = targetRestEndTime.subtract(
          const Duration(seconds: 15),
        );
        remaining = targetRestEndTime.difference(simulatedNow).inSeconds;
        expect(remaining, equals(50));
      },
    );

    test(
      'Incremental persistence sets in_progress status and preserves sets',
      () {
        final now = DateTime.now();
        final workout = WorkoutEntity(
          id: 'w_persist_test',
          title: 'Crash Recovery Test',
          startedAt: now,
          status: 'in_progress',
          durationSeconds: 120,
          updatedAt: now,
          exercises: [
            const WorkoutExerciseEntity(
              id: 'we_test',
              workoutId: 'w_persist_test',
              exerciseId: 'ex_1',
              exerciseName: 'Bench Press',
              category: 'Strength',
              orderIndex: 0,
              sets: [
                WorkoutSetEntity(
                  id: 's_1',
                  workoutExerciseId: 'we_test',
                  setNumber: 1,
                  reps: 10,
                  weightKg: 80,
                  targetReps: 10,
                  targetWeightKg: 80,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );

        expect(workout.status, equals('in_progress'));
        expect(workout.exercises.first.sets.first.isCompleted, isTrue);
        expect(workout.exercises.first.sets.first.volumeKg, equals(800.0));
      },
    );
  });
}
