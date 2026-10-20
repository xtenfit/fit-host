import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/nutrition_models.dart';
import '../controllers/nutrition_controller.dart';

class HydrationDetailScreen extends ConsumerStatefulWidget {
  const HydrationDetailScreen({super.key});

  @override
  ConsumerState<HydrationDetailScreen> createState() => _HydrationDetailScreenState();
}

class _HydrationDetailScreenState extends ConsumerState<HydrationDetailScreen> {
  void _showCustomDrinkDialog(BuildContext context) {
    final nameController = TextEditingController();
    final volumeController = TextEditingController(text: '300');
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Log Custom Drink',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Drink Name (e.g. BCAA, Coconut Water, Tea)',
                      prefixIcon: const Icon(Icons.local_drink_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: volumeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Volume (ml)',
                      prefixIcon: const Icon(Icons.speed_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      suffixText: 'ml',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Optional Note (e.g. 5g powder, ice chilled)',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final name = nameController.text.trim();
                        final vol = int.tryParse(volumeController.text.trim()) ?? 250;
                        if (name.isNotEmpty) {
                          ref.read(nutritionProvider.notifier).logDrink(
                                type: LiquidDrinkType.custom,
                                name: name,
                                volumeMl: vol,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged $name ($vol ml)'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Add to Hydration Log',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _logPresetDrink(
    BuildContext context, {
    required LiquidDrinkType type,
    required String name,
    required int volumeMl,
    String? note,
  }) {
    ref.read(nutritionProvider.notifier).logDrink(
          type: type,
          name: name,
          volumeMl: volumeMl,
          note: note,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $name (+$volumeMl ml)'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalMl = nutrition.totalHydrationMl;
    final targetMl = nutrition.targetHydrationMl;
    final percent = targetMl > 0 ? (totalMl / targetMl).clamp(0.0, 1.5) : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Hydration & Fluids Tracker',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Today\'s Water',
            onPressed: () {
              notifier.resetHydration();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset today\'s hydration log'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Full View Photographic Banner with Transparent Background (Never Cropped)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
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
                border: Border.all(
                  color: AppColors.electricCyan.withValues(alpha: isDark ? 0.35 : 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricCyan.withValues(alpha: isDark ? 0.15 : 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1774 / 887,
                child: Stack(
                  children: [
                    // Luminous ambient splash behind
                    Positioned(
                      right: -20,
                      top: -20,
                      bottom: -20,
                      width: 220,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.electricCyan.withValues(alpha: isDark ? 0.2 : 0.15),
                        ),
                      ),
                    ),
                    // Transparent Athlete & Water Splash Full View
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Image.asset(
                          'assets/images/nutrition/hydration.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.water_drop_rounded, size: 64, color: AppColors.electricCyan),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Interactive Liquid Drink Options ("What do you drink?")
            Text(
              'What are you drinking?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to instantly log fluids and track hydration saturation',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Quick Drinks Grid (2 Columns, generous height for non-truncating text)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.65,
              children: [
                _buildDrinkCard(
                  title: 'Pure Water',
                  subtitle: '+250 ml (1 Glass)',
                  icon: Icons.water_drop_rounded,
                  accentColor: AppColors.electricCyan,
                  isDark: isDark,
                  onTap: () => _logPresetDrink(
                    context,
                    type: LiquidDrinkType.water,
                    name: 'Pure Water',
                    volumeMl: 250,
                  ),
                ),
                _buildDrinkCard(
                  title: 'Creatine Mix',
                  subtitle: '+300 ml (5g Saturation)',
                  icon: Icons.bolt_rounded,
                  accentColor: const Color(0xFFFF9E00),
                  isDark: isDark,
                  onTap: () => _logPresetDrink(
                    context,
                    type: LiquidDrinkType.creatine,
                    name: 'Creatine Monohydrate',
                    volumeMl: 300,
                    note: '5g Creatine + 300ml Water',
                  ),
                ),
                _buildDrinkCard(
                  title: 'Glucose & Salts',
                  subtitle: '+350 ml (Intra-workout)',
                  icon: Icons.flash_on_rounded,
                  accentColor: AppColors.limeGreen,
                  isDark: isDark,
                  onTap: () => _logPresetDrink(
                    context,
                    type: LiquidDrinkType.glucose,
                    name: 'Glucose & Electrolytes',
                    volumeMl: 350,
                    note: 'Fast glycogen replenish',
                  ),
                ),
                _buildDrinkCard(
                  title: 'Protein Shake',
                  subtitle: '+300 ml (Whey/Plant)',
                  icon: Icons.local_drink_rounded,
                  accentColor: const Color(0xFF7C4DFF),
                  isDark: isDark,
                  onTap: () => _logPresetDrink(
                    context,
                    type: LiquidDrinkType.protein,
                    name: 'Protein Shake',
                    volumeMl: 300,
                    note: '25g Protein isolate',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Custom Drink / Water Bottle Quick Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                        color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    icon: const Icon(Icons.wine_bar_rounded, size: 18),
                    label: const Text('+500 ml Bottle'),
                    onPressed: () => _logPresetDrink(
                      context,
                      type: LiquidDrinkType.water,
                      name: 'Water Bottle',
                      volumeMl: 500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      foregroundColor: AppColors.electricCyan,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.electricCyan, width: 1.2),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Custom Liquid', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showCustomDrinkDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 3. Hydration Balance Metrics Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Fluid Volume',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalMl / $targetMl ml (${(percent * 100).toInt()}%)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.electricCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.electricCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${nutrition.waterGlasses} / ${nutrition.targetWater} Glasses',
                          style: const TextStyle(
                            color: AppColors.electricCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Smooth Progress Track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.electricCyan),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Glass Icons Row (Interactive)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(nutrition.targetWater, (index) {
                      final isFilled = index < nutrition.waterGlasses;
                      return GestureDetector(
                        onTap: () => notifier.setWater(index + 1),
                        child: Icon(
                          isFilled ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                          color: isFilled
                              ? AppColors.electricCyan
                              : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                          size: 26,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Plus / Minus Buttons
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.remove_rounded, size: 16),
                        label: const Text('Minus Glass'),
                        onPressed: nutrition.waterGlasses > 0 ? () => notifier.decrementWater() : null,
                      ),
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
            ),
            const SizedBox(height: 22),

            // 4. Logged Drinks Feed / Timeline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Drink Entries',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${nutrition.loggedDrinks.length} entries',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (nutrition.loggedDrinks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 40,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No drink entries logged yet today',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any liquid option above (Water, Creatine, Glucose, Custom) to log your fluid balance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...nutrition.loggedDrinks.map((entry) {
                final timeStr = DateFormat('h:mm a').format(entry.loggedAt);
                final drinkIcon = _getDrinkIcon(entry.type);
                final drinkColor = _getDrinkColor(entry.type);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: drinkColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(drinkIcon, color: drinkColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.volumeMl} ml • $timeStr${entry.note != null ? ' • ${entry.note}' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                        onPressed: () {
                          notifier.removeDrink(entry.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${entry.name}'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDrinkIcon(LiquidDrinkType type) {
    switch (type) {
      case LiquidDrinkType.water:
        return Icons.water_drop_rounded;
      case LiquidDrinkType.creatine:
        return Icons.bolt_rounded;
      case LiquidDrinkType.glucose:
        return Icons.flash_on_rounded;
      case LiquidDrinkType.protein:
        return Icons.local_drink_rounded;
      case LiquidDrinkType.custom:
        return Icons.local_cafe_rounded;
    }
  }

  Color _getDrinkColor(LiquidDrinkType type) {
    switch (type) {
      case LiquidDrinkType.water:
        return AppColors.electricCyan;
      case LiquidDrinkType.creatine:
        return const Color(0xFFFF9E00);
      case LiquidDrinkType.glucose:
        return AppColors.limeGreen;
      case LiquidDrinkType.protein:
        return const Color(0xFF7C4DFF);
      case LiquidDrinkType.custom:
        return Colors.tealAccent;
    }
  }
}
