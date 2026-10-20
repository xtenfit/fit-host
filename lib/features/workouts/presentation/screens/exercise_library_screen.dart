import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _query = '';
  String _selectedCategory = 'All';

  final _categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesListProvider);
    final filter = ref.watch(exercisesFilterProvider);
    final profile = ref.watch(userProfileProvider);
    final userGender = profile.gender;
    final currentGenderFilter = filter.genderFilter ?? userGender;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Gender chip options
    final userGenderLabel = userGender.toLowerCase() == 'female'
        ? 'Female (${userGender[0].toUpperCase()}${userGender.substring(1)})'
        : (userGender.toLowerCase() == 'male'
            ? 'Male (${userGender[0].toUpperCase()}${userGender.substring(1)})'
            : '${userGender[0].toUpperCase()}${userGender.substring(1)} Focus');

    final genderChips = [
      {'id': 'All', 'label': 'All'},
      {'id': 'male', 'label': 'Male Focus'},
      {'id': 'female', 'label': 'Female Focus'},
      {'id': userGender, 'label': userGenderLabel},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _query = '';
                _selectedCategory = 'All';
              });
              ref.read(exercisesFilterProvider.notifier).resetToAll();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.limeGreen),
            label: const Text(
              'Show all',
              style: TextStyle(
                color: AppColors.limeGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by exercise or muscle...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() => _query = '');
                          ref.read(exercisesFilterProvider.notifier).updateFilter(
                                query: '',
                                category: _selectedCategory,
                                genderFilter: currentGenderFilter,
                              );
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() => _query = val);
                ref.read(exercisesFilterProvider.notifier).updateFilter(
                      query: _query,
                      category: _selectedCategory,
                      genderFilter: currentGenderFilter,
                    );
              },
            ),
          ),

          // Gender Focus Chip Row
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: genderChips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final chip = genderChips[idx];
                final chipId = chip['id']!;
                final chipLabel = chip['label']!;
                final isSelected = currentGenderFilter.toLowerCase() == chipId.toLowerCase();

                return ChoiceChip(
                  avatar: chipId.toLowerCase() == userGender.toLowerCase() && chipId.toLowerCase() != 'all'
                      ? const Icon(Icons.person_rounded, size: 14, color: Colors.black)
                      : null,
                  label: Text(chipLabel),
                  selected: isSelected,
                  selectedColor: AppColors.limeGreen,
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.black
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(exercisesFilterProvider.notifier).updateFilter(
                            query: _query,
                            category: _selectedCategory,
                            genderFilter: chipId,
                          );
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Category Chips Row
          SizedBox(
            height: 38,
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
                  selectedColor: AppColors.electricBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                      ref.read(exercisesFilterProvider.notifier).updateFilter(
                            query: _query,
                            category: cat,
                            genderFilter: currentGenderFilter,
                          );
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
                  return Center(
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
                        const Text('No exercises matched your query.'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  itemCount: exercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final ex = exercises[idx];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showExerciseDetails(context, ex, isDark),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkSurfaceBorder
                                        : AppColors.lightSurfaceBorder,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: ex.imageAsset != null
                                      ? Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Image.asset(
                                            ex.imageAsset!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) => Center(
                                              child: Icon(
                                                _getCategoryIcon(ex.category),
                                                color: AppColors.limeGreenDark,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            _getCategoryIcon(ex.category),
                                            color: AppColors.limeGreenDark,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ex.category} • ${ex.equipment}',
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
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.darkTextTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
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
      default:
        return Icons.fitness_center_rounded;
    }
  }

  void _showExerciseDetails(
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(exercise.category),
                  avatar: const Icon(Icons.category_outlined, size: 16),
                ),
                Chip(
                  label: Text(exercise.equipment),
                  avatar: const Icon(Icons.handyman_outlined, size: 16),
                ),
              ],
            ),
            if (exercise.imageAsset != null || exercise.anatomyAsset != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (exercise.imageAsset != null)
                    Expanded(
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurfaceBorder
                                : AppColors.lightSurfaceBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Exercise Form',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            Expanded(
                              child: Image.asset(
                                exercise.imageAsset!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(
                                    _getCategoryIcon(exercise.category),
                                    color: AppColors.limeGreenDark,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (exercise.imageAsset != null &&
                      exercise.anatomyAsset != null)
                    const SizedBox(width: 10),
                  if (exercise.anatomyAsset != null)
                    Expanded(
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.limeGreen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Target Anatomy',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.limeGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Image.asset(
                                exercise.anatomyAsset!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Target Muscles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              exercise.targetMuscle,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions & Form',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              exercise.instructions,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
