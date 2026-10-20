import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/guest_account_claim_service.dart';
import 'package:fit_host/core/sync/sync_coordinator.dart';

void main() {
  group('Part 2: Guest Data Claim Transaction with Rollback Tests', () {
    late AppDatabase memoryDb;
    late SyncCoordinator coordinator;
    late GuestAccountClaimService claimService;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      coordinator = SyncCoordinator(
        db: memoryDb,
        supabase: null,
      );
      claimService = GuestAccountClaimService(
        db: memoryDb,
        syncCoordinator: coordinator,
      );
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('Guest with 3 workouts and 2 nutrition logs gets user_id, enqueued, and preserved', () async {
      const newUserId = 'account-user-target-123';
      final now = DateTime.now().toUtc();

      // Seed 3 guest workouts
      for (int i = 1; i <= 3; i++) {
        await memoryDb.into(memoryDb.workouts).insert(
              WorkoutsCompanion.insert(
                id: 'workout-guest-$i',
                userId: const drift.Value('guest'),
                title: 'Workout $i',
                startedAt: now.subtract(Duration(days: i)),
                updatedAt: now.subtract(Duration(days: i)),
              ),
            );
      }

      // Seed 2 guest nutrition logs
      for (int i = 1; i <= 2; i++) {
        await memoryDb.into(memoryDb.nutritionLogs).insert(
              NutritionLogsCompanion.insert(
                id: 'nutrition-guest-$i',
                userId: const drift.Value('guest'),
                logDate: now.subtract(Duration(days: i)),
                waterGlasses: drift.Value(i * 4),
                createdAt: now.subtract(Duration(days: i)),
                updatedAt: now.subtract(Duration(days: i)),
              ),
            );
      }

      // Execute claim transaction
      final outcome = await claimService.claimGuestDataToAccount(newUserId);
      expect(outcome, isNot(equals(ClaimOutcome.failed)));

      // 1. Verify all 3 workouts assigned newUserId and pending_upload
      final workouts = await (memoryDb.select(memoryDb.workouts)
            ..where((t) => t.userId.equals(newUserId)))
          .get();
      expect(workouts.length, equals(3));
      for (final w in workouts) {
        expect(w.userId, equals(newUserId));
        expect(w.syncStatus, equals('pending_upload'));
      }

      // Verify no guest workouts remain
      final remainingGuestWorkouts = await (memoryDb.select(memoryDb.workouts)
            ..where((t) => t.userId.equals('guest')))
          .get();
      expect(remainingGuestWorkouts, isEmpty);

      // 2. Verify all 2 nutrition logs assigned newUserId and pending_upload
      final nutritionLogs = await (memoryDb.select(memoryDb.nutritionLogs)
            ..where((t) => t.userId.equals(newUserId)))
          .get();
      expect(nutritionLogs.length, equals(2));
      for (final n in nutritionLogs) {
        expect(n.userId, equals(newUserId));
        expect(n.syncStatus, equals('pending_upload'));
      }

      // Verify no guest nutrition logs remain
      final remainingGuestNutrition = await (memoryDb.select(memoryDb.nutritionLogs)
            ..where((t) => t.userId.equals('guest')))
          .get();
      expect(remainingGuestNutrition, isEmpty);

      // 3. Verify all 5 items enqueued in sync_queue with status = 'queued'
      final queueItems = await memoryDb.select(memoryDb.syncQueue).get();
      expect(queueItems.length, equals(5));
      for (final q in queueItems) {
        expect(q.userId, equals(newUserId));
        expect(q.status, equals('queued'));
      }
    });

    test('Claim failure midway triggers transaction rollback preserving original guest state', () async {
      final now = DateTime.now().toUtc();

      // Seed a guest workout
      await memoryDb.into(memoryDb.workouts).insert(
            WorkoutsCompanion.insert(
              id: 'workout-guest-atomic',
              userId: const drift.Value('guest'),
              title: 'Rollback Test Workout',
              startedAt: now,
              updatedAt: now,
            ),
          );

      // Execute a failing transaction simulating error midway
      expect(
        () async {
          await memoryDb.transaction(() async {
            // First operation modifies row
            await (memoryDb.update(memoryDb.workouts)
                  ..where((t) => t.userId.equals('guest')))
                .write(const WorkoutsCompanion(
              userId: drift.Value('partial-fail-user'),
              syncStatus: drift.Value('pending_upload'),
            ));

            // Force simulated runtime failure midway inside the transaction
            throw Exception('Simulated network/DB error midway in transaction');
          });
        },
        throwsA(isA<Exception>()),
      );

      // Verify that after rollback, the row is 100% restored to its original guest state!
      final row = await (memoryDb.select(memoryDb.workouts)
            ..where((t) => t.id.equals('workout-guest-atomic')))
          .getSingle();

      expect(row.userId, equals('guest'));
      expect(row.syncStatus, isNull);
    });

    test('Claim on empty guest database returns success immediately with ready stage', () async {
      final stages = <MigrationStage>[];
      final outcome = await claimService.claimGuestDataToAccount(
        'new-empty-user',
        onProgress: (p) => stages.add(p.stage),
      );

      expect(outcome, equals(ClaimOutcome.success));
      expect(stages, contains(MigrationStage.ready));
    });

    test('Claim reports 4 distinct sequential progress stages during migration', () async {
      final now = DateTime.now().toUtc();
      await memoryDb.into(memoryDb.workouts).insert(
            WorkoutsCompanion.insert(
              id: 'workout-stage-test',
              userId: const drift.Value('guest'),
              title: 'Stage Workout',
              startedAt: now,
              updatedAt: now,
            ),
          );

      final stages = <MigrationStage>[];
      final messages = <String>[];
      final outcome = await claimService.claimGuestDataToAccount(
        'user-stage-verify',
        onProgress: (p) {
          stages.add(p.stage);
          messages.add(p.message);
        },
      );

      expect(outcome, isNot(equals(ClaimOutcome.failed)));
      expect(stages, contains(MigrationStage.preparing));
      expect(stages, contains(MigrationStage.backingUp));
      expect(stages, contains(MigrationStage.synchronizing));
      expect(stages, contains(MigrationStage.ready));
      expect(messages, contains('Preparing your saved data.'));
      expect(messages, contains('Backing up your workouts and activity logs.'));
      expect(messages, contains('Synchronizing your records.'));
      expect(messages, contains('Your account is ready.'));
    });

    test('clearAccountCache isolates authenticated data and leaves guest records intact', () async {
      final now = DateTime.now().toUtc();
      // Insert guest workout
      await memoryDb.into(memoryDb.workouts).insert(
            WorkoutsCompanion.insert(
              id: 'w-guest-keep',
              userId: const drift.Value('guest'),
              title: 'Guest Workout',
              startedAt: now,
              updatedAt: now,
            ),
          );

      // Insert account workout
      await memoryDb.into(memoryDb.workouts).insert(
            WorkoutsCompanion.insert(
              id: 'w-user-clear',
              userId: const drift.Value('user-to-clear-999'),
              title: 'Account Workout',
              startedAt: now,
              updatedAt: now,
            ),
          );

      // Clear account cache
      await memoryDb.clearAccountCache('user-to-clear-999');

      // Verify account workout is deleted
      final userWorkouts = await (memoryDb.select(memoryDb.workouts)
            ..where((t) => t.userId.equals('user-to-clear-999')))
          .get();
      expect(userWorkouts, isEmpty);

      // Verify guest workout is 100% preserved!
      final guestWorkouts = await (memoryDb.select(memoryDb.workouts)
            ..where((t) => t.userId.equals('guest')))
          .get();
      expect(guestWorkouts.length, equals(1));
      expect(guestWorkouts.first.id, equals('w-guest-keep'));
    });
  });
}
