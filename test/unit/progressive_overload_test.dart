import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/domain/repositories/workout_repository.dart';
import 'package:fit_host/features/workouts/domain/repositories/routine_repository.dart';
import 'package:fit_host/features/workouts/domain/services/progressive_overload_service.dart';

class MockWorkoutRepository implements WorkoutRepository {
  List<WorkoutEntity> mockWorkouts = [];

  @override
  Future<List<WorkoutEntity>> getWorkouts() async => mockWorkouts;

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) async =>
      mockWorkouts.where((w) => w.id == id).firstOrNull;

  @override
  Stream<List<WorkoutEntity>> watchWorkouts() => Stream.value(mockWorkouts);

  @override
  Future<void> saveWorkout(WorkoutEntity workout) async =>
      mockWorkouts.add(workout);

  @override
  Future<void> deleteWorkout(String id) async =>
      mockWorkouts.removeWhere((w) => w.id == id);

  @override
  Future<List<ExerciseEntity>> getExercises({
    String? query,
    String? category,
    String? genderFilter,
    String? bodyPart,
    String? equipment,
    bool includeArchived = false,
    int? limit,
    int offset = 0,
  }) async => [];

  @override
  Future<ExerciseEntity?> getExerciseById(String id) async => null;

  @override
  Future<void> seedDefaultExercises() async {}
}

class MockRoutineRepository implements RoutineRepository {
  final Map<String, PersonalRecordEntity> prs = {};
  final Map<String, ProgressionSettingsEntity> settings = {};

  @override
  Future<List<RoutineEntity>> getRoutines({
    bool includeArchived = false,
  }) async => [];

  @override
  Future<RoutineEntity?> getRoutineById(String id) async => null;

  @override
  Stream<List<RoutineEntity>> watchRoutines({bool includeArchived = false}) =>
      Stream.value([]);

  @override
  Future<void> saveRoutine(RoutineEntity routine) async {}

  @override
  Future<void> deleteRoutine(String id) async {}

  @override
  Future<RoutineEntity> duplicateRoutine(
    String routineId, {
    String? newName,
  }) async => throw UnimplementedError();

  @override
  Future<void> archiveRoutine(String routineId, {bool archive = true}) async {}

  @override
  Future<void> seedTemplateRoutines() async {}

  @override
  Future<List<PersonalRecordEntity>> getPersonalRecords({
    String? exerciseId,
  }) async => prs.values.toList();

  @override
  Future<PersonalRecordEntity?> getPersonalRecord(
    String exerciseId,
    String recordType,
  ) async => prs['${exerciseId}_$recordType'];

  @override
  Future<void> savePersonalRecord(PersonalRecordEntity pr) async {
    prs['${pr.exerciseId}_${pr.recordType}'] = pr;
  }

  @override
  Future<ProgressionSettingsEntity?> getProgressionSettings(
    String exerciseId,
  ) async => settings[exerciseId];

  @override
  Future<void> saveProgressionSettings(ProgressionSettingsEntity s) async {
    if (s.exerciseId != null) {
      settings[s.exerciseId!] = s;
    }
  }
}

