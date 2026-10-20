import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Reusable Primary Button matching FIT HOST locked tokens:
/// - Background: #00E676 (brand green)
/// - Text: near-black / #0A0F0D
/// - Radius: 16
/// - Elevation & glow: brand green shadow
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF00E676);

    return BouncyTap(
      onTap: isLoading ? null : onPressed,
      scaleDown: 0.96,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: const Color(0xFF0A0F0D),
          disabledBackgroundColor: brandGreen.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.black38,
          elevation: 4,
          shadowColor: brandGreen.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A0F0D)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: const Color(0xFF0A0F0D)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: Color(0xFF0A0F0D),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
