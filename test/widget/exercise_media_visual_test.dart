import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/workouts/presentation/widgets/exercise_media_visual.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExerciseMediaVisual Widget Tests', () {
    testWidgets('Thumbnail mode renders fallback icon when urls are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseMediaVisual(
              mediaThumbnailUrl: null,
              mediaAnimationUrl: null,
              category: 'Chest',
              exerciseName: 'Bench Press',
              mode: ExerciseMediaVisualMode.thumbnail,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets(
      'Player mode renders badge, play/pause controls, and action buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ExerciseMediaVisual(
                mediaAnimationUrl: 'videos/0001-2gPfomN.gif',
                mediaThumbnailUrl: 'images/0001-2gPfomN.jpg',
                category: 'Core',
                exerciseName: '3/4 Sit-Up',
                mode: ExerciseMediaVisualMode.player,
                showBadge: true,
              ),
            ),
          ),
        );
        await tester.pump();

        // Check badge presence
        expect(find.text('ANIMATED FORM'), findsOneWidget);

        // Check play/pause toggle button
        expect(find.byIcon(Icons.pause_circle_outline_rounded), findsOneWidget);

        // Check fullscreen button
        expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);

        // Tap pause button
        await tester.tap(find.byIcon(Icons.pause_circle_outline_rounded));
        await tester.pump();

        // After pause, state displays PAUSED
        expect(find.text('PAUSED'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
      },
    );

    testWidgets('Anatomy toggle switches view when anatomyAsset is supplied', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExerciseMediaVisual(
              mediaAnimationUrl: 'videos/0001-2gPfomN.gif',
              anatomyAsset: 'assets/images/setup/female_model.png',
              category: 'Back',
              exerciseName: 'Lat Pulldown',
              mode: ExerciseMediaVisualMode.player,
            ),
          ),
        ),
      );
      await tester.pump();

      // Check anatomy toggle icon is visible
      expect(find.byIcon(Icons.accessibility_rounded), findsOneWidget);

      // Tap anatomy toggle
      await tester.tap(find.byIcon(Icons.accessibility_rounded));
      await tester.pump();

      // Verify badge switches to ANATOMY
      expect(find.text('ANATOMY'), findsOneWidget);
    });
  });
}
