import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../../features/workouts/domain/models/workout_models.dart';

class VolumeTrendChart extends StatefulWidget {
  final List<WorkoutEntity> workouts;
  final int days; // 7, 14, or 30 days
  final bool isDark;

  const VolumeTrendChart({
    super.key,
    required this.workouts,
    this.days = 14,
    required this.isDark,
  });

  @override
  State<VolumeTrendChart> createState() => _VolumeTrendChartState();
}

class _VolumeTrendChartState extends State<VolumeTrendChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    // 1. Group workouts by day for the last N days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: widget.days - 1));

    final Map<DateTime, double> dailyVolume = {};
    for (int i = 0; i < widget.days; i++) {
      final d = startDate.add(Duration(days: i));
      dailyVolume[d] = 0.0;
    }

    final completed = widget.workouts
        .where((w) => w.status == 'completed')
        .toList();

    for (final w in completed) {
      final wDate = DateTime(
        w.startedAt.year,
        w.startedAt.month,
        w.startedAt.day,
      );
      if (dailyVolume.containsKey(wDate)) {
        dailyVolume[wDate] = (dailyVolume[wDate] ?? 0.0) + w.totalVolumeKg;
      }
    }

    final sortedEntries = dailyVolume.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxVolume = sortedEntries.fold<double>(
      0.0,
      (max, e) => e.value > max ? e.value : max,
    );

    final totalPeriodVolume = sortedEntries.fold<double>(
      0.0,
      (sum, e) => sum + e.value,
    );

    final activeSessions = completed
        .where((w) => !w.startedAt.isBefore(startDate))
        .length;

    // Check if empty
    if (totalPeriodVolume == 0.0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDark
                ? AppColors.darkSurfaceBorder
                : AppColors.lightSurfaceBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.days}-Day Volume Curve',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'REAL-TIME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.show_chart_rounded,
              size: 44,
              color: widget.isDark
                  ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No completed workouts in the last ${widget.days} days',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete your scheduled routines to track training volume overload curves.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: widget.isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

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
                    '${widget.days}-Day Training Volume',
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
                    '${(totalPeriodVolume / 1000).toStringAsFixed(1)} tons across $activeSessions sessions',
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
              if (_selectedIndex != null &&
                  _selectedIndex! < sortedEntries.length)
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
                    '${DateFormat('MMM d').format(sortedEntries[_selectedIndex!].key)}: ${sortedEntries[_selectedIndex!].value.toInt()} kg',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Custom Paint Canvas
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (details) => _handleTouch(
                    details.localPosition,
                    constraints.maxWidth,
                    sortedEntries.length,
                  ),
                  onPanUpdate: (details) => _handleTouch(
                    details.localPosition,
                    constraints.maxWidth,
                    sortedEntries.length,
                  ),
                  onPanEnd: (_) => setState(() => _selectedIndex = null),
                  onPanCancel: () => setState(() => _selectedIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 150),
                    painter: _VolumePainter(
                      entries: sortedEntries,
                      maxVolume: maxVolume,
                      selectedIndex: _selectedIndex,
                      isDark: widget.isDark,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // X-Axis Date Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d').format(sortedEntries.first.key),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
              Text(
                'Peak: ${(maxVolume).toInt()} kg',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                DateFormat('MMM d').format(sortedEntries.last.key),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPos, double width, int count) {
    if (count <= 1 || width <= 0) return;
    final step = width / (count - 1);
    final index = (localPos.dx / step).round().clamp(0, count - 1);
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _VolumePainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> entries;
  final double maxVolume;
  final int? selectedIndex;
  final bool isDark;

  _VolumePainter({
    required this.entries,
    required this.maxVolume,
    required this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final double effectiveMax = maxVolume > 0 ? maxVolume * 1.15 : 100.0;
    final double stepX = entries.length > 1
        ? size.width / (entries.length - 1)
        : size.width;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> points = [];
    for (int i = 0; i < entries.length; i++) {
      final x = i * stepX;
      final val = entries[i].value;
      final y = size.height - (val / effectiveMax * (size.height - 12)) - 6;
      points.add(Offset(x, y));
    }

    // Build smooth bezier path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Fill gradient under curve
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.limeGreen.withValues(alpha: isDark ? 0.35 : 0.25),
          AppColors.limeGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke curve
    final strokePaint = Paint()
      ..color = AppColors.limeGreen
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Draw dots on workout days
    final dotPaint = Paint()..color = AppColors.limeGreen;
    final dotBorderPaint = Paint()
      ..color = isDark ? AppColors.darkBackground : Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      if (entries[i].value > 0) {
        canvas.drawCircle(points[i], 4, dotPaint);
        canvas.drawCircle(points[i], 4, dotBorderPaint);
      }
    }

    // Highlight selected index
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      final selectedPt = points[selectedIndex!];

      // Draw vertical indicator line
      final linePaint = Paint()
        ..color = AppColors.electricCyan.withValues(alpha: 0.7)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(selectedPt.dx, 0),
        Offset(selectedPt.dx, size.height),
        linePaint,
      );

      // Glowing dot
      final glowPaint = Paint()
        ..color = AppColors.electricCyan.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(selectedPt, 8, glowPaint);

      final indicatorPaint = Paint()..color = AppColors.electricCyan;
      canvas.drawCircle(selectedPt, 5, indicatorPaint);
      canvas.drawCircle(selectedPt, 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumePainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.entries != entries ||
        oldDelegate.maxVolume != maxVolume ||
        oldDelegate.isDark != isDark;
  }
}
