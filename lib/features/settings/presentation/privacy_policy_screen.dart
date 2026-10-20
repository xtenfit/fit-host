import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                      ? [const Color(0xFF132219), const Color(0xFF1A1F2C)]
                      : [const Color(0xFFE8FDF0), Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.35),
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
                          color: AppColors.limeGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security_rounded, color: AppColors.limeGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'End-to-End User Encryption',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.electricCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'v1.2.2v2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.electricCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Powered by amitrana • Developed & Managed by amitrana team\nOfficial Support: support@amitrana.tech',
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
              title: '1. Transparent Data Collection & Service Improvement',
              body:
                  'We collect user data to improve user experience and give better services. This includes fitness logs, workout volume metrics, step sensor records, nutrition logs, and user preference settings. We process this information strictly to provide real-time calorie burn estimations, personalized macro cycling recommendations, recovery rest-day guidance, and reliable cloud synchronization and local data protection. We strictly adhere to zero unauthorized disclosure, selling, or third-party sharing of your personal health data.',
              isDark: isDark,
            ),
            _buildSection(
              title: '2. End-to-End User Encryption & Local Vault',
              body:
                  'Your data is protected by industry-standard cryptography. When stored locally on your device, all tables (workouts, exercises, biometrics, diary notes, and voice memos) reside in an isolated SQLite database protected by your device sandbox and hardware-backed keystore. When synchronized with the optional cloud backup, all records are encrypted in transit via TLS 1.3/HTTPS and secured at rest using PostgreSQL Row-Level Security (RLS) keys unique to your user identifier.',
              isDark: isDark,
            ),
            _buildSection(
              title: '3. Local Data Storage & Data Accuracy',
              body:
                  'Fit Host provides a complete guest mode with local data storage that operates on your device without mandatory account registration. In Guest mode, all computations and data storage remain securely on your device. When you authenticate, your records synchronize with secure cloud storage. All sensor logs, treadmill entries, workout sets, and diary entries represent real user data with complete numerical precision and zero simulated developer telemetry.',
              isDark: isDark,
            ),
            _buildSection(
              title: '4. Voice Memos & Diary Data Privacy',
              body:
                  'Voice notes recorded within the Daily Work & Life Diary are captured locally in standard high-fidelity audio formats (.m4a/.wav) and saved strictly to your device private app directory. Voice audio files are never analyzed by remote automated bots or third-party ad networks.',
              isDark: isDark,
            ),
            _buildSection(
              title: '5. Universal Export & Permanent Account Deletion',
              body:
                  'Under global privacy laws (including GDPR and CCPA), you maintain absolute ownership over your fitness records. You can generate a comprehensive backup at any moment formatted as an official PDF Health Audit, an Excel Spreadsheet (.xlsx), or raw JSON archive. Furthermore, you can permanently purge all cloud and local records through the Delete Account portal at any time.',
              isDark: isDark,
            ),
            _buildSection(
              title: '6. Support & Privacy Contact',
              body:
                  'If you have inquiries regarding privacy governance, data handling, or wish to exercise your rights under data privacy regulations, reach out directly to our engineering and governance team at:\nEmail: support@amitrana.tech\nManaged by: amitrana team',
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
              color: isDark ? AppColors.limeGreen : Colors.green.shade800,
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
