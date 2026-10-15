import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

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
            Text(
              _formatTimer(workout.durationSeconds),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.limeGreen : AppColors.limeGreenLight,
              ),
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
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () async {
                final completedWorkout = await notifier.finishWorkout();
                if (context.mounted && completedWorkout != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.limeGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Workout saved offline! (${completedWorkout.completedSets} sets completed)',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Finish', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rest Timer Banner if resting
          if (activeState.isResting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142B1F) : const Color(0xFFDCFCE7),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.limeGreen.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.limeGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Rest Timer: ${_formatTimer(activeState.restTimeRemaining)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppColors.limeGreen : AppColors.limeGreenLight,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => notifier.adjustRestTimer(30),
                    child: const Text('+30s'),
                  ),
                  TextButton(
                    onPressed: () => notifier.skipRestTimer(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

          // Workout Exercises List
          Expanded(
            child: workout.exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No exercises added yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap below to add an exercise from your library.',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddExerciseModal(context, ref),
                          icon: const Icon(Icons.add_rounded, color: Colors.black),
                          label: const Text(
                            'Add Exercise',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: workout.exercises.length + 1,
                    itemBuilder: (context, exIndex) {
                      if (exIndex == workout.exercises.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddExerciseModal(context, ref),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Another Exercise'),
                          ),
                        );
                      }

                      final exercise = workout.exercises[exIndex];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
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
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.exerciseName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          exercise.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
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
                                            Icon(Icons.delete_outline_rounded,
                                                color: AppColors.error, size: 18),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 32,
                                    child: Text(
                                      'SET',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
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
                                  const SizedBox(width: 8),
                                  const Expanded(
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
                                  const SizedBox(width: 8),
                                  const SizedBox(
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
                                  notifier.updateSet(exIndex, setIndex, weightKg: val);
                                },
                                onRepsChanged: (val) {
                                  notifier.updateSet(exIndex, setIndex, reps: val);
                                },
                                onToggleCompleted: () {
                                  notifier.toggleSetCompleted(exIndex, setIndex);
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
      builder: (ctx) => _ExercisePickerSheet(
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<ExerciseEntity> onExerciseSelected;

  const _ExercisePickerSheet({required this.onExerciseSelected});

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _query = '';
  String _selectedCategory = 'All';

  final _categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Exercise',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search exercise name or muscle...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (val) {
                setState(() => _query = val);
                ref
                    .read(exercisesFilterProvider.notifier)
                    .updateFilter(query: _query, category: _selectedCategory);
              },
            ),
          ),
          // Categories horizontal scroll
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                      ref
                          .read(exercisesFilterProvider.notifier)
                          .updateFilter(query: _query, category: cat);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(child: Text('No exercises found'));
                }
                return ListView.separated(
                  itemCount: exercises.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final ex = exercises[idx];
                    return ListTile(
                      title: Text(
                        ex.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${ex.category} • ${ex.targetMuscle}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.limeGreen),
                      onTap: () => widget.onExerciseSelected(ex),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
