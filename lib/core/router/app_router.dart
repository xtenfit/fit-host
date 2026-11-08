import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_motion.dart';
import 'package:fit_host/features/home/presentation/home_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/workouts_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/active_workout_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/workout_detail_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/exercise_library_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/exercise_wiki_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/all_routines_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/routine_builder_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/workout_summary_screen.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/screens/workout_category_detail_screen.dart';
import 'package:fit_host/features/progress/presentation/progress_screen.dart';
import 'package:fit_host/features/progress/presentation/screens/body_measurements_screen.dart';
import 'package:fit_host/features/progress/presentation/screens/progress_gallery_screen.dart';
import 'package:fit_host/features/nutrition/presentation/nutrition_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/hydration_detail_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/add_meal_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/nutrition_diary_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/barcode_scanner_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/photo_meal_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/food_search_screen.dart';
import 'package:fit_host/features/profile/presentation/profile_screen.dart';
import 'package:fit_host/features/shell/main_navigation_shell.dart';
import 'package:fit_host/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:fit_host/features/calendar/presentation/screens/calendar_sync_screen.dart';
import 'package:fit_host/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:fit_host/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:fit_host/features/planner/presentation/daily_planner_screen.dart';
import 'package:fit_host/features/more/presentation/more_screen.dart';
import 'package:fit_host/features/settings/presentation/notification_settings_screen.dart';
import 'package:fit_host/features/settings/presentation/privacy_export_screen.dart';
import 'package:fit_host/features/profile/presentation/screens/fitness_setup_wizard_screen.dart';
import 'package:fit_host/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:fit_host/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:fit_host/features/steps/presentation/screens/steps_screen.dart';
import 'package:fit_host/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:fit_host/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:fit_host/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:fit_host/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:fit_host/features/auth/presentation/screens/update_password_screen.dart';
import 'package:fit_host/features/auth/presentation/screens/auth_decision_screen.dart';
import 'package:fit_host/features/onboarding/presentation/startup_gate_screen.dart';
import 'package:fit_host/features/onboarding/presentation/splash_screen.dart';
import 'package:fit_host/features/settings/presentation/delete_account_screen.dart';
import 'package:fit_host/features/settings/presentation/user_manual_screen.dart';
import 'package:fit_host/features/reminders/presentation/screens/sound_settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_host/features/reminders/presentation/screens/fullscreen_alarm_screen.dart';
import 'package:fit_host/features/settings/presentation/permission_settings_screen.dart';
import 'package:fit_host/features/settings/presentation/home_widgets_hub_screen.dart';
import 'package:fit_host/features/settings/presentation/health_connect_settings_screen.dart';
import 'package:fit_host/features/diary/presentation/daily_diary_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

/// Listenable that notifies GoRouter whenever Supabase auth state changes,
/// ensuring routes are immediately re-evaluated to eliminate auth screen repetition.
class RouterAuthNotifier extends ChangeNotifier {
  static final RouterAuthNotifier instance = RouterAuthNotifier._();
  dynamic _subscription;

  RouterAuthNotifier._() {
    _tryAttachListener();
  }

  void _tryAttachListener() {
    if (_subscription != null) return;
    try {
      final client = Supabase.instance.client;
      _subscription = client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
    } catch (_) {}
  }

  void initialize(SupabaseClient client) {
    try {
      _subscription?.cancel();
    } catch (_) {}
    try {
      _subscription = client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
      notifyListeners();
    } catch (_) {}
  }

