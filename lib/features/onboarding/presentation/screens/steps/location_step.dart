import 'package:flutter/material.dart';

class LocationStep extends StatelessWidget {
  final List<String> selectedLocations;
  final ValueChanged<String> onToggle;

  const LocationStep({
    super.key,
    required this.selectedLocations,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where do you train?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFF0F6F2),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select all that apply.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: Color(0xFF8FA396),
          ),
        ),
        const SizedBox(height: 28),

        _buildLocationCard(
          id: 'gym',
          title: 'Gym',
          subtitle: 'Commercial gym with full barbell & machine access',
          icon: Icons.fitness_center_rounded,
        ),
        const SizedBox(height: 14),
        _buildLocationCard(
          id: 'home',
          title: 'Home',
          subtitle: 'Living room, garage, or dedicated home setup',
          icon: Icons.home_rounded,
        ),
        const SizedBox(height: 14),
        _buildLocationCard(
          id: 'outdoors',
          title: 'Outdoors',
          subtitle: 'Parks, calisthenics parks, running trails',
          icon: Icons.park_rounded,
        ),
      ],
    );
  }

  Widget _buildLocationCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedLocations.contains(id);

    return InkWell(
      onTap: () => onToggle(id),
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
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8FA396),
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(id),
              activeColor: const Color(0xFF00E676),
              checkColor: const Color(0xFF0A0F0D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
