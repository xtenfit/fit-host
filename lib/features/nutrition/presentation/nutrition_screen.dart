import 'package:flutter/material.dart';
import 'package:fit_host/core/theme/app_colors.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _waterGlasses = 4;
  final int _targetWater = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition & Fuel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Offline banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSurfaceBorder
                    : AppColors.lightSurfaceBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.electricCyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fit Host core features run 100% offline. No paid subscription required.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily Macro Target Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Energy Target',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calculated for optimal strength and lean mass recovery.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MacroIndicator(
                        label: 'Calories',
                        current: 1850,
                        target: 2400,
                        unit: 'kcal',
                        color: AppColors.limeGreen,
                        isDark: isDark,
                      ),
                      _MacroIndicator(
                        label: 'Protein',
                        current: 140,
                        target: 180,
                        unit: 'g',
                        color: AppColors.electricCyan,
                        isDark: isDark,
                      ),
                      _MacroIndicator(
                        label: 'Carbs',
                        current: 190,
                        target: 250,
                        unit: 'g',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                      _MacroIndicator(
                        label: 'Fats',
                        current: 55,
                        target: 70,
                        unit: 'g',
                        color: const Color(0xFFA855F7),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hydration Tracker
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hydration Tracker',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_waterGlasses / $_targetWater Glasses',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricCyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_targetWater, (index) {
                      final isFilled = index < _waterGlasses;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _waterGlasses = index + 1;
                          });
                        },
                        child: Icon(
                          isFilled
                              ? Icons.local_drink_rounded
                              : Icons.local_drink_outlined,
                          color: isFilled
                              ? AppColors.electricCyan
                              : (isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary),
                          size: 28,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.remove_rounded, size: 16),
                        label: const Text('Minus'),
                        onPressed: _waterGlasses > 0
                            ? () => setState(() => _waterGlasses--)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Glass'),
                        onPressed: _waterGlasses < _targetWater
                            ? () => setState(() => _waterGlasses++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroIndicator extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final String unit;
  final Color color;
  final bool isDark;

  const _MacroIndicator({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text(
              '$current',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          '/$target$unit',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
      ],
    );
  }
}
