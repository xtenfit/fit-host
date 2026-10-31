import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../../features/steps/domain/daily_step_record.dart';

class WeeklyStepsChart extends StatefulWidget {
  final List<DailyStepRecord> history;
  final int todaySteps;
  final int targetSteps;
  final bool isDark;

  const WeeklyStepsChart({
    super.key,
    required this.history,
    required this.todaySteps,
    this.targetSteps = 10000,
    required this.isDark,
  });

  @override
  State<WeeklyStepsChart> createState() => _WeeklyStepsChartState();
}

class _WeeklyStepsChartState extends State<WeeklyStepsChart> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build 7 consecutive days ending today
    final List<({DateTime date, int steps, bool isToday})> daysData = [];

    // Map history by date string 'YYYY-MM-DD'
    final Map<String, int> historyMap = {};
    for (final rec in widget.history) {
      final key = DateFormat('yyyy-MM-dd').format(rec.date);
      historyMap[key] = rec.steps;
    }

    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      final isToday = i == 0;
      final steps = isToday ? widget.todaySteps : (historyMap[key] ?? 0);
      daysData.add((date: d, steps: steps, isToday: isToday));
    }

    final maxSteps = daysData.fold<int>(
      widget.targetSteps,
      (max, d) => d.steps > max ? d.steps : max,
    );

    final total7DaySteps = daysData.fold<int>(0, (sum, d) => sum + d.steps);
    final avgDailySteps = (total7DaySteps / 7).round();

    final selectedItem =
        (_selectedDayIndex != null &&
            _selectedDayIndex! >= 0 &&
            _selectedDayIndex! < daysData.length)
        ? daysData[_selectedDayIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-Day Step Activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark
                          ? Colors.white
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Avg: ${NumberFormat('#,###').format(avgDailySteps)} steps/day',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              if (selectedItem != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.limeGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${DateFormat('E, MMM d').format(selectedItem.date)}: ${NumberFormat('#,###').format(selectedItem.steps)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.limeGreen,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.electricCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GOAL: ${widget.targetSteps ~/ 1000}k',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.electricCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Custom Paint Canvas for Bars + Target Line
          SizedBox(
            height: 140,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _handleTap(
                    details.localPosition,
                    constraints.maxWidth,
                    daysData.length,
                  ),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 140),
                    painter: _StepsBarPainter(
                      daysData: daysData,
                      maxSteps: maxSteps,
                      targetSteps: widget.targetSteps,
                      selectedIndex: _selectedDayIndex,
                      isDark: widget.isDark,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // X-Axis Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < daysData.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedDayIndex == i
                          ? AppColors.limeGreen.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      daysData[i].isToday
                          ? 'Today'
                          : DateFormat('E').format(daysData[i].date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            daysData[i].isToday || _selectedDayIndex == i
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _selectedDayIndex == i
                            ? AppColors.limeGreen
                            : (daysData[i].isToday
                                  ? AppColors.electricCyan
                                  : (widget.isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset localPos, double width, int count) {
    if (count == 0 || width <= 0) return;
    final slotWidth = width / count;
    final index = (localPos.dx / slotWidth).floor().clamp(0, count - 1);
    setState(() {
      _selectedDayIndex = _selectedDayIndex == index ? null : index;
    });
  }
}

class _StepsBarPainter extends CustomPainter {
  final List<({DateTime date, int steps, bool isToday})> daysData;
  final int maxSteps;
  final int targetSteps;
  final int? selectedIndex;
  final bool isDark;

  _StepsBarPainter({
    required this.daysData,
    required this.maxSteps,
    required this.targetSteps,
    required this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (daysData.isEmpty) return;

    final double effectiveMax = maxSteps > 0
        ? (maxSteps * 1.15).toDouble()
        : 10000.0;
    final int count = daysData.length;
    final double slotWidth = size.width / count;
    final double barWidth = math.min(slotWidth * 0.48, 24.0);

    // 1. Draw Target Goal Horizontal Dashed Line
    final double targetY =
        size.height - (targetSteps / effectiveMax * (size.height - 16)) - 8;

    final dashPaint = Paint()
      ..color = AppColors.electricCyan.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(math.min(startX + dashWidth, size.width), targetY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 2. Draw Bars
    for (int i = 0; i < count; i++) {
      final item = daysData[i];
      final double centerX = (i * slotWidth) + (slotWidth / 2);
      final double barLeft = centerX - (barWidth / 2);

      final double heightRatio = (item.steps / effectiveMax).clamp(0.02, 1.0);
      final double barHeight = heightRatio * (size.height - 16);
      final double barTop = size.height - barHeight - 4;

      final bool isMet = item.steps >= targetSteps;
      final bool isSelected = selectedIndex == i;

      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );

      // Background track
      final trackPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.05,
        );
      final trackRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, 4, barWidth, size.height - 8),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Fill Paint
      final Color baseColor = isMet
          ? AppColors.limeGreen
          : (item.isToday ? AppColors.electricCyan : const Color(0xFF64748B));

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [baseColor, baseColor.withValues(alpha: 0.65)],
        ).createShader(barRect.outerRect);

      canvas.drawRRect(barRect, barPaint);

      // Selection glow
      if (isSelected) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawRRect(barRect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StepsBarPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.daysData != daysData ||
        oldDelegate.maxSteps != maxSteps ||
        oldDelegate.targetSteps != targetSteps ||
        oldDelegate.isDark != isDark;
  }
}
