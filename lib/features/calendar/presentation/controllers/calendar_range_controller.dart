import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/day_summary.dart';
import '../../data/services/day_summary_service.dart';

enum RangeFilter {
  today('Today'),
  week('Week'),
  month('Month'),
  custom('Custom');

  final String label;
  const RangeFilter(this.label);
}

class CalendarRangeState {
  final RangeFilter selectedFilter;
  final DateTime customStartDate;
  final DateTime customEndDate;
  final DateTime focusedDate;
  final bool showLockCard;

  const CalendarRangeState({
    this.selectedFilter = RangeFilter.today,
    required this.customStartDate,
    required this.customEndDate,
    required this.focusedDate,
    this.showLockCard = false,
  });

  DateTime get startDate {
    final now = focusedDate;
    final today = DateTime(now.year, now.month, now.day);
    switch (selectedFilter) {
      case RangeFilter.today:
        return today;
      case RangeFilter.week:
        // Monday as first day of week
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case RangeFilter.month:
        return DateTime(today.year, today.month, 1);
      case RangeFilter.custom:
        return DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
    }
  }

  DateTime get endDate {
    final now = focusedDate;
    final today = DateTime(now.year, now.month, now.day);
    switch (selectedFilter) {
      case RangeFilter.today:
        return today;
      case RangeFilter.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return DateTime(sunday.year, sunday.month, sunday.day);
      case RangeFilter.month:
        return DateTime(today.year, today.month + 1, 0);
      case RangeFilter.custom:
        return DateTime(customEndDate.year, customEndDate.month, customEndDate.day);
    }
  }

  CalendarRangeState copyWith({
    RangeFilter? selectedFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    DateTime? focusedDate,
    bool? showLockCard,
  }) {
    return CalendarRangeState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      focusedDate: focusedDate ?? this.focusedDate,
      showLockCard: showLockCard ?? this.showLockCard,
    );
  }
}

class CalendarRangeNotifier extends Notifier<CalendarRangeState> {
  @override
  CalendarRangeState build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pastWeek = today.subtract(const Duration(days: 6));

    return CalendarRangeState(
      selectedFilter: RangeFilter.today,
      customStartDate: pastWeek,
      customEndDate: today,
      focusedDate: today,
      showLockCard: false,
    );
  }

  void selectFilter(RangeFilter filter, {required bool isGuest}) {
    // Deliverable D: Advanced Aggregation = ACCOUNT ONLY
    // Guests see today + this week. Tapping Month or Custom shows a lock card.
    if (isGuest && (filter == RangeFilter.month || filter == RangeFilter.custom)) {
      state = state.copyWith(
        selectedFilter: filter,
        showLockCard: true,
      );
      return;
    }

    state = state.copyWith(
      selectedFilter: filter,
      showLockCard: false,
    );
  }

  void setCustomRange(DateTime start, DateTime end, {required bool isGuest}) {
    if (isGuest) {
      state = state.copyWith(
        selectedFilter: RangeFilter.custom,
        showLockCard: true,
      );
      return;
    }

    state = state.copyWith(
      selectedFilter: RangeFilter.custom,
      customStartDate: start,
      customEndDate: end,
      showLockCard: false,
    );
  }

  void setFocusedDate(DateTime date) {
    state = state.copyWith(focusedDate: date);
  }

  void dismissLockCard() {
    state = state.copyWith(showLockCard: false);
  }
}

final calendarRangeProvider =
    NotifierProvider<CalendarRangeNotifier, CalendarRangeState>(
  CalendarRangeNotifier.new,
);

/// Stream provider for day summaries in the selected range
final rangeSummariesStreamProvider =
    StreamProvider<RangeAggregation>((ref) {
  final rangeState = ref.watch(calendarRangeProvider);
  final service = ref.watch(daySummaryServiceProvider);
  final auth = ref.watch(authProvider);

  final isGuest = auth.isGuest;

  // If locked, return empty summaries to prevent data leak before sign-up
  if (isGuest && (rangeState.selectedFilter == RangeFilter.month || rangeState.selectedFilter == RangeFilter.custom)) {
    return Stream.value(RangeAggregation(
      startDate: rangeState.startDate,
      endDate: rangeState.endDate,
      dailySummaries: const [],
    ));
  }

  return service
      .watchDaySummaries(rangeState.startDate, rangeState.endDate)
      .map((summaries) => RangeAggregation(
            startDate: rangeState.startDate,
            endDate: rangeState.endDate,
            dailySummaries: summaries,
          ));
});

/// Stream provider for month day summaries (for month grid badges and rings)
final monthSummariesMapProvider =
    StreamProvider.family<Map<String, DaySummary>, DateTime>((ref, month) {
  final service = ref.watch(daySummaryServiceProvider);
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  return service.watchDaySummaries(startOfMonth, endOfMonth).map((summaries) {
    final Map<String, DaySummary> map = {};
    for (final s in summaries) {
      final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      map[key] = s;
    }
    return map;
  });
});
