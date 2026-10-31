import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/workouts/data/datasources/unified_exercise_catalog_data.dart';
import 'package:fit_host/features/workouts/data/routine_service.dart';

void main() {
  group('Preloaded workout templates', () {
    test('every default routine has exercises', () {
      for (final routine in defaultRoutines) {
        expect(
          routine.exerciseIds,
          isNotEmpty,
          reason: '${routine.title} must not be an empty template',
        );
      }
    });

    test('every preloaded exercise resolves to the canonical catalog', () {
      final canonicalIds = kUnifiedExerciseCatalog.map((e) => e.id).toSet();

      for (final routine in defaultRoutines) {
        for (final exerciseId in routine.exerciseIds) {
          expect(
            canonicalIds,
            contains(canonicalExerciseId(exerciseId)),
            reason:
                '${routine.title} references unavailable exercise $exerciseId',
          );
        }
      }
    });
  });
}
