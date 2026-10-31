import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';
import '../controllers/workout_providers.dart';
import 'exercise_media_visual.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<ExerciseEntity>? onExerciseSelected;
  final ValueChanged<List<ExerciseEntity>>? onExercisesSelected;
  final List<String>? initiallySelectedExerciseIds;

  const ExercisePickerSheet({
    super.key,
    this.onExerciseSelected,
    this.onExercisesSelected,
    this.initiallySelectedExerciseIds,
  }) : assert(
         onExerciseSelected != null || onExercisesSelected != null,
         'Must provide either onExerciseSelected or onExercisesSelected',
       );

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  final Set<String> _selectedExerciseIds = {};
  final Map<String, ExerciseEntity> _selectedExerciseMap = {};

  final List<String> _categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Olympic Weightlifting',
    'Calisthenics',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initiallySelectedExerciseIds != null) {
      _selectedExerciseIds.addAll(widget.initiallySelectedExerciseIds!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExercise(ExerciseEntity exercise) {
    setState(() {
      if (_selectedExerciseIds.contains(exercise.id)) {
        _selectedExerciseIds.remove(exercise.id);
        _selectedExerciseMap.remove(exercise.id);
      } else {
        _selectedExerciseIds.add(exercise.id);
        _selectedExerciseMap[exercise.id] = exercise;
      }
    });
  }

  void _confirmSelection() {
    if (_selectedExerciseIds.isEmpty) return;

    final selectedList = _selectedExerciseMap.values.toList();
    if (widget.onExercisesSelected != null) {
      widget.onExercisesSelected!(selectedList);
    } else if (widget.onExerciseSelected != null) {
      for (final exercise in selectedList) {
        widget.onExerciseSelected!(exercise);
      }
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center_rounded;
      case 'back':
        return Icons.accessibility_new_rounded;
      case 'legs':
        return Icons.directions_walk_rounded;
      case 'shoulders':
        return Icons.sports_kabaddi_rounded;
      case 'arms':
        return Icons.front_hand_rounded;
      case 'core':
        return Icons.adjust_rounded;
      case 'cardio':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  void _showExercisePreview(
    BuildContext context,
    ExerciseEntity exercise,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (exercise.imageAsset != null)
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Image.asset(
                  exercise.imageAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Center(
                    child: Icon(
                      _getCategoryIcon(exercise.category),
                      size: 48,
                      color: AppColors.limeGreenDark,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(exercise.category),
                  avatar: const Icon(Icons.category_outlined, size: 16),
                ),
                Chip(
                  label: Text(exercise.equipment),
                  avatar: const Icon(Icons.handyman_outlined, size: 16),
                ),
                Chip(
                  label: Text(exercise.targetMuscle),
                  avatar: const Icon(Icons.fitness_center_rounded, size: 16),
                ),
                Chip(
                  label: Text(exercise.difficultyLevel),
                  avatar: const Icon(Icons.speed_rounded, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (exercise.instructionSteps.isNotEmpty)
              ...exercise.instructionSteps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.limeGreen,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                exercise.instructions,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _toggleExercise(exercise);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedExerciseIds.contains(exercise.id)
                    ? AppColors.error
                    : AppColors.limeGreen,
                foregroundColor: _selectedExerciseIds.contains(exercise.id)
                    ? Colors.white
                    : Colors.black,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                _selectedExerciseIds.contains(exercise.id)
                    ? Icons.remove_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                _selectedExerciseIds.contains(exercise.id)
                    ? 'Deselect from Workout'
                    : 'Select for Workout',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final exercisesAsync = ref.watch(exercisesListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header with count & close
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Exercises',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedExerciseIds.isEmpty
                            ? 'Tap any exercise to select. Select multiple if needed.'
                            : '${_selectedExerciseIds.length} ${_selectedExerciseIds.length == 1 ? 'exercise' : 'exercises'} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedExerciseIds.isEmpty
                              ? (isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary)
                              : AppColors.limeGreen,
                          fontWeight: _selectedExerciseIds.isEmpty
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedExerciseIds.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedExerciseIds.clear();
                        _selectedExerciseMap.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkTextSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  iconSize: 24,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search input with clear button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercise name, equipment, muscle...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          ref
                              .read(exercisesFilterProvider.notifier)
                              .updateFilter(
                                query: '',
                                category: _selectedCategory,
                              );
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceElevated
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
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
            height: 44,
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
                  selectedColor: AppColors.limeGreen,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.limeGreen
                        : (isDark
                              ? AppColors.darkSurfaceBorder
                              : AppColors.lightSurfaceBorder),
                  ),
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

          const SizedBox(height: 6),

          // Exercises List
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No exercises match your filter',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _selectedCategory = 'All';
                              });
                              ref
                                  .read(exercisesFilterProvider.notifier)
                                  .resetToAll();
                            },
                            child: const Text('Reset filters'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: exercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final ex = exercises[idx];
                    final isSelected = _selectedExerciseIds.contains(ex.id);
                    // Ensure the exercise map has this exercise instance if it was initially selected
                    if (isSelected &&
                        !_selectedExerciseMap.containsKey(ex.id)) {
                      _selectedExerciseMap[ex.id] = ex;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.limeGreen.withValues(alpha: 0.12)
                                  : AppColors.limeGreen.withValues(alpha: 0.08))
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.limeGreen
                              : (isDark
                                    ? AppColors.darkSurfaceBorder
                                    : AppColors.lightSurfaceBorder),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _toggleExercise(ex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Exercise Thumbnail
                              ExerciseMediaVisual(
                                mediaThumbnailUrl: ex.mediaThumbnailUrl,
                                mediaAnimationUrl: ex.mediaAnimationUrl,
                                imageAsset: ex.imageAsset,
                                anatomyAsset: ex.anatomyAsset,
                                category: ex.category,
                                exerciseName: ex.name,
                                mode: ExerciseMediaVisualMode.thumbnail,
                                width: 52,
                                height: 52,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 12),

                              // Text details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        fontSize: 15,
                                        color: isSelected && isDark
                                            ? AppColors.limeGreen
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${ex.category} • ${ex.targetMuscle} • ${ex.equipment}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            ex.difficultyLevel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkTextTertiary
                                                  : AppColors.lightTextTertiary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                ex.audienceSuitability
                                                        .toLowerCase() ==
                                                    'universal'
                                                ? AppColors.limeGreen
                                                      .withValues(alpha: 0.15)
                                                : Colors.blue.withValues(
                                                    alpha: 0.15,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            ex.audienceSuitability
                                                        .toLowerCase() ==
                                                    'universal'
                                                ? 'Universal'
                                                : '${ex.audienceSuitability[0].toUpperCase()}${ex.audienceSuitability.substring(1)} Focus',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  ex.audienceSuitability
                                                          .toLowerCase() ==
                                                      'universal'
                                                  ? (isDark
                                                        ? AppColors.limeGreen
                                                        : AppColors
                                                              .limeGreenDark)
                                                  : Colors.blueAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Info / preview button
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                ),
                                tooltip: 'Exercise info',
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                onPressed: () =>
                                    _showExercisePreview(context, ex, isDark),
                              ),

                              // Selection Toggle Checkbox
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.limeGreen
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.limeGreen
                                          : (isDark
                                                ? Colors.white38
                                                : Colors.black38),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: Colors.black,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.limeGreen),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          // Sticky Bottom Confirmation Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _selectedExerciseIds.isEmpty
                    ? null
                    : _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: isDark
                      ? Colors.white10
                      : Colors.black12,
                  disabledForegroundColor: isDark
                      ? Colors.white38
                      : Colors.black38,
                  elevation: _selectedExerciseIds.isEmpty ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_task_rounded, size: 20),
                label: Text(
                  _selectedExerciseIds.isEmpty
                      ? 'Select Exercises to Add'
                      : (_selectedExerciseIds.length == 1
                            ? 'Add 1 Exercise'
                            : 'Add ${_selectedExerciseIds.length} Exercises'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
