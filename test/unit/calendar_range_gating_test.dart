import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/features/calendar/presentation/controllers/calendar_range_controller.dart';
import 'package:fit_host/features/calendar/domain/models/day_summary.dart';

void main() {
  group('Part 4: Calendar Range Gating & Aggregations (Deliverable D)', () {
    test('Guest can view Today and Week, but Month and Custom trigger Lock Card', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(AuthService.new),
        ],
      );

      final notifier = container.read(calendarRangeProvider.notifier);

      // Default state: Today, no lock card
      var state = container.read(calendarRangeProvider);
      expect(state.selectedFilter, equals(RangeFilter.today));
      expect(state.showLockCard, isFalse);

      // Guest selects Week -> allowed, no lock card
      notifier.selectFilter(RangeFilter.week, isGuest: true);
      state = container.read(calendarRangeProvider);
      expect(state.selectedFilter, equals(RangeFilter.week));
      expect(state.showLockCard, isFalse);

      // Guest selects Month -> blocked, lock card shown
      notifier.selectFilter(RangeFilter.month, isGuest: true);
      state = container.read(calendarRangeProvider);
      expect(state.showLockCard, isTrue);

      // Guest selects Custom -> blocked, lock card shown
      notifier.selectFilter(RangeFilter.custom, isGuest: true);
      state = container.read(calendarRangeProvider);
      expect(state.showLockCard, isTrue);

      // Guest dismisses lock card
      notifier.dismissLockCard();
      state = container.read(calendarRangeProvider);
      expect(state.showLockCard, isFalse);
    });

    test('Signed-in user can access Month and Custom without lock card', () {
      final container = ProviderContainer();
      final notifier = container.read(calendarRangeProvider.notifier);

      // Authenticated user selects Month -> no lock card
      notifier.selectFilter(RangeFilter.month, isGuest: false);
      var state = container.read(calendarRangeProvider);
      expect(state.selectedFilter, equals(RangeFilter.month));
      expect(state.showLockCard, isFalse);

      // Authenticated user sets Custom Range -> no lock card
      final customStart = DateTime(2026, 8, 1);
      final customEnd = DateTime(2026, 9, 15);
      notifier.setCustomRange(customStart, customEnd, isGuest: false);
      state = container.read(calendarRangeProvider);
      expect(state.selectedFilter, equals(RangeFilter.custom));
      expect(state.customStartDate, equals(customStart));
      expect(state.customEndDate, equals(customEnd));
      expect(state.showLockCard, isFalse);
    });

    test('RangeAggregation computes averages, formatted distance, and streaks accurately', () {
      final day1 = DaySummary(
        date: DateTime(2026, 10, 1),
        steps: 10000,
        distanceKm: 7.0,
        caloriesIn: 2200,
        caloriesBurned: 600,
        proteinG: 150.0,
        carbsG: 250.0,
        fatsG: 60.0,
        waterMl: 2500,
        workoutCount: 1,
      );

      final day2 = DaySummary(
        date: DateTime(2026, 10, 2),
        steps: 8000,
        distanceKm: 5.6,
        caloriesIn: 2000,
        caloriesBurned: 500,
        proteinG: 130.0,
        carbsG: 230.0,
        fatsG: 50.0,
        waterMl: 2000,
        workoutCount: 1,
      );

      final day3 = DaySummary(
        date: DateTime(2026, 10, 3), // Rest day, no activity
        steps: 2000,
        distanceKm: 1.4,
        caloriesIn: 0,
        caloriesBurned: 200,
        proteinG: 0.0,
        carbsG: 0.0,
        fatsG: 0.0,
        waterMl: 1500,
        workoutCount: 0,
      );

      final aggregation = RangeAggregation(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 3),
        dailySummaries: [day1, day2, day3],
      );

      expect(aggregation.dayCount, equals(3));
      expect(aggregation.totalSteps, equals(20000));
      expect(aggregation.totalDistanceKm, closeTo(14.0, 0.01));
      expect(aggregation.formattedTotalDistance, equals('14.00 km'));

      expect(aggregation.totalCaloriesIn, equals(4200));
      expect(aggregation.totalCaloriesBurned, equals(1300));
      expect(aggregation.netCalories, equals(2900));

      expect(aggregation.totalProteinG, equals(280.0));
      expect(aggregation.avgProteinG, closeTo(93.33, 0.1));

      expect(aggregation.totalWorkoutsCompleted, equals(2));
      // Days 1 and 2 are active, day 3 is rest -> streak is 2
      expect(aggregation.longestStreak, equals(2));
    });
  });
}
