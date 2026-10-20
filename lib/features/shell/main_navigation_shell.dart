import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'package:fit_host/features/profile/presentation/widgets/sync_status_indicator.dart';
import 'package:fit_host/core/theme/app_motion.dart';

class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/progress')) return 2;
    if (location.startsWith('/nutrition')) return 3;
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
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final activeState = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 4-item bottom navigation dock (Profile removed as requested; accessible via header / more menu)
    final navItems = [
      _NavItemData(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center_rounded, label: 'Workouts'),
      _NavItemData(icon: Icons.show_chart_rounded, selectedIcon: Icons.show_chart_rounded, label: 'Activity'),
      _NavItemData(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'My Diary'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Screen Content with Apple iOS Framer-Motion window switch transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: AppMotion.iosDecelerate,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return AppleTransitions.buildWindowSwitchTransition(
                child: child,
                animation: animation,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(selectedIndex),
              child: child,
            ),
          ),

          // Top Offline / Outbox Status Banner
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            left: 16,
            right: 16,
            child: const OfflineSyncBanner(),
          ),

          // Active Workout Floating Banner (sitting above floating navigation dock)
          if (activeState.isActive && activeState.workout != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: BouncyTap(
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

          // Floating Island Bottom Navigation Dock (4 tabs: Home, Workouts, Activity, My Diary)
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: RepaintBoundary(
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161920) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
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

                    return BouncyTap(
                      scaleDown: 0.94,
                      onTap: () {
                        if (!isSelected) {
                          AppMotion.selectHaptic();
                          _onItemTapped(index, context);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 18 : 14,
                          vertical: isSelected ? 10 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.limeGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.limeGreen.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: isSelected ? 18 : 22,
                              color: isSelected
                                  ? Colors.black
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
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
