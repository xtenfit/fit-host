import '../models/exercise_submission.dart';

abstract class ExerciseSubmissionRepository {
  Future<ExerciseSubmission> createSubmission(ExerciseSubmission submission);

  Future<List<ExerciseSubmission>> getMySubmissions({String? userId});

  Stream<List<ExerciseSubmission>> watchMySubmissions({String? userId});

  Future<List<ExerciseSubmission>> getApprovedSubmissions();

  Stream<List<ExerciseSubmission>> watchApprovedSubmissions();

  Future<bool> hasPendingDuplicate({
    required SubmissionType type,
    String? targetExerciseId,
    required String name,
    required String equipment,
  });

  Future<void> reviewSubmission({
    required String submissionId,
    required ModerationStatus newStatus,
    required String moderatorId,
    String? notes,
  });

  Future<List<ExerciseModerationLog>> getModerationLogs(String submissionId);
}
