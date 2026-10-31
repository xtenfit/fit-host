import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/workouts/presentation/widgets/exercise_picker_sheet.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  final mockExercises = [
    ExerciseEntity(
      id: 'ex_bench_press',
      name: 'Barbell Bench Press',
      category: 'Chest',
      targetMuscle: 'Pectoralis Major',
      instructions: 'Lie on bench and press barbell up.',
      equipment: 'Barbell',
      exerciseType: 'Strength',
      movementType: 'Compound',
      difficultyLevel: 'Intermediate',
      createdAt: DateTime(2026, 1, 1),
    ),
    ExerciseEntity(
      id: 'ex_incline_dumbbell',
      name: 'Incline Dumbbell Press',
      category: 'Chest',
      targetMuscle: 'Upper Chest',
      instructions: 'Set bench to 30 degrees and press dumbbells.',
      equipment: 'Dumbbells',
      exerciseType: 'Strength',
      movementType: 'Compound',
      difficultyLevel: 'Intermediate',
      createdAt: DateTime(2026, 1, 1),
    ),
    ExerciseEntity(
      id: 'ex_pullup',
      name: 'Pull-up',
      category: 'Back',
      targetMuscle: 'Latissimus Dorsi',
      instructions: 'Grip bar and pull chin above bar.',
      equipment: 'Pull-up Bar',
      exerciseType: 'Strength',
      movementType: 'Compound',
      difficultyLevel: 'Advanced',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  Widget buildTestWidget({
    ValueChanged<List<ExerciseEntity>>? onExercisesSelected,
    ValueChanged<ExerciseEntity>? onExerciseSelected,
    List<String>? initiallySelectedExerciseIds,
  }) {
    return ProviderScope(
      overrides: [
        exercisesListProvider.overrideWith((ref) async => mockExercises),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ExercisePickerSheet(
            onExercisesSelected: onExercisesSelected,
            onExerciseSelected: onExerciseSelected,
            initiallySelectedExerciseIds: initiallySelectedExerciseIds,
          ),
        ),
      ),
    );
  }

  group('ExercisePickerSheet Multi-Select & UX Redesign Widget Tests', () {
    testWidgets(
      'Renders exercise cards with full names, targets, and category icons',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(onExercisesSelected: (_) {}));
        await tester.pumpAndSettle();

        expect(find.text('Select Exercises'), findsOneWidget);
        expect(find.text('Barbell Bench Press'), findsOneWidget);
        expect(find.text('Incline Dumbbell Press'), findsOneWidget);
        expect(find.text('Pull-up'), findsOneWidget);
        expect(find.textContaining('Pectoralis Major'), findsOneWidget);
      },
    );

    testWidgets(
      'Multi-select toggling updates count and shows sticky bottom confirmation bar',
      (tester) async {
        List<ExerciseEntity> selected = [];

        await tester.pumpWidget(
          buildTestWidget(
            onExercisesSelected: (list) {
              selected = list;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Initially no exercises selected; bottom bar shows disabled 'Select Exercises to Add'
        expect(find.text('Select Exercises to Add'), findsOneWidget);

        // Tap on first exercise card (Barbell Bench Press)
        await tester.tap(find.text('Barbell Bench Press'));
        await tester.pumpAndSettle();

        // Should now show bottom confirmation bar for 1 exercise
        expect(find.text('Add 1 Exercise'), findsOneWidget);

        // Tap on second exercise card (Incline Dumbbell Press)
        await tester.tap(find.text('Incline Dumbbell Press'));
        await tester.pumpAndSettle();

        // Should now show bottom confirmation bar for 2 exercises
        expect(find.text('Add 2 Exercises'), findsOneWidget);

        // Deselect the first exercise card
        await tester.tap(find.text('Barbell Bench Press'));
        await tester.pumpAndSettle();

        // Should drop back to 1 exercise
        expect(find.text('Add 1 Exercise'), findsOneWidget);

        // Tap confirmation CTA
        await tester.tap(find.text('Add 1 Exercise'));
        await tester.pumpAndSettle();

        // Callback should have received the remaining selected exercise
        expect(selected.length, equals(1));
        expect(selected.first.id, equals('ex_incline_dumbbell'));
      },
    );

    testWidgets('Respects initiallySelectedExerciseIds on load', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          onExercisesSelected: (_) {},
          initiallySelectedExerciseIds: ['ex_pullup'],
        ),
      );
      await tester.pumpAndSettle();

      // Pull-up should already be selected; checkmark badge rendered
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });
  });
}
