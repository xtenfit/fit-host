import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calendar_event.dart';
import '../../data/repositories/calendar_repository.dart';

enum CalendarViewMode {
  month(label: 'Month'),
  week(label: 'Week'),
  day(label: 'Day');

  final String label;
  const CalendarViewMode({required this.label});
}

class CalendarState {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final CalendarViewMode viewMode;
  final CalendarEventType? selectedCategoryFilter;

  const CalendarState({
    required this.selectedDate,
    required this.focusedMonth,
    this.viewMode = CalendarViewMode.month,
    this.selectedCategoryFilter,
  });

  CalendarState copyWith({
    DateTime? selectedDate,
    DateTime? focusedMonth,
    CalendarViewMode? viewMode,
    CalendarEventType? selectedCategoryFilter,
    bool clearCategoryFilter = false,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      viewMode: viewMode ?? this.viewMode,
      selectedCategoryFilter: clearCategoryFilter
          ? null
          : (selectedCategoryFilter ?? this.selectedCategoryFilter),
    );
  }
}

class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    final now = DateTime.now();
    return CalendarState(
      selectedDate: DateTime(now.year, now.month, now.day),
      focusedMonth: DateTime(now.year, now.month, 1),
    );
  }

  CalendarRepository get _repository => ref.read(calendarRepositoryProvider);

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
      focusedMonth: DateTime(date.year, date.month, 1),
    );
  }

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void jumpToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      selectedDate: DateTime(now.year, now.month, now.day),
      focusedMonth: DateTime(now.year, now.month, 1),
    );
  }

  void previousPeriod() {
    switch (state.viewMode) {
      case CalendarViewMode.month:
        final prevMonth = DateTime(state.focusedMonth.year, state.focusedMonth.month - 1, 1);
        state = state.copyWith(
          focusedMonth: prevMonth,
          selectedDate: DateTime(prevMonth.year, prevMonth.month, 1),
        );
        break;
      case CalendarViewMode.week:
        final prevWeek = state.selectedDate.subtract(const Duration(days: 7));
        state = state.copyWith(
          selectedDate: prevWeek,
          focusedMonth: DateTime(prevWeek.year, prevWeek.month, 1),
        );
        break;
      case CalendarViewMode.day:
        final prevDay = state.selectedDate.subtract(const Duration(days: 1));
        state = state.copyWith(
          selectedDate: prevDay,
          focusedMonth: DateTime(prevDay.year, prevDay.month, 1),
        );
        break;
    }
  }

  void nextPeriod() {
    switch (state.viewMode) {
      case CalendarViewMode.month:
        final nextMonth = DateTime(state.focusedMonth.year, state.focusedMonth.month + 1, 1);
        state = state.copyWith(
          focusedMonth: nextMonth,
          selectedDate: DateTime(nextMonth.year, nextMonth.month, 1),
        );
        break;
      case CalendarViewMode.week:
        final nextWeek = state.selectedDate.add(const Duration(days: 7));
        state = state.copyWith(
          selectedDate: nextWeek,
          focusedMonth: DateTime(nextWeek.year, nextWeek.month, 1),
        );
        break;
      case CalendarViewMode.day:
        final nextDay = state.addOneDay(state.selectedDate);
        state = state.copyWith(
          selectedDate: nextDay,
          focusedMonth: DateTime(nextDay.year, nextDay.month, 1),
        );
        break;
    }
  }

  void setCategoryFilter(CalendarEventType? category) {
    if (category == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(selectedCategoryFilter: category);
    }
  }

  Future<void> addEvent(CalendarEvent event) async {
    await _repository.createEvent(event);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _repository.updateEvent(event);
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
  }

  Future<void> toggleCompletion(String id, bool isCompleted) async {
    await _repository.toggleCompletion(id, isCompleted);
  }

  Future<void> rescheduleEvent(String id, DateTime newDate, DateTime? newTime) async {
    await _repository.rescheduleEvent(id, newDate, newTime);
  }
}

extension on CalendarState {
  DateTime addOneDay(DateTime dt) => dt.add(const Duration(days: 1));
}

final calendarStateProvider =
    NotifierProvider<CalendarNotifier, CalendarState>(CalendarNotifier.new);

final calendarEventsForSelectedDateProvider =
    StreamProvider<List<CalendarEvent>>((ref) {
  final state = ref.watch(calendarStateProvider);
  final repo = ref.watch(calendarRepositoryProvider);

  return repo.watchEventsForDate(state.selectedDate).map((events) {
    if (state.selectedCategoryFilter == null) return events;
    return events.where((e) => e.eventType == state.selectedCategoryFilter).toList();
  });
});

final calendarEventsForMonthProvider =
    StreamProvider<List<CalendarEvent>>((ref) {
  final state = ref.watch(calendarStateProvider);
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.watchEventsForMonth(state.focusedMonth);
});

final allCalendarEventsProvider =
    StreamProvider<List<CalendarEvent>>((ref) {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.watchAllEvents();
});
