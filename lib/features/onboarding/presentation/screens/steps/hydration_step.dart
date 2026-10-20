import 'package:flutter/material.dart';

class HydrationStep extends StatelessWidget {
  final int dailyWaterMl;
  final int reminderFrequencyHours;
  final String quietHoursStart;
  final String quietHoursEnd;
  final Function({
    int? dailyWaterMl,
    int? reminderFrequencyHours,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) onChanged;

  const HydrationStep({
    super.key,
    required this.dailyWaterMl,
    required this.reminderFrequencyHours,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final liters = (dailyWaterMl / 1000.0).toStringAsFixed(1);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Water target',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stay on top of hydration for recovery and performance.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 32),

          // Big Value Display
          Center(
            child: Column(
              children: [
                Text(
                  '$liters L',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00E676),
                  ),
                ),
                Text(
                  '($dailyWaterMl ml / day)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8FA396),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Slider 1.0 to 5.0 L
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00E676),
              inactiveTrackColor: const Color(0xFF121A16),
              thumbColor: const Color(0xFF00E676),
              trackHeight: 6,
            ),
            child: Slider(
              value: (dailyWaterMl / 1000.0).clamp(1.0, 5.0),
              min: 1.0,
              max: 5.0,
              divisions: 40,
              onChanged: (val) {
                final ml = (val * 1000).round();
                onChanged(dailyWaterMl: ml);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1.0 L',
                    style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                Text('5.0 L',
                    style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Reminder Frequency
          const Text(
            'REMINDER FREQUENCY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildFreqChip(
                label: '1 hour',
                hours: 1,
                isSelected: reminderFrequencyHours == 1,
              ),
              const SizedBox(width: 8),
              _buildFreqChip(
                label: '2 hours',
                hours: 2,
                isSelected: reminderFrequencyHours == 2,
              ),
              const SizedBox(width: 8),
              _buildFreqChip(
                label: '3 hours',
                hours: 3,
                isSelected: reminderFrequencyHours == 3,
              ),
              const SizedBox(width: 8),
              _buildFreqChip(
                label: 'Off',
                hours: 0,
                isSelected: reminderFrequencyHours == 0,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Quiet Hours Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUIET HOURS (NO ALERTS)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF8FA396),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nightlight_round,
                            size: 18, color: Color(0xFF00E676)),
                        const SizedBox(width: 8),
                        Text(
                          'From $quietHoursStart',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF0F6F2),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Color(0xFF8FA396)),
                    Text(
                      'To $quietHoursEnd',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF0F6F2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFreqChip({
    required String label,
    required int hours,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(reminderFrequencyHours: hours),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E676)
                : const Color(0xFF121A16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0A0F0D)
                    : const Color(0xFFF0F6F2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