  void notifyAuthChanged() {
    _tryAttachListener();
    notifyListeners();
  }
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: RouterAuthNotifier.instance,
  redirect: (BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;
    final isAuthScreen =
        path == '/auth-decision' ||
        path == '/auth' ||
        path == '/auth/sign-in' ||
        path == '/auth/sign-up' ||
        path == '/auth/verify-email' ||
        path == '/auth/reset-password' ||
        path == '/auth/update-password';
    final isStartupScreen = path == '/' || path == '/startup-gate';

    bool isAuthenticated = false;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user.id.isNotEmpty) {
        isAuthenticated = true;
      }
    } catch (_) {}

    if (isAuthScreen) {
      if (isAuthenticated) {
        debugPrint(
          '[AppRouter] Active session detected -> redirecting from $path to /home',
        );
        return '/home';
      }
      return null;
    }

    // Startup screens handle their own initial navigation via StartupGateNotifier
    if (isStartupScreen) {
      return null;
    }

    // Every user is required to have an account. No guest mode allowed.
    if (!isAuthenticated) {
      debugPrint(
        '[AppRouter] Unauthenticated access to $path -> redirecting to /auth-decision',
      );
      return '/auth-decision';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/startup-gate',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StartupGateScreen(),
    ),
    GoRoute(
      path: '/auth-decision',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const AuthDecisionScreen(),
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
        ),
        GoRoute(
          path: '/workouts',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const WorkoutsScreen(),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProgressScreen(),
          ),
        ),
        GoRoute(
          path: '/nutrition',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const NutritionScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/profile/edit',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const EditProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/calendar',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const CalendarScreen(),
      ),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const RemindersScreen(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const NotificationCenterScreen(),
      ),
    ),
    GoRoute(
      path: '/alarm',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.uri.queryParameters['id'] ?? 'alarm_default';
        final title = state.uri.queryParameters['title'] ?? 'Fit Host Alert';
        final body = state.uri.queryParameters['body'] ?? '';
        final channel = state.uri.queryParameters['channel'];
        final snoozeMinutes =
            int.tryParse(state.uri.queryParameters['snoozeMinutes'] ?? '') ??
            10;
        return AppleTransitions.iosModal(
          key: state.pageKey,
          child: FullscreenAlarmScreen(
            id: id,
            title: title,
            body: body,
            channel: channel,
            snoozeMinutes: snoozeMinutes,
          ),
        );
      },
    ),
    GoRoute(
      path: '/permission-settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final isPostOnboarding =
            state.uri.queryParameters['postOnboarding'] == 'true';
        return AppleTransitions.iosPage(
          key: state.pageKey,
          child: PermissionSettingsScreen(isPostOnboarding: isPostOnboarding),
        );
      },
    ),
    GoRoute(
      path: '/planner',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const DailyPlannerScreen(),
      ),
    ),
    GoRoute(
      path: '/more',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const MoreScreen(),
      ),
    ),
    GoRoute(
      path: '/routines',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const AllRoutinesScreen(),
      ),
    ),
    GoRoute(
      path: '/routines/builder',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final routineId = state.uri.queryParameters['id'];
        return AppleTransitions.iosPage(
          key: state.pageKey,
          child: RoutineBuilderScreen(routineId: routineId),
        );
      },
    ),
    GoRoute(
      path: '/workout-category/:category',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final category = state.pathParameters['category'] ?? 'Strength';
        return AppleTransitions.iosPage(
          key: state.pageKey,
          child: WorkoutCategoryDetailScreen(categoryName: category),
        );
      },
    ),
    GoRoute(
      path: '/progress/measurements',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const BodyMeasurementsScreen(),
      ),
    ),
    GoRoute(
      path: '/progress/gallery',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const ProgressGalleryScreen(),
      ),
    ),
    GoRoute(
      path: '/hydration',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const HydrationDetailScreen(),
      ),
    ),
    GoRoute(
      path: '/nutrition/add',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosModal(
        key: state.pageKey,
        child: const AddMealScreen(),
      ),
    ),
    GoRoute(
      path: '/nutrition/diary',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const NutritionDiaryScreen(),
      ),
    ),
    GoRoute(
      path: '/nutrition/scan-barcode',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosModal(
        key: state.pageKey,
        child: const BarcodeScannerScreen(),
      ),
    ),
    GoRoute(
      path: '/nutrition/snap-meal',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosModal(
        key: state.pageKey,
        child: const PhotoMealScreen(),
      ),
    ),
    GoRoute(
      path: '/nutrition/search-food',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const FoodSearchScreen(),
      ),
    ),
    GoRoute(
      path: '/steps',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const StepsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const NotificationSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const PrivacyExportScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/data-export',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const PrivacyExportScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/delete-account',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const DeleteAccountScreen(),
      ),
    ),
    GoRoute(
      path: '/diary',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const DailyDiaryScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/user-manual',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const UserManualScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/sound-settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const SoundSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/widgets',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const HomeWidgetsHubScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/health-connect',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const HealthConnectSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/calendar-sync',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const CalendarSyncScreen(),
      ),
    ),
    GoRoute(
      path: '/profile/setup',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const ProfileSetupScreen(isInitialSetup: true),
      ),
    ),
    GoRoute(
      path: '/active-workout',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosModal(
        key: state.pageKey,
        child: const ActiveWorkoutScreen(),
      ),
    ),
    GoRoute(
      path: '/workout/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AppleTransitions.iosPage(
          key: state.pageKey,
          child: WorkoutDetailScreen(workoutId: id),
        );
      },
    ),
    GoRoute(
      path: '/workout-summary',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final workout = state.extra as WorkoutEntity;
        return AppleTransitions.iosPage(
          key: state.pageKey,
          child: WorkoutSummaryScreen(workout: workout),
        );
      },
    ),
    GoRoute(
      path: '/exercises',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const ExerciseLibraryScreen(),
      ),
    ),
    GoRoute(
      path: '/exercise-wiki',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const ExerciseWikiScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const FitnessSetupWizardScreen(isInitialSetup: true),
      ),
    ),
    GoRoute(
      path: '/profile-setup',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const ProfileSetupScreen(isInitialSetup: true),
      ),
    ),
    GoRoute(
      path: '/setup-wizard',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final stepParam = state.uri.queryParameters['step'];
        final isRedo = state.uri.queryParameters['redo'] == 'true';
        final initialStep = stepParam != null
            ? (int.tryParse(stepParam) ?? 0)
            : 0;
        return AppleTransitions.iosPage(
          key: state.pageKey,
          child: FitnessSetupWizardScreen(
            isInitialSetup: !isRedo,
            initialScreen: initialStep,
          ),
        );
      },
    ),
    GoRoute(
      path: '/setup-wizard-plan',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const FitnessSetupWizardScreen(
          isInitialSetup: true,
          initialScreen: 19,
        ),
      ),
    ),
    GoRoute(
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const SignInScreen(),
      ),
    ),
    GoRoute(
      path: '/auth/sign-in',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const SignInScreen(),
      ),
    ),
    GoRoute(
      path: '/auth/sign-up',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const SignUpScreen(),
      ),
    ),
    GoRoute(
      path: '/auth/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/auth/verify-email',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final email = state.uri.queryParameters['email'];
        return AppleTransitions.iosPage(
          key: state.pageKey,
          child: EmailVerificationScreen(email: email),
        );
      },
    ),
    GoRoute(
      path: '/auth/update-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppleTransitions.iosPage(
        key: state.pageKey,
        child: const UpdatePasswordScreen(),
      ),
    ),
  ],
);
