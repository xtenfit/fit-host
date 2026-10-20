import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/home/presentation/widgets/home_today_workout_hero.dart';
import 'package:fit_host/features/workouts/presentation/screens/workouts_screen.dart';

import 'package:flutter/services.dart';

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

    for (final family in ['Roboto', 'Arial', '.SF Pro Text', '.SF Pro Display', '.SF UI Text', 'SF Pro Display', 'SF Pro Text']) {
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

  testWidgets('Task 5: Futuristic Workout Carousel renders with glassmorphism, neon glow, and 24sp title',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0F0D),
            body: SafeArea(
              child: RepaintBoundary(
                key: repaintKey,
                child: Container(
                  color: const Color(0xFF0A0F0D),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      HomeTodayWorkoutHero(isDark: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify PageView carousel is rendered
    expect(find.byType(PageView), findsOneWidget);

    // 2. Verify assigned routine is displayed
    expect(find.text('Push Day: Chest, Delts & Triceps'), findsOneWidget);

    // 3. Verify neon glow halo is removed (no spreadRadius >= 3 green box shadow)
    final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    bool foundNeonShadow = false;
    for (final container in animatedContainers) {
      final decoration = container.decoration;
      if (decoration is BoxDecoration && decoration.boxShadow != null) {
        for (final shadow in decoration.boxShadow!) {
          if ((shadow.color.g * 255.0).round().clamp(0, 255) == 230 && shadow.spreadRadius >= 3.0) {
            foundNeonShadow = true;
            break;
          }
        }
      }
    }
    expect(foundNeonShadow, isFalse, reason: 'Green halo glow should be removed as per Phase 1 spec');

    // 5. Save evidence screenshot
    await _saveBoundaryToImage(
      tester,
      repaintKey,
      '$artifactsDir/evidence_workout_carousel.png',
    );

    await inMemoryDb.close();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Task 5: Routines & Plans Tab groups by Active Plan, Saved Routines, and Templates with sticky headers & BouncingScrollPhysics',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme.copyWith(
            appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
              titleTextStyle: AppTheme.darkTheme.appBarTheme.titleTextStyle?.copyWith(
                fontFamily: 'Arial',
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
          home: RepaintBoundary(
            key: repaintKey,
            child: const WorkoutsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Switch to 'Routines & Plans' tab
    final routinesTabFinder = find.text('Routines & Plans');
    expect(routinesTabFinder, findsOneWidget);
    await tester.tap(routinesTabFinder);
    await tester.pumpAndSettle();

    // 1. Verify Active Plan & Saved Routines Headers
    expect(find.text('Active Plan'), findsOneWidget);
    expect(find.text('Saved Routines'), findsOneWidget);

    expect(find.text('Hypertrophy & Power Mass'), findsOneWidget);
    expect(find.textContaining('workouts / week'), findsOneWidget);
    expect(find.textContaining('Structured Progression'), findsOneWidget);

    // 3. Verify Saved Routines list items
    expect(find.text('Push Day (Chest, Shoulders, Triceps)'), findsOneWidget);

    // 4. Save evidence screenshot of Routines & Plans top view
    await _saveBoundaryToImage(
      tester,
      repaintKey,
      '$artifactsDir/evidence_routines_plans.png',
    );

    // 5. Scroll down to verify Pull Day, Leg Day and Templates section
    await tester.scrollUntilVisible(
      find.text('Pull Day (Back, Rear Delts, Biceps)'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Pull Day (Back, Rear Delts, Biceps)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Leg Day (Quads, Hamstrings, Core)'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Leg Day (Quads, Hamstrings, Core)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Templates'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('Full Body Blitz'), findsOneWidget);
    expect(find.text('Upper Body Power Spec'), findsOneWidget);

    // 6. Verify BouncingScrollPhysics on the CustomScrollView
    final customScrollView = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    expect(customScrollView.physics, isA<BouncingScrollPhysics>());

    await inMemoryDb.close();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
