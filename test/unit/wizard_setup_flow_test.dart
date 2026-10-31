import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/features/profile/presentation/screens/fitness_setup_wizard_screen.dart';
import 'package:fit_host/features/home/presentation/widgets/setup_reminder_banner.dart';
import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:fit_host/features/profile/domain/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('FitnessSetupWizardScreen UI & Flow Tests', () {
    testWidgets(
      'Wizard renders header with back, step counter pill, skip, and close button',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FitnessSetupWizardScreen(initialScreen: 0),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert header elements
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.textContaining('Step 1 of 20'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping exit/close button triggers Condition 3 notifications and records wizard skip',
      (tester) async {
        final notifService = NotificationService.instance;
        await notifService.cancelAllNotifications();

        final gateService = StartupGateService();
        expect(await gateService.hasSkippedWizard(), isFalse);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FitnessSetupWizardScreen(initialScreen: 0),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap close button in header
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Verify immediate skip notification was registered
        final notifications = notifService.scheduledNotifications;
        expect(
          notifications.any((n) => n.id == 'setup_wizard_skip_reminder'),
          isTrue,
          reason:
              'Immediate skip reminder notification should be triggered upon wizard exit',
        );
        expect(
          notifications.any((n) => n.id == 'setup_wizard_reminder_followup'),
          isTrue,
          reason:
              'Followup reminder notification should be scheduled upon wizard exit',
        );

        // Verify gate marked wizard as skipped so user is not trapped
        expect(await gateService.hasSkippedWizard(), isTrue);
      },
    );

    testWidgets(
      'SetupReminderBanner displays on HomeScreen when profile setup is incomplete',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileProvider.overrideWith(_IncompleteProfileNotifier.new),
            ],
            child: const MaterialApp(
              home: Scaffold(body: SetupReminderBanner(isDark: true)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('SETUP INCOMPLETE'), findsOneWidget);
        expect(find.text('Complete Your Setup Wizard'), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      },
    );

    testWidgets('SetupReminderBanner hides when profile setup is completed', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(_CompletedProfileNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SetupReminderBanner(isDark: true)),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('SETUP INCOMPLETE'), findsNothing);
      expect(find.text('Complete Your Setup Wizard'), findsNothing);
    });
  });
}

class _IncompleteProfileNotifier extends UserProfileNotifier {
  @override
  UserProfile build() {
    return UserProfile.defaultGuest().copyWith(isProfileSetupCompleted: false);
  }
}

class _CompletedProfileNotifier extends UserProfileNotifier {
  @override
  UserProfile build() {
    return UserProfile.defaultGuest().copyWith(isProfileSetupCompleted: true);
  }
}
