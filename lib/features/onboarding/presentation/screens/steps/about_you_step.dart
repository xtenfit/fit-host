import 'package:flutter/material.dart';

class AboutYouStep extends StatelessWidget {
  final int age;
  final ValueChanged<int> onAgeChanged;

  const AboutYouStep({
    super.key,
    required this.age,
    required this.onAgeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How old are you?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFF0F6F2),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Age helps tune recovery recommendations and intensity.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: Color(0xFF8FA396),
          ),
        ),
        const SizedBox(height: 48),

        // Big numeric display
        Center(
          child: Column(
            children: [
              Text(
                '$age',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00E676),
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'years old',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8FA396),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Stepper / quick controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoundButton(
              icon: Icons.remove_rounded,
              onPressed: age > 13 ? () => onAgeChanged(age - 1) : null,
            ),
            const SizedBox(width: 32),
            _buildRoundButton(
              icon: Icons.add_rounded,
              onPressed: age < 100 ? () => onAgeChanged(age + 1) : null,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Slider for quick scrub
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00E676),
            inactiveTrackColor: const Color(0xFF121A16),
            thumbColor: const Color(0xFF00E676),
            overlayColor: const Color(0xFF00E676).withValues(alpha: 0.15),
            trackHeight: 6,
          ),
          child: Slider(
            value: age.toDouble().clamp(13.0, 100.0),
            min: 13.0,
            max: 100.0,
            divisions: 87,
            onChanged: (val) => onAgeChanged(val.round()),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('13 yrs', style: TextStyle(color: Color(0xFF8FA396), fontSize: 12)),
              Text('100 yrs', style: TextStyle(color: Color(0xFF8FA396), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF121A16),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF00E676), size: 24),
        onPressed: onPressed,
      ),
    );
  }
}
