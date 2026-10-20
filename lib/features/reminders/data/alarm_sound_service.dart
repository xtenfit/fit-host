import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundPreset {
  final String id;
  final String name;
  final String description;
  final List<double> frequencies;
  final double durationSeconds;
  final String category;

  const SoundPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.frequencies,
    required this.durationSeconds,
    required this.category,
  });
}

class AlarmSoundSettings {
  final String defaultSoundId;
  final bool fullVolumeBoost;
  final String vibrationPattern;
  final Map<String, String> activitySounds;
  final String? customAudioPath;
  final String? customAudioName;

  const AlarmSoundSettings({
    required this.defaultSoundId,
    required this.fullVolumeBoost,
    required this.vibrationPattern,
    required this.activitySounds,
    this.customAudioPath,
    this.customAudioName,
  });

  AlarmSoundSettings copyWith({
    String? defaultSoundId,
    bool? fullVolumeBoost,
    String? vibrationPattern,
    Map<String, String>? activitySounds,
    String? customAudioPath,
    String? customAudioName,
    bool clearCustomAudio = false,
  }) {
    return AlarmSoundSettings(
      defaultSoundId: defaultSoundId ?? this.defaultSoundId,
      fullVolumeBoost: fullVolumeBoost ?? this.fullVolumeBoost,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      activitySounds: activitySounds ?? this.activitySounds,
      customAudioPath: clearCustomAudio ? null : (customAudioPath ?? this.customAudioPath),
      customAudioName: clearCustomAudio ? null : (customAudioName ?? this.customAudioName),
    );
  }
}

class AlarmSoundService {
  static const List<SoundPreset> defaultPresets = [
    SoundPreset(
      id: 'cyber_chime',
      name: 'Cyber Chime',
      description: 'Modern clean digital chime with progressive harmonics',
      frequencies: [880.0, 1320.0, 1760.0],
      durationSeconds: 1.2,
      category: 'Nutrition & Meals',
    ),
    SoundPreset(
      id: 'zen_bell',
      name: 'Zen Bell',
      description: 'Harmonic singing bowl gong with warm acoustic decay',
      frequencies: [440.0, 554.37, 659.25],
      durationSeconds: 2.0,
      category: 'Hydration & Rest',
    ),
    SoundPreset(
      id: 'energy_uplift',
      name: 'Energy Uplift',
      description: 'Ascending cadence pulse to motivate active motion',
      frequencies: [587.33, 880.0, 1174.66],
      durationSeconds: 1.4,
      category: 'Steps & Cardio',
    ),
    SoundPreset(
      id: 'titan_horn',
      name: 'Titan Horn',
      description: 'Bold resonant brass gym alert designed for loud gym floors',
      frequencies: [220.0, 329.63, 440.0],
      durationSeconds: 1.6,
      category: 'Heavy Workouts',
    ),
    SoundPreset(
      id: 'midnight_radar',
      name: 'Midnight Radar',
      description: 'Apple-styled crisp acoustic sonar radar ping',
      frequencies: [1046.50, 1318.51, 2093.0],
      durationSeconds: 1.1,
      category: 'Daily Diary',
    ),
  ];

  static const String deviceDefaultId = 'device_default';
  static const String customSoundId = 'custom_device_sound';
  static const String kCustomAudioPathKey = 'fit_host_custom_alarm_path';
  static const String kCustomAudioNameKey = 'fit_host_custom_alarm_name';

  AudioPlayer? _player;

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Synthesizes and caches a high-quality 44.1kHz 16-bit PCM WAV audio file
  Future<File> getOrGenerateSoundFile(SoundPreset preset) async {
    final tempDir = await getTemporaryDirectory();
    final soundFile = File('${tempDir.path}/sound_${preset.id}.wav');

    if (await soundFile.exists()) {
      return soundFile;
    }

    const sampleRate = 44100;
    final totalSamples = (sampleRate * preset.durationSeconds).round();
    final pcmData = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-2.5 * (t / preset.durationSeconds));
      double sample = 0.0;

