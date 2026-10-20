import 'package:flutter/material.dart';

class YourBodyStep extends StatefulWidget {
  final double heightCm;
  final double weightKg;
  final bool useMetricUnits;
  final Function({double? heightCm, double? weightKg, bool? useMetricUnits}) onChanged;

  const YourBodyStep({
    super.key,
    required this.heightCm,
    required this.weightKg,
    required this.useMetricUnits,
    required this.onChanged,
  });

  @override
  State<YourBodyStep> createState() => _YourBodyStepState();
}

class _YourBodyStepState extends State<YourBodyStep> {
  late bool _useMetric;
  late double _heightCm;
  late double _weightKg;

  @override
  void initState() {
    super.initState();
    _useMetric = widget.useMetricUnits;
    _heightCm = widget.heightCm;
    _weightKg = widget.weightKg;
  }

  @override
  Widget build(BuildContext context) {
    final double weightLbs = _weightKg * 2.20462;
    final int feet = (_heightCm / 30.48).floor();
    final int inches = ((_heightCm / 2.54) - (feet * 12)).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Let's know your body",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Accurate metrics give accurate recommendations.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 28),

          // HEIGHT SECTION
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HEIGHT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF8FA396),
                      ),
                    ),
                    _buildToggle(
                      options: const ['cm', 'ft'],
                      selectedIndex: _useMetric ? 0 : 1,
                      onSelected: (idx) {
                        setState(() {
                          _useMetric = (idx == 0);
                        });
                        widget.onChanged(useMetricUnits: _useMetric);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _useMetric
                            ? '${_heightCm.round()}'
                            : '$feet\' $inches"',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00E676),
                        ),
                      ),
                      if (_useMetric) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'cm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8FA396),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _heightCm.clamp(120.0, 220.0),
                    min: 120.0,
                    max: 220.0,
                    divisions: 100,
                    onChanged: (val) {
                      setState(() {
                        _heightCm = val;
                      });
                      widget.onChanged(heightCm: _heightCm);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('120 cm', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                      Text('220 cm', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // WEIGHT SECTION
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WEIGHT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF8FA396),
                      ),
                    ),
                    _buildToggle(
                      options: const ['kg', 'lb'],
                      selectedIndex: _useMetric ? 0 : 1,
                      onSelected: (idx) {
                        setState(() {
                          _useMetric = (idx == 0);
                        });
                        widget.onChanged(useMetricUnits: _useMetric);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _useMetric
                            ? _weightKg.toStringAsFixed(1)
                            : weightLbs.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _useMetric ? 'kg' : 'lbs',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8FA396),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _weightKg.clamp(30.0, 200.0),
                    min: 30.0,
                    max: 200.0,
                    divisions: 340, // 0.5 step
                    onChanged: (val) {
                      setState(() {
                        _weightKg = double.parse(val.toStringAsFixed(1));
                      });
                      widget.onChanged(weightKg: _weightKg);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('30 kg', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                      Text('200 kg', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
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

  Widget _buildToggle({
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0D),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (idx) {
          final isSel = selectedIndex == idx;
          return GestureDetector(
            onTap: () => onSelected(idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF00E676) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                options[idx],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSel ? const Color(0xFF0A0F0D) : const Color(0xFF8FA396),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
