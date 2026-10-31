import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/onboarding/presentation/widgets/animated_gender_selector.dart';
import 'package:fit_host/features/onboarding/presentation/widgets/plan_summary_reveal_card.dart';
import 'package:fit_host/features/workouts/presentation/widgets/exercise_media_visual.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _saveBoundaryToImage(
  WidgetTester tester,
  GlobalKey key,
  String path,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final file = File(path);
    await file.writeAsBytes(pngBytes, flush: true);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers'),
          (MethodCall methodCall) async => 1,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global'),
          (MethodCall methodCall) async => 1,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers/events'),
          (MethodCall methodCall) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global/events'),
          (MethodCall methodCall) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('xyz.luan/audioplayers/events'),
          MockStreamHandler.inline(
            onListen: (args, sink) {},
            onCancel: (args) {},
          ),
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('xyz.luan/audioplayers.global/events'),
          MockStreamHandler.inline(
            onListen: (args, sink) {},
            onCancel: (args) {},
          ),
        );
  });

  const artifactsDir =
      '/Users/amitrana/.gemini/antigravity-ide/brain/d701eba8-c58e-4db0-9107-ae19e3e24c0e';

  testWidgets('Evidence: Step 1 Animated Gender Selection (Male selected)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0F0D),
          body: SafeArea(
            child: RepaintBoundary(
              key: globalKey,
              child: Column(
                children: [
                  // Top Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00E676,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00E676,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                'Step 1 of 20',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8FA396),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.05,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E676),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedGenderSelector(
                      selectedGender: 'male',
                      onGenderSelected: (_) {},
                      heading: "What's your gender?",
                      subtitle: 'Let us know you better',
                      showPreferNotToSay: true,
                      isDark: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_onboarding_step1_male.png',
    );
  });

  testWidgets('Evidence: Step 1 Animated Gender Selection (Female selected)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0F0D),
          body: SafeArea(
            child: RepaintBoundary(
              key: globalKey,
              child: Column(
                children: [
                  // Top Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00E676,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00E676,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                'Step 1 of 20',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8FA396),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.05,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E676),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedGenderSelector(
                      selectedGender: 'female',
                      onGenderSelected: (_) {},
                      heading: "What's your gender?",
                      subtitle: 'Let us know you better',
                      showPreferNotToSay: true,
                      isDark: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_onboarding_step1_female.png',
    );
  });

  testWidgets('Evidence: Final Step Personalized Plan Reveal Screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0F0D),
          body: SafeArea(
            child: RepaintBoundary(
              key: globalKey,
              child: PlanSummaryRevealCard(
                planTitle: 'Full Body Shred',
                dailyTime: '45 Min',
                experienceLevel: 'Intermediate',
                targetArea: 'Full Body',
                equipment: 'Full Gym',
                gender: 'male',
                onStart: () {},
                onGoToHome: () {},
                showActionButtons: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_onboarding_final_plan.png',
    );
  });

  testWidgets(
    'Evidence: Exercise Media Visual Player with Dataset GIF and Anatomy',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final globalKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0F0D),
            body: SafeArea(
              child: RepaintBoundary(
                key: globalKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exercise Visual Player (exercises-dataset & wger)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ExerciseMediaVisual(
                        mediaAnimationUrl: 'videos/0001-2gPfomN.gif',
                        mediaThumbnailUrl: 'images/0001-2gPfomN.jpg',
                        anatomyAsset: 'assets/images/setup/male_model.png',
                        category: 'Core',
                        exerciseName: '3/4 Sit-Up',
                        mode: ExerciseMediaVisualMode.player,
                        height: 220,
                        isDark: true,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Exercise Picker Thumbnails',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          ExerciseMediaVisual(
                            mediaThumbnailUrl: 'images/0001-2gPfomN.jpg',
                            category: 'Core',
                            exerciseName: '3/4 Sit-Up',
                            mode: ExerciseMediaVisualMode.thumbnail,
                            width: 52,
                            height: 52,
                          ),
                          SizedBox(width: 12),
                          ExerciseMediaVisual(
                            mediaThumbnailUrl: 'images/0025-EIeI8Vf.jpg',
                            category: 'Chest',
                            exerciseName: 'Barbell Bench Press',
                            mode: ExerciseMediaVisualMode.thumbnail,
                            width: 52,
                            height: 52,
                          ),
                          SizedBox(width: 12),
                          ExerciseMediaVisual(
                            mediaThumbnailUrl: 'images/0043-qXTaZnJ.jpg',
                            category: 'Legs',
                            exerciseName: 'Barbell Squat',
                            mode: ExerciseMediaVisualMode.thumbnail,
                            width: 52,
                            height: 52,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await _saveBoundaryToImage(
        tester,
        globalKey,
        '$artifactsDir/evidence_exercise_visuals.png',
      );
    },
  );
}
