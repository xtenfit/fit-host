import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/onboarding/presentation/widgets/animated_gender_selector.dart';
import 'package:fit_host/features/onboarding/presentation/widgets/plan_summary_reveal_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimatedGenderSelector Widget Tests', () {
    testWidgets('Renders all gender options and switches correctly', (
      WidgetTester tester,
    ) async {
      String? selectedGender = 'male';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedGenderSelector(
                  selectedGender: selectedGender,
                  onGenderSelected: (gender) {
                    setState(() {
                      selectedGender = gender;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify pill labels are rendered
      expect(find.text('Male'), findsWidgets);
      expect(find.text('Female'), findsWidgets);
      expect(find.text('Prefer not to say'), findsOneWidget);

      // Verify initial selected state
      expect(selectedGender, 'male');

      // Tap Female option pill
      await tester.tap(find.text('Female').first);
      await tester.pumpAndSettle();

      // Verify state updated
      expect(selectedGender, 'female');

      // Tap Prefer not to say
      await tester.tap(find.text('Prefer not to say'));
      await tester.pumpAndSettle();

      expect(selectedGender, 'prefer_not_to_say');
    });

    testWidgets('Handles null initial selection gracefully', (
      WidgetTester tester,
    ) async {
      String? selectedGender;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedGenderSelector(
              selectedGender: selectedGender,
              onGenderSelected: (gender) => selectedGender = gender,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Male'), findsWidgets);
      expect(find.text('Female'), findsWidgets);
    });
  });

  group('PlanSummaryRevealCard Widget Tests', () {
    testWidgets('Renders personalized data, hero card, badge, and stat tiles', (
      WidgetTester tester,
    ) async {
      bool startPressed = false;
      bool homePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanSummaryRevealCard(
              planTitle: 'FULL BODY SHRED',
              dailyTime: '20 Min',
              experienceLevel: 'Beginner',
              targetArea: 'Full Body',
              equipment: 'No Equipment',
              gender: 'male',
              onStart: () => startPressed = true,
              onGoToHome: () => homePressed = true,
              showActionButtons: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Your plan is ready!'), findsOneWidget);
      expect(
        find.text('We have selected this plan that suits you best'),
        findsOneWidget,
      );

      // Verify Hero Badge and Title
      expect(find.text('CUSTOMIZED FOR YOU'), findsOneWidget);
      expect(find.text('FULL BODY SHRED'), findsOneWidget);

      // Verify 4 Stat Tiles
      expect(find.text('20 Min'), findsOneWidget);
      expect(find.text('Daily Time'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);
      expect(find.text('Target area'), findsOneWidget);
      expect(find.text('No Equipment'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);

      // Verify Actions
      expect(find.text('START NOW'), findsOneWidget);
      expect(find.text('Go to homepage'), findsOneWidget);

      // Tap actions
      await tester.ensureVisible(find.text('START NOW'));
      await tester.tap(find.text('START NOW'));
      await tester.pump();
      expect(startPressed, isTrue);

      await tester.ensureVisible(find.text('Go to homepage'));
      await tester.tap(find.text('Go to homepage'));
      await tester.pump();
      expect(homePressed, isTrue);
    });

    testWidgets(
      'Respects showActionButtons: false to hide start and home buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PlanSummaryRevealCard(
                planTitle: 'HYPERTROPHY BUILDER',
                dailyTime: '45 Min',
                experienceLevel: 'Intermediate',
                targetArea: 'Chest & Arms',
                equipment: 'Full Gym',
                gender: 'female',
                showActionButtons: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify title & stats exist
        expect(find.text('HYPERTROPHY BUILDER'), findsOneWidget);
        expect(find.text('45 Min'), findsOneWidget);

        // Verify action buttons are suppressed
        expect(find.text('START NOW'), findsNothing);
        expect(find.text('Go to homepage'), findsNothing);
      },
    );

    testWidgets('Displays fallback values gracefully when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlanSummaryRevealCard(
              planTitle: '',
              dailyTime: '15 Min',
              experienceLevel: '',
              targetArea: '',
              equipment: '',
              showActionButtons: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your plan is ready!'), findsOneWidget);
      expect(find.text('CUSTOMIZED FOR YOU'), findsOneWidget);
      expect(find.text('START NOW'), findsOneWidget);
    });
  });
}
