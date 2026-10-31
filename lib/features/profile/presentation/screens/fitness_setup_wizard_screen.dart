import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../../../../core/services/notification_service.dart';
import '../../../onboarding/presentation/widgets/animated_gender_selector.dart';
import '../../../onboarding/presentation/widgets/plan_summary_reveal_card.dart';
import 'package:uuid/uuid.dart';
import '../../../progress/domain/models/body_measurement.dart';
import '../../../progress/presentation/controllers/progress_providers.dart';
import '../../../../core/data/reminder_repository.dart';
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
// Locked Design Tokens
const Color kBackground = Color(0xFF0A0F0D);
const Color kSurface = Color(0xFF121A16);
const Color kPrimary = Color(0xFF00E676);
const Color kSecondary = Color(0xFF00E5FF);
const Color kTextPrimary = Color(0xFFF0F6F2);
const Color kTextSecondary = Color(0xFF8FA396);
const Color kBorder = Color(0xFF1F2D26);

class FitnessSetupWizardScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  final int initialScreen;

  const FitnessSetupWizardScreen({
    super.key,
    this.isInitialSetup = false,
    this.initialScreen = 0,
  });

  @override
  ConsumerState<FitnessSetupWizardScreen> createState() =>
      _FitnessSetupWizardScreenState();
}

