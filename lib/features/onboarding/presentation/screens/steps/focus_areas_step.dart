import 'package:flutter/material.dart';
import '../../../../profile/domain/models/profile_constants.dart';

class FocusAreasStep extends StatelessWidget {
  final List<String> selectedFocusAreas;
  final ValueChanged<String> onToggle;

  const FocusAreasStep({
    super.key,
    required this.selectedFocusAreas,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which areas to focus on?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that apply. Affects exercise selection.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 24),

          // Anatomy preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMuscleHighlightIcon(
                  label: 'Upper Body',
                  icon: Icons.accessibility_new_rounded,
                  isHighlighted: selectedFocusAreas.any((e) =>
                      ['Chest', 'Back', 'Arms', 'Shoulders', 'Full Body']
                          .contains(e)),
                ),
                const SizedBox(width: 32),
                _buildMuscleHighlightIcon(
                  label: 'Core & Abs',
                  icon: Icons.crop_portrait_rounded,
                  isHighlighted: selectedFocusAreas.any((e) =>
                      ['Abs/Core', 'Full Body', 'Flexibility'].contains(e)),
                ),
                const SizedBox(width: 32),
                _buildMuscleHighlightIcon(
                  label: 'Lower Body',
                  icon: Icons.directions_run_rounded,
                  isHighlighted: selectedFocusAreas.any((e) =>
                      ['Legs', 'Glutes', 'Full Body'].contains(e)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'TARGET MUSCLE GROUPS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: kFocusAreas.map((area) {
              final isSelected = selectedFocusAreas.contains(area) ||
                  (area == 'Full Body' && selectedFocusAreas.contains('full_body'));

              return FilterChip(
                label: Text(
                  area,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0A0F0D)
                        : const Color(0xFFF0F6F2),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onToggle(area),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMuscleHighlightIcon({
    required String label,
    required IconData icon,
    required bool isHighlighted,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isHighlighted
                ? const Color(0xFF00E676).withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.03),
            shape: BoxShape.circle,
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFF00E676)
                  : Colors.white.withValues(alpha: 0.08),
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 28,
            color: isHighlighted
                ? const Color(0xFF00E676)
                : const Color(0xFF8FA396),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: isHighlighted
                ? const Color(0xFF00E676)
                : const Color(0xFF8FA396),
          ),
        ),
      ],
    );
  }
}
