import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/exercise_media_visual.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeWorkoutProvider);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final workout = activeState.workout;
    if (workout == null) {
      if (activeState.recoveredWorkout != null) {
        final rec = activeState.recoveredWorkout!;
        return Scaffold(
          appBar: AppBar(title: const Text('Active Workout')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restore_rounded,
                      color: AppColors.limeGreen,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Recovered Session Found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have an in-progress workout "${rec.title}" with ${rec.completedSets} completed sets from a previous session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Resume Recovered Workout',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => notifier.resumeRecoveredWorkout(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () => notifier.discardRecoveredWorkout(),
                    child: const Text('Discard Unsaved Session'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No workout currently active.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  notifier.startNewWorkout();
                },
                child: const Text('Start Workout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workout.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  _formatTimer(activeState.elapsedSeconds),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => notifier.toggleTimer(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activeState.isTimerRunning
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 16,
                          color: activeState.isTimerRunning
                              ? AppColors.limeGreen
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activeState.isTimerRunning
                              ? 'Active'
                              : (workout.exercises.isEmpty
                                    ? 'Ready'
                                    : 'Paused'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: activeState.isTimerRunning
                                ? AppColors.limeGreen
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cancel Workout?'),
                  content: const Text(
                    'Are you sure you want to discard this workout? Unsaved progress will be lost.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep Training'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                notifier.cancelWorkout();
                if (context.mounted) context.pop();
              }
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (workout.exercises.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('No Exercises Added'),
                      content: const Text(
                        'This session currently has no exercises. Please add an exercise before finishing, or tap Discard.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                final completedWorkout = await notifier.finishWorkout();
                if (context.mounted && completedWorkout != null) {
                  try {
                    context.pushReplacement(
                      '/workout-summary',
                      extra: completedWorkout,
                    );
                  } catch (_) {
                    Navigator.of(context).maybePop();
                  }
                }
              },
              child: const Text(
                'Finish',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Crash Recovery Banner if an in-progress session exists
          if (activeState.recoveredWorkout != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2E1A1A)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unsaved session found: "${activeState.recoveredWorkout!.title}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => notifier.resumeRecoveredWorkout(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => notifier.discardRecoveredWorkout(),
                  ),
                ],
              ),
            ),

          // PR Celebration Banner
          if (activeState.lastCompletedSetPRs.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2E240D)
                    : const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.military_tech_rounded,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New PR! ${activeState.lastCompletedSetPRs.map((p) => '${p.recordType.toUpperCase().replaceAll('_', ' ')}: ${p.formattedRecord}').join(', ')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Rest Timer Banner if resting
          if (activeState.isResting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF142B1F)
                    : const Color(0xFFDCFCE7),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.limeGreen.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.limeGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rest Timer: ${_formatTimer(activeState.restTimeRemaining)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.limeGreen
                          : AppColors.limeGreenLight,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    tooltip: '-15s',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => notifier.adjustRestTimer(-15),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => notifier.adjustRestTimer(15),
                    child: const Text('+15s', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => notifier.adjustRestTimer(30),
                    child: const Text('+30s', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => notifier.skipRestTimer(),
                    child: const Text('Skip', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Workout Exercises List
          Expanded(
            child: workout.exercises.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkSurfaceBorder
                                    : AppColors.lightSurfaceBorder,
                              ),
                            ),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              size: 44,
                              color: isDark
                                  ? AppColors.limeGreen
                                  : AppColors.limeGreenLight,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Session Ready To Begin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activeState.isTimerRunning
                                ? 'Session timer is running. Tap below to pick an exercise.'
                                : 'Timer will begin when you add your first exercise or tap Start Timer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.limeGreen,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () =>
                                    _showAddExerciseModal(context, ref),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  'Add Exercise',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(
                                    color: activeState.isTimerRunning
                                        ? AppColors.warning
                                        : AppColors.limeGreen,
                                  ),
                                ),
                                onPressed: () => notifier.toggleTimer(),
                                icon: Icon(
                                  activeState.isTimerRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 20,
                                  color: activeState.isTimerRunning
                                      ? AppColors.warning
                                      : AppColors.limeGreen,
                                ),
                                label: Text(
                                  activeState.isTimerRunning
                                      ? 'Pause'
                                      : 'Start Timer',
                                  style: TextStyle(
                                    color: activeState.isTimerRunning
                                        ? AppColors.warning
                                        : AppColors.limeGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: workout.exercises.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx == workout.exercises.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(
                                  color: AppColors.limeGreen,
                                ),
                              ),
                              onPressed: () =>
                                  _showAddExerciseModal(context, ref),
                              icon: const Icon(
                                Icons.add,
                                color: AppColors.limeGreen,
                              ),
                              label: const Text(
                                'Add Exercise',
                                style: TextStyle(color: AppColors.limeGreen),
                              ),
                            ),
                          ),
                        );
                      }

                      final exIndex = idx;
                      final exercise = workout.exercises[exIndex];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurfaceBorder
                                : AppColors.lightSurfaceBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Exercise Header
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final exAsync = ref.watch(
                                        exerciseByIdProvider(
                                          exercise.exerciseId,
                                        ),
                                      );
                                      return exAsync.when(
                                        data: (ex) {
                                          if (ex == null) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12.0,
                                            ),
                                            child: ExerciseMediaVisual(
                                              mediaThumbnailUrl:
                                                  ex.mediaThumbnailUrl,
                                              mediaAnimationUrl:
                                                  ex.mediaAnimationUrl,
                                              imageAsset: ex.imageAsset,
                                              anatomyAsset: ex.anatomyAsset,
                                              category: ex.category,
                                              exerciseName: ex.name,
                                              mode: ExerciseMediaVisualMode
                                                  .thumbnail,
                                              width: 44,
                                              height: 44,
                                              isDark: isDark,
                                            ),
                                          );
                                        },
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, _) =>
                                            const SizedBox.shrink(),
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.exerciseName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          exercise.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        // Previous Performance Indicator Pill
                                        Consumer(
                                          builder: (context, ref, _) {
                                            final prevExAsync = ref.watch(
                                              previousExercisePerformanceProvider(
                                                exercise.exerciseId,
                                              ),
                                            );
                                            return prevExAsync.when(
                                              data: (prevEx) {
                                                if (prevEx == null ||
                                                    prevEx.sets.isEmpty) {
                                                  return const SizedBox.shrink();
                                                }
                                                final completedPrevSets = prevEx
                                                    .sets
                                                    .where((s) => s.isCompleted)
                                                    .toList();
                                                if (completedPrevSets.isEmpty) {
                                                  return const SizedBox.shrink();
                                                }
                                                final bestSet =
                                                    completedPrevSets.reduce(
                                                      (curr, next) =>
                                                          (curr.weightKg *
                                                                  curr.reps) >
                                                              (next.weightKg *
                                                                  next.reps)
                                                          ? curr
                                                          : next,
                                                    );

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppColors
                                                              .darkBackground
                                                        : const Color(
                                                            0xFFF1F5F9,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? AppColors
                                                                .darkSurfaceBorder
                                                          : AppColors
                                                                .lightSurfaceBorder,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.history_rounded,
                                                        size: 12,
                                                        color:
                                                            AppColors.limeGreen,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Last: ${completedPrevSets.length} sets • Best: ${bestSet.weightKg.toStringAsFixed(bestSet.weightKg % 1 == 0 ? 0 : 1)}kg × ${bestSet.reps}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? AppColors
                                                                    .darkTextSecondary
                                                              : AppColors
                                                                    .lightTextSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              loading: () =>
                                                  const SizedBox.shrink(),
                                              error: (err, stack) =>
                                                  const SizedBox.shrink(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'delete') {
                                        notifier.removeExercise(exIndex);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              color: AppColors.error,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Remove Exercise'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Sets Header Row
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      'SET',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'KG',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'REPS',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  SizedBox(
                                    width: 44,
                                    child: Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sets Rows
                            ...exercise.sets.asMap().entries.map((entry) {
                              final setIndex = entry.key;
                              final set = entry.value;

                              return _SetRow(
                                key: ValueKey(set.id),
                                setNumber: set.setNumber,
                                weightKg: set.weightKg,
                                reps: set.reps,
                                isCompleted: set.isCompleted,
                                isDark: isDark,
                                onWeightChanged: (val) {
                                  notifier.updateSet(
                                    exIndex,
                                    setIndex,
                                    weightKg: val,
                                  );
                                },
                                onRepsChanged: (val) {
                                  notifier.updateSet(
                                    exIndex,
                                    setIndex,
                                    reps: val,
                                  );
                                },
                                onToggleCompleted: () {
                                  notifier.toggleSetCompleted(
                                    exIndex,
                                    setIndex,
                                  );
                                },
                                onDeleteSet: () {
                                  notifier.removeSet(exIndex, setIndex);
                                },
                              );
                            }),

                            // Add Set Button
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () => notifier.addSet(exIndex),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Set'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExercisePickerSheet(
        onExercisesSelected: (exercises) {
          for (final exercise in exercises) {
            ref.read(activeWorkoutProvider.notifier).addExercise(exercise);
          }
          Navigator.pop(ctx);
        },
        onExerciseSelected: (exercise) {
          ref.read(activeWorkoutProvider.notifier).addExercise(exercise);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _SetRow extends StatefulWidget {
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isCompleted;
  final bool isDark;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDeleteSet;

  const _SetRow({
    super.key,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.isCompleted,
    required this.isDark,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleCompleted,
    required this.onDeleteSet,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.weightKg == widget.weightKg.roundToDouble()
          ? widget.weightKg.toInt().toString()
          : widget.weightKg.toString(),
    );
    _repsController = TextEditingController(text: widget.reps.toString());
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weightKg != widget.weightKg) {
      final text = widget.weightKg == widget.weightKg.roundToDouble()
          ? widget.weightKg.toInt().toString()
          : widget.weightKg.toString();
      if (_weightController.text != text) {
        _weightController.text = text;
      }
    }
    if (oldWidget.reps != widget.reps) {
      if (_repsController.text != widget.reps.toString()) {
        _repsController.text = widget.reps.toString();
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isCompleted
        ? (widget.isDark
              ? AppColors.limeGreen.withValues(alpha: 0.12)
              : AppColors.limeGreen.withValues(alpha: 0.08))
        : Colors.transparent;

    return Dismissible(
      key: ValueKey('dismiss-${widget.setNumber}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDeleteSet(),
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${widget.setNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: widget.isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    if (d != null) widget.onWeightChanged(d);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: widget.isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                  ),
                  onChanged: (val) {
                    final i = int.tryParse(val);
                    if (i != null) widget.onRepsChanged(i);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              child: IconButton(
                icon: Icon(
                  widget.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: widget.isCompleted
                      ? AppColors.limeGreen
                      : (widget.isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                ),
                onPressed: widget.onToggleCompleted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
