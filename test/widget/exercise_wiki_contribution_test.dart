import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/theme/app_theme.dart';
import 'package:fit_host/features/workouts/data/repositories/exercise_submission_repository_impl.dart';
import 'package:fit_host/features/workouts/domain/models/exercise_submission.dart';
import 'package:fit_host/features/workouts/presentation/screens/exercise_wiki_screen.dart';
import 'package:fit_host/features/workouts/presentation/widgets/exercise_contribution_sheet.dart';

void main() {
  group('Exercise Wiki & Contribution Widget Tests', () {
    late AppDatabase memoryDb;
    late ExerciseSubmissionRepositoryImpl repo;

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      repo = ExerciseSubmissionRepositoryImpl(memoryDb);
    });

    tearDown(() async {
      await memoryDb.close();
    });

    testWidgets(
      'ExerciseWikiScreen renders standards tab and switches to my submissions tab',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(memoryDb),
              exerciseSubmissionRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const ExerciseWikiScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Header and Governance information
        expect(find.text('Exercise Wiki & Community'), findsOneWidget);
        expect(find.text('Fit Host Verification Standards'), findsOneWidget);
        expect(find.text('1. Biomechanical Safety First'), findsOneWidget);
        expect(find.text('2. Strict Copyright & Attribution'), findsOneWidget);

        // Drag ListView to reveal pillar 3
        await tester.drag(find.byType(ListView).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(
          find.text('3. Universal Non-Stereotyped Classification'),
          findsOneWidget,
        );

        // Drag back up to ensure tab bar is accessible
        await tester.drag(find.byType(ListView).first, const Offset(0, 200));
        await tester.pumpAndSettle();
        expect(find.text('Propose Exercise'), findsOneWidget);

        // Switch to My Submissions tab
        final submissionsTab = find.text('My Submissions');
        expect(submissionsTab, findsOneWidget);
        await tester.tap(submissionsTab);
        await tester.pumpAndSettle();

        // Verify empty state
        expect(find.text('No contributions submitted yet'), findsOneWidget);

        // Cleanly unmount to drain query stream timers
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'ExerciseContributionSheet validates required fields and submits successfully',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(memoryDb),
              exerciseSubmissionRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(body: ExerciseContributionSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Propose Community Exercise'), findsOneWidget);
        expect(find.text('Fit Host Wiki Moderation Policy'), findsOneWidget);

        // Attempt submit without filling required name
        final submitButton = find.text('Submit Exercise for Review');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Verify validation error
        expect(find.text('Exercise name is required'), findsOneWidget);

        // Fill valid information
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Exercise Name *'),
          'Barbell Hip Thrust',
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Instructions & Form Guidance *'),
          'Sit on ground with back against bench. Place loaded barbell across hips. Drive through heels to full hip extension.',
        );
        await tester.pumpAndSettle();

        // Submit valid form
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Cleanly unmount
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));

        // Verify stored in repository with pending status
        final userSubs = await repo.getMySubmissions(userId: 'guest');
        expect(userSubs.length, equals(1));
        expect(userSubs.first.name, equals('Barbell Hip Thrust'));
        expect(userSubs.first.status, equals(ModerationStatus.pending));
      },
    );
  });
}
