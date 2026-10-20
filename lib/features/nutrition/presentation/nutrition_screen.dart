import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import '../domain/models/nutrition_models.dart';
import 'controllers/nutrition_controller.dart';
import 'widgets/custom_meal_routine_sheet.dart';
import '../../profile/presentation/controllers/user_profile_controller.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  @override
  Widget build(BuildContext context) {
    final nutrition = ref.watch(nutritionProvider);
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition & Fuel'),
        actions: [
          IconButton(
            tooltip: 'Custom Meal Routines',
            icon: const Icon(Icons.restaurant_menu_rounded, color: AppColors.limeGreen),
            onPressed: () => CustomMealRoutineSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.limeGreen,
          onRefresh: () async {
            ref.invalidate(nutritionProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                    'Track daily nutrition, calories, and macros effortlessly with smart targets.',
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

          // Daily Macro Target Card with Clean Abstract Gradient Header
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0D2818), const Color(0xFF04170E), const Color(0xFF081C1B)]
                            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFFE0F2F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.limeGreen.withValues(alpha: isDark ? 0.12 : 0.2),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 40,
                          bottom: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.electricCyan.withValues(alpha: isDark ? 0.08 : 0.15),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.limeGreen.withValues(alpha: isDark ? 0.18 : 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.limeGreen.withValues(alpha: isDark ? 0.4 : 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 36,
                                  color: AppColors.limeGreen,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.limeGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'OPTIMAL NUTRITION TARGET',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: AppColors.limeGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${profile.dailyCaloriesTarget} kcal / Day',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Calibrated for ${profile.fitnessGoal.replaceAll('_', ' ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                  ),
                ),
                Padding(
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
                            current: nutrition.totalCaloriesGained,
                            target: profile.dailyCaloriesTarget > 0
                                ? profile.dailyCaloriesTarget
                                : nutrition.targetCalories,
                            unit: 'kcal',
                            color: AppColors.limeGreen,
                            isDark: isDark,
                          ),
                          _MacroIndicator(
                            label: 'Protein',
                            current: nutrition.totalProteinGained.toInt(),
                            target: profile.targetProteinGrams > 0
                                ? profile.targetProteinGrams
                                : nutrition.targetProtein,
                            unit: 'g',
                            color: AppColors.electricCyan,
                            isDark: isDark,
                          ),
                          _MacroIndicator(
                            label: 'Carbs',
                            current: nutrition.totalCarbsGained.toInt(),
                            target: profile.targetCarbsGrams > 0
                                ? profile.targetCarbsGrams
                                : nutrition.targetCarbs,
                            unit: 'g',
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                          _MacroIndicator(
                            label: 'Fats',
                            current: nutrition.totalFatGained.toInt(),
                            target: profile.targetFatsGrams > 0
                                ? profile.targetFatsGrams
                                : nutrition.targetFat,
                            unit: 'g',
                            color: const Color(0xFFA855F7),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.limeGreen,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text(
                                'Log Meal',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () => context.push('/nutrition/add'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? AppColors.limeGreen : Colors.black,
                                side: BorderSide(color: AppColors.limeGreen.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              icon: const Icon(Icons.menu_book_rounded, size: 18),
                              label: const Text(
                                'Food Diary',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () => context.push('/nutrition/diary'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            side: BorderSide(
                              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                          label: const Text(
                            'Log Routine (Daily Meal Presets)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                          onPressed: () => CustomMealRoutineSheet.show(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hydration Tracker with Transparent Banner & Liquid Options
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full View Transparent Banner with Ambient Glow (Never Cropped)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF0F1E36),
                              const Color(0xFF091426),
                              const Color(0xFF060B14),
                            ]
                          : [
                              const Color(0xFFE0F7FA),
                              const Color(0xFFB2EBF2),
                              const Color(0xFFE1F5FE),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1774 / 887,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          bottom: -10,
                          width: 180,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.electricCyan.withValues(alpha: isDark ? 0.2 : 0.15),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Image.asset(
                              'assets/images/nutrition/hydration.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.water_drop_rounded, size: 40, color: AppColors.electricCyan),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hydration Tracker',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${nutrition.totalHydrationMl} ml total fluid logged',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${nutrition.waterGlasses} / ${nutrition.targetWater} Glasses',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.electricCyan,
                                ),
                              ),
                              if (nutrition.waterGlasses > 0) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => notifier.resetHydration(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Tooltip(
                                    message: 'Reset to 0 Glasses',
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.restart_alt_rounded,
                                        size: 16,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(nutrition.targetWater, (index) {
                          final isFilled = index < nutrition.waterGlasses;
                          return GestureDetector(
                            onTap: () => notifier.setWater(index + 1),
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
                      const SizedBox(height: 14),

                      // Quick Liquid Drink Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.water_drop_rounded, size: 14, color: AppColors.electricCyan),
                            label: const Text('+ Water (250ml)', style: TextStyle(fontSize: 11)),
                            onPressed: () => notifier.logDrink(
                              type: LiquidDrinkType.water,
                              name: 'Pure Water',
                              volumeMl: 250,
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFF9E00)),
                            label: const Text('+ Creatine (300ml)', style: TextStyle(fontSize: 11)),
                            onPressed: () => notifier.logDrink(
                              type: LiquidDrinkType.creatine,
                              name: 'Creatine Monohydrate',
                              volumeMl: 300,
                              note: '5g Creatine',
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.limeGreen),
                            label: const Text('+ Glucose & Salts (350ml)', style: TextStyle(fontSize: 11)),
                            onPressed: () => notifier.logDrink(
                              type: LiquidDrinkType.glucose,
                              name: 'Glucose & Salts',
                              volumeMl: 350,
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.local_drink_rounded, size: 14, color: Color(0xFF7C4DFF)),
                            label: const Text('+ Protein Shake (300ml)', style: TextStyle(fontSize: 11)),
                            onPressed: () => notifier.logDrink(
                              type: LiquidDrinkType.protein,
                              name: 'Protein Shake',
                              volumeMl: 300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.open_in_new_rounded, size: 14),
                            label: const Text('Full View & Custom Liquid', style: TextStyle(fontSize: 12)),
                            onPressed: () => context.push('/hydration'),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.remove_rounded, size: 16),
                                label: const Text('Minus'),
                                onPressed: nutrition.waterGlasses > 0
                                    ? () => notifier.decrementWater()
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Glass'),
                                onPressed: nutrition.waterGlasses < nutrition.targetWater
                                    ? () => notifier.incrementWater()
                                    : null,
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
          ),
          const SizedBox(height: 16),

          // Rest Day & Recovery Nutrition Menu Card
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0D2825), const Color(0xFF091C1B)]
                            : [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14B8A6).withValues(alpha: isDark ? 0.2 : 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.4)),
                          ),
                          child: const Icon(
                            Icons.spa_rounded,
                            size: 28,
                            color: Color(0xFF14B8A6),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'REST DAY RECOVERY PROTOCOL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF14B8A6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tissue Repair & Anti-Inflammatory Menu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rest Day Macro Cycling Strategy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'On rest and recovery days, glycogen expenditure drops. Moderate carbohydrates by ~20% while elevating restorative fats and collagen peptides to reduce systemic inflammation and speed muscular repair.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Micronutrient Recovery Stack
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildRestPill('🐟 Wild Omega-3 EPA/DHA', isDark),
                          _buildRestPill('🦴 Collagen & Vit C', isDark),
                          _buildRestPill('🫐 Tart Cherry Polyphenols', isDark),
                          _buildRestPill('⚡ Magnesium Glycinate', isDark),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      const Text(
                        'Curated Rest Day Routine Meals',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),

                      _buildRestMealTile(
                        context: context,
                        isDark: isDark,
                        name: 'Anti-Inflammatory Salmon & Avocado Bowl',
                        calories: 510,
                        protein: 44,
                        carbs: 14,
                        fat: 30,
                        diet: 'high_protein',
                        mealType: 'dinner',
                        notifier: notifier,
                      ),
                      const SizedBox(height: 8),
                      _buildRestMealTile(
                        context: context,
                        isDark: isDark,
                        name: 'Turmeric Bone Broth & Shredded Chicken',
                        calories: 280,
                        protein: 34,
                        carbs: 8,
                        fat: 12,
                        diet: 'high_protein',
                        mealType: 'lunch',
                        notifier: notifier,
                      ),
                      const SizedBox(height: 8),
                      _buildRestMealTile(
                        context: context,
                        isDark: isDark,
                        name: 'Tart Cherry & Casein Bedtime Shake',
                        calories: 320,
                        protein: 38,
                        carbs: 18,
                        fat: 8,
                        diet: 'balanced',
                        mealType: 'snack',
                        notifier: notifier,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Whole Foods & Nutrition Quality Card
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF14241B), const Color(0xFF0F1A14)]
                            : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.limeGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 26,
                            color: AppColors.limeGreen,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'QUALITY RECOVERY NUTRITION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.limeGreen,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Whole Foods & Protein Synthesis',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prioritize unprocessed, nutrient-dense whole foods. Aim for 1.6 to 2.2 grams of protein per kilogram of bodyweight spread across 3-4 meals to maximize muscle protein synthesis.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sleep & Recovery Card
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.electricCyan.withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.electricCyan.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.bedtime_rounded,
                            size: 32,
                            color: AppColors.electricCyan,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '7.5 – 8.5 hrs',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Target Sleep Window • Peak Anabolic Recovery',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.electricCyan,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _SleepStageChip(label: 'Deep ~20%', isDark: isDark),
                                  _SleepStageChip(label: 'REM ~25%', isDark: isDark),
                                  _SleepStageChip(label: 'Light ~55%', isDark: isDark),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rest & Recovery Window',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.electricCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '7-9 hrs target',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hypertrophy and nervous system recovery occur primarily during slow-wave and REM sleep cycles. Maintain a cool, dark sleeping environment for peak growth hormone release.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
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
    ),
  ),
);
}

  Widget _buildRestPill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withValues(alpha: isDark ? 0.14 : 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
        ),
      ),
    );
  }

  Widget _buildRestMealTile({
    required BuildContext context,
    required bool isDark,
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String diet,
    required String mealType,
    required NutritionNotifier notifier,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF14B8A6), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$calories kcal • ${protein.toInt()}g P • ${carbs.toInt()}g C • ${fat.toInt()}g F',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(50, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              notifier.logMeal(
                MealItem(
                  id: 'rest-${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  mealType: mealType,
                  dietType: diet,
                  calories: calories,
                  proteinGrams: protein,
                  carbsGrams: carbs,
                  fatGrams: fat,
                  portion: '1 rest serving',
                  loggedAt: DateTime.now(),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged $name (+$calories kcal)'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('+ Log', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

class _SleepStageChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SleepStageChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
