import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Reusable CardShell matching FIT HOST locked tokens:
/// - Surface Background: #121A16
/// - Radius: 16
/// - Border: subtle #1F2D26 or brand green highlight
class CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool isSelected;
  final double radius;

  const CardShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.isSelected = false,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    const defaultSurface = Color(0xFF121A16);
    const brandGreen = Color(0xFF00E676);
    const defaultBorder = Color(0xFF1F2D26);

    final bg = backgroundColor ?? defaultSurface;
    final border = isSelected
        ? brandGreen
        : (borderColor ?? defaultBorder);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border,
          width: isSelected ? 1.8 : borderWidth,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: brandGreen.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return BouncyTap(
        onTap: onTap,
        scaleDown: 0.98,
        child: card,
      );
    }

    return card;
  }
}
