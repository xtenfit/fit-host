import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
          'More Features & Tools',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Planning & Schedules Section
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
                  title: 'Notification Settings',
                  subtitle: 'Channels, quiet hours & snoozes',
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFF00B4D8),
                  route: '/settings/notifications',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Nutrition & Fuel Section
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
                  onTap: () => context.push('/nutrition'),
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
                  onTap: () => context.push('/nutrition'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Workouts & Routines Section
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
                  onTap: () => context.push('/workouts'),
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

            // 4. Analytics & Account Section
            _buildSectionHeader('Analytics, Privacy & Data'),
            const SizedBox(height: 10),
            _buildListContainer(
              isDark,
              [
                _MoreListItem(
                  title: 'Activity & Progress Reports',
                  subtitle: 'Volume trends, workout frequency & charts',
                  icon: Icons.show_chart_rounded,
                  color: Colors.purple,
                  onTap: () => context.push('/progress'),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'Profile & Fitness Goals',
                  subtitle: 'Target weight, height, BMR & biometric metrics',
                  icon: Icons.person_rounded,
                  color: Colors.blueAccent,
                  onTap: () => context.push('/profile'),
                ),
                const Divider(height: 1),
                _MoreListItem(
                  title: 'Privacy & Data Export',
                  subtitle: 'Download complete offline SQLite data as JSON',
                  icon: Icons.shield_rounded,
                  color: Colors.teal,
                  onTap: () => context.push('/settings/privacy'),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: items.map((item) {
        return InkWell(
          onTap: () => context.push(item.route),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 22, color: item.color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListContainer(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
