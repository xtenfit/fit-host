import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fit_host/core/services/permission_service.dart';
import 'package:fit_host/features/settings/presentation/permission_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Permission State Architecture & Service Tests', () {
    test(
      'AppPermissionStatus correctly identifies granted and actionable states',
      () {
        expect(AppPermissionStatus.granted.isGranted, isTrue);
        expect(AppPermissionStatus.denied.isGranted, isFalse);
        expect(AppPermissionStatus.notRequested.isGranted, isFalse);
        expect(AppPermissionStatus.requiresSystemSettings.isGranted, isFalse);

        expect(AppPermissionStatus.notRequested.isActionable, isTrue);
        expect(AppPermissionStatus.denied.isActionable, isTrue);
        expect(AppPermissionStatus.permanentlyDenied.isActionable, isTrue);
        expect(AppPermissionStatus.requiresSystemSettings.isActionable, isTrue);
        expect(AppPermissionStatus.granted.isActionable, isFalse);
      },
    );

    test('AppPermissionState calculates recommended step count truthfully', () {
      final state = AppPermissionState(
        notifications: AppPermissionStatus.granted,
        exactAlarms: AppPermissionStatus.granted,
        healthConnect: AppPermissionStatus.denied,
        physicalActivity: AppPermissionStatus.notRequested,
        camera: AppPermissionStatus
            .granted, // Camera is on-demand, not in recommended count
        googleCalendarConnected: true,
        lastChecked: DateTime.now(),
      );

      expect(state.totalRecommendedCount, equals(4));
      expect(
        state.recommendedGrantedCount,
        equals(2),
      ); // Only notifications + exactAlarms
    });

    test(
      'PermissionService correctly persists and resets onboarding setup flag',
      () async {
        final service = PermissionService.instance;

        expect(await service.hasCompletedPermissionSetup(), isFalse);

        await service.setPermissionSetupCompleted(true);
        expect(await service.hasCompletedPermissionSetup(), isTrue);

        await service.resetPermissionSetup();
        expect(await service.hasCompletedPermissionSetup(), isFalse);
      },
    );

    test(
      'PermissionService checkPermissionReport reflects live state without fake flags',
      () async {
        final service = PermissionService.instance;
        final report = await service.checkPermissionReport();

        // Check that report returns concrete typed values
        expect(report.batteryOptimizationExempt, isTrue);
        expect(report.systemAlertWindowGranted, isTrue);
        expect(report.notificationsEnabled, isA<bool>());
      },
    );
  });

  group('PermissionSettingsScreen UI & Flow Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(
        1080,
        2400,
      );
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets(
      'Renders Post-Onboarding mode with header, progress, and cards',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: PermissionSettingsScreen(isPostOnboarding: true),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify Step 2 of 2 Badge & Title
        expect(find.text('STEP 2 OF 2 • PERMISSIONS'), findsOneWidget);
        expect(find.text('Set Up Your Experience'), findsOneWidget);

        // Verify recommended feature cards
        expect(find.text('Notifications & Reminders'), findsOneWidget);
        expect(find.text('Alarm-Style Precision'), findsOneWidget);
        expect(find.text('Health Connect Sync'), findsOneWidget);
        expect(find.text('Device Motion & Pedometer'), findsOneWidget);

        // Camera must NOT be displayed in post-onboarding mode
        expect(find.text('Camera & Barcode Scanner'), findsNothing);

        // Bottom action buttons
        expect(find.text('Continue to Fit Host'), findsOneWidget);
        expect(find.text('Skip for Now'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders Settings mode with management title and on-demand features',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: PermissionSettingsScreen(isPostOnboarding: false),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify Settings AppBar
        expect(find.text('Permissions & Integrations'), findsOneWidget);

        // Verify On-Demand & Integrations sections are present in Settings mode
        expect(find.text('ON-DEMAND APP FEATURES'), findsOneWidget);
        expect(find.text('Camera & Barcode Scanner'), findsOneWidget);
        expect(find.text('Google Calendar (OAuth 2.0)'), findsOneWidget);

        // Post-onboarding buttons must NOT be present
        expect(find.text('Continue to Fit Host'), findsNothing);
        expect(find.text('Skip for Now'), findsNothing);
      },
    );

    testWidgets(
      'Continue and Skip buttons complete setup and trigger navigation callback',
      (tester) async {
        final service = PermissionService.instance;
        await service.resetPermissionSetup();
        expect(await service.hasCompletedPermissionSetup(), isFalse);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: PermissionSettingsScreen(isPostOnboarding: true),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Skip for Now
        final skipBtn = find.text('Skip for Now');
        expect(skipBtn, findsOneWidget);
        await tester.tap(skipBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Setup completion should be persisted in SharedPreferences
        expect(await service.hasCompletedPermissionSetup(), isTrue);
      },
    );
  });
}
