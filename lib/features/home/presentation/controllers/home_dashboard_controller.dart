import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardState {
  final DateTime selectedDate;
  final int streakDays;
  final String activeDietRoutine;
  final bool isFavoriteWorkout;
  final String selectedActivityFilter;
  final int walkSteps;
  final double sleepHours;

  const HomeDashboardState({
    required this.selectedDate,
    this.streakDays = 1,
    this.activeDietRoutine = 'Balanced Nutrition',
    this.isFavoriteWorkout = true,
    this.selectedActivityFilter = 'Today',
    this.walkSteps = 0,
    this.sleepHours = 7.5,
  });

  HomeDashboardState copyWith({
    DateTime? selectedDate,
    int? streakDays,
    String? activeDietRoutine,
    bool? isFavoriteWorkout,
    String? selectedActivityFilter,
    int? walkSteps,
    double? sleepHours,
  }) {
    return HomeDashboardState(
      selectedDate: selectedDate ?? this.selectedDate,
      streakDays: streakDays ?? this.streakDays,
      activeDietRoutine: activeDietRoutine ?? this.activeDietRoutine,
      isFavoriteWorkout: isFavoriteWorkout ?? this.isFavoriteWorkout,
      selectedActivityFilter:
          selectedActivityFilter ?? this.selectedActivityFilter,
      walkSteps: walkSteps ?? this.walkSteps,
      sleepHours: sleepHours ?? this.sleepHours,
    );
  }
}

class HomeDashboardNotifier extends Notifier<HomeDashboardState> {
  @override
  HomeDashboardState build() {
    return HomeDashboardState(selectedDate: DateTime.now());
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void toggleFavorite() {
    state = state.copyWith(isFavoriteWorkout: !state.isFavoriteWorkout);
  }

  void setDietRoutine(String routine) {
    state = state.copyWith(activeDietRoutine: routine);
  }

  void setActivityFilter(String filter) {
    state = state.copyWith(selectedActivityFilter: filter);
  }

  void logSteps(int steps) {
    state = state.copyWith(walkSteps: state.walkSteps + steps);
  }

  void setSleepHours(double hours) {
    state = state.copyWith(sleepHours: hours);
  }
}

final homeDashboardProvider =
    NotifierProvider<HomeDashboardNotifier, HomeDashboardState>(
  HomeDashboardNotifier.new,
);