      for (int f = 0; f < preset.frequencies.length; f++) {
        final freq = preset.frequencies[f];
        final phase = 2 * math.pi * freq * t;
        sample += math.sin(phase) * (1.0 / (f + 1));
      }

      sample = (sample * envelope * 0.75).clamp(-1.0, 1.0);
      pcmData[i] = (sample * 32767).round();
    }

    // Build standard RIFF WAVE header
    final byteData = _encodeWav(pcmData, sampleRate: sampleRate);
    await soundFile.writeAsBytes(byteData);
    return soundFile;
  }

  Uint8List _encodeWav(Int16List pcmData, {required int sampleRate}) {
    final numSamples = pcmData.length;
    final subChunk2Size = numSamples * 2; // 16-bit = 2 bytes per sample
    final chunkSize = 36 + subChunk2Size;

    final bytes = BytesBuilder();

    // 1. ChunkID "RIFF"
    bytes.add([0x52, 0x49, 0x46, 0x46]);
    // 2. ChunkSize
    bytes.add(_int32ToBytes(chunkSize));
    // 3. Format "WAVE"
    bytes.add([0x57, 0x41, 0x56, 0x45]);
    // 4. Subchunk1ID "fmt "
    bytes.add([0x66, 0x6D, 0x74, 0x20]);
    // 5. Subchunk1Size (16 for PCM)
    bytes.add(_int32ToBytes(16));
    // 6. AudioFormat (1 for PCM)
    bytes.add(_int16ToBytes(1));
    // 7. NumChannels (1 mono)
    bytes.add(_int16ToBytes(1));
    // 8. SampleRate
    bytes.add(_int32ToBytes(sampleRate));
    // 9. ByteRate = SampleRate * NumChannels * BitsPerSample/8
    bytes.add(_int32ToBytes(sampleRate * 2));
    // 10. BlockAlign = NumChannels * BitsPerSample/8
    bytes.add(_int16ToBytes(2));
    // 11. BitsPerSample (16 bits)
    bytes.add(_int16ToBytes(16));
    // 12. Subchunk2ID "data"
    bytes.add([0x64, 0x61, 0x74, 0x61]);
    // 13. Subchunk2Size
    bytes.add(_int32ToBytes(subChunk2Size));
    // 14. PCM Samples
    final buffer = Uint8List(subChunk2Size);
    for (int i = 0; i < numSamples; i++) {
      final sample = pcmData[i];
      buffer[i * 2] = sample & 0xFF;
      buffer[i * 2 + 1] = (sample >> 8) & 0xFF;
    }
    bytes.add(buffer);

    return bytes.toBytes();
  }

  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  List<int> _int16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }

  /// Picks an audio file from the user's device and saves it to app storage
  Future<File?> pickAndSaveCustomAudio() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      if (files.isEmpty || files.first.path == null) {
        return null;
      }
      final pickedPath = files.first.path!;
      final pickedName = files.first.name;
      final docsDir = await getApplicationDocumentsDirectory();
      final ext = pickedName.contains('.') ? pickedName.split('.').last : 'mp3';
      final savedFile = File('${docsDir.path}/custom_device_alarm.$ext');
      await File(pickedPath).copy(savedFile.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kCustomAudioPathKey, savedFile.path);
      await prefs.setString(kCustomAudioNameKey, pickedName);

      return savedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking custom audio: $e');
      }
      return null;
    }
  }

  /// Clears stored custom device audio
  Future<void> clearCustomAudio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(kCustomAudioPathKey);
      if (path != null) {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      }
      await prefs.remove(kCustomAudioPathKey);
      await prefs.remove(kCustomAudioNameKey);
    } catch (_) {}
  }

  /// Plays preview of sound preset or custom audio
  Future<void> previewSound(String soundId, {bool boostVolume = false}) async {
    try {
      await player.stop();

      if (soundId == customSoundId) {
        final prefs = await SharedPreferences.getInstance();
        final path = prefs.getString(kCustomAudioPathKey);
        if (path != null && await File(path).exists()) {
          await player.setVolume(boostVolume ? 1.0 : 0.85);
          await player.play(DeviceFileSource(path));
          return;
        }
      }

      if (soundId == deviceDefaultId) {
        // Fallback tone for device default
        soundId = 'cyber_chime';
      }

      final preset = defaultPresets.firstWhere(
        (p) => p.id == soundId,
        orElse: () => defaultPresets.first,
      );

      final file = await getOrGenerateSoundFile(preset);
      await player.setVolume(boostVolume ? 1.0 : 0.85);
      await player.play(DeviceFileSource(file.path));
    } catch (_) {}
  }

  bool _isContinuousAlarmRinging = false;
  bool get isContinuousAlarmRinging => _isContinuousAlarmRinging;

  /// Starts continuous ringing of alarm sound in a loop until dismissed
  Future<void> startContinuousAlarm({String? soundId, bool boostVolume = true}) async {
    _isContinuousAlarmRinging = true;
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      await player.stop();

      final targetSound = soundId ?? 'cyber_chime';

      if (targetSound == customSoundId) {
        final prefs = await SharedPreferences.getInstance();
        final path = prefs.getString(kCustomAudioPathKey);
        if (path != null && await File(path).exists()) {
          await player.setReleaseMode(ReleaseMode.loop);
          await player.setVolume(boostVolume ? 1.0 : 0.85);
          await player.play(DeviceFileSource(path));
          return;
        }
      }

      final preset = defaultPresets.firstWhere(
        (p) => p.id == targetSound,
        orElse: () => defaultPresets.first,
      );

      final file = await getOrGenerateSoundFile(preset);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(boostVolume ? 1.0 : 0.85);
      await player.play(DeviceFileSource(file.path));
    } catch (_) {}
  }

  /// Stops the continuous alarm ringing and resets player
  Future<void> stopContinuousAlarm() async {
    _isContinuousAlarmRinging = false;
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.release);
    } catch (_) {}
  }

  Future<void> stopSound() async {
    try {
      await player.stop();
    } catch (_) {}
  }

  // --- Persistence Methods ---
  static const _kDefaultSoundKey = 'fit_host_alarm_default_sound';
  static const _kFullVolumeBoostKey = 'fit_host_alarm_volume_boost';
  static const _kVibrationPatternKey = 'fit_host_alarm_vibration';
  static const _kActivitySoundPrefix = 'fit_host_activity_sound_';

  Future<AlarmSoundSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultSound = prefs.getString(_kDefaultSoundKey) ?? 'cyber_chime';
    final fullVolume = prefs.getBool(_kFullVolumeBoostKey) ?? true;
    final vibration = prefs.getString(_kVibrationPatternKey) ?? 'standard';

    String? customPath = prefs.getString(kCustomAudioPathKey);
    String? customName = prefs.getString(kCustomAudioNameKey);
    if (customPath != null && !await File(customPath).exists()) {
      customPath = null;
      customName = null;
    }

    final activities = ['workout', 'hydration', 'nutrition', 'steps', 'diary', 'recovery'];
    final Map<String, String> activitySounds = {};

    for (final act in activities) {
      final saved = prefs.getString('$_kActivitySoundPrefix$act');
      if (saved != null) {
        activitySounds[act] = saved;
      } else {
        // Default mappings
        switch (act) {
          case 'workout':
            activitySounds[act] = 'titan_horn';
            break;
          case 'hydration':
            activitySounds[act] = 'zen_bell';
            break;
          case 'nutrition':
            activitySounds[act] = 'cyber_chime';
            break;
          case 'steps':
            activitySounds[act] = 'energy_uplift';
            break;
          case 'diary':
            activitySounds[act] = 'midnight_radar';
            break;
          case 'recovery':
            activitySounds[act] = 'zen_bell';
            break;
          default:
            activitySounds[act] = 'cyber_chime';
        }
      }
    }

    return AlarmSoundSettings(
      defaultSoundId: defaultSound,
      fullVolumeBoost: fullVolume,
      vibrationPattern: vibration,
      activitySounds: activitySounds,
      customAudioPath: customPath,
      customAudioName: customName,
    );
  }

  Future<void> saveSettings(AlarmSoundSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultSoundKey, settings.defaultSoundId);
    await prefs.setBool(_kFullVolumeBoostKey, settings.fullVolumeBoost);
    await prefs.setString(_kVibrationPatternKey, settings.vibrationPattern);

    if (settings.customAudioPath != null) {
      await prefs.setString(kCustomAudioPathKey, settings.customAudioPath!);
    } else {
      await prefs.remove(kCustomAudioPathKey);
    }

    if (settings.customAudioName != null) {
      await prefs.setString(kCustomAudioNameKey, settings.customAudioName!);
    } else {
      await prefs.remove(kCustomAudioNameKey);
    }

    for (final entry in settings.activitySounds.entries) {
      await prefs.setString('$_kActivitySoundPrefix${entry.key}', entry.value);
    }
  }
}

