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
import 'package:fit_host/features/shell/main_navigation_shell.dart';

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
  ],
);
