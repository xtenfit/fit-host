import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await NotificationService.instance.cancelAllNotifications();
  });

  tearDown(() async {
    await NotificationService.instance.cancelAllNotifications();
  });

  group('Existing Account User Wizard & Notification Prevention Suite', () {
    test(
      'NotificationService.cancelWizardSetupNotifications() cancels both skip and followup reminder notifications',
      () async {
        final notifService = NotificationService.instance;

        // 1. Schedule wizard skip reminder and followup reminder
        await notifService.showImmediateNotification(
          id: NotificationService.keyWizardSkipReminderId,
          title: 'Complete Your Fitness Setup 🎯',
          body:
              'Finish setting up your personalized goals and workout schedule.',
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );

        await notifService.scheduleNotification(
          id: NotificationService.keyWizardFollowupReminderId,
          title: 'Your Fitness Plan Is Waiting ⚡',
          body: 'Take 2 minutes to complete your setup wizard.',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );

        // Verify both reminders are scheduled
        expect(
          notifService.scheduledNotifications.any(
            (item) => item.id == NotificationService.keyWizardSkipReminderId,
          ),
          isTrue,
        );
        expect(
          notifService.scheduledNotifications.any(
            (item) =>
                item.id == NotificationService.keyWizardFollowupReminderId,
          ),
          isTrue,
        );

        // 2. Call cancelWizardSetupNotifications()
        await notifService.cancelWizardSetupNotifications();

        // Verify both reminders are completely removed from scheduled list
        expect(
          notifService.scheduledNotifications.any(
            (item) => item.id == NotificationService.keyWizardSkipReminderId,
          ),
          isFalse,
        );
        expect(
          notifService.scheduledNotifications.any(
            (item) =>
                item.id == NotificationService.keyWizardFollowupReminderId,
          ),
          isFalse,
        );
      },
    );

    test(
      'Existing account with profile completed in DB routes directly to /home and cancels wizard notifications',
      () async {
        final notifService = NotificationService.instance;
        final gateService = StartupGateService();
        const userId = 'existing-db-user-123';

        // Pre-schedule notifications as if previously queued
        await notifService.showImmediateNotification(
          id: NotificationService.keyWizardSkipReminderId,
          title: 'Setup Reminder',
          body: 'Finish setup',
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );
        expect(notifService.scheduledNotifications.length, equals(1));

        // Authenticated existing user with completed profile setup
        final route = await gateService.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: true,
          userId: userId,
        );

        expect(route, equals('/home'));
        expect(await gateService.isAccountOnboardingCompleted(userId), isTrue);

        // Verify wizard notifications are cancelled
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          notifService.scheduledNotifications.any(
            (n) => n.id == NotificationService.keyWizardSkipReminderId,
          ),
          isFalse,
        );
      },
    );

    test(
      'Existing account with saved profile in secure storage routes directly to /home even if in-memory flag is false',
      () async {
        final notifService = NotificationService.instance;
        final gateService = StartupGateService();
        const userId = 'existing-storage-user-456';

        // Pre-populate secure storage with existing user profile
        const storage = FlutterSecureStorage();
        await storage.write(
          key: 'fit_host_user_profile_$userId',
          value: '{"id":"$userId","name":"Existing User","heightCm":178}',
        );

        // Pre-queue a wizard followup
        await notifService.scheduleNotification(
          id: NotificationService.keyWizardFollowupReminderId,
          title: 'Your Fitness Plan Is Waiting ⚡',
          body: 'Take 2 minutes to complete your setup wizard.',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );
        expect(notifService.scheduledNotifications.length, equals(1));

        // In-memory isProfileSetupCompleted is false because profile was not loaded yet
        final route = await gateService.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );

        expect(route, equals('/home'));
        expect(await gateService.isAccountOnboardingCompleted(userId), isTrue);

        // Verify notifications cancelled
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          notifService.scheduledNotifications.any(
            (n) => n.id == NotificationService.keyWizardFollowupReminderId,
          ),
          isFalse,
        );
      },
    );

    test(
      'Existing account with account onboarding completed flag routes to /home and cancels wizard notifications',
      () async {
        final notifService = NotificationService.instance;
        final gateService = StartupGateService();
        const userId = 'existing-onboarded-user-789';

        await gateService.setAccountOnboardingCompleted(userId, true);

        // Pre-queue wizard notifications
        await notifService.showImmediateNotification(
          id: NotificationService.keyWizardSkipReminderId,
          title: 'Setup Reminder',
          body: 'Finish setup',
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );

        final route = await gateService.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );

        expect(route, equals('/home'));

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          notifService.scheduledNotifications.any(
            (n) => n.id == NotificationService.keyWizardSkipReminderId,
          ),
          isFalse,
        );
      },
    );

    test(
      'Brand new user without profile or onboarding routes to /setup-wizard',
      () async {
        final gateService = StartupGateService();
        const userId = 'brand-new-user-000';

        final route = await gateService.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );

        expect(route, equals('/setup-wizard'));
      },
    );

    test(
      'hasSavedProfile returns true only when valid profile JSON exists in storage',
      () async {
        final gateService = StartupGateService();
        const storage = FlutterSecureStorage();
        const userId = 'test-profile-check-user';

        expect(await gateService.hasSavedProfile(userId), isFalse);

        await storage.write(
          key: 'fit_host_user_profile_$userId',
          value: '{"id":"$userId","name":"Test Athlete"}',
        );

        expect(await gateService.hasSavedProfile(userId), isTrue);
      },
    );

    test(
      'resetOnboarding with userId cleans up user-scoped onboarding key',
      () async {
        final gateService = StartupGateService();
        const userId = 'reset-user-test';

        await gateService.setAccountOnboardingCompleted(userId, true);
        expect(await gateService.isAccountOnboardingCompleted(userId), isTrue);

        await gateService.resetOnboarding(userId: userId);
        expect(await gateService.isAccountOnboardingCompleted(userId), isFalse);
      },
    );
  });
}
