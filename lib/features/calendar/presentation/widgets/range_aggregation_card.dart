import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../controllers/calendar_range_controller.dart';
import '../../domain/models/day_summary.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';

class RangeAggregationCard extends ConsumerWidget {
  const RangeAggregationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rangeState = ref.watch(calendarRangeProvider);
    final rangeNotifier = ref.read(calendarRangeProvider.notifier);
    final auth = ref.watch(authProvider);
    final isGuest = auth.isGuest;

    final summariesAsync = ref.watch(rangeSummariesStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Range Segmented Control
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: RangeFilter.values.map((filter) {
              final isSelected = rangeState.selectedFilter == filter;
              final isLocked = isGuest &&
                  (filter == RangeFilter.month || filter == RangeFilter.custom);

              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (filter == RangeFilter.custom) {
                      if (isGuest) {
                        rangeNotifier.selectFilter(filter, isGuest: true);
                        return;
                      }

                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDateRange: DateTimeRange(
                          start: rangeState.customStartDate,
                          end: rangeState.customEndDate,
                        ),
                        builder: (ctx, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                primary: AppColors.electricBlue,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        rangeNotifier.setCustomRange(
                          picked.start,
                          picked.end,
                          isGuest: isGuest,
                        );
                      }
                    } else {
                      rangeNotifier.selectFilter(filter, isGuest: isGuest);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF232733) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLocked) ...[
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: AppColors.electricBlue,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            filter.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.electricBlue
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Deliverable D: Lock Card for Guests on Month/Custom
        if (rangeState.showLockCard) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E2638), const Color(0xFF151926)]
                    : [const Color(0xFFEBF3FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.electricBlue.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.electricBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account-Only Feature',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Monthly & Custom Range Analytics',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.electricBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Guests can view today and weekly trends. Create a free Fit Host account to unlock full month aggregations, multi-week streaks, and unlimited custom date ranges.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/auth');
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text(
                          'Sign Up / Sign In',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        rangeNotifier.selectFilter(RangeFilter.today, isGuest: true);
                      },
                      child: const Text('Back to Today'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // 3. Totals Aggregation Panel
          summariesAsync.when(
            data: (aggregation) => _TotalsPanel(aggregation: aggregation),
            loading: () => Container(
              height: 180,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text('Error loading range: $err'),
            ),
          ),
        ],
      ],
    );
  }
}

class _TotalsPanel extends ConsumerWidget {
  final RangeAggregation aggregation;

  const _TotalsPanel({required this.aggregation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nutrition = ref.watch(nutritionProvider);
    final meals = nutrition.loggedMeals;
    final counts = <String, int>{};
    for (final m in meals) {
      counts[m.name] = (counts[m.name] ?? 0) + 1;
    }
    String? mostEatenFood;
    int maxCount = 0;
    counts.forEach((k, v) {
      if (v > maxCount) {
        mostEatenFood = k;
        maxCount = v;
      }
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range Header + Streak Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range Summary • ${aggregation.dayCount} ${aggregation.dayCount == 1 ? 'Day' : 'Days'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: Color(0xFFFF9500),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${aggregation.longestStreak}d streak',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF9500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Primary Metrics Grid
          Row(
            children: [
              // Workouts Completed
              Expanded(
                child: _MetricTile(
                  icon: Icons.fitness_center_rounded,
                  iconColor: AppColors.electricBlue,
                  value: '${aggregation.totalWorkoutsCompleted}',
                  label: 'Workouts',
                  subtext: 'completed',
                ),
              ),
              const SizedBox(width: 10),
              // Steps & Distance
              Expanded(
                child: _MetricTile(
                  icon: Icons.directions_walk_rounded,
                  iconColor: const Color(0xFF10B981),
                  value: '${aggregation.totalSteps}',
                  label: 'Steps',
                  subtext: aggregation.formattedTotalDistance,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Calories In, Out, Net
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B202D) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SubStat(
                  label: 'Calories In',
                  value: '${aggregation.totalCaloriesIn}',
                  color: const Color(0xFF22C55E),
                ),
                Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.3)),
                _SubStat(
                  label: 'Burned',
                  value: '${aggregation.totalCaloriesBurned}',
                  color: const Color(0xFFFF5252),
                ),
                Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.3)),
                _SubStat(
                  label: 'Net',
                  value: '${aggregation.netCalories > 0 ? '+' : ''}${aggregation.netCalories}',
                  color: aggregation.netCalories <= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFFF9500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Macros (Protein, Carbs, Fats totals + daily averages) & Water
          Row(
            children: [
              Expanded(
                child: _MacroChip(
                  label: 'Protein',
                  total: '${aggregation.totalProteinG.round()}g',
                  avg: '${aggregation.avgProteinG.toStringAsFixed(1)}g/d',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MacroChip(
                  label: 'Carbs',
                  total: '${aggregation.totalCarbsG.round()}g',
                  avg: '${aggregation.avgCarbsG.toStringAsFixed(1)}g/d',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MacroChip(
                  label: 'Fats',
                  total: '${aggregation.totalFatsG.round()}g',
                  avg: '${aggregation.avgFatsG.toStringAsFixed(1)}g/d',
                  color: const Color(0xFFEC4899),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MacroChip(
                  label: 'Water',
                  total: '${(aggregation.totalWaterMl / 1000).toStringAsFixed(1)}L',
                  avg: '${(aggregation.totalWaterMl / (aggregation.dayCount > 0 ? aggregation.dayCount : 1)).round()}ml/d',
                  color: const Color(0xFF06B6D4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Average Daily Intake and Top Eaten Food
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141923) : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: AppColors.limeGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Avg Daily Intake: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      '${aggregation.avgCaloriesIn} kcal/d',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ],
                ),
                if (mostEatenFood != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.grey)),
                        const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF5252)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Top: $mostEatenFood',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
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

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String subtext;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B202D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$label • $subtext',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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

class _SubStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SubStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String total;
  final String avg;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.total,
    required this.avg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B202D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            total,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            avg,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
