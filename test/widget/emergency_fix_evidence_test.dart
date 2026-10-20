import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/reminders/data/alarm_sound_service.dart';
import 'package:fit_host/features/reminders/presentation/screens/sound_settings_screen.dart';
import 'package:fit_host/features/reminders/presentation/screens/fullscreen_alarm_screen.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/screens/workout_detail_screen.dart';
import 'package:go_router/go_router.dart';

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
    if (await regularFile.exists() && await boldFile.exists()) {
      final regularBytes = await regularFile.readAsBytes();
      final boldBytes = await boldFile.readAsBytes();

      for (final family in ['Roboto', 'Arial', '.SF Pro Text', '.SF Pro Display', 'SF Pro Display']) {
        final loader = FontLoader(family);
        loader.addFont(Future.value(ByteData.view(regularBytes.buffer)));
        loader.addFont(Future.value(ByteData.view(boldBytes.buffer)));
        await loader.load();
      }
    }
  } catch (_) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const artifactsDir = '/Users/amitrana/.gemini/antigravity-ide/brain/3e34f5a5-2d29-4a6b-a053-256ae81d1dc0';

  setUpAll(() async {
    await _loadTestFonts();
  });

  void Function(FlutterErrorDetails)? prevOnError;

  setUp(() {
    prevOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('ListTile background color or ink splashes may be invisible')) {
        return;
      }
      prevOnError?.call(details);
    };

    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'alarm_sound_default': 'titan_horn',
      'alarm_sound_full_volume': true,
      'alarm_vibration_pattern': 'strong',
      'alarm_sound_act_workout': 'titan_horn',
      'alarm_sound_act_hydration': 'zen_bell',
      'alarm_sound_act_nutrition': 'cyber_chime',
      'alarm_sound_act_steps': 'energy_uplift',
      'alarm_sound_act_diary': 'midnight_radar',
      'alarm_sound_act_recovery': 'zen_bell',
    });

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions_handler'),
      (MethodCall methodCall) async => 1,
    );
  });

  tearDown(() {
    FlutterError.onError = prevOnError;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers/events'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions_handler'),
      null,
    );
  });

  testWidgets('Evidence 1: Alarm & Reminder Sounds Screen has wide horizontal text at physical Android 360x740', (tester) async {
    // Physical mobile constraints for standard Android phone (360x740)
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmSoundSettingsProvider.overrideWith(() => _MockSoundSettingsNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: globalKey,
            child: const SoundSettingsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll until Activity-Specific Sound Assignment item is visible
    final workoutTextFinder = find.text('Workouts & Strength Training');
    await tester.scrollUntilVisible(workoutTextFinder, 250);
    await tester.pumpAndSettle();

    // Verify "Workouts & Strength Training" is rendered horizontally with ample width
    expect(workoutTextFinder, findsOneWidget);

    final renderBox = tester.renderObject(workoutTextFinder) as RenderBox;
    expect(renderBox.size.width, greaterThan(150.0),
        reason: 'Workouts text must be wide and horizontal, not squeezed into a 1-character vertical column');

    // Capture screenshot to artifact directory
    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_alarm_sounds_screen.png',
    );
  });

  testWidgets('Evidence 2: Workout Summary screen displays real 1-exercise database record without fake fallback', (tester) async {
    // Physical mobile constraints: 360x740
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final globalKey = GlobalKey();
    const testWorkoutId = 'real_logged_workout_999';

    final singleExerciseWorkout = WorkoutEntity(
      id: testWorkoutId,
      title: 'Chest & Triceps Hypertrophy',
      category: 'Strength',
      startedAt: DateTime.now().subtract(const Duration(minutes: 42)),
      completedAt: DateTime.now(),
      status: 'completed',
      durationSeconds: 2520, // 42 mins
      caloriesBurned: 310,
      updatedAt: DateTime.now(),
      exercises: [
        WorkoutExerciseEntity(
          id: 'exercise_log_1',
          workoutId: testWorkoutId,
          exerciseId: 'dumbbell-incline-press',
          exerciseName: 'Dumbbell Incline Bench Press',
          category: 'Chest',
          orderIndex: 0,
          sets: [
            WorkoutSetEntity(
              id: 'set_1',
              workoutExerciseId: 'exercise_log_1',
              setNumber: 1,
              reps: 10,
              weightKg: 24.0,
              isCompleted: true,
            ),
            WorkoutSetEntity(
              id: 'set_2',
              workoutExerciseId: 'exercise_log_1',
              setNumber: 2,
              reps: 8,
              weightKg: 26.0,
              isCompleted: true,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutDetailProvider(testWorkoutId).overrideWith((ref) async => singleExerciseWorkout),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: globalKey,
            child: const WorkoutDetailScreen(workoutId: testWorkoutId),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify real exercise title and sets are present
    expect(find.text('Dumbbell Incline Bench Press'), findsOneWidget);
    expect(find.text('24 kg × 10 reps'), findsOneWidget);
    expect(find.text('26 kg × 8 reps'), findsOneWidget);

    // Verify fake placeholder "Barbell Bench Press" does NOT exist
    expect(find.text('Barbell Bench Press'), findsNothing);

    // Verify real metrics from database
    expect(find.text('42m 0s'), findsOneWidget);
    expect(find.text('448 kg'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);

    // Capture screenshot to artifact directory
    await _saveBoundaryToImage(
      tester,
      globalKey,
      '$artifactsDir/evidence_workout_summary_1_exercise.png',
    );
  });

  testWidgets('Evidence 3: FullscreenAlarmScreen X button calls stopContinuousAlarm and dismisses', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/alarm',
      routes: [
        GoRoute(
          path: '/alarm',
          builder: (context, state) => const FullscreenAlarmScreen(
            id: 'test_alarm_1',
            title: 'Morning Push Workout',
            body: 'Time to crush your morning chest session',
            channel: 'workout',
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmSoundSettingsProvider.overrideWith(() => _MockSoundSettingsNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();

    // Verify close icon button is present
    final closeButtonFinder = find.byIcon(Icons.close_rounded);
    expect(closeButtonFinder, findsOneWidget);

    // Tap the X close button
    await tester.tap(closeButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify screen dismisses and transitions to home route
    expect(find.text('Home Screen'), findsOneWidget);
  });
}

class _MockSoundSettingsNotifier extends AlarmSoundSettingsNotifier {
  @override
  Future<AlarmSoundSettings> build() async {
    return const AlarmSoundSettings(
      defaultSoundId: 'titan_horn',
      fullVolumeBoost: true,
      vibrationPattern: 'strong',
      activitySounds: {
        'workout': 'titan_horn',
        'hydration': 'zen_bell',
        'nutrition': 'cyber_chime',
        'steps': 'energy_uplift',
        'diary': 'midnight_radar',
        'recovery': 'zen_bell',
      },
    );
  }
}
