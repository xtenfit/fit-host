import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imageAsset;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMultiSelect;

  const OnboardingSelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imageAsset,
    required this.isSelected,
    required this.onTap,
    this.isMultiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.electricBlueSurface
                  : AppColors.electricBlueSurfaceLight)
              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue
                : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon or Asset Illustration
            if (imageAsset != null)
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imageAsset!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fitness_center_rounded, size: 22),
                  ),
                ),
              )
            else if (icon != null)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.electricBlue.withValues(alpha: 0.2)
                      : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.electricBlue
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.electricBlueDark)
                          : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Selection Indicator: Checkmark for multi-select, Radio for single
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: isMultiSelect ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isMultiSelect ? BorderRadius.circular(6) : null,
                color: isSelected ? AppColors.electricBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.electricBlue
                      : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      isMultiSelect ? Icons.check_rounded : Icons.circle,
                      size: isMultiSelect ? 16 : 8,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
