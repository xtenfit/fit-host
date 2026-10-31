import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/workout_repository.dart'
    show routineRepositoryProvider, WorkoutRepository;
import '../domain/models/workout_models.dart';
import 'datasources/default_exercises.dart';
import 'datasources/unified_exercise_catalog_data.dart';
import '../presentation/controllers/workout_providers.dart';
import '../../profile/presentation/controllers/user_profile_controller.dart';

class WorkoutRoutine {
  final String id;
  final String title;
  final String category;
  final int durationMinutes;
  final String difficulty;
  final String description;
  final String imageAsset;
  final List<String> exerciseIds;
  final bool isCustom;

  const WorkoutRoutine({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.difficulty,
    required this.description,
    required this.imageAsset,
    required this.exerciseIds,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'durationMinutes': durationMinutes,
    'difficulty': difficulty,
    'description': description,
    'imageAsset': imageAsset,
    'exerciseIds': exerciseIds,
    'isCustom': isCustom,
  };

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) => WorkoutRoutine(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String? ?? 'Strength',
    durationMinutes: json['durationMinutes'] as int? ?? 45,
    difficulty: json['difficulty'] as String? ?? 'Intermediate',
    description: json['description'] as String? ?? '',
    imageAsset:
        json['imageAsset'] as String? ??
        'assets/images/workouts/today_workout_athlete.png',
    exerciseIds:
        (json['exerciseIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    isCustom: json['isCustom'] as bool? ?? false,
  );
}

const List<WorkoutRoutine> defaultRoutines = [
  WorkoutRoutine(
    id: 'routine-push',
    title: 'Push Day: Chest, Delts & Triceps',
    category: 'Strength',
    durationMinutes: 45,
    difficulty: 'Intermediate',
    description:
        'Bench Press, Incline Press, Overhead Press, Lateral Raises & Tricep Pushdown',
    imageAsset: 'assets/images/workouts/today_workout_athlete.png',
    exerciseIds: [
      'ex-bench-press',
      'ex-incline-barbell-press',
      'ex-arnold-press',
      'ex-lateral-raise-db',
      'ex-tricep-pushdown',
    ],
  ),
  WorkoutRoutine(
    id: 'routine-pull',
    title: 'Pull Day: Back & Biceps',
    category: 'Strength',
    durationMinutes: 50,
    difficulty: 'Advanced',
    description:
        'Deadlifts, Pull-Ups, Barbell Rows, Dumbbell Pullovers & Bicep Curls',
    imageAsset: 'assets/images/categories/strength.png',
    exerciseIds: [
      'ex-deadlift',
      'ex-pullup',
      'ex-barbell-row',
      'ex-dumbbell-pullover',
      'ex-bicep-curl',
    ],
  ),
  WorkoutRoutine(
    id: 'routine-legs',
    title: 'Leg Day: Quads, Hams & Core',
    category: 'Strength',
    durationMinutes: 55,
    difficulty: 'Intermediate',
    description:
        'Barbell Squats, Romanian Deadlifts, Walking Lunges & Core Planks',
    imageAsset: 'assets/images/categories/bodyweight.png',
    exerciseIds: ['ex-barbell-squat', 'ex-deadlift', 'ex-lunges', 'ex-plank'],
  ),
  WorkoutRoutine(
    id: 'routine-conditioning',
    title: 'Athletic Conditioning & Agility',
    category: 'Cardio & Agility',
    durationMinutes: 40,
    difficulty: 'Intermediate',
    description: 'Push-Ups, Pull-Ups, Walking Lunges & Isometric Core Planks',
    imageAsset: 'assets/images/categories/hiit.png',
    exerciseIds: ['ex-pushup', 'ex-pullup', 'ex-lunges', 'ex-plank'],
  ),
];

String canonicalExerciseId(String exerciseId) =>
    kLegacyExerciseMappings[exerciseId] ?? exerciseId;

String _humanizeExerciseId(String id) {
  final clean = id.replaceAll('ex-', '').replaceAll('-', ' ').trim();
  return clean
      .split(' ')
      .map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}

Future<List<ExerciseEntity>> resolveRoutineExercises(
  WorkoutRepository? repository,
  Iterable<String> exerciseIds,
) async {
  final resolved = <ExerciseEntity>[];

  // 1. In-memory indexes for instant, zero-latency fallback resolution
  final catalogById = <String, ExerciseEntity>{};
  final catalogByName = <String, ExerciseEntity>{};

  for (final ex in kUnifiedExerciseCatalog) {
    catalogById[ex.id] = ex;
    if (ex.canonicalId != null) {
      catalogById[ex.canonicalId!] = ex;
    }
    catalogByName[ex.name.toLowerCase().trim()] = ex;
  }

  for (final ex in defaultExercisesList) {
    catalogById[ex.id] = ex;
    catalogByName[ex.name.toLowerCase().trim()] = ex;
  }

  for (final id in exerciseIds) {
    final mappedId = kLegacyExerciseMappings[id] ?? id;
    ExerciseEntity? found;

    // A. Direct database lookup via repository
    if (repository != null) {
      try {
        found =
            await repository.getExerciseById(mappedId) ??
            await repository.getExerciseById(id);
      } catch (_) {}
    }

    // B. Direct in-memory catalog lookup by mappedId or raw id
    found ??= catalogById[mappedId] ?? catalogById[id];

    // C. Slug / name heuristic matching
    if (found == null) {
      final clean = id
          .toLowerCase()
          .replaceAll('ex-', '')
          .replaceAll('-', ' ')
          .trim();
      for (final entry in catalogByName.entries) {
        if (entry.key.contains(clean) || clean.contains(entry.key)) {
          found = entry.value;
          break;
        }
      }
    }

    // D. Common exercise semantic fallbacks
    if (found == null) {
      if (id.contains('bench')) {
        found = catalogById['9da7a605-e3b6-55ae-a0a0-28f417eb3a8f'];
      } else if (id.contains('incline')) {
        found = catalogById['c589ed7d-b627-58f5-8c93-f58f27050f59'];
      } else if (id.contains('overhead') || id.contains('press')) {
        found = catalogById['bb9a1e5e-39a6-55fd-841f-2fe682cfee58'];
      } else if (id.contains('tricep') || id.contains('pushdown')) {
        found = catalogById['da1e063e-24c7-5ea5-b6fb-ca3f394acb86'];
      } else if (id.contains('deadlift')) {
        found = catalogById['70ed073d-9ef7-52d3-a8a8-8eed2028110a'];
      } else if (id.contains('pullup') || id.contains('pull-up')) {
        found = catalogById['ea15170a-6e1d-5e39-a83a-b1d13bd9fa99'];
      } else if (id.contains('row')) {
        found = catalogById['87517ccf-d112-51c5-b482-b2ee9f42eb1b'];
      } else if (id.contains('curl')) {
        found = catalogById['0ddd1277-bffd-5a29-8c86-dc9cbf15a483'];
      } else if (id.contains('squat')) {
        found = catalogById['451fe126-c77b-5be6-8ef3-4690d283096e'];
      } else if (id.contains('lunge')) {
        found = catalogById['1b3bc40e-561e-5d63-9ecb-2fcbcfb1833b'];
      } else if (id.contains('pushup') || id.contains('push-up')) {
        found = catalogById['db5eb5ad-0f11-55e1-aa70-9bc984030377'];
      } else if (id.contains('plank')) {
        found = catalogById['9825cdb8-81c9-5273-9bac-039ab80b8f1f'];
      } else if (id.contains('bridge') || id.contains('glute')) {
        found = catalogById['89513af0-55c3-5f5e-8d4c-08fc69b7ecfc'];
      }
    }

    // E. Guaranteed non-null synthesis
    found ??= ExerciseEntity(
      id: mappedId,
      canonicalId: mappedId,
      source: 'synthesized',
      originalSourceId: id,
      name: _humanizeExerciseId(id),
      aliases: const [],
      category: 'General',
      bodyPart: 'full body',
      targetMuscle: 'Full Body',
      muscleGroup: 'Full Body',
      secondaryMuscles: const [],
      instructions:
          'Perform exercise with controlled cadence and full range of motion.',
      equipment: 'Bodyweight',
      isCustom: false,
      createdAt: DateTime.now(),
    );

    resolved.add(found);
  }

  return resolved;
}

class RoutineState {
  final List<WorkoutRoutine> routines;
  final String assignedRoutineId;

  const RoutineState({required this.routines, required this.assignedRoutineId});

  WorkoutRoutine? get assignedRoutine {
    try {
      return routines.firstWhere((r) => r.id == assignedRoutineId);
    } catch (_) {
      return routines.isNotEmpty ? routines.first : null;
    }
  }

  RoutineState copyWith({
    List<WorkoutRoutine>? routines,
    String? assignedRoutineId,
  }) {
    return RoutineState(
      routines: routines ?? this.routines,
      assignedRoutineId: assignedRoutineId ?? this.assignedRoutineId,
    );
  }
}

class RoutineNotifier extends Notifier<RoutineState> {
  static const _kCustomRoutinesKey = 'fit_host_custom_workout_routines_v1';
  static const _kAssignedRoutineKey = 'fit_host_assigned_routine_id_v1';
  final _uuid = const Uuid();

  @override
  RoutineState build() {
    _loadState();
    return const RoutineState(
      routines: defaultRoutines,
      assignedRoutineId: 'routine-push',
    );
  }

  Future<void> _loadState() async {
    try {
      await ref.read(workoutRepositoryProvider).seedDefaultExercises();
      final routineRepo = ref.read(routineRepositoryProvider);
      await routineRepo.seedTemplateRoutines();

      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString(_kCustomRoutinesKey);
      final assignedId =
          prefs.getString(_kAssignedRoutineKey) ?? 'routine-push';

      List<WorkoutRoutine> custom = [];
      if (customJson != null && customJson.isNotEmpty) {
        final decoded = jsonDecode(customJson) as List<dynamic>;
        custom = decoded
            .map((e) => WorkoutRoutine.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      state = RoutineState(
        routines: [...defaultRoutines, ...custom],
        assignedRoutineId: assignedId,
      );
    } catch (e) {
      debugPrint('[RoutineNotifier] Load error: $e');
    }
  }

  Future<void> setAssignedRoutine(String routineId) async {
    state = state.copyWith(assignedRoutineId: routineId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAssignedRoutineKey, routineId);
    } catch (_) {}
  }

  Future<WorkoutRoutine> createCustomRoutine({
    required String title,
    required String category,
    required int durationMinutes,
    required List<String> exerciseIds,
    String difficulty = 'Intermediate',
    String? description,
  }) async {
    final newRoutine = WorkoutRoutine(
      id: 'custom_routine_${_uuid.v4()}',
      title: title,
      category: category,
      durationMinutes: durationMinutes,
      difficulty: difficulty,
      description:
          description ??
          'Custom user routine (${exerciseIds.length} exercises)',
      imageAsset: 'assets/images/workouts/today_workout_athlete.png',
      exerciseIds: exerciseIds,
      isCustom: true,
    );

    final updated = [...state.routines, newRoutine];
    state = state.copyWith(routines: updated, assignedRoutineId: newRoutine.id);

    try {
      final prefs = await SharedPreferences.getInstance();
      final customOnly = updated
          .where((r) => r.isCustom)
          .map((r) => r.toJson())
          .toList();
      await prefs.setString(_kCustomRoutinesKey, jsonEncode(customOnly));
      await prefs.setString(_kAssignedRoutineKey, newRoutine.id);

      // Also persist to relational RoutineRepository
      final routineRepo = ref.read(routineRepositoryProvider);
      final now = DateTime.now();
      final routineEntity = RoutineEntity(
        id: newRoutine.id,
        userId: 'guest',
        name: newRoutine.title,
        description: newRoutine.description,
        category: newRoutine.category,
        difficulty: newRoutine.difficulty.toLowerCase(),
        estimatedDurationMinutes: newRoutine.durationMinutes,
        isTemplate: false,
        createdAt: now,
        updatedAt: now,
        exercises: exerciseIds.asMap().entries.map((entry) {
          final exId = 're_${_uuid.v4()}';
          return RoutineExerciseEntity(
            id: exId,
            routineId: newRoutine.id,
            exerciseId: entry.value,
            exerciseName: entry.value,
            category: newRoutine.category,
            orderIndex: entry.key,
            sets: [
              RoutineSetEntity(
                id: 'rs_${_uuid.v4()}',
                routineExerciseId: exId,
                setNumber: 1,
                targetReps: 10,
                restSeconds: 60,
              ),
            ],
          );
        }).toList(),
      );
      await routineRepo.saveRoutine(routineEntity);
    } catch (_) {}

    return newRoutine;
  }

  /// One-tap "Mark as Done" for a routine
  Future<void> markRoutineAsDone(WorkoutRoutine routine) async {
    final now = DateTime.now();
    final repo = ref.read(workoutRepositoryProvider);

    final exercises = <ExerciseEntity>[];
    for (final id in routine.exerciseIds) {
      final ex = await repo.getExerciseById(id);
      if (ex != null) {
        exercises.add(ex);
      } else {
        try {
          final def = defaultExercisesList.firstWhere((d) => d.id == id);
          exercises.add(
            ExerciseEntity(
              id: def.id,
              canonicalId: kLegacyExerciseMappings[def.id] ?? def.id,
              name: def.name,
              category: def.category,
              targetMuscle: def.targetMuscle,
              instructions: def.instructions,
              equipment: def.equipment,
              createdAt: def.createdAt,
            ),
          );
        } catch (_) {}
      }
    }

    final profile = ref.read(userProfileProvider);
    final userWeight = profile.weightKg > 0 ? profile.weightKg : 72.0;
    // Standard MET for moderate resistance routine ~ 5.0 MET: (5.0 * 3.5 * weightKg / 200) * minutes
    final burned = ((5.0 * 3.5 * userWeight / 200.0) * routine.durationMinutes)
        .round();

    final workoutId = 'workout_${_uuid.v4()}';
    final workout = WorkoutEntity(
      id: workoutId,
      title: routine.title,
      category: routine.category,
      startedAt: now.subtract(Duration(minutes: routine.durationMinutes)),
      completedAt: now,
      status: 'completed',
      durationSeconds: routine.durationMinutes * 60,
      caloriesBurned: burned,
      updatedAt: now,
      exercises: List.generate(exercises.length, (idx) {
        final ex = exercises[idx];
        final exEntityId = 'we_${_uuid.v4()}';
        return WorkoutExerciseEntity(
          id: exEntityId,
          workoutId: workoutId,
          exerciseId: ex.id,
          exerciseName: ex.name,
          category: ex.category,
          orderIndex: idx,
          // Do not fabricate completed sets/volume if exercises were not explicitly logged
          sets: const [],
        );
      }),
    );

    await repo.saveWorkout(workout);
    ref.invalidate(workoutsStreamProvider);
  }
}

final routineProvider = NotifierProvider<RoutineNotifier, RoutineState>(
  RoutineNotifier.new,
);
