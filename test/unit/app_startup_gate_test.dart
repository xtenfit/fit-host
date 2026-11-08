import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';
import 'package:fit_host/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Startup Gate & Setup Wizard Routing Lifecycle', () {
    test(
      '1st screen flow: fresh unauthenticated user is always routed to /auth-decision',
      () async {
        final service = StartupGateService();

        expect(await service.isFirstLaunchCompleted(), isFalse);
        expect(await service.isAuthDecisionMade(), isFalse);
        expect(await service.isGuestOnboardingCompleted(), isFalse);

        final route = await service.determineInitialRoute(
          isAuthenticated: false,
          isProfileSetupCompleted: false,
        );
        expect(route, equals('/auth-decision'));
      },
    );

    test(
      'Condition 1: unauthenticated user without sign-in is strictly routed to /auth-decision',
      () async {
        final service = StartupGateService();

        await service.setAuthDecisionMade(true);

        expect(await service.isAuthDecisionMade(), isTrue);

        final route = await service.determineInitialRoute(
          isAuthenticated: false,
          isProfileSetupCompleted: false,
        );
        expect(route, equals('/auth-decision'));
      },
    );

    test(
      'Unauthenticated user cannot bypass auth even with legacy flags',
      () async {
        final service = StartupGateService();

        await service.setAuthDecisionMade(true);
        await service.setGuestOnboardingCompleted(true);

        final route = await service.determineInitialRoute(
          isAuthenticated: false,
          isProfileSetupCompleted: true,
        );
        expect(route, equals('/auth-decision'));
      },
    );

    test(
      'Condition 2 (Existing Account User): DB profile setup completed -> routes directly to /home (no wizard)',
      () async {
        final service = StartupGateService();
        const userId = 'existing-user-999';

        // Authenticated with isProfileSetupCompleted == true in DB
        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: true,
          userId: userId,
        );

        expect(route, equals('/home'));
        expect(await service.isAccountOnboardingCompleted(userId), isTrue);
      },
    );

    test(
      'Condition 2 (New Account User): DB profile setup not completed -> routes to /setup-wizard',
      () async {
        final service = StartupGateService();
        const userId = 'brand-new-user-111';

        // Authenticated with isProfileSetupCompleted == false in DB
        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );

        expect(route, equals('/setup-wizard'));
      },
    );

    test(
      'Condition 3: Wizard skip persists skip flag and authenticated user enters /home',
      () async {
        final service = StartupGateService();
        const userId = 'skip-wizard-athlete-1';

        expect(await service.hasSkippedWizard(), isFalse);
        await service.setWizardSkipped(true);
        await service.setAccountOnboardingCompleted(userId, true);

        expect(await service.hasSkippedWizard(), isTrue);
        expect(await service.isAccountOnboardingCompleted(userId), isTrue);

        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );
        expect(route, equals('/home'));
      },
    );

    test(
      'Condition 3: NotificationService dispatches immediate and scheduled wizard reminder',
      () async {
        final notifService = NotificationService.instance;
        await notifService.cancelAllNotifications();

        await notifService.showImmediateNotification(
          id: 'setup_wizard_skip_reminder',
          title: 'Complete Your Fitness Setup 🎯',
          body:
              'Finish setting up your personalized goals and workout schedule.',
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );

        await notifService.scheduleNotification(
          id: 'setup_wizard_reminder_followup',
          title: 'Your Fitness Plan Is Waiting ⚡',
          body: 'Take 2 minutes to complete your setup wizard.',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );

        final items = notifService.scheduledNotifications;
        expect(
          items.any((item) => item.id == 'setup_wizard_skip_reminder'),
          isTrue,
        );
        expect(
          items.any((item) => item.id == 'setup_wizard_reminder_followup'),
          isTrue,
        );
        final item = items.firstWhere(
          (i) => i.id == 'setup_wizard_skip_reminder',
        );
        expect(item.payload, equals('/setup-wizard'));
      },
    );

    test(
      'resetOnboarding resets all flags and routes fresh state back to /auth-decision',
      () async {
        final service = StartupGateService();

        await service.setFirstLaunchCompleted(true);
        await service.setAuthDecisionMade(true);
        await service.setGuestOnboardingCompleted(true);
        await service.setWizardSkipped(true);
        await service.saveWizardDraftStep(5);

        await service.resetOnboarding();

        expect(await service.isFirstLaunchCompleted(), isFalse);
        expect(await service.isAuthDecisionMade(), isFalse);
        expect(await service.isGuestOnboardingCompleted(), isFalse);
        expect(await service.hasSkippedWizard(), isFalse);
        expect(await service.getWizardDraftStep(), isNull);

        final route = await service.determineInitialRoute(
          isAuthenticated: false,
          isProfileSetupCompleted: false,
        );
        expect(route, equals('/auth-decision'));
      },
    );
  });
}
