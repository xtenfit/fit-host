import '../models/workout_models.dart';

/// Service to generate suggested workout routines and exercise selections based on
/// user's gender-specific goals, focus areas, and gender recommendation hierarchy.
class WorkoutPlanGenerator {
  /// Map user-selected gender goals from Step 8b to recommendedFor tags
  static const Map<String, String> goalToTag = {
    // Male-specific goals
    'Upper chest development': 'upper_chest',
    'upper_chest': 'upper_chest',
    'Shoulder width': 'shoulder_width',
    'shoulder_width': 'shoulder_width',
    'Arm size': 'arm_size',
    'arm_size': 'arm_size',
    'Back thickness (V-taper)': 'back_thickness',
    'back_thickness': 'back_thickness',
    'Leg power': 'leg_power',
    'leg_power': 'leg_power',
    'Core strength': 'core_strength',
    'core_strength': 'core_strength',

    // Female-specific goals
    'Glute development': 'glute_focus',
    'glute_focus': 'glute_focus',
    'Hip curves': 'hip_curves',
    'hip_curves': 'hip_curves',
    'Waist definition': 'waist_definition',
    'waist_definition': 'waist_definition',
    'Toned arms': 'toned_arms',
    'toned_arms': 'toned_arms',
    'Thigh shaping': 'thigh_shaping',
    'thigh_shaping': 'thigh_shaping',
    'Full body toning': 'full_body_toning',
    'full_body_toning': 'full_body_toning',
  };

  /// Computes weight for an exercise given user criteria.
  /// Hierarchy:
  /// - Matches user's genderSpecificGoals: 3.0x
  /// - Matches user's focusAreas: 2.0x
  /// - Matches user's gender in recommendedFor: 1.5x
  /// - Neutral: 1.0x
  static double computeWeight({
    required ExerciseEntity exercise,
    required String userGender,
    required List<String> genderSpecificGoals,
    required List<String> focusAreas,
  }) {
    // 1. Matches genderSpecificGoals (3.0x)
    final genderGoalTags = genderSpecificGoals
        .map((g) => goalToTag[g] ?? g.toLowerCase().replaceAll(' ', '_'))
        .toSet();

    final matchesGenderGoal = exercise.recommendedFor.any((tag) => genderGoalTags.contains(tag));
    if (matchesGenderGoal) {
      return 3.0;
    }

    // 2. Matches focusAreas (2.0x)
    final normFocusAreas = focusAreas.map((f) => f.toLowerCase().replaceAll(' ', '_')).toSet();
    final catNorm = exercise.category.toLowerCase().replaceAll(' ', '_');
    final muscleNorm = exercise.targetMuscle.toLowerCase();
    final matchesFocus = normFocusAreas.any((f) =>
        f == catNorm ||
        f == 'full_body' ||
        catNorm.contains(f) ||
        muscleNorm.contains(f.replaceAll('_', ' ')) ||
        exercise.recommendedFor.contains(f));
    if (matchesFocus) {
      return 2.0;
    }

    // 3. Matches gender (1.5x)
    final cleanGender = userGender.toLowerCase();
    if (cleanGender.isNotEmpty &&
        cleanGender != 'other' &&
        cleanGender != 'prefer_not_to_say' &&
        cleanGender != 'unspecified' &&
        exercise.recommendedFor.contains(cleanGender)) {
      return 1.5;
    }

    // 4. Neutral
    return 1.0;
  }

  /// Generates a suggested list of exercises ordered by weight,
  /// guaranteeing that at least 2 top-priority (3.0x) exercises are included if available.
  static List<ExerciseEntity> generateSuggestedExercises({
    required List<ExerciseEntity> pool,
    required String userGender,
    required List<String> genderSpecificGoals,
    required List<String> focusAreas,
    int count = 6,
  }) {
    if (pool.isEmpty) return [];

    // Group by weight
    final weighted = pool.map((e) {
      final w = computeWeight(
        exercise: e,
        userGender: userGender,
        genderSpecificGoals: genderSpecificGoals,
        focusAreas: focusAreas,
      );
      return MapEntry(e, w);
    }).toList();

    // Sort descending by weight
    weighted.sort((a, b) => b.value.compareTo(a.value));

    final topPriority = weighted.where((entry) => entry.value >= 3.0).map((e) => e.key).toList();
    final otherExercises = weighted.where((entry) => entry.value < 3.0).map((e) => e.key).toList();

    final result = <ExerciseEntity>[];

    // Ensure at least 2 from top-priority if available
    final topToAdd = topPriority.take(2).toList();
    result.addAll(topToAdd);

    // Remaining top priority
    final remainingTop = topPriority.skip(2).toList();

    // Add remaining top priority then lower priority until count is reached
    final candidates = [...remainingTop, ...otherExercises];
    for (final e in candidates) {
      if (result.length >= count) break;
      if (!result.contains(e)) {
        result.add(e);
      }
    }

    // If pool has fewer exercises than count, ensure everything unique is included
    if (result.length < count) {
      for (final e in pool) {
        if (!result.contains(e)) {
          result.add(e);
        }
        if (result.length >= count) break;
      }
    }

    return result;
  }
}
