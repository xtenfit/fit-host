import 'package:flutter/material.dart';

class BasicsStep extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderSelected;

  const BasicsStep({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's your gender?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFF0F6F2),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Used only for BMR calculation and workout recommendations. You may skip this.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: Color(0xFF8FA396),
          ),
        ),
        const SizedBox(height: 28),
        _buildGenderCard(
          id: 'male',
          title: 'Male',
          description: 'Calculates standard male basal metabolic rate',
          icon: Icons.male_rounded,
        ),
        const SizedBox(height: 14),
        _buildGenderCard(
          id: 'female',
          title: 'Female',
          description: 'Calculates standard female basal metabolic rate',
          icon: Icons.female_rounded,
        ),
        const SizedBox(height: 14),
        _buildGenderCard(
          id: 'prefer_not_to_say',
          title: 'Prefer not to say',
          description: 'Uses gender-neutral metabolic estimates',
          icon: Icons.person_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedGender == id;

    return InkWell(
      onTap: () => onGenderSelected(id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676).withValues(alpha: 0.06)
              : const Color(0xFF121A16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E676)
                : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF00E676).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF00E676) : const Color(0xFF8FA396),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : const Color(0xFFF0F6F2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8FA396),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00E676)
                      : const Color(0xFF8FA396).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
