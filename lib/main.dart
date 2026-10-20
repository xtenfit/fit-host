import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/workouts/presentation/controllers/workout_providers.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  try {
    await Supabase.initialize(
      url: getSupabaseUrl(),
      // ignore: deprecated_member_use
      anonKey: getSupabasePublishableKey(),
    );
  } catch (e) {
    debugPrint('[main] Supabase early init: $e');
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('[main] NotificationService init: $e');
  }

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
  StreamSubscription<String>? _notifSub;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _notifSub = NotificationService.instance.onNotificationTap.listen((payload) {
      if (payload.isNotEmpty) {
        debugPrint('🔔 [App] Routing to notification payload: $payload');
        appRouter.push(payload);
      }
    });

    // Listen for Supabase password recovery callback deep link
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          debugPrint('🔑 [App] Deep link password recovery detected -> /auth/update-password');
          appRouter.push('/auth/update-password');
        }
      });
    } catch (_) {}

    // Handle cold boot from alarm/notification popup when app was closed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialPayload =
          await NotificationService.instance.getInitialPayload();
      if (initialPayload != null && initialPayload.isNotEmpty) {
        debugPrint('🚨 [App] Launching from cold boot alarm payload: $initialPayload');
        appRouter.push(initialPayload);
      }
    });

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
  void dispose() {
    _notifSub?.cancel();
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
