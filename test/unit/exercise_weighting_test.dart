import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/workouts/domain/services/workout_plan_generator.dart';
import 'package:fit_host/features/workouts/data/datasources/default_exercises.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';

void main() {
  group('Exercise Weighting Hierarchy & Plan Generator Tests', () {
    test('Calculates 3.0x weight for exercise matching gender-specific goals', () {
      final inclinePress = defaultExercisesList.firstWhere((e) => e.name == 'Incline Barbell Press');
      final weight = WorkoutPlanGenerator.computeWeight(
        exercise: inclinePress,
        userGender: 'male',
        genderSpecificGoals: ['Upper chest development'],
        focusAreas: ['Chest'],
      );

      expect(weight, equals(3.0));
    });

    test('Calculates 2.0x weight for exercise matching general focus area without gender goal', () {
      final flatBench = defaultExercisesList.firstWhere((e) => e.name == 'Bench Press (Barbell)');
      final weight = WorkoutPlanGenerator.computeWeight(
        exercise: flatBench,
        userGender: 'female',
        genderSpecificGoals: ['Glute development'],
        focusAreas: ['Chest'],
      );

      expect(weight, equals(2.0));
    });

    test('Calculates 1.5x weight for exercise tagged with matching gender when no specific focus or goal matches', () {
      final lateralRaise = defaultExercisesList.firstWhere((e) => e.name == 'Lateral Raise (Dumbbell)');
      // User is male, but focus is 'Legs' and goals are 'Leg power'
      final weight = WorkoutPlanGenerator.computeWeight(
        exercise: lateralRaise,
        userGender: 'male',
        genderSpecificGoals: ['Leg power'],
        focusAreas: ['Legs'],
      );

      expect(weight, equals(1.5));
    });

    test('Calculates 1.0x weight for neutral exercise with no matches', () {
      final neutralEx = ExerciseEntity(
        id: 'neutral-ex',
        name: 'Neutral Move',
        category: 'Calisthenics',
        targetMuscle: 'Forearms',
        instructions: 'Test instructions',
        equipment: 'Bodyweight',
        recommendedFor: const [],
        createdAt: DateTime.utc(2025, 1, 1),
      );

      final weight = WorkoutPlanGenerator.computeWeight(
        exercise: neutralEx,
        userGender: 'male',
        genderSpecificGoals: ['Upper chest development'],
        focusAreas: ['Back'],
      );

      expect(weight, equals(1.0));
    });

    test('generateSuggestedExercises guarantees at least 2 top-priority (3.0x) exercises for female user', () {
      final suggested = WorkoutPlanGenerator.generateSuggestedExercises(
        pool: defaultExercisesList,
        userGender: 'female',
        genderSpecificGoals: ['Glute development', 'Hip curves'],
        focusAreas: ['Glutes', 'Legs'],
        count: 6,
      );

      expect(suggested.length, equals(6));
      
      // Count how many match the 3.0x weight
      final topPriorityCount = suggested.where((e) {
        return WorkoutPlanGenerator.computeWeight(
          exercise: e,
          userGender: 'female',
          genderSpecificGoals: ['Glute development', 'Hip curves'],
          focusAreas: ['Glutes', 'Legs'],
        ) == 3.0;
      }).length;

      expect(topPriorityCount, greaterThanOrEqualTo(2));
      // First exercises must be high-priority glute exercises
      final names = suggested.map((e) => e.name).toList();
      expect(names.any((n) => n.contains('Glute') || n.contains('Hip Thrust')), isTrue);
    });

    test('generateSuggestedExercises guarantees at least 2 top-priority (3.0x) exercises for male user', () {
      final suggested = WorkoutPlanGenerator.generateSuggestedExercises(
        pool: defaultExercisesList,
        userGender: 'male',
        genderSpecificGoals: ['Upper chest development', 'Shoulder width'],
        focusAreas: ['Chest', 'Shoulders'],
        count: 6,
      );

      expect(suggested.length, equals(6));

      final topPriorityCount = suggested.where((e) {
        return WorkoutPlanGenerator.computeWeight(
          exercise: e,
          userGender: 'male',
          genderSpecificGoals: ['Upper chest development', 'Shoulder width'],
          focusAreas: ['Chest', 'Shoulders'],
        ) == 3.0;
      }).length;

      expect(topPriorityCount, greaterThanOrEqualTo(2));
      final names = suggested.map((e) => e.name).toList();
      expect(names.contains('Incline Barbell Press') || names.contains('Lateral Raise (Dumbbell)'), isTrue);
    });
  });
}
