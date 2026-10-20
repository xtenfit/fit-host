import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import '../../../profile/presentation/widgets/avatar_picker_sheet.dart';

class HomeHeader extends ConsumerWidget {
  final bool isDark;

  const HomeHeader({super.key, required this.isDark});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = ref.watch(userProfileProvider);

    final displayName = authState.isAuthenticated
        ? (authState.displayName ?? profile.name)
        : profile.name;

    return Row(
      children: [
        // Squircle Grid Menu Button with Framer-motion Spring Tap
        BouncyTap(
          onTap: () => context.push('/more'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(14),
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
            child: Icon(
              Icons.grid_view_rounded,
              size: 20,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // User Greeting & Real Profile Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: authState.isAuthenticated
                          ? AppColors.electricCyan.withValues(alpha: 0.15)
                          : AppColors.limeGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      authState.isAuthenticated ? 'PRO' : 'MEMBER',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: authState.isAuthenticated
                            ? AppColors.electricCyan
                            : AppColors.limeGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Notification Bell with Unread Dot and Bouncy Spring Tap
        BouncyTap(
          onTap: () => context.push('/reminders'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(14),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                Positioned(
                  top: 11,
                  right: 12,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.limeGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // User Profile Avatar with Tactile Spring Bounce
        BouncyTap(
          onTap: () => context.push('/profile'),
          child: AppAvatar(
            avatarId: profile.avatarId,
            avatarUrl: authState.avatarUrl,
            name: displayName,
            radius: 22,
            borderColor: authState.isAuthenticated
                ? AppColors.electricCyan
                : AppColors.limeGreen.withValues(alpha: 0.8),
            borderWidth: 1.8,
          ),
        ),
      ],
    );
  }
}
