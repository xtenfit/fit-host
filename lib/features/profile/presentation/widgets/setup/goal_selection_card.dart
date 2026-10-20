import 'package:flutter/material.dart';

/// Interactive Goal Selection Card
/// Uses locked tokens:
/// - Surface: #121A16
/// - Primary: #00E676 (brand green)
/// - Radius: 16
/// - Card title: 17sp w600
/// - Card description: 14sp w400 secondary (#8FA396)
class GoalSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String imageAsset;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeText;

  const GoalSelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.imageAsset,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const brandGreen = Color(0xFF00E676);
    const surfaceColor = Color(0xFF121A16);
    const textSecondary = Color(0xFF8FA396);
    const borderColor = Color(0xFF1F2D26);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: badgeText != null ? 118 : 110,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? surfaceColor : Colors.white)
                : (isDark ? surfaceColor : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? brandGreen
                  : (isDark ? borderColor : const Color(0xFFE5E7EB)),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: brandGreen.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Clean image cutout on Right with fallback
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                width: 150,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) => Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 48,
                      color: brandGreen.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),

              // Title and Subtitle on Left
              Positioned(
                left: 18,
                top: 0,
                bottom: 0,
                right: 140,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badgeText != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: brandGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: brandGreen.withValues(alpha: 0.45),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: brandGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: isSelected
                              ? brandGreen
                              : (isDark ? Colors.white : const Color(0xFF111827)),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDark ? textSecondary : const Color(0xFF6B7280),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Checkmark Badge when Selected
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: brandGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF0A0F0D),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
