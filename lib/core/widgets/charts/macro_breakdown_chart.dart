import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MacroBreakdownChart extends StatelessWidget {
  final double currentProtein;
  final double targetProtein;
  final double currentCarbs;
  final double targetCarbs;
  final double currentFat;
  final double targetFat;
  final int totalCalories;
  final int targetCalories;
  final bool isDark;

  const MacroBreakdownChart({
    super.key,
    required this.currentProtein,
    required this.targetProtein,
    required this.currentCarbs,
    required this.targetCarbs,
    required this.currentFat,
    required this.targetFat,
    required this.totalCalories,
    required this.targetCalories,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final proteinRatio = targetProtein > 0
        ? (currentProtein / targetProtein).clamp(0.0, 1.0)
        : 0.0;
    final carbsRatio = targetCarbs > 0
        ? (currentCarbs / targetCarbs).clamp(0.0, 1.0)
        : 0.0;
    final fatRatio = targetFat > 0
        ? (currentFat / targetFat).clamp(0.0, 1.0)
        : 0.0;

    final proteinKcal = (currentProtein * 4).round();
    final carbsKcal = (currentCarbs * 4).round();
    final fatKcal = (currentFat * 9).round();
    final totalMacroKcal = proteinKcal + carbsKcal + fatKcal;

    final proteinPct = totalMacroKcal > 0
        ? ((proteinKcal / totalMacroKcal) * 100).round()
        : 0;
    final carbsPct = totalMacroKcal > 0
        ? ((carbsKcal / totalMacroKcal) * 100).round()
        : 0;
    final fatPct = totalMacroKcal > 0
        ? ((fatKcal / totalMacroKcal) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Macro Distribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Macronutrient Distribution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.limeGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalCalories / $targetCalories kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.limeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Caloric Proportion Bar (Concentric / Segmented)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: totalMacroKcal > 0
                  ? Row(
                      children: [
                        if (proteinPct > 0)
                          Expanded(
                            flex: proteinPct,
                            child: Container(color: AppColors.electricCyan),
                          ),
                        if (carbsPct > 0)
                          Expanded(
                            flex: carbsPct,
                            child: Container(color: const Color(0xFFFFB300)),
                          ),
                        if (fatPct > 0)
                          Expanded(
                            flex: fatPct,
                            child: Container(color: const Color(0xFFFF6B4A)),
                          ),
                      ],
                    )
                  : Container(color: isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          const SizedBox(height: 16),

          // Individual Macro Progress Rows
          _buildMacroRow(
            label: 'Protein',
            current: currentProtein,
            target: targetProtein,
            ratio: proteinRatio,
            pct: proteinPct,
            color: AppColors.electricCyan,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildMacroRow(
            label: 'Carbohydrates',
            current: currentCarbs,
            target: targetCarbs,
            ratio: carbsRatio,
            pct: carbsPct,
            color: const Color(0xFFFFB300),
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildMacroRow(
            label: 'Dietary Fats',
            current: currentFat,
            target: targetFat,
            ratio: fatRatio,
            pct: fatPct,
            color: const Color(0xFFFF6B4A),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required double current,
    required double target,
    required double ratio,
    required int pct,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                if (pct > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '($pct% kcal)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${current.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceElevated,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
