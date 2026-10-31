import '../models/workout_models.dart';

abstract class RoutineRepository {
  Stream<List<RoutineEntity>> watchRoutines({bool includeArchived = false});
  Future<List<RoutineEntity>> getRoutines({bool includeArchived = false});
  Future<RoutineEntity?> getRoutineById(String id);
  Future<void> saveRoutine(RoutineEntity routine);
  Future<void> deleteRoutine(String id);
  Future<RoutineEntity> duplicateRoutine(String routineId, {String? newName});
  Future<void> archiveRoutine(String routineId, {bool archive = true});
  Future<void> seedTemplateRoutines();

  // Personal Records
  Future<List<PersonalRecordEntity>> getPersonalRecords({String? exerciseId});
  Future<PersonalRecordEntity?> getPersonalRecord(
    String exerciseId,
    String recordType,
  );
  Future<void> savePersonalRecord(PersonalRecordEntity pr);

  // Progression Settings
  Future<ProgressionSettingsEntity?> getProgressionSettings(String exerciseId);
  Future<void> saveProgressionSettings(ProgressionSettingsEntity settings);
}
