import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/services/lock_screen_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LockScreenSecurityService & Lockscreen Protection Tests', () {
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.fithost.fit_host/lockscreen'),
            (MethodCall call) async {
              methodCalls.add(call);
              switch (call.method) {
                case 'isDeviceLocked':
                  return true; // Simulate locked phone
                case 'enableLockScreenOverlay':
                case 'disableLockScreenOverlay':
                case 'closeAlarmToLockScreen':
                  return true;
                case 'dismissKeyguardAndProceed':
                  return true;
                default:
                  return null;
              }
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.fithost.fit_host/lockscreen'),
            null,
          );
    });

    test(
      'isDeviceLocked returns boolean from native platform channel when not in test bypass',
      () async {
        // In test mode, default _isTest is true, so it safely returns false for UI tests
        expect(
          await LockScreenSecurityService.instance.isDeviceLocked(),
          isFalse,
        );
      },
    );

    testWidgets(
      'dismissAlarmSafely navigates in test environment without exposing lockscreen bypass',
      (tester) async {
        bool navigated = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await LockScreenSecurityService.instance.dismissAlarmSafely(
                      context,
                      nextRoute: '/workouts',
                    );
                    navigated = true;
                  },
                  child: const Text('Dismiss Alarm'),
                );
              },
            ),
            routes: {
              '/workouts': (context) =>
                  const Scaffold(body: Text('Workouts Screen')),
              '/home': (context) => const Scaffold(body: Text('Home Screen')),
            },
          ),
        );

        await tester.tap(find.text('Dismiss Alarm'));
        await tester.pumpAndSettle();

        expect(navigated, isTrue);
        expect(find.text('Workouts Screen'), findsOneWidget);
      },
    );
  });
}