void main() {
  group('ProgressiveOverloadService', () {
    late MockWorkoutRepository mockWorkoutRepo;
    late MockRoutineRepository mockRoutineRepo;
    late ProgressiveOverloadService service;

    const testExerciseId = '0a01618b-0e07-59b4-929d-5e49d63a2cb2';
    const testExerciseName = 'Incline Barbell Press';

    setUp(() {
      mockWorkoutRepo = MockWorkoutRepository();
      mockRoutineRepo = MockRoutineRepository();
      service = ProgressiveOverloadService(
        workoutRepository: mockWorkoutRepo,
        routineRepository: mockRoutineRepo,
      );
    });

    test(
      'Triggers weight increase when targetRepsMax is hit for consecutive sessions',
      () async {
        // 2 consecutive sessions of 3 sets x 12 reps @ 60kg
        final now = DateTime.now();
        final workout1 = WorkoutEntity(
          id: 'w1',
          title: 'Push Day 1',
          startedAt: now.subtract(const Duration(days: 4)),
          completedAt: now.subtract(const Duration(days: 4, hours: -1)),
          status: 'completed',
          durationSeconds: 3600,
          updatedAt: now,
          exercises: [
            WorkoutExerciseEntity(
              id: 'we1',
              workoutId: 'w1',
              exerciseId: testExerciseId,
              exerciseName: testExerciseName,
              category: 'Strength',
              orderIndex: 0,
              sets: [
                const WorkoutSetEntity(
                  id: 's1',
                  workoutExerciseId: 'we1',
                  setNumber: 1,
                  reps: 12,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
                const WorkoutSetEntity(
                  id: 's2',
                  workoutExerciseId: 'we1',
                  setNumber: 2,
                  reps: 12,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
                const WorkoutSetEntity(
                  id: 's3',
                  workoutExerciseId: 'we1',
                  setNumber: 3,
                  reps: 12,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );

        final workout2 = WorkoutEntity(
          id: 'w2',
          title: 'Push Day 2',
          startedAt: now.subtract(const Duration(days: 1)),
          completedAt: now.subtract(const Duration(days: 1, hours: -1)),
          status: 'completed',
          durationSeconds: 3600,
          updatedAt: now,
          exercises: [
            WorkoutExerciseEntity(
              id: 'we2',
              workoutId: 'w2',
              exerciseId: testExerciseId,
              exerciseName: testExerciseName,
              category: 'Strength',
              orderIndex: 0,
              sets: [
                const WorkoutSetEntity(
                  id: 's4',
                  workoutExerciseId: 'we2',
                  setNumber: 1,
                  reps: 12,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
                const WorkoutSetEntity(
                  id: 's5',
                  workoutExerciseId: 'we2',
                  setNumber: 2,
                  reps: 12,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
                const WorkoutSetEntity(
                  id: 's6',
                  workoutExerciseId: 'we2',
                  setNumber: 3,
                  reps: 12,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );

        mockWorkoutRepo.mockWorkouts = [workout2, workout1];

        final rec = await service.evaluateExerciseProgression(
          exerciseId: testExerciseId,
          exerciseName: testExerciseName,
        );

        expect(rec, isNotNull);
        expect(rec!.strategy, equals('double_progression_increase'));
        expect(rec.currentWeightKg, equals(60.0));
        expect(rec.suggestedWeightKg, equals(62.5));
        expect(rec.targetRepsMin, equals(8));
        expect(rec.status, equals('pending'));
        expect(rec.rationale, contains('Progress load by +2.5kg'));
      },
    );

    test(
      'Excludes warmup sets and skipped sets from progression calculation',
      () async {
        final now = DateTime.now();
        final workout = WorkoutEntity(
          id: 'w1',
          title: 'Push Day',
          startedAt: now,
          completedAt: now,
          status: 'completed',
          durationSeconds: 3600,
          updatedAt: now,
          exercises: [
            WorkoutExerciseEntity(
              id: 'we1',
              workoutId: 'w1',
              exerciseId: testExerciseId,
              exerciseName: testExerciseName,
              category: 'Strength',
              orderIndex: 0,
              sets: [
                // Warmup set should not trigger load increase
                const WorkoutSetEntity(
                  id: 's1',
                  workoutExerciseId: 'we1',
                  setNumber: 1,
                  reps: 15,
                  weightKg: 20.0,
                  type: 'warmup',
                  isCompleted: true,
                ),
                // Working sets with 10 reps (below 12)
                const WorkoutSetEntity(
                  id: 's2',
                  workoutExerciseId: 'we1',
                  setNumber: 2,
                  reps: 10,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
                const WorkoutSetEntity(
                  id: 's3',
                  workoutExerciseId: 'we1',
                  setNumber: 3,
                  reps: 10,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
                const WorkoutSetEntity(
                  id: 's4',
                  workoutExerciseId: 'we1',
                  setNumber: 4,
                  reps: 10,
                  weightKg: 60.0,
                  isCompleted: true,
                ),
                // Skipped set
                const WorkoutSetEntity(
                  id: 's5',
                  workoutExerciseId: 'we1',
                  setNumber: 5,
                  reps: 0,
                  weightKg: 60.0,
                  isSkipped: true,
                ),
              ],
            ),
          ],
        );

        mockWorkoutRepo.mockWorkouts = [workout];

        final rec = await service.evaluateExerciseProgression(
          exerciseId: testExerciseId,
          exerciseName: testExerciseName,
        );

        expect(rec, isNotNull);
        expect(rec!.strategy, equals('rep_progression'));
        expect(rec.currentWeightKg, equals(60.0));
        expect(rec.suggestedWeightKg, equals(60.0)); // No load increase yet
      },
    );

    test(
      'Triggers strategic deload when athlete misses targetRepsMin for 3 consecutive sessions',
      () async {
        final now = DateTime.now();
        List<WorkoutEntity> missedWorkouts = [];

        for (int i = 0; i < 3; i++) {
          missedWorkouts.add(
            WorkoutEntity(
              id: 'w_missed_$i',
              title: 'Push Day',
              startedAt: now.subtract(Duration(days: (3 - i) * 3)),
              completedAt: now.subtract(Duration(days: (3 - i) * 3)),
              status: 'completed',
              durationSeconds: 3600,
              updatedAt: now,
              exercises: [
                WorkoutExerciseEntity(
                  id: 'we_m_$i',
                  workoutId: 'w_missed_$i',
                  exerciseId: testExerciseId,
                  exerciseName: testExerciseName,
                  category: 'Strength',
                  orderIndex: 0,
                  sets: [
                    const WorkoutSetEntity(
                      id: 's1',
                      workoutExerciseId: 'we_m',
                      setNumber: 1,
                      reps: 6,
                      weightKg: 100.0,
                      isCompleted: true,
                    ),
                    const WorkoutSetEntity(
                      id: 's2',
                      workoutExerciseId: 'we_m',
                      setNumber: 2,
                      reps: 5,
                      weightKg: 100.0,
                      isCompleted: true,
                    ),
                    const WorkoutSetEntity(
                      id: 's3',
                      workoutExerciseId: 'we_m',
                      setNumber: 3,
                      reps: 4,
                      weightKg: 100.0,
                      isCompleted: true,
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        mockWorkoutRepo.mockWorkouts = missedWorkouts.reversed.toList();

        final rec = await service.evaluateExerciseProgression(
          exerciseId: testExerciseId,
          exerciseName: testExerciseName,
        );

        expect(rec, isNotNull);
        expect(rec!.strategy, equals('deload'));
        expect(rec.currentWeightKg, equals(100.0));
        expect(rec.suggestedWeightKg, equals(90.0)); // 10% deload of 100kg
        expect(rec.rationale, contains('strategic deload'));
      },
    );

    test(
      'Epley 1RM formula calculation matches standard exercise science model',
      () {
        // 100kg for 5 reps -> 100 * (1 + 5/30) = 116.666...
        final est1 = ProgressiveOverloadService.calculateEstimated1Rm(100, 5);
        expect(est1, closeTo(116.67, 0.01));

        // 100kg for 1 rep -> 100kg
        final est2 = ProgressiveOverloadService.calculateEstimated1Rm(100, 1);
        expect(est2, equals(100.0));

        // 80kg for 10 reps -> 80 * (1 + 10/30) = 106.67
        final est3 = ProgressiveOverloadService.calculateEstimated1Rm(80, 10);
        expect(est3, closeTo(106.67, 0.01));
      },
    );

    test(
      'checkAndRecordPRs identifies max weight, estimated 1RM and set volume PRs',
      () async {
        final now = DateTime.now();
        final workout = WorkoutEntity(
          id: 'w_pr_test',
          title: 'Bench PR Test',
          startedAt: now,
          completedAt: now,
          status: 'completed',
          durationSeconds: 3000,
          updatedAt: now,
          exercises: [
            WorkoutExerciseEntity(
              id: 'we_pr',
              workoutId: 'w_pr_test',
              exerciseId: testExerciseId,
              exerciseName: testExerciseName,
              category: 'Strength',
              orderIndex: 0,
              sets: [
                const WorkoutSetEntity(
                  id: 'set_pr_1',
                  workoutExerciseId: 'we_pr',
                  setNumber: 1,
                  reps: 5,
                  weightKg: 100.0,
                  isCompleted: true,
                ),
              ],
            ),
          ],
        );

        final prs = await service.checkAndRecordPRs(workout: workout);

        expect(prs.length, equals(3));
        final weightPr = prs.firstWhere((p) => p.recordType == 'max_weight');
        expect(weightPr.value, equals(100.0));

        final oneRmPr = prs.firstWhere((p) => p.recordType == 'estimated_1rm');
        expect(oneRmPr.value, closeTo(116.7, 0.1));

        final volPr = prs.firstWhere((p) => p.recordType == 'max_volume_set');
        expect(volPr.value, equals(500.0)); // 100 * 5
      },
    );

    test('Evaluates timed isometric holds with duration increase', () async {
      const plankId = '9825cdb8-81c9-5273-9bac-039ab80b8f1f';
      const plankName = 'Plank';
      final now = DateTime.now();

      final workout = WorkoutEntity(
        id: 'w_plank',
        title: 'Core Workout',
        startedAt: now,
        completedAt: now,
        status: 'completed',
        durationSeconds: 1200,
        updatedAt: now,
        exercises: [
          const WorkoutExerciseEntity(
            id: 'we_plank',
            workoutId: 'w_plank',
            exerciseId: plankId,
            exerciseName: plankName,
            category: 'Core',
            orderIndex: 0,
            sets: [
              WorkoutSetEntity(
                id: 's_plank_1',
                workoutExerciseId: 'we_plank',
                setNumber: 1,
                reps: 1,
                weightKg: 0,
                durationSeconds: 60,
                isCompleted: true,
              ),
            ],
          ),
        ],
      );

      mockWorkoutRepo.mockWorkouts = [workout];

      final rec = await service.evaluateExerciseProgression(
        exerciseId: plankId,
        exerciseName: plankName,
      );

      expect(rec, isNotNull);
      expect(rec!.strategy, equals('duration_progression'));
      expect(rec.rationale, contains('increase duration to 70s'));
    });
  });
}
