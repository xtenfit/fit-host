import 'package:flutter/material.dart';
import '../../../../profile/domain/models/profile_constants.dart';

class DietStep extends StatefulWidget {
  final String selectedDiet;
  final String allergies;
  final Function({String? diet, String? allergies}) onChanged;

  const DietStep({
    super.key,
    required this.selectedDiet,
    required this.allergies,
    required this.onChanged,
  });

  @override
  State<DietStep> createState() => _DietStepState();
}

class _DietStepState extends State<DietStep> {
  late TextEditingController _allergiesCtrl;

  @override
  void initState() {
    super.initState();
    _allergiesCtrl = TextEditingController(text: widget.allergies);
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How do you eat?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'For meal recommendations. You can change this anytime.',
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
            children: kDietTypes.map((diet) {
              final internalId = _mapToInternal(diet);
              final isSelected = widget.selectedDiet == internalId ||
                  widget.selectedDiet == diet.toLowerCase();

              return ChoiceChip(
                label: Text(diet),
                selected: isSelected,
                onSelected: (_) {
                  widget.onChanged(diet: internalId);
                },
                backgroundColor: const Color(0xFF121A16),
                selectedColor: const Color(0xFF00E676),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0A0F0D)
                      : const Color(0xFFF0F6F2),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF00E676)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          const Text(
            'ANY ALLERGIES OR RESTRICTIONS?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _allergiesCtrl,
            maxLines: 3,
            style: const TextStyle(
              color: Color(0xFFF0F6F2),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. lactose, gluten, nuts, shellfish...',
              hintStyle: TextStyle(
                color: const Color(0xFF8FA396).withValues(alpha: 0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFF121A16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF00E676)),
              ),
            ),
            onChanged: (val) {
              widget.onChanged(allergies: val.trim());
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _mapToInternal(String diet) {
    switch (diet) {
      case 'Vegetarian':
        return 'vegetarian';
      case 'Non-Veg':
        return 'non_vegetarian';
      case 'Eggetarian':
        return 'eggetarian';
      case 'Vegan':
        return 'vegan';
      case 'Pescatarian':
        return 'pescatarian';
      case 'Other':
      default:
        return 'other';
    }
  }
}
