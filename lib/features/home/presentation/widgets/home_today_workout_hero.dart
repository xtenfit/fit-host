import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workouts/presentation/controllers/workout_providers.dart';
import '../../../workouts/domain/models/workout_models.dart';
import '../../../workouts/data/routine_service.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import '../controllers/home_dashboard_controller.dart';

/// Data model representing a workout item displayed in the mobile-first carousel.
class CarouselWorkoutItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String tag;
  final String imageAsset;
  final double progress;
  final String durationText;
  final String caloriesText;
  final bool isLive;
  final bool isCompleted;
  final bool canMarkDone;
  final bool isDefaultEmptyState;
  final WorkoutRoutine? routine;

  const CarouselWorkoutItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.tag,
    required this.imageAsset,
    required this.progress,
    required this.durationText,
    required this.caloriesText,
    this.isLive = false,
    this.isCompleted = false,
    this.canMarkDone = false,
    this.isDefaultEmptyState = false,
    this.routine,
  });
}

class HomeTodayWorkoutHero extends ConsumerStatefulWidget {
  final bool isDark;

  const HomeTodayWorkoutHero({super.key, required this.isDark});

  @override
  ConsumerState<HomeTodayWorkoutHero> createState() => _HomeTodayWorkoutHeroState();
}

class _HomeTodayWorkoutHeroState extends ConsumerState<HomeTodayWorkoutHero> {
  late final PageController _pageController;
  int _activePageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageController.hasClients) {
      final page = _pageController.page ?? 0.0;
      setState(() {
        _activePageIndex = page.round();
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  List<CarouselWorkoutItem> _buildCarouselItems({
    required ActiveWorkoutState activeState,
    required List<WorkoutEntity> completedToday,
    required dynamic profile,
    required RoutineState routineState,
  }) {
    final items = <CarouselWorkoutItem>[];

    // 1. Live workout in progress (highest priority)
    if (activeState.isActive && activeState.workout != null) {
      final burned = (activeState.workout!.durationSeconds * 0.12).toInt();
      final minutes = activeState.workout!.durationSeconds ~/ 60;
      final completedEx = activeState.workout!.exercises
          .where((e) => e.sets.any((s) => s.isCompleted))
          .length;
      final totalEx = activeState.workout!.exercises.length;
      final progress = totalEx > 0 ? (completedEx / totalEx) : 0.35;

      items.add(
        CarouselWorkoutItem(
          id: activeState.workout!.id,
          title: activeState.workout!.title,
          subtitle: 'Live Session in Progress • Tap to Resume',
          category: activeState.workout!.category ?? 'Live Workout',
          tag: '• LIVE IN PROGRESS',
          imageAsset: 'assets/images/workouts/today_workout_athlete.png',
          progress: progress.clamp(0.05, 0.95),
          durationText: '$minutes min',
          caloriesText: '$burned Kcal',
          isLive: true,
        ),
      );
    }

    // 2. Real workouts completed today from SQLite / Drift
    for (final w in completedToday) {
      int durationSec = w.durationSeconds;
      if (durationSec <= 0 && w.completedAt != null) {
        durationSec = w.completedAt!.difference(w.startedAt).inSeconds;
      }
      final minutes = durationSec >= 60 ? (durationSec / 60).round() : (durationSec > 0 ? 1 : 0);
      final burned = (w.caloriesBurned != null && w.caloriesBurned! > 0)
          ? w.caloriesBurned!
          : (minutes > 0 ? (minutes * 7.5).round() : 0);
      items.add(
        CarouselWorkoutItem(
          id: w.id,
          title: w.title,
          subtitle: 'Completed Today • ${w.exercises.length} Exercises',
          category: w.category ?? 'Completed Workout',
          tag: 'COMPLETED TODAY',
          imageAsset: 'assets/images/workouts/today_workout_athlete.png',
          progress: 1.0,
          durationText: '$minutes min',
          caloriesText: '$burned Kcal',
          isCompleted: true,
        ),
      );
    }

    // 3. Assigned daily routine (if not completed today yet)
    final assigned = routineState.assignedRoutine;
    final alreadyDoneAssigned = completedToday.any((w) => w.title == assigned?.title);
    if (assigned != null && !alreadyDoneAssigned) {
      final estCalories = (assigned.durationMinutes * 7.5).round();
      items.add(
        CarouselWorkoutItem(
          id: assigned.id,
          title: assigned.title,
          subtitle: '${assigned.durationMinutes} min • ${assigned.exerciseIds.length} Exercises',
          category: assigned.category,
          tag: 'ASSIGNED ROUTINE',
          imageAsset: assigned.imageAsset,
          progress: 0.0,
          durationText: '${assigned.durationMinutes} min',
          caloriesText: '$estCalories Kcal',
          canMarkDone: true,
          routine: assigned,
        ),
      );
    }

    // 4. Default Empty State: "Start First Workout" if no active or completed session
    if (items.isEmpty) {
      items.add(
        const CarouselWorkoutItem(
          id: 'start-first-workout',
          title: 'Start First Workout',
          subtitle: 'Choose a routine or create your custom split',
          category: 'No Session Yet',
          tag: 'NO ACTIVE SESSION',
          imageAsset: 'assets/images/workouts/today_workout_athlete.png',
          progress: 0.0,
          durationText: '0 min',
          caloriesText: '0 Kcal',
          isDefaultEmptyState: true,
        ),
      );
    }

    return items;
  }

  void _showAddExtraWorkoutSheet(BuildContext context) {
    final titleController = TextEditingController(text: 'Extra Workout');
    final durationController = TextEditingController(text: '30');
    final caloriesController = TextEditingController(text: '210');

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSubmitting = false;
        String? titleError;
        String? durationError;
        String? caloriesError;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final viewInsets = MediaQuery.of(modalCtx).viewInsets;
            return Container(
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Extra Workout Today',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        onChanged: (_) {
                          if (titleError != null) {
                            setModalState(() => titleError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Workout Title',
                          errorText: titleError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.fitness_center_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: durationController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                if (durationError != null) {
                                  setModalState(() => durationError = null);
                                }
                                final d = int.tryParse(val.trim());
                                if (d != null && d > 0) {
                                  // Auto-calculate realistic estimated calories (~7 kcal/min)
                                  setModalState(() {
                                    caloriesController.text = '${(d * 7).round()}';
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Duration (min)',
                                errorText: durationError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.schedule_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: caloriesController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                if (caloriesError != null) {
                                  setModalState(() => caloriesError = null);
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Burned (kcal)',
                                helperText: 'Estimated • editable',
                                errorText: caloriesError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.local_fire_department_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      context.push('/routines');
                                    },
                              child: const Text('Browse Routines'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.limeGreen,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final title = titleController.text.trim();
                                      final durationStr = durationController.text.trim();
                                      final caloriesStr = caloriesController.text.trim();

                                      final duration = int.tryParse(durationStr);
                                      final calories = int.tryParse(caloriesStr);

                                      bool hasError = false;
                                      if (title.isEmpty) {
                                        setModalState(() => titleError = 'Title cannot be empty');
                                        hasError = true;
                                      }
                                      if (duration == null || duration <= 0) {
                                        setModalState(() => durationError = 'Enter valid minutes (>0)');
                                        hasError = true;
                                      }
                                      if (calories == null || calories < 0) {
                                        setModalState(() => caloriesError = 'Enter valid kcal');
                                        hasError = true;
                                      }

                                      if (hasError) return;

                                      setModalState(() => isSubmitting = true);

                                      try {
                                        final now = DateTime.now();
                                        final repo = ref.read(workoutRepositoryProvider);

                                        final w = WorkoutEntity(
                                          id: 'extra_workout_${DateTime.now().millisecondsSinceEpoch}',
                                          title: title,
                                          category: 'Extra Session',
                                          startedAt: now.subtract(Duration(minutes: duration!)),
                                          completedAt: now,
                                          status: 'completed',
                                          durationSeconds: duration * 60,
                                          caloriesBurned: calories ?? (duration * 7),
                                          updatedAt: now,
                                        );

                                        await repo.saveWorkout(w);
                                        ref.invalidate(workoutsStreamProvider);
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('✅ Logged extra workout: $title (+${calories ?? (duration * 7)} kcal)'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (modalCtx.mounted) {
                                          setModalState(() => isSubmitting = false);
                                        }
                                      }
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Text(
                                      'Log Workout',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeWorkoutProvider);
    final profile = ref.watch(userProfileProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final dashboard = ref.watch(homeDashboardProvider);
    final dashboardNotifier = ref.read(homeDashboardProvider.notifier);
    final routineState = ref.watch(routineProvider);

    final completedToday = workoutsAsync.maybeWhen(
      data: (workouts) => workouts.where((w) {
        if (w.status != 'completed' || w.completedAt == null) return false;
        final now = DateTime.now();
        final isToday = w.completedAt!.year == now.year &&
            w.completedAt!.month == now.month &&
            w.completedAt!.day == now.day;
        if (!isToday) return false;
        // Ignore corrupt/empty phantom records with 0 duration, 0 calories, and 0 exercises
        return w.durationSeconds > 0 ||
            (w.caloriesBurned != null && w.caloriesBurned! > 0) ||
            w.exercises.isNotEmpty;
      }).toList(),
      orElse: () => <WorkoutEntity>[],
    );

    final items = _buildCarouselItems(
      activeState: activeState,
      completedToday: completedToday,
      profile: profile,
      routineState: routineState,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final cardTargetWidth = screenWidth - 36;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row: Title + Add Extra Workout Action + Indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'Today\'s Workout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showAddExtraWorkoutSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: widget.isDark ? 0.16 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.limeGreen.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add_rounded, size: 14, color: AppColors.limeGreen),
                          SizedBox(width: 4),
                          Text(
                            'Extra Workout',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.limeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (items.length > 1) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(items.length, (idx) {
                        final isCurrent = idx == _activePageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(left: 4),
                          height: 4,
                          width: isCurrent ? 16 : 5,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.limeGreen
                                : (widget.isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : Colors.black.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carousel Container with PageView
        SizedBox(
          height: 236,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = items[index];
              final isActive = index == _activePageIndex;

              return _FuturisticWorkoutCard(
                item: item,
                cardWidth: cardTargetWidth,
                isActive: isActive,
                isDark: widget.isDark,
                isFavorite: dashboard.isFavoriteWorkout,
                onToggleFavorite: () => dashboardNotifier.toggleFavorite(),
                onTapCard: () {
                  if (item.isDefaultEmptyState) {
                    context.push('/routines');
                  } else if (item.isLive) {
                    context.push('/active-workout');
                  } else {
                    context.push('/workout/${item.id}');
                  }
                },
                onTapPlay: () {
                  if (item.isDefaultEmptyState) {
                    context.push('/routines');
                  } else if (item.isLive) {
                    context.push('/active-workout');
                  } else {
                    ref.read(activeWorkoutProvider.notifier).startNewWorkout(
                          title: item.title,
                        );
                    context.push('/active-workout');
                  }
                },
                onMarkDone: item.canMarkDone && item.routine != null
                    ? () async {
                        await ref
                            .read(routineProvider.notifier)
                            .markRoutineAsDone(item.routine!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 Completed today\'s workout: ${item.title}!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FuturisticWorkoutCard extends StatelessWidget {
  final CarouselWorkoutItem item;
  final double cardWidth;
  final bool isActive;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTapCard;
  final VoidCallback onTapPlay;
  final VoidCallback? onMarkDone;

  const _FuturisticWorkoutCard({
    required this.item,
    required this.cardWidth,
    required this.isActive,
    required this.isDark,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTapCard,
    required this.onTapPlay,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Clean dark elevation shadow without solid green spread/halo
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Athlete Image
              Positioned.fill(
                child: Hero(
                  tag: 'workout_hero_image_${item.id}',
                  child: Image.asset(
                    item.imageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (ctx, err, st) => Image.asset(
                      'assets/images/workouts/today_workout_athlete.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ),

              // 2. Soft Glassmorphic Tint & subtle border (no neon green borders)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF0D1512) : Colors.white)
                        .withValues(alpha: isDark ? 0.40 : 0.50),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),

              // 3. CRITICAL: Bottom gradient scrim so text NEVER overlaps athlete face/image
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        (isDark ? const Color(0xFF080D0B) : Colors.white)
                            .withValues(alpha: isDark ? 0.70 : 0.75),
                        isDark ? const Color(0xFF080D0B) : Colors.white,
                      ],
                      stops: const [0.20, 0.62, 1.0],
                    ),
                  ),
                ),
              ),

              // 4. Interactive Card Tap Surface & Content
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onTapCard,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Row: Status / Plan Tag & Action/Favorite
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.black : Colors.white)
                                        .withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: item.isCompleted
                                          ? AppColors.limeGreen.withValues(alpha: 0.4)
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.15)
                                              : Colors.black.withValues(alpha: 0.10)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: item.isCompleted
                                              ? AppColors.limeGreen
                                              : (item.isLive
                                                  ? const Color(0xFFFF5252)
                                                  : AppColors.electricCyan),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            item.tag,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: item.isCompleted
                                                  ? AppColors.limeGreen
                                                  : (item.isLive
                                                      ? const Color(0xFFFF5252)
                                                      : (isDark ? Colors.white70 : Colors.black87)),
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (onMarkDone != null)
                                InkWell(
                                  onTap: onMarkDone,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.limeGreen.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.limeGreen.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.check_circle_rounded, size: 14, color: AppColors.limeGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          'Mark Done',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.limeGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: InkWell(
                                    onTap: onToggleFavorite,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        isFavorite
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: const Color(0xFFFFB300),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Middle: Title & Subtitle (protected by bottom gradient scrim)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),

                          // Bottom Row: Real Progress Ring & Metrics
                          Row(
                            children: [
                              GestureDetector(
                                onTap: onTapPlay,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: CircularProgressIndicator(
                                          value: item.progress,
                                          strokeWidth: 3.2,
                                          backgroundColor: (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.12),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            item.isCompleted
                                                ? AppColors.limeGreen
                                                : (item.isLive
                                                    ? const Color(0xFFFF5252)
                                                    : AppColors.electricCyan),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: item.isCompleted
                                              ? AppColors.limeGreen
                                              : (item.isLive
                                                  ? const Color(0xFFFF5252)
                                                  : AppColors.limeGreen),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item.isCompleted
                                              ? Icons.check_rounded
                                              : (item.isLive
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded),
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Real Status & Metrics
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.isCompleted
                                          ? '100% COMPLETED'
                                          : (item.progress > 0
                                              ? '${(item.progress * 100).toInt()}% COMPLETED'
                                              : (item.isDefaultEmptyState
                                                  ? 'START WORKOUT'
                                                  : 'START WORKOUT')),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: item.isCompleted
                                            ? AppColors.limeGreen
                                            : (item.progress > 0
                                                ? AppColors.electricCyan
                                                : (isDark ? Colors.white70 : Colors.black87)),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 2,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department_rounded,
                                              size: 13,
                                              color: Color(0xFFFF7043),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              item.caloriesText,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 13,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              item.durationText,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
