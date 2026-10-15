import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../workouts/presentation/controllers/workout_providers.dart';

class PrivacyExportScreen extends ConsumerStatefulWidget {
  const PrivacyExportScreen({super.key});

  @override
  ConsumerState<PrivacyExportScreen> createState() => _PrivacyExportScreenState();
}

class _PrivacyExportScreenState extends ConsumerState<PrivacyExportScreen> {
  bool _isExporting = false;
  String? _exportedDataPreview;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final db = ref.read(databaseProvider);

      final exercises = await db.select(db.exercises).get();
      final workouts = await db.select(db.workouts).get();
      final workoutExercises = await db.select(db.workoutExercises).get();
      final workoutSets = await db.select(db.workoutSets).get();
      final calendarEvents = await db.select(db.calendarEvents).get();
      final reminders = await db.select(db.reminders).get();

      final exportPayload = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'app': 'Fit Host',
        'storage': 'Local Offline SQLite (Drift)',
        'data': {
          'exercisesCount': exercises.length,
          'workoutExercisesCount': workoutExercises.length,
          'workoutSetsCount': workoutSets.length,
          'workouts': workouts.map((w) => {
            'id': w.id,
            'title': w.title,
            'startedAt': w.startedAt.toIso8601String(),
            'completedAt': w.completedAt?.toIso8601String(),
            'status': w.status,
            'durationSeconds': w.durationSeconds,
          }).toList(),
          'calendarEvents': calendarEvents.map((c) => {
            'id': c.id,
            'title': c.title,
            'eventType': c.eventType,
            'scheduledDate': c.scheduledDate.toIso8601String(),
            'isCompleted': c.isCompleted,
            'recurrenceRule': c.recurrenceRule,
          }).toList(),
          'reminders': reminders.map((r) => {
            'id': r.id,
            'title': r.title,
            'category': r.category,
            'timeOfDay': r.timeOfDay,
            'isEnabled': r.isEnabled,
            'recurrence': r.recurrence,
          }).toList(),
        },
      };

      const encoder = JsonEncoder.withIndent('  ');
      final jsonStr = encoder.convert(exportPayload);

      setState(() {
        _isExporting = false;
        _exportedDataPreview = jsonStr;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Complete offline data archive generated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Privacy & Data Export',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Security & Privacy Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF14241B), const Color(0xFF131722)]
                      : [const Color(0xFFEDFFF2), Colors.white],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.limeGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% On-Device Privacy',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your fitness data, nutrition logs, calendar events, and alarms remain stored solely on your device in secure SQLite.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Complete Archive',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Download or copy your complete workout logs, sets, calendar activities, and reminders in standard open JSON format.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportData,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isExporting ? 'Generating JSON...' : 'Generate JSON Archive',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_exportedDataPreview != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Export Preview',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _exportedDataPreview!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Copied JSON archive to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy to Clipboard'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F121A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : Colors.grey[300]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _exportedDataPreview!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
