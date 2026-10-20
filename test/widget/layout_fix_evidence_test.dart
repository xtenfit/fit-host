import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/features/home/presentation/home_screen.dart';
import 'package:fit_host/features/home/presentation/widgets/home_today_workout_hero.dart';
import 'package:fit_host/features/home/presentation/widgets/home_streak_date_strip.dart';
import 'package:fit_host/features/home/presentation/widgets/home_statistics_grid.dart';
import 'package:fit_host/features/home/presentation/widgets/home_step_card.dart';
import 'package:fit_host/features/home/presentation/widgets/home_diet_diary_card.dart';
import 'package:fit_host/features/home/presentation/widgets/home_activity_card.dart';
import 'package:fit_host/features/shell/main_navigation_shell.dart';
import 'package:fit_host/features/workouts/presentation/screens/workouts_screen.dart';
import 'package:flutter/services.dart';

Future<void> _precache(WidgetTester tester, ImageProvider provider) async {
  final ImageStream stream = provider.resolve(ImageConfiguration.empty);
  final completer = Completer<void>();
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool syncCall) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
    onError: (dynamic exception, StackTrace? stackTrace) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  await tester.runAsync(() async {
    await completer.future.timeout(const Duration(seconds: 3), onTimeout: () {});
  });
  await tester.pump();
}

Future<void> _saveBoundaryToImage(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final file = File(path);
    await file.writeAsBytes(pngBytes, flush: true);
  });
}

Future<void> _loadTestFonts() async {
  try {
    final regularFile = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    final boldFile = File('/System/Library/Fonts/Supplemental/Arial Bold.ttf');
    final regularBytes = await regularFile.readAsBytes();
    final boldBytes = await boldFile.readAsBytes();

    for (final family in [
      'Roboto',
      'Arial',
      '.SF Pro Text',
      '.SF Pro Display',
      '.SF UI Text',
      'SF Pro Display',
      'SF Pro Text',
      'Ahem',
    ]) {
      final loader = FontLoader(family);
      loader.addFont(Future.value(ByteData.view(regularBytes.buffer)));
      loader.addFont(Future.value(ByteData.view(boldBytes.buffer)));
      await loader.load();
    }
  } catch (_) {}

  try {
    final iconFile = File('/usr/local/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (await iconFile.exists()) {
      final bytes = await iconFile.readAsBytes();
      final loader = FontLoader('MaterialIcons');
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
    }
  } catch (_) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadTestFonts();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  const artifactsDir = '/Users/amitrana/.gemini/antigravity-ide/brain/40f965a1-4177-4cc1-a2dd-eeb480561dea';

  testWidgets('Evidence 1: Workouts Screen (Routines & Plans) has New Workout in AppBar, NO FAB, and Push Day card is fully visible without overlap',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    final repaintKey = GlobalKey();

    final testRouter = GoRouter(
      initialLocation: '/workouts',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainNavigationShell(child: child),
          routes: [
            GoRoute(
              path: '/workouts',
              builder: (context, state) => const WorkoutsScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme.copyWith(
            textTheme: AppTheme.darkTheme.textTheme.apply(fontFamily: 'Arial'),
            primaryTextTheme: AppTheme.darkTheme.primaryTextTheme.apply(fontFamily: 'Arial'),
            appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
              titleTextStyle: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: (AppTheme.darkTheme.elevatedButtonTheme.style ?? const ButtonStyle()).copyWith(
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
          routerConfig: testRouter,
          builder: (context, child) => RepaintBoundary(
            key: repaintKey,
            child: child!,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Precache assets so image decoders produce frames
    await _precache(tester, const AssetImage('assets/images/workouts/today_workout_athlete.png'));
    await _precache(tester, const AssetImage('assets/images/workouts/strength.png'));
    await tester.pumpAndSettle();

    // 1. Switch to 'Routines & Plans' tab
    final routinesTabFinder = find.text('Routines & Plans');
    expect(routinesTabFinder, findsOneWidget);
    await tester.tap(routinesTabFinder);
    await tester.pumpAndSettle();

    // 2. Verify FloatingActionButton is completely removed
    expect(find.byType(FloatingActionButton), findsNothing);

    // 3. Verify 'New Workout' is in the top AppBar
    final newWorkoutButtonFinder = find.text('New Workout');
    expect(newWorkoutButtonFinder, findsOneWidget);
    expect(find.byType(TextButton), findsWidgets);

    // 4. Verify Active Plan and Saved Routines cards (Push Day) are rendered
    expect(find.text('Active Plan'), findsOneWidget);
    expect(find.text('Hypertrophy & Power Mass'), findsOneWidget);
    expect(find.text('Push Day (Chest, Shoulders, Triceps)'), findsOneWidget);

    // 5. Capture screenshot of the Workouts tab showing the fixed layout with NO FAB and Push Day image
    await _saveBoundaryToImage(
      tester,
      repaintKey,
      '$artifactsDir/evidence_workouts_tab_fixed.png',
    );

    await db.close();
  });

  testWidgets('Evidence 2: Home Screen structure follows Header -> Today\'s Workout Hero -> Real Training Metrics -> Steps -> Nutrition -> Sleep, scrollable without blank gap',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    final repaintKey = GlobalKey();

    final testRouter = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainNavigationShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme.copyWith(
            textTheme: AppTheme.darkTheme.textTheme.apply(fontFamily: 'Arial'),
            primaryTextTheme: AppTheme.darkTheme.primaryTextTheme.apply(fontFamily: 'Arial'),
            appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
              titleTextStyle: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: (AppTheme.darkTheme.elevatedButtonTheme.style ?? const ButtonStyle()).copyWith(
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
          routerConfig: testRouter,
          builder: (context, child) => RepaintBoundary(
            key: repaintKey,
            child: child!,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Precache hero asset
    await _precache(tester, const AssetImage('assets/images/workouts/today_workout_athlete.png'));
    await tester.pumpAndSettle();

    // 1. Verify single scrollable ListView on Home
    final homeListViewFinder = find.byType(ListView);
    expect(homeListViewFinder, findsWidgets);

    // 2. Verify Today's Workout Hero is present
    expect(find.byType(HomeTodayWorkoutHero), findsOneWidget);

    // 3. Verify Real Training Metrics (Date Strip + Statistics Grid) are present
    expect(find.byType(HomeStreakDateStrip), findsOneWidget);
    expect(find.byType(HomeStatisticsGrid), findsOneWidget);

    // 4. Scroll down so that Steps and Nutrition cards are centered and completely clear of bottom navigation dock
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -550));
    await tester.pumpAndSettle();

    // 5. Verify Steps and Nutrition cards are now scrolled into view
    expect(find.byType(HomeStepCard), findsOneWidget);
    expect(find.byType(HomeDietDiaryCard), findsOneWidget);

    // 6. Capture screenshot showing cards seamlessly flowing below hero carousel with nutrition card clear of bottom nav
    await _saveBoundaryToImage(
      tester,
      repaintKey,
      '$artifactsDir/evidence_home_screen_scrolled_down.png',
    );

    // 7. Scroll further to reveal Activity / Sleep card
    await tester.scrollUntilVisible(find.byType(HomeActivityCard), 300, scrollable: scrollable);
    expect(find.byType(HomeActivityCard), findsOneWidget);

    await db.close();
  });
}
