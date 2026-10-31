import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/core/theme/app_motion.dart';
import 'package:fit_host/core/router/app_router.dart';
import 'package:fit_host/features/steps/presentation/screens/steps_screen.dart';
import 'package:fit_host/features/workouts/presentation/screens/workout_category_detail_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/hydration_detail_screen.dart';
import 'package:fit_host/features/progress/presentation/screens/body_measurements_screen.dart';
import 'package:fit_host/features/progress/presentation/controllers/progress_providers.dart';
import 'package:fit_host/features/progress/domain/models/body_measurement.dart';
import 'package:fit_host/features/progress/domain/models/measurement_delta.dart';
import 'package:fit_host/features/calendar/presentation/screens/calendar_sync_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getAll') return <String, Object?>{};
            return true;
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async => ['wifi'],
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
          MockStreamHandler.inline(
            onListen: (args, sink) {
              sink.success(['wifi']);
            },
          ),
        );
  });

  group('UI/UX Overflow, Shifting & Navigation Repairs Verification Suite', () {
    // -------------------------------------------------------------------------
    // Screenshot 1: Step Counter 7-day movement trend overflow (was 6.6px overflow)
    // -------------------------------------------------------------------------
    testWidgets(
      'Screenshot 1: StepsScreen renders 7-Day Movement Trend header cleanly on 360px viewport without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              authStatusProvider.overrideWithValue(AuthStatus.guest),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const StepsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the 7-day movement trend card and badge render
        expect(find.text('7-Day Movement Trend'), findsOneWidget);
        expect(find.text('Today Only'), findsOneWidget);

        // Verify no RenderFlex overflow exception was caught
        expect(tester.takeException(), isNull);

        db.close().ignore();
      },
    );

    // -------------------------------------------------------------------------
    // Screenshot 2: Workout Category Detail routine difficulty & start button (was 0.788px overflow)
    // -------------------------------------------------------------------------
    testWidgets(
      'Screenshot 2: WorkoutCategoryDetailScreen routine split cards render difficulty and button cleanly on 360px viewport without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              authStatusProvider.overrideWithValue(AuthStatus.guest),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const WorkoutCategoryDetailScreen(
                categoryName: 'Strength Training',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify 'Curated Routines' tab is active and routines render
        expect(find.text('Curated Routines'), findsOneWidget);

        // Verify routine start buttons and difficulty text render without overflow
        expect(find.text('Start Routine'), findsWidgets);
        expect(tester.takeException(), isNull);

        db.close().ignore();
      },
    );

    // -------------------------------------------------------------------------
    // Screenshot 3: Hydration 12-glass interactive row (was 22px overflow)
    // -------------------------------------------------------------------------
    testWidgets(
      'Screenshot 3: HydrationDetailScreen renders 12 glasses via adaptive Wrap without overflow on 360px viewport',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              authStatusProvider.overrideWithValue(AuthStatus.guest),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const HydrationDetailScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Hydration Tracker renders
        expect(find.text('Hydration & Fluids Tracker'), findsOneWidget);

        // Verify adaptive Wrap exists for glasses
        expect(find.byType(Wrap), findsWidgets);

        // Verify zero overflow exceptions
        expect(tester.takeException(), isNull);

        db.close().ignore();
      },
    );

    // -------------------------------------------------------------------------
    // Screenshot 4: AppleTransitions guarantees unique Page keys, preventing Navigator assert crash
    // -------------------------------------------------------------------------
    test(
      'Screenshot 4: AppleTransitions generates unique keys to prevent !keyReservation.contains(key) Navigator crash',
      () {
        const testKey = ValueKey('test_route_key');
        final page1 = AppleTransitions.iosPage(
          child: const SizedBox(),
          key: testKey,
        );
        final page2 = AppleTransitions.iosPage(
          child: const SizedBox(),
          key: testKey,
        );
        final page3 = AppleTransitions.iosModal(
          child: const SizedBox(),
          key: testKey,
        );

        // Ensure every generated page has a distinct, unique key
        expect(page1.key, isNotNull);
        expect(page2.key, isNotNull);
        expect(page3.key, isNotNull);
        expect(page1.key, isNot(equals(page2.key)));
        expect(page2.key, isNot(equals(page3.key)));
      },
    );

    // -------------------------------------------------------------------------
    // Screenshot 5: Missing /settings/calendar-sync route resolved
    // -------------------------------------------------------------------------
    testWidgets(
      'Screenshot 5: GoRouter /settings/calendar-sync route is configured and renders CalendarSyncScreen',
      (WidgetTester tester) async {
        // Verify route match exists in GoRouter configuration
        final match = appRouter.configuration.findMatch(
          Uri.parse('/settings/calendar-sync'),
        );
        expect(match.matches, isNotEmpty);
        expect(
          match.matches.last.matchedLocation,
          equals('/settings/calendar-sync'),
        );

        final db = AppDatabase(NativeDatabase.memory());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              authStatusProvider.overrideWithValue(AuthStatus.guest),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const CalendarSyncScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify CalendarSyncScreen is rendered with title and sync card
        expect(find.byType(CalendarSyncScreen), findsOneWidget);
        expect(find.text('Google Calendar Sync'), findsWidgets);
        expect(tester.takeException(), isNull);

        db.close().ignore();
      },
    );

    // -------------------------------------------------------------------------
    // Screenshot 6: BodyMeasurementsScreen Transformation Summary header overflow (was 11px overflow)
    // -------------------------------------------------------------------------
    testWidgets(
      'Screenshot 6: BodyMeasurementsScreen transformation summary card renders cleanly without overflow on 360px viewport',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final baselineMeasurement = BodyMeasurement(
          id: 'meas-1',
          userId: 'test-user',
          measuredAt: now.subtract(const Duration(days: 45)),
          weightKg: 82.0,
          bodyFatPercentage: 18.5,
          waistCm: 88.0,
          createdAt: now.subtract(const Duration(days: 45)),
          updatedAt: now.subtract(const Duration(days: 45)),
        );

        final latestMeasurement = BodyMeasurement(
          id: 'meas-2',
          userId: 'test-user',
          measuredAt: now,
          weightKg: 78.5,
          bodyFatPercentage: 15.2,
          waistCm: 82.0,
          createdAt: now,
          updatedAt: now,
        );

        final mockDelta = MeasurementProgressDelta(
          baseline: baselineMeasurement,
          latest: latestMeasurement,
        );

        final db = AppDatabase(NativeDatabase.memory());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              authStatusProvider.overrideWithValue(AuthStatus.guest),
              bodyMeasurementsStreamProvider.overrideWith(
                (ref) => Stream.value([latestMeasurement, baselineMeasurement]),
              ),
              measurementProgressDeltaProvider.overrideWith((ref) => mockDelta),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const BodyMeasurementsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Transformation Summary header card renders
        expect(find.text('Transformation Summary'), findsOneWidget);
        expect(find.text('45 Days Progress'), findsOneWidget);

        // Verify zero overflow exceptions
        expect(tester.takeException(), isNull);

        db.close().ignore();
      },
    );
  });
}
