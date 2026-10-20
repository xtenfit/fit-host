import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_profile.dart';
import '../controllers/user_profile_controller.dart';
import '../widgets/avatar_picker_sheet.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;

  const ProfileSetupScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0; // 0: Name/Gender, 1: Body Metrics, 2: Goal, 3: Diet, 4: Calorie/Macros, 5: Workout Target
  final int _totalSteps = 6;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

  // Custom Macro controllers
  late TextEditingController _customCaloriesController;
  late TextEditingController _customProteinController;
  late TextEditingController _customCarbsController;
  late TextEditingController _customFatsController;
  late TextEditingController _customWorkoutTargetController;

  late String _gender;
  late bool _useMetricUnits;
  late String _fitnessGoal;
  late String _dietType;
  late String _targetMode; // 'suggested' or 'custom'
  late int _weeklyWorkoutDays;
  late int _dailyWorkoutMinutes;
  late String _activityLevel;
  late String _experienceLevel;
  late double _targetPaceKgPerWeek;
  late String _fastingProtocol;
  late int _dailyStepsGoal;
  late double _targetSleepHours;
  late String _avatarId;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);

    _nameController = TextEditingController(text: profile.name == 'Guest Athlete' && widget.isInitialSetup ? '' : profile.name);
    _ageController = TextEditingController(text: '${profile.age}');
    _gender = profile.gender;
    _useMetricUnits = profile.useMetricUnits;
    _avatarId = profile.avatarId;
    if (_avatarId.isEmpty || _avatarId == 'initial') {
      _avatarId = profile.gender == 'female' ? 'avatar_female_1' : 'avatar_male_1';
    }

    _heightController = TextEditingController(
      text: _useMetricUnits ? '${profile.heightCm.toInt()}' : profile.heightInFeet.toStringAsFixed(1),
    );
    _weightController = TextEditingController(
      text: _useMetricUnits ? '${profile.weightKg.toInt()}' : profile.weightInLbs.toStringAsFixed(1),
    );
    _targetWeightController = TextEditingController(
      text: profile.targetWeightKg != null
          ? (_useMetricUnits ? '${profile.targetWeightKg!.toInt()}' : profile.targetWeightInLbs!.toStringAsFixed(1))
          : '',
    );

    _fitnessGoal = profile.fitnessGoal;
    _dietType = profile.dietType;
    _targetMode = profile.targetMode;

    _customCaloriesController = TextEditingController(text: '${profile.dailyCaloriesTarget}');
    _customProteinController = TextEditingController(text: '${profile.targetProteinGrams}');
    _customCarbsController = TextEditingController(text: '${profile.targetCarbsGrams}');
    _customFatsController = TextEditingController(text: '${profile.targetFatsGrams}');
    _customWorkoutTargetController = TextEditingController(text: profile.customTargetNote ?? '');

    _weeklyWorkoutDays = profile.weeklyWorkoutDays;
    _dailyWorkoutMinutes = profile.dailyWorkoutMinutes;
    _activityLevel = profile.activityLevel;
    _experienceLevel = profile.experienceLevel;
    _targetPaceKgPerWeek = profile.targetPaceKgPerWeek;
    _fastingProtocol = profile.fastingProtocol;
    _dailyStepsGoal = profile.dailyStepsGoal;
    _targetSleepHours = profile.targetSleepHours;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _customCaloriesController.dispose();
    _customProteinController.dispose();
    _customCarbsController.dispose();
    _customFatsController.dispose();
    _customWorkoutTargetController.dispose();
    super.dispose();
  }

  // Calculate live suggested targets preview
  UserProfile _getLivePreviewProfile() {
    final age = int.tryParse(_ageController.text.trim()) ?? 26;
    double height = double.tryParse(_heightController.text.trim()) ?? 175.0;
    if (!_useMetricUnits) {
      height = height * 30.48; // ft to cm
    }
    double weight = double.tryParse(_weightController.text.trim()) ?? 72.0;
    if (!_useMetricUnits) {
      weight = weight / 2.20462; // lbs to kg
    }
    double? targetWeight = double.tryParse(_targetWeightController.text.trim());
    if (targetWeight != null && !_useMetricUnits) {
      targetWeight = targetWeight / 2.20462;
    }

    return UserProfile.calculateSuggestedTargets(
      name: _nameController.text.trim(),
      age: age,
      gender: _gender,
      heightCm: height,
      weightKg: weight,
      targetWeightKg: targetWeight,
      useMetricUnits: _useMetricUnits,
      fitnessGoal: _fitnessGoal,
      dietType: _dietType,
      weeklyWorkoutDays: _weeklyWorkoutDays,
      dailyWorkoutMinutes: _dailyWorkoutMinutes,
      customTargetNote: _customWorkoutTargetController.text.trim(),
      activityLevel: _activityLevel,
      experienceLevel: _experienceLevel,
      targetPaceKgPerWeek: _targetPaceKgPerWeek,
      fastingProtocol: _fastingProtocol,
      dailyStepsGoal: _dailyStepsGoal,
      targetSleepHours: _targetSleepHours,
    );
  }

  Future<void> _saveAndFinish() async {
    final preview = _getLivePreviewProfile();

    if (_targetMode == 'custom') {
      final customCal = int.tryParse(_customCaloriesController.text.trim()) ?? preview.dailyCaloriesTarget;
      final customProt = int.tryParse(_customProteinController.text.trim()) ?? preview.targetProteinGrams;
      final customCarb = int.tryParse(_customCarbsController.text.trim()) ?? preview.targetCarbsGrams;
      final customFat = int.tryParse(_customFatsController.text.trim()) ?? preview.targetFatsGrams;

      final updated = preview.copyWith(
        targetMode: 'custom',
        dailyCaloriesTarget: customCal.clamp(1000, 6000),
        targetProteinGrams: customProt.clamp(30, 400),
        targetCarbsGrams: customCarb.clamp(20, 600),
        targetFatsGrams: customFat.clamp(15, 200),
        avatarId: _avatarId,
        activityLevel: _activityLevel,
        experienceLevel: _experienceLevel,
        targetPaceKgPerWeek: _targetPaceKgPerWeek,
        fastingProtocol: _fastingProtocol,
        dailyStepsGoal: _dailyStepsGoal,
        targetSleepHours: _targetSleepHours,
      );
      await ref.read(userProfileProvider.notifier).updateProfile(updated);
    } else {
      await ref.read(userProfileProvider.notifier).updateProfile(preview.copyWith(avatarId: _avatarId));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isInitialSetup
                ? 'Welcome to Fit Host, ${preview.name}!'
                : 'Fitness profile and real targets updated!',
          ),
          backgroundColor: AppColors.limeGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await showPhotoOrAvatarPicker(
      context,
      currentAvatarId: _avatarId,
      userGender: _gender,
      userName: _nameController.text.trim().isEmpty ? 'Athlete' : _nameController.text.trim(),
    );
    if (picked != null) {
      setState(() => _avatarId = picked);
    }
  }

  Future<void> _saveInitialSetup() async {
    final current = ref.read(userProfileProvider);
    final name = _nameController.text.trim().isEmpty ? 'Athlete' : _nameController.text.trim();
    final updated = current.copyWith(
      name: name,
      avatarId: _avatarId,
      isProfileSetupCompleted: true,
    );
    await ref.read(userProfileProvider.notifier).updateProfile(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome to Fit Host, $name!'),
          backgroundColor: AppColors.limeGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }
  }

  Widget _buildInitialSetup(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Personalize your athlete profile and avatar to get started.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              AppAvatar(
                avatarId: _avatarId,
                name: _nameController.text.trim().isEmpty ? 'Athlete' : _nameController.text.trim(),
                radius: 56,
                borderWidth: 3,
                borderColor: AppColors.limeGreen,
                onTap: _pickAvatar,
              ),
              GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.limeGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _pickAvatar,
          icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppColors.limeGreen),
          label: const Text(
            'Change Avatar',
            style: TextStyle(color: AppColors.limeGreen, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'What should we call you?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Athlete Name',
            hintText: 'e.g. Alex, Jordan, Sam',
            prefixIcon: const Icon(Icons.person_rounded),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveInitialSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Complete Setup & Start',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.isInitialSetup) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Complete Your Profile'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: _saveInitialSetup,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildInitialSetup(isDark),
          ),
        ),
      );
    }

    final livePreview = _getLivePreviewProfile();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Profile Setup' : 'Edit Profile & Targets'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: _saveAndFinish,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF $_totalSteps',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.limeGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _getStepTitle(_currentStep),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.limeGreen),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(isDark, livePreview),
              ),
            ),

            // Navigation Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < _totalSteps - 1) {
                          setState(() => _currentStep++);
                        } else {
                          _saveAndFinish();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _currentStep < _totalSteps - 1 ? 'Continue' : 'Activate Plan & Save',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
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

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'Body Metrics';
      case 2:
        return 'Fitness Goal';
      case 3:
        return 'Diet Preference';
      case 4:
        return 'Nutrition Targets';
      case 5:
        return 'Workout Schedule';
      default:
        return '';
    }
  }

  Widget _buildStepContent(bool isDark, UserProfile livePreview) {
    switch (_currentStep) {
      case 0:
        return _buildStepPersonalInfo(isDark);
      case 1:
        return _buildStepBodyMetrics(isDark);
      case 2:
        return _buildStepFitnessGoal(isDark);
      case 3:
        return _buildStepDietPreference(isDark);
      case 4:
        return _buildStepNutritionTargets(isDark, livePreview);
      case 5:
        return _buildStepWorkoutTargets(isDark, livePreview);
      default:
        return const SizedBox();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 0: NAME & GENDER
  // ---------------------------------------------------------------------------
  Widget _buildStepPersonalInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What should we call you?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Personalize your workout logs, progressive overload, and daily fitness diary.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Athlete Name',
            hintText: 'e.g. Alex, Jordan, Sam',
            prefixIcon: const Icon(Icons.person_rounded),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),
        const Text(
          'Gender',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Used to compute accurate basal metabolic rate (BMR) and caloric needs.',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionCard(
              title: 'Male',
              icon: Icons.male_rounded,
              isSelected: _gender == 'male',
              onTap: () => setState(() => _gender = 'male'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildSelectionCard(
              title: 'Female',
              icon: Icons.female_rounded,
              isSelected: _gender == 'female',
              onTap: () => setState(() => _gender = 'female'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildSelectionCard(
              title: 'Other',
              icon: Icons.transgender_rounded,
              isSelected: _gender == 'other',
              onTap: () => setState(() => _gender = 'other'),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Training Experience Level',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Helps determine volume and progression intensity.',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionCard(
              title: 'Beginner',
              icon: Icons.fitness_center_rounded,
              isSelected: _experienceLevel == 'beginner',
              onTap: () => setState(() => _experienceLevel = 'beginner'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildSelectionCard(
              title: 'Intermediate',
              icon: Icons.sports_gymnastics_rounded,
              isSelected: _experienceLevel == 'intermediate',
              onTap: () => setState(() => _experienceLevel = 'intermediate'),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildSelectionCard(
              title: 'Advanced',
              icon: Icons.military_tech_rounded,
              isSelected: _experienceLevel == 'advanced',
              onTap: () => setState(() => _experienceLevel = 'advanced'),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: BODY METRICS
  // ---------------------------------------------------------------------------
  Widget _buildStepBodyMetrics(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Body Stats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            // Units Toggle
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildUnitChip('Metric (kg/cm)', _useMetricUnits, () {
                    if (!_useMetricUnits) {
                      setState(() {
                        _useMetricUnits = true;
                        final ft = double.tryParse(_heightController.text) ?? 5.7;
                        _heightController.text = '${(ft * 30.48).round()}';
                        final lbs = double.tryParse(_weightController.text) ?? 158.0;
                        _weightController.text = '${(lbs / 2.20462).round()}';
                        if (_targetWeightController.text.isNotEmpty) {
                          final tLbs = double.tryParse(_targetWeightController.text) ?? 154.0;
                          _targetWeightController.text = '${(tLbs / 2.20462).round()}';
                        }
                      });
                    }
                  }),
                  _buildUnitChip('Imperial (lbs/ft)', !_useMetricUnits, () {
                    if (_useMetricUnits) {
                      setState(() {
                        _useMetricUnits = false;
                        final cm = double.tryParse(_heightController.text) ?? 175.0;
                        _heightController.text = (cm / 30.48).toStringAsFixed(1);
                        final kg = double.tryParse(_weightController.text) ?? 72.0;
                        _weightController.text = (kg * 2.20462).toStringAsFixed(1);
                        if (_targetWeightController.text.isNotEmpty) {
                          final tKg = double.tryParse(_targetWeightController.text) ?? 70.0;
                          _targetWeightController.text = (tKg * 2.20462).toStringAsFixed(1);
                        }
                      });
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Allows calculation of precise macro ratios and lean body composition.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 20),

        // Age
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Age (Years)',
            prefixIcon: const Icon(Icons.cake_rounded),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Height
        TextField(
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _useMetricUnits ? 'Height (cm)' : 'Height (feet)',
            prefixIcon: const Icon(Icons.height_rounded),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Weight
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _useMetricUnits ? 'Current Weight (kg)' : 'Current Weight (lbs)',
            prefixIcon: const Icon(Icons.monitor_weight_rounded),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Target Weight
        TextField(
          controller: _targetWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _useMetricUnits ? 'Target Weight (kg) - Optional' : 'Target Weight (lbs) - Optional',
            prefixIcon: const Icon(Icons.flag_rounded),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.limeGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed_rounded, size: 20, color: AppColors.limeGreen),
                  SizedBox(width: 10),
                  Text(
                    'Body Mass Index (BMI)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.limeGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_getLivePreviewProfile().bmi} • ${_getLivePreviewProfile().bmiCategory}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.limeGreen),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: FITNESS GOAL
  // ---------------------------------------------------------------------------
  Widget _buildStepFitnessGoal(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your primary goal?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'We automatically adjust your daily caloric deficit or surplus accordingly.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 20),

        _buildGoalTile(
          id: 'lose_weight',
          title: 'Lose Weight (Fat Loss)',
          subtitle: 'Moderate caloric deficit (~450 kcal), high protein retention to preserve lean muscle.',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6D00),
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        _buildGoalTile(
          id: 'gain_weight',
          title: 'Gain Weight (Muscle Hypertrophy)',
          subtitle: 'Lean caloric surplus (~350 kcal), optimal progressive overload and muscle synthesis.',
          icon: Icons.fitness_center_rounded,
          color: AppColors.limeGreen,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        _buildGoalTile(
          id: 'maintain_weight',
          title: 'Maintain Weight & Vitality',
          subtitle: 'Energy equilibrium (TDEE balance), enhanced endurance, flexibility & wellness.',
          icon: Icons.balance_rounded,
          color: AppColors.electricCyan,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        const Text(
          'Target Pace (Weekly Rate)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Target speed of bodyweight change for caloric calculations.',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionCard(
              title: '0.25 kg/wk',
              icon: Icons.battery_charging_full_rounded,
              isSelected: _targetPaceKgPerWeek == 0.25,
              onTap: () => setState(() => _targetPaceKgPerWeek = 0.25),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildSelectionCard(
              title: '0.50 kg/wk',
              icon: Icons.recommend_rounded,
              isSelected: _targetPaceKgPerWeek == 0.50,
              onTap: () => setState(() => _targetPaceKgPerWeek = 0.50),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildSelectionCard(
              title: '0.75 kg/wk',
              icon: Icons.rocket_launch_rounded,
              isSelected: _targetPaceKgPerWeek == 0.75,
              onTap: () => setState(() => _targetPaceKgPerWeek = 0.75),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _fitnessGoal == id;

    return InkWell(
      onTap: () => setState(() => _fitnessGoal = id),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: DIET PREFERENCE
  // ---------------------------------------------------------------------------
  Widget _buildStepDietPreference(bool isDark) {
    final diets = [
      {'id': 'balanced', 'title': 'Balanced Nutrition', 'sub': 'Clean whole carbs, lean protein, and essential fats', 'icon': Icons.restaurant_rounded},
      {'id': 'high_protein', 'title': 'High Protein', 'sub': '2.2g/kg protein priority for maximum muscle recovery', 'icon': Icons.egg_alt_rounded},
      {'id': 'low_carb', 'title': 'Low Carb / Keto', 'sub': 'Restricted carbs (<50g) and healthy natural fats', 'icon': Icons.set_meal_rounded},
      {'id': 'vegetarian', 'title': 'Vegetarian', 'sub': 'Plant-based fuel with dairy & wholesome pulses', 'icon': Icons.spa_rounded},
      {'id': 'vegan', 'title': 'Vegan Plant Fuel', 'sub': '100% plant protein, whole seeds, grains & greens', 'icon': Icons.eco_rounded},
      {'id': 'mediterranean', 'title': 'Mediterranean', 'sub': 'Rich in olive oils, nuts, seafood, and fresh produce', 'icon': Icons.local_florist_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your diet type',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Tunes your macro breakdown (protein, carbs, fats) to fit your lifestyle.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 16),
        ...diets.map((d) {
          final id = d['id'] as String;
          final isSelected = _dietType == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _dietType = id),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.limeGreen.withValues(alpha: isDark ? 0.2 : 0.1)
                      : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.limeGreen : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(d['icon'] as IconData, color: isSelected ? AppColors.limeGreen : AppColors.electricCyan, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['title'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            d['sub'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.limeGreen, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: NUTRITION TARGETS (SUGGESTED VS CUSTOM)
  // ---------------------------------------------------------------------------
  Widget _buildStepNutritionTargets(bool isDark, UserProfile livePreview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition & Calorie Targets',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose between scientifically calculated balanced values or enter custom targets.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 16),

        // Mode Switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeToggleOption(
                  title: '✨ Suggested Balanced',
                  isSelected: _targetMode == 'suggested',
                  onTap: () {
                    setState(() {
                      _targetMode = 'suggested';
                      _customCaloriesController.text = '${livePreview.dailyCaloriesTarget}';
                      _customProteinController.text = '${livePreview.targetProteinGrams}';
                      _customCarbsController.text = '${livePreview.targetCarbsGrams}';
                      _customFatsController.text = '${livePreview.targetFatsGrams}';
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildModeToggleOption(
                  title: '⚙️ Custom Targets',
                  isSelected: _targetMode == 'custom',
                  onTap: () => setState(() => _targetMode = 'custom'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_targetMode == 'suggested') ...[
          // Suggested breakdown card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF162520), const Color(0xFF1B2F25)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SCIENTIFIC RECOMMENDATION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.limeGreen),
                    ),
                    Text(
                      'Based on ${_gender.toUpperCase()}, ${_ageController.text}y, ${_weightController.text}${_useMetricUnits ? "kg" : "lbs"}',
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroPreviewPill('Calories', '${livePreview.dailyCaloriesTarget}', 'kcal', AppColors.limeGreen),
                    _buildMacroPreviewPill('Protein', '${livePreview.targetProteinGrams}', 'grams', AppColors.electricCyan),
                    _buildMacroPreviewPill('Carbs', '${livePreview.targetCarbsGrams}', 'grams', const Color(0xFFF59E0B)),
                    _buildMacroPreviewPill('Fats', '${livePreview.targetFatsGrams}', 'grams', const Color(0xFFA855F7)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Calculated via Mifflin-St Jeor BMR & activity multiplier with ${livePreview.goalLabel} calibration.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
        ] else ...[
          // Custom Editable Fields
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customize Your Daily Targets', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 14),
                TextField(
                  controller: _customCaloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Daily Calories (kcal)',
                    prefixIcon: const Icon(Icons.local_fire_department_rounded, color: AppColors.limeGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customProteinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _customCarbsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _customFatsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fats (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: WORKOUT TARGETS & CUSTOM TARGET NOTE
  // ---------------------------------------------------------------------------
  Widget _buildStepWorkoutTargets(bool isDark, UserProfile livePreview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout & Activity Target',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Set your weekly workout days, session duration, and add custom goals.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 20),

        // Weekly Days
        const Text('Weekly Workout Days', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [2, 3, 4, 5, 6].map((days) {
            final isSelected = _weeklyWorkoutDays == days;
            return InkWell(
              onTap: () => setState(() => _weeklyWorkoutDays = days),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.limeGreen : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.limeGreen : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$days d',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Daily Active Minutes Target
        const Text('Target Session Duration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [30, 45, 60, 90].map((mins) {
            final isSelected = _dailyWorkoutMinutes == mins;
            return InkWell(
              onTap: () => setState(() => _dailyWorkoutMinutes = mins),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.electricCyan : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.electricCyan : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$mins min',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Add Custom Target (User able to add custom target)
        const Text('Custom Fitness Target (Optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 6),
        Text(
          'e.g. 10,000 steps daily, 100 pushups, run 5km twice weekly',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _customWorkoutTargetController,
          decoration: InputDecoration(
            hintText: 'Enter your custom target...',
            prefixIcon: const Icon(Icons.star_rounded, color: Color(0xFFFFB300)),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.limeGreen : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.limeGreen : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.limeGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.limeGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPreviewPill(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
