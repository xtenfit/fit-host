import 'package:flutter/material.dart';

class ExperienceStep extends StatelessWidget {
  final String selectedLevel;
  final ValueChanged<String> onSelected;

  const ExperienceStep({
    super.key,
    required this.selectedLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How experienced are you?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFF0F6F2),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "We'll set intensity, volume, and complexity accordingly.",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: Color(0xFF8FA396),
          ),
        ),
        const SizedBox(height: 28),

        _buildLevelCard(
          id: 'beginner',
          title: 'Beginner',
          description: 'New to training, or returning after a long break',
          icon: Icons.spa_rounded,
        ),
        const SizedBox(height: 14),
        _buildLevelCard(
          id: 'intermediate',
          title: 'Intermediate',
          description: 'Trained consistently for 6+ months',
          icon: Icons.directions_run_rounded,
        ),
        const SizedBox(height: 14),
        _buildLevelCard(
          id: 'advanced',
          title: 'Advanced',
          description: 'Years of structured training with progressive overload',
          icon: Icons.local_fire_department_rounded,
        ),
      ],
    );
  }

  Widget _buildLevelCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedLevel == id;

    return InkWell(
      onTap: () => onSelected(id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676).withValues(alpha: 0.08)
              : const Color(0xFF121A16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00E676).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF00E676)
                    : const Color(0xFF8FA396),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8FA396),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
