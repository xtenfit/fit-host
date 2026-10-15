import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/workouts/presentation/controllers/workout_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FitHostApp(),
    ),
  );
}

class FitHostApp extends ConsumerStatefulWidget {
  const FitHostApp({super.key});

  @override
  ConsumerState<FitHostApp> createState() => _FitHostAppState();
}

class _FitHostAppState extends ConsumerState<FitHostApp> {
  @override
  void initState() {
    super.initState();
    // Warm up the database and pre-seed exercise library
    Future.microtask(() async {
      try {
        final repo = ref.read(workoutRepositoryProvider);
        await repo.seedDefaultExercises();
      } catch (e) {
        debugPrint('DB init error: $e');
      }
    });
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
