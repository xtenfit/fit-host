import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/theme/theme_provider.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/features/workouts/presentation/controllers/workout_providers.dart';
import 'controllers/user_profile_controller.dart';
import 'widgets/sync_status_indicator.dart';
import 'widgets/avatar_picker_sheet.dart';
import '../../auth/presentation/dialogs/sign_out_dialog.dart';
import '../../auth/presentation/dialogs/delete_account_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider);
    final authState = ref.watch(authProvider);
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final completedWorkoutsCount = workoutsAsync.maybeWhen(
      data: (workouts) => workouts.where((w) => w.status == 'completed').length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          // User Profile Card: Dynamic Guest vs Authenticated (Tap to Edit)
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSurfaceBorder
                      : AppColors.lightSurfaceBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar with border
                  AppAvatar(
                    avatarId: profile.avatarId,
                    name: authState.displayName ?? profile.name,
                    radius: 29,
                    borderColor: authState.isAuthenticated
                        ? AppColors.electricCyan
                        : AppColors.limeGreen,
                    borderWidth: 2,
                  ),
                  const SizedBox(width: 16),

                  // Name & Mode details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                authState.isAuthenticated
                                    ? (authState.displayName ?? profile.name)
                                    : profile.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          authState.isAuthenticated
                              ? (authState.email ?? 'Cloud Synced Profile')
                              : 'Guest • ${profile.age}y • ${profile.heightCm.toInt()}cm • ${profile.weightKg.toInt()}kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        const SyncStatusIndicator(compact: true),
                      ],
                    ),
                  ),

                  // Status Pill ('Guest' in guest mode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: authState.isAuthenticated
                          ? AppColors.electricCyan.withValues(alpha: 0.15)
                          : AppColors.limeGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      authState.isAuthenticated ? 'Pro Athlete Cloud' : 'Guest',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: authState.isAuthenticated
                            ? AppColors.electricCyan
                            : AppColors.limeGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Supabase Auth Action Banner
          if (!authState.isAuthenticated) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF162520), const Color(0xFF1B2F25)]
                      : [const Color(0xFFF0FDF4), const Color(0xFFE2FBEA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.4),
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
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: AppColors.limeGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Cloud Backup & Multi-Device Sync',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sign in with Google or Email OTP to backup all your workouts and routines.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/auth/sign-up'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.limeGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/auth/sign-in'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            side: BorderSide(
                              color: isDark ? AppColors.limeGreen.withValues(alpha: 0.5) : Colors.black26,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Authenticated Cloud Sync Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_done_rounded, color: AppColors.electricCyan, size: 22),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fit Host Cloud Active',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Workouts and health metrics live synced',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SyncStatusIndicator(compact: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => SignOutDialog.show(context),
                        icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.orangeAccent),
                        label: const Text('Sign Out', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => DeleteAccountDialog.show(context),
                        icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.error),
                        label: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],



          // Health Intelligence & Metabolism Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.insights_rounded, color: AppColors.electricCyan, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Health Intelligence',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            'Metabolic Diagnostics',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'BMI ${profile.bmi} • ${profile.bmiCategory}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.limeGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metabolic Burn Metrics: BMR, TDEE, Calorie Balance Delta
                Row(
                  children: [
                    _buildProfileTargetMiniBox(
                      'BMR (Resting)',
                      '${profile.bmrCalculated.round()}',
                      'kcal/d',
                      AppColors.electricCyan,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildProfileTargetMiniBox(
                      'TDEE (Burn)',
                      '${profile.tdeeCalculated.round()}',
                      'kcal/d',
                      const Color(0xFFFFB300),
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildProfileTargetMiniBox(
                      'Energy Delta',
                      profile.calorieDelta >= 0 ? '+${profile.calorieDelta}' : '${profile.calorieDelta}',
                      'kcal',
                      profile.calorieDelta > 0
                          ? AppColors.limeGreen
                          : (profile.calorieDelta < 0 ? const Color(0xFFFF5252) : Colors.grey),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Macro Caloric Distribution Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Caloric Macro Ratio',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'P: ${profile.proteinCaloriesPercent}%  •  C: ${profile.carbsCaloriesPercent}%  •  F: ${profile.fatsCaloriesPercent}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: profile.proteinCaloriesPercent.clamp(5, 80),
                            child: Container(height: 7, color: AppColors.electricCyan),
                          ),
                          Expanded(
                            flex: profile.carbsCaloriesPercent.clamp(5, 80),
                            child: Container(height: 7, color: const Color(0xFFF59E0B)),
                          ),
                          Expanded(
                            flex: profile.fatsCaloriesPercent.clamp(5, 80),
                            child: Container(height: 7, color: const Color(0xFFA855F7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target Weight Timeline (if goal weight set)
                if (profile.targetWeightKg != null && (profile.weightKg - profile.targetWeightKg!).abs() > 0.1) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 20, color: AppColors.limeGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.weightKg.toStringAsFixed(1)} kg  ➔  ${profile.targetWeightKg!.toStringAsFixed(1)} kg',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estimated ~${profile.estimatedWeeksToGoal} weeks at ${profile.targetPaceKgPerWeek} kg/week pace',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Lifestyle & Habit Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildLifestyleChip(Icons.water_drop_rounded, '${profile.targetWaterMl} ml/day', AppColors.electricCyan, isDark),
                    _buildLifestyleChip(Icons.bedtime_rounded, '${profile.targetSleepHours.toStringAsFixed(1)}h sleep', const Color(0xFFA855F7), isDark),
                    _buildLifestyleChip(Icons.directions_walk_rounded, '${profile.dailyStepsGoal} steps', const Color(0xFFFFB300), isDark),
                    _buildLifestyleChip(Icons.timer_outlined, profile.fastingProtocolLabel, AppColors.limeGreen, isDark),
                    _buildLifestyleChip(Icons.bolt_rounded, profile.activityLevelLabel, AppColors.electricBlue, isDark),
                  ],
                ),
                const SizedBox(height: 16),

                // Interactive Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(userProfileProvider.notifier).recalculateSuggestedTargets();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Targets recalculated using Mifflin-St Jeor formula.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 15),
                        label: const Text('Recalculate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(userProfileProvider.notifier).toggleMetricUnits();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.straighten_rounded, size: 15),
                        label: Text(
                          profile.useMetricUnits ? 'Units: kg/cm' : 'Units: lbs/ft',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Real User Summary Metrics
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  title: 'Workouts Completed',
                  value: '$completedWorkoutsCount',
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.limeGreen,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryBox(
                  title: 'Data Storage',
                  value: '100% Local',
                  icon: Icons.sd_card_rounded,
                  color: AppColors.electricCyan,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),



          // Settings Section
          Text(
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFF00B4D8),
            title: 'Notification & Alert Settings',
            subtitle: 'Notification channels, quiet hours & reminder banners',
            isDark: isDark,
            onTap: () => context.push('/settings/notifications'),
          ),
          _SettingsTile(
            icon: Icons.security_rounded,
            iconColor: AppColors.limeGreen,
            title: 'System Permissions Manager',
            subtitle: 'Exact alarms, lockscreen popups, notifications & battery',
            isDark: isDark,
            onTap: () => context.push('/permission-settings'),
          ),
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            iconColor: const Color(0xFFFFB300),
            title: 'Alarm & Alert Sounds',
            subtitle: '5 default audio tones, device volume & activity mapping',
            isDark: isDark,
            onTap: () => context.push('/settings/sound-settings'),
          ),
          _SettingsTile(
            icon: Icons.backup_table_rounded,
            iconColor: Colors.teal,
            title: 'Backup & Data Export',
            subtitle: 'Export audit report as PDF, Excel (.xlsx) spreadsheet or JSON',
            isDark: isDark,
            onTap: () => context.push('/settings/privacy'),
          ),
          _SettingsTile(
            icon: Icons.support_agent_rounded,
            iconColor: AppColors.electricCyan,
            title: 'Support & Feedback',
            subtitle: 'Direct support (support@amitrana.tech) with email templates',
            isDark: isDark,
            onTap: () => context.push('/settings/support'),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.electricCyan,
            title: 'Privacy Policy & Encryption',
            subtitle: 'End-to-end user encryption & transparent service data usage',
            isDark: isDark,
            onTap: () => context.push('/settings/privacy-policy'),
          ),
          _SettingsTile(
            icon: Icons.gavel_rounded,
            iconColor: AppColors.warmCoral,
            title: 'Terms & Conditions',
            subtitle: 'User license, service agreements & amitrana copyrights',
            isDark: isDark,
            onTap: () => context.push('/settings/terms-of-service'),
          ),

          const SizedBox(height: 24),

          // Appearance Section
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 22),
                    SizedBox(width: 14),
                    Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox(),
                  dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themeModeProvider.notifier).setMode(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Fit Host Card
          Text(
            'About Fit Host',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSurfaceBorder
                    : AppColors.lightSurfaceBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('App Version', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '1.2.2v2',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.limeGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_rounded, size: 18, color: AppColors.electricCyan),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Powered by amitrana',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Developed by amitrana team  •  Managed by amitrana team',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Fit Host encrypts all biometric, workout and nutrition records on-device. Support inquiries & feature requests can be directed to support@amitrana.tech.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const Divider(height: 24),
                Center(
                  child: Text(
                    '© 2026 amitrana. All rights reserved.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        ),
      ),
    );
  }
}

Widget _buildProfileTargetMiniBox(
    String label, String value, String unit, Color color, bool isDark) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
          ),
        ],
      ),
    ),
  );
}

Widget _buildLifestyleChip(IconData icon, String label, Color color, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

