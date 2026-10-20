import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/steps_repository.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import '../../data/step_service.dart';
import '../../data/step_permission_service.dart';
import '../../domain/step_calculator.dart';
import '../../domain/daily_step_record.dart';

class StepState {
  final int todaySteps;
  final int targetSteps;
  final double distanceKm;
  final int calories;
  final int activeMinutes;
  final double strideLengthCm;
  final bool isRunningStride;
  final List<DailyStepRecord> history;
  final bool isGuest;
  final StepPermissionState permissionState;
  final bool isInitialized;

  const StepState({
    this.todaySteps = 0,
    this.targetSteps = 10000,
    this.distanceKm = 0.0,
    this.calories = 0,
    this.activeMinutes = 0,
    this.strideLengthCm = 72.6,
    this.isRunningStride = false,
    this.history = const [],
    this.isGuest = true,
    this.permissionState = StepPermissionState.unknown,
    this.isInitialized = false,
  });

  double get progressPercentage {
    if (targetSteps <= 0) return 0.0;
    return (todaySteps / targetSteps).clamp(0.0, 1.0);
  }

  bool get isGoalReached => todaySteps >= targetSteps;

  String get formattedDistance => StepCalculator.formatDistance(distanceKm);

  StepState copyWith({
    int? todaySteps,
    int? targetSteps,
    double? distanceKm,
    int? calories,
    int? activeMinutes,
    double? strideLengthCm,
    bool? isRunningStride,
    List<DailyStepRecord>? history,
    bool? isGuest,
    StepPermissionState? permissionState,
    bool? isInitialized,
  }) {
    return StepState(
      todaySteps: todaySteps ?? this.todaySteps,
      targetSteps: targetSteps ?? this.targetSteps,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      strideLengthCm: strideLengthCm ?? this.strideLengthCm,
      isRunningStride: isRunningStride ?? this.isRunningStride,
      history: history ?? this.history,
      isGuest: isGuest ?? this.isGuest,
      permissionState: permissionState ?? this.permissionState,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class StepController extends Notifier<StepState> {
  StreamSubscription<int>? _stepsSub;

  @override
  StepState build() {
    final auth = ref.watch(authProvider);
    final isGuest = auth.isGuest;
    final profile = ref.watch(userProfileProvider);

    final height = profile.heightCm;
    final initialStride = profile.effectiveStrideLengthCm;
    final goal = profile.dailyStepsGoal;

    final initial = StepState(
      targetSteps: goal,
      strideLengthCm: initialStride,
      isGuest: isGuest,
    );

    Future.microtask(() => _init(height: height, goal: goal, isGuest: isGuest));
    return initial;
  }

  Future<void> _init({
    required double height,
    required int goal,
    required bool isGuest,
  }) async {
    final stepService = ref.read(stepServiceProvider);
    final repo = ref.read(stepsRepositoryProvider);

    // Initial load from today's steps in service
    final initialSteps = stepService.todaySteps;
    final stride = state.strideLengthCm;
    final dist = StepCalculator.distanceKm(steps: initialSteps, strideCm: stride);
    final cal = StepCalculator.estimateCalories(initialSteps);
    final mins = StepCalculator.estimateActiveMinutes(initialSteps);

    // Load 7-day history (guests get today only)
    final history = await repo.getStepsHistory(days: 7);

    state = state.copyWith(
      todaySteps: initialSteps,
      distanceKm: dist,
      calories: cal,
      activeMinutes: mins,
      history: history,
      isInitialized: true,
      isGuest: isGuest,
    );

    // Listen to real-time step increments
    _stepsSub?.cancel();
    _stepsSub = stepService.todayStepsStream.listen((steps) {
      final updatedDist =
          StepCalculator.distanceKm(steps: steps, strideCm: state.strideLengthCm);
      final updatedCal = StepCalculator.estimateCalories(steps);
      final updatedMins = StepCalculator.estimateActiveMinutes(steps);

      state = state.copyWith(
        todaySteps: steps,
        distanceKm: updatedDist,
        calories: updatedCal,
        activeMinutes: updatedMins,
      );
    });
  }

  /// Request permissions only when user opens the Steps screen (Deliverable A)
  Future<void> requestPermissionsOnScreenEntry() async {
    final permService = ref.read(stepPermissionProvider.notifier);
    final permStatus = await permService.requestStepsPermission();
    state = state.copyWith(permissionState: permStatus);
  }

  /// Updates daily steps target goal
  Future<void> updateGoal(int newGoal) async {
    if (newGoal <= 0) return;
    state = state.copyWith(targetSteps: newGoal);
    final stepService = ref.read(stepServiceProvider);
    stepService.updateStrideAndGoal(goal: newGoal);

    // Update profile goal
    try {
      ref.read(userProfileProvider.notifier).updateStepGoal(newGoal);
    } catch (_) {}
  }

  /// Configures stride length in settings (Deliverable C)
  void setStrideMode({required bool isRunning, required double heightCm}) {
    final newStride = StepCalculator.estimateStrideCm(
      heightCm: heightCm,
      isRunning: isRunning,
    );
    final newDist = StepCalculator.distanceKm(
      steps: state.todaySteps,
      strideCm: newStride,
    );

    state = state.copyWith(
      isRunningStride: isRunning,
      strideLengthCm: newStride,
      distanceKm: newDist,
    );

    ref.read(stepServiceProvider).updateStrideAndGoal(strideCm: newStride);
  }

  void setCustomStride(double strideCm) {
    if (strideCm <= 0) return;
    final newDist = StepCalculator.distanceKm(
      steps: state.todaySteps,
      strideCm: strideCm,
    );

    state = state.copyWith(
      strideLengthCm: strideCm,
      distanceKm: newDist,
    );

    ref.read(stepServiceProvider).updateStrideAndGoal(strideCm: strideCm);
  }

  void addSimulatedSteps(int steps) {
    ref.read(stepServiceProvider).addSteps(steps);
  }
}

final stepControllerProvider =
    NotifierProvider<StepController, StepState>(
  StepController.new,
);
