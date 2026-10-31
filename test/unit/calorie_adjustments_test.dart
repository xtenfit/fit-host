import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/nutrition/domain/models/calorie_adjustment.dart';
import 'package:fit_host/features/nutrition/data/repositories/calorie_adjustment_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CalorieAdjustmentRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CalorieAdjustmentRepositoryImpl(db: db, userId: 'test_athlete');
  });

  tearDown(() async {
    await db.close();
  });

  group('Calorie Adjustment Repository & Model Tests', () {
    test(
      'CalorieAdjustment model validates burn range between 1 and 5000 kcal',
      () {
        expect(
          () => CalorieAdjustment(
            id: 'adj_invalid_0',
            date: DateTime.now(),
            caloriesBurned: 0,
            title: 'Zero burn',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => CalorieAdjustment(
            id: 'adj_invalid_neg',
            date: DateTime.now(),
            caloriesBurned: -100,
            title: 'Negative burn',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          throwsA(isA<AssertionError>()),
        );

        final valid = CalorieAdjustment(
          id: 'adj_valid',
          date: DateTime(2026, 10, 23),
          caloriesBurned: 350,
          title: 'Brisk Walk with Incline',
          note: 'Carrying 10kg backpack',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(valid.caloriesBurned, equals(350));
        expect(valid.source, equals('manual_adjustment'));
        expect(valid.isDeleted, isFalse);
      },
    );

    test('Add, retrieve, and filter adjustments by specific date', () async {
      final today = DateTime(2026, 10, 23);
      final yesterday = DateTime(2026, 10, 22);

      final adjToday = CalorieAdjustment(
        id: 'adj_today_1',
        userId: 'test_athlete',
        date: today,
        caloriesBurned: 250,
        title: 'Hiking',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final adjYesterday = CalorieAdjustment(
        id: 'adj_yesterday_1',
        userId: 'test_athlete',
        date: yesterday,
        caloriesBurned: 400,
        title: 'Swimming',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.addAdjustment(adjToday);
      await repo.addAdjustment(adjYesterday);

      final todayList = await repo.getAdjustmentsForDate(today);
      expect(todayList.length, equals(1));
      expect(todayList.first.id, equals('adj_today_1'));
      expect(todayList.first.caloriesBurned, equals(250));

      final yesterdayList = await repo.getAdjustmentsForDate(yesterday);
      expect(yesterdayList.length, equals(1));
      expect(yesterdayList.first.id, equals('adj_yesterday_1'));
      expect(yesterdayList.first.caloriesBurned, equals(400));
    });

    test('Update existing adjustment modifies calories and title', () async {
      final date = DateTime(2026, 10, 23);
      final adj = CalorieAdjustment(
        id: 'adj_update_me',
        userId: 'test_athlete',
        date: date,
        caloriesBurned: 150,
        title: 'Short walk',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.addAdjustment(adj);

      final updated = adj.copyWith(
        caloriesBurned: 220,
        title: 'Longer walk with hills',
      );
      await repo.updateAdjustment(updated);

      final list = await repo.getAdjustmentsForDate(date);
      expect(list.length, equals(1));
      expect(list.first.caloriesBurned, equals(220));
      expect(list.first.title, equals('Longer walk with hills'));
    });

    test(
      'Delete soft-deletes adjustment and excludes it from active calculations',
      () async {
        final date = DateTime(2026, 10, 23);
        final adj = CalorieAdjustment(
          id: 'adj_to_delete',
          userId: 'test_athlete',
          date: date,
          caloriesBurned: 300,
          title: 'Gardening',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repo.addAdjustment(adj);
        var list = await repo.getAdjustmentsForDate(date);
        expect(list.length, equals(1));

        await repo.deleteAdjustment(adj.id);
        list = await repo.getAdjustmentsForDate(date);
        expect(list.isEmpty, isTrue);
      },
    );

    test(
      'Range query returns adjustments ordered by date across multiple days',
      () async {
        final d1 = DateTime(2026, 10, 20);
        final d2 = DateTime(2026, 10, 21);
        final d3 = DateTime(2026, 10, 25);

        await repo.addAdjustment(
          CalorieAdjustment(
            id: 'd1',
            userId: 'test_athlete',
            date: d1,
            caloriesBurned: 100,
            title: 'Activity 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await repo.addAdjustment(
          CalorieAdjustment(
            id: 'd2',
            userId: 'test_athlete',
            date: d2,
            caloriesBurned: 200,
            title: 'Activity 2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await repo.addAdjustment(
          CalorieAdjustment(
            id: 'd3',
            userId: 'test_athlete',
            date: d3,
            caloriesBurned: 300,
            title: 'Activity 3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Range between Oct 20 and Oct 22
        final range = await repo.getAdjustmentsForRange(
          DateTime(2026, 10, 20),
          DateTime(2026, 10, 22),
        );
        expect(range.length, equals(2));
        expect(range[0].id, equals('d1'));
        expect(range[1].id, equals('d2'));
      },
    );
  });
}
