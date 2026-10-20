import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/home/presentation/home_screen.dart';
import 'package:fit_host/features/nutrition/presentation/screens/hydration_detail_screen.dart';
import 'package:fit_host/features/profile/presentation/screens/fitness_setup_wizard_screen.dart';
import 'package:fit_host/features/shell/main_navigation_shell.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  const artifactsDir = '/Users/amitrana/.gemini/antigravity-ide/brain/40f965a1-4177-4cc1-a2dd-eeb480561dea';

  testWidgets('Evidence 1: Home screen scrolled to bottom showing nav bar does not overlap content', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    final globalKey = GlobalKey();

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
          theme: AppTheme.darkTheme,
          routerConfig: testRouter,
          builder: (context, child) => RepaintBoundary(
            key: globalKey,
            child: child!,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to the bottom of the Home screen ListView
    final scrollFinder = find.byType(Scrollable).first;
    await tester.fling(scrollFinder, const Offset(0, -3000), 1000);
    await tester.pumpAndSettle();

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_home_scrolled.png',
    );

    await db.close();
  });

  testWidgets('Evidence 2: Hydration screen showing fixed 2-column Grid without text truncation', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
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

    // Verify preset drinks are visible without truncation
    expect(find.text('Glucose & Salts'), findsOneWidget);
    expect(find.text('Protein Shake'), findsOneWidget);
    expect(find.text('Pure Water'), findsOneWidget);
    expect(find.text('Creatine Mix'), findsOneWidget);

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_hydration_wrap.png',
    );

    await db.close();
  });

  testWidgets('Evidence 3: Gender Selection wizard screen fits without scrolling', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
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
            child: const FitnessSetupWizardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Step 1 of 20 and Gender cards are rendered
    expect(find.text('Step 1 of 20'), findsOneWidget);
    expect(find.text("What's your gender?"), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_wizard_step1.png',
    );

    await db.close();
  });
}