class _FitnessSetupWizardScreenState
    extends ConsumerState<FitnessSetupWizardScreen>
    with SingleTickerProviderStateMixin {
  late int _currentScreen;
  static const int _totalScreens = 20;

  // Profile Identity & Avatar State
  late TextEditingController _nameController;
  String _avatarId = 'avatar_male_1';
  String? _customProfileImagePath;

  // Selected State
  String _selectedGender = 'male'; // 'male' or 'female'
  int _age = 0;

  // Height State
  bool _useFt = true;
  double _heightCm = 0.0;
  double _heightInches = 0.0;

  // Weight State
  bool _useLbs = true;
  double _weightKg = 0.0;
  double _weightLbs = 0.0;

  // Target Weight & Pace
  double _targetWeightKg = 0.0;
  double _targetWeightLbs = 0.0;
  double _targetPaceKgPerWeek = 0.5;

  // Body Composition (Optional)
  bool _useInches = false;
  double _bodyFatPercentage = 18.0;
  double? _waistCm;
  double? _hipCm;
  double? _chestCm;
  double? _neckCm;
  double? _armsCm;
  double? _thighsCm;
  double? _calvesCm;
  double? _shouldersCm;
  DateTime _measuredAt = DateTime.now();
  final TextEditingController _measurementNotesController =
      TextEditingController();
  late TextEditingController _weightInputController;
  late TextEditingController _bodyFatInputController;
  late TextEditingController _waistInputController;
  late TextEditingController _chestInputController;
  late TextEditingController _hipsInputController;
  late TextEditingController _armsInputController;
  late TextEditingController _thighsInputController;
  late TextEditingController _calvesInputController;
  late TextEditingController _neckInputController;
  late TextEditingController _shouldersInputController;

  // Schedule & Timing
  String _preferredWorkoutTime = '17:30';
  List<String> _mealTimes = ['08:30', '13:00', '20:00'];

  String _formatTimeString(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMinute $period';
      }
    } catch (_) {}
    return time24;
  }

  List<String> _getDefaultMealTimesForCount(int count) {
    switch (count) {
      case 2:
        return ['11:30', '19:30'];
      case 3:
        return ['08:30', '13:00', '20:00'];
      case 4:
        return ['08:00', '12:30', '16:30', '20:30'];
      case 5:
      default:
        return ['07:30', '10:30', '13:30', '17:00', '20:30'];
    }
  }

  List<String> _getMealNamesForCount(int count) {
    switch (count) {
      case 2:
        return ['Brunch / Meal 1', 'Dinner / Meal 2'];
      case 3:
        return ['Breakfast', 'Lunch', 'Dinner'];
      case 4:
        return ['Breakfast', 'Lunch', 'Pre/Post Workout Snack', 'Dinner'];
      case 5:
      default:
        return [
          'Breakfast',
          'Morning Fuel',
          'Lunch',
          'Afternoon Snack',
          'Dinner',
        ];
    }
  }

  // Goals
  String _selectedGoal =
      'build_muscle'; // 'lose_weight', 'build_muscle', 'keep_fit'
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
  String _experienceLevel =
      'intermediate'; // 'beginner', 'intermediate', 'advanced', 'athlete'
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
  String _preferredSleepTime = '22:00';
  int _dailyStepsGoal = 10000;
  final String _stressLevel = 'moderate';

  // Transition controller
  Timer? _transitionTimer;
  double _transitionProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentScreen = widget.initialScreen.clamp(0, _totalScreens - 1);

    // If an existing user who already finished setup is opened in initial setup mode,
    // do not force them through the wizard again — cancel notifications and redirect to home.
    if (widget.isInitialSetup) {
      final existingProfile = ref.read(userProfileProvider);
      final authState = ref.read(authProvider);
      if (existingProfile.isProfileSetupCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await NotificationService.instance.cancelWizardSetupNotifications();
          if (!mounted) return;
          context.go('/home');
        });
      } else if (authState.isAuthenticated && authState.user != null) {
        ref
            .read(startupGateServiceProvider)
            .isAccountOnboardingCompleted(authState.user!.id)
            .then((done) {
              if (done && mounted) {
                NotificationService.instance.cancelWizardSetupNotifications();
                context.go('/home');
              }
            })
            .catchError((_) {});
      }
    }

    if (widget.initialScreen == 0) {
      ref.read(startupGateServiceProvider).getWizardDraftStep().then((draft) {
        if (draft != null && draft > 0 && draft < _totalScreens && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentScreen = draft;
              });
            }
          });
        }
      });
    }

    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(
      text: profile.name == 'Guest Athlete' ? '' : profile.name,
    );
    if (profile.avatarId.startsWith('/') ||
        profile.avatarId.contains('image_picker')) {
      _customProfileImagePath = profile.avatarId;
    } else if (profile.avatarId.isNotEmpty && profile.avatarId != 'initial') {
      _avatarId = profile.avatarId;
    } else {
      _avatarId = profile.gender == 'female'
          ? 'avatar_female_1'
          : 'avatar_male_1';
    }

    _selectedGender = profile.gender;
    _age = profile.age > 0 ? profile.age.clamp(16, 99) : 0;
    _useLbs = !profile.useMetricUnits;
    _useFt = !profile.useMetricUnits;
    _useInches = !profile.useMetricUnits;

    final pWeight = profile.weightKg > 0 ? profile.weightKg : 0.0;
    final pHeight = profile.heightCm > 0 ? profile.heightCm : 0.0;
    _weightKg = pWeight;
    _heightCm = pHeight;
    _weightLbs = _weightKg > 0 ? _weightKg * 2.20462 : 0.0;
    _heightInches = _heightCm > 0 ? _heightCm / 2.54 : 0.0;

    final pTargetWeight =
        (profile.targetWeightKg != null && profile.targetWeightKg! > 0)
        ? profile.targetWeightKg!
        : _weightKg;
    _targetWeightKg = pTargetWeight > 0 ? pTargetWeight : 0.0;
    _targetWeightLbs = _targetWeightKg > 0 ? _targetWeightKg * 2.20462 : 0.0;
    _targetPaceKgPerWeek = profile.targetPaceKgPerWeek > 0
        ? profile.targetPaceKgPerWeek
        : 0.5;

    if (profile.fitnessGoal.isNotEmpty && profile.isProfileSetupCompleted) {
      _hasUserManuallySelectedGoal = true;
      _selectedGoal = profile.fitnessGoal == 'gain_weight'
          ? 'build_muscle'
          : (profile.fitnessGoal == 'maintain_weight'
                ? 'keep_fit'
                : profile.fitnessGoal);
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

    if (profile.waistCm != null) _waistCm = profile.waistCm;
    if (profile.hipCm != null) _hipCm = profile.hipCm;
    if (profile.chestCm != null) _chestCm = profile.chestCm;
    if (profile.neckCm != null) _neckCm = profile.neckCm;
    if (profile.armsCm != null) _armsCm = profile.armsCm;
    if (profile.thighsCm != null) _thighsCm = profile.thighsCm;
    if (profile.calvesCm != null) _calvesCm = profile.calvesCm;
    if (profile.shouldersCm != null) _shouldersCm = profile.shouldersCm;
    if (profile.bodyFatPercentage != null) {
      _bodyFatPercentage = profile.bodyFatPercentage!;
    }
    _initMeasurementControllers();
    if (profile.preferredWorkoutTime.isNotEmpty) {
      _preferredWorkoutTime = profile.preferredWorkoutTime;
    }
    if (profile.mealTimes.isNotEmpty) {
      _mealTimes = List<String>.from(profile.mealTimes);
    } else {
      _mealTimes = _getDefaultMealTimesForCount(_mealsPerDay);
    }

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
        final isAllSelected =
            _selectedFocusAreas.contains('full_body') ||
            _selectedFocusAreas.contains('full body') ||
            allPartIds.every(
              (id) =>
                  _selectedFocusAreas.contains(id) ||
                  (id == 'quads' &&
                      (_selectedFocusAreas.contains('leg') ||
                          _selectedFocusAreas.contains('legs'))) ||
                  (id == 'thighs' &&
                      (_selectedFocusAreas.contains('leg') ||
                          _selectedFocusAreas.contains('legs'))) ||
                  (id == 'arms' && _selectedFocusAreas.contains('arm')),
            );

        if (isAllSelected) {
          _selectedFocusAreas.clear();
        } else {
          _selectedFocusAreas.clear();
          _selectedFocusAreas.addAll(allPartIds);
          _selectedFocusAreas.add('full_body');
        }
      } else {
        final isCurrentlySelected =
            _selectedFocusAreas.contains(key) ||
            (key == 'quads' &&
                (_selectedFocusAreas.contains('leg') ||
                    _selectedFocusAreas.contains('legs'))) ||
            (key == 'thighs' &&
                (_selectedFocusAreas.contains('leg') ||
                    _selectedFocusAreas.contains('legs'))) ||
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
          final allSelected = allPartIds.every(
            (id) =>
                _selectedFocusAreas.contains(id) ||
                (id == 'quads' &&
                    (_selectedFocusAreas.contains('leg') ||
                        _selectedFocusAreas.contains('legs'))) ||
                (id == 'thighs' &&
                    (_selectedFocusAreas.contains('leg') ||
                        _selectedFocusAreas.contains('legs'))) ||
                (id == 'arms' && _selectedFocusAreas.contains('arm')),
          );
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
    _measurementNotesController.dispose();
    _weightInputController.dispose();
    _bodyFatInputController.dispose();
    _waistInputController.dispose();
    _chestInputController.dispose();
    _hipsInputController.dispose();
    _armsInputController.dispose();
    _thighsInputController.dispose();
    _calvesInputController.dispose();
    _neckInputController.dispose();
    _shouldersInputController.dispose();
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

  void _saveName(String name) {
    if (!mounted) return;
    final finalName = name.trim().isNotEmpty ? name.trim() : 'Athlete';
    setState(() {
      _nameController.text = finalName;
    });
    final baseProfile = ref.read(userProfileProvider);
    ref
        .read(userProfileProvider.notifier)
        .updateProfile(baseProfile.copyWith(name: finalName));
  }

  Future<void> _showSetNameSheet() async {
    final currentName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (ref.read(userProfileProvider).name.isNotEmpty &&
                  ref.read(userProfileProvider).name != 'Guest Athlete'
              ? ref.read(userProfileProvider).name
              : '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SetNameSheetContent(
          initialName: currentName,
          customProfileImagePath: _customProfileImagePath,
          avatarId: _avatarId,
          selectedGender: _selectedGender,
          onSaveName: (name) => _saveName(name),
          onPickAvatar: () async {
            await _pickProfilePhotoOrAvatar();
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  Future<void> _nextScreen() async {
    FocusScope.of(context).unfocus();
    if (_currentScreen == 5) {
      _syncMeasurementsFromControllers();
      _saveStep6Measurement().ignore();
    }
    if (_currentScreen == 16) {
      // Reminder delivery is intentionally foreground-only. There is no
      // notification or alarm permission to request here.
    }
    _syncGoalFromWeightsIfUntouched();
    if (_currentScreen < _totalScreens - 1) {
      setState(() {
        _currentScreen++;
        if (_currentScreen == 18) {
          _startTransitionTimer();
        }
      });
      ref.read(startupGateServiceProvider).saveWizardDraftStep(_currentScreen);
    } else {
      await _finishAndActivatePlan();
    }
  }

  void _previousScreen() {
    if (_currentScreen > 0) {
      setState(() => _currentScreen--);
      ref.read(startupGateServiceProvider).saveWizardDraftStep(_currentScreen);
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
    _transitionTimer = Timer.periodic(const Duration(milliseconds: 35), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _transitionProgress += 0.02;
        if (_transitionProgress >= 1.0) {
          timer.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentScreen == 18) _nextScreen();
          });
        }
      });
    });
  }

  Future<void> _handleExit() async {
    // Preserve draft progress
    try {
      await ref
          .read(startupGateServiceProvider)
          .saveWizardDraftStep(_currentScreen);
    } catch (_) {}

    final profile = ref.read(userProfileProvider);
    final authState = ref.read(authProvider);
    final isAuthUser = authState.isAuthenticated && authState.user != null;
    bool isAccountDone = false;
    if (isAuthUser) {
      try {
        isAccountDone = await ref
            .read(startupGateServiceProvider)
            .isAccountOnboardingCompleted(authState.user!.id);
      } catch (_) {}
    }
    final isNeverSetupBefore =
        !profile.isProfileSetupCompleted && !isAccountDone;

    if (isNeverSetupBefore) {
      // Condition 3: user skipped wizard screen and never setup before -> show notification to setup wizard
      try {
        await NotificationService.instance.showImmediateNotification(
          id: NotificationService.keyWizardSkipReminderId,
          title: 'Complete Your Fitness Setup 🎯',
          body:
              'Finish setting up your personalized goals and workout schedule to unlock tailored plans.',
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );

        await NotificationService.instance.scheduleNotification(
          id: NotificationService.keyWizardFollowupReminderId,
          title: 'Your Fitness Plan Is Waiting ⚡',
          body:
              'Take 2 minutes to complete your setup wizard and get your customized workout split.',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
          channel: NotificationChannelType.habits,
          payload: '/setup-wizard',
        );
      } catch (e) {
        debugPrint('[FitnessSetupWizard] Skip notification error: $e');
      }

      // Mark that user skipped wizard so startup gate routes them to /home instead of looping
      try {
        await ref.read(startupGateServiceProvider).setWizardSkipped(true);
        if (isAuthUser) {
          await ref
              .read(startupGateServiceProvider)
              .setAccountOnboardingCompleted(authState.user!.id, true);
        } else {
          await ref
              .read(startupGateServiceProvider)
              .setGuestOnboardingCompleted(true);
        }
      } catch (_) {}
    } else {
      // Existing user exiting wizard -> ensure no wizard reminders are scheduled or kept
      await NotificationService.instance.cancelWizardSetupNotifications();
    }

    if (mounted) {
      try {
        context.go('/home');
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _finishAndActivatePlan({
    bool navigateToSignUp = false,
    bool navigateToSignIn = false,
  }) async {
    final finalWeightKg = _useLbs ? (_weightLbs / 2.20462) : _weightKg;
    final finalHeightCm = _useFt ? (_heightInches * 2.54) : _heightCm;
    final finalTargetWeightKg = _useLbs
        ? (_targetWeightLbs / 2.20462)
        : _targetWeightKg;

    final baseProfile = ref.read(userProfileProvider);
    final chosenName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (baseProfile.name.isNotEmpty && baseProfile.name != 'Guest Athlete'
              ? baseProfile.name
              : 'Athlete');
    final chosenAvatarId = _customProfileImagePath ?? _avatarId;

    final updatedProfile =
        UserProfile.calculateSuggestedTargets(
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
          customTargetNote:
              'Personalized via 20-step setup wizard. Focus: ${_selectedFocusAreas.join(', ')}.',
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
          armsCm: _armsCm,
          thighsCm: _thighsCm,
          calvesCm: _calvesCm,
          shouldersCm: _shouldersCm,
          preferredWorkoutTime: _preferredWorkoutTime,
          mealTimes: _mealTimes,
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
    await _saveConfiguredReminders();

    // Save initial baseline body measurement into Drift database
    try {
      final baselineMeasurement = BodyMeasurement(
        id: const Uuid().v4(),
        userId: ref.read(authProvider).user?.id ?? 'guest',
        measuredAt: DateTime.now(),
        weightKg: finalWeightKg,
        bodyFatPercentage: _bodyFatPercentage,
        waistCm: _waistCm,
        chestCm: _chestCm,
        hipsCm: _hipCm,
        armsCm: _armsCm,
        thighsCm: _thighsCm,
        calvesCm: _calvesCm,
        neckCm: _neckCm,
        shouldersCm: _shouldersCm,
        notes: _measurementNotesController.text.trim().isNotEmpty
            ? _measurementNotesController.text.trim()
            : 'Initial setup baseline',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await ref
          .read(bodyMeasurementRepositoryProvider)
          .recordMeasurement(baselineMeasurement);
    } catch (_) {}
    try {
      await ref
          .read(authProvider.notifier)
          .updateUserProfileMetadata(
            name: chosenName,
            avatarUrl: chosenAvatarId,
          );
    } catch (_) {}
    try {
      await ref.read(startupGateServiceProvider).clearWizardDraftStep();
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final user = authState.user;
      if (isAuth && user != null) {
        await ref
            .read(startupGateServiceProvider)
            .setAccountOnboardingCompleted(user.id, true);
        await ref.read(startupGateServiceProvider).setAuthDecisionMade(true);
      } else {
        await ref
            .read(startupGateServiceProvider)
            .setFirstLaunchCompleted(true);
        await ref
            .read(startupGateServiceProvider)
            .setGuestOnboardingCompleted(true);
      }
      await NotificationService.instance.cancelWizardSetupNotifications();
    } catch (_) {}

    if (mounted) {
      if (navigateToSignUp) {
        context.go('/auth/sign-up');
      } else if (navigateToSignIn) {
        context.go('/auth/sign-in');
      } else {
        final permDone = await ref
            .read(permissionServiceProvider)
            .hasCompletedPermissionSetup();
        if (!permDone && mounted) {
          context.go('/permission-settings?postOnboarding=true');
        } else if (mounted) {
          context.go('/home');
        }
      }
    }
  }

  Future<void> _saveConfiguredReminders() async {
    final repository = ref.read(reminderRepositoryProvider);
    final now = DateTime.now();
    final existing = await repository.getAllReminders();

    Future<void> save({
      required String title,
      required ReminderCategory category,
      required String time,
      ReminderRecurrence recurrence = ReminderRecurrence.daily,
      List<int> repeatDays = const [],
    }) async {
      final match = existing.where(
        (item) =>
            item.title == title &&
            item.category == category &&
            item.timeOfDay == time,
      );
      final current = match.isEmpty ? null : match.first;
      await repository.createReminder(
        Reminder(
          id: current?.id ?? const Uuid().v4(),
          title: title,
          category: category,
          timeOfDay: time,
          recurrence: recurrence,
          repeatDays: repeatDays,
          isEnabled: current?.isEnabled ?? true,
          createdAt: current?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    await save(
      title: 'Workout time',
      category: ReminderCategory.workout,
      time: _preferredWorkoutTime,
      recurrence: ReminderRecurrence.custom,
      repeatDays: _selectedWeekdays.toList()..sort(),
    );
    final mealNames = _getMealNamesForCount(_mealsPerDay);
    for (var index = 0; index < _mealTimes.length; index++) {
      await save(
        title: '${mealNames[index]} time',
        category: ReminderCategory.meal,
        time: _mealTimes[index],
      );
    }
    await save(
      title: 'Sleep wind-down',
      category: ReminderCategory.sleep,
      time: _preferredSleepTime,
    );
    for (var hour = 8; hour <= 20; hour += _reminderFrequencyHours) {
      await save(
        title: 'Drink water',
        category: ReminderCategory.hydration,
        time: '${hour.toString().padLeft(2, '0')}:00',
      );
    }
  }

  bool _isStepSkippable(int screenIndex) {
    // Every step can be skipped individually except the final AI generation transition and plan ready screen
    return screenIndex < _totalScreens - 2;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _previousScreen();
      },
      child: Scaffold(
        backgroundColor: kBackground,
        bottomNavigationBar: _currentScreen < 18
            ? SafeArea(top: false, child: _buildBottomActionBar())
            : null,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top App Bar Navigation Header (Screens 0 to 17)
              if (_currentScreen < 18) _buildTopNavigationHeader(),

              // Animated Screen Transition
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
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
              ),
            ],
          ),
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
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: kTextPrimary,
                ),
                onPressed: _previousScreen,
                tooltip: 'Back',
              ),
              const Spacer(),

              // Step counter pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: kTextSecondary,
                ),
                onPressed: _handleExit,
                tooltip: 'Exit Setup',
              ),
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
    final isStep6 = _currentScreen == 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: kBackground,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: PrimaryButton(
        key: isStep6 ? const ValueKey('save_measurement_button') : null,
        text: isStep6 ? 'Save Measurement' : 'NEXT',
        onPressed: _nextScreen,
      ),
    );
  }

  // ===========================================================================
  // SCREEN 0: GENDER SELECTION
  // ===========================================================================
  Widget _buildScreen0Gender() {
    return Column(
      children: [
        // Compact Athlete Profile Row (Preserves avatar & name editing)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: _showSetNameSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePhotoOrAvatar,
                        child: AppAvatar(
                          avatarId: _customProfileImagePath ?? _avatarId,
                          radius: 12,
                          name: _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : 'Athlete',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : 'Set Name',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Animated Hero Gender Selector (Matches Screenshot 1)
        AnimatedGenderSelector(
          selectedGender: _selectedGender,
          showPreferNotToSay: false,
          heading: "What's your gender?",
          subtitle: 'Let us know you better',
          onGenderSelected: (genderValue) {
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
        ),
      ],
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
      zoneDesc =
          'High natural testosterone/GH and rapid muscular recovery response.';
    } else if (_age < 40) {
      zoneBadge = 'Prime Athletic Performance';
      zoneDesc =
          'Ideal neuromuscular coordination with focused strength potential.';
    } else if (_age < 55) {
      zoneBadge = 'Metabolic Optimization & Joint Longevity';
      zoneDesc =
          'Targeting tendon elasticity, visceral fat reduction and lean retention.';
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                InteractiveRulerSlider(
                  key: const ValueKey('ruler_age'),
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
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: kSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zoneBadge,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zoneDesc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
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

  Future<void> _showDirectHeightInputDialog() async {
    final ftValue = (_heightInches / 12).floor();
    final inValue = (_heightInches % 12).round();
    final ftCtrl = TextEditingController(text: ftValue.toString());
    final inCtrl = TextEditingController(text: inValue.toString());
    final cmCtrl = TextEditingController(text: _heightCm.round().toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Exact Height',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _useFt
                  ? 'Enter feet and inches:'
                  : 'Enter height in centimeters (90 - 250 cm):',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (_useFt)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ftCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'ft',
                        suffixStyle: const TextStyle(
                          fontSize: 16,
                          color: kPrimary,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: inCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'in',
                        suffixStyle: const TextStyle(
                          fontSize: 16,
                          color: kPrimary,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              TextField(
                controller: cmCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
                decoration: InputDecoration(
                  suffixText: 'cm',
                  suffixStyle: const TextStyle(fontSize: 16, color: kPrimary),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_useFt) {
                final ft = int.tryParse(ftCtrl.text.trim()) ?? 5;
                final inch = int.tryParse(inCtrl.text.trim()) ?? 9;
                final totalInches = (ft * 12.0 + inch).clamp(36.0, 96.0);
                setState(() {
                  _heightInches = totalInches;
                  _heightCm = totalInches * 2.54;
                });
              } else {
                final cm = double.tryParse(cmCtrl.text.trim()) ?? 0.0;
                final clampedCm = cm.clamp(90.0, 250.0);
                setState(() {
                  _heightCm = clampedCm;
                  _heightInches = clampedCm / 2.54;
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Set Height'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDirectWeightInputDialog() async {
    final weightCtrl = TextEditingController(
      text: _useLbs
          ? _weightLbs.toStringAsFixed(1)
          : _weightKg.toStringAsFixed(1),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Current Weight',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter weight in ${_useLbs ? 'lbs (66 - 550)' : 'kg (30 - 250)'}:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
              decoration: InputDecoration(
                suffixText: _useLbs ? 'lbs' : 'kg',
                suffixStyle: const TextStyle(fontSize: 16, color: kPrimary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(weightCtrl.text.trim());
              if (val != null) {
                setState(() {
                  if (_useLbs) {
                    final clamped = val.clamp(66.0, 550.0);
                    _weightLbs = clamped;
                    _weightKg = clamped / 2.20462;
                  } else {
                    final clamped = val.clamp(30.0, 250.0);
                    _weightKg = clamped;
                    _weightLbs = clamped * 2.20462;
                  }
                  _syncWeightInputController();
                  _syncGoalFromWeightsIfUntouched();
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Set Weight'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDirectTargetWeightInputDialog() async {
    final targetCtrl = TextEditingController(
      text: _useLbs
          ? _targetWeightLbs.toStringAsFixed(1)
          : _targetWeightKg.toStringAsFixed(1),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Target Weight',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter target weight in ${_useLbs ? 'lbs (66 - 550)' : 'kg (30 - 250)'}:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kSecondary,
              ),
              decoration: InputDecoration(
                suffixText: _useLbs ? 'lbs' : 'kg',
                suffixStyle: const TextStyle(fontSize: 16, color: kSecondary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(targetCtrl.text.trim());
              if (val != null) {
                setState(() {
                  if (_useLbs) {
                    final clamped = val.clamp(66.0, 550.0);
                    _targetWeightLbs = clamped;
                    _targetWeightKg = clamped / 2.20462;
                  } else {
                    final clamped = val.clamp(30.0, 250.0);
                    _targetWeightKg = clamped;
                    _targetWeightLbs = clamped * 2.20462;
                  }
                  _syncGoalFromWeightsIfUntouched();
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Set Target'),
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
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
                InkWell(
                  onTap: _showDirectHeightInputDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _useFt
                              ? "$ftValue' $inValue\""
                              : '${_heightCm.round()} cm',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: kPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: kPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _useFt
                      ? 'FEET & INCHES (TAP TO TYPE)'
                      : 'CENTIMETERS (TAP TO TYPE)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
                InteractiveRulerSlider(
                  key: ValueKey('ruler_height_$_useFt'),
                  value: _useFt ? _heightInches : _heightCm,
                  minValue: _useFt ? 36.0 : 90.0,
                  maxValue: _useFt ? 96.0 : 250.0,
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              _buildUnitToggle(
                option1: 'lbs',
                option2: 'kg',
                isOption1: _useLbs,
                onToggle: (val) {
                  setState(() {
                    _useLbs = val;
                    _syncWeightInputController();
                  });
                },
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
                InkWell(
                  onTap: _showDirectWeightInputDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _useLbs
                              ? _weightLbs.toStringAsFixed(1)
                              : _weightKg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: kPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: kPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _useLbs ? 'POUNDS (TAP TO TYPE)' : 'KILOGRAMS (TAP TO TYPE)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 28),
                InteractiveRulerSlider(
                  key: ValueKey('ruler_weight_$_useLbs'),
                  value: _useLbs ? _weightLbs : _weightKg,
                  minValue: _useLbs ? 66.0 : 30.0,
                  maxValue: _useLbs ? 550.0 : 250.0,
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
                      _syncWeightInputController();
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
                  const Text(
                    'Calculated BMI',
                    style: TextStyle(fontSize: 14, color: kTextSecondary),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kPrimary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${bmi.toStringAsFixed(1)} • $bmiCategory',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
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
    final estimatedWeeks = _targetPaceKgPerWeek > 0
        ? (diffKg / _targetPaceKgPerWeek).ceil()
        : 8;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target weight & pace',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                InkWell(
                  onTap: _showDirectTargetWeightInputDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _useLbs
                              ? _targetWeightLbs.toStringAsFixed(1)
                              : _targetWeightKg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: kSecondary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: kSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _useLbs
                      ? 'TARGET POUNDS (TAP TO TYPE)'
                      : 'TARGET KILOGRAMS (TAP TO TYPE)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                InteractiveRulerSlider(
                  key: ValueKey('ruler_target_weight_$_useLbs'),
                  value: _useLbs ? _targetWeightLbs : _targetWeightKg,
                  minValue: _useLbs ? 66.0 : 30.0,
                  maxValue: _useLbs ? 550.0 : 250.0,
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
          const Text(
            'Weekly Desired Pace',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
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
                  color: isSelected
                      ? kPrimary.withValues(alpha: 0.8)
                      : kTextSecondary,
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
    if (_weightInputController.text.isEmpty && _weightKg > 0) {
      _weightInputController.text = _useLbs
          ? _weightLbs.toStringAsFixed(1)
          : _weightKg.toStringAsFixed(1);
    }
    if (_bodyFatInputController.text.isEmpty && _bodyFatPercentage > 0) {
      _bodyFatInputController.text = _bodyFatPercentage % 1 == 0
          ? _bodyFatPercentage.toInt().toString()
          : _bodyFatPercentage.toStringAsFixed(1);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordMeasurementsHeader(),
          const SizedBox(height: 20),
          _buildPrimaryMetricsSection(),
          const SizedBox(height: 20),
          _buildCircumferenceTapeSection(),
          const SizedBox(height: 16),
          _buildMeasurementNotesField(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecordMeasurementsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Measurements',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Optional: Calibrate your baseline metrics',
                style: TextStyle(fontSize: 13, color: kTextSecondary),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _measuredAt,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (picked != null) {
              setState(() => _measuredAt = picked);
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            foregroundColor: AppColors.electricBlue,
          ),
          child: Text(
            DateFormat('MMM d, y').format(_measuredAt),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.electricBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Metrics',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMeasurementInputField(
                controller: _weightInputController,
                label: 'Weight',
                suffix: _useLbs ? 'lbs' : 'kg',
                icon: Icons.scale_rounded,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      if (_useLbs) {
                        _weightLbs = parsed;
                        _weightKg = parsed / 2.20462;
                      } else {
                        _weightKg = parsed;
                        _weightLbs = parsed * 2.20462;
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMeasurementInputField(
                controller: _bodyFatInputController,
                label: 'Body Fat',
                suffix: '%',
                icon: Icons.pie_chart_outline_rounded,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  if (parsed != null && parsed >= 0) {
                    setState(() {
                      _bodyFatPercentage = parsed.clamp(3.0, 60.0);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircumferenceTapeSection() {
    final unit = _useInches ? 'in' : 'cm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _useInches
                  ? 'Circumference Tape (in)'
                  : 'Circumference Tape (cm)',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            _buildUnitToggle(
              option1: 'in',
              option2: 'cm',
              isOption1: _useInches,
              onToggle: (val) {
                setState(() {
                  _useInches = val;
                  _syncCircumferenceControllers();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 1: Waist, Chest
        Row(
          children: [
            Expanded(
              child: _buildMeasurementInputField(
                controller: _waistInputController,
                label: 'Waist',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _waistCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMeasurementInputField(
                controller: _chestInputController,
                label: 'Chest',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _chestCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Hips, Arms / Biceps
        Row(
          children: [
            Expanded(
              child: _buildMeasurementInputField(
                controller: _hipsInputController,
                label: 'Hips',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _hipCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMeasurementInputField(
                controller: _armsInputController,
                label: 'Arms / Biceps',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _armsCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Thighs, Calves
        Row(
          children: [
            Expanded(
              child: _buildMeasurementInputField(
                controller: _thighsInputController,
                label: 'Thighs',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _thighsCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMeasurementInputField(
                controller: _calvesInputController,
                label: 'Calves',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _calvesCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 4: Neck, Shoulders
        Row(
          children: [
            Expanded(
              child: _buildMeasurementInputField(
                controller: _neckInputController,
                label: 'Neck',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _neckCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMeasurementInputField(
                controller: _shouldersInputController,
                label: 'Shoulders',
                suffix: unit,
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    _shouldersCm = parsed != null
                        ? (_useInches ? parsed * 2.54 : parsed)
                        : null;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementNotesField() {
    return TextFormField(
      controller: _measurementNotesController,
      maxLines: 2,
      style: const TextStyle(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        labelText: 'Notes (e.g. morning fasted weigh-in)',
        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
        floatingLabelStyle: const TextStyle(
          color: AppColors.electricBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFF161F1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.electricBlue,
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildMeasurementInputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    IconData? icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
        floatingLabelStyle: const TextStyle(
          color: AppColors.electricBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: kTextSecondary)
            : null,
        filled: true,
        fillColor: const Color(0xFF161F1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.electricBlue,
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _initMeasurementControllers() {
    _weightInputController = TextEditingController(
      text: _useLbs
          ? _weightLbs.toStringAsFixed(1)
          : _weightKg.toStringAsFixed(1),
    );
    _bodyFatInputController = TextEditingController(
      text: _bodyFatPercentage > 0
          ? (_bodyFatPercentage % 1 == 0
                ? _bodyFatPercentage.toInt().toString()
                : _bodyFatPercentage.toStringAsFixed(1))
          : '',
    );
    _waistInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_waistCm),
    );
    _chestInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_chestCm),
    );
    _hipsInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_hipCm),
    );
    _armsInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_armsCm),
    );
    _thighsInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_thighsCm),
    );
    _calvesInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_calvesCm),
    );
    _neckInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_neckCm),
    );
    _shouldersInputController = TextEditingController(
      text: _formatCircumferenceDisplay(_shouldersCm),
    );
  }

  void _syncWeightInputController() {
    final value = _useLbs ? _weightLbs : _weightKg;
    if (value > 0 && _weightInputController.text != value.toStringAsFixed(1)) {
      _weightInputController.text = value.toStringAsFixed(1);
    }
  }

  String _formatCircumferenceDisplay(double? cm) {
    if (cm == null || cm <= 0) return '';
    if (_useInches) {
      final val = ((cm / 2.54) * 10).round() / 10;
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
    } else {
      final val = (cm * 10).round() / 10;
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
    }
  }

  void _syncCircumferenceControllers() {
    _waistInputController.text = _formatCircumferenceDisplay(_waistCm);
    _chestInputController.text = _formatCircumferenceDisplay(_chestCm);
    _hipsInputController.text = _formatCircumferenceDisplay(_hipCm);
    _armsInputController.text = _formatCircumferenceDisplay(_armsCm);
    _thighsInputController.text = _formatCircumferenceDisplay(_thighsCm);
    _calvesInputController.text = _formatCircumferenceDisplay(_calvesCm);
    _neckInputController.text = _formatCircumferenceDisplay(_neckCm);
    _shouldersInputController.text = _formatCircumferenceDisplay(_shouldersCm);
  }

  void _syncMeasurementsFromControllers() {
    final weightParsed = double.tryParse(_weightInputController.text.trim());
    if (weightParsed != null && weightParsed > 0) {
      if (_useLbs) {
        _weightLbs = weightParsed;
        _weightKg = weightParsed / 2.20462;
      } else {
        _weightKg = weightParsed;
        _weightLbs = weightParsed * 2.20462;
      }
    }

    final bfParsed = double.tryParse(_bodyFatInputController.text.trim());
    if (bfParsed != null && bfParsed >= 0) {
      _bodyFatPercentage = bfParsed.clamp(3.0, 60.0);
    }

    _waistCm = _parseCircumferenceInput(_waistInputController.text);
    _chestCm = _parseCircumferenceInput(_chestInputController.text);
    _hipCm = _parseCircumferenceInput(_hipsInputController.text);
    _armsCm = _parseCircumferenceInput(_armsInputController.text);
    _thighsCm = _parseCircumferenceInput(_thighsInputController.text);
    _calvesCm = _parseCircumferenceInput(_calvesInputController.text);
    _neckCm = _parseCircumferenceInput(_neckInputController.text);
    _shouldersCm = _parseCircumferenceInput(_shouldersInputController.text);
  }

  double? _parseCircumferenceInput(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null || parsed <= 0) return null;
    return _useInches ? parsed * 2.54 : parsed;
  }

  Future<void> _saveStep6Measurement() async {
    try {
      final finalWeightKg = _useLbs ? _weightLbs / 2.20462 : _weightKg;
      final measurement = BodyMeasurement(
        id: const Uuid().v4(),
        userId: ref.read(authProvider).user?.id ?? 'guest',
        measuredAt: _measuredAt,
        weightKg: finalWeightKg > 0 ? finalWeightKg : null,
        bodyFatPercentage: _bodyFatPercentage > 0 ? _bodyFatPercentage : null,
        waistCm: _waistCm,
        chestCm: _chestCm,
        hipsCm: _hipCm,
        armsCm: _armsCm,
        thighsCm: _thighsCm,
        calvesCm: _calvesCm,
        neckCm: _neckCm,
        shouldersCm: _shouldersCm,
        notes: _measurementNotesController.text.trim().isNotEmpty
            ? _measurementNotesController.text.trim()
            : null,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      // Only record if at least one metric has a value
      if (measurement.weightKg != null ||
          measurement.bodyFatPercentage != null ||
          measurement.waistCm != null ||
          measurement.chestCm != null ||
          measurement.hipsCm != null ||
          measurement.armsCm != null ||
          measurement.thighsCm != null ||
          measurement.calvesCm != null ||
          measurement.neckCm != null ||
          measurement.shouldersCm != null) {
        await ref
            .read(bodyMeasurementRepositoryProvider)
            .recordMeasurement(measurement);
      }

      // Also persist to current user profile
      final currentProfile = ref.read(userProfileProvider);
      final updatedProfile = currentProfile.copyWith(
        weightKg: finalWeightKg > 0 ? finalWeightKg : currentProfile.weightKg,
        bodyFatPercentage: _bodyFatPercentage > 0
            ? _bodyFatPercentage
            : currentProfile.bodyFatPercentage,
        waistCm: _waistCm ?? currentProfile.waistCm,
        hipCm: _hipCm ?? currentProfile.hipCm,
        chestCm: _chestCm ?? currentProfile.chestCm,
        neckCm: _neckCm ?? currentProfile.neckCm,
        armsCm: _armsCm ?? currentProfile.armsCm,
        thighsCm: _thighsCm ?? currentProfile.thighsCm,
        calvesCm: _calvesCm ?? currentProfile.calvesCm,
        shouldersCm: _shouldersCm ?? currentProfile.shouldersCm,
      );
      await ref
          .read(userProfileProvider.notifier)
          .updateProfile(updatedProfile);
    } catch (_) {}
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
            subtitle:
                'Hypertrophy-focused training for dense muscular development',
            imageAsset: buildMuscleImg,
            isSelected: _selectedGoal == 'build_muscle',
            onTap: () => setState(() => _selectedGoal = 'build_muscle'),
          ),
          GoalSelectionCard(
            title: 'Keep Fit',
            subtitle:
                'Cardiovascular endurance, mobility and functional stamina',
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
            (
              'booty_lift',
              '🍑 Lifted Booty & Glutes',
              'Target gluteus maximus & medius for firm projection',
            ),
            (
              'hourglass',
              '⏳ Hourglass & Flat Stomach',
              'Deep core activation and slender waistline tapering',
            ),
            (
              'lean_thighs',
              '🦵 Lean Thighs & Sculpted Calves',
              'Elongated, toned leg lines without bulky quad mass',
            ),
            (
              'toned_arms',
              '💪 Sleek Arms & Back Posture',
              'Defined shoulders, upright posture, zero batwings',
            ),
            (
              'radiance',
              '✨ Metabolic Glow & Vitality',
              'High daily energy, cellular hydration, active fat burning',
            ),
          ]
        : [
            (
              'v_taper',
              '🦅 V-Taper Broad Back',
              'Wide upper latissimus dorsi and narrow athletic waistline',
            ),
            (
              'chiseled_chest',
              '🛡️ Chiseled Chest & Arm Peaks',
              'Upper pectoral density and prominent bicep/tricep heads',
            ),
            (
              'six_pack',
              '⚡ Six-Pack Abs & Serratus',
              'Direct core flexion, low visceral fat, etched midsection',
            ),
            (
              'power_legs',
              '🦵 Athletic Quads & Hamstrings',
              'Teardrop quad definition and explosive lower body chain',
            ),
            (
              'total_mass',
              '🦁 Total Muscular Mass & Power',
              'Maximum progressive overload and total body hypertrophy',
            ),
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFemale ? 'Female aesthetic focus' : 'Male aesthetic focus',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
      (
        'beginner',
        'Beginner',
        'Learning basic lifting mechanics & form (< 6 months)',
      ),
      (
        'intermediate',
        'Intermediate',
        'Consistent compound training for 6 months – 2 years',
      ),
      (
        'advanced',
        'Advanced',
        'Solid progressive overload foundation (2+ years)',
      ),
      (
        'athlete',
        'Competitive Athlete',
        'High-volume periodization and maximum output',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your experience?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                            Text(
                              lvl.$3,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
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
      (
        'gym',
        '🏋️ Commercial Gym',
        'Full access to barbells, squat racks, cable towers and machines',
      ),
      (
        'home',
        '🏠 Home Gym',
        'Dedicated home workout space with personal gear',
      ),
      (
        'outdoors',
        '🌲 Outdoors & Parks',
        'Open-air bodyweight, running, pull-up bars and calisthenics',
      ),
      (
        'travel',
        '✈️ Travel & Hotel',
        'Minimal space, hotel room friendly and portable routines',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where will you train?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                            Text(
                              loc.$3,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
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
      (
        'full_gym',
        '🔩 Full Gym Equipment',
        'Barbells, power racks, cable crossovers, leg press',
      ),
      (
        'dumbbells',
        '🏋️ Dumbbells & Bench',
        'Adjustable or hex dumbbells with adjustable incline bench',
      ),
      (
        'bands',
        '🪢 Resistance Bands & Bar',
        'Loop bands, door anchors, pull-up bar',
      ),
      (
        'bodyweight',
        '🧘 Bodyweight Only',
        'Zero equipment required, calisthenics & core work',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available equipment?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                            Text(
                              g.$3,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                      const Expanded(
                        child: Text(
                          'Workout Days / Week',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_weeklyWorkoutDays days',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [2, 3, 4, 5, 6, 7].map((count) {
                      final isSelected = _weeklyWorkoutDays == count;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _weeklyWorkoutDays = count),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimary : kBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? kPrimary : kBorder,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.black
                                        : kTextPrimary,
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
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Training Days',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
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
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.15)
                        : kSurface,
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
          const SizedBox(height: 24),
          const Text(
            'Regular Workout Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose your usual workout time to calibrate notifications & nutrition timing',
            style: TextStyle(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  ('07:00', '🌅 Morning (7:00 AM)'),
                  ('12:30', '☀️ Midday (12:30 PM)'),
                  ('17:30', '🌆 Evening (5:30 PM)'),
                  ('20:30', '🌙 Night (8:30 PM)'),
                ].map((preset) {
                  final isPresetSelected = _preferredWorkoutTime == preset.$1;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _preferredWorkoutTime = preset.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isPresetSelected
                            ? kPrimary.withValues(alpha: 0.18)
                            : kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPresetSelected ? kPrimary : kBorder,
                          width: isPresetSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Text(
                        preset.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isPresetSelected ? kPrimary : kTextPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
          CardShell(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final parts = _preferredWorkoutTime.split(':');
                final initialH = int.tryParse(parts.first) ?? 17;
                final initialM = int.tryParse(parts.last) ?? 30;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: initialH, minute: initialM),
                );
                if (picked != null) {
                  setState(() {
                    _preferredWorkoutTime =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: kPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Workout Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeString(_preferredWorkoutTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      color: kTextSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
      (
        45,
        '🎯 45 min Athletic (Recommended)',
        'Optimal sweet spot for compound strength and hypertrophy',
      ),
      (
        60,
        '🏋️ 60 min Complete',
        'Comprehensive warm-up, core compounds and isolation finishers',
      ),
      (
        90,
        '🦁 90 min Extended Power',
        'Full powerlifting or bodybuilding volume splits',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session duration',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                            Text(
                              d.$3,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
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
      (
        'balanced',
        '🥗 Balanced Standard',
        '30% Protein, 40% Carbs, 30% Healthy Fats',
      ),
      (
        'high_protein',
        '🥩 High Protein Clean',
        '40% Protein, 35% Carbs, 25% Fats for maximum muscle synthesis',
      ),
      (
        'low_carb',
        '🥑 Low Carb / Keto',
        '30% Protein, 10% Carbs, 60% Fats for fat adaptation',
      ),
      (
        'vegetarian',
        '🥦 Vegetarian',
        'Plant-forward diet with eggs and dairy for complete amino acids',
      ),
      (
        'vegan',
        '🌱 100% Vegan',
        'Exclusively whole plant foods, grains, legumes and seeds',
      ),
      (
        'mediterranean',
        '🐟 Mediterranean',
        'Rich in omega-3 fatty acids, olive oil, greens and lean seafood',
      ),
      (
        'fasting',
        '⏱️ Intermittent Fasting',
        'Daily 16:8 or 18:6 structured eating window',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition & diet style',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                            Text(
                              d.$3,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
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
      (
        4,
        '4 Meals / Day',
        '3 main meals + dedicated pre/post workout nutrition',
      ),
      (
        5,
        '5+ Meals / Day',
        'Frequent feeding split for high-volume bodybuilding',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily meal frequency',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                onTap: () => setState(() {
                  _mealsPerDay = opt.$1;
                  _mealTimes = _getDefaultMealTimesForCount(opt.$1);
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                            Text(
                              opt.$3,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: isSelected ? kPrimary : kTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Meal Timing Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Personalized schedule for $_mealsPerDay meals. Tap any time to customize.',
            style: const TextStyle(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 12),
          ...List.generate(_mealTimes.length, (idx) {
            final mealNames = _getMealNamesForCount(_mealsPerDay);
            final mealName = idx < mealNames.length
                ? mealNames[idx]
                : 'Meal ${idx + 1}';
            final timeStr = _mealTimes[idx];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CardShell(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final parts = timeStr.split(':');
                    final initialH = int.tryParse(parts.first) ?? 8;
                    final initialM = int.tryParse(parts.last) ?? 0;
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: initialH, minute: initialM),
                    );
                    if (picked != null) {
                      setState(() {
                        _mealTimes[idx] =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            mealName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: kSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTimeString(timeStr),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                InteractiveRulerSlider(
                  key: const ValueKey('ruler_hydration'),
                  value: _targetWaterMl.toDouble(),
                  minValue: 1800.0,
                  maxValue: 4800.0,
                  step: 100.0,
                  unit: 'ml',
                  onChanged: (val) =>
                      setState(() => _targetWaterMl = val.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Water Reminder Interval',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
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
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kSecondary.withValues(alpha: 0.15)
                            : kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? kSecondary : kBorder,
                        ),
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
                  const Icon(
                    Icons.bedtime_outlined,
                    color: kTextSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Quiet hours: $_quietHoursStart – $_quietHoursEnd (no sleep interruptions)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
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

  Future<void> _showCustomSleepDialog() async {
    final ctrl = TextEditingController(text: _targetSleepHours.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Custom Sleep Goal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter target sleep duration in hours (4.0 - 14.0 hrs):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
              decoration: InputDecoration(
                suffixText: 'hrs',
                suffixStyle: const TextStyle(fontSize: 16, color: kPrimary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null) {
                final clamped = val.clamp(4.0, 14.0);
                setState(() => _targetSleepHours = clamped);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomStepsDialog() async {
    final ctrl = TextEditingController(text: _dailyStepsGoal.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Custom Steps Goal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter daily steps target (1,000 - 50,000 steps):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
              decoration: InputDecoration(
                suffixText: 'steps',
                suffixStyle: const TextStyle(fontSize: 16, color: kPrimary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null) {
                final clamped = val.clamp(1000, 50000);
                setState(() => _dailyStepsGoal = clamped);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Non-exercise activity thermogenesis (NEAT) and sleep duration',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Daily Activity Level',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...activities.map((act) {
            final isSelected = _activityLevel == act.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activityLevel = act.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.12)
                        : kSurface,
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
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? kPrimary : kTextPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
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
          const Text(
            'Target Sleep Hours',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...[6.0, 7.0, 8.0, 9.0].map((hours) {
                final isSelected = (_targetSleepHours - hours).abs() < 0.1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _targetSleepHours = hours),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kPrimary.withValues(alpha: 0.15)
                              : kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? kPrimary : kBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${hours.round()} hrs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? kPrimary : kTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Expanded(
                child: GestureDetector(
                  onTap: _showCustomSleepDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          ![
                            6.0,
                            7.0,
                            8.0,
                            9.0,
                          ].any((h) => (_targetSleepHours - h).abs() < 0.1)
                          ? kPrimary.withValues(alpha: 0.15)
                          : kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            ![
                              6.0,
                              7.0,
                              8.0,
                              9.0,
                            ].any((h) => (_targetSleepHours - h).abs() < 0.1)
                            ? kPrimary
                            : kBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        ![
                              6.0,
                              7.0,
                              8.0,
                              9.0,
                            ].any((h) => (_targetSleepHours - h).abs() < 0.1)
                            ? '${_targetSleepHours % 1 == 0 ? _targetSleepHours.toInt() : _targetSleepHours.toStringAsFixed(1)}h'
                            : 'Custom',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              ![
                                6.0,
                                7.0,
                                8.0,
                                9.0,
                              ].any((h) => (_targetSleepHours - h).abs() < 0.1)
                              ? kPrimary
                              : kTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Sleep wind-down reminder',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final parts = _preferredSleepTime.split(':');
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.tryParse(parts.first) ?? 22,
                  minute: int.tryParse(parts.last) ?? 0,
                ),
              );
              if (picked != null && mounted) {
                setState(() {
                  _preferredSleepTime =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bedtime_rounded, color: kPrimary),
                  const SizedBox(width: 12),
                  Text(
                    _formatTimeString(_preferredSleepTime),
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: kTextSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Daily Steps Goal',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...[6000, 8000, 10000, 12000].map((steps) {
                final isSelected = _dailyStepsGoal == steps;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _dailyStepsGoal = steps),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kPrimary.withValues(alpha: 0.15)
                              : kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? kPrimary : kBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${steps ~/ 1000}k',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? kPrimary : kTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Expanded(
                child: GestureDetector(
                  onTap: _showCustomStepsDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          ![6000, 8000, 10000, 12000].contains(_dailyStepsGoal)
                          ? kPrimary.withValues(alpha: 0.15)
                          : kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            ![
                              6000,
                              8000,
                              10000,
                              12000,
                            ].contains(_dailyStepsGoal)
                            ? kPrimary
                            : kBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        ![6000, 8000, 10000, 12000].contains(_dailyStepsGoal)
                            ? '${(_dailyStepsGoal / 1000).toStringAsFixed(_dailyStepsGoal % 1000 == 0 ? 0 : 1)}k'
                            : 'Custom',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              ![
                                6000,
                                8000,
                                10000,
                                12000,
                              ].contains(_dailyStepsGoal)
                              ? kPrimary
                              : kTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
      stepText =
          'Structuring $_weeklyWorkoutDays-day training split for $_dailyWorkoutMinutes min sessions...';
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
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 44,
                  color: kPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Crafting your custom plan',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
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
    final calories = _selectedGoal == 'lose_weight'
        ? 1850
        : (_selectedGoal == 'build_muscle' ? 2450 : 2100);
    final protein = (_weightKg * 2.0).round();
    final fats = (_weightKg * 0.8).round();
    final carbs = ((calories - (protein * 4) - (fats * 9)) / 4).round();

    final planTitle = _selectedGoal == 'lose_weight'
        ? 'Full Body Shred'
        : (_selectedGoal == 'build_muscle'
              ? 'Hypertrophy Builder'
              : 'Athletic Conditioning');

    final dailyTime = '$_dailyWorkoutMinutes Min';
    final experienceLevel = _experienceLevel == 'beginner'
        ? 'Beginner'
        : (_experienceLevel == 'advanced' ? 'Advanced' : 'Intermediate');
    final targetArea =
        _selectedFocusAreas.contains('full_body') || _selectedFocusAreas.isEmpty
        ? 'Full Body'
        : _selectedFocusAreas.first
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (s) => s.isNotEmpty
                    ? '${s[0].toUpperCase()}${s.substring(1)}'
                    : '',
              )
              .join(' ');
    final equipment = _selectedEquipment.contains('full_gym')
        ? 'Full Gym'
        : (_selectedEquipment.contains('dumbbells')
              ? 'Dumbbells'
              : 'No Equipment');

    final coachImg = _selectedGender == 'female'
        ? 'assets/images/setup/female_fitness_coach.png'
        : 'assets/images/setup/male_fitness_coach.png';

    return PlanSummaryRevealCard(
      planTitle: planTitle,
      dailyTime: dailyTime,
      experienceLevel: experienceLevel,
      targetArea: targetArea,
      equipment: equipment,
      gender: _selectedGender,
      onStart: () => _finishAndActivatePlan(),
      onGoToHome: () => _finishAndActivatePlan(),
      extraContent: Column(
        children: [
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
                  radius: 20,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Protocol tailored for $_selectedGender • ${_useLbs ? '${_weightLbs.round()} lbs' : '${_weightKg.round()} kg'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OPTIMIZED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 14),

          // Coach Row
          CardShell(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kPrimary.withValues(alpha: 0.2),
                    backgroundImage: AssetImage(coachImg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedGender == 'female'
                              ? "Coach Elena (Women's Specialization)"
                              : 'Coach Marcus (Hypertrophy Lead)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Assigned to guide your progression and volume loading',
                          style: TextStyle(fontSize: 11, color: kTextSecondary),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: kTextSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 9, color: kTextSecondary),
            ),
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

class _SetNameSheetContent extends StatefulWidget {
  final String initialName;
  final String? customProfileImagePath;
  final String avatarId;
  final String selectedGender;
  final ValueChanged<String> onSaveName;
  final Future<void> Function() onPickAvatar;

  const _SetNameSheetContent({
    required this.initialName,
    required this.customProfileImagePath,
    required this.avatarId,
    required this.selectedGender,
    required this.onSaveName,
    required this.onPickAvatar,
  });

  @override
  State<_SetNameSheetContent> createState() => _SetNameSheetContentState();
}

class _SetNameSheetContentState extends State<_SetNameSheetContent> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSaveName(_nameController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = widget.customProfileImagePath ?? widget.avatarId;
    final currentName = _nameController.text.trim();

    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: kBorder),
          left: BorderSide(color: kBorder),
          right: BorderSide(color: kBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Set Athlete Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: kTextSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Personalize your Fit Host profile, workouts, and analytics.',
                style: TextStyle(fontSize: 13, color: kTextSecondary),
              ),
              const SizedBox(height: 18),

              // Avatar with quick change trigger
              Center(
                child: Stack(
                  children: [
                    AppAvatar(
                      avatarId: currentAvatar,
                      radius: 34,
                      name: currentName.isNotEmpty ? currentName : 'Athlete',
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () async {
                          await widget.onPickAvatar();
                          if (mounted) setState(() {});
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: kSurface, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await widget.onPickAvatar();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(
                    Icons.image_outlined,
                    size: 14,
                    color: kPrimary,
                  ),
                  label: const Text(
                    'Change Avatar / Photo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Name Input Field
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Your Name or Call Sign',
                  labelStyle: const TextStyle(color: kTextSecondary),
                  hintText: 'e.g. Alex Hunter',
                  hintStyle: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: kPrimary,
                    size: 20,
                  ),
                  suffixIcon: currentName.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: kTextSecondary,
                          ),
                          onPressed: () {
                            _nameController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),

              // Save Button
              PrimaryButton(text: 'SAVE NAME', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
