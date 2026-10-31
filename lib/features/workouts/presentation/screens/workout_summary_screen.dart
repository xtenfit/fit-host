import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/workout_repository.dart'
    show routineRepositoryProvider;
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';
import '../controllers/workout_providers.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutEntity workout;

  const WorkoutSummaryScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  bool _isLoadingRecommendations = true;
  List<ProgressionRecommendationEntity> _recommendations = [];
  List<PersonalRecordEntity> _recentPrs = [];

  @override
  void initState() {
    super.initState();
    _analyzeWorkoutPerformance();
  }

  Future<void> _analyzeWorkoutPerformance() async {
    try {
      final overloadService = ref.read(progressiveOverloadServiceProvider);
      final routineRepo = ref.read(routineRepositoryProvider);

      final recs = <ProgressionRecommendationEntity>[];

      // Analyze each exercise in the completed workout
      for (final ex in widget.workout.exercises) {
        if (ex.isSkipped || ex.sets.isEmpty) continue;

        final rec = await overloadService.evaluateExerciseProgression(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
        );

        if (rec != null) {
          recs.add(rec);
        }
      }

      // Fetch any personal records recorded around this workout time
      final prs = await routineRepo.getPersonalRecords();
      final workoutTime = widget.workout.startedAt;
      final recentPrs = prs.where((p) {
        return p.achievedAt.isAfter(
          workoutTime.subtract(const Duration(minutes: 5)),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _recommendations = recs;
          _recentPrs = recentPrs;
          _isLoadingRecommendations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final remM = m % 60;
      return '${h}h ${remM}m';
    }
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workout = widget.workout;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Workout Summary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/workouts');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Hero Celebration Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1B382B), const Color(0xFF0F1E17)]
                      : [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.limeGreen.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.limeGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Workout Completed!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workout.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.limeGreen
                          : const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'EEEE, MMM d, y • h:mm a',
                    ).format(workout.completedAt ?? DateTime.now()),
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
            const SizedBox(height: 20),

            // Metrics Grid (Duration, Volume, Sets, Exercises)
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Duration',
                    value: _formatDuration(workout.durationSeconds),
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.electricCyan,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Total Volume',
                    value: '${workout.totalVolumeKg.toStringAsFixed(0)} kg',
                    icon: Icons.fitness_center_rounded,
                    iconColor: AppColors.limeGreen,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Completed Sets',
                    value: '${workout.completedSets}',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFFFFB300),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Exercises',
                    value: '${workout.exercises.length}',
                    icon: Icons.format_list_bulleted_rounded,
                    iconColor: const Color(0xFFAB47BC),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Personal Records Section (if any were achieved)
            if (_recentPrs.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFD700),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Personal Records Broken! 🏆',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._recentPrs.map((pr) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF262010)
                        : const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: Color(0xFFFFD700),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pr.recordType.toUpperCase().replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFCA8A04),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pr.formattedRecord,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW PR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Progressive Overload Engine Recommendations
            Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.limeGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Progressive Overload Coach',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoadingRecommendations)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.limeGreen,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Analyzing overload criteria across sessions...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else if (_recommendations.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keep consistent! Once 2 consecutive sessions hit target max reps, load increases will be automatically recommended.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._recommendations.map((rec) {
                final isIncrease = rec.shouldIncreaseLoad;
                final isDeload = rec.isDeload;

                Color accentColor = AppColors.limeGreen;
                IconData iconData = Icons.arrow_upward_rounded;
                String badgeText = 'OVERLOAD READY';

                if (isDeload) {
                  accentColor = const Color(0xFFFF9800);
                  iconData = Icons.restart_alt_rounded;
                  badgeText = 'DELOAD RECOMMENDED';
                } else if (!isIncrease) {
                  accentColor = AppColors.electricCyan;
                  iconData = Icons.sync_rounded;
                  badgeText = 'MAINTAIN & ADAPT';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(iconData, size: 14, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            rec.recommendedWeightKg != null
                                ? 'Next Load: ${rec.recommendedWeightKg!.toStringAsFixed(1)} kg'
                                : 'Next: ${rec.recommendedReps} reps',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rec.reason,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Exercises Completed Breakdown
            const Text(
              'Exercise Performance Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...workout.exercises.map((ex) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
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
                    Text(
                      ex.exerciseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ex.sets.where((s) => s.isCompleted).length} of ${ex.sets.length} sets completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ex.sets.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: s.isCompleted
                                ? AppColors.limeGreen.withValues(alpha: 0.15)
                                : (isDark ? Colors.white10 : Colors.black12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: s.isCompleted
                                  ? AppColors.limeGreen.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            'S${s.setNumber}: ${s.weightKg.toStringAsFixed(s.weightKg % 1 == 0 ? 0 : 1)}kg × ${s.reps}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: s.isCompleted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: s.isCompleted
                                  ? (isDark
                                        ? AppColors.limeGreen
                                        : const Color(0xFF166534))
                                  : (isDark ? Colors.white54 : Colors.black54),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkSurfaceBorder
                  : AppColors.lightSurfaceBorder,
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/workouts');
              }
            },
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
