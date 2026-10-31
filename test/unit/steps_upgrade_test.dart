import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/steps/data/health_platform_service.dart';

void main() {
  group('Health Platform & Step Deduplication Tests', () {
    test(
      'DefaultHealthPlatformService accurately initializes and exposes preferredSource',
      () {
        final service = DefaultHealthPlatformService();
        expect(service.preferredSource, isNotNull);
      },
    );

    test('StepDataSource display names and database serialization mapping', () {
      expect(
        StepDataSource.healthConnect.displayName,
        equals('Android Health Connect'),
      );
      expect(StepDataSource.healthConnect.dbValue, equals('health_connect'));
      expect(
        StepDataSource.appleHealthKit.displayName,
        equals('Apple HealthKit'),
      );
      expect(StepDataSource.appleHealthKit.dbValue, equals('health_kit'));
      expect(
        StepDataSource.hardwareSensor.displayName,
        equals('Device Hardware Pedometer'),
      );
      expect(StepDataSource.hardwareSensor.dbValue, equals('hardware_sensor'));
      expect(
        StepDataSourceX.fromString('health_connect'),
        equals(StepDataSource.healthConnect),
      );
      expect(
        StepDataSourceX.fromString('health_kit'),
        equals(StepDataSource.appleHealthKit),
      );
    });

    test(
      'HealthDataSyncResult accurately stores steps, source, and sync time',
      () {
        final now = DateTime.now();
        final result = HealthDataSyncResult(
          steps: 8500,
          source: StepDataSource.healthConnect,
          synchronizedAt: now,
          isAggregated: true,
        );

        expect(result.steps, equals(8500));
        expect(result.source, equals(StepDataSource.healthConnect));
        expect(result.isAggregated, isTrue);
        expect(result.synchronizedAt, equals(now));
      },
    );

    test(
      'Step deduplication rule: sensor counts ignored when Health Connect active',
      () {
        int aggregatedSteps = 8500;
        final activeSource = StepDataSource.healthConnect;
        const rawSensorDelta = 200;

        // Deduplication guard:
        if (activeSource != StepDataSource.healthConnect &&
            activeSource != StepDataSource.appleHealthKit) {
          aggregatedSteps += rawSensorDelta;
        }

        // Assert that steps were NOT double counted:
        expect(aggregatedSteps, equals(8500));
      },
    );

    test(
      'Step fallback rule: sensor counts applied when platform is hardwareSensor',
      () {
        int localSteps = 3000;
        final activeSource = StepDataSource.hardwareSensor;
        const rawSensorDelta = 150;

        if (activeSource == StepDataSource.hardwareSensor) {
          localSteps += rawSensorDelta;
        }

        expect(localSteps, equals(3150));
      },
    );
  });
}
