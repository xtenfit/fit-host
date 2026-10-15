import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/nutrition')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/workouts');
        break;
      case 2:
        context.go('/progress');
        break;
      case 3:
        context.go('/nutrition');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final activeState = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navItems = [
      _NavItemData(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center_rounded, label: 'Workouts'),
      _NavItemData(icon: Icons.show_chart_rounded, selectedIcon: Icons.show_chart_rounded, label: 'Activity'),
      _NavItemData(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'My Diary'),
      _NavItemData(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          child,

          // Active Workout Floating Banner (sitting above floating navigation dock)
          if (activeState.isActive && activeState.workout != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: GestureDetector(
                onTap: () => context.push('/active-workout'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.limeGreen.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.limeGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeState.workout!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${activeState.workout!.completedSets}/${activeState.workout!.totalSets} sets • ${_formatDuration(activeState.workout!.durationSeconds)}',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.limeGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Island Bottom Navigation Dock matching reference UI
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161920) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = index == selectedIndex;

                  if (isSelected) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B4A),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B4A).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.selectedIcon, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return InkWell(
                    onTap: () => _onItemTapped(index, context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