final alarmSoundServiceProvider = Provider<AlarmSoundService>((ref) {
  final service = AlarmSoundService();
  ref.onDispose(() => service.stopSound());
  return service;
});

final alarmSoundSettingsProvider =
    AsyncNotifierProvider<AlarmSoundSettingsNotifier, AlarmSoundSettings>(
  AlarmSoundSettingsNotifier.new,
);

class AlarmSoundSettingsNotifier extends AsyncNotifier<AlarmSoundSettings> {
  @override
  Future<AlarmSoundSettings> build() async {
    final service = ref.watch(alarmSoundServiceProvider);
    return service.loadSettings();
  }

  Future<void> setDefaultSound(String soundId) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(defaultSoundId: soundId);
    state = AsyncValue.data(updated);
    final service = ref.read(alarmSoundServiceProvider);
    await service.saveSettings(updated);
    await service.previewSound(soundId, boostVolume: updated.fullVolumeBoost);
  }

  Future<void> toggleVolumeBoost(bool val) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(fullVolumeBoost: val);
    state = AsyncValue.data(updated);
    final service = ref.read(alarmSoundServiceProvider);
    await service.saveSettings(updated);
  }

  Future<void> setVibrationPattern(String val) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(vibrationPattern: val);
    state = AsyncValue.data(updated);
    final service = ref.read(alarmSoundServiceProvider);
    await service.saveSettings(updated);
  }

  Future<void> setActivitySound(String activity, String soundId) async {
    final current = state.value;
    if (current == null) return;
    final map = Map<String, String>.from(current.activitySounds);
    map[activity] = soundId;
    final updated = current.copyWith(activitySounds: map);
    state = AsyncValue.data(updated);
    final service = ref.read(alarmSoundServiceProvider);
    await service.saveSettings(updated);
    await service.previewSound(soundId, boostVolume: updated.fullVolumeBoost);
  }

  Future<bool> pickCustomAudio() async {
    final service = ref.read(alarmSoundServiceProvider);
    final file = await service.pickAndSaveCustomAudio();
    if (file != null) {
      final current = state.value;
      if (current != null) {
        final prefs = await SharedPreferences.getInstance();
        final name = prefs.getString(AlarmSoundService.kCustomAudioNameKey) ?? 'Device Audio';
        final updated = current.copyWith(
          customAudioPath: file.path,
          customAudioName: name,
          defaultSoundId: AlarmSoundService.customSoundId,
        );
        state = AsyncValue.data(updated);
        await service.saveSettings(updated);
        await service.previewSound(AlarmSoundService.customSoundId, boostVolume: updated.fullVolumeBoost);
      }
      return true;
    }
    return false;
  }

  Future<void> removeCustomAudio() async {
    final service = ref.read(alarmSoundServiceProvider);
    await service.clearCustomAudio();
    final current = state.value;
    if (current != null) {
      final updated = current.copyWith(
        clearCustomAudio: true,
        defaultSoundId: current.defaultSoundId == AlarmSoundService.customSoundId
            ? 'cyber_chime'
            : current.defaultSoundId,
      );
      state = AsyncValue.data(updated);
      await service.saveSettings(updated);
    }
  }
}
