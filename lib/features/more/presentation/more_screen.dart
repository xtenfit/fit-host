import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../nutrition/presentation/widgets/custom_meal_routine_sheet.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Features & Tools',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
          children: [
            // 1. Planning & Schedules Section (Features)
            _buildSectionHeader('Planning & Schedules'),
            const SizedBox(height: 10),
            _buildGridCards(
              context,
              isDark,
              [
                _MoreCardItem(
                  title: 'Fitness Calendar',
                  subtitle: 'Month, week & day workout agenda',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.electricBlue,
                  route: '/calendar',
                ),
                _MoreCardItem(
                  title: 'Reminders & Alarms',
                  subtitle: 'Workout, meal & hydration alerts',
                  icon: Icons.alarm_rounded,
                  color: const Color(0xFFFF9E00),
                  route: '/reminders',
                ),
                _MoreCardItem(
                  title: 'Daily Planner',
                  subtitle: 'Today\'s routine & task checklist',
                  icon: Icons.checklist_rounded,
                  color: AppColors.limeGreen,
                  route: '/planner',
                ),
                _MoreCardItem(
                  title: 'Daily Life Diary',
                  subtitle: 'Career, fitness & voice memo notes',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFFA855F7),
                  route: '/diary',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Movement & Steps Section (Feature)
            _buildSectionHeader('Movement & Pedometer'),
            const SizedBox(height: 10),
            _buildListContainer(
              isDark,
              [
                _MoreListItem(
                  title: 'Step Counter & Distance',
                  subtitle: 'Real-time pedometer, walking/running km & 7-day trend',
                  icon: Icons.directions_walk_rounded,
                  color: AppColors.limeGreen,
                  onTap: () => context.push('/steps'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Nutrition & Hydration Section (Features)
            _buildSectionHeader('Nutrition & Hydration'),
            const SizedBox(height: 10),
            _buildListContainer(
              isDark,
              [
                _MoreListItem(
                  title: 'My Diet & Nutrition Diary',
                  subtitle: 'Calorie balance, macros, breakfast, lunch & dinner',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFFF6B4A),
                  onTap: () => context.go('/nutrition'),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'Custom Meal Routine Setup',
                  subtitle: 'Configure vegan/non-veg split, target calories & fasting',
                  icon: Icons.restaurant_menu_rounded,
                  color: Colors.deepOrange,
                  onTap: () => CustomMealRoutineSheet.show(context),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'Hydration Tracker',
                  subtitle: 'Daily 3.5L fluid balance and intake logs',
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF00B4D8),
                  onTap: () => context.push('/hydration'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Workouts & Routines Section (Features)
            _buildSectionHeader('Training & Exercises'),
            const SizedBox(height: 10),
            _buildListContainer(
              isDark,
              [
                _MoreListItem(
                  title: 'Workout Routines & Plans',
                  subtitle: 'Pre-built splits, custom programs & history',
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.electricBlue,
                  onTap: () => context.push('/routines'),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'Exercise Library',
                  subtitle: '130+ exercises with anatomy diagrams & muscle targets',
                  icon: Icons.menu_book_rounded,
                  color: Colors.indigoAccent,
                  onTap: () => context.push('/exercises'),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'Start Quick Workout',
                  subtitle: 'Launch active session with live timer & set logging',
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.limeGreen,
                  onTap: () => context.push('/active-workout'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Smart Tools & Utilities Section (Tools)
            _buildSectionHeader('Smart Tools & Audio Controls'),
            const SizedBox(height: 10),
            _buildListContainer(
              isDark,
              [
                _MoreListItem(
                  title: 'Alarm & Reminder Sounds',
                  subtitle: '5 acoustic tones, volume boost, device audio & custom mapping',
                  icon: Icons.volume_up_rounded,
                  color: const Color(0xFFFFB300),
                  onTap: () => context.push('/settings/sound-settings'),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'Home Screen Widgets & Shortcuts',
                  subtitle: 'iOS & Android widget showcase and instant action launchers',
                  icon: Icons.widgets_rounded,
                  color: const Color(0xFF00E5FF),
                  onTap: () => context.push('/settings/widgets'),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'User Manual & Interactive Guides',
                  subtitle: 'Interactive guide for workouts, diet, alarms & sensors',
                  icon: Icons.auto_stories_rounded,
                  color: AppColors.limeGreen,
                  onTap: () => context.push('/settings/user-manual'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildGridCards(
    BuildContext context,
    bool isDark,
    List<_MoreCardItem> items,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return BouncyTap(
          onTap: () => context.push(item.route),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListContainer(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }
}

class _MoreCardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _MoreCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _MoreListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MoreListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTap(
      scaleDown: 0.98,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
