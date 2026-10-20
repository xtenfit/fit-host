import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/home_widget_service.dart';
import '../../profile/presentation/controllers/user_profile_controller.dart';
import '../../steps/presentation/controllers/step_controller.dart';
import '../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../home/presentation/controllers/home_dashboard_controller.dart';

class HomeWidgetsHubScreen extends ConsumerStatefulWidget {
  const HomeWidgetsHubScreen({super.key});

  @override
  ConsumerState<HomeWidgetsHubScreen> createState() => _HomeWidgetsHubScreenState();
}

class _HomeWidgetsHubScreenState extends ConsumerState<HomeWidgetsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedWidgetSize = 1; // 0: Small, 1: Medium, 2: Large, 3: Lock Screen
  int _selectedThemeIndex = 0; // 0: Dark Obsidian, 1: Neon Lime, 2: Cyber Cyan

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final stepState = ref.watch(stepControllerProvider);
    final nutrition = ref.watch(nutritionProvider);
    final dashboard = ref.watch(homeDashboardProvider);

    final currentSteps = stepState.todaySteps;
    final stepGoal = profile.dailyStepsGoal > 0 ? profile.dailyStepsGoal : 10000;
    final stepProgress = (currentSteps / stepGoal).clamp(0.0, 1.0);
    final caloriesBurned = stepState.calories;
    final waterGlasses = nutrition.waterGlasses;
    final targetWater = nutrition.targetWater > 0 ? nutrition.targetWater : 8;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Home Screen Widgets'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Intro Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF161F2E), const Color(0xFF0D131D)]
                      : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.electricCyan.withValues(alpha: isDark ? 0.3 : 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.widgets_rounded,
                      color: AppColors.electricCyan,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Glanceable Fitness',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add live telemetry widgets to your iOS or Android home screen for instant tracking without opening the app.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
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
            const SizedBox(height: 24),

            // Size Selector Segmented Chips
            const Text(
              'WIDGET FORM FACTOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.electricCyan,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSizeChip(0, 'Small (2x2)', Icons.crop_square_rounded),
                const SizedBox(width: 8),
                _buildSizeChip(1, 'Medium (4x2)', Icons.view_stream_rounded),
                const SizedBox(width: 8),
                _buildSizeChip(2, 'Large (4x4)', Icons.grid_view_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSizeChip(3, 'Lock Screen Accessory', Icons.screen_lock_portrait_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Theme Styling Palette
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ACCENT THEME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.electricCyan,
                  ),
                ),
                Row(
                  children: [
                    _buildThemeDot(0, const Color(0xFF1E293B), 'Obsidian'),
                    const SizedBox(width: 8),
                    _buildThemeDot(1, AppColors.limeGreen, 'Lime'),
                    const SizedBox(width: 8),
                    _buildThemeDot(2, AppColors.electricCyan, 'Cyan'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Interactive Widget Preview Canvas
            Center(
              child: _buildWidgetPreview(
                isDark: isDark,
                steps: currentSteps,
                stepGoal: stepGoal,
                stepProgress: stepProgress,
                calories: caloriesBurned,
                waterGlasses: waterGlasses,
                targetWater: targetWater,
              ),
            ),
            const SizedBox(height: 16),

            // Real Native Sync Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await HomeWidgetService.instance.syncData(
                    steps: currentSteps,
                    stepGoal: stepGoal,
                    calories: caloriesBurned,
                    waterGlasses: waterGlasses,
                    targetWater: targetWater,
                    streak: dashboard.streakDays,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor:
                            success ? const Color(0xFF131722) : Colors.red[900],
                        content: Row(
                          children: [
                            Icon(
                              success
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              color: success ? AppColors.limeGreen : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                success
                                    ? 'Synced to Home Widget: $currentSteps steps • $waterGlasses glasses'
                                    : 'Failed to sync with home widget engine',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.sync_rounded, size: 20),
                label: const Text(
                  'Sync Telemetry to Native OS Widget',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instant Quick Shortcuts
            const Text(
              'ONE-TAP LAUNCHER SHORTCUTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.electricCyan,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildShortcutTile(
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.limeGreen,
                    title: 'Start Live Workout',
                    subtitle: 'Launch active resistance or HIIT timer',
                    onTap: () => context.push('/workouts'),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                  _buildShortcutTile(
                    icon: Icons.directions_walk_rounded,
                    color: AppColors.electricCyan,
                    title: 'Log Steps & Activity',
                    subtitle: 'Record treadmill, outdoor walk or stride distance',
                    onTap: () => context.push('/steps'),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                  _buildShortcutTile(
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF38BDF8),
                    title: 'Log Fluid Hydration',
                    subtitle: 'One-tap water, creatine or protein shake',
                    onTap: () => context.push('/hydration'),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                  _buildShortcutTile(
                    icon: Icons.mic_rounded,
                    color: const Color(0xFFA855F7),
                    title: 'New Daily Diary & Voice Memo',
                    subtitle: 'Capture voice reflections and work thoughts',
                    onTap: () => context.push('/diary'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Installation Guide Tabs
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.electricCyan,
                    labelColor: isDark ? Colors.white : Colors.black87,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                    tabs: const [
                      Tab(text: 'iOS (iPhone / iPad)'),
                      Tab(text: 'Android (Home Screen)'),
                    ],
                  ),
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInstallationSteps([
                          '1. Go to your iPhone or iPad Home Screen.',
                          '2. Touch and hold any empty area until the apps jiggle.',
                          '3. Tap the "+" (Add Widget) button in the upper corner.',
                          '4. Search for "FitHost" in the widget gallery.',
                          '5. Swipe to select your preferred size (Small, Medium, or Large) and tap "Add Widget".',
                          '6. Optional: Stack it on top of another widget to create a smart cycling Smart Stack.',
                        ], isDark),
                        _buildInstallationSteps([
                          '1. Long-press on any empty space on your Android Home Screen.',
                          '2. Select "Widgets" from the bottom popup menu.',
                          '3. Scroll down and locate "FitHost" in your installed apps.',
                          '4. Touch and hold the FitHost widget form factor you desire.',
                          '5. Drag the widget to your home screen and release.',
                          '6. Resize the handles to expand telemetry fields dynamically.',
                        ], isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // System attribution footer
            Center(
              child: Column(
                children: [
                  Text(
                    'FitHost v1.2.2v2 Widget Engine',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Powered by amitrana • Managed by amitrana team',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeChip(int index, String label, IconData icon) {
    final isSelected = _selectedWidgetSize == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWidgetSize = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.electricCyan.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.electricCyan
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.electricCyan : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.electricCyan : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeDot(int index, Color color, String name) {
    final isSelected = _selectedThemeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedThemeIndex = index),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Color get _accentColor {
    switch (_selectedThemeIndex) {
      case 1:
        return AppColors.limeGreen;
      case 2:
        return AppColors.electricCyan;
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _buildWidgetPreview({
    required bool isDark,
    required int steps,
    required int stepGoal,
    required double stepProgress,
    required int calories,
    required int waterGlasses,
    required int targetWater,
  }) {
    final accent = _accentColor;

    switch (_selectedWidgetSize) {
      case 0:
        // Small (2x2)
        return Container(
          width: 160,
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
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
                  Icon(Icons.directions_walk_rounded, color: accent, size: 22),
                  Text(
                    'FITHOST',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$steps',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'of $stepGoal steps',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stepProgress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
          ),
        );

      case 1:
        // Medium (4x2)
        return Container(
          width: 320,
          height: 160,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left Ring & Steps
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk_rounded, color: accent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'DAILY STEPS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$steps',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Goal: $stepGoal • ${(stepProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stepProgress,
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              VerticalDivider(
                width: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              const SizedBox(width: 16),
              // Right Quick Telemetry
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Color(0xFFF97316), size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$calories kcal',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Burned',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white54 : Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.water_drop_rounded,
                            color: AppColors.electricCyan, size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$waterGlasses / $targetWater cups',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Hydration',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white54 : Colors.black45),
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
        );

      case 2:
        // Large (4x4)
        return Container(
          width: 320,
          height: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 10),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fitness_center_rounded, color: accent, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FITHOST COMMAND',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$steps',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Daily Steps ($stepGoal goal)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: stepProgress,
                      strokeWidth: 6,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stepProgress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              Divider(color: isDark ? Colors.white12 : Colors.black12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricMini(
                      Icons.local_fire_department_rounded,
                      const Color(0xFFF97316),
                      '$calories',
                      'Kcal Burned',
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricMini(
                      Icons.water_drop_rounded,
                      AppColors.electricCyan,
                      '$waterGlasses / $targetWater',
                      'Hydration',
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricMini(
                      Icons.bedtime_rounded,
                      const Color(0xFFA855F7),
                      '7h 45m',
                      'Sleep Score',
                      isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 3:
      default:
        // Lock Screen Accessory
        return Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: stepProgress,
                  strokeWidth: 3.5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$steps STEPS',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${(stepProgress * 100).toInt()}% of $stepGoal',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMetricMini(
      IconData icon, Color color, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildInstallationSteps(List<String> steps, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            steps[index],
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        );
      },
    );
  }
}
