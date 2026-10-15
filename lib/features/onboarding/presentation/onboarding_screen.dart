import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Hero App Icon
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.limeGreen.withValues(alpha: 0.28),
                              blurRadius: 36,
                              spreadRadius: 4,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.limeGreen.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/images/fit_host_app_icon.jpg',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Official Wordmark Banner
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: Colors.black,
                          child: Image.asset(
                            'assets/images/fit_host_wordmark.jpg',
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'High-performance, offline-first strength and conditioning tracker.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Value Pillars
                      _ValuePillar(
                        icon: Icons.lock_open_rounded,
                        title: 'Free Core Forever',
                        description:
                            'All workouts, exercises, and tracking features are completely free.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ValuePillar(
                        icon: Icons.wifi_off_rounded,
                        title: '100% Offline SQLite',
                        description:
                            'No network required. All workout logs and sets stay on your device.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ValuePillar(
                        icon: Icons.trending_up_rounded,
                        title: 'Progressive Overload',
                        description:
                            'Structured set logging, rest timers, and volume analytics.',
                        isDark: isDark,
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // Primary CTA: Continue Offline
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            context.go('/home');
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue Offline',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.black, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary CTA: Cloud Account (Optional)
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Optional Cloud Sync'),
                              content: const Text(
                                'Cloud accounts allow optional backup and synchronization across devices.\n\n'
                                'Fit Host never requires an account or internet connection to log workouts.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.go('/home');
                                  },
                                  child: const Text('Start Offline Now'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'Cloud Account (Optional)',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ValuePillar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _ValuePillar({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.limeGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.limeGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
