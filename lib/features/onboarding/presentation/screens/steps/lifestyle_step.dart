import 'package:flutter/material.dart';

class LifestyleStep extends StatelessWidget {
  final String activityLevel;
  final double sleepHours;
  final int workHours;
  final String stressLevel;
  final Function({
    String? activityLevel,
    double? sleepHours,
    int? workHours,
    String? stressLevel,
  }) onChanged;

  const LifestyleStep({
    super.key,
    required this.activityLevel,
    required this.sleepHours,
    required this.workHours,
    required this.stressLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One last thing',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps tune recovery, stress, and sleep guidance.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 28),

          // Activity Level
          const Text(
            'ACTIVITY LEVEL (OUTSIDE WORKOUTS)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Sedentary',
                id: 'sedentary',
                selectedId: activityLevel,
                onTap: () => onChanged(activityLevel: 'sedentary'),
              ),
              _buildChoiceChip(
                label: 'Light',
                id: 'lightly_active',
                selectedId: activityLevel,
                onTap: () => onChanged(activityLevel: 'lightly_active'),
              ),
              _buildChoiceChip(
                label: 'Moderate',
                id: 'moderately_active',
                selectedId: activityLevel,
                onTap: () => onChanged(activityLevel: 'moderately_active'),
              ),
              _buildChoiceChip(
                label: 'Active',
                id: 'very_active',
                selectedId: activityLevel,
                onTap: () => onChanged(activityLevel: 'very_active'),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // Sleep Hours Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AVERAGE SLEEP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF8FA396),
                      ),
                    ),
                    Text(
                      '${sleepHours.toStringAsFixed(1)} hrs / night',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: sleepHours.clamp(4.0, 10.0),
                    min: 4.0,
                    max: 10.0,
                    divisions: 12,
                    onChanged: (val) {
                      onChanged(sleepHours: double.parse(val.toStringAsFixed(1)));
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('4 hrs', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                      Text('10 hrs', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Daily Work Hours Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DAILY WORK HOURS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF8FA396),
                      ),
                    ),
                    Text(
                      '$workHours hrs / day',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: workHours.toDouble().clamp(0.0, 14.0),
                    min: 0.0,
                    max: 14.0,
                    divisions: 14,
                    onChanged: (val) {
                      onChanged(workHours: val.round());
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0 hrs', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                      Text('14 hrs', style: TextStyle(color: Color(0xFF8FA396), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stress Level
          const Text(
            'STRESS LEVEL',
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
              Expanded(
                child: _buildChoiceChip(
                  label: 'Low',
                  id: 'low',
                  selectedId: stressLevel,
                  onTap: () => onChanged(stressLevel: 'low'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceChip(
                  label: 'Medium',
                  id: 'moderate',
                  selectedId: stressLevel,
                  onTap: () => onChanged(stressLevel: 'moderate'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceChip(
                  label: 'High',
                  id: 'high',
                  selectedId: stressLevel,
                  onTap: () => onChanged(stressLevel: 'high'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String id,
    required String selectedId,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedId == id;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676)
              : const Color(0xFF121A16),
          borderRadius: BorderRadius.circular(12),
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
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF0A0F0D)
                  : const Color(0xFFF0F6F2),
            ),
          ),
        ),
      ),
    );
  }
}
