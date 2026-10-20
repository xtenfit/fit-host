import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/alarm_sound_service.dart';

class SoundSettingsScreen extends ConsumerStatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  ConsumerState<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends ConsumerState<SoundSettingsScreen> {
  String? _currentlyPlayingId;

  Future<void> _togglePreview(String soundId, bool isPlaying, bool boostVolume) async {
    final service = ref.read(alarmSoundServiceProvider);
    if (isPlaying) {
      await service.stopSound();
      setState(() => _currentlyPlayingId = null);
    } else {
      setState(() => _currentlyPlayingId = soundId);
      await service.previewSound(soundId, boostVolume: boostVolume);
      // Automatically reset playing state after 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _currentlyPlayingId == soundId) {
          setState(() => _currentlyPlayingId = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsAsync = ref.watch(alarmSoundSettingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Alarm & Reminder Sounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading sound settings: $err')),
        data: (settings) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF261D10), const Color(0xFF131722)]
                          : [const Color(0xFFFFF7E6), Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.volume_up_rounded, color: Color(0xFFFFB300), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acoustic Alert Engine',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                Text(
                                  '5 Built-in Tones + Activity Controls',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'v1.2.2v2',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFFFB300)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select default notification chimes, boost stream volume for loud gym environments, and customize alert sounds for workouts, hydration, and daily life diaries.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Default Sounds
                const Text(
                  'Default Alarm & Reminder Sounds',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                const SizedBox(height: 10),

                ...AlarmSoundService.defaultPresets.map((preset) {
                  final isSelected = settings.defaultSoundId == preset.id;
                  final isPlaying = _currentlyPlayingId == preset.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.limeGreen
                              : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                          color: isPlaying ? Colors.redAccent : AppColors.limeGreen,
                          size: 32,
                        ),
                        onPressed: () => _togglePreview(preset.id, isPlaying, settings.fullVolumeBoost),
                      ),
                      title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                        '${preset.description} • ${preset.category}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.limeGreen : Colors.grey,
                        ),
                        onPressed: () => ref.read(alarmSoundSettingsProvider.notifier).setDefaultSound(preset.id),
                      ),
                      onTap: () => ref.read(alarmSoundSettingsProvider.notifier).setDefaultSound(preset.id),
                    ),
                    ),
                  );
                }),

                // Custom Device Sound Section
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: settings.defaultSoundId == AlarmSoundService.customSoundId
                          ? AppColors.limeGreen
                          : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                      width: settings.defaultSoundId == AlarmSoundService.customSoundId ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.electricCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.audio_file_rounded,
                              color: AppColors.electricCyan,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Custom Device Audio',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  settings.customAudioName ?? 'Select any MP3, WAV, AAC from your phone',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: settings.customAudioName != null
                                        ? AppColors.limeGreen
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    fontWeight: settings.customAudioName != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (settings.customAudioName != null) ...[
                            IconButton(
                              tooltip: 'Preview custom audio',
                              icon: Icon(
                                _currentlyPlayingId == AlarmSoundService.customSoundId
                                    ? Icons.stop_circle_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: _currentlyPlayingId == AlarmSoundService.customSoundId
                                    ? Colors.redAccent
                                    : AppColors.electricCyan,
                                size: 28,
                              ),
                              onPressed: () => _togglePreview(
                                AlarmSoundService.customSoundId,
                                _currentlyPlayingId == AlarmSoundService.customSoundId,
                                settings.fullVolumeBoost,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Set as default alarm',
                              icon: Icon(
                                settings.defaultSoundId == AlarmSoundService.customSoundId
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: settings.defaultSoundId == AlarmSoundService.customSoundId
                                    ? AppColors.limeGreen
                                    : Colors.grey,
                              ),
                              onPressed: () => ref
                                  .read(alarmSoundSettingsProvider.notifier)
                                  .setDefaultSound(AlarmSoundService.customSoundId),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await ref
                                    .read(alarmSoundSettingsProvider.notifier)
                                    .pickCustomAudio();
                                if (picked && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Custom device sound loaded and set!'),
                                      backgroundColor: AppColors.limeGreen,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                settings.customAudioName == null
                                    ? Icons.folder_open_rounded
                                    : Icons.sync_rounded,
                                size: 18,
                              ),
                              label: Text(
                                settings.customAudioName == null
                                    ? 'Select Audio File from Device'
                                    : 'Change Custom Sound',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (settings.customAudioName != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Remove custom audio',
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () =>
                                  ref.read(alarmSoundSettingsProvider.notifier).removeCustomAudio(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Device System Default Option
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: settings.defaultSoundId == AlarmSoundService.deviceDefaultId
                            ? AppColors.limeGreen
                            : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                        width: settings.defaultSoundId == AlarmSoundService.deviceDefaultId ? 1.5 : 1.0,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phonelink_ring_rounded, color: Colors.blueAccent, size: 20),
                    ),
                    title: const Text('Device System Default Sound', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(
                      'Use standard OS notification tone configured in system settings',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        settings.defaultSoundId == AlarmSoundService.deviceDefaultId
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: settings.defaultSoundId == AlarmSoundService.deviceDefaultId
                            ? AppColors.limeGreen
                            : Colors.grey,
                      ),
                      onPressed: () => ref.read(alarmSoundSettingsProvider.notifier).setDefaultSound(AlarmSoundService.deviceDefaultId),
                    ),
                    onTap: () => ref.read(alarmSoundSettingsProvider.notifier).setDefaultSound(AlarmSoundService.deviceDefaultId),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: Volume Boost & Vibration Controls
                const Text(
                  'Sound & Volume Control',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: settings.fullVolumeBoost,
                        activeTrackColor: AppColors.limeGreen,
                        title: const Text('Full Volume Boost (Gym Mode)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          'Forces reminder audio streams to full volume to penetrate gym background noise',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        onChanged: (val) => ref.read(alarmSoundSettingsProvider.notifier).toggleVolumeBoost(val),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Haptic Vibration Pattern',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tactile alert feedback on notification',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: settings.vibrationPattern,
                            underline: const SizedBox(),
                            dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'gentle', child: Text('Gentle Pulse')),
                              DropdownMenuItem(value: 'standard', child: Text('Standard')),
                              DropdownMenuItem(value: 'double_pulse', child: Text('Double Pulse')),
                              DropdownMenuItem(value: 'strong', child: Text('Gym Strong')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(alarmSoundSettingsProvider.notifier).setVibrationPattern(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

                // Section 3: Activity-Specific Sound Mapping
                const Text(
                  'Activity-Specific Sound Assignment',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                const SizedBox(height: 6),
                Text(
                  'Assign distinctive sound signatures to different health actions',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                ...[
                  _ActivitySoundRowData(
                    key: 'workout',
                    title: 'Workouts & Strength Training',
                    subtitle: 'Alerts when it is time to lift or train',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.limeGreen,
                  ),
                  _ActivitySoundRowData(
                    key: 'hydration',
                    title: 'Hydration & Water Drink Alerts',
                    subtitle: 'Gentle hydration check-ins',
                    icon: Icons.water_drop_rounded,
                    color: Colors.blueAccent,
                  ),
                  _ActivitySoundRowData(
                    key: 'nutrition',
                    title: 'Meals & Nutrition Reminders',
                    subtitle: 'Scheduled meal windows and macro checks',
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _ActivitySoundRowData(
                    key: 'steps',
                    title: 'Step Goal & Movement Prompts',
                    subtitle: 'Prompts to hit 10,000 steps daily',
                    icon: Icons.directions_walk_rounded,
                    color: const Color(0xFF00E5FF),
                  ),
                  _ActivitySoundRowData(
                    key: 'diary',
                    title: 'Daily Work & Life Diary Prompts',
                    subtitle: 'Evening reflection & voice memo notes',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFFA855F7),
                  ),
                  _ActivitySoundRowData(
                    key: 'recovery',
                    title: 'Sleep & Recovery Reminders',
                    subtitle: 'Wind down and sleep preparation',
                    icon: Icons.bedtime_rounded,
                    color: Colors.indigoAccent,
                  ),
                ].map((act) {
                  final currentSoundId = settings.activitySounds[act.key] ?? 'cyber_chime';
                  final isPlaying = _currentlyPlayingId == 'act_${act.key}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: act.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(act.icon, color: act.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    act.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: (currentSoundId == AlarmSoundService.customSoundId && settings.customAudioName == null)
                                        ? 'cyber_chime'
                                        : currentSoundId,
                                    dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                                    items: [
                                      ...AlarmSoundService.defaultPresets.map(
                                        (p) => DropdownMenuItem(
                                          value: p.id,
                                          child: Text(
                                            p.name,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      if (settings.customAudioName != null)
                                        DropdownMenuItem(
                                          value: AlarmSoundService.customSoundId,
                                          child: Text(
                                            'Custom: ${settings.customAudioName}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.limeGreen),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      const DropdownMenuItem(
                                        value: AlarmSoundService.deviceDefaultId,
                                        child: Text('Device Default', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(alarmSoundSettingsProvider.notifier).setActivitySound(act.key, val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                color: isPlaying ? Colors.redAccent : act.color,
                                size: 22,
                              ),
                              onPressed: () => _togglePreview(currentSoundId, isPlaying, settings.fullVolumeBoost),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '© 2026 amitrana. All rights reserved.\nFit Host Acoustic Alert Engine v1.2.2v2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivitySoundRowData {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ActivitySoundRowData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
