import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/theme/theme_provider.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSurfaceBorder
                    : AppColors.lightSurfaceBorder,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.limeGreen.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.limeGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Offline Athlete',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Local Storage Active • SQLite',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Free Forever',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Theme Section
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppColors.limeGreen,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Theme Mode',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark (Charcoal)'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light (Soft Gray)'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System Default'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setMode(mode);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Storage & Privacy
          const Text(
            'Data & Privacy',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_rounded, color: AppColors.electricCyan),
                  title: const Text('Offline Local Database'),
                  subtitle: workoutsAsync.when(
                    data: (list) => Text('${list.length} workouts stored in SQLite'),
                    loading: () => const Text('Querying local DB...'),
                    error: (_, _) => const Text('Active'),
                  ),
                  trailing: const Icon(Icons.check_circle_rounded,
                      color: AppColors.limeGreen, size: 20),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Cloud Synchronization'),
                  subtitle: const Text('Optional • Ready for Supabase Auth & RLS'),
                  trailing: const Chip(
                    label: Text('Optional', style: TextStyle(fontSize: 10)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppColors.limeGreen),
                  title: const Text('Privacy & Security Policy'),
                  subtitle: const Text('Zero telemetry • Zero third-party ad trackers'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Privacy & Security Commitment'),
                        content: const Text(
                          'Fit Host is designed offline-first:\n\n'
                          '1. All workout logs and personal measurements remain securely on your device SQLite database.\n'
                          '2. No sensitive data is sold, monetized, or sent to third-party ad networks.\n'
                          '3. Cloud accounts are optional and protected by PostgreSQL Row Level Security (RLS) and encrypted transport.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Understood'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About Section
          const Text(
            'About Fit Host',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Version'),
                  subtitle: Text('1.0.0 (Production Release Candidate)'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.code_rounded),
                  title: Text('Architecture'),
                  subtitle: Text('Flutter • Riverpod • Drift SQLite • GoRouter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
