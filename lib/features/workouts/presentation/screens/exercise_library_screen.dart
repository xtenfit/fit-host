import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

import 'package:fit_host/features/profile/presentation/controllers/user_profile_controller.dart';
import 'package:go_router/go_router.dart';
import '../widgets/exercise_contribution_sheet.dart';
import '../widgets/exercise_media_visual.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _query = '';
  String _selectedCategory = 'All';

  final _categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];

  void _showAudienceInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.limeGreen),
            SizedBox(width: 8),
            Text('Audience Suitability', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Audience Filtering Works in Fit Host:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '• Universal Standard: Most movements are physiologically safe and effective for athletes of any gender. By default, exercises are classified as Universal.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 6),
            Text(
              '• Never Restrictive: Selecting Male or Female never hides universal exercises. It shows universal exercises alongside any targeted programming.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 6),
            Text(
              '• Evidence-Based: Exercise choices depend on individual mobility, goals, and training experience—not gender stereotypes.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppColors.limeGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesListProvider);
    final filter = ref.watch(exercisesFilterProvider);
    final profile = ref.watch(userProfileProvider);
    final userGender = profile.gender;
    final currentAudience = filter.effectiveAudienceFilter ?? userGender;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final audienceChips = [
      {'id': 'All', 'label': 'All'},
      {'id': 'universal', 'label': 'Universal'},
      {'id': 'male', 'label': 'Male (+Universal)'},
      {'id': 'female', 'label': 'Female (+Universal)'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, size: 20),
            tooltip: 'Exercise Wiki & Community Submissions',
            onPressed: () => context.push('/exercise-wiki'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            tooltip: 'Audience suitability explanation',
            onPressed: () => _showAudienceInfoDialog(context),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _query = '';
                _selectedCategory = 'All';
              });
              ref.read(exercisesFilterProvider.notifier).resetToAll();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
              color: AppColors.limeGreen,
            ),
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
                hintText: 'Search by exercise, muscle, or equipment...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() => _query = '');
                          ref
                              .read(exercisesFilterProvider.notifier)
                              .updateFilter(
                                query: '',
                                category: _selectedCategory,
                                audienceFilter: currentAudience,
                              );
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() => _query = val);
                ref
                    .read(exercisesFilterProvider.notifier)
                    .updateFilter(
                      query: _query,
                      category: _selectedCategory,
                      audienceFilter: currentAudience,
                    );
              },
            ),
          ),

          // Audience Filter Chips Row with info button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  'Audience:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: audienceChips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final chip = audienceChips[idx];
                        final chipId = chip['id']!;
                        final chipLabel = chip['label']!;
                        final isSelected =
                            currentAudience.toLowerCase() ==
                            chipId.toLowerCase();

                        return ChoiceChip(
                          avatar: chipId.toLowerCase() == 'universal'
                              ? const Icon(Icons.public_rounded, size: 14)
                              : null,
                          label: Text(chipLabel),
                          selected: isSelected,
                          selectedColor: AppColors.limeGreen,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : Colors.grey.shade200,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.black
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(exercisesFilterProvider.notifier)
                                  .updateFilter(
                                    query: _query,
                                    category: _selectedCategory,
                                    audienceFilter: chipId,
                                  );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
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
                      ref
                          .read(exercisesFilterProvider.notifier)
                          .updateFilter(
                            query: _query,
                            category: cat,
                            audienceFilter: currentAudience,
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
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
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
                                      '${ex.category} • ${ex.equipment}${ex.bodyPart != null ? ' • ${ex.bodyPart}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
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
                                            ? AppColors.limeGreen.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.blue.withValues(
                                                alpha: 0.15,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ex.audienceSuitability.toLowerCase() ==
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
                                                    : AppColors.limeGreenDark)
                                              : Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkSurfaceBorder
                                        : AppColors.lightSurfaceBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.limeGreen
                                            : AppColors.limeGreenDark,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: isDark
                                          ? AppColors.limeGreen
                                          : AppColors.limeGreenDark,
                                    ),
                                  ],
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(
    BuildContext context,
    ExerciseEntity exercise,
    bool isDark,
  ) {
    final activeWorkout = ref.read(activeWorkoutProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
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
            const SizedBox(height: 8),

            // Metadata Chips
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
                  label: Text(
                    exercise.audienceSuitability.toLowerCase() == 'universal'
                        ? 'Universal Suitability'
                        : '${exercise.audienceSuitability[0].toUpperCase()}${exercise.audienceSuitability.substring(1)} Suitability',
                  ),
                  avatar: const Icon(Icons.public_rounded, size: 16),
                ),
                if (exercise.bodyPart != null && exercise.bodyPart!.isNotEmpty)
                  Chip(
                    label: Text(exercise.bodyPart!),
                    avatar: const Icon(
                      Icons.accessibility_new_outlined,
                      size: 16,
                    ),
                  ),
                Chip(
                  label: Text(
                    '${exercise.difficultyLevel} • ${exercise.movementType}',
                  ),
                  avatar: const Icon(Icons.speed_rounded, size: 16),
                ),
              ],
            ),

            if (exercise.mediaAnimationUrl != null ||
                exercise.mediaThumbnailUrl != null ||
                exercise.imageAsset != null ||
                exercise.anatomyAsset != null) ...[
              const SizedBox(height: 14),
              ExerciseMediaVisual(
                mediaAnimationUrl: exercise.mediaAnimationUrl,
                mediaThumbnailUrl: exercise.mediaThumbnailUrl,
                imageAsset: exercise.imageAsset,
                anatomyAsset: exercise.anatomyAsset,
                category: exercise.category,
                exerciseName: exercise.name,
                mode: ExerciseMediaVisualMode.player,
                height: 220,
                isDark: isDark,
              ),
              if (exercise.mediaAttribution != null &&
                  exercise.mediaAttribution!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    exercise.mediaAttribution!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                          : AppColors.lightTextSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),
            const Text(
              'Target Muscles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              exercise.secondaryMuscles.isNotEmpty
                  ? '${exercise.targetMuscle} (Secondary: ${exercise.secondaryMuscles.join(', ')})'
                  : exercise.targetMuscle,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),

            if (exercise.safetyNotes != null &&
                exercise.safetyNotes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.safetyNotes!,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Instructions & Form',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            if (exercise.instructionSteps.isNotEmpty)
              ...exercise.instructionSteps.asMap().entries.map((entry) {
                return Padding(
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              Text(
                exercise.instructions,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),

            const SizedBox(height: 18),
            // TASL Attribution & Licensing Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 14,
                        color: AppColors.limeGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Provenance & Legal Attribution',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Content: ${exercise.contentAttribution ?? 'exercises-dataset (MIT License)'}\n'
                    'Visuals: ${exercise.mediaAttribution ?? '© Gym visual — https://gymvisual.com/'}\n'
                    'Fit Host Canonical ID: ${exercise.id}',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // Suggest Correction action button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.limeGreen,
                side: BorderSide(
                  color: AppColors.limeGreen.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text(
                'Suggest Correction or Form Refinement',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (c) =>
                      ExerciseContributionSheet(targetExercise: exercise),
                );
              },
            ),

            const SizedBox(height: 14),
            // Add to workout action button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_task_rounded),
                label: Text(
                  activeWorkout.isActive
                      ? 'Add to Current Workout'
                      : 'Start Workout with this Exercise',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (activeWorkout.isActive) {
                    ref
                        .read(activeWorkoutProvider.notifier)
                        .addExercise(exercise);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added ${exercise.name} to active workout',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ref
                        .read(activeWorkoutProvider.notifier)
                        .startNewWorkout(
                          title: exercise.name,
                          initialExercises: [exercise],
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Started new workout with ${exercise.name}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
