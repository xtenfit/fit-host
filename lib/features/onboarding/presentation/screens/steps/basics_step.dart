import 'package:flutter/material.dart';
import '../../widgets/animated_gender_selector.dart';

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
    return AnimatedGenderSelector(
      selectedGender: selectedGender,
      onGenderSelected: onGenderSelected,
      showPreferNotToSay: true,
      heading: "What's your gender?",
      subtitle: 'Used only for BMR calculation and workout recommendations.',
    );
  }
}
