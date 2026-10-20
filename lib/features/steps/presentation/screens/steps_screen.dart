import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';
import '../../../auth/presentation/dialogs/feature_upsell_sheet.dart';
import '../../data/step_permission_service.dart';
import '../../domain/daily_step_record.dart';
import '../../domain/step_calculator.dart';
import '../controllers/step_controller.dart';

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});

  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  @override
  void initState() {
    super.initState();
    // Deliverable A: Request permission on first entry to Steps screen (NOT at app launch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stepControllerProvider.notifier).requestPermissionsOnScreenEntry();
    });
  }

  void _showGoalEditorDialog(BuildContext context, int currentGoal) {
    int selectedGoal = currentGoal;
    final controller = TextEditingController(text: currentGoal.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F1A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark
                    ? AppColors.limeGreen.withValues(alpha: 0.2)
                    : Colors.black12,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daily Step Goal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set your daily movement target to stay healthy and active.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                // Quick chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [6000, 8000, 10000, 12000, 15000].map((val) {
                    final isSel = selectedGoal == val;
                    return ChoiceChip(
                      label: Text('${val ~/ 1000}k steps'),
                      selected: isSel,
                      selectedColor: AppColors.limeGreen,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : (isDark ? Colors.white : Colors.black87),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          selectedGoal = val;
                          controller.text = val.toString();
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Custom Step Target',
                    suffixText: 'steps',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      selectedGoal = parsed;
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      final parsed = int.tryParse(controller.text) ?? selectedGoal;
                      if (parsed > 0) {
                        ref.read(stepControllerProvider.notifier).updateGoal(parsed);
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Save Goal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualStepEntryDialog(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final parsed = int.tryParse(controller.text.trim()) ?? 0;
            final dist = StepCalculator.distanceKm(steps: parsed, strideCm: 72.6);
            final cal = StepCalculator.estimateCalories(parsed);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161F1A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? AppColors.limeGreen.withValues(alpha: 0.2) : Colors.black12,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Log Treadmill / Walk Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'Record real steps from an indoor walking pad, treadmill, or outdoor workout session.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Actual Step Count',
                        hintText: 'e.g. 3200',
                        prefixIcon: const Icon(Icons.directions_walk_rounded, color: AppColors.limeGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    if (parsed > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Estimated Distance: ${dist.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Burn: $cal kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.limeGreen)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.limeGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: parsed <= 0
                            ? null
                            : () {
                                ref.read(stepControllerProvider.notifier).addSimulatedSteps(parsed);
                                Navigator.pop(ctx);
                              },
                        child: const Text('Save Walk Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepState = ref.watch(stepControllerProvider);
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Step Counter & Distance',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Edit Step Goal',
            onPressed: () => _showGoalEditorDialog(context, stepState.targetSteps),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            // Date subtitle
            Text(
              todayFormatted,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Deliverable A: Inline Permission Card if permission is denied
            if (stepState.permissionState == StepPermissionState.denied ||
                stepState.permissionState == StepPermissionState.permanentlyDenied) ...[
              _PermissionWarningCard(isDark: isDark),
              const SizedBox(height: 16),
            ],

            // Deliverable D: Big Animated Circular Progress Ring
            _BigStepRingCard(
              steps: stepState.todaySteps,
              goal: stepState.targetSteps,
              progress: stepState.progressPercentage,
              isDark: isDark,
              onTapGoal: () => _showGoalEditorDialog(context, stepState.targetSteps),
            ),
            const SizedBox(height: 20),

            // Key Metrics Row: Distance, Active Minutes, Calories
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.straighten_rounded,
                    color: AppColors.electricCyan,
                    label: 'Distance',
                    value: stepState.formattedDistance,
                    subtitle: 'Computed',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.timer_outlined,
                    color: const Color(0xFFFFB703),
                    label: 'Active Time',
                    value: '${stepState.activeMinutes}m',
                    subtitle: 'Paced walking',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF5252),
                    label: 'Calories',
                    value: '${stepState.calories}',
                    subtitle: 'Active kcal',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stride & Distance Configuration Tile (Deliverable C)
            _StrideConfigTile(
              heightCm: profile.heightCm,
              strideCm: stepState.strideLengthCm,
              isRunning: stepState.isRunningStride,
              isDark: isDark,
              onToggleMode: (isRunning) {
                ref.read(stepControllerProvider.notifier).setStrideMode(
                      isRunning: isRunning,
                      heightCm: profile.heightCm,
                    );
              },
            ),
            const SizedBox(height: 24),

            // 7-Day Mini Bar Chart (Deliverable D)
            _SevenDayStepsChartCard(
              history: stepState.history,
              isGuest: stepState.isGuest,
              targetSteps: stepState.targetSteps,
              todaySteps: stepState.todaySteps,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Manual Walk / Treadmill Logging Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.limeGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual Treadmill / Walk Log',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          'Record indoor walking sessions and treadmill workouts',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showManualStepEntryDialog(context),
                    child: const Text('Log Walk', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionWarningCard extends ConsumerWidget {
  final bool isDark;
  const _PermissionWarningCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF332600),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB703), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB703), size: 22),
              SizedBox(width: 8),
              Text(
                'Activity Sensor Access Needed',
                style: TextStyle(
                  color: Color(0xFFFFB703),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Physical activity recognition is disabled. Step counting cannot update in real-time until sensor permission is enabled in device settings.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB703),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              onPressed: () {
                ref.read(stepPermissionProvider.notifier).openAppSettingsMenu();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStepRingCard extends StatelessWidget {
  final int steps;
  final int goal;
  final double progress;
  final bool isDark;
  final VoidCallback onTapGoal;

  const _BigStepRingCard({
    required this.steps,
    required this.goal,
    required this.progress,
    required this.isDark,
    required this.onTapGoal,
  });

  @override
  Widget build(BuildContext context) {
    final pctText = '${(progress * 100).toInt()}%';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF16231C), const Color(0xFF101914)]
              : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.limeGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _CircularStepRingPainter(
              progress: progress,
              trackColor: isDark ? const Color(0xFF263329) : Colors.black12,
              progressColor: AppColors.limeGreen,
            ),
            child: SizedBox(
              width: 220,
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: AppColors.limeGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat('#,###').format(steps),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  InkWell(
                    onTap: onTapGoal,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Goal: ${NumberFormat('#,###').format(goal)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_rounded, size: 12, color: AppColors.limeGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pctText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularStepRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _CircularStepRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.limeGreen, AppColors.electricCyan],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularStepRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrideConfigTile extends StatelessWidget {
  final double heightCm;
  final double strideCm;
  final bool isRunning;
  final bool isDark;
  final ValueChanged<bool> onToggleMode;

  const _StrideConfigTile({
    required this.heightCm,
    required this.strideCm,
    required this.isRunning,
    required this.isDark,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings_accessibility_rounded, color: AppColors.limeGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Stride Length & Pace',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Text(
                '${strideCm.toStringAsFixed(1)} cm / step',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.limeGreen, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated based on ${heightCm.toInt()} cm height (${isRunning ? 'running 0.45×' : 'walking 0.415×'}).',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Walking Stride'),
                  selected: !isRunning,
                  selectedColor: AppColors.limeGreen,
                  labelStyle: TextStyle(
                    color: !isRunning ? Colors.black : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) onToggleMode(false);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Running Stride'),
                  selected: isRunning,
                  selectedColor: AppColors.electricCyan,
                  labelStyle: TextStyle(
                    color: isRunning ? Colors.black : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) onToggleMode(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SevenDayStepsChartCard extends StatelessWidget {
  final List<DailyStepRecord> history;
  final bool isGuest;
  final int targetSteps;
  final int todaySteps;
  final bool isDark;

  const _SevenDayStepsChartCard({
    required this.history,
    required this.isGuest,
    required this.targetSteps,
    required this.todaySteps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 7 days ending today
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGuest
            ? () {
                FeatureUpsellSheet.show(
                  context,
                  title: 'Step History & Trends',
                  description:
                      'Track your 7-day movement trends, weekly step volume, and multi-week consistency with a free Fit Host account.',
                  icon: Icons.directions_walk_rounded,
                );
              }
            : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161F1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: AppColors.limeGreen, size: 22),
                      SizedBox(width: 8),
                      Text(
                        '7-Day Movement Trend',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  if (isGuest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Today Only',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    // Bars Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final isToday = index == 6;
                        final dayDate = days[index];

                        int stepsVal = 0;
                        if (isToday) {
                          stepsVal = todaySteps;
                        } else if (!isGuest) {
                          final match = history.where((r) =>
                            r.date.year == dayDate.year &&
                            r.date.month == dayDate.month &&
                            r.date.day == dayDate.day,
                          ).firstOrNull;
                          stepsVal = match?.steps ?? 0;
                        }

                        final heightRatio = (stepsVal / targetSteps).clamp(0.08, 1.0);

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              stepsVal > 0 ? '${(stepsVal / 1000).toStringAsFixed(1)}k' : '-',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isToday ? AppColors.limeGreen : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 22,
                              height: 90 * heightRatio,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.limeGreen
                                    : (isGuest
                                        ? (isDark ? Colors.white10 : Colors.black12)
                                        : AppColors.electricCyan.withValues(alpha: 0.6)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('E').format(dayDate),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                color: isToday
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                    // Deliverable D: Lock badge overlay for guests
                    if (isGuest)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2822) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded, size: 16, color: Colors.amber),
                                SizedBox(width: 6),
                                Text(
                                  'Sign in for 7-day trends & records',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
