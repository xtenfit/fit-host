import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fit_host/core/services/notification_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Native Android Alarm System On-Device Verification', () {
    late NotificationService notificationService;

    setUp(() async {
      notificationService = NotificationService();
      await notificationService.initialize();
    });

    testWidgets(
      'Verify Exact Alarm Permission and Scheduling on Real Android OS',
      (WidgetTester tester) async {
        // 1. Check exact alarm permission capability on Android
        final canExact = await notificationService.canScheduleExactAlarms();
        debugPrint('DEVICE VERIFICATION: canScheduleExactAlarms = $canExact');
        expect(canExact, isTrue);

        // 2. Schedule a real Android OS Alarm
        final scheduledTime = DateTime.now().add(const Duration(seconds: 45));
        await notificationService.scheduleAlarm(
          id: 'integration-test-alarm-1',
          title: 'Fit Host Real Android Alarm',
          body: 'Testing exact alarm firing on Android platform',
          scheduledTime: scheduledTime,
          channel: NotificationChannelType.workouts,
          sound: true,
          vibration: true,
        );
        debugPrint(
          'DEVICE VERIFICATION: Successfully scheduled exact alarm for $scheduledTime',
        );

        // 3. Snooze verification
        await notificationService.snoozeAlarmDirect(
          id: 'integration-test-alarm-1',
          title: 'Fit Host Real Android Alarm',
          body: 'Testing exact alarm firing on Android platform',
          snoozeMinutes: 5,
          channelName: 'workouts',
        );
        debugPrint(
          'DEVICE VERIFICATION: Successfully snoozed alarm for 5 minutes',
        );

        // 4. Cancel verification
        await notificationService.cancelNotification(
          'integration-test-alarm-1',
        );
        debugPrint('DEVICE VERIFICATION: Cleaned up and cancelled test alarm');
      },
    );
  });
}
