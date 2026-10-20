import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable Voice Memo Player Widget
class VoiceMemoPlayerWidget extends StatefulWidget {
  final String audioPath;
  final int? totalDurationSeconds;
  final VoidCallback? onDelete;

  const VoiceMemoPlayerWidget({
    super.key,
    required this.audioPath,
    this.totalDurationSeconds,
    this.onDelete,
  });

  @override
  State<VoiceMemoPlayerWidget> createState() => _VoiceMemoPlayerWidgetState();
}

class _VoiceMemoPlayerWidgetState extends State<VoiceMemoPlayerWidget> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    if (widget.totalDurationSeconds != null) {
      _duration = Duration(seconds: widget.totalDurationSeconds!);
    }

    _posSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _durSub = _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      final file = File(widget.audioPath);
      if (await file.exists()) {
        await _player.play(DeviceFileSource(widget.audioPath));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file not found on device.')),
          );
        }
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2332) : const Color(0xFFEEF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: Colors.blueAccent,
              size: 34,
            ),
            onPressed: _togglePlay,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.mic_rounded, size: 14, color: Colors.blueAccent),
                        SizedBox(width: 4),
                        Text(
                          'Voice Memo Note',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Colors.blueAccent,
                    inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                    thumbColor: Colors.blueAccent,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: (val) {
                      final targetMs = (val * _duration.inMilliseconds).round();
                      _player.seek(Duration(milliseconds: targetMs));
                    },
                  ),
                ),
              ],
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              onPressed: widget.onDelete,
            ),
        ],
      ),
    );
  }
}

/// Voice Memo Recorder Dialog / Inline Component
class VoiceMemoRecorderWidget extends StatefulWidget {
  final Function(String path, int durationSeconds) onRecordingComplete;

  const VoiceMemoRecorderWidget({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<VoiceMemoRecorderWidget> createState() => _VoiceMemoRecorderWidgetState();
}

class _VoiceMemoRecorderWidgetState extends State<VoiceMemoRecorderWidget> {
  late final AudioRecorder _recorder;
  bool _isRecording = false;
  int _secondsRecorded = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required for voice notes.')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/diary_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _secondsRecorded = 0;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() => _secondsRecorded++);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path != null && _secondsRecorded > 0) {
        widget.onRecordingComplete(path, _secondsRecorded);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving voice note: $e')),
        );
      }
    }
  }

  String _formatTimer(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recording Voice Note...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                  Text(
                    'Elapsed: ${_formatTimer(_secondsRecorded)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('Stop & Attach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _startRecording,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      icon: const Icon(Icons.mic_rounded, color: Colors.blueAccent, size: 20),
      label: const Text(
        'Record Audio Voice Memo',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
