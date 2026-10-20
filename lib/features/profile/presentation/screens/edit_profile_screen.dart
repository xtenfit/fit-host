import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import '../controllers/user_profile_controller.dart';
import '../widgets/avatar_picker_sheet.dart';
import '../../domain/models/profile_constants.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

  late String _selectedGender;
  late String _selectedGoal;
  late String _selectedDiet;
  late bool _useMetricUnits;
  late String _avatarId;
  late Set<String> _selectedFocusAreas;

  bool _isSaving = false;

  final List<String> _goalOptions = kFitnessGoals;

  final List<Map<String, String>> _dietOptions = [
    {'value': 'balanced', 'label': 'Balanced'},
    {'value': 'high_protein', 'label': 'High Protein'},
    {'value': 'low_carb', 'label': 'Low Carb'},
    {'value': 'vegetarian', 'label': 'Vegetarian'},
    {'value': 'vegan', 'label': 'Vegan'},
    {'value': 'mediterranean', 'label': 'Mediterranean'},
  ];

  final List<String> _focusAreaOptions = kFocusAreas;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);

    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: '${profile.age}');
    _useMetricUnits = profile.useMetricUnits;

    final displayHeight = _useMetricUnits
        ? profile.heightCm.toInt().toString()
        : (profile.heightCm / 30.48).toStringAsFixed(1);
    final displayWeight = _useMetricUnits
        ? profile.weightKg.toInt().toString()
        : (profile.weightKg * 2.20462).toStringAsFixed(1);
    final displayTargetWeight = profile.targetWeightKg != null
        ? (_useMetricUnits
            ? profile.targetWeightKg!.toInt().toString()
            : (profile.targetWeightKg! * 2.20462).toStringAsFixed(1))
        : '';

    _heightController = TextEditingController(text: displayHeight);
    _weightController = TextEditingController(text: displayWeight);
    _targetWeightController = TextEditingController(text: displayTargetWeight);

    _selectedGender = profile.gender;
    _selectedGoal = profile.fitnessGoal;
    _selectedDiet = profile.dietType;
    _avatarId = profile.avatarId;
    _selectedFocusAreas = Set<String>.from(profile.focusAreas);
    if (_selectedFocusAreas.isEmpty) {
      _selectedFocusAreas.add('Full Body');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _onUnitsToggled(bool metric) {
    if (_useMetricUnits == metric) return;

    final hVal = double.tryParse(_heightController.text) ?? 175.0;
    final wVal = double.tryParse(_weightController.text) ?? 70.0;
    final twVal = double.tryParse(_targetWeightController.text);

    setState(() {
      _useMetricUnits = metric;
      if (metric) {
        // Imperial -> Metric
        _heightController.text = (hVal * 30.48).round().toString();
        _weightController.text = (wVal / 2.20462).round().toString();
        if (twVal != null) {
          _targetWeightController.text = (twVal / 2.20462).round().toString();
        }
      } else {
        // Metric -> Imperial
        _heightController.text = (hVal / 30.48).toStringAsFixed(1);
        _weightController.text = (wVal * 2.20462).round().toString();
        if (twVal != null) {
          _targetWeightController.text = (twVal * 2.20462).round().toString();
        }
      }
    });
  }

  Future<void> _pickAvatar() async {
    final picked = await showPhotoOrAvatarPicker(
      context,
      currentAvatarId: _avatarId,
      userGender: _selectedGender,
      userName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Athlete',
    );
    if (picked != null && mounted) {
      setState(() => _avatarId = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final current = ref.read(userProfileProvider);
      final age = int.tryParse(_ageController.text.trim()) ?? current.age;

      double heightCm;
      double weightKg;
      double? targetWeightKg;

      final parsedHeight = double.tryParse(_heightController.text.trim()) ?? 175.0;
      final parsedWeight = double.tryParse(_weightController.text.trim()) ?? 70.0;
      final parsedTargetWeight = double.tryParse(_targetWeightController.text.trim());

      if (_useMetricUnits) {
        heightCm = parsedHeight;
        weightKg = parsedWeight;
        targetWeightKg = parsedTargetWeight;
      } else {
        heightCm = parsedHeight * 30.48;
        weightKg = parsedWeight / 2.20462;
        targetWeightKg = parsedTargetWeight != null ? (parsedTargetWeight / 2.20462) : null;
      }

      final updated = current.copyWith(
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Athlete',
        gender: _selectedGender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        targetWeightKg: targetWeightKg,
        useMetricUnits: _useMetricUnits,
        fitnessGoal: _selectedGoal,
        dietType: _selectedDiet,
        avatarId: _avatarId,
        focusAreas: _selectedFocusAreas.toList(),
        updatedAt: DateTime.now(),
      );

      // Saves through ProfileRepository (Local for guest, Cloud for authed)
      await ref.read(userProfileProvider.notifier).updateProfile(updated);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.limeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.warmCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.limeGreen),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.limeGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AppAvatar(
                          avatarId: _avatarId,
                          name: _nameController.text,
                          radius: 46,
                          borderColor: AppColors.limeGreen,
                          borderWidth: 3,
                          onTap: _pickAvatar,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppColors.limeGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickAvatar,
                      child: const Text(
                        'Change Avatar',
                        style: TextStyle(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Storage Mode Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      authState.isAuthenticated ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
                      size: 20,
                      color: authState.isAuthenticated ? AppColors.electricCyan : AppColors.limeGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        authState.isAuthenticated
                            ? 'Cloud Sync Mode (Synced to Supabase Profile)'
                            : 'Guest Local Mode (Stored Securely on Device)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Athlete Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 14),

              // Gender Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRadioChip('Male', 'male', _selectedGender, (val) {
                        setState(() {
                          _selectedGender = val;
                          // If current avatar is female and gender changed to male, reset or adapt
                          if (_avatarId.contains('female')) {
                            _avatarId = 'avatar_male_1';
                          }
                        });
                      }),
                      const SizedBox(width: 10),
                      _buildRadioChip('Female', 'female', _selectedGender, (val) {
                        setState(() {
                          _selectedGender = val;
                          if (_avatarId.contains('male')) {
                            _avatarId = 'avatar_female_1';
                          }
                        });
                      }),
                      const SizedBox(width: 10),
                      _buildRadioChip('Other', 'other', _selectedGender, (val) {
                        setState(() => _selectedGender = val);
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ageController,
                label: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 12 || n > 110) return 'Enter a valid age (12-110)';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Units & Physical Metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Physical Metrics'),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Metric', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: _useMetricUnits,
                        onSelected: (s) {
                          if (s) _onUnitsToggled(true);
                        },
                        selectedColor: AppColors.limeGreen,
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Imperial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        selected: !_useMetricUnits,
                        onSelected: (s) {
                          if (s) _onUnitsToggled(false);
                        },
                        selectedColor: AppColors.limeGreen,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: _useMetricUnits ? 'Height (cm)' : 'Height (ft)',
                      icon: Icons.height_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: _useMetricUnits ? 'Weight (kg)' : 'Weight (lbs)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _targetWeightController,
                label: _useMetricUnits ? 'Target Weight (kg, optional)' : 'Target Weight (lbs, optional)',
                icon: Icons.flag_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),

              // Fitness Goal
              _buildSectionTitle('Fitness Goal'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goalOptions.map((goal) {
                  final isSelected = _selectedGoal.toLowerCase().replaceAll('_', ' ') ==
                          goal.toLowerCase().replaceAll('_', ' ') ||
                      _selectedGoal == goal;
                  return ChoiceChip(
                    label: Text(goal),
                    selected: isSelected,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedGoal = goal);
                    },
                    selectedColor: AppColors.electricBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Focus Areas
              _buildSectionTitle('Priority Focus Areas'),
              const SizedBox(height: 6),
              Text(
                'Select the muscle groups you want emphasized in recommendations.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _focusAreaOptions.map((area) {
                  final isSelected = _selectedFocusAreas.any((a) =>
                      a.toLowerCase().replaceAll('_', ' ') ==
                          area.toLowerCase().replaceAll('_', ' ') ||
                      a == area);
                  return FilterChip(
                    label: Text(area),
                    selected: isSelected,
                    onSelected: (sel) {
                      setState(() {
                        if (area == 'Full Body') {
                          _selectedFocusAreas.clear();
                          _selectedFocusAreas.add('Full Body');
                        } else {
                          _selectedFocusAreas.removeWhere((a) =>
                              a.toLowerCase().replaceAll('_', ' ') == 'full body');
                          if (sel) {
                            _selectedFocusAreas.add(area);
                          } else {
                            _selectedFocusAreas.removeWhere((a) =>
                                a.toLowerCase().replaceAll('_', ' ') ==
                                    area.toLowerCase().replaceAll('_', ' ') ||
                                a == area);
                          }
                          if (_selectedFocusAreas.isEmpty) {
                            _selectedFocusAreas.add('Full Body');
                          }
                        }
                      });
                    },
                    selectedColor: AppColors.limeGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.limeGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.limeGreen : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Diet Type
              _buildSectionTitle('Dietary Routine'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dietOptions.map((diet) {
                  final isSelected = _selectedDiet == diet['value'];
                  return ChoiceChip(
                    label: Text(diet['label']!),
                    selected: isSelected,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedDiet = diet['value']!);
                    },
                    selectedColor: AppColors.electricCyan.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.electricCyan : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                        )
                      : const Text(
                          'Save Profile Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildRadioChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = value == selectedValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.limeGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.limeGreen : Colors.grey.shade700,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.black : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.limeGreen, width: 2),
        ),
      ),
    );
  }
}
