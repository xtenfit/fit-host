import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool showSkip;

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 12,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.onSkip,
    this.showSkip = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Navigation Controls: Back, Step Counter, Skip
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBack != null && currentStep > 1)
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              )
            else
              const SizedBox(width: 36),

            // Step Indicator Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.electricBlueSurface : AppColors.electricBlueSurfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Step $currentStep of $totalSteps',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.electricBlue,
                ),
              ),
            ),

            if (showSkip && onSkip != null)
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 14),

        // Animated Linear Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
          ),
        ),
        const SizedBox(height: 20),

        // Step Heading & Subtitle
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
