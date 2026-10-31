import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/progress/domain/models/body_measurement.dart';
import 'package:fit_host/features/progress/domain/models/progress_photo.dart';
import 'package:fit_host/features/progress/domain/models/measurement_delta.dart';
import 'package:fit_host/features/progress/data/repositories/body_measurement_repository_impl.dart';

void main() {
  group('Part 4: Body Measurements & Progress Delta Unit Tests', () {
    test(
      'MeasurementProgressDelta computes accurate differences between two check-ins',
      () {
        final baseline = BodyMeasurement(
          id: 'meas_1',
          userId: 'user_1',
          measuredAt: DateTime(2026, 1, 1),
          weightKg: 85.0,
          bodyFatPercentage: 22.0,
          waistCm: 92.0,
          chestCm: 104.0,
          hipsCm: 100.0,
          armsCm: 36.0,
          thighsCm: 60.0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        final latest = BodyMeasurement(
          id: 'meas_2',
          userId: 'user_1',
          measuredAt: DateTime(2026, 3, 1),
          weightKg: 81.5,
          bodyFatPercentage: 18.5,
          waistCm: 87.0,
          chestCm: 106.0,
          hipsCm: 97.0,
          armsCm: 37.5,
          thighsCm: 59.0,
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
        );

        final delta = MeasurementProgressDelta(
          baseline: baseline,
          latest: latest,
        );

        expect(delta.elapsedDays, equals(59));
        expect(delta.weightDeltaKg, closeTo(-3.5, 0.01));
        expect(delta.bodyFatDelta, closeTo(-3.5, 0.01));
        expect(delta.waistDeltaCm, closeTo(-5.0, 0.01));
        expect(delta.chestDeltaCm, closeTo(2.0, 0.01));
        expect(delta.armsDeltaCm, closeTo(1.5, 0.01));
        // Total circumference delta = waist(-5) + chest(2) + hips(-3) + arms(1.5) + thighs(-1) = -5.5
        expect(delta.totalCircumferenceDeltaCm, closeTo(-5.5, 0.01));
      },
    );

    test('BodyMeasurement JSON serialization handles all fields and nulls', () {
      final now = DateTime.now();
      final measurement = BodyMeasurement(
        id: 'm_test_json',
        userId: 'guest',
        measuredAt: now,
        weightKg: 78.4,
        bodyFatPercentage: 16.2,
        waistCm: 82.0,
        notes: 'Morning fasted',
        createdAt: now,
        updatedAt: now,
      );

      final json = measurement.toJson();
      final restored = BodyMeasurement.fromJson(json);

      expect(restored.id, equals('m_test_json'));
      expect(restored.weightKg, equals(78.4));
      expect(restored.bodyFatPercentage, equals(16.2));
      expect(restored.waistCm, equals(82.0));
      expect(restored.notes, equals('Morning fasted'));
      expect(restored.chestCm, isNull);
    });

    test('ProgressPhoto PhotoPoseType mappings and JSON serialization', () {
      expect(PhotoPoseType.fromString('front'), equals(PhotoPoseType.front));
      expect(PhotoPoseType.fromString('side'), equals(PhotoPoseType.side));
      expect(PhotoPoseType.fromString('back'), equals(PhotoPoseType.back));
      expect(PhotoPoseType.fromString('other'), equals(PhotoPoseType.other));
      expect(PhotoPoseType.fromString('unknown'), equals(PhotoPoseType.other));

      final now = DateTime.now();
      final photo = ProgressPhoto(
        id: 'photo_1',
        userId: 'user_a',
        takenAt: now,
        photoPath: '/mock/path/front.jpg',
        poseType: PhotoPoseType.front,
        weightKgAtPhoto: 76.5,
        notes: 'Post workout pump',
        createdAt: now,
        updatedAt: now,
      );

      final json = photo.toJson();
      final restored = ProgressPhoto.fromJson(json);

      expect(restored.id, equals('photo_1'));
      expect(restored.poseType, equals(PhotoPoseType.front));
      expect(restored.weightKgAtPhoto, equals(76.5));
      expect(restored.photoPath, equals('/mock/path/front.jpg'));
    });
  });

  group('Part 4: Drift SQLite In-Memory Repository & SyncQueue Tests', () {
    late AppDatabase db;
    late BodyMeasurementRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = BodyMeasurementRepositoryImpl(db, userId: 'test_user');
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Records body measurements and retrieves latest measurement descending',
      () async {
        final m1 = BodyMeasurement(
          id: 'm_1',
          userId: 'test_user',
          measuredAt: DateTime(2026, 1, 10),
          weightKg: 80.0,
          waistCm: 88.0,
          createdAt: DateTime(2026, 1, 10),
          updatedAt: DateTime(2026, 1, 10),
        );

        final m2 = BodyMeasurement(
          id: 'm_2',
          userId: 'test_user',
          measuredAt: DateTime(2026, 2, 15),
          weightKg: 78.5,
          waistCm: 85.5,
          createdAt: DateTime(2026, 2, 15),
          updatedAt: DateTime(2026, 2, 15),
        );

        await repository.recordMeasurement(m1);
        await repository.recordMeasurement(m2);

        final all = await repository.getAllMeasurements();
        expect(all.length, equals(2));
        // First item must be latest date (Feb 15)
        expect(all.first.id, equals('m_2'));
        expect(all.first.weightKg, equals(78.5));

        final latest = await repository.getLatestMeasurement();
        expect(latest, isNotNull);
        expect(latest!.id, equals('m_2'));
      },
    );

    test('Updates body measurement and enqueues outbox sync event', () async {
      final m1 = BodyMeasurement(
        id: 'm_edit',
        userId: 'test_user',
        measuredAt: DateTime(2026, 3, 1),
        weightKg: 75.0,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );

      await repository.recordMeasurement(m1);
      final updated = m1.copyWith(weightKg: 74.2, waistCm: 80.0);
      await repository.updateMeasurement(updated);

      final retrieved = await repository.getLatestMeasurement();
      expect(retrieved!.weightKg, equals(74.2));
      expect(retrieved.waistCm, equals(80.0));

      final queueEntries = await db.select(db.syncQueue).get();
      expect(queueEntries.isNotEmpty, isTrue);
      expect(
        queueEntries.any(
          (q) => q.entityType == 'body_measurement' && q.entityId == 'm_edit',
        ),
        isTrue,
      );
    });

    test(
      'Soft deletes measurement and excludes from active query results',
      () async {
        final m1 = BodyMeasurement(
          id: 'm_delete',
          userId: 'test_user',
          measuredAt: DateTime.now(),
          weightKg: 72.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.recordMeasurement(m1);
        final beforeDelete = await repository.getAllMeasurements();
        expect(beforeDelete.length, equals(1));

        await repository.deleteMeasurement('m_delete');
        final afterDelete = await repository.getAllMeasurements();
        expect(afterDelete.isEmpty, isTrue);
      },
    );

    test('Adds and queries progress photos filtered by pose type', () async {
      final pFront = ProgressPhoto(
        id: 'p_front_1',
        userId: 'test_user',
        takenAt: DateTime(2026, 1, 1),
        photoPath: '/photos/front_1.jpg',
        poseType: PhotoPoseType.front,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final pSide = ProgressPhoto(
        id: 'p_side_1',
        userId: 'test_user',
        takenAt: DateTime(2026, 1, 1),
        photoPath: '/photos/side_1.jpg',
        poseType: PhotoPoseType.side,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await repository.addProgressPhoto(pFront);
      await repository.addProgressPhoto(pSide);

      final allPhotos = await repository.getAllProgressPhotos();
      expect(allPhotos.length, equals(2));

      final frontOnly = await repository.getAllProgressPhotos(
        poseType: PhotoPoseType.front,
      );
      expect(frontOnly.length, equals(1));
      expect(frontOnly.first.id, equals('p_front_1'));

      final sideOnly = await repository.getAllProgressPhotos(
        poseType: PhotoPoseType.side,
      );
      expect(sideOnly.length, equals(1));
      expect(sideOnly.first.id, equals('p_side_1'));

      await repository.deleteProgressPhoto('p_front_1');
      final afterDelete = await repository.getAllProgressPhotos();
      expect(afterDelete.length, equals(1));
      expect(afterDelete.first.id, equals('p_side_1'));
    });
  });
}
