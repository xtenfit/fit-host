import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/theme/app_motion.dart';

class HomeQuickTools extends StatelessWidget {
  final bool isDark;

  const HomeQuickTools({super.key, required this.isDark});

  static const List<_QuickToolItem> _tools = [
    _QuickToolItem(
      title: 'Log Meal',
      subtitle: 'Diary',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF7043),
      route: '/nutrition/diary',
    ),
    _QuickToolItem(
      title: 'Workouts',
      subtitle: 'Train',
      icon: Icons.fitness_center_rounded,
      color: AppColors.electricCyan,
      route: '/workouts',
    ),
    _QuickToolItem(
      title: 'Log Weight',
      subtitle: 'Metrics',
      icon: Icons.monitor_weight_outlined,
      color: AppColors.limeGreen,
      route: '/progress/measurements',
    ),
    _QuickToolItem(
      title: 'Photos',
      subtitle: 'Gallery',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE040FB),
      route: '/progress/gallery',
    ),
    _QuickToolItem(
      title: 'History',
      subtitle: 'Calendar',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFFFB300),
      route: '/calendar',
    ),
    _QuickToolItem(
      title: 'Routines',
      subtitle: 'Programs',
      icon: Icons.format_list_bulleted_rounded,
      color: Color(0xFF7C4DFF),
      route: '/routines',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Tools',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              'Shortcuts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _tools.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tool = _tools[index];
              return _QuickToolCard(tool: tool, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _QuickToolCard extends StatelessWidget {
  final _QuickToolItem tool;
  final bool isDark;

  const _QuickToolCard({required this.tool, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      scaleDown: 0.93,
      onTap: () => context.push(tool.route),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkSurfaceBorder
                : AppColors.lightSurfaceBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tool.icon, color: tool.color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tool.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  tool.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black45,
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
