import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/features/home/presentation/home_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/workouts_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/active_workout_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/workout_detail_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/exercise_library_screen.dart';
import 'package:fit_host/features/progress/presentation/progress_screen.dart';
import 'package:fit_host/features/nutrition/presentation/nutrition_screen.dart';
import 'package:fit_host/features/profile/presentation/profile_screen.dart';
import 'package:fit_host/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fit_host/features/shell/main_navigation_shell.dart';
import 'package:fit_host/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:fit_host/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:fit_host/features/planner/presentation/daily_planner_screen.dart';
import 'package:fit_host/features/more/presentation/more_screen.dart';
import 'package:fit_host/features/settings/presentation/notification_settings_screen.dart';
import 'package:fit_host/features/settings/presentation/privacy_export_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/workouts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WorkoutsScreen(),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProgressScreen(),
          ),
        ),
        GoRoute(
          path: '/nutrition',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NutritionScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/calendar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RemindersScreen(),
    ),
    GoRoute(
      path: '/planner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DailyPlannerScreen(),
    ),
    GoRoute(
      path: '/more',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MoreScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyExportScreen(),
    ),
    GoRoute(
      path: '/active-workout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ActiveWorkoutScreen(),
    ),
    GoRoute(
      path: '/workout/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return WorkoutDetailScreen(workoutId: id);
      },
    ),
    GoRoute(
      path: '/exercises',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExerciseLibraryScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
);
