import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/workout_providers.dart';

class AllRoutinesScreen extends ConsumerStatefulWidget {
  const AllRoutinesScreen({super.key});

  @override
  ConsumerState<AllRoutinesScreen> createState() => _AllRoutinesScreenState();
}

class _AllRoutinesScreenState extends ConsumerState<AllRoutinesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<_RoutineItem> _allRoutines = [
    _RoutineItem(
      id: 'routine-push',
      title: 'Push Day (Chest, Delts, Triceps)',
      category: 'Strength',
      duration: '45 mins',
      difficulty: 'Intermediate',
      description: 'Bench Press, Incline DB Press, Overhead Press, Cable Pushdowns',
      imageAsset: 'assets/images/categories/strength.png',
      color: AppColors.electricBlue,
      exerciseIds: ['ex-bench-press', 'ex-incline-db-press', 'ex-overhead-press', 'ex-tricep-pushdown'],
    ),
    _RoutineItem(
      id: 'routine-pull',
      title: 'Pull Day (Back, Rear Delts, Biceps)',
      category: 'Strength',
      duration: '50 mins',
      difficulty: 'Advanced',
      description: 'Conventional Deadlift, Pull-Ups, Barbell Row, Bicep Curls',
      imageAsset: 'assets/images/workouts/today_workout_athlete.png',
      color: AppColors.electricCyan,
      exerciseIds: ['ex-deadlift', 'ex-pullup', 'ex-barbell-row', 'ex-bicep-curl'],
    ),
    _RoutineItem(
      id: 'routine-legs',
      title: 'Leg Day (Quads, Hamstrings, Core)',
      category: 'Strength',
      duration: '55 mins',
      difficulty: 'Intermediate',
      description: 'Barbell Back Squats, Romanian Deadlifts, Walking Lunges, Plank',
      imageAsset: 'assets/images/categories/bodyweight.png',
      color: const Color(0xFFFF9E00),
      exerciseIds: ['ex-barbell-squat', 'ex-romanian-deadlift', 'ex-lunges', 'ex-plank'],
    ),
    _RoutineItem(
      id: 'routine-hiit-tabata',
      title: 'Tabata Full Throttle',
      category: 'HIIT',
      duration: '20 mins',
      difficulty: 'Advanced',
      description: '8 sets of 20s explosive work / 10s rest across compound exercises',
      imageAsset: 'assets/images/categories/hiit.png',
      color: const Color(0xFFFF6D00),
      exerciseIds: ['ex-pushup', 'ex-lunges', 'ex-plank'],
    ),
    _RoutineItem(
      id: 'routine-fat-burn',
      title: 'Zone 2 Fat Burn Intervals',
      category: 'Cardio',
      duration: '35 mins',
      difficulty: 'Beginner',
      description: 'Sub-maximal aerobic intervals for maximum fat oxidation',
      imageAsset: 'assets/images/categories/cardio.png',
      color: const Color(0xFFFF5252),
      exerciseIds: ['ex-lunges', 'ex-plank'],
    ),
    _RoutineItem(
      id: 'routine-calisthenics',
      title: 'Calisthenics Core & Pull Mastery',
      category: 'Bodyweight',
      duration: '30 mins',
      difficulty: 'Intermediate',
      description: 'Zero equipment bodyweight circuit for tendon resilience and core power',
      imageAsset: 'assets/images/categories/bodyweight.png',
      color: AppColors.electricCyan,
      exerciseIds: ['ex-pushup', 'ex-pullup', 'ex-plank'],
    ),
    _RoutineItem(
      id: 'routine-morning-flow',
      title: 'Morning Power Vinyasa',
      category: 'Yoga',
      duration: '25 mins',
      difficulty: 'All Levels',
      description: 'Spinal mobility, warrior flows, and hip openers for mindful strength',
      imageAsset: 'assets/images/categories/yoga.png',
      color: const Color(0xFF00E676),
      exerciseIds: ['ex-plank'],
    ),
    _RoutineItem(
      id: 'routine-speed-run',
      title: 'Track Sprints & Locomotive Pace',
      category: 'Running',
      duration: '30 mins',
      difficulty: 'Advanced',
      description: '400m speed intervals with active recovery walk splits',
      imageAsset: 'assets/images/categories/running.png',
      color: AppColors.limeGreen,
      exerciseIds: ['ex-lunges'],
    ),
    _RoutineItem(
      id: 'routine-spine-rehab',
      title: 'Total Spine & Joint Mobility',
      category: 'Mobility',
      duration: '20 mins',
      difficulty: 'All Levels',
      description: 'Dynamic joint flossing, cat-cows, and thoracic rotations for recovery',
      imageAsset: 'assets/images/categories/mobility.png',
      color: const Color(0xFF7C4DFF),
      exerciseIds: ['ex-plank'],
    ),
  ];

  void _startRoutine(_RoutineItem routine) {
    ref.read(workoutRepositoryProvider).getExercises().then((allExercises) {
      final selected = allExercises
          .where((e) => routine.exerciseIds.contains(e.id))
          .toList();

      ref.read(activeWorkoutProvider.notifier).startNewWorkout(
            title: routine.title,
            initialExercises: selected.isNotEmpty ? selected : null,
          );

      if (mounted) {
        context.push('/active-workout');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = [
      'All',
      'Strength',
      'Cardio',
      'HIIT',
      'Bodyweight',
      'Yoga',
      'Running',
      'Mobility',
    ];

    final filtered = _allRoutines.where((r) {
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Workout Routines & Plans',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center_rounded),
            tooltip: 'Start Empty Workout',
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).startNewWorkout();
              context.push('/active-workout');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search routines, splits or muscle targets...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Category Filter Pills
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (ctx, idx) {
                  final cat = categories[idx];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      selectedColor: AppColors.limeGreen,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.limeGreen
                            : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                      ),
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // 3. Routines List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No matching routines found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different category filter or search term.',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final r = filtered[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _startRoutine(r),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: r.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Image.asset(
                                          r.imageAsset,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.fitness_center_rounded,
                                            color: r.color,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: r.color.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    r.category,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: r.color,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${r.duration} • ${r.difficulty}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    r.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${r.exerciseIds.length} compound exercises',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.limeGreen,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        ),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.black),
                                        label: const Text(
                                          'Start Workout',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                                        ),
                                        onPressed: () => _startRoutine(r),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineItem {
  final String id;
  final String title;
  final String category;
  final String duration;
  final String difficulty;
  final String description;
  final String imageAsset;
  final Color color;
  final List<String> exerciseIds;

  const _RoutineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.description,
    required this.imageAsset,
    required this.color,
    required this.exerciseIds,
  });
}
