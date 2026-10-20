import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/workout_providers.dart';

class WorkoutCategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const WorkoutCategoryDetailScreen({super.key, required this.categoryName});

  @override
  ConsumerState<WorkoutCategoryDetailScreen> createState() =>
      _WorkoutCategoryDetailScreenState();
}

class _WorkoutCategoryDetailScreenState
    extends ConsumerState<WorkoutCategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _CategoryConfig _getConfig(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('strength')) {
      return _CategoryConfig(
        title: 'Strength Training',
        subtitle: 'Build lean muscle mass, raw power & bone density',
        imageAsset: 'assets/images/categories/strength.png',
        color: AppColors.electricBlue,
        intensity: 'High Intensity',
        caloriesPerHour: '450 - 650 kcal/hr',
        targetMuscles: 'Full Body • Hypertrophy & Power',
        benefits: [
          'Stimulates muscle protein synthesis and hypertrophy',
          'Increases resting metabolic rate and strength',
          'Fortifies connective tissues and joint stability',
        ],
        routines: [
          _CategoryRoutine(
            title: 'Push Day Hypertrophy',
            duration: '45 mins',
            difficulty: 'Intermediate',
            description: 'Flat Bench Press, Incline DB Press, Overhead Press, Tricep Pushdown',
            exerciseIds: ['ex-bench-press', 'ex-incline-db-press', 'ex-overhead-press', 'ex-tricep-pushdown'],
          ),
          _CategoryRoutine(
            title: 'Pull Day Power & Lats',
            duration: '50 mins',
            difficulty: 'Advanced',
            description: 'Deadlifts, Weighted Pull-Ups, Barbell Rows, Hammer Curls',
            exerciseIds: ['ex-deadlift', 'ex-pullup', 'ex-barbell-row', 'ex-bicep-curl'],
          ),
          _CategoryRoutine(
            title: 'Leg Day Annihilation',
            duration: '55 mins',
            difficulty: 'Intermediate',
            description: 'Barbell Back Squats, Romanian Deadlifts, Walking Lunges',
            exerciseIds: ['ex-barbell-squat', 'ex-romanian-deadlift', 'ex-lunges'],
          ),
          _CategoryRoutine(
            title: 'Upper Body Explosive Split',
            duration: '40 mins',
            difficulty: 'Beginner - Intermediate',
            description: 'Bench Press, Pull-Ups, Lateral Raises, Tricep Extensions',
            exerciseIds: ['ex-bench-press', 'ex-pullup', 'ex-overhead-press', 'ex-tricep-pushdown'],
          ),
        ],
      );
    } else if (lower.contains('cardio')) {
      return _CategoryConfig(
        title: 'Cardiovascular Conditioning',
        subtitle: 'Burn stubborn fat, boost VO2 Max & stamina',
        imageAsset: 'assets/images/categories/cardio.png',
        color: const Color(0xFFFF5252),
        intensity: 'Moderate - High',
        caloriesPerHour: '500 - 750 kcal/hr',
        targetMuscles: 'Cardiovascular System • Legs • Core',
        benefits: [
          'Maximizes mitochondrial density and capillary blood flow',
          'Promotes sustained fat oxidation and stamina',
          'Significantly lowers resting heart rate & blood pressure',
        ],
        routines: [
          _CategoryRoutine(
            title: 'Fat Burn Interval Circuit',
            duration: '35 mins',
            difficulty: 'All Levels',
            description: 'High-intensity interval sprints followed by active aerobic recovery',
            exerciseIds: ['ex-lunges', 'ex-pushup', 'ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Zone 2 Base Aerobic Builder',
            duration: '45 mins',
            difficulty: 'Beginner',
            description: 'Steady sub-maximal pacing to build deep mitochondrial capacity',
            exerciseIds: ['ex-lunges', 'ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Full Body Endurance Burn',
            duration: '30 mins',
            difficulty: 'Intermediate',
            description: 'High-cadence bodyweight circuits with minimal rest windows',
            exerciseIds: ['ex-pushup', 'ex-pullup', 'ex-lunges', 'ex-plank'],
          ),
        ],
      );
    } else if (lower.contains('hiit')) {
      return _CategoryConfig(
        title: 'High Intensity Interval Training',
        subtitle: 'Maximum calorie burn & EPOC afterburn effect',
        imageAsset: 'assets/images/categories/hiit.png',
        color: const Color(0xFFFF6D00),
        intensity: 'Extreme Peak',
        caloriesPerHour: '600 - 900 kcal/hr',
        targetMuscles: 'Total Body • Glycolytic System',
        benefits: [
          'Triggers post-exercise oxygen consumption (EPOC afterburn)',
          'High calorie expenditure in minimal training time',
          'Spikes growth hormone and metabolic conditioning',
        ],
        routines: [
          _CategoryRoutine(
            title: 'Tabata Full Throttle (20s on / 10s off)',
            duration: '20 mins',
            difficulty: 'Advanced',
            description: '8 sets of max effort explosive intervals across 4 compound movements',
            exerciseIds: ['ex-pushup', 'ex-lunges', 'ex-plank'],
          ),
          _CategoryRoutine(
            title: '20-Min MetCon Inferno',
            duration: '20 mins',
            difficulty: 'Intermediate',
            description: 'Every Minute on the Minute (EMOM) rapid-fire conditioning',
            exerciseIds: ['ex-pushup', 'ex-lunges', 'ex-pullup', 'ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Core & Sprint Rapid Burn',
            duration: '15 mins',
            difficulty: 'All Levels',
            description: 'Tabata core shred followed by high cadence plyometrics',
            exerciseIds: ['ex-plank', 'ex-lunges'],
          ),
        ],
      );
    } else if (lower.contains('bodyweight') || lower.contains('calisthenic')) {
      return _CategoryConfig(
        title: 'Calisthenics & Bodyweight',
        subtitle: 'Master relative strength without gym equipment',
        imageAsset: 'assets/images/categories/bodyweight.png',
        color: AppColors.electricCyan,
        intensity: 'Progressive Body Control',
        caloriesPerHour: '350 - 550 kcal/hr',
        targetMuscles: 'Core • Shoulder Girdle • Kinetic Chain',
        benefits: [
          'Develops gymnastic body control and tendon resilience',
          'Zero equipment required — train anywhere in the world',
          'Builds bulletproof core stability and shoulder health',
        ],
        routines: [
          _CategoryRoutine(
            title: 'Calisthenics Foundations',
            duration: '30 mins',
            difficulty: 'Beginner',
            description: 'Strict push-ups, pull-ups, bodyweight squats and isometric hollow holds',
            exerciseIds: ['ex-pushup', 'ex-pullup', 'ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Upper Body Push/Pull Mastery',
            duration: '40 mins',
            difficulty: 'Intermediate',
            description: 'Diamond push-ups, explosive pull-ups and core planks',
            exerciseIds: ['ex-pushup', 'ex-pullup', 'ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Hotel Room 15-Min Blitz',
            duration: '15 mins',
            difficulty: 'All Levels',
            description: 'High-density bodyweight circuit for travelers on tight schedules',
            exerciseIds: ['ex-pushup', 'ex-lunges', 'ex-plank'],
          ),
        ],
      );
    } else if (lower.contains('yoga')) {
      return _CategoryConfig(
        title: 'Yoga & Flow',
        subtitle: 'Flexibility, decompression & breath control',
        imageAsset: 'assets/images/categories/yoga.png',
        color: const Color(0xFF00E676),
        intensity: 'Mindful & Restorative',
        caloriesPerHour: '200 - 350 kcal/hr',
        targetMuscles: 'Spine • Pelvic Girdle • Central Nervous System',
        benefits: [
          'Decompresses lumbar and cervical spine after heavy lifting',
          'Downregulates cortisol and activates parasympathetic recovery',
          'Dramatically improves joint range of motion & balance',
        ],
        routines: [
          _CategoryRoutine(
            title: 'Morning Power Vinyasa',
            duration: '25 mins',
            difficulty: 'All Levels',
            description: 'Sun salutations, warrior flows, and active spinal articulation',
            exerciseIds: ['ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Deep Hip & Hamstring Release',
            duration: '30 mins',
            difficulty: 'Beginner',
            description: 'Targeted pigeon poses, forward folds, and glute stretches',
            exerciseIds: ['ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Post-Workout Decompression',
            duration: '15 mins',
            difficulty: 'All Levels',
            description: 'Full body restorative flow to accelerate muscle repair',
            exerciseIds: ['ex-plank'],
          ),
        ],
      );
    } else if (lower.contains('running')) {
      return _CategoryConfig(
        title: 'Running & Sprints',
        subtitle: 'Road pace, track sprints & locomotive power',
        imageAsset: 'assets/images/categories/running.png',
        color: AppColors.limeGreen,
        intensity: 'Aerobic & Anaerobic Pace',
        caloriesPerHour: '600 - 850 kcal/hr',
        targetMuscles: 'Quadriceps • Hamstrings • Calves • Cardiovascular',
        benefits: [
          'Builds explosive stride power and locomotive stamina',
          'Fortifies leg tendons and ankle joint resilience',
          'Elevates mood and mental fortitude via endorphin surges',
        ],
        routines: [
          _CategoryRoutine(
            title: 'Track Sprint Intervals (400m Splits)',
            duration: '30 mins',
            difficulty: 'Advanced',
            description: 'High speed intervals with active walk recovery',
            exerciseIds: ['ex-lunges', 'ex-plank'],
          ),
          _CategoryRoutine(
            title: '5K Tempo Pace Builder',
            duration: '35 mins',
            difficulty: 'Intermediate',
            description: 'Targeted lactate threshold run at sustained competitive pace',
            exerciseIds: ['ex-lunges'],
          ),
          _CategoryRoutine(
            title: 'Easy Recovery Aerobic Jog',
            duration: '25 mins',
            difficulty: 'Beginner',
            description: 'Sub-maximal heart rate recovery run to flush metabolic waste',
            exerciseIds: ['ex-lunges'],
          ),
        ],
      );
    } else if (lower.contains('cycling')) {
      return _CategoryConfig(
        title: 'Cycling & Wattage',
        subtitle: 'Low-impact cadence power & quad endurance',
        imageAsset: 'assets/images/categories/cycling.png',
        color: const Color(0xFFFFAB00),
        intensity: 'High Cadence Power',
        caloriesPerHour: '500 - 800 kcal/hr',
        targetMuscles: 'Quadriceps • Glutes • Heart & Lungs',
        benefits: [
          'Zero impact on knees and ankles while delivering massive calorie burn',
          'Builds dense quadriceps power and aerobic threshold',
          'Perfect cross-training tool during deload weeks',
        ],
        routines: [
          _CategoryRoutine(
            title: 'High Cadence Spin Intervals',
            duration: '30 mins',
            difficulty: 'Intermediate',
            description: 'Rapid cadence surges interspersed with heavy resistance flats',
            exerciseIds: ['ex-lunges', 'ex-barbell-squat'],
          ),
          _CategoryRoutine(
            title: 'Hill Climb Torque Simulation',
            duration: '45 mins',
            difficulty: 'Advanced',
            description: 'High resistance standing climbs to build raw leg drive',
            exerciseIds: ['ex-barbell-squat', 'ex-lunges'],
          ),
        ],
      );
    } else {
      // Mobility & Recovery default
      return _CategoryConfig(
        title: 'Mobility & Recovery',
        subtitle: 'Joint health, dynamic stretching & tissue rehab',
        imageAsset: 'assets/images/categories/mobility.png',
        color: const Color(0xFF7C4DFF),
        intensity: 'Restorative Care',
        caloriesPerHour: '150 - 250 kcal/hr',
        targetMuscles: 'Total Kinetic Chain • Facets & Fascia',
        benefits: [
          'Restores lost mobility and eliminates muscular imbalances',
          'Flushes muscular soreness and speeds neuromuscular recovery',
          'Safeguards against training injuries and joint wear',
        ],
        routines: [
          _CategoryRoutine(
            title: 'Total Spine & Thoracic Unlock',
            duration: '20 mins',
            difficulty: 'All Levels',
            description: 'Cat-cows, thread-the-needle, and foam roller thoracic extensions',
            exerciseIds: ['ex-plank'],
          ),
          _CategoryRoutine(
            title: 'Lower Body Flosser & Ankles',
            duration: '25 mins',
            difficulty: 'All Levels',
            description: 'Deep ankle dorsiflexion, couch stretch, and hip 90/90s',
            exerciseIds: ['ex-lunges'],
          ),
        ],
      );
    }
  }

  Future<void> _startRoutine(BuildContext context, _CategoryRoutine routine) async {
    final allExercises = await ref.read(workoutRepositoryProvider).getExercises();
    if (!context.mounted) return;

    final selected = allExercises
        .where((e) => routine.exerciseIds.contains(e.id))
        .toList();

    ref.read(activeWorkoutProvider.notifier).startNewWorkout(
          title: routine.title,
          initialExercises: selected.isNotEmpty ? selected : null,
        );

    context.push('/active-workout');
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(widget.categoryName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final exercisesAsync = ref.watch(exercisesListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // 1. Collapsing Hero App Bar with Category Banner
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                config.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          config.color.withValues(alpha: 0.8),
                          const Color(0xFF0A0F1D),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 20,
                    bottom: 20,
                    width: 200,
                    child: Image.asset(
                      config.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.fitness_center_rounded,
                        size: 80,
                        color: config.color.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 40,
                    right: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: config.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.intensity.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          config.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Overview Stats & Quick Start Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fast Quick Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.color,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24, color: Colors.black),
                      label: Text(
                        'Start Quick ${widget.categoryName} Session',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                      ),
                      onPressed: () {
                        if (config.routines.isNotEmpty) {
                          _startRoutine(context, config.routines.first);
                        } else {
                          ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                                title: '${widget.categoryName} Session',
                              );
                          context.push('/active-workout');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Calorie Burn',
                          value: config.caloriesPerHour,
                          icon: Icons.local_fire_department_rounded,
                          color: Colors.orange,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Target Focus',
                          value: config.targetMuscles,
                          icon: Icons.track_changes_rounded,
                          color: config.color,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Switcher (Routines vs Exercises)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: config.color,
                      labelColor: config.color,
                      unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: 'Curated Routines'),
                        Tab(text: 'Category Exercises'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Tab Contents
          SliverFillRemaining(
            hasScrollBody: true,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sub-tab 1: Routines
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  itemCount: config.routines.length,
                  itemBuilder: (ctx, idx) {
                    final routine = config.routines[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  routine.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: config.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  routine.duration,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: config.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            routine.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Difficulty: ${routine.difficulty}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: config.color,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.black),
                                label: const Text('Start Routine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                                onPressed: () => _startRoutine(context, routine),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Sub-tab 2: Exercises Library filtered by Category
                exercisesAsync.when(
                  data: (exercises) {
                    final filtered = exercises.where((e) {
                      final lowerCat = widget.categoryName.toLowerCase();
                      if (lowerCat.contains('strength')) return true;
                      if (lowerCat.contains('cardio')) return e.equipment.toLowerCase().contains('body') || e.category == 'Legs';
                      if (lowerCat.contains('hiit')) return e.equipment.toLowerCase().contains('body') || e.category == 'Core';
                      if (lowerCat.contains('bodyweight')) return e.equipment.toLowerCase().contains('body');
                      return true;
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final ex = filtered[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: config.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.fitness_center_rounded, color: config.color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ex.category} • ${ex.equipment}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                                color: config.color,
                                tooltip: 'Start Exercise',
                                onPressed: () {
                                  ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                                        title: '${ex.name} Session',
                                        initialExercises: [ex],
                                      );
                                  context.push('/active-workout');
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading exercises: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryConfig {
  final String title;
  final String subtitle;
  final String imageAsset;
  final Color color;
  final String intensity;
  final String caloriesPerHour;
  final String targetMuscles;
  final List<String> benefits;
  final List<_CategoryRoutine> routines;

  const _CategoryConfig({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.color,
    required this.intensity,
    required this.caloriesPerHour,
    required this.targetMuscles,
    required this.benefits,
    required this.routines,
  });
}

class _CategoryRoutine {
  final String title;
  final String duration;
  final String difficulty;
  final String description;
  final List<String> exerciseIds;

  const _CategoryRoutine({
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.description,
    required this.exerciseIds,
  });
}
