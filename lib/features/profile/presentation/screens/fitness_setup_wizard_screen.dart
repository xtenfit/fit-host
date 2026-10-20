import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/card_shell.dart';
import '../../domain/models/user_profile.dart';
import '../controllers/user_profile_controller.dart';
import '../widgets/setup/anatomy_pointer_diagram.dart';
import '../widgets/setup/goal_selection_card.dart';
import '../widgets/setup/interactive_ruler_slider.dart';
import '../widgets/avatar_picker_sheet.dart';
import '../../../../core/services/startup_gate_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/permission_service.dart';

/// Full-featured, Apple UI & Framer Motion styled 20-Step Premium Fitness Setup Wizard.
/// Uses FIT HOST locked tokens:
/// - Background: #0A0F0D
/// - Surface: #121A16
/// - Primary: #00E676 (brand green)
/// - Secondary: #00E5FF (electric cyan)
/// - Text primary: near-white (#F0F6F2)
/// - Text secondary: #8FA396
/// - Radius: 16
///
/// Features 20 full-detailed steps:
///  0: Gender Selection (Male vs Female model assets)
///  1: Age & Metabolic Stage
///  2: Height (Interactive Ruler with ft/in & cm)
///  3: Current Weight (Interactive Ruler with lbs & kg + BMI)
///  4: Target Weight & Desired Timeline / Pace
///  5: Body Composition & Circumferences (Optional)
///  6: Primary Fitness Goal (Lose Weight, Build Muscle, Keep Fit)
///  7: Gender-Specific Aesthetic Specialization Goals
///  8: Focus Target Muscle Areas (Interactive Anatomy Pointer Diagram)
///  9: Training Experience Level
/// 10: Training Environment & Locations
/// 11: Available Equipment
/// 12: Weekly Workout Days & Schedule (Mon-Sun chips)
/// 13: Preferred Session Duration (15, 30, 45, 60, 90 min)
/// 14: Diet Style & Nutritional Preferences
/// 15: Daily Meal Frequency & Timing
/// 16: Daily Hydration Target & Water Reminders
/// 17: Daily Lifestyle, Sleep & Activity Level
/// 18: AI Plan Analysis & Generation Transition
/// 19: Customized Plan Ready & Activation
class FitnessSetupWizardScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;

  const FitnessSetupWizardScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  ConsumerState<FitnessSetupWizardScreen> createState() => _FitnessSetupWizardScreenState();
}

