import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/workout_models.dart';
import 'datasources/default_exercises.dart';
import '../presentation/controllers/workout_providers.dart';

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
        imageAsset: json['imageAsset'] as String? ??
            'assets/images/workouts/today_workout_athlete.png',
        exerciseIds: (json['exerciseIds'] as List<dynamic>?)
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
    description: 'Bench Press, Incline Press, Overhead Press & Tricep extensions',
    imageAsset: 'assets/images/workouts/today_workout_athlete.png',
    exerciseIds: [
      'ex-incline-barbell-press',
      'ex-arnold-press',
      'ex-lateral-raise-db',
    ],
  ),
  WorkoutRoutine(
    id: 'routine-pull',
    title: 'Pull Day: Back & Biceps',
    category: 'Strength',
    durationMinutes: 50,
    difficulty: 'Advanced',
    description: 'Dumbbell Pullover, Lat Rows & Arm hypertrophy',
    imageAsset: 'assets/images/categories/strength.png',
    exerciseIds: [
      'ex-dumbbell-pullover',
    ],
  ),
  WorkoutRoutine(
    id: 'routine-legs',
    title: 'Leg Day: Quads, Hams & Core',
    category: 'Strength',
    durationMinutes: 55,
    difficulty: 'Intermediate',
    description: 'Lower body foundation, compound movement & core balance',
    imageAsset: 'assets/images/categories/bodyweight.png',
    exerciseIds: [],
  ),
  WorkoutRoutine(
    id: 'routine-conditioning',
    title: 'Athletic Conditioning & Agility',
    category: 'Cardio & Agility',
    durationMinutes: 40,
    difficulty: 'Intermediate',
    description: 'High intensity aerobic intervals and endurance circuit',
    imageAsset: 'assets/images/categories/hiit.png',
    exerciseIds: [],
  ),
];

class RoutineState {
  final List<WorkoutRoutine> routines;
  final String assignedRoutineId;

  const RoutineState({
    required this.routines,
    required this.assignedRoutineId,
  });

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
      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString(_kCustomRoutinesKey);
      final assignedId = prefs.getString(_kAssignedRoutineKey) ?? 'routine-push';

      List<WorkoutRoutine> custom = [];
      if (customJson != null && customJson.isNotEmpty) {
        final decoded = jsonDecode(customJson) as List<dynamic>;
        custom = decoded.map((e) => WorkoutRoutine.fromJson(e as Map<String, dynamic>)).toList();
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
      description: description ??
          'Custom user routine (${exerciseIds.length} exercises)',
      imageAsset: 'assets/images/workouts/today_workout_athlete.png',
      exerciseIds: exerciseIds,
      isCustom: true,
    );

    final updated = [...state.routines, newRoutine];
    state = state.copyWith(
      routines: updated,
      assignedRoutineId: newRoutine.id,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final customOnly = updated.where((r) => r.isCustom).map((r) => r.toJson()).toList();
      await prefs.setString(_kCustomRoutinesKey, jsonEncode(customOnly));
      await prefs.setString(_kAssignedRoutineKey, newRoutine.id);
    } catch (_) {}

    return newRoutine;
  }

  /// One-tap "Mark as Done" for a routine
  Future<void> markRoutineAsDone(WorkoutRoutine routine) async {
    final now = DateTime.now();
    final repo = ref.read(workoutRepositoryProvider);
    final exercises = defaultExercisesList
        .where((e) => routine.exerciseIds.contains(e.id))
        .toList();

    final burned = (routine.durationMinutes * 7.5).round();

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
          sets: [
            WorkoutSetEntity(
              id: 'set_${_uuid.v4()}',
              workoutExerciseId: exEntityId,
              setNumber: 1,
              reps: 10,
              weightKg: 40,
              isCompleted: true,
            ),
          ],
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
