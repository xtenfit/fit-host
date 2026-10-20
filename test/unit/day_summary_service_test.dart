import 'dart:convert';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/core/data/workout_repository.dart';
import 'package:fit_host/core/data/nutrition_repository.dart';
import 'package:fit_host/core/data/hydration_repository.dart';
import 'package:fit_host/core/data/steps_repository.dart';
import 'package:fit_host/core/data/reminder_repository.dart';
import 'package:fit_host/core/services/notification_service.dart';
import 'package:fit_host/features/calendar/domain/models/day_summary.dart';
import 'package:fit_host/features/calendar/data/services/day_summary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 4: DaySummaryService & Unified Aggregations', () {
    late AppDatabase memoryDb;
    late LocalWorkoutRepository workoutRepo;
    late LocalNutritionRepository nutritionRepo;
    late LocalHydrationRepository hydrationRepo;
    late LocalStepsRepository stepsRepo;
    late LocalReminderRepository reminderRepo;
    late DaySummaryService daySummaryService;

    const testUserId = 'athlete_part4_pro';

    setUp(() {
      memoryDb = AppDatabase(NativeDatabase.memory());
      workoutRepo = LocalWorkoutRepository(memoryDb);
      nutritionRepo = LocalNutritionRepository(memoryDb, userId: testUserId);
      hydrationRepo = LocalHydrationRepository(memoryDb, userId: testUserId);
      stepsRepo = LocalStepsRepository(memoryDb, userId: testUserId);
      reminderRepo = LocalReminderRepository(
        memoryDb,
        NotificationService(),
      );

      daySummaryService = DaySummaryService(
        db: memoryDb,
        workoutRepository: workoutRepo,
        nutritionRepository: nutritionRepo,
        hydrationRepository: hydrationRepo,
        stepsRepository: stepsRepo,
        reminderRepository: reminderRepo,
        userId: testUserId,
      );
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('DST test: date range generation across 23h and 25h DST boundaries produces exact day count', () {
      // 1. Spring forward boundary (23-hour calendar day)
      // E.g., March 28 to April 3 (7 calendar days)
      final springStart = DateTime(2026, 3, 28);
      final springEnd = DateTime(2026, 4, 3);
      final springDays = DaySummaryService.generateDateRange(springStart, springEnd);
      expect(springDays.length, equals(7));
      expect(springDays.first.day, equals(28));
      expect(springDays.last.day, equals(3));
      expect(springDays.last.month, equals(4));

      // 2. Fall back boundary (25-hour calendar day)
      // E.g., October 24 to October 30 (7 calendar days)
      final fallStart = DateTime(2026, 10, 24);
      final fallEnd = DateTime(2026, 10, 30);
      final fallDays = DaySummaryService.generateDateRange(fallStart, fallEnd);
      expect(fallDays.length, equals(7));
      expect(fallDays.first.day, equals(24));
      expect(fallDays.last.day, equals(30));

      // 3. Custom 45-day range covering DST transition
      final range45Start = DateTime(2026, 10, 1);
      final range45End = DateTime(2026, 11, 14);
      final days45 = DaySummaryService.generateDateRange(range45Start, range45End);
      expect(days45.length, equals(45));
    });

    test('Single-pass batch aggregation fans out to 5 tables and aggregates into DaySummary', () async {
      final now = DateTime.now();

      // 1. Workouts
      await memoryDb.into(memoryDb.workouts).insert(
            WorkoutsCompanion.insert(
              id: 'w_test_1',
              userId: drift.Value(testUserId),
              title: 'Morning Upper Body Hypertrophy',
              startedAt: DateTime(2026, 10, 16, 8, 0),
              completedAt: drift.Value(DateTime(2026, 10, 16, 8, 45)),
              status: const drift.Value('completed'),
              durationSeconds: const drift.Value(2700), // 45 min
              updatedAt: now,
            ),
          );

      await memoryDb.into(memoryDb.workouts).insert(
            WorkoutsCompanion.insert(
              id: 'w_test_2',
              userId: drift.Value(testUserId),
              title: 'Evening Mobility & Stretch',
              startedAt: DateTime(2026, 10, 16, 19, 0),
              completedAt: drift.Value(DateTime(2026, 10, 16, 19, 30)),
              status: const drift.Value('completed'),
              durationSeconds: const drift.Value(1800), // 30 min
              updatedAt: now,
            ),
          );

      // 2. Nutrition
      final mealsJson = jsonEncode([
        {
          'id': 'meal_1',
          'name': 'Oatmeal & Protein Shake',
          'calories': 650,
          'protein_grams': 52.0,
          'carbs_grams': 75.0,
          'fat_grams': 12.0,
        },
        {
          'id': 'meal_2',
          'name': 'Grilled Chicken & Quinoa',
          'calories': 850,
          'protein_grams': 65.0,
          'carbs_grams': 80.0,
          'fat_grams': 18.0,
        },
      ]);

      await memoryDb.into(memoryDb.nutritionLogs).insert(
            NutritionLogsCompanion.insert(
              id: 'nut_log_1',
              userId: drift.Value(testUserId),
              logDate: DateTime(2026, 10, 16),
              waterGlasses: const drift.Value(8),
              loggedMeals: drift.Value(mealsJson),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Hydration
      await memoryDb.into(memoryDb.hydrationLogs).insert(
            HydrationLogsCompanion.insert(
              id: 'hyd_log_1',
              userId: drift.Value(testUserId),
              logDate: DateTime(2026, 10, 16),
              waterGlasses: const drift.Value(10),
              totalMl: const drift.Value(2500),
              loggedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 4. Steps
      await memoryDb.into(memoryDb.stepDailyLogs).insert(
            StepDailyLogsCompanion.insert(
              id: 'step_log_1',
              userId: drift.Value(testUserId),
              stepDate: DateTime(2026, 10, 16),
              steps: const drift.Value(10500),
              distanceMeters: const drift.Value(7350.0),
              activeCalories: const drift.Value(420),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 5. Reminders
      await memoryDb.into(memoryDb.reminders).insert(
            RemindersCompanion.insert(
              id: 'rem_1',
              userId: drift.Value(testUserId),
              title: 'Take Creatine & Water',
              category: 'Hydration',
              timeOfDay: '10:00',
              lastCompletedAt: drift.Value(DateTime(2026, 10, 16, 10, 5)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Fetch batch day summaries for 1 week
      final summaries = await daySummaryService.getDaySummaries(
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 18),
      );

      expect(summaries.length, equals(7));

      final daySummary = summaries.firstWhere(
        (s) => s.date.day == 16,
      );

      // Verify Workout aggregation
      expect(daySummary.workoutCount, equals(2));
      expect(daySummary.workoutDurationMin, equals(75)); // 45 + 30
      expect(daySummary.hasWorkout, isTrue);

      // Verify Nutrition aggregation
      expect(daySummary.caloriesIn, equals(1500)); // 650 + 850
      expect(daySummary.proteinG, equals(117.0)); // 52 + 65
      expect(daySummary.carbsG, equals(155.0)); // 75 + 80
      expect(daySummary.fatsG, equals(30.0)); // 12 + 18
      expect(daySummary.hasMealLogged, isTrue);

      // Verify Hydration aggregation
      expect(daySummary.waterMl, equals(2500));
      expect(daySummary.hasWaterLogged, isTrue);

      // Verify Steps aggregation
      expect(daySummary.steps, equals(10500));
      expect(daySummary.distanceKm, closeTo(7.35, 0.01));
      expect(daySummary.isStepsGoalMet(), isTrue);
      expect(daySummary.formattedDistance, equals('7.35 km'));

      // Verify Reminders aggregation
      expect(daySummary.hasReminder, isTrue);
      expect(daySummary.completedReminders, equals(1));
    });

    test('Switch to Week -> totals match the sum of the 7 days', () async {
      final monday = DateTime(2026, 10, 12);
      final sunday = DateTime(2026, 10, 18);
      final now = DateTime.now();

      // Seed 7 days of varied activity
      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));
        final steps = (i + 1) * 2000; // 2k, 4k, 6k, 8k, 10k, 12k, 14k

        await memoryDb.into(memoryDb.stepDailyLogs).insert(
              StepDailyLogsCompanion.insert(
                id: const Uuid().v4(),
                userId: drift.Value(testUserId),
                stepDate: dayDate,
                steps: drift.Value(steps),
                distanceMeters: drift.Value(steps * 0.7),
                activeCalories: drift.Value(steps ~/ 25),
                createdAt: now,
                updatedAt: now,
              ),
            );

        if (i % 2 == 0) {
          await memoryDb.into(memoryDb.workouts).insert(
                WorkoutsCompanion.insert(
                  id: const Uuid().v4(),
                  userId: drift.Value(testUserId),
                  title: 'Workout Day $i',
                  startedAt: DateTime(dayDate.year, dayDate.month, dayDate.day, 9),
                  status: const drift.Value('completed'),
                  durationSeconds: const drift.Value(3600), // 60 min
                  updatedAt: now,
                ),
              );
        }
      }

      final summaries = await daySummaryService.getDaySummaries(monday, sunday);
      expect(summaries.length, equals(7));

      final aggregation = RangeAggregation(
        startDate: monday,
        endDate: sunday,
        dailySummaries: summaries,
      );

      // Sum of steps: 2k+4k+6k+8k+10k+12k+14k = 56,000
      final expectedSteps = summaries.fold(0, (sum, s) => sum + s.steps);
      expect(aggregation.totalSteps, equals(56000));
      expect(aggregation.totalSteps, equals(expectedSteps));

      // Workouts completed on days 0, 2, 4, 6 -> 4 workouts
      final expectedWorkouts = summaries.fold(0, (sum, s) => sum + s.workoutCount);
      expect(aggregation.totalWorkoutsCompleted, equals(4));
      expect(aggregation.totalWorkoutsCompleted, equals(expectedWorkouts));

      // Net calories = totalCaloriesIn - totalCaloriesBurned
      expect(
        aggregation.netCalories,
        equals(aggregation.totalCaloriesIn - aggregation.totalCaloriesBurned),
      );

      // Longest streak
      expect(aggregation.longestStreak, greaterThanOrEqualTo(1));
    });

    test('Custom range covering 45 days -> loads in < 800ms on device benchmark', () async {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 10, 15); // exactly 45 days
      final now = DateTime.now();

      // Populate sample logs across all 45 days
      for (int i = 0; i < 45; i++) {
        final d = start.add(Duration(days: i));
        await memoryDb.into(memoryDb.stepDailyLogs).insert(
              StepDailyLogsCompanion.insert(
                id: 'bench_step_$i',
                userId: drift.Value(testUserId),
                stepDate: d,
                steps: drift.Value(7500 + (i * 50)),
                distanceMeters: const drift.Value(5500.0),
                activeCalories: const drift.Value(300),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      final stopwatch = Stopwatch()..start();
      final summaries = await daySummaryService.getDaySummaries(start, end);
      stopwatch.stop();

      expect(summaries.length, equals(45));
      expect(stopwatch.elapsedMilliseconds, lessThan(800));
    });

    test('Live watch stream: Add workout today, log meal, add water, walk 100 steps -> updates live without refresh', () async {
      final today = DateTime(2026, 10, 16);
      final now = DateTime.now();

      final stream = daySummaryService.watchDaySummaries(today, today);

      final events = <List<DaySummary>>[];
      final sub = stream.listen(events.add);

      // Allow initial emission to settle
      await Future.delayed(const Duration(milliseconds: 50));

      // 1. Add workout
      await memoryDb.into(memoryDb.workouts).insert(
            WorkoutsCompanion.insert(
              id: 'live_workout_1',
              userId: drift.Value(testUserId),
              title: 'Live Quick HIIT',
              startedAt: DateTime(2026, 10, 16, 12, 0),
              status: const drift.Value('completed'),
              durationSeconds: const drift.Value(1200),
              updatedAt: now,
            ),
          );

      // 2. Log meal
      final mealJson = jsonEncode([
        {
          'id': 'meal_live',
          'name': 'Post-workout Shake',
          'calories': 500,
          'protein_grams': 40.0,
          'carbs_grams': 60.0,
          'fat_grams': 5.0,
        }
      ]);
      await memoryDb.into(memoryDb.nutritionLogs).insert(
            NutritionLogsCompanion.insert(
              id: 'live_nut_1',
              userId: drift.Value(testUserId),
              logDate: DateTime(2026, 10, 16),
              loggedMeals: drift.Value(mealJson),
              waterGlasses: const drift.Value(8),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Add water
      await memoryDb.into(memoryDb.hydrationLogs).insert(
            HydrationLogsCompanion.insert(
              id: 'live_hyd_1',
              userId: drift.Value(testUserId),
              logDate: DateTime(2026, 10, 16),
              totalMl: const drift.Value(2000),
              waterGlasses: const drift.Value(8),
              loggedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 4. Walk 100 steps
      await memoryDb.into(memoryDb.stepDailyLogs).insert(
            StepDailyLogsCompanion.insert(
              id: 'live_step_1',
              userId: drift.Value(testUserId),
              stepDate: DateTime(2026, 10, 16),
              steps: const drift.Value(100),
              distanceMeters: const drift.Value(70.0),
              activeCalories: const drift.Value(4),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await Future.delayed(const Duration(milliseconds: 80));

      expect(events.isNotEmpty, isTrue);
      // Initial state was empty
      expect(events.first.first.workoutCount, equals(0));
      expect(events.first.first.caloriesIn, equals(0));
      expect(events.first.first.steps, equals(0));

      // Final state has all updates live
      final finalDay = events.last.first;
      expect(finalDay.workoutCount, equals(1));
      expect(finalDay.caloriesIn, equals(500));
      expect(finalDay.waterMl, equals(2000));
      expect(finalDay.steps, equals(100));
      expect(finalDay.hasWorkout, isTrue);
      expect(finalDay.hasMealLogged, isTrue);
      expect(finalDay.hasWaterLogged, isTrue);

      await sub.cancel();
    });
  });
}
