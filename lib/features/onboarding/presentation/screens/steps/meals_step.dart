import 'package:flutter/material.dart';
import '../../../domain/models/onboarding_models.dart';

class MealsStep extends StatelessWidget {
  final int mealsPerDay;
  final List<OnboardingMealSchedule> mealSchedules;
  final ValueChanged<int> onMealsCountChanged;
  final Function(int index, String name, String time) onUpdateMeal;
  final VoidCallback onAddCustomMeal;

  const MealsStep({
    super.key,
    required this.mealsPerDay,
    required this.mealSchedules,
    required this.onMealsCountChanged,
    required this.onUpdateMeal,
    required this.onAddCustomMeal,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How many meals per day?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll set up your nutrition diary to match.",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 24),

          // Chips 2..6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [2, 3, 4, 5, 6].map((count) {
              final isSelected = mealsPerDay == count;
              return ChoiceChip(
                label: Text('$count'),
                selected: isSelected,
                onSelected: (_) => onMealsCountChanged(count),
                selectedColor: const Color(0xFF00E676),
                backgroundColor: const Color(0xFF121A16),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0A0F0D)
                      : const Color(0xFFF0F6F2),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF00E676)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          const Text(
            'MEAL SCHEDULE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(mealSchedules.length, (idx) {
            final meal = mealSchedules[idx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121A16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getMealIcon(meal.name),
                      size: 20,
                      color: const Color(0xFF00E676),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF0F6F2),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 0),
                        );
                        if (time != null && context.mounted) {
                          onUpdateMeal(
                            idx,
                            meal.name,
                            time.format(context),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          meal.time,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00E676),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onAddCustomMeal,
            icon: const Icon(Icons.add_rounded, color: Color(0xFF00E676)),
            label: const Text(
              'Add custom meal slot',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _getMealIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('breakfast') || lower.contains('brunch')) {
      return Icons.wb_twilight_rounded;
    } else if (lower.contains('lunch') || lower.contains('noon')) {
      return Icons.wb_sunny_rounded;
    } else if (lower.contains('dinner')) {
      return Icons.nights_stay_rounded;
    }
    return Icons.restaurant_rounded;
  }
}
