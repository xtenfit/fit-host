import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/services/startup_gate_service.dart';
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/features/profile/domain/models/user_profile.dart';
import 'package:fit_host/features/reminders/domain/models/reminder.dart';
import 'package:fit_host/features/reminders/presentation/screens/fullscreen_alarm_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('1. One-Time Onboarding Routing & Scoped State Tests', () {
    test(
      'Fresh user is routed to /auth-decision and defaults isProfileSetupCompleted to false',
      () async {
        final service = StartupGateService();
        final guestProfile = UserProfile.defaultGuest();

        expect(guestProfile.isProfileSetupCompleted, isFalse);
        expect(await service.isGuestOnboardingCompleted(), isFalse);
        expect(await service.isAuthDecisionMade(), isFalse);

        final route = await service.determineInitialRoute(
          isAuthenticated: false,
          isProfileSetupCompleted: guestProfile.isProfileSetupCompleted,
          userId: null,
        );

        expect(route, equals('/auth-decision'));
      },
    );

    test(
      'Condition 1: New guest user who chose continue as guest is routed to /setup-wizard',
      () async {
        final service = StartupGateService();
        await service.setAuthDecisionMade(true);

        final route = await service.determineInitialRoute(
          isAuthenticated: false,
          isProfileSetupCompleted: false,
          userId: null,
        );

        expect(route, equals('/setup-wizard'));
      },
    );

    test(
      'Returning guest who completed onboarding routes directly to /home',
      () async {
        final service = StartupGateService();
        await service.setFirstLaunchCompleted(true);
        await service.setAuthDecisionMade(true);
        await service.setGuestOnboardingCompleted(true);

        final route = await service.determineInitialRoute(
          isAuthenticated: false,
          isProfileSetupCompleted: true,
          userId: null,
        );

        expect(route, equals('/home'));
      },
    );

    test(
      'Fresh authenticated user without completed profile routes to /setup-wizard',
      () async {
        final service = StartupGateService();
        await service.setFirstLaunchCompleted(true);
        await service.setAuthDecisionMade(true);

        const userId = 'user-abc-123';
        expect(await service.isAccountOnboardingCompleted(userId), isFalse);

        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userId,
        );

        expect(route, equals('/setup-wizard'));
      },
    );

    test(
      'Returning authenticated user with completed profile routes to /home',
      () async {
        final service = StartupGateService();
        await service.setFirstLaunchCompleted(true);
        await service.setAuthDecisionMade(true);

        const userId = 'user-abc-123';
        await service.setAccountOnboardingCompleted(userId, true);

        final route = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: true,
          userId: userId,
        );

        expect(route, equals('/home'));
      },
    );

    test(
      'Account onboarding state is strictly user-scoped and does not leak across users',
      () async {
        final service = StartupGateService();
        const userA = 'user-alice-111';
        const userB = 'user-bob-222';

        await service.setAccountOnboardingCompleted(userA, true);

        expect(await service.isAccountOnboardingCompleted(userA), isTrue);
        expect(await service.isAccountOnboardingCompleted(userB), isFalse);

        // Alice routes to /home, Bob routes to /setup-wizard
        final routeAlice = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: true,
          userId: userA,
        );
        final routeBob = await service.determineInitialRoute(
          isAuthenticated: true,
          isProfileSetupCompleted: false,
          userId: userB,
        );

        expect(routeAlice, equals('/home'));
        expect(routeBob, equals('/setup-wizard'));
      },
    );

    test(
      'Wizard draft step saves and restores correctly, then clears on completion',
      () async {
        final service = StartupGateService();

        expect(await service.getWizardDraftStep(), isNull);

        await service.saveWizardDraftStep(14);
        expect(await service.getWizardDraftStep(), equals(14));

        await service.clearWizardDraftStep();
        expect(await service.getWizardDraftStep(), isNull);
      },
    );

    test(
      'UserProfile model defaults isProfileSetupCompleted to false for uninitialized profiles',
      () {
        final freshProfile = UserProfile(updatedAt: DateTime.now());
        expect(freshProfile.isProfileSetupCompleted, isFalse);

        final completedProfile = freshProfile.copyWith(
          isProfileSetupCompleted: true,
        );
        expect(completedProfile.isProfileSetupCompleted, isTrue);
      },
    );
  });

  group('2. Fullscreen Alarm Screen Constraint & Zero Overflow Tests', () {
    testWidgets(
      'FullscreenAlarmScreen renders without overflow on narrow viewport with 2.0x text scaling',
      (WidgetTester tester) async {
        // Configure extremely constrained viewport (320x480 - smaller than iPhone SE)
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Wrap with MediaQuery setting accessibility textScaler to 2.0x
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 480),
                  textScaler: TextScaler.linear(2.0),
                  padding: EdgeInsets.only(top: 24, bottom: 20),
                ),
                child: const FullscreenAlarmScreen(
                  id: 'test-reminder-1',
                  title: 'Morning Electrolyte Hydration',
                  body: 'Hydration',
                  channel: 'hydration',
                  snoozeMinutes: 10,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify no overflow errors were triggered
        expect(tester.takeException(), isNull);

        // Verify clock, title, and actions are rendered
        expect(find.text('Morning Electrolyte Hydration'), findsOneWidget);
        expect(find.text('Hydration'), findsOneWidget);
        expect(find.text('Log Water (+250ml) ✓'), findsOneWidget);
        expect(find.textContaining('Snooze'), findsOneWidget);
        expect(find.byTooltip('Dismiss'), findsOneWidget);
      },
    );

    testWidgets(
      'FullscreenAlarmScreen renders without overflow on standard phone dimensions',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FullscreenAlarmScreen(
                id: 'test-reminder-2',
                title: 'High-Protein Lunch & Creatine',
                body: 'Nutrition',
                channel: 'nutrition',
                snoozeMinutes: 15,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('High-Protein Lunch & Creatine'), findsOneWidget);
        expect(find.text('Nutrition'), findsOneWidget);
        expect(find.text('Log Meal ✓'), findsOneWidget);
        expect(find.textContaining('Snooze'), findsOneWidget);
      },
    );
  });

  group('3. Notification Service & Alarm Timing Logic Tests', () {
    test(
      'NotificationService records scheduled alarms without throwing in test environment',
      () async {
        final notifService = NotificationService.instance;
        await notifService.initialize();

        const reminderId = 'test-alarm-unit-1';
        final futureTime = DateTime.now().add(const Duration(hours: 3));

        await notifService.scheduleAlarm(
          id: reminderId,
          title: 'Afternoon Workout Session',
          body: 'Time for Afternoon Workout Session (Workout)',
          scheduledTime: futureTime,
          channel: NotificationChannelType.workouts,
          sound: true,
          vibration: true,
        );

        final scheduled = notifService.scheduledNotifications;
        expect(scheduled.any((item) => item.id == reminderId), isTrue);

        final item = scheduled.firstWhere((i) => i.id == reminderId);
        expect(item.title, equals('Afternoon Workout Session'));
        expect(item.channel, equals(NotificationChannelType.workouts));
        expect(item.payload, contains('/alarm?id=test-alarm-unit-1'));

        // Clean up
        await notifService.cancelNotification(reminderId);
        expect(
          notifService.scheduledNotifications.any((i) => i.id == reminderId),
          isFalse,
        );
      },
    );

    test(
      'canScheduleExactAlarms returns valid boolean without error',
      () async {
        final notifService = NotificationService.instance;
        final canExact = await notifService.canScheduleExactAlarms();
        expect(canExact, isA<bool>());
      },
    );

    test(
      'Quiet hours correctly detect suppression intervals across midnight',
      () {
        final notifService = NotificationService.instance;
        notifService.configureQuietHours(
          start: '22:00',
          end: '07:00',
          enabled: true,
        );

        // 23:30 is within quiet hours
        final lateNight = DateTime(2026, 10, 22, 23, 30);
        expect(notifService.isWithinQuietHours(lateNight), isTrue);

        // 03:00 is within quiet hours
        final earlyMorning = DateTime(2026, 10, 22, 3, 0);
        expect(notifService.isWithinQuietHours(earlyMorning), isTrue);

        // 14:00 is outside quiet hours
        final afternoon = DateTime(2026, 10, 22, 14, 0);
        expect(notifService.isWithinQuietHours(afternoon), isFalse);
      },
    );

    test(
      'Recurring daily reminder skips today after completion and targets tomorrow',
      () {
        final reminder = Reminder(
          id: 'daily-reminder-1',
          title: 'Morning Water',
          category: ReminderCategory.hydration,
          timeOfDay: '08:00',
          isEnabled: true,
          recurrence: ReminderRecurrence.daily,
          lastCompletedAt: DateTime.now(), // completed today
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
        );

        expect(reminder.isCompletedToday, isTrue);

        final next = reminder.nextOccurrence(DateTime.now());
        final now = DateTime.now();

        // Next occurrence must be on a future calendar day
        expect(
          next.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59)),
          isTrue,
        );
        expect(next.hour, equals(8));
        expect(next.minute, equals(0));
      },
    );
  });
}
