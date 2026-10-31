import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calorie_adjustment.dart';
import '../../domain/services/nutrition_calculation_service.dart';
import '../controllers/nutrition_controller.dart';

class EnergyBalanceCard extends ConsumerWidget {
  final DateTime? activeDate;

  const EnergyBalanceCard({super.key, this.activeDate});

  void _showAddAdjustmentSheet(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime selectedDate =
        activeDate ?? ref.read(nutritionProvider.notifier).currentDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log Manual Burn Adjustment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Record physical activity expenditure separate from verified workouts and wearables.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Activity Name *',
                    hintText: 'e.g. Hiking, Gardening, Yard Work',
                    prefixIcon: const Icon(
                      Icons.directions_run_rounded,
                      color: AppColors.limeGreen,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Calories Burned (kcal) *',
                    hintText: 'e.g. 250',
                    prefixIcon: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.warmCoral,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Optional Notes',
                    hintText: 'e.g. 45 min moderate pace with backpack',
                    prefixIcon: const Icon(
                      Icons.note_alt_outlined,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.electricCyan,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Date: ${DateFormat('EEE, MMM d, yyyy').format(selectedDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final cals = int.tryParse(caloriesCtrl.text.trim()) ?? 0;
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an activity title'),
                          ),
                        );
                        return;
                      }
                      if (cals <= 0 || cals > 5000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Calories must be between 1 and 5000 kcal',
                            ),
                          ),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final adjustment = CalorieAdjustment(
                        id: const Uuid().v4(),
                        date: selectedDate,
                        caloriesBurned: cals,
                        title: title,
                        note: noteCtrl.text.trim().isNotEmpty
                            ? noteCtrl.text.trim()
                            : null,
                        source: 'manual_adjustment',
                        createdAt: now,
                        updatedAt: now,
                      );

                      ref
                          .read(nutritionProvider.notifier)
                          .addCalorieAdjustment(adjustment);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added adjustment: $title (+$cals kcal)',
                          ),
                        ),
                      );
                    },
                    child: const Text('Save Adjustment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(nutritionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final balance = NutritionCalculationService.computeEnergyBalance(
      caloriesConsumed: nutrition.totalCaloriesGained,
      workoutCaloriesBurned: nutrition.workoutCaloriesBurned,
      manualCaloriesBurned: nutrition.manualCaloriesBurned,
      targetCalories: nutrition.targetCalories,
    );

    final totalBurned = balance['totalBurned']!;
    final netCalories = balance['netCalories']!;
    final remainingCalories = balance['remainingCalories']!;

    final adjustments = nutrition.manualAdjustments
        .where((a) => !a.isDeleted)
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.balance_rounded,
                          color: AppColors.limeGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Energy Balance & Expenditure',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.limeGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text(
                    'Add Burn',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _showAddAdjustmentSheet(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3 Summary Columns: Intake, Burned, Net
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BalanceMetric(
                    label: 'Intake',
                    value: '${nutrition.totalCaloriesGained}',
                    unit: 'kcal',
                    color: AppColors.electricCyan,
                    icon: Icons.restaurant_rounded,
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _BalanceMetric(
                    label: 'Burned',
                    value: '-$totalBurned',
                    unit: 'kcal',
                    color: AppColors.warmCoral,
                    icon: Icons.local_fire_department_rounded,
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _BalanceMetric(
                    label: 'Net Balance',
                    value: '$netCalories',
                    unit: 'kcal',
                    color: netCalories <= nutrition.targetCalories
                        ? AppColors.limeGreen
                        : AppColors.amberWarning,
                    icon: Icons.speed_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Burn Breakdown Details
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verified Workouts',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nutrition.workoutCaloriesBurned} kcal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manual Adjustments',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nutrition.manualCaloriesBurned} kcal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // List of manual adjustments if any exist
            if (adjustments.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Today\'s Manual Adjustments (${adjustments.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ...adjustments.map(
                (a) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (a.note != null && a.note!.isNotEmpty)
                              Text(
                                a.note!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '+${a.caloriesBurned} kcal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.warmCoral,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              ref
                                  .read(nutritionProvider.notifier)
                                  .deleteCalorieAdjustment(a.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining to daily budget:',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.black54,
                  ),
                ),
                Text(
                  '$remainingCalories kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: remainingCalories >= 0
                        ? AppColors.limeGreen
                        : AppColors.warmCoral,
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

class _BalanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
