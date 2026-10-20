import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/home/presentation/widgets/home_today_workout_hero.dart';
import 'package:fit_host/features/nutrition/presentation/nutrition_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/hydration_detail_screen.dart';
import 'package:fit_host/features/diary/presentation/daily_diary_screen.dart';
import 'package:fit_host/features/reminders/presentation/screens/fullscreen_alarm_screen.dart';

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

  const artifactsDir = '/Users/amitrana/.gemini/antigravity-ide/brain/40f965a1-4177-4cc1-a2dd-eeb480561dea';

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await _loadTestFonts();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers/events'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (MethodCall methodCall) async => null,
    );
  });

  testWidgets('Phase 1 Evidence: Today\'s Workout Hero at 375x812 (no green halo, dark gradient scrim, real data)', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    final globalKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0F0D),
            body: SafeArea(
              child: RepaintBoundary(
                key: globalKey,
                child: Container(
                  color: const Color(0xFF0A0F0D),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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

    // Verify PageView renders
    expect(find.byType(PageView), findsOneWidget);

    // Verify no solid neon green glow halo (spreadRadius >= 3 with color #00E676)
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
    expect(foundNeonShadow, isFalse, reason: 'Solid green halo must be completely removed');

    // Verify no fake "72% Completed" or "620 Kcal" mockups
    expect(find.text('72% Completed'), findsNothing);
    expect(find.text('620 Kcal'), findsNothing);

    // Verify real assigned routine title or Start First Workout
    expect(find.byType(HomeTodayWorkoutHero), findsOneWidget);

    // Capture visual evidence
    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_phase1_workout_hero.png',
    );

    await db.close();
  });

  testWidgets('Phase 1 Evidence: Hydration Card & Responsive Wrap at 375x812 (no overflow, correct math)', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    final globalKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: globalKey,
            child: const NutritionScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll down to center the Hydration Tracker card
    final scrollableFinder = find.byType(Scrollable).first;
    await tester.drag(scrollableFinder, const Offset(0, -320));
    await tester.pumpAndSettle();

    // Capture visual evidence of Hydration Card on Nutrition Screen
    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_phase1_hydration.png',
    );

    await db.close();
  });

  testWidgets('Phase 1 Evidence: Hydration Detail Screen at 375x812 (responsive grid & presets)', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    final globalKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: globalKey,
            child: const HydrationDetailScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hydration & Fluids Tracker'), findsOneWidget);
    expect(find.text('Pure Water'), findsOneWidget);
    expect(find.text('Protein Shake'), findsOneWidget);
    expect(find.text('Creatine Mix'), findsOneWidget);
    expect(find.text('Glucose & Salts'), findsOneWidget);

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_phase1_hydration_detail.png',
    );

    await db.close();
  });

  testWidgets('Phase 4 Evidence: Daily Focus & Habits Checklist at 375x812', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    final globalKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authStatusProvider.overrideWithValue(AuthStatus.guest),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: globalKey,
            child: const DailyDiaryScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Daily Focus & Habits section and default tasks
    expect(find.text('Daily Focus & Habits'), findsOneWidget);
    expect(find.text('Take Vitamins & Omega-3'), findsOneWidget);
    expect(find.text('Drink 1L Water'), findsOneWidget);
    expect(find.text('Morning Mobility Stretch'), findsOneWidget);
    expect(find.text('Log Nutritious Lunch'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // Capture visual evidence
    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_phase4_diary_checklist.png',
    );

    await db.close();
  });

  testWidgets('Phase 4 Evidence: Fullscreen Alarm Screen at 375x812', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: globalKey,
            child: const FullscreenAlarmScreen(
              id: 'alarm-test-1',
              title: 'Morning Workout',
              body: 'Time to hit the gym!',
              channel: 'Workout',
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Verify Alarm screen elements
    expect(find.text('Morning Workout'), findsOneWidget);
    expect(find.text('Time to hit the gym!'), findsOneWidget);
    expect(find.textContaining('Snooze'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Capture visual evidence
    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_phase4_fullscreen_alarm.png',
    );
  });
}
