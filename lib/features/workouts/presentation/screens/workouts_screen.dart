import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_host/core/data/workout_repository.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/theme/app_motion.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  String _routineType = 'All'; // 'All', 'Curated', 'Custom'
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routineRepositoryProvider).seedTemplateRoutines();
    });
  }

  void _startRoutine(RoutineEntity routine) {
    ref.read(activeWorkoutProvider.notifier).startFromRoutine(routine);
    if (mounted) {
      context.push('/active-workout');
    }
  }

  Future<void> _duplicateRoutine(RoutineEntity routine) async {
    try {
      final copyName = '${routine.name} (Copy)';
      await ref
          .read(routineRepositoryProvider)
          .duplicateRoutine(routine.id, newName: copyName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routine duplicated: "$copyName"'),
            backgroundColor: AppColors.limeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoutine(RoutineEntity routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: Text(
          'Are you sure you want to delete "${routine.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(routineRepositoryProvider).deleteRoutine(routine.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Routine "${routine.name}" deleted.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting routine: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final routinesAsync = ref.watch(routinesStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Workouts',
            style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.w800),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                ref
                    .read(activeWorkoutProvider.notifier)
                    .startNewWorkout(
                      title:
                          'Workout ${DateFormat('EEE, MMM d').format(DateTime.now())}',
                    );
                context.push('/active-workout');
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'New Workout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.limeGreen),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'New Routine',
              onPressed: () => context.push('/routines/builder'),
            ),
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'Exercise Library',
              onPressed: () => context.push('/exercises'),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.limeGreen,
            labelColor: AppColors.limeGreen,
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Routines & Plans'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // 1. History Tab
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(workoutsStreamProvider);
                },
                child: workoutsAsync.when(
                  data: (workouts) {
                    final history = workouts
                        .where(
                          (workout) =>
                              workout.status == 'completed' ||
                              workout.status == 'cancelled',
                        )
                        .toList();
                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No workout history yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete a session to start tracking your progress.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(activeWorkoutProvider.notifier)
                                    .startNewWorkout();
                                context.push('/active-workout');
                              },
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Start First Workout',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                      physics: const BouncingScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, idx) {
                        final w = history[idx];
                        final dateStr = DateFormat(
                          'EEEE, MMM d, y • h:mm a',
                        ).format(w.startedAt);

                        return BouncyTap(
                          scaleDown: 0.97,
                          onTap: () => context.push('/workout/${w.id}'),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          w.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: w.status == 'completed'
                                              ? AppColors.limeGreen.withValues(
                                                  alpha: 0.15,
                                                )
                                              : AppColors.warning.withValues(
                                                  alpha: 0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          w.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: w.status == 'completed'
                                                ? AppColors.limeGreen
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextTertiary
                                          : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _Metric(
                                        label: 'Duration',
                                        value: _formatDuration(
                                          w.durationSeconds,
                                        ),
                                        isDark: isDark,
                                      ),
                                      _Metric(
                                        label: 'Sets',
                                        value:
                                            '${w.completedSets}/${w.totalSets}',
                                        isDark: isDark,
                                      ),
                                      _Metric(
                                        label: 'Volume',
                                        value: '${w.totalVolumeKg.toInt()} kg',
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),

              // 2. Combined Routines & Plans Tab
              routinesAsync.when(
                data: (routines) {
                  final filtered = routines.where((r) {
                    if (_routineType == 'Curated' && !r.isTemplate) {
                      return false;
                    }
                    if (_routineType == 'Custom' && r.isTemplate) {
                      return false;
                    }
                    if (_selectedCategory != 'All') {
                      final cat = r.category.toLowerCase();
                      final target = _selectedCategory.toLowerCase();
                      final matchCat = cat.contains(target);
                      final matchTags = r.tags.any(
                        (t) => t.toLowerCase().contains(target),
                      );
                      if (!matchCat && !matchTags) return false;
                    }
                    return true;
                  }).toList();

                  final customCount = routines
                      .where((r) => !r.isTemplate)
                      .length;
                  final curatedCount = routines
                      .where((r) => r.isTemplate)
                      .length;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // QUICK ACTIONS BAR
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () =>
                                      context.push('/routines/builder'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.limeGreen.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_circle_outline_rounded,
                                          size: 18,
                                          color: AppColors.limeGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create Routine',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => context.push('/routines'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkSurfaceBorder
                                            : AppColors.lightSurfaceBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.format_list_bulleted_rounded,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Manage Routines',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // SECTION 1: WORKOUT CATEGORIES CAROUSEL
                      SliverPersistentHeader(
                        pinned: false,
                        delegate: _StickySectionHeaderDelegate(
                          title: 'Workout Categories',
                          badge: '8 DISCIPLINES',
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 116,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _kCategories.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              final cat = _kCategories[idx];
                              return _CategoryCard(
                                category: cat,
                                isDark: isDark,
                                onTap: () => context.push(
                                  '/workout-category/${cat.name}',
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      // SECTION 2: ACTIVE PLAN
                      SliverPersistentHeader(
                        pinned: false,
                        delegate: _StickySectionHeaderDelegate(
                          title: 'Active Training Plan',
                          badge: 'FEATURED',
                          isDark: isDark,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: _ActivePlanCard(
                            title: 'Hypertrophy & Power Mass',
                            subtitle:
                                'Recommended • 4-5 workouts / week • 60 min',
                            progress: 0.0,
                            progressText: '12-Week Structured Progression',
                            imageAsset:
                                'assets/images/workouts/today_workout_athlete.png',
                            isDark: isDark,
                            onTap: () =>
                                context.push('/workout/plan-hypertrophy'),
                            onResume: () {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .startNewWorkout(
                                    title: 'Hypertrophy & Power Mass - Day 1',
                                  );
                              context.push('/active-workout');
                            },
                          ),
                        ),
                      ),

                      // SECTION 3: WORKOUT ROUTINES & CUSTOM SPLITS
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickySectionHeaderDelegate(
                          title: 'Workout Routines & Splits',
                          badge: '${filtered.length} AVAILABLE',
                          isDark: isDark,
                        ),
                      ),

                      // FILTER SEGMENTS & CATEGORY PILLS
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type Filter Tabs
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkSurfaceBorder
                                        : AppColors.lightSurfaceBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildTypeTab(
                                      'All Routines',
                                      'All',
                                      routines.length,
                                      isDark,
                                    ),
                                    _buildTypeTab(
                                      'Curated',
                                      'Curated',
                                      curatedCount,
                                      isDark,
                                    ),
                                    _buildTypeTab(
                                      'My Custom',
                                      'Custom',
                                      customCount,
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Category Pills
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children:
                                      [
                                        'All',
                                        'Strength',
                                        'Hypertrophy',
                                        'Cardio',
                                        'HIIT',
                                        'Bodyweight',
                                        'Mobility',
                                      ].map((catName) {
                                        final isSelected =
                                            _selectedCategory == catName;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(
                                              catName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? Colors.black
                                                    : (isDark
                                                          ? Colors.white70
                                                          : AppColors
                                                                .lightTextPrimary),
                                              ),
                                            ),
                                            selected: isSelected,
                                            selectedColor: AppColors.limeGreen,
                                            backgroundColor: isDark
                                                ? AppColors.darkSurface
                                                : AppColors.lightSurface,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              side: BorderSide(
                                                color: isSelected
                                                    ? AppColors.limeGreen
                                                    : (isDark
                                                          ? AppColors
                                                                .darkSurfaceBorder
                                                          : AppColors
                                                                .lightSurfaceBorder),
                                              ),
                                            ),
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(
                                                  () => _selectedCategory =
                                                      catName,
                                                );
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ROUTINES LIST
                      if (filtered.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _buildEmptyState(isDark),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              idx,
                            ) {
                              final routine = filtered[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _UnifiedRoutineCard(
                                  routine: routine,
                                  isDark: isDark,
                                  onStart: () => _startRoutine(routine),
                                  onDuplicate: () => _duplicateRoutine(routine),
                                  onDelete: () => _deleteRoutine(routine),
                                ),
                              );
                            }, childCount: filtered.length),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text('Error loading routines: $err'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(routinesStreamProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, String type, int count, bool isDark) {
    final isSelected = _routineType == type;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _routineType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.limeGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.black
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.15)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.black
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    if (_routineType == 'Custom') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? AppColors.darkSurfaceBorder
                : AppColors.lightSurfaceBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.limeGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_add_rounded,
                size: 36,
                color: AppColors.limeGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Custom Routines Yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Design your personalized workout split with your favorite exercises, sets, reps, and rest timers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 18),
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
              icon: const Icon(Icons.add_rounded, color: Colors.black),
              label: const Text(
                'Create Custom Routine',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              onPressed: () => context.push('/routines/builder'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
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
              'No routines found matching your filter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _routineType = 'All';
                  _selectedCategory = 'All';
                });
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final String asset;
  final Color color;
  final String countText;

  const _CategoryItem({
    required this.name,
    required this.asset,
    required this.color,
    required this.countText,
  });
}

const _kCategories = [
  _CategoryItem(
    name: 'Strength',
    asset: 'assets/images/categories/strength.png',
    color: Color(0xFF3D7AF5),
    countText: 'Hypertrophy & Power',
  ),
  _CategoryItem(
    name: 'Cardio',
    asset: 'assets/images/categories/cardio.png',
    color: Color(0xFFFF5252),
    countText: 'Heart & Stamina',
  ),
  _CategoryItem(
    name: 'HIIT',
    asset: 'assets/images/categories/hiit.png',
    color: Color(0xFFFF7043),
    countText: 'Metabolic Circuit',
  ),
  _CategoryItem(
    name: 'Bodyweight',
    asset: 'assets/images/categories/bodyweight.png',
    color: Color(0xFF66BB6A),
    countText: 'Calisthenics Mastery',
  ),
  _CategoryItem(
    name: 'Mobility',
    asset: 'assets/images/categories/mobility.png',
    color: Color(0xFF26A69A),
    countText: 'Joints & Recovery',
  ),
  _CategoryItem(
    name: 'Yoga',
    asset: 'assets/images/categories/yoga.png',
    color: Color(0xFFAB47BC),
    countText: 'Flow & Breathwork',
  ),
  _CategoryItem(
    name: 'Running',
    asset: 'assets/images/categories/running.png',
    color: Color(0xFF29B6F6),
    countText: 'Endurance & Pace',
  ),
  _CategoryItem(
    name: 'Cycling',
    asset: 'assets/images/categories/cycling.png',
    color: Color(0xFFFFA726),
    countText: 'Cadence & Power',
  ),
];

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      scaleDown: 0.95,
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.color.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    color: category.color.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      category.asset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.fitness_center_rounded,
                        color: category.color,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.countText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedRoutineCard extends StatelessWidget {
  final RoutineEntity routine;
  final bool isDark;
  final VoidCallback onStart;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _UnifiedRoutineCard({
    required this.routine,
    required this.isDark,
    required this.onStart,
    required this.onDuplicate,
    required this.onDelete,
  });

  String _getImageAsset(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('strength') || lower.contains('hypertrophy')) {
      return 'assets/images/categories/strength.png';
    } else if (lower.contains('cardio') || lower.contains('running')) {
      return 'assets/images/categories/cardio.png';
    } else if (lower.contains('hiit')) {
      return 'assets/images/categories/hiit.png';
    } else if (lower.contains('mobility') || lower.contains('yoga')) {
      return 'assets/images/categories/mobility.png';
    }
    return 'assets/images/categories/bodyweight.png';
  }

  @override
  Widget build(BuildContext context) {
    final exerciseCount = routine.exercises.length;
    final imageAsset = _getImageAsset(routine.category);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Thumbnail + Title & Badges + More Options
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 68,
                    height: 68,
                    color: isDark
                        ? const Color(0xFF1B202B)
                        : const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: routine.isTemplate
                                  ? AppColors.limeGreen.withValues(alpha: 0.15)
                                  : const Color(
                                      0xFF00E5FF,
                                    ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              routine.isTemplate ? 'CURATED' : 'CUSTOM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: routine.isTemplate
                                    ? AppColors.limeGreen
                                    : const Color(0xFF00E5FF),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              routine.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black87,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        routine.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!routine.isTemplate)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (val) {
                      if (val == 'edit') {
                        context.push('/routines/builder?id=${routine.id}');
                      } else if (val == 'duplicate') {
                        onDuplicate();
                      } else if (val == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Routine'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (routine.description != null &&
                routine.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                routine.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.3,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Honest Exercise Count & Duration Pill Row
            Row(
              children: [
                const Icon(
                  Icons.fitness_center_rounded,
                  size: 15,
                  color: AppColors.limeGreen,
                ),
                const SizedBox(width: 5),
                Text(
                  '$exerciseCount Exercises',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.limeGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                const SizedBox(width: 5),
                Text(
                  '${routine.estimatedDurationMinutes} min',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (routine.difficulty.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black26,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    routine.difficulty[0].toUpperCase() +
                        routine.difficulty.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),

            // Exercise Preview Chips
            if (routine.exercises.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final ex in routine.exercises.take(4))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        ex.exerciseName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  if (routine.exercises.length > 4)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${routine.exercises.length - 4} more',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.limeGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Start Routine Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: Colors.black,
                ),
                label: const Text(
                  'Start Routine',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: onStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky Header with frosted glass background that pins neatly at the top of each category
class _StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String badge;
  final bool isDark;

  const _StickySectionHeaderDelegate({
    required this.title,
    required this.badge,
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.centerLeft,
      decoration: overlapsContent
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      (isDark
                              ? AppColors.darkSurfaceBorder
                              : AppColors.lightSurfaceBorder)
                          .withValues(alpha: 0.6),
                ),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00E676),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get minExtent => 44.0;

  @override
  double get maxExtent => 44.0;

  @override
  bool shouldRebuild(covariant _StickySectionHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.badge != badge ||
        oldDelegate.isDark != isDark;
  }
}

/// Futuristic Active Plan Card with neon glow border, progress indicator, and action buttons
class _ActivePlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final String progressText;
  final String imageAsset;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onResume;

  const _ActivePlanCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressText,
    required this.imageAsset,
    required this.isDark,
    required this.onTap,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF00E676,
            ).withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Athlete Banner with Hero expansion
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'workout_hero_image_plan-hypertrophy',
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? AppColors.darkSurface : Colors.white)
                              .withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CURRENT ENROLLED PLAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar & Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          progressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white70
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Start Today\'s Workout',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      onPressed: onResume,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _Metric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
