import 'package:flutter/material.dart';

class MainGoalStep extends StatelessWidget {
  final List<String> selectedGoals;
  final ValueChanged<String> onGoalSelected;

  const MainGoalStep({
    super.key,
    required this.selectedGoals,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's your main goal?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFF0F6F2),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "We'll tailor your plan around this.",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: Color(0xFF8FA396),
          ),
        ),
        const SizedBox(height: 28),

        // 2x2 Grid of large cards
        Row(
          children: [
            Expanded(
              child: _buildGoalCard(
                id: 'lose_weight',
                title: 'Lose Weight',
                subtitle: 'Reduce body fat while preserving muscle',
                icon: Icons.track_changes_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGoalCard(
                id: 'build_muscle',
                title: 'Build Muscle',
                subtitle: 'Increase lean mass with progressive overload',
                icon: Icons.fitness_center_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildGoalCard(
                id: 'recomp',
                title: 'Recomp',
                subtitle: 'Lose fat and build muscle simultaneously',
                icon: Icons.balance_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGoalCard(
                id: 'maintain',
                title: 'Maintain',
                subtitle: 'Keep current physique and fitness level',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedGoals.contains(id) ||
        (id == 'maintain' && selectedGoals.contains('maintain_weight'));

    return InkWell(
      onTap: () => onGoalSelected(id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676).withValues(alpha: 0.08)
              : const Color(0xFF121A16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00E676).withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF00E676)
                    : const Color(0xFF8FA396),
                size: 26,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF00E676)
                        : const Color(0xFFF0F6F2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8FA396),
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
