import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardState {
  final DateTime selectedDate;
  final int streakDays;
  final int stepsCount;
  final int heartRateBpm;
  final String activeDietRoutine;
  final bool isFavoriteWorkout;
  final String selectedActivityFilter;
  final int walkSteps;
  final double sleepHours;

  const HomeDashboardState({
    required this.selectedDate,
    this.streakDays = 21,
    this.stepsCount = 9560,
    this.heartRateBpm = 73,
    this.activeDietRoutine = 'Mediterranean Diet',
    this.isFavoriteWorkout = true,
    this.selectedActivityFilter = 'Today',
    this.walkSteps = 6432,
    this.sleepHours = 7.40,
  });

  HomeDashboardState copyWith({
    DateTime? selectedDate,
    int? streakDays,
    int? stepsCount,
    int? heartRateBpm,
    String? activeDietRoutine,
    bool? isFavoriteWorkout,
    String? selectedActivityFilter,
    int? walkSteps,
    double? sleepHours,
  }) {
    return HomeDashboardState(
      selectedDate: selectedDate ?? this.selectedDate,
      streakDays: streakDays ?? this.streakDays,
      stepsCount: stepsCount ?? this.stepsCount,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
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

  void addSteps(int steps) {
    state = state.copyWith(
      stepsCount: state.stepsCount + steps,
      walkSteps: state.walkSteps + steps,
    );
  }

  void pulseHeartRate() {
    final nextBpm = state.heartRateBpm == 73 ? 76 : (state.heartRateBpm == 76 ? 71 : 73);
    state = state.copyWith(heartRateBpm: nextBpm);
  }
}

final homeDashboardProvider =
    NotifierProvider<HomeDashboardNotifier, HomeDashboardState>(
  HomeDashboardNotifier.new,
);
