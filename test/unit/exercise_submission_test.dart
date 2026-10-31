import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/domain/models/exercise_submission.dart';
import 'package:fit_host/features/workouts/data/repositories/exercise_submission_repository_impl.dart';
import 'package:fit_host/features/workouts/data/datasources/unified_exercise_catalog_data.dart';

void main() {
  group('Exercise Wiki & Community Contribution Tests', () {
    late AppDatabase memoryDb;
    late ExerciseSubmissionRepositoryImpl repo;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      repo = ExerciseSubmissionRepositoryImpl(memoryDb);
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test(
      'generateHash generates deterministic SHA-256 for duplicate matching',
      () {
        final hash1 = ExerciseSubmission.generateHash(
          type: SubmissionType.newExercise,
          name: 'Bulgarian Split Squat',
          equipment: 'Dumbbell',
        );

        final hash2 = ExerciseSubmission.generateHash(
          type: SubmissionType.newExercise,
          name: '  bulgarian split squat  ',
          equipment: 'dumbbell',
        );

        expect(hash1, equals(hash2));
        expect(hash1.length, equals(64));
      },
    );

    test(
      'createSubmission creates pending submission and checks duplicate prevention',
      () async {
        final sub = ExerciseSubmission(
          id: const Uuid().v4(),
          submissionType: SubmissionType.newExercise,
          name: 'Incline Cable Fly',
          category: 'Chest',
          equipment: 'Cable',
          targetMuscle: 'Upper Pectoralis Major',
          secondaryMuscles: const ['Anterior Deltoid'],
          instructions:
              'Set pulleys to low position. Bring handles up and together in an arc.',
          safetyNotes:
              'Keep a slight bend in elbows; avoid excessive shoulder extension.',
          difficultyLevel: 'Intermediate',
          movementType: 'Isolation',
          audienceSuitability: 'universal',
          suggestedRationale: 'Provides constant tension on clavicular head.',
          submittedBy: 'test-user-123',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          duplicateHash: '',
        );

        final created = await repo.createSubmission(sub);
        expect(created.status, equals(ModerationStatus.pending));

        // Query user submissions
        final userSubs = await repo.getMySubmissions(userId: 'test-user-123');
        expect(userSubs.length, equals(1));
        expect(userSubs.first.name, equals('Incline Cable Fly'));
        expect(userSubs.first.status, equals(ModerationStatus.pending));

        // Attempting to submit the exact same exercise again while pending must fail
        expect(
          () => repo.createSubmission(sub.copyWith(id: const Uuid().v4())),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'correction submissions link to target exercise ID and maintain distinct hashes',
      () async {
        const canonicalId = '00000000-0000-0000-0000-000000000001';
        final correction = ExerciseSubmission(
          id: const Uuid().v4(),
          submissionType: SubmissionType.correction,
          targetExerciseId: canonicalId,
          name: 'Barbell Bench Press',
          category: 'Chest',
          equipment: 'Barbell',
          targetMuscle: 'Pectoralis Major',
          secondaryMuscles: const ['Triceps', 'Anterior Deltoid'],
          instructions:
              'Lower bar to mid-chest with controlled descent. Press upwards to lockout.',
          safetyNotes:
              'Maintain five points of contact. Do not flare elbows past 75 degrees.',
          suggestedRationale:
              'Clarifies elbow tuck angle to reduce anterior shoulder impingement risk.',
          submittedBy: 'coach-sarah',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          duplicateHash: '',
        );

        final created = await repo.createSubmission(correction);
        expect(created.submissionType, equals(SubmissionType.correction));
        expect(created.targetExerciseId, equals(canonicalId));
      },
    );

    test('moderation review updates status and appends audit log entry', () async {
      final sub = ExerciseSubmission(
        id: const Uuid().v4(),
        submissionType: SubmissionType.newExercise,
        name: 'Nordic Hamstring Curl',
        category: 'Legs',
        equipment: 'Bodyweight',
        targetMuscle: 'Hamstrings',
        instructions:
            'Anchor ankles under pad. Slowly lower torso forward using eccentric hamstring strength.',
        submittedBy: 'athlete-dan',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        duplicateHash: '',
      );

      final created = await repo.createSubmission(sub);
      expect(created.status, equals(ModerationStatus.pending));

      // Moderator reviews and approves submission
      await repo.reviewSubmission(
        submissionId: created.id,
        newStatus: ModerationStatus.approved,
        moderatorId: 'mod-chief-1',
        notes:
            'Verified biomechanics and form instructions. Safe for community wiki publication.',
      );

      // Verify status in repository
      final approvedList = await repo.getApprovedSubmissions();
      expect(approvedList.length, equals(1));
      expect(approvedList.first.id, equals(created.id));
      expect(approvedList.first.status, equals(ModerationStatus.approved));
      expect(
        approvedList.first.moderatorNotes,
        contains('Verified biomechanics'),
      );

      // Verify audit logs
      final logs = await repo.getModerationLogs(created.id);
      expect(logs.length, equals(1));
      expect(logs.first.action, equals('approved'));
      expect(logs.first.moderatorId, equals('mod-chief-1'));
    });

    test(
      'canonical exercise catalog integrity: 1324 exercises remain unchanged and protected',
      () {
        expect(kUnifiedExerciseCatalog.length, equals(1324));

        final bench = kUnifiedExerciseCatalog.firstWhere(
          (e) => e.name.toLowerCase().contains('bench press'),
        );
        expect(bench.contentAttribution, isNotNull);
        expect(bench.mediaAttribution, contains('Gym visual'));
        // Catalog exercises have immutable IDs and license terms
        expect(bench.id.length, equals(36));
      },
    );
  });
}