class _FitnessSetupWizardScreenState extends ConsumerState<FitnessSetupWizardScreen>
    with SingleTickerProviderStateMixin {
  int _currentScreen = 0;
  static const int _totalScreens = 20;

  // Profile Identity & Avatar State
  late TextEditingController _nameController;
  String _avatarId = 'avatar_male_1';
  String? _customProfileImagePath;

  // Selected State
  String _selectedGender = 'male'; // 'male' or 'female'
  int _age = 26;

  // Height State
  bool _useFt = true;
  double _heightCm = 175.0;
  double _heightInches = 69.0;

  // Weight State
  bool _useLbs = true;
  double _weightKg = 74.8;
  double _weightLbs = 165.0;

  // Target Weight & Pace
  double _targetWeightKg = 70.0;
  double _targetWeightLbs = 154.0;
  double _targetPaceKgPerWeek = 0.5;

  // Body Composition (Optional)
  double _bodyFatPercentage = 18.0;
  double? _waistCm;
  double? _hipCm;
  double? _chestCm;
  double? _neckCm;

  // Goals
  String _selectedGoal = 'build_muscle'; // 'lose_weight', 'build_muscle', 'keep_fit'
  bool _hasUserManuallySelectedGoal = false;
  final Set<String> _genderSpecificGoals = {};
  final Set<String> _selectedFocusAreas = {'chest', 'leg'};

  /// Determines the optimal fitness goal from current and target weights:
  /// - target < current (-0.5 kg threshold): 'lose_weight'
  /// - target > current (+0.5 kg threshold): 'build_muscle'
  /// - target ≈ current: 'keep_fit'
  String _determineGoalFromWeights() {
    final curWeight = _useLbs ? (_weightLbs / 2.20462) : _weightKg;
    final tgtWeight = _useLbs ? (_targetWeightLbs / 2.20462) : _targetWeightKg;
    final diff = tgtWeight - curWeight;

    if (diff < -0.5) {
      return 'lose_weight';
    } else if (diff > 0.5) {
      return 'build_muscle';
    } else {
      return 'keep_fit';
    }
  }

  void _syncGoalFromWeightsIfUntouched() {
    if (!_hasUserManuallySelectedGoal) {
      _selectedGoal = _determineGoalFromWeights();
    }
  }

  // Experience, Environment & Equipment
  String _experienceLevel = 'intermediate'; // 'beginner', 'intermediate', 'advanced', 'athlete'
  final Set<String> _selectedLocations = {'gym'};
  final Set<String> _selectedEquipment = {'full_gym', 'dumbbells'};

  // Schedule & Duration
  int _weeklyWorkoutDays = 4;
  final Set<int> _selectedWeekdays = {1, 3, 5, 6};
  final bool _usesEveryDay = false;
  int _dailyWorkoutMinutes = 45;

  // Nutrition & Meals
  String _selectedDiet = 'balanced';
  int _mealsPerDay = 3;

  // Hydration
  int _targetWaterMl = 3000;
  int _reminderFrequencyHours = 2;
  final String _quietHoursStart = '22:00';
  final String _quietHoursEnd = '07:00';

  // Lifestyle & Sleep
  String _activityLevel = 'moderately_active';
  double _targetSleepHours = 8.0;
  int _dailyStepsGoal = 10000;
  final String _stressLevel = 'moderate';

  // Transition controller
  Timer? _transitionTimer;
  double _transitionProgress = 0.0;

  // Locked Design Tokens
  static const Color kBackground = Color(0xFF0A0F0D);
  static const Color kSurface = Color(0xFF121A16);
  static const Color kPrimary = Color(0xFF00E676);
  static const Color kSecondary = Color(0xFF00E5FF);
  static const Color kTextPrimary = Color(0xFFF0F6F2);
  static const Color kTextSecondary = Color(0xFF8FA396);
  static const Color kBorder = Color(0xFF1F2D26);

  @override
  void initState() {
    super.initState();

    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(
      text: profile.name == 'Guest Athlete' ? '' : profile.name,
    );
    if (profile.avatarId.startsWith('/') || profile.avatarId.contains('image_picker')) {
      _customProfileImagePath = profile.avatarId;
    } else if (profile.avatarId.isNotEmpty && profile.avatarId != 'initial') {
      _avatarId = profile.avatarId;
    } else {
      _avatarId = profile.gender == 'female' ? 'avatar_female_1' : 'avatar_male_1';
    }

    _selectedGender = profile.gender;
    _age = profile.age.clamp(16, 99);
    _useLbs = !profile.useMetricUnits;
    _useFt = !profile.useMetricUnits;

    _weightKg = profile.weightKg;
    _heightCm = profile.heightCm;
    _weightLbs = profile.weightInLbs;
    _heightInches = profile.heightCm / 2.54;

    _targetWeightKg = profile.targetWeightKg ?? profile.weightKg;
    _targetWeightLbs = _targetWeightKg * 2.20462;
    _targetPaceKgPerWeek = profile.targetPaceKgPerWeek;

    if (profile.fitnessGoal.isNotEmpty && profile.isProfileSetupCompleted) {
      _hasUserManuallySelectedGoal = true;
      _selectedGoal = profile.fitnessGoal == 'gain_weight'
          ? 'build_muscle'
          : (profile.fitnessGoal == 'maintain_weight' ? 'keep_fit' : profile.fitnessGoal);
    } else {
      _hasUserManuallySelectedGoal = false;
      _selectedGoal = _determineGoalFromWeights();
    }

    _weeklyWorkoutDays = profile.weeklyWorkoutDays.clamp(2, 7);
    _dailyWorkoutMinutes = profile.dailyWorkoutMinutes.clamp(15, 90);
    _experienceLevel = profile.experienceLevel;
    _selectedDiet = profile.dietType;
    _mealsPerDay = profile.mealsPerDay;
    _targetWaterMl = profile.targetWaterMl;
    _activityLevel = profile.activityLevel;
    _targetSleepHours = profile.targetSleepHours;
    _dailyStepsGoal = profile.dailyStepsGoal;

    if (_selectedGender == 'female') {
      _selectedFocusAreas.clear();
      _selectedFocusAreas.addAll(['glutes', 'thighs']);
      _genderSpecificGoals.addAll(['booty_lift', 'hourglass']);
    } else {
      _selectedFocusAreas.clear();
      _selectedFocusAreas.addAll(['chest', 'arms']);
      _genderSpecificGoals.addAll(['v_taper', 'chiseled_chest']);
    }
  }

  void _handleToggleFocusArea(String area) {
    final isFemale = _selectedGender.toLowerCase() == 'female';
    final allPartIds = isFemale
        ? [
            'arms',
            'chest',
            'back',
            'abs',
            'waist',
            'hips',
            'glutes',
            'hamstrings',
            'thighs',
            'calves',
          ]
        : [
            'shoulders',
            'chest',
            'arms',
            'back',
            'abs',
            'obliques',
            'triceps',
            'glutes',
            'quads',
            'calves',
          ];

    setState(() {
      final key = area.toLowerCase().replaceAll(' ', '_');
      final isFullBody = key == 'full_body' || key == 'full';

      if (isFullBody) {
        final isAllSelected = _selectedFocusAreas.contains('full_body') ||
            _selectedFocusAreas.contains('full body') ||
            allPartIds.every((id) =>
                _selectedFocusAreas.contains(id) ||
                (id == 'quads' && (_selectedFocusAreas.contains('leg') || _selectedFocusAreas.contains('legs'))) ||
                (id == 'thighs' && (_selectedFocusAreas.contains('leg') || _selectedFocusAreas.contains('legs'))) ||
                (id == 'arms' && _selectedFocusAreas.contains('arm')));

        if (isAllSelected) {
          _selectedFocusAreas.clear();
        } else {
          _selectedFocusAreas.clear();
          _selectedFocusAreas.addAll(allPartIds);
          _selectedFocusAreas.add('full_body');
        }
      } else {
        final isCurrentlySelected = _selectedFocusAreas.contains(key) ||
            (key == 'quads' && (_selectedFocusAreas.contains('leg') || _selectedFocusAreas.contains('legs'))) ||
            (key == 'thighs' && (_selectedFocusAreas.contains('leg') || _selectedFocusAreas.contains('legs'))) ||
            (key == 'arms' && _selectedFocusAreas.contains('arm'));

        if (isCurrentlySelected) {
          _selectedFocusAreas.remove(key);
          _selectedFocusAreas.remove('leg');
          _selectedFocusAreas.remove('legs');
          _selectedFocusAreas.remove('arm');
          _selectedFocusAreas.remove('full_body');
          _selectedFocusAreas.remove('full body');
        } else {
          _selectedFocusAreas.add(key);
          final allSelected = allPartIds.every((id) =>
              _selectedFocusAreas.contains(id) ||
              (id == 'quads' && (_selectedFocusAreas.contains('leg') || _selectedFocusAreas.contains('legs'))) ||
              (id == 'thighs' && (_selectedFocusAreas.contains('leg') || _selectedFocusAreas.contains('legs'))) ||
              (id == 'arms' && _selectedFocusAreas.contains('arm')));
          if (allSelected) {
            _selectedFocusAreas.add('full_body');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _transitionTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickProfilePhotoOrAvatar() async {
    final picked = await showPhotoOrAvatarPicker(
      context,
      currentAvatarId: _customProfileImagePath ?? _avatarId,
      userGender: _selectedGender,
      userName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Athlete',
    );
    if (picked != null && mounted) {
      setState(() {
        if (picked.startsWith('/') ||
            picked.contains('cache') ||
            picked.contains('image_picker')) {
          _customProfileImagePath = picked;
        } else {
          _avatarId = picked;
          _customProfileImagePath = null;
        }
      });
    }
  }

  void _nextScreen() {
    if (_currentScreen == 16) {
      PermissionService.instance.requestReminderPermissions(context);
    }
    _syncGoalFromWeightsIfUntouched();
    if (_currentScreen < _totalScreens - 1) {
      setState(() {
        _currentScreen++;
        if (_currentScreen == 18) {
          _startTransitionTimer();
        }
      });
    } else {
      _finishAndActivatePlan();
    }
  }

  void _previousScreen() {
    if (_currentScreen > 0) {
      setState(() => _currentScreen--);
    } else {
      _handleExit();
    }
  }

  void _skipScreen() {
    _nextScreen();
  }

  void _startTransitionTimer() {
    _transitionProgress = 0.0;
    _transitionTimer?.cancel();
    _transitionTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _transitionProgress += 0.02;
        if (_transitionProgress >= 1.0) {
          timer.cancel();
          _nextScreen();
        }
      });
    });
  }

  Future<void> _handleExit() async {
    if (widget.isInitialSetup) {
      final baseProfile = ref.read(userProfileProvider);
      await ref.read(userProfileProvider.notifier).updateProfile(
        baseProfile.copyWith(isProfileSetupCompleted: true),
      );
      try {
        await ref.read(startupGateServiceProvider).setFirstLaunchCompleted(true);
        await ref.read(startupGateServiceProvider).setAuthDecisionMade(true);
      } catch (_) {}
    }
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _finishAndActivatePlan({
    bool navigateToSignUp = false,
    bool navigateToSignIn = false,
  }) async {
    final finalWeightKg = _useLbs ? (_weightLbs / 2.20462) : _weightKg;
    final finalHeightCm = _useFt ? (_heightInches * 2.54) : _heightCm;
    final finalTargetWeightKg = _useLbs ? (_targetWeightLbs / 2.20462) : _targetWeightKg;

    final baseProfile = ref.read(userProfileProvider);
    final chosenName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (baseProfile.name.isNotEmpty && baseProfile.name != 'Guest Athlete'
            ? baseProfile.name
            : 'Athlete');
    final chosenAvatarId = _customProfileImagePath ?? _avatarId;

    final updatedProfile = UserProfile.calculateSuggestedTargets(
      name: chosenName,
      age: _age,
      gender: _selectedGender,
      heightCm: finalHeightCm,
      weightKg: finalWeightKg,
      targetWeightKg: finalTargetWeightKg,
      useMetricUnits: !_useLbs,
      fitnessGoal: _selectedGoal,
      dietType: _selectedDiet,
      weeklyWorkoutDays: _weeklyWorkoutDays,
      dailyWorkoutMinutes: _dailyWorkoutMinutes,
      customTargetNote: 'Personalized via 20-step setup wizard. Focus: ${_selectedFocusAreas.join(', ')}.',
      activityLevel: _activityLevel,
      experienceLevel: _experienceLevel,
      focusAreas: _selectedFocusAreas.toList(),
      isCompleted: true,
    ).copyWith(
      targetPaceKgPerWeek: _targetPaceKgPerWeek,
      bodyFatPercentage: _bodyFatPercentage,
      waistCm: _waistCm,
      hipCm: _hipCm,
      chestCm: _chestCm,
      neckCm: _neckCm,
      genderSpecificGoals: _genderSpecificGoals.toList(),
      selectedWeekdays: _selectedWeekdays.toList(),
      usesEveryDay: _usesEveryDay,
      sessionDurationMinutes: _dailyWorkoutMinutes,
      mealsPerDay: _mealsPerDay,
      targetWaterMl: _targetWaterMl,
      reminderFrequencyHours: _reminderFrequencyHours,
      quietHoursStart: _quietHoursStart,
      quietHoursEnd: _quietHoursEnd,
      targetSleepHours: _targetSleepHours,
      dailyStepsGoal: _dailyStepsGoal,
      stressLevel: _stressLevel,
      avatarId: chosenAvatarId,
      isProfileSetupCompleted: true,
    );

    await ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
    try {
      await ref.read(authProvider.notifier).updateUserProfileMetadata(
        name: chosenName,
        avatarUrl: chosenAvatarId,
      );
    } catch (_) {}
    try {
      await ref.read(startupGateServiceProvider).setFirstLaunchCompleted(true);
      await ref.read(startupGateServiceProvider).setAuthDecisionMade(true);
    } catch (_) {}

    if (mounted) {
      if (navigateToSignUp) {
        context.go('/auth/sign-up');
      } else if (navigateToSignIn) {
        context.go('/auth/sign-in');
      } else {
        context.go('/home');
      }
    }
  }

  bool _isStepSkippable(int screenIndex) {
    // Non-skippable: Gender (0), Goals (6), Transition (18), Plan Ready (19)
    if (screenIndex == 0 || screenIndex == 6 || screenIndex >= 18) {
      return false;
    }
    return true;
  }

  Widget _buildActiveScreen() {
    switch (_currentScreen) {
      case 0:
        return _buildScreen0Gender();
      case 1:
        return _buildScreen1Age();
      case 2:
        return _buildScreen2Height();
      case 3:
        return _buildScreen3Weight();
      case 4:
        return _buildScreen4TargetWeight();
      case 5:
        return _buildScreen5BodyComposition();
      case 6:
        return _buildScreen6Goals();
      case 7:
        return _buildScreen7GenderAesthetic();
      case 8:
        return _buildScreen8FocusArea();
      case 9:
        return _buildScreen9Experience();
      case 10:
        return _buildScreen10Location();
      case 11:
        return _buildScreen11Equipment();
      case 12:
        return _buildScreen12Schedule();
      case 13:
        return _buildScreen13Duration();
      case 14:
        return _buildScreen14Diet();
      case 15:
        return _buildScreen15Meals();
      case 16:
        return _buildScreen16Hydration();
      case 17:
        return _buildScreen17Lifestyle();
      case 18:
        return _buildScreen18Transition();
      case 19:
        return _buildScreen19PlanReady();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      bottomNavigationBar: _currentScreen < 18
          ? SafeArea(
              top: false,
              child: _buildBottomActionBar(),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar Navigation Header (Screens 0 to 17)
            if (_currentScreen < 18) _buildTopNavigationHeader(),

            // Animated Screen Transition
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentScreen),
                  child: _buildActiveScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP NAVIGATION HEADER WITH PROGRESS BAR
  // ---------------------------------------------------------------------------
  Widget _buildTopNavigationHeader() {
    final progressValue = (_currentScreen + 1) / _totalScreens.toDouble();
    final showSkip = _isStepSkippable(_currentScreen);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 22, color: kTextPrimary),
                onPressed: _previousScreen,
                tooltip: 'Back',
              ),
              const Spacer(),

              // Step counter pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Step ${_currentScreen + 1} of $_totalScreens',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              const Spacer(),
              if (showSkip)
                TextButton(
                  onPressed: _skipScreen,
                  style: TextButton.styleFrom(
                    foregroundColor: kTextSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: kBackground,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: PrimaryButton(
        text: 'NEXT',
        onPressed: _nextScreen,
      ),
    );
  }

  // ===========================================================================
  // SCREEN 0: GENDER SELECTION
  // ===========================================================================
  Widget _buildScreen0Gender() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Welcome, Athlete",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kTextPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Personalize your athlete profile and identity',
                      style: TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _pickProfilePhotoOrAvatar,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: AppAvatar(
                        avatarId: _customProfileImagePath ?? _avatarId,
                        radius: 28,
                        name: _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : 'Athlete',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: kBackground, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Name Input
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your name (e.g. Alex Hunter)',
              hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.6), fontSize: 13),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: kPrimary, size: 18),
              suffixIcon: TextButton(
                onPressed: _pickProfilePhotoOrAvatar,
                child: const Text('Photo', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              filled: true,
              fillColor: kSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kPrimary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),

          const Text(
            "What's your gender?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Calibrates hormone profiles, metabolic expenditure, and aesthetic targets',
            style: TextStyle(fontSize: 12, color: kTextSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  label: 'Male',
                  genderValue: 'male',
                  imageAsset: 'assets/images/setup/male_model.png',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGenderCard(
                  label: 'Female',
                  genderValue: 'female',
                  imageAsset: 'assets/images/setup/female_model.png',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard({
    required String label,
    required String genderValue,
    required String imageAsset,
  }) {
    final isSelected = _selectedGender == genderValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = genderValue;
          if (_selectedGender == 'female') {
            _selectedFocusAreas.clear();
            _selectedFocusAreas.addAll(['glutes', 'thighs']);
            _genderSpecificGoals.clear();
            _genderSpecificGoals.addAll(['booty_lift', 'hourglass']);
          } else {
            _selectedFocusAreas.clear();
            _selectedFocusAreas.addAll(['chest', 'arms']);
            _genderSpecificGoals.clear();
            _genderSpecificGoals.addAll(['v_taper', 'chiseled_chest']);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 240,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? kPrimary : kBorder,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? kPrimary : kTextPrimary,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      genderValue == 'male' ? Icons.male_rounded : Icons.female_rounded,
                      size: 64,
                      color: isSelected ? kPrimary : kTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 1: AGE & METABOLIC STAGE
  // ===========================================================================
  Widget _buildScreen1Age() {
    String zoneBadge;
    String zoneDesc;
    if (_age < 25) {
      zoneBadge = 'Peak Growth & Protein Synthesis';
      zoneDesc = 'High natural testosterone/GH and rapid muscular recovery response.';
    } else if (_age < 40) {
      zoneBadge = 'Prime Athletic Performance';
      zoneDesc = 'Ideal neuromuscular coordination with focused strength potential.';
    } else if (_age < 55) {
      zoneBadge = 'Metabolic Optimization & Joint Longevity';
      zoneDesc = 'Targeting tendon elasticity, visceral fat reduction and lean retention.';
    } else {
      zoneBadge = 'Vitality, Bone Density & Functional Strength';
      zoneDesc = 'Prioritizing functional range of motion and joint stability.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How old are you?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Age directly informs recovery curves, joint load allowances and caloric baseline',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 36),
          Center(
            child: Column(
              children: [
                Text(
                  '$_age',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: kPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'YEARS OLD',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextSecondary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 24),
                InteractiveRulerSlider(
                  value: _age.toDouble(),
                  minValue: 16,
                  maxValue: 85,
                  step: 1,
                  unit: 'yrs',
                  onChanged: (val) => setState(() => _age = val.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kSecondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: kSecondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zoneBadge,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zoneDesc,
                          style: const TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2: HEIGHT
  // ===========================================================================
  Widget _buildScreen2Height() {
    final ftValue = (_heightInches / 12).floor();
    final inValue = (_heightInches % 12).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'How tall are you?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
              ),
              _buildUnitToggle(
                option1: 'ft',
                option2: 'cm',
                isOption1: _useFt,
                onToggle: (val) => setState(() => _useFt = val),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Height determines your mechanical lever arms and healthy weight threshold',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 44),
          Center(
            child: Column(
              children: [
                Text(
                  _useFt ? "$ftValue' $inValue\"" : '${_heightCm.round()} cm',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: kPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _useFt ? 'FEET & INCHES' : 'CENTIMETERS',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextSecondary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 32),
                InteractiveRulerSlider(
                  value: _useFt ? _heightInches : _heightCm,
                  minValue: _useFt ? 48.0 : 120.0,
                  maxValue: _useFt ? 86.0 : 220.0,
                  step: 1.0,
                  unit: _useFt ? 'in' : 'cm',
                  onChanged: (val) {
                    setState(() {
                      if (_useFt) {
                        _heightInches = val;
                        _heightCm = val * 2.54;
                      } else {
                        _heightCm = val;
                        _heightInches = val / 2.54;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3: CURRENT WEIGHT
  // ===========================================================================
  Widget _buildScreen3Weight() {
    final weightKgVal = _useLbs ? (_weightLbs / 2.20462) : _weightKg;
    final heightM = _heightCm / 100.0;
    final bmi = weightKgVal / (heightM * heightM);
    String bmiCategory;
    if (bmi < 18.5) {
      bmiCategory = 'Lean Baseline';
    } else if (bmi < 25.0) {
      bmiCategory = 'Optimal Athletic Range';
    } else if (bmi < 30.0) {
      bmiCategory = 'Elevated Mass / Hypertrophic';
    } else {
      bmiCategory = 'Targeted Body Recomposition';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current weight?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
              ),
              _buildUnitToggle(
                option1: 'lbs',
                option2: 'kg',
                isOption1: _useLbs,
                onToggle: (val) => setState(() => _useLbs = val),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Calibrates your baseline energy burn, barbell percentages and water need',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  _useLbs ? _weightLbs.toStringAsFixed(1) : _weightKg.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: kPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _useLbs ? 'POUNDS' : 'KILOGRAMS',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextSecondary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 28),
                InteractiveRulerSlider(
                  value: _useLbs ? _weightLbs : _weightKg,
                  minValue: _useLbs ? 80.0 : 36.0,
                  maxValue: _useLbs ? 350.0 : 160.0,
                  step: 0.5,
                  fractionDigits: 1,
                  unit: _useLbs ? 'lbs' : 'kg',
                  onChanged: (val) {
                    setState(() {
                      if (_useLbs) {
                        _weightLbs = val;
                        _weightKg = val / 2.20462;
                      } else {
                        _weightKg = val;
                        _weightLbs = val * 2.20462;
                      }
                      _syncGoalFromWeightsIfUntouched();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Calculated BMI', style: TextStyle(fontSize: 14, color: kTextSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      '${bmi.toStringAsFixed(1)} • $bmiCategory',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 4: TARGET WEIGHT & TIMELINE
  // ===========================================================================
  Widget _buildScreen4TargetWeight() {
    final diffKg = (_weightKg - _targetWeightKg).abs();
    final estimatedWeeks = _targetPaceKgPerWeek > 0 ? (diffKg / _targetPaceKgPerWeek).ceil() : 8;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target weight & pace',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'We compute sustainable caloric deficits/surpluses to protect lean muscle',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  _useLbs ? _targetWeightLbs.toStringAsFixed(1) : _targetWeightKg.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: kSecondary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _useLbs ? 'TARGET POUNDS' : 'TARGET KILOGRAMS',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextSecondary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 24),
                InteractiveRulerSlider(
                  value: _useLbs ? _targetWeightLbs : _targetWeightKg,
                  minValue: _useLbs ? 80.0 : 36.0,
                  maxValue: _useLbs ? 350.0 : 160.0,
                  step: 0.5,
                  fractionDigits: 1,
                  unit: _useLbs ? 'lbs' : 'kg',
                  onChanged: (val) {
                    setState(() {
                      if (_useLbs) {
                        _targetWeightLbs = val;
                        _targetWeightKg = val / 2.20462;
                      } else {
                        _targetWeightKg = val;
                        _targetWeightLbs = val * 2.20462;
                      }
                      _syncGoalFromWeightsIfUntouched();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Weekly Desired Pace', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPaceChip('0.25 kg/wk', 0.25, 'Gentle'),
              const SizedBox(width: 8),
              _buildPaceChip('0.5 kg/wk', 0.5, 'Recommended'),
              const SizedBox(width: 8),
              _buildPaceChip('0.75 kg/wk', 0.75, 'Athletic'),
              const SizedBox(width: 8),
              _buildPaceChip('1.0 kg/wk', 1.0, 'Intense'),
            ],
          ),
          const SizedBox(height: 24),
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: kPrimary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      diffKg < 0.5
                          ? 'Maintaining healthy weight with body recomposition.'
                          : 'Target achievable in ~$estimatedWeeks weeks with high adherence.',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceChip(String label, double pace, String tag) {
    final isSelected = (_targetPaceKgPerWeek - pace).abs() < 0.05;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _targetPaceKgPerWeek = pace),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kPrimary.withValues(alpha: 0.15) : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kPrimary : kBorder,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? kPrimary : kTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? kPrimary.withValues(alpha: 0.8) : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 5: BODY COMPOSITION & MEASUREMENTS (OPTIONAL)
  // ===========================================================================
  Widget _buildScreen5BodyComposition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Composition',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Optional: Provides granular Katch-McArdle metabolic rate accuracy',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 24),
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Body Fat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
                      Text('${_bodyFatPercentage.round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: kPrimary,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      thumbColor: kPrimary,
                      overlayColor: kPrimary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _bodyFatPercentage,
                      min: 6.0,
                      max: 42.0,
                      divisions: 36,
                      onChanged: (val) => setState(() => _bodyFatPercentage = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Circumference Estimates (cm)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMeasureInput(
                  label: 'Waist',
                  currentVal: _waistCm ?? 82.0,
                  onChanged: (val) => setState(() => _waistCm = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasureInput(
                  label: 'Hips',
                  currentVal: _hipCm ?? 96.0,
                  onChanged: (val) => setState(() => _hipCm = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMeasureInput(
                  label: 'Chest',
                  currentVal: _chestCm ?? 98.0,
                  onChanged: (val) => setState(() => _chestCm = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasureInput(
                  label: 'Neck',
                  currentVal: _neckCm ?? 38.0,
                  onChanged: (val) => setState(() => _neckCm = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureInput({
    required String label,
    required double currentVal,
    required ValueChanged<double> onChanged,
  }) {
    return CardShell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentVal.round()} cm',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: kTextSecondary),
                      onPressed: () => onChanged((currentVal - 1).clamp(20.0, 180.0)),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20, color: kPrimary),
                      onPressed: () => onChanged((currentVal + 1).clamp(20.0, 180.0)),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 6: PRIMARY GOAL
  // ===========================================================================
  Widget _buildScreen6Goals() {
    final loseWeightImg = _selectedGender == 'female'
        ? 'assets/images/setup/female_fitness_showcase_weight.png'
        : 'assets/images/setup/male_fitness_showcase_weight.png';
    final buildMuscleImg = _selectedGender == 'female'
        ? 'assets/images/setup/female_fitness.png'
        : 'assets/images/setup/male_fitness.png';
    final keepFitImg = _selectedGender == 'female'
        ? 'assets/images/setup/female_goal_fitness.png'
        : 'assets/images/setup/male_goal_fitness.png';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your primary goal?",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your workout intensity, rep schemes and nutrition macros branch from this selection',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          GoalSelectionCard(
            title: 'Lose Weight',
            subtitle: 'Target stubborn fat while preserving lean athletic tone',
            imageAsset: loseWeightImg,
            isSelected: _selectedGoal == 'lose_weight',
            onTap: () => setState(() => _selectedGoal = 'lose_weight'),
          ),
          GoalSelectionCard(
            title: 'Build Muscle',
            subtitle: 'Hypertrophy-focused training for dense muscular development',
            imageAsset: buildMuscleImg,
            isSelected: _selectedGoal == 'build_muscle',
            onTap: () => setState(() => _selectedGoal = 'build_muscle'),
          ),
          GoalSelectionCard(
            title: 'Keep Fit',
            subtitle: 'Cardiovascular endurance, mobility and functional stamina',
            imageAsset: keepFitImg,
            isSelected: _selectedGoal == 'keep_fit',
            onTap: () => setState(() => _selectedGoal = 'keep_fit'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 7: GENDER-SPECIFIC AESTHETIC GOALS
  // ===========================================================================
  Widget _buildScreen7GenderAesthetic() {
    final isFemale = _selectedGender == 'female';
    final items = isFemale
        ? [
            ('booty_lift', '🍑 Lifted Booty & Glutes', 'Target gluteus maximus & medius for firm projection'),
            ('hourglass', '⏳ Hourglass & Flat Stomach', 'Deep core activation and slender waistline tapering'),
            ('lean_thighs', '🦵 Lean Thighs & Sculpted Calves', 'Elongated, toned leg lines without bulky quad mass'),
            ('toned_arms', '💪 Sleek Arms & Back Posture', 'Defined shoulders, upright posture, zero batwings'),
            ('radiance', '✨ Metabolic Glow & Vitality', 'High daily energy, cellular hydration, active fat burning'),
          ]
        : [
            ('v_taper', '🦅 V-Taper Broad Back', 'Wide upper latissimus dorsi and narrow athletic waistline'),
            ('chiseled_chest', '🛡️ Chiseled Chest & Arm Peaks', 'Upper pectoral density and prominent bicep/tricep heads'),
            ('six_pack', '⚡ Six-Pack Abs & Serratus', 'Direct core flexion, low visceral fat, etched midsection'),
            ('power_legs', '🦵 Athletic Quads & Hamstrings', 'Teardrop quad definition and explosive lower body chain'),
            ('total_mass', '🦁 Total Muscular Mass & Power', 'Maximum progressive overload and total body hypertrophy'),
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFemale ? 'Female aesthetic focus' : 'Male aesthetic focus',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Specialized targets calibrated for ${isFemale ? "women's" : "men's"} physique goals',
            style: const TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 18),
          ...items.map((it) {
            final isSelected = _genderSpecificGoals.contains(it.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _genderSpecificGoals.remove(it.$1);
                    } else {
                      _genderSpecificGoals.add(it.$1);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.$2,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              it.$3,
                              style: const TextStyle(fontSize: 12, color: kTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 8: FOCUS TARGET AREAS (ANATOMY DIAGRAM)
  // ===========================================================================
  Widget _buildScreen8FocusArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please choose your focus area',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap target muscle groups to allocate dedicated sets in each split',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 18),
          Center(
            child: AnatomyPointerDiagram(
              gender: _selectedGender,
              selectedAreas: _selectedFocusAreas,
              onToggleArea: _handleToggleFocusArea,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 9: EXPERIENCE LEVEL
  // ===========================================================================
  Widget _buildScreen9Experience() {
    final levels = [
      ('beginner', 'Beginner', 'Learning basic lifting mechanics & form (< 6 months)'),
      ('intermediate', 'Intermediate', 'Consistent compound training for 6 months – 2 years'),
      ('advanced', 'Advanced', 'Solid progressive overload foundation (2+ years)'),
      ('athlete', 'Competitive Athlete', 'High-volume periodization and maximum output'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your experience?",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sets starting weights, rest intervals and progressive overload volume',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ...levels.map((lvl) {
            final isSelected = _experienceLevel == lvl.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _experienceLevel = lvl.$1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lvl.$2,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(lvl.$3, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 10: TRAINING LOCATION
  // ===========================================================================
  Widget _buildScreen10Location() {
    final locations = [
      ('gym', '🏋️ Commercial Gym', 'Full access to barbells, squat racks, cable towers and machines'),
      ('home', '🏠 Home Gym', 'Dedicated home workout space with personal gear'),
      ('outdoors', '🌲 Outdoors & Parks', 'Open-air bodyweight, running, pull-up bars and calisthenics'),
      ('travel', '✈️ Travel & Hotel', 'Minimal space, hotel room friendly and portable routines'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where will you train?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'We ensure every exercise assigned fits your actual training environment',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ...locations.map((loc) {
            final isSelected = _selectedLocations.contains(loc.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedLocations.remove(loc.$1);
                    } else {
                      _selectedLocations.add(loc.$1);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.$2,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(loc.$3, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 11: AVAILABLE EQUIPMENT
  // ===========================================================================
  Widget _buildScreen11Equipment() {
    final gear = [
      ('full_gym', '🔩 Full Gym Equipment', 'Barbells, power racks, cable crossovers, leg press'),
      ('dumbbells', '🏋️ Dumbbells & Bench', 'Adjustable or hex dumbbells with adjustable incline bench'),
      ('bands', '🪢 Resistance Bands & Bar', 'Loop bands, door anchors, pull-up bar'),
      ('bodyweight', '🧘 Bodyweight Only', 'Zero equipment required, calisthenics & core work'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available equipment?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select everything you have access to for exercise substitute matching',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ...gear.map((g) {
            final isSelected = _selectedEquipment.contains(g.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedEquipment.remove(g.$1);
                    } else {
                      _selectedEquipment.add(g.$1);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.$2,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(g.$3, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 12: WEEKLY SCHEDULE & WORKOUT DAYS
  // ===========================================================================
  Widget _buildScreen12Schedule() {
    final daysOfWeek = [
      (1, 'Mon'),
      (2, 'Tue'),
      (3, 'Wed'),
      (4, 'Thu'),
      (5, 'Fri'),
      (6, 'Sat'),
      (7, 'Sun'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly schedule',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose your weekly workout frequency and designated workout days',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 24),
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Workout Days / Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
                      Text('$_weeklyWorkoutDays days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [2, 3, 4, 5, 6, 7].map((count) {
                      final isSelected = _weeklyWorkoutDays == count;
                      return GestureDetector(
                        onTap: () => setState(() => _weeklyWorkoutDays = count),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimary : kBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? kPrimary : kBorder),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.black : kTextPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Select Training Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysOfWeek.map((d) {
              final isSelected = _selectedWeekdays.contains(d.$1);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedWeekdays.remove(d.$1);
                    } else {
                      _selectedWeekdays.add(d.$1);
                    }
                  });
                },
                child: Container(
                  width: 42,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.15) : kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      d.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? kPrimary : kTextPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 13: SESSION DURATION
  // ===========================================================================
  Widget _buildScreen13Duration() {
    final durations = [
      (15, '⚡ 15 min Express', 'High-intensity circuit with zero downtime'),
      (30, '⏱️ 30 min Efficient', 'Dense superset format for tight schedules'),
      (45, '🎯 45 min Athletic (Recommended)', 'Optimal sweet spot for compound strength and hypertrophy'),
      (60, '🏋️ 60 min Complete', 'Comprehensive warm-up, core compounds and isolation finishers'),
      (90, '🦁 90 min Extended Power', 'Full powerlifting or bodybuilding volume splits'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session duration',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'We program your rest timers, total set volume and pacing to this duration',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ...durations.map((d) {
            final isSelected = _dailyWorkoutMinutes == d.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _dailyWorkoutMinutes = d.$1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.$2,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(d.$3, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 14: DIET STYLE & NUTRITION
  // ===========================================================================
  Widget _buildScreen14Diet() {
    final diets = [
      ('balanced', '🥗 Balanced Standard', '30% Protein, 40% Carbs, 30% Healthy Fats'),
      ('high_protein', '🥩 High Protein Clean', '40% Protein, 35% Carbs, 25% Fats for maximum muscle synthesis'),
      ('low_carb', '🥑 Low Carb / Keto', '30% Protein, 10% Carbs, 60% Fats for fat adaptation'),
      ('vegetarian', '🥦 Vegetarian', 'Plant-forward diet with eggs and dairy for complete amino acids'),
      ('vegan', '🌱 100% Vegan', 'Exclusively whole plant foods, grains, legumes and seeds'),
      ('mediterranean', '🐟 Mediterranean', 'Rich in omega-3 fatty acids, olive oil, greens and lean seafood'),
      ('fasting', '⏱️ Intermittent Fasting', 'Daily 16:8 or 18:6 structured eating window'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition & diet style',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Calculates customized daily protein, carb and healthy fat targets',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ...diets.map((d) {
            final isSelected = _selectedDiet == d.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDiet = d.$1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.$2,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(d.$3, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 15: MEALS COUNT & SCHEDULE
  // ===========================================================================
  Widget _buildScreen15Meals() {
    final mealOptions = [
      (2, '2 Meals / Day', 'Intermittent fasting structure (Brunch & Dinner)'),
      (3, '3 Meals / Day', 'Standard breakfast, lunch, and dinner pattern'),
      (4, '4 Meals / Day', '3 main meals + dedicated pre/post workout nutrition'),
      (5, '5+ Meals / Day', 'Frequent feeding split for high-volume bodybuilding'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily meal frequency',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'We distribute your total caloric budget across your daily meal times',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ...mealOptions.map((opt) {
            final isSelected = _mealsPerDay == opt.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _mealsPerDay = opt.$1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? kPrimary : kBorder,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.$2,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(opt.$3, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 16: HYDRATION TARGET & REMINDERS
  // ===========================================================================
  Widget _buildScreen16Hydration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily hydration target',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Muscle fibers are 76% water. Proper hydration prevents cramping and fatigue',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 36),
          Center(
            child: Column(
              children: [
                Text(
                  '${(_targetWaterMl / 1000).toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: kSecondary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_targetWaterMl ML PER DAY',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextSecondary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 24),
                InteractiveRulerSlider(
                  value: _targetWaterMl.toDouble(),
                  minValue: 1800.0,
                  maxValue: 4800.0,
                  step: 100.0,
                  unit: 'ml',
                  onChanged: (val) => setState(() => _targetWaterMl = val.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Water Reminder Interval', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [1, 2, 3].map((hours) {
              final isSelected = _reminderFrequencyHours == hours;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _reminderFrequencyHours = hours);
                      PermissionService.instance.requestReminderPermissions(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? kSecondary.withValues(alpha: 0.15) : kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? kSecondary : kBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Every $hours hr',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? kSecondary : kTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.bedtime_outlined, color: kTextSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Quiet hours: $_quietHoursStart – $_quietHoursEnd (no sleep interruptions)',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 17: LIFESTYLE, SLEEP & DAILY ACTIVITY
  // ===========================================================================
  Widget _buildScreen17Lifestyle() {
    final activities = [
      ('sedentary', '🪑 Sedentary (Desk job / minimal movement)'),
      ('lightly_active', '🚶 Lightly Active (1-3 hrs light walking daily)'),
      ('moderately_active', '⚡ Moderately Active (Regular daily activity)'),
      ('very_active', '🔥 Very Active (Heavy manual job or intense training)'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily routine & sleep',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Non-exercise activity thermogenesis (NEAT) and sleep duration',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          const Text('Daily Activity Level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 10),
          ...activities.map((act) {
            final isSelected = _activityLevel == act.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activityLevel = act.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withValues(alpha: 0.12) : kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? kPrimary : kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          act.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? kPrimary : kTextPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        size: 20,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text('Target Sleep Hours', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [6.0, 7.0, 8.0, 9.0].map((hours) {
              final isSelected = (_targetSleepHours - hours).abs() < 0.1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _targetSleepHours = hours),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary.withValues(alpha: 0.15) : kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? kPrimary : kBorder),
                      ),
                      child: Center(
                        child: Text(
                          '${hours.round()} hrs',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? kPrimary : kTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Daily Steps Goal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [6000, 8000, 10000, 12000].map((steps) {
              final isSelected = _dailyStepsGoal == steps;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _dailyStepsGoal = steps),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary.withValues(alpha: 0.15) : kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? kPrimary : kBorder),
                      ),
                      child: Center(
                        child: Text(
                          '${steps ~/ 1000}k',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? kPrimary : kTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 18: AI PLAN ANALYSIS & GENERATION TRANSITION
  // ===========================================================================
  Widget _buildScreen18Transition() {
    String stepText;
    if (_transitionProgress < 0.25) {
      stepText = 'Computing basal metabolic rate (BMR) & TDEE...';
    } else if (_transitionProgress < 0.50) {
      stepText = _selectedGender == 'female'
          ? 'Optimizing glute, waist & core volume distribution...'
          : 'Calibrating v-taper, pectoral & deltoid hypertrophy splits...';
    } else if (_transitionProgress < 0.75) {
      stepText = 'Structuring $_weeklyWorkoutDays-day training split for $_dailyWorkoutMinutes min sessions...';
    } else {
      stepText = 'Synthesizing customized macro targets & recovery protocol...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary.withValues(alpha: 0.1),
                border: Border.all(color: kPrimary.withValues(alpha: 0.3), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.fitness_center_rounded, size: 44, color: kPrimary),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Crafting your custom plan',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kTextPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              stepText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 36),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _transitionProgress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_transitionProgress * 100).toInt()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 19: CUSTOMIZED PLAN READY & ACTIVATION
  // ===========================================================================
  Widget _buildScreen19PlanReady() {
    final coachImg = _selectedGender == 'female'
        ? 'assets/images/setup/female_fitness_coach.png'
        : 'assets/images/setup/male_fitness_coach.png';
    final trainerImg = _selectedGender == 'female'
        ? 'assets/images/setup/female_fitness_trainer.png'
        : 'assets/images/setup/male_fitness_trainer.png';

    final calories = _selectedGoal == 'lose_weight'
        ? 1850
        : (_selectedGoal == 'build_muscle' ? 2450 : 2100);
    final protein = (_weightKg * 2.0).round();
    final fats = (_weightKg * 0.8).round();
    final carbs = ((calories - (protein * 4) - (fats * 9)) / 4).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.check_rounded, color: kPrimary, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your plan is ready!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Calibrated to your exact body composition and aesthetic targets',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 16),

          // Athlete summary banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                AppAvatar(
                  avatarId: _customProfileImagePath ?? _avatarId,
                  radius: 22,
                  name: _nameController.text.trim().isNotEmpty
                      ? _nameController.text.trim()
                      : 'Athlete',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : 'Athlete',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Protocol tailored for $_selectedGender • ${_useLbs ? '${_weightLbs.round()} lbs' : '${_weightKg.round()} kg'}',
                        style: const TextStyle(fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OPTIMIZED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Hero Plan Card
          Container(
            height: 230,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF132A1C), Color(0xFF0F1E16)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: 0,
                  top: 0,
                  child: Image.asset(
                    trainerImg,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CUSTOMIZED FOR YOU',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedGoal == 'lose_weight'
                            ? 'Lean Cut &\nDefinition'
                            : (_selectedGoal == 'build_muscle'
                                ? 'Hypertrophy &\nPower Mass'
                                : 'Athletic Longevity\n& Conditioning'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_weeklyWorkoutDays workouts / week • $_dailyWorkoutMinutes min',
                        style: const TextStyle(fontSize: 13, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Macro & Water Targets Row
          Row(
            children: [
              _buildTargetStatTile('CALORIES', '$calories', 'kcal/day'),
              const SizedBox(width: 8),
              _buildTargetStatTile('PROTEIN', '${protein}g', 'daily'),
              const SizedBox(width: 8),
              _buildTargetStatTile('CARBS', '${carbs}g', 'daily'),
              const SizedBox(width: 8),
              _buildTargetStatTile('FATS', '${fats}g', 'daily'),
            ],
          ),
          const SizedBox(height: 16),

          // Coach Row
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: kPrimary.withValues(alpha: 0.2),
                    backgroundImage: AssetImage(coachImg),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedGender == 'female' ? 'Coach Elena (Women\'s Specialization)' : 'Coach Marcus (Hypertrophy Lead)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Assigned to guide your progression and volume loading',
                          style: TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          PrimaryButton(
            text: 'START NOW',
            onPressed: () => _finishAndActivatePlan(),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => _finishAndActivatePlan(),
              child: const Text(
                'Go to homepage',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetStatTile(String title, String val, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kTextSecondary, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: kTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitToggle({
    required String option1,
    required String option2,
    required bool isOption1,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onToggle(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isOption1 ? kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                option1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOption1 ? Colors.black : kTextSecondary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onToggle(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: !isOption1 ? kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                option2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: !isOption1 ? Colors.black : kTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
