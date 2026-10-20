import 'package:flutter/material.dart';
import '../../../../profile/domain/models/profile_constants.dart';

class EquipmentStep extends StatelessWidget {
  final List<String> selectedEquipment;
  final ValueChanged<String> onToggle;

  const EquipmentStep({
    super.key,
    required this.selectedEquipment,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFullGym = selectedEquipment.any((e) =>
        e.toLowerCase() == 'full gym' || e.toLowerCase() == 'full_gym');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What equipment do you have?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll only suggest exercises you can actually do.",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 28),

          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: kAvailableEquipment.map((eq) {
              final isFullGymChip = eq == 'Full Gym';
              final isSelected = hasFullGym ||
                  selectedEquipment.contains(eq) ||
                  selectedEquipment.contains(eq.toLowerCase());

              return FilterChip(
                label: Text(
                  eq,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0A0F0D)
                        : const Color(0xFFF0F6F2),
                  ),
                ),
                selected: isSelected,
                onSelected: isFullGymChip
                    ? (_) => onToggle('Full Gym')
                    : (hasFullGym ? null : (_) => onToggle(eq)),
                backgroundColor: const Color(0xFF121A16),
                selectedColor: const Color(0xFF00E676),
                checkmarkColor: const Color(0xFF0A0F0D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF00E676)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          if (hasFullGym)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF00E676), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Full Gym selected: All equipment options unlocked for your programming.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFF0F6F2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
