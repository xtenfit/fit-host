import '../models/workout_models.dart';

abstract class WorkoutRepository {
  Stream<List<WorkoutEntity>> watchWorkouts();
  Future<List<WorkoutEntity>> getWorkouts();
  Future<WorkoutEntity?> getWorkoutById(String id);
  Future<void> saveWorkout(WorkoutEntity workout);
  Future<void> deleteWorkout(String id);
  Future<List<ExerciseEntity>> getExercises({
    String? query,
    String? category,
    String? genderFilter,
  });
  Future<ExerciseEntity?> getExerciseById(String id);
  Future<void> seedDefaultExercises();
}
