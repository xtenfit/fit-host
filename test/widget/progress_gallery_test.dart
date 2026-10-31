import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/progress/domain/models/body_measurement.dart';
import 'package:fit_host/features/progress/domain/models/progress_photo.dart';
import 'package:fit_host/features/progress/presentation/controllers/progress_providers.dart';
import 'package:fit_host/features/progress/presentation/screens/body_measurements_screen.dart';
import 'package:fit_host/features/progress/presentation/screens/progress_gallery_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Part 4: BodyMeasurementsScreen & ProgressGalleryScreen Widget Tests', () {
    testWidgets(
      'BodyMeasurementsScreen displays empty state and opens LogMeasurementSheet',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: BodyMeasurementsScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify Empty State is shown
        expect(find.text('No Measurements Logged'), findsOneWidget);
        expect(find.text('Log First Measurement'), findsOneWidget);

        // Tap to open sheet
        await tester.tap(find.text('Log First Measurement'));
        await tester.pumpAndSettle();

        // Verify sheet inputs
        expect(find.text('Record Measurements'), findsOneWidget);
        expect(find.text('Primary Metrics'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Save Measurement'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Save Measurement'), findsOneWidget);
      },
    );

    testWidgets(
      'BodyMeasurementsScreen displays populated history and delta card',
      (WidgetTester tester) async {
        final m1 = BodyMeasurement(
          id: 'm_widget_1',
          userId: 'guest',
          measuredAt: DateTime(2026, 1, 1),
          weightKg: 85.0,
          waistCm: 90.0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
        final m2 = BodyMeasurement(
          id: 'm_widget_2',
          userId: 'guest',
          measuredAt: DateTime(2026, 2, 1),
          weightKg: 82.0,
          waistCm: 86.0,
          createdAt: DateTime(2026, 2, 1),
          updatedAt: DateTime(2026, 2, 1),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            bodyMeasurementsStreamProvider.overrideWith(
              (ref) => Stream.value([m2, m1]),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: BodyMeasurementsScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify Transformation summary hero card
        expect(find.text('Transformation Summary'), findsOneWidget);
        expect(find.text('Current Status'), findsOneWidget);
        expect(find.text('Measurement History'), findsOneWidget);
        expect(find.text('2 logs'), findsOneWidget);
        expect(find.text('82.0 kg'), findsWidgets);
      },
    );

    testWidgets(
      'ProgressGalleryScreen displays pose tabs and opens Before & After sheet',
      (WidgetTester tester) async {
        final p1 = ProgressPhoto(
          id: 'p_w_1',
          userId: 'guest',
          takenAt: DateTime(2026, 1, 1),
          photoPath: '/mock/p1.jpg',
          poseType: PhotoPoseType.front,
          weightKgAtPhoto: 85.0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
        final p2 = ProgressPhoto(
          id: 'p_w_2',
          userId: 'guest',
          takenAt: DateTime(2026, 3, 1),
          photoPath: '/mock/p2.jpg',
          poseType: PhotoPoseType.front,
          weightKgAtPhoto: 80.0,
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            allProgressPhotosStreamProvider.overrideWith(
              (ref) => Stream.value([p2, p1]),
            ),
            progressPhotosStreamProvider.overrideWith(
              (ref, pose) => Stream.value([p2, p1]),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProgressGalleryScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify title & tabs
        expect(find.text('Progress Photo Gallery'), findsOneWidget);
        expect(find.text('All Poses'), findsOneWidget);
        expect(find.text('Front'), findsOneWidget);
        expect(find.text('Side Profile'), findsOneWidget);

        // Verify photo weight badges
        expect(find.text('80.0 kg'), findsOneWidget);

        // Tap Before & After comparison icon in AppBar
        final compareBtn = find.byTooltip('Before & After Compare');
        expect(compareBtn, findsOneWidget);
        await tester.tap(compareBtn);
        await tester.pumpAndSettle();

        // Verify Comparison Sheet opened
        expect(find.text('Side-by-Side Transformation'), findsOneWidget);
        expect(find.text('BEFORE'), findsOneWidget);
        expect(find.text('AFTER'), findsOneWidget);
        expect(find.text('Elapsed Time'), findsOneWidget);
        expect(find.text('59 Days'), findsOneWidget);
        expect(find.text('-5.0 kg'), findsOneWidget);
      },
    );
  });
}
