import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/steps_repository.dart';
import 'package:fit_host/features/steps/data/step_service.dart';

void main() {
  group('Part 3: StepService Lifecycle, Rollover & Reboot Tests', () {
    late AppDatabase memoryDb;
    late LocalStepsRepository repo;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      repo = LocalStepsRepository(memoryDb, userId: 'test_athlete_1');
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('Walk 50 steps -> counter increments and persists to Drift', () async {
      DateTime mockTime = DateTime(2026, 10, 16, 10, 0, 0);
      final service = StepService(
        repository: repo,
        clock: () => mockTime,
        strideLengthCm: 70.0,
        targetSteps: 10000,
      );
      await service.init();

      // Walk 50 steps
      await service.onSensorReading(1000); // Baseline sensor reading
      await service.onSensorReading(1050); // Walked 50 steps

      expect(service.todaySteps, equals(50));

      final persistedSteps = await repo.getDailySteps(mockTime);
      expect(persistedSteps, equals(50));

      final record = await repo.getDailyStepRecord(mockTime);
      expect(record, isNotNull);
      expect(record!.steps, equals(50));
      // distance: 50 * 70 / 100000 = 0.035 km = 35 m
      expect(record.distanceKm, closeTo(0.035, 0.001));

      service.dispose();
    });

    test('Simulate midnight rollover (mock clock) -> yesterday row sealed, new row starts at 0', () async {
      DateTime mockTime = DateTime(2026, 10, 16, 23, 50, 0); // 11:50 PM Day 1
      final service = StepService(
        repository: repo,
        clock: () => mockTime,
        strideLengthCm: 70.0,
      );
      await service.init();

      // Day 1: accumulate 4,500 steps
      await service.onSensorReading(5000);
      await service.onSensorReading(9500); // +4500 steps
      expect(service.todaySteps, equals(4500));

      // Advance mock clock past midnight to Day 2 (00:05 AM)
      mockTime = DateTime(2026, 10, 17, 0, 5, 0);

      // Sensor reading continues at 9500 (or slight increase to 9510)
      await service.onSensorReading(9510);

      // New day starts at 0 (or +10 steps taken after midnight)
      expect(service.todaySteps, equals(10));
      expect(service.currentDate.day, equals(17));

      // Verify yesterday's row (Oct 16) is sealed at 4500 steps in SQLite
      final yesterdayRecord =
          await repo.getDailyStepRecord(DateTime(2026, 10, 16));
      expect(yesterdayRecord, isNotNull);
      expect(yesterdayRecord!.steps, equals(4500));

      // Verify today's row (Oct 17) starts fresh
      final todayRecord =
          await repo.getDailyStepRecord(DateTime(2026, 10, 17));
      expect(todayRecord, isNotNull);
      expect(todayRecord!.steps, equals(10));

      service.dispose();
    });

    test('Device reboot handling -> sensor counter resets below base without losing accumulated steps', () async {
      DateTime mockTime = DateTime(2026, 10, 16, 14, 0, 0);
      final service = StepService(
        repository: repo,
        clock: () => mockTime,
        strideLengthCm: 70.0,
      );
      await service.init();

      // Pre-reboot: sensor is at 10,000, athlete walks 2,000 steps
      await service.onSensorReading(10000);
      await service.onSensorReading(12000);
      expect(service.todaySteps, equals(2000));

      // Phone reboots! Android SensorManager step counter drops to 15 steps
      await service.onSensorReading(15);
      // Steps should NOT drop or become negative; accumulated 2000 steps are preserved!
      expect(service.todaySteps, equals(2000));

      // Athlete takes another 35 steps after reboot (sensor now at 50)
      await service.onSensorReading(50);
      expect(service.todaySteps, equals(2035));

      service.dispose();
    });

    test('Offline / Airplane mode -> sensor counting is local and persists without network', () async {
      // In offline mode (airplane mode), pedometer sensor continues counting locally into Drift SQLite
      DateTime mockTime = DateTime(2026, 10, 16, 16, 0, 0);
      final service = StepService(
        repository: repo,
        clock: () => mockTime,
        strideLengthCm: 70.0,
      );
      await service.init();

      await service.addSteps(300);
      expect(service.todaySteps, equals(300));

      final persisted = await repo.getDailySteps(mockTime);
      expect(persisted, equals(300));

      service.dispose();
    });

    test('Guest vs Signed-in user 7-day history gating', () async {
      final guestRepo = LocalStepsRepository(memoryDb, userId: 'guest');
      final guestHistory = await guestRepo.getStepsHistory(days: 7);
      // Guests history is restricted to 1 entry (today only)
      expect(guestHistory.length, equals(1));

      final authRepo = LocalStepsRepository(memoryDb, userId: 'auth_uid_101');
      final authHistory = await authRepo.getStepsHistory(days: 7);
      // Signed-in athletes get all 7 days of movement trends
      expect(authHistory.length, equals(7));
    });
  });
}
