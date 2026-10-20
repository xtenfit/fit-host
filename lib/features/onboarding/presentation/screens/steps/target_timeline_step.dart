import 'package:flutter/material.dart';

class TargetTimelineStep extends StatelessWidget {
  final double currentWeightKg;
  final double targetWeightKg;
  final int targetWeeks;
  final bool useMetricUnits;
  final Function({double? targetWeightKg, int? targetWeeks}) onChanged;

  const TargetTimelineStep({
    super.key,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.targetWeeks,
    required this.useMetricUnits,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final diffKg = (currentWeightKg - targetWeightKg).abs();
    final paceKgPerWeek = targetWeeks > 0
        ? double.parse((diffKg / targetWeeks).toStringAsFixed(2))
        : 0.5;

    // Pace categories:
    // < 0.25 -> Healthy (Green)
    // 0.25 - 0.5 -> Moderate (Yellow)
    // 0.5 - 0.75 -> Aggressive (Orange)
    // > 0.75 -> Not recommended (Red warning)
    Color paceColor;
    String paceLabel;
    String paceDescription;

    if (paceKgPerWeek < 0.25) {
      paceColor = const Color(0xFF00E676);
      paceLabel = 'Healthy & Sustainable';
      paceDescription = 'Gentle pace with high retention and minimal fatigue.';
    } else if (paceKgPerWeek <= 0.5) {
      paceColor = const Color(0xFFFFD54F);
      paceLabel = 'Moderate & Optimal';
      paceDescription = 'Balanced rate of progression with solid muscle preservation.';
    } else if (paceKgPerWeek <= 0.75) {
      paceColor = const Color(0xFFFF9800);
      paceLabel = 'Aggressive';
      paceDescription = 'Requires strict nutrition discipline and optimal recovery.';
    } else {
      paceColor = const Color(0xFFFF5252);
      paceLabel = 'Not Recommended';
      paceDescription = 'Overly aggressive pace risks muscle loss and metabolic slowdown.';
    }

    final displayWeight = useMetricUnits
        ? '${targetWeightKg.toStringAsFixed(1)} kg'
        : '${(targetWeightKg * 2.20462).toStringAsFixed(1)} lbs';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where do you want to be?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Set a target weight and timeline. We'll compute a realistic pace.",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 28),

          // Target Weight Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TARGET WEIGHT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF8FA396),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    displayWeight,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00E676),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: targetWeightKg.clamp(30.0, 200.0),
                    min: 30.0,
                    max: 200.0,
                    divisions: 340,
                    onChanged: (val) {
                      onChanged(
                        targetWeightKg: double.parse(val.toStringAsFixed(1)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Timeline Weeks Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TIMELINE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF8FA396),
                      ),
                    ),
                    Text(
                      '$targetWeeks weeks',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: targetWeeks.toDouble().clamp(4.0, 52.0),
                    min: 4.0,
                    max: 52.0,
                    divisions: 48,
                    onChanged: (val) {
                      onChanged(targetWeeks: val.round());
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('4 weeks', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                      Text('52 weeks (1 yr)', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live-computed Pace Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: paceColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: paceColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: paceColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    paceKgPerWeek > 0.75
                        ? Icons.warning_amber_rounded
                        : Icons.speed_rounded,
                    color: paceColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pace: $paceKgPerWeek kg/week',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: paceColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  $paceLabel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: paceColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paceDescription,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8FA396),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
