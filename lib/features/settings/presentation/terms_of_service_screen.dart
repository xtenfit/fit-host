import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1724), const Color(0xFF131722)]
                      : [const Color(0xFFF9F0FF), Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.gavel_rounded, color: Color(0xFFA855F7), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Terms & User Agreement',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'v1.2.2v2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFA855F7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Powered by amitrana • Developed by amitrana team\nManaged by amitrana team • Support: support@amitrana.tech',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Acceptance & Contractual Capacity',
              body:
                  'By installing, copying, launching, or utilizing Fit Host ("the App"), you agree to be bound by all provisions of this agreement. This application is designed, authored, and published by amitrana and maintained by the amitrana team. If you disagree with any portion of these terms, please discontinue using the application immediately.',
              isDark: isDark,
            ),
            _buildSection(
              title: '2. Purpose, Service Enhancement & Data Utilization',
              body:
                  'Fit Host provides fitness tracking, strength workout telemetry, nutrition and macro cycling logs, hydration reminders, and personal work and life diaries. We collect user data to improve user experience and give better services, specifically by optimizing workout recommendations, calculating accurate metabolic expenditures, and maintaining cross-session state consistency. Your data remains protected under strict privacy safeguards.',
              isDark: isDark,
            ),
            _buildSection(
              title: '3. Physical Training & Health Disclaimer',
              body:
                  'Fit Host is an informational tracking tool and is not a medical device, licensed physician, or clinical diagnostic instrument. You should consult a physician or licensed healthcare provider prior to starting or modifying any strenuous workout program or dietary protocol. All exercises, workouts, and dietary suggestions are performed at your own risk.',
              isDark: isDark,
            ),
            _buildSection(
              title: '4. Copyrights & Intellectual Property',
              body:
                  'All software architecture, visual interface components, graphics, animations, branding, documentation, algorithms, and codebases are the exclusive intellectual property of amitrana and protected by international copyright laws. Unauthorized reproduction, reverse engineering, decompilation, or redistribution of this software or any part thereof is strictly prohibited.\n\n© 2026 amitrana. All rights reserved.',
              isDark: isDark,
            ),
            _buildSection(
              title: '5. Technical Inquiries & Contact',
              body:
                  'For legal notices, support questions, or service feedback, contact:\nEmail: support@amitrana.tech\nSubject: Fit Host Inquiries\nPowered by amitrana',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 amitrana. All rights reserved.\nFit Host Application Version 1.2.2v2',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFA855F7) : Colors.purple.shade800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
