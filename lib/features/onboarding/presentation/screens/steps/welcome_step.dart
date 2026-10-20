import 'package:flutter/material.dart';
import 'package:fit_host/core/widgets/primary_button.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onContinueAsGuest;

  const WelcomeStep({
    super.key,
    required this.onStart,
    required this.onContinueAsGuest,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Fit Host Logo: hex dumbbell mark
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF121A16),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center_rounded,
                size: 52,
                color: Color(0xFF00E676),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'FIT HOST',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'YOUR PERSONAL FITNESS ARCHITECTURE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Smart Fitness Companion',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Personalized workout routines, nutrition guidance, and progress tracking — no subscriptions, no ads.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8FA396),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 3 Feature Cards
          _buildFeatureCard(
            icon: Icons.sync_rounded,
            title: 'Sync Across Devices',
            description:
                'Your data stays available on every device you sign in to.',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.trending_up_rounded,
            title: 'Progressive Overload Tracking',
            description:
                'Smart rest timer, volume analytics, and weight tracking.',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.lock_outline_rounded,
            title: 'Private by Default',
            description:
                'Your health data stays on your device unless you choose to sync.',
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            text: 'Start Personalization →',
            onPressed: onStart,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onContinueAsGuest,
            child: const Text(
              'Continue as Guest',
              style: TextStyle(
                color: Color(0xFF8FA396),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121A16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color(0xFF00E676),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF0F6F2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8FA396),
                    height: 1.35,
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
