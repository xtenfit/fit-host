import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/workouts/presentation/controllers/workout_providers.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/lock_screen_security_service.dart';
import 'core/services/supabase_service.dart';
import 'features/profile/presentation/controllers/user_profile_controller.dart';
import 'features/reminders/data/repositories/reminder_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Readiness: Global exception & crash monitoring boundaries
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    CrashlyticsService.instance.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[UncaughtAsyncError] $error\n$stack');
    CrashlyticsService.instance.recordError(error, stack, fatal: true);
    return true; // Mark as handled to prevent process termination
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0A0F0D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFF00E676),
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kDebugMode
                    ? details.exceptionAsString()
                    : 'An unexpected interface error occurred. Please restart the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  };

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Initialize Crashlytics safely (no crash if unconfigured)
  await CrashlyticsService.instance.initialize();

  // Initialize PostHog Analytics safely (never throws)
  final posthogKey = dotenv.isInitialized
      ? (dotenv.env['POSTHOG_API_KEY'] ?? dotenv.env['POSTHOG_PROJECT_TOKEN'])
            ?.trim()
      : null;
  final posthogHost = dotenv.isInitialized
      ? dotenv.env['POSTHOG_HOST']?.trim()
      : 'https://us.i.posthog.com';

  await AnalyticsService.instance.initialize(
    apiKey: posthogKey,
    host: posthogHost,
  );
  AnalyticsService.instance.track(AnalyticsEvents.appOpened);

  try {
    await Supabase.initialize(
      url: getSupabaseUrl(),
      // ignore: deprecated_member_use
      anonKey: getSupabasePublishableKey(),
    );
    AnalyticsService.instance.logInfo(
      'Application dependencies initialized',
      attributes: {
        'event': 'application_dependencies_initialized',
        'dependency': 'supabase',
      },
    );
  } catch (e) {
    debugPrint('[main] Supabase init info: $e');
  }

  runApp(const ProviderScope(child: FitHostApp()));

  unawaited(_initializeNotifications());
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('[main] NotificationService init: $e');
  }
}

class FitHostApp extends ConsumerStatefulWidget {
  const FitHostApp({super.key});

  @override
  ConsumerState<FitHostApp> createState() => _FitHostAppState();
}

class _FitHostAppState extends ConsumerState<FitHostApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notifSub;
  StreamSubscription<Map<String, String>>? _alarmActionSub;
  StreamSubscription? _authSub;
  String? _lastPayload;
  DateTime? _lastPayloadTime;

  void _routeToPayload(String payload) {
    if (payload.isEmpty) return;
    final uri = Uri.tryParse(payload);
    if (uri == null || !payload.startsWith('/')) {
      debugPrint('[App] Ignoring invalid notification route: $payload');
      return;
    }
    const supportedPrefixes = <String>[
      '/alarm',
      '/workout/',
      '/workout-summary',
      '/workouts',
      '/nutrition',
      '/hydration',
      '/steps',
      '/notifications',
      '/calendar',
      '/reminders',
      '/progress',
      '/diary',
      '/setup-wizard',
    ];
    if (!supportedPrefixes.any(
      (prefix) => uri.path == prefix || uri.path.startsWith(prefix),
    )) {
      debugPrint('[App] Ignoring unsupported notification route: $payload');
      return;
    }
    final now = DateTime.now();
    if (_lastPayload == payload &&
        _lastPayloadTime != null &&
        now.difference(_lastPayloadTime!) <
            const Duration(milliseconds: 2500)) {
      debugPrint(
        '🔔 [App] Suppressing duplicate notification payload routing: $payload',
      );
      return;
    }
    _lastPayload = payload;
    _lastPayloadTime = now;

    if (payload == '/setup-wizard' || payload.startsWith('/setup-wizard')) {
      final profile = ref.read(userProfileProvider);
      final auth = ref.read(authProvider);
      final isExistingUser =
          profile.isProfileSetupCompleted ||
          (auth.isAuthenticated && auth.user != null);
      if (isExistingUser) {
        NotificationService.instance.cancelWizardSetupNotifications().ignore();
        debugPrint(
          '🔔 [App] Suppressing /setup-wizard notification route for existing user -> routing to /home',
        );
        appRouter.go('/home');
        return;
      }
    }

    debugPrint('🔔 [App] Routing to notification payload: $payload');
    appRouter.push(payload);
  }

  void _reconcileAlarms() {
    try {
      ref.read(reminderRepositoryProvider).reconcileSchedules();
    } catch (e) {
      debugPrint('Alarm reconciliation error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AnalyticsService.instance.track(AnalyticsEvents.sessionStarted);
      AnalyticsService.instance.logInfo(
        'Application resumed',
        attributes: {'event': 'application_resumed'},
      );
      debugPrint('🔄 [App] Resumed -> reconciling reminder schedules');
      _reconcileAlarms();
      final profile = ref.read(userProfileProvider);
      final auth = ref.read(authProvider);
      if (profile.isProfileSetupCompleted ||
          (auth.isAuthenticated && auth.user != null)) {
        NotificationService.instance.cancelWizardSetupNotifications().ignore();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifSub = NotificationService.instance.onNotificationTap.listen((
      payload,
    ) {
      _routeToPayload(payload);
    });

    _alarmActionSub = NotificationService.instance.onAlarmAction.listen((
      event,
    ) {
      if (event['action'] == 'complete' && event['id'] != null) {
        debugPrint(
          '✓ [App] Alarm action complete received for id: ${event['id']}',
        );
        ref.read(reminderRepositoryProvider).completeReminder(event['id']!);
      }
    });

    // Listen for Supabase auth state change and password recovery callback deep link
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          debugPrint(
            '🔑 [App] Deep link password recovery detected -> /auth/update-password',
          );
          appRouter.push('/auth/update-password');
        } else if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.initialSession) {
          // Identify at the authentication boundary, including a restored session,
          // so subsequent events and PostHog error reports inherit this UUID.
          final uid = data.session?.user.id;
          if (uid != null) {
            AnalyticsService.instance.identify(uid);
            AnalyticsService.instance.track(AnalyticsEvents.sessionStarted);
            CrashlyticsService.instance.setUserId(uid);
          }
        } else if (data.event == AuthChangeEvent.signedOut) {
          AnalyticsService.instance.reset();
          CrashlyticsService.instance.setUserId('guest');
        }
      });
    } catch (_) {}

    // Handle cold boot from alarm/notification popup when app was closed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifPayload = await NotificationService.instance
          .getInitialPayload();
      final alarmPayload = await LockScreenSecurityService.instance
          .getInitialAlarmPayload();
      final initialPayload = notifPayload ?? alarmPayload;
      if (initialPayload != null && initialPayload.isNotEmpty) {
        debugPrint(
          '🚨 [App] Launching from cold boot alarm payload: $initialPayload',
        );
        _routeToPayload(initialPayload);
      }
    });

    // Warm up the database, pre-seed exercise library, and reconcile active reminders
    Future.microtask(() async {
      try {
        final repo = ref.read(workoutRepositoryProvider);
        await repo.seedDefaultExercises();
      } catch (e) {
        debugPrint('DB init error: $e');
      }
      _reconcileAlarms();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    _alarmActionSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Fit Host',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
