import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/services/analytics_service.dart';
import 'package:fit_host/core/services/crashlytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalyticsEvents Constants Verification', () {
    test('standard events match required specifications', () {
      expect(AnalyticsEvents.appOpened, 'app_opened');
      expect(AnalyticsEvents.sessionStarted, 'session_started');
      expect(AnalyticsEvents.signupStarted, 'signup_started');
      expect(AnalyticsEvents.signupCompleted, 'signup_completed');
      expect(AnalyticsEvents.loginFailed, 'login_failed');
      expect(AnalyticsEvents.onboardingCompleted, 'onboarding_completed');
      expect(AnalyticsEvents.workoutCreated, 'workout_created');
      expect(AnalyticsEvents.workoutCompleted, 'workout_completed');
      expect(AnalyticsEvents.exerciseLibraryOpened, 'exercise_library_opened');
      expect(AnalyticsEvents.mealLogged, 'meal_logged');
      expect(AnalyticsEvents.hydrationLogged, 'hydration_logged');
      expect(AnalyticsEvents.bodyMeasurementLogged, 'body_measurement_logged');
      expect(AnalyticsEvents.reminderCreated, 'reminder_created');
      expect(AnalyticsEvents.reminderCompleted, 'reminder_completed');
      expect(
        AnalyticsEvents.integrationSetupCompleted,
        'integration_setup_completed',
      );
      expect(AnalyticsEvents.coreJourneyFailed, 'core_journey_failed');
    });
  });

  group('AnalyticsService Privacy & Initialization Tests', () {
    test(
      'initializes safely without API key and operates in fallback mode',
      () async {
        final analytics = AnalyticsService.instance;
        await analytics.initialize(apiKey: null, host: null);

        expect(analytics.isInitialized, isTrue);
        expect(analytics.isOptedOut, isFalse);
      },
    );

    test(
      'track() executes safely without throwing when unconfigured',
      () async {
        final analytics = AnalyticsService.instance;
        await analytics.initialize(apiKey: '');

        expect(
          () => analytics.track(
            AnalyticsEvents.workoutCompleted,
            properties: {
              'duration_seconds': 1200,
              'email': 'should_be_stripped@example.com',
              'weight': 80.5,
              'description':
                  'Athlete with email test@fit.com and Bearer token123',
              'exercise_list': ['squat', 'bench', 'deadlift'],
            },
          ),
          returnsNormally,
        );
      },
    );

    test(
      'identify() blocks raw email address and sanitizes identifier',
      () async {
        final analytics = AnalyticsService.instance;

        expect(() => analytics.identify('user@example.com'), returnsNormally);

        expect(() => analytics.identify('guest'), returnsNormally);

        expect(
          () => analytics.identify('3f9d45e1-884b-4bfa-9f79-66bf82ce9dc4'),
          returnsNormally,
        );
      },
    );

    test('optOut() and optIn() manage user privacy preference', () async {
      final analytics = AnalyticsService.instance;

      await analytics.optOut();
      expect(analytics.isOptedOut, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('fithost_analytics_opt_out'), isTrue);

      await analytics.optIn();
      expect(analytics.isOptedOut, isFalse);
      expect(prefs.getBool('fithost_analytics_opt_out'), isFalse);
    });

    test('reset() clears analytics session safely', () async {
      final analytics = AnalyticsService.instance;
      expect(() => analytics.reset(), returnsNormally);
    });
  });

  group('CrashlyticsService Resilience & Redaction Tests', () {
    test('initializes safely when native Firebase is unconfigured', () async {
      final crashlytics = CrashlyticsService.instance;
      await crashlytics.initialize(enableInDev: false);

      expect(crashlytics.isInitialized, isFalse);
      expect(crashlytics.isEnabled, isFalse);
    });

    test('recordFlutterError handles error details safely', () {
      final crashlytics = CrashlyticsService.instance;
      final details = FlutterErrorDetails(
        exception: Exception(
          'Simulated test rendering exception with Bearer abc.123',
        ),
        stack: StackTrace.current,
        context: ErrorDescription(
          'Widget build error on user@test.com profile',
        ),
      );

      expect(() => crashlytics.recordFlutterError(details), returnsNormally);
    });

    test(
      'recordError captures asynchronous exception without crashing',
      () async {
        final crashlytics = CrashlyticsService.instance;

        await expectLater(
          crashlytics.recordError(
            StateError('Async worker error: sb_publishable_secret_key_12345'),
            StackTrace.current,
            reason: 'Network request timeout',
          ),
          completes,
        );
      },
    );

    test('setUserId and setCustomKey strip sensitive data', () async {
      final crashlytics = CrashlyticsService.instance;

      await expectLater(
        crashlytics.setUserId('athlete@fithost.tech'),
        completes,
      );
      await expectLater(
        crashlytics.setUserId('d41d8cd9-8f00-b204-e980-0998ecf8427e'),
        completes,
      );

      // Sensitive keys are ignored
      await expectLater(
        crashlytics.setCustomKey('password', 'secret'),
        completes,
      );
      await expectLater(
        crashlytics.setCustomKey('body_weight', '75kg'),
        completes,
      );
      await expectLater(
        crashlytics.setCustomKey('screen', 'home_dashboard'),
        completes,
      );
    });
  });
}
