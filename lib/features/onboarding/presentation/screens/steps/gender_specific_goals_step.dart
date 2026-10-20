import 'package:flutter/material.dart';
import '../../../../profile/domain/models/profile_constants.dart';

class GenderSpecificGoalsStep extends StatelessWidget {
  final String? gender;
  final List<String> selectedGoals;
  final ValueChanged<String> onToggle;

  const GenderSpecificGoalsStep({
    super.key,
    required this.gender,
    required this.selectedGoals,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFemale = gender == 'female';
    final goals = isFemale ? kFemaleSpecificGoals : kMaleSpecificGoals;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What matters most to you?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll prioritize exercises that hit these target adaptations.",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 24),

          ...goals.map((goal) {
            final isSelected = selectedGoals.contains(goal);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => onToggle(goal),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00E676).withValues(alpha: 0.08)
                        : const Color(0xFF121A16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF00E676).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.04),
                        ),
                        child: Icon(
                          _getIconForGoal(goal),
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : const Color(0xFF8FA396),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          goal,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : const Color(0xFFF0F6F2),
                          ),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : const Color(0xFF8FA396).withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Color(0xFF0A0F0D),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getIconForGoal(String goal) {
    switch (goal) {
      case 'Upper chest development':
        return Icons.fitness_center_rounded;
      case 'Shoulder width':
        return Icons.crop_square_rounded;
      case 'Arm size':
        return Icons.sports_kabaddi_rounded;
      case 'Back thickness (V-taper)':
        return Icons.accessibility_new_rounded;
      case 'Leg power':
        return Icons.directions_run_rounded;
      case 'Core strength':
        return Icons.shield_rounded;
      case 'Glute development':
        return Icons.airline_seat_recline_extra_rounded;
      case 'Hip curves':
        return Icons.waves_rounded;
      case 'Waist definition':
        return Icons.hourglass_empty_rounded;
      case 'Toned arms':
        return Icons.fitness_center_rounded;
      case 'Thigh shaping':
        return Icons.directions_walk_rounded;
      case 'Full body toning':
      default:
        return Icons.star_border_rounded;
    }
  }
}
