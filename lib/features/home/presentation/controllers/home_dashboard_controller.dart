import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data/nutrition_repository.dart';
import '../../../../core/data/steps_repository.dart';
import '../../../steps/domain/daily_step_record.dart';
import '../../../workouts/domain/models/workout_models.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../nutrition/domain/models/nutrition_models.dart';

DateTime calendarDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool isSameCalendarDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

class HomeDashboardSummary {
  final DateTime date;
  final List<WorkoutEntity> completedWorkouts;
  final DailyNutritionState nutrition;
  final DailyStepRecord? steps;

  const HomeDashboardSummary({
    required this.date,
    required this.completedWorkouts,
    required this.nutrition,
    required this.steps,
  });

  int get workoutCount => completedWorkouts.length;
  int get totalMinutes =>
      completedWorkouts.fold(
        0,
        (sum, workout) => sum + workout.durationSeconds,
      ) ~/
      60;
  double get totalVolumeKg =>
      completedWorkouts.fold(0, (sum, workout) => sum + workout.totalVolumeKg);
  int get caloriesBurned => completedWorkouts.fold(
    0,
    (sum, workout) => sum + (workout.caloriesBurned ?? 0),
  );
}

final homeDashboardSummaryProvider =
    FutureProvider.family<HomeDashboardSummary, DateTime>((ref, date) async {
      final selectedDate = calendarDate(date);
      ref.watch(workoutsStreamProvider);
      final workouts = await ref
          .read(workoutRepositoryProvider)
          .getWorkouts()
          .timeout(const Duration(seconds: 15));
      final completed = workouts.where((workout) {
        return workout.status == 'completed' &&
            isSameCalendarDate(workout.startedAt.toLocal(), selectedDate);
      }).toList();
      final nutrition = await ref
          .read(nutritionRepositoryProvider)
          .getDailyNutrition(selectedDate)
          .timeout(const Duration(seconds: 15));
      final steps = await ref
          .read(stepsRepositoryProvider)
          .getDailyStepRecord(selectedDate)
          .timeout(const Duration(seconds: 15));

      return HomeDashboardSummary(
        date: selectedDate,
        completedWorkouts: completed,
        nutrition: nutrition,
        steps: steps,
      );
    });

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
    this.streakDays = 0,
    this.activeDietRoutine = 'Balanced Nutrition',
    this.isFavoriteWorkout = true,
    this.selectedActivityFilter = 'Today',
    this.walkSteps = 0,
    this.sleepHours = 0.0,
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
    final now = DateTime.now();
    _loadPersistedSleep(now);
    return HomeDashboardState(selectedDate: now);
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPersistedSleep(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sleep_hours_${_dateKey(date)}';
      final val = prefs.getDouble(key);
      if (val != null &&
          val > 0 &&
          isSameCalendarDate(date, state.selectedDate)) {
        state = state.copyWith(sleepHours: val);
      }
    } catch (_) {}
  }

  void selectDate(DateTime date) {
    final normalized = calendarDate(date);
    state = state.copyWith(selectedDate: normalized);
    _loadPersistedSleep(normalized);
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
    _savePersistedSleep(state.selectedDate, hours);
  }

  Future<void> _savePersistedSleep(DateTime date, double hours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sleep_hours_${_dateKey(date)}';
      await prefs.setDouble(key, hours);
    } catch (_) {}
  }
}

final homeDashboardProvider =
    NotifierProvider<HomeDashboardNotifier, HomeDashboardState>(
      HomeDashboardNotifier.new,
    );
