import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/models/onboarding_models.dart';
import 'controllers/onboarding_controller.dart';
import 'widgets/onboarding_progress_header.dart';
import 'widgets/onboarding_selection_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Controllers for Step 7 inputs
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _allergiesController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(onboardingProvider);
    _ageController = TextEditingController(text: '${s.age}');
    _heightController = TextEditingController(
      text: s.useMetricUnits ? '${s.heightCm.toInt()}' : s.heightInFeet.toStringAsFixed(1),
    );
    _weightController = TextEditingController(
      text: s.useMetricUnits ? '${s.weightKg.toInt()}' : s.weightInLbs.toStringAsFixed(1),
    );
    _targetWeightController = TextEditingController(
      text: s.targetWeightKg != null
          ? (s.useMetricUnits ? '${s.targetWeightKg!.toInt()}' : s.targetWeightInLbs!.toStringAsFixed(1))
          : '',
    );
    _allergiesController = TextEditingController(text: s.allergies);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _syncPhysicalControllers(OnboardingState state) {
    _ageController.text = '${state.age}';
    _heightController.text = state.useMetricUnits
        ? '${state.heightCm.toInt()}'
        : state.heightInFeet.toStringAsFixed(1);
    _weightController.text = state.useMetricUnits
        ? '${state.weightKg.toInt()}'
        : state.weightInLbs.toStringAsFixed(1);
    if (state.targetWeightKg != null) {
      _targetWeightController.text = state.useMetricUnits
          ? '${state.targetWeightKg!.toInt()}'
          : state.targetWeightInLbs!.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Header
                      if (state.currentStep > 1) ...[
                        OnboardingProgressHeader(
                          currentStep: state.currentStep,
                          title: _getStepTitle(state.currentStep),
                          subtitle: _getStepSubtitle(state.currentStep),
                          onBack: () => notifier.previousStep(),
                          onSkip: () => notifier.skipStep(),
                          showSkip: _isStepSkippable(state.currentStep),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Step Content
                      _buildStepBody(state, notifier, isDark),
                    ],
                  ),
                ),
              ),

              // Bottom Action Controls
              const SizedBox(height: 14),
              _buildBottomBar(state, notifier, isDark),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStepSkippable(int step) {
    return step == 2 || step == 5 || step == 10 || step == 11;
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 2:
        return 'What is your gender?';
      case 3:
        return 'What are your focus areas?';
      case 4:
        return 'What are your main fitness goals?';
      case 5:
        return 'What is your primary motivation?';
      case 6:
        return 'Experience & Equipment';
      case 7:
        return 'Your Physical Profile';
      case 8:
        return 'Dietary Preferences';
      case 9:
        return 'Daily Meal Schedule';
      case 10:
        return 'Hydration & Water Habits';
      case 11:
        return 'Lifestyle & Daily Routine';
      case 12:
        return 'Your Personalized Plan';
      default:
        return 'Welcome to Fit Host';
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 2:
        return 'Used only for biological BMR caloric estimation. You may skip this.';
      case 3:
        return 'Select the muscle groups you want to prioritize in your routines.';
      case 4:
        return 'Choose what matters most to your training journey.';
      case 5:
        return 'Understanding your drive helps tailor recommendations.';
      case 6:
        return 'Tell us where you train and what gear you have available.';
      case 7:
        return 'Accurate stats ensure safe and effective target calculations.';
      case 8:
        return 'We tailor macro ratios and meal recommendations to your lifestyle.';
      case 9:
        return 'Customize your eating window and frequency.';
      case 10:
        return 'Track daily fluid intake and hydration consistency.';
      case 11:
        return 'Balanced sleep and recovery maximize training results.';
      case 12:
        return 'Review your tailored schedule and nutrition targets before beginning.';
      default:
        return '';
    }
  }

  Widget _buildStepBody(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1Welcome(isDark);
      case 2:
        return _buildStep2Gender(state, notifier);
      case 3:
        return _buildStep3FocusAreas(state, notifier);
      case 4:
        return _buildStep4Goals(state, notifier);
      case 5:
        return _buildStep5Motivation(state, notifier);
      case 6:
        return _buildStep6Experience(state, notifier, isDark);
      case 7:
        return _buildStep7PhysicalProfile(state, notifier, isDark);
      case 8:
        return _buildStep8Diet(state, notifier, isDark);
      case 9:
        return _buildStep9MealSchedule(state, notifier, isDark);
      case 10:
        return _buildStep10Hydration(state, notifier, isDark);
      case 11:
        return _buildStep11Lifestyle(state, notifier, isDark);
      case 12:
        return _buildStep12PlanSummary(state, notifier, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: WELCOME & BRANDING
  // ---------------------------------------------------------------------------
  Widget _buildStep1Welcome(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Official App Icon
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.electricBlue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/branding/app_icon.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.fitness_center_rounded, size: 40, color: AppColors.electricBlue),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lockup Title Banner
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.4)),
            ),
            child: Image.asset(
              'assets/images/branding/logo_lockup.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'FIT HOST',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'Your Offline-First Fitness Companion',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Personalized workout routines, progressive overload tracking, and nutrition guidance without subscriptions, ads, or paywalls.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Value Pillars
        _buildPillar(
          icon: Icons.lock_open_rounded,
          title: 'Free Core Forever',
          description: 'No premium subscriptions or paywalls for tracking workouts.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildPillar(
          icon: Icons.wifi_off_rounded,
          title: '100% Offline SQLite',
          description: 'Logs, exercises, and routines stay private on your device.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildPillar(
          icon: Icons.trending_up_rounded,
          title: 'Progressive Overload',
          description: 'Smart rest timer, volume analytics, and weight tracking.',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPillar({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.electricBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: GENDER
  // ---------------------------------------------------------------------------
  Widget _buildStep2Gender(OnboardingState state, OnboardingNotifier notifier) {
    return Column(
      children: [
        OnboardingSelectionCard(
          title: 'Male',
          subtitle: 'Calculates standard male basal metabolic rate',
          icon: Icons.male_rounded,
          isSelected: state.gender == 'male',
          onTap: () => notifier.setGender('male'),
        ),
        const SizedBox(height: 12),
        OnboardingSelectionCard(
          title: 'Female',
          subtitle: 'Calculates standard female basal metabolic rate',
          icon: Icons.female_rounded,
          isSelected: state.gender == 'female',
          onTap: () => notifier.setGender('female'),
        ),
        const SizedBox(height: 12),
        OnboardingSelectionCard(
          title: 'Prefer not to say',
          subtitle: 'Uses balanced gender-neutral metabolic estimates',
          icon: Icons.person_outline_rounded,
          isSelected: state.gender == 'prefer_not_to_say',
          onTap: () => notifier.setGender('prefer_not_to_say'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: FOCUS AREAS (MULTI-SELECT)
  // ---------------------------------------------------------------------------
  Widget _buildStep3FocusAreas(OnboardingState state, OnboardingNotifier notifier) {
    final areas = [
      {'id': 'full_body', 'title': 'Full Body', 'sub': 'Balanced overall physique', 'icon': Icons.accessibility_new_rounded},
      {'id': 'chest', 'title': 'Chest & Pecs', 'sub': 'Bench press & hypertrophy', 'icon': Icons.fitness_center_rounded},
      {'id': 'back', 'title': 'Back & Lats', 'sub': 'Width, thickness & posture', 'icon': Icons.shield_rounded},
      {'id': 'arms', 'title': 'Arms (Biceps & Triceps)', 'sub': 'Arm strength & definition', 'icon': Icons.sports_gymnastics_rounded},
      {'id': 'core', 'title': 'Abs & Core', 'sub': 'Core stability & six-pack', 'icon': Icons.flash_on_rounded},
      {'id': 'legs', 'title': 'Legs & Quads', 'sub': 'Squat strength & lower body', 'icon': Icons.directions_walk_rounded},
      {'id': 'shoulders', 'title': 'Shoulders & Delts', 'sub': 'Overhead pressing power', 'icon': Icons.sports_martial_arts_rounded},
      {'id': 'glutes', 'title': 'Glutes & Hamstrings', 'sub': 'Posterior chain explosive power', 'icon': Icons.speed_rounded},
      {'id': 'flexibility', 'title': 'Flexibility & Mobility', 'sub': 'Joint health & range of motion', 'icon': Icons.self_improvement_rounded},
    ];

    return Column(
      children: areas.map((a) {
        final id = a['id'] as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OnboardingSelectionCard(
            title: a['title'] as String,
            subtitle: a['sub'] as String,
            icon: a['icon'] as IconData,
            isSelected: state.focusAreas.contains(id),
            isMultiSelect: true,
            onTap: () => notifier.toggleFocusArea(id),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: GOALS (MULTI-SELECT)
  // ---------------------------------------------------------------------------
  Widget _buildStep4Goals(OnboardingState state, OnboardingNotifier notifier) {
    final goals = [
      {'id': 'lose_weight', 'title': 'Lose Weight & Fat', 'sub': 'Caloric deficit & conditioning', 'icon': Icons.local_fire_department_rounded},
      {'id': 'build_muscle', 'title': 'Build Muscle (Hypertrophy)', 'sub': 'Progressive overload & protein focus', 'icon': Icons.fitness_center_rounded},
      {'id': 'improve_strength', 'title': 'Improve Strength', 'sub': 'Heavy compound lifting 1-5 reps', 'icon': Icons.bolt_rounded},
      {'id': 'maintain_fitness', 'title': 'Maintain Fitness', 'sub': 'Consistent healthy habits', 'icon': Icons.check_circle_outline_rounded},
      {'id': 'improve_endurance', 'title': 'Improve Endurance', 'sub': 'Cardio, stamina, and work capacity', 'icon': Icons.directions_run_rounded},
      {'id': 'improve_flexibility', 'title': 'Improve Flexibility', 'sub': 'Mobility, yoga, and posture', 'icon': Icons.self_improvement_rounded},
      {'id': 'general_wellness', 'title': 'General Wellness & Longevity', 'sub': 'Heart health, sleep, and energy', 'icon': Icons.favorite_rounded},
    ];

    return Column(
      children: goals.map((g) {
        final id = g['id'] as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OnboardingSelectionCard(
            title: g['title'] as String,
            subtitle: g['sub'] as String,
            icon: g['icon'] as IconData,
            isSelected: state.goals.contains(id),
            isMultiSelect: true,
            onTap: () => notifier.toggleGoal(id),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: MOTIVATION
  // ---------------------------------------------------------------------------
  Widget _buildStep5Motivation(OnboardingState state, OnboardingNotifier notifier) {
    final motivations = [
      {'id': 'feel_confident', 'title': 'Feel More Confident', 'sub': 'Look and feel strong in everyday life', 'icon': Icons.sentiment_very_satisfied_rounded},
      {'id': 'reduce_stress', 'title': 'Reduce Stress & Anxiety', 'sub': 'Use workouts as active mental therapy', 'icon': Icons.spa_rounded},
      {'id': 'improve_health', 'title': 'Improve Long-Term Health', 'sub': 'Cardiovascular health and vital energy', 'icon': Icons.health_and_safety_rounded},
      {'id': 'boost_energy', 'title': 'Boost Daily Energy', 'sub': 'Eliminate midday fatigue and sleep deeper', 'icon': Icons.battery_charging_full_rounded},
      {'id': 'build_consistency', 'title': 'Build Lifelong Consistency', 'sub': 'Create an unbreakable workout habit', 'icon': Icons.repeat_rounded},
      {'id': 'athletic_performance', 'title': 'Peak Athletic Performance', 'sub': 'Run faster, jump higher, lift heavier', 'icon': Icons.emoji_events_rounded},
    ];

    return Column(
      children: motivations.map((m) {
        final id = m['id'] as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OnboardingSelectionCard(
            title: m['title'] as String,
            subtitle: m['sub'] as String,
            icon: m['icon'] as IconData,
            isSelected: state.motivations.contains(id),
            isMultiSelect: true,
            onTap: () => notifier.toggleMotivation(id),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 6: EXPERIENCE & EQUIPMENT
  // ---------------------------------------------------------------------------
  Widget _buildStep6Experience(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Experience Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildOptionPill('Beginner', state.experienceLevel == 'beginner', () => notifier.setExperienceLevel('beginner'), isDark),
            const SizedBox(width: 8),
            _buildOptionPill('Intermediate', state.experienceLevel == 'intermediate', () => notifier.setExperienceLevel('intermediate'), isDark),
            const SizedBox(width: 8),
            _buildOptionPill('Advanced', state.experienceLevel == 'advanced', () => notifier.setExperienceLevel('advanced'), isDark),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Workout Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildOptionPill('🏋️ Gym', state.workoutLocation == 'gym', () => notifier.setWorkoutLocation('gym'), isDark),
            const SizedBox(width: 8),
            _buildOptionPill('🏠 Home', state.workoutLocation == 'home', () => notifier.setWorkoutLocation('home'), isDark),
            const SizedBox(width: 8),
            _buildOptionPill('🌲 Outdoors', state.workoutLocation == 'outdoors', () => notifier.setWorkoutLocation('outdoors'), isDark),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Available Equipment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildOptionPill('Bodyweight Only', state.equipment.contains('bodyweight'), () => notifier.toggleEquipment('bodyweight'), isDark),
            _buildOptionPill('Dumbbells', state.equipment.contains('dumbbells'), () => notifier.toggleEquipment('dumbbells'), isDark),
            _buildOptionPill('Barbells', state.equipment.contains('barbells'), () => notifier.toggleEquipment('barbells'), isDark),
            _buildOptionPill('Full Gym', state.equipment.contains('full_gym'), () => notifier.toggleEquipment('full_gym'), isDark),
            _buildOptionPill('Resistance Bands', state.equipment.contains('resistance_bands'), () => notifier.toggleEquipment('resistance_bands'), isDark),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Workout Days per Week', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${state.workoutDaysPerWeek} days', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.electricBlue)),
          ],
        ),
        Slider(
          value: state.workoutDaysPerWeek.toDouble(),
          min: 2,
          max: 6,
          divisions: 4,
          activeColor: AppColors.electricBlue,
          onChanged: (v) => notifier.setWorkoutDaysPerWeek(v.round()),
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Session Duration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${state.sessionDurationMinutes} min', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.electricBlue)),
          ],
        ),
        Slider(
          value: state.sessionDurationMinutes.toDouble(),
          min: 15,
          max: 90,
          divisions: 5,
          activeColor: AppColors.electricBlue,
          onChanged: (v) => notifier.setSessionDuration(v.round()),
        ),
      ],
    );
  }

  Widget _buildOptionPill(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.electricBlueSurface : AppColors.electricBlueSurfaceLight)
              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue
                : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.white : AppColors.electricBlueDark)
                : (isDark ? Colors.white : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 7: PHYSICAL PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildStep7PhysicalProfile(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit Switcher: Metric vs Imperial
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    notifier.updatePhysicalProfile(useMetricUnits: true);
                    _syncPhysicalControllers(state.copyWith(useMetricUnits: true));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: state.useMetricUnits ? AppColors.electricBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Metric (cm / kg)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: state.useMetricUnits ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    notifier.updatePhysicalProfile(useMetricUnits: false);
                    _syncPhysicalControllers(state.copyWith(useMetricUnits: false));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !state.useMetricUnits ? AppColors.electricBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Imperial (ft / lbs)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !state.useMetricUnits ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Age Input
        Text('Age', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 26',
            suffixText: 'years',
          ),
          onChanged: (val) {
            final age = int.tryParse(val);
            if (age != null && age >= 13 && age <= 100) {
              notifier.updatePhysicalProfile(age: age);
            }
          },
        ),
        const SizedBox(height: 16),

        // Height Input
        Text(
          state.useMetricUnits ? 'Height (cm)' : 'Height (ft)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: state.useMetricUnits ? 'e.g. 175' : 'e.g. 5.9',
            suffixText: state.useMetricUnits ? 'cm' : 'ft',
          ),
          onChanged: (val) {
            final h = double.tryParse(val);
            if (h != null) {
              final cm = state.useMetricUnits ? h : h * 30.48;
              if (cm >= 90 && cm <= 250) {
                notifier.updatePhysicalProfile(heightCm: cm);
              }
            }
          },
        ),
        const SizedBox(height: 16),

        // Weight Input
        Text(
          state.useMetricUnits ? 'Current Weight (kg)' : 'Current Weight (lbs)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: state.useMetricUnits ? 'e.g. 72' : 'e.g. 160',
            suffixText: state.useMetricUnits ? 'kg' : 'lbs',
          ),
          onChanged: (val) {
            final w = double.tryParse(val);
            if (w != null) {
              final kg = state.useMetricUnits ? w : w / 2.20462;
              if (kg >= 30 && kg <= 300) {
                notifier.updatePhysicalProfile(weightKg: kg);
              }
            }
          },
        ),
        const SizedBox(height: 16),

        // Optional Target Weight
        Text(
          state.useMetricUnits ? 'Target Weight (kg) - Optional' : 'Target Weight (lbs) - Optional',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _targetWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: state.useMetricUnits ? 'e.g. 70' : 'e.g. 155',
            suffixText: state.useMetricUnits ? 'kg' : 'lbs',
          ),
          onChanged: (val) {
            final tw = double.tryParse(val);
            if (tw != null) {
              final kg = state.useMetricUnits ? tw : tw / 2.20462;
              notifier.updatePhysicalProfile(targetWeightKg: kg);
            }
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 8: DIET PREFERENCES
  // ---------------------------------------------------------------------------
  Widget _buildStep8Diet(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    final diets = [
      {'id': 'non_vegetarian', 'title': '🥩 Non-Vegetarian', 'sub': 'Chicken, fish, beef, eggs & dairy'},
      {'id': 'vegetarian', 'title': '🥦 Vegetarian', 'sub': 'Plant foods, dairy, whole grains'},
      {'id': 'eggetarian', 'title': '🍳 Eggetarian', 'sub': 'Vegetarian diet including eggs'},
      {'id': 'vegan', 'title': '🌱 Vegan', 'sub': '100% plant-based: legumes, tofu, grains'},
      {'id': 'pescatarian', 'title': '🐟 Pescatarian', 'sub': 'Plant foods, fish, and seafood'},
      {'id': 'other', 'title': '✨ Other / Custom Diet', 'sub': 'Flexible or personalized routine'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...diets.map((d) {
          final id = d['id'] as String;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OnboardingSelectionCard(
              title: d['title'] as String,
              subtitle: d['sub'] as String,
              isSelected: state.dietPreference == id,
              onTap: () => notifier.setDietPreference(id),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text('Allergies or Dietary Restrictions (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _allergiesController,
          decoration: const InputDecoration(
            hintText: 'e.g. Peanut allergy, lactose intolerance, gluten-free',
          ),
          onChanged: (val) => notifier.setAllergies(val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 9: MEAL SCHEDULE
  // ---------------------------------------------------------------------------
  Widget _buildStep9MealSchedule(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Usual Number of Meals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [2, 3, 4, 5, 6].map((count) {
            final isSelected = state.mealsPerDay == count;
            return InkWell(
              onTap: () => notifier.setMealsPerDay(count),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.electricBlue : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.electricBlue : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        const Text('Meal Schedule & Target Times', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...List.generate(state.mealSchedules.length, (index) {
          final item = state.mealSchedules[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_rounded, size: 18, color: AppColors.electricBlue),
                    const SizedBox(width: 10),
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 12, minute: 0),
                    );
                    if (time != null && mounted) {
                      notifier.updateMealScheduleItem(index, item.name, time.format(context));
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(item.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 4),
                        const Icon(Icons.access_time_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 10: HYDRATION
  // ---------------------------------------------------------------------------
  Widget _buildStep10Hydration(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daily Hydration Target', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${state.dailyWaterMl} ml', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.electricCyan)),
          ],
        ),
        Slider(
          value: state.dailyWaterMl.toDouble(),
          min: 1500,
          max: 4500,
          divisions: 12,
          activeColor: AppColors.electricCyan,
          onChanged: (v) => notifier.setDailyWater(v.round()),
        ),
        const SizedBox(height: 20),

        const Text('Drinking Frequency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        OnboardingSelectionCard(
          title: 'Every 1 Hour',
          subtitle: 'Consistent hydration throughout the active day',
          icon: Icons.timer_outlined,
          isSelected: state.drinkingFrequency == 'every_1_hour',
          onTap: () => notifier.setDrinkingFrequency('every_1_hour'),
        ),
        const SizedBox(height: 10),
        OnboardingSelectionCard(
          title: 'Every 2 Hours',
          subtitle: 'Balanced intervals between work and training',
          icon: Icons.schedule_rounded,
          isSelected: state.drinkingFrequency == 'every_2_hours',
          onTap: () => notifier.setDrinkingFrequency('every_2_hours'),
        ),
        const SizedBox(height: 10),
        OnboardingSelectionCard(
          title: 'With Meals & Workouts',
          subtitle: 'Pre-workout, post-workout, and at meal times',
          icon: Icons.water_drop_rounded,
          isSelected: state.drinkingFrequency == 'with_meals',
          onTap: () => notifier.setDrinkingFrequency('with_meals'),
        ),
        const SizedBox(height: 20),

        // Reminder Toggle & Quiet Hours
        SwitchListTile.adaptive(
          title: const Text('Hydration Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Gentle local notifications during waking hours'),
          value: state.enableWaterReminders,
          activeTrackColor: AppColors.electricCyan,
          onChanged: (val) => notifier.setWaterReminders(val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 11: LIFESTYLE & SLEEP
  // ---------------------------------------------------------------------------
  Widget _buildStep11Lifestyle(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daily Activity Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        OnboardingSelectionCard(
          title: 'Sedentary',
          subtitle: 'Desk job, little regular physical movement',
          icon: Icons.chair_rounded,
          isSelected: state.activityLevel == 'sedentary',
          onTap: () => notifier.setActivityLevel('sedentary'),
        ),
        const SizedBox(height: 10),
        OnboardingSelectionCard(
          title: 'Lightly Active',
          subtitle: '1-3 light sessions per week, daily walking',
          icon: Icons.directions_walk_rounded,
          isSelected: state.activityLevel == 'lightly_active',
          onTap: () => notifier.setActivityLevel('lightly_active'),
        ),
        const SizedBox(height: 10),
        OnboardingSelectionCard(
          title: 'Moderately Active',
          subtitle: '3-5 training sessions per week, active job',
          icon: Icons.fitness_center_rounded,
          isSelected: state.activityLevel == 'moderately_active',
          onTap: () => notifier.setActivityLevel('moderately_active'),
        ),
        const SizedBox(height: 10),
        OnboardingSelectionCard(
          title: 'Very Active',
          subtitle: 'Hard physical training 6+ times per week or manual labor',
          icon: Icons.bolt_rounded,
          isSelected: state.activityLevel == 'very_active',
          onTap: () => notifier.setActivityLevel('very_active'),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Average Nightly Sleep', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${state.sleepHours} hrs', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.electricBlue)),
          ],
        ),
        Slider(
          value: state.sleepHours,
          min: 5.0,
          max: 10.0,
          divisions: 10,
          activeColor: AppColors.electricBlue,
          onChanged: (v) => notifier.setSleepHours(v),
        ),
        const SizedBox(height: 16),

        const Text('Preferred Workout Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildOptionPill('🌅 Morning', state.workoutTimePreference == 'morning', () => notifier.setWorkoutTimePreference('morning'), isDark),
            const SizedBox(width: 8),
            _buildOptionPill('☀️ Afternoon', state.workoutTimePreference == 'afternoon', () => notifier.setWorkoutTimePreference('afternoon'), isDark),
            const SizedBox(width: 8),
            _buildOptionPill('🌙 Evening', state.workoutTimePreference == 'evening', () => notifier.setWorkoutTimePreference('evening'), isDark),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 12: PERSONALIZED PLAN SUMMARY
  // ---------------------------------------------------------------------------
  Widget _buildStep12PlanSummary(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommended Program Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TAILORED WORKOUT PLAN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.electricBlue),
                    ),
                  ),
                  InkWell(
                    onTap: () => notifier.jumpToStep(6),
                    child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.electricBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                state.recommendedWorkoutPlanName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                '${state.workoutDaysPerWeek} sessions/week • ${state.sessionDurationMinutes} min/session • ${state.experienceLevel.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nutrition & Calorie Guidance Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ESTIMATED NUTRITION TARGETS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.limeGreen),
                    ),
                  ),
                  InkWell(
                    onTap: () => notifier.jumpToStep(8),
                    child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.electricBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientStat('Calories', '${state.estimatedDailyCalories}', 'kcal', AppColors.electricBlue),
                  _buildNutrientStat('Protein', '${state.recommendedProteinGrams}g', 'target', AppColors.limeGreen),
                  _buildNutrientStat('Carbs', '${state.recommendedCarbsGrams}g', 'fuel', AppColors.electricCyan),
                  _buildNutrientStat('Fats', '${state.recommendedFatsGrams}g', 'essential', AppColors.warmCoral),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hydration & Schedule Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💧 Daily Hydration Target', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${state.dailyWaterMl} ml/day', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.electricCyan)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🥗 Meal Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${state.mealsPerDay} meals scheduled', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🌙 Recovery Sleep', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${state.sleepHours} hours/night', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.darkTextTertiary)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR CONTROLS
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar(OnboardingState state, OnboardingNotifier notifier, bool isDark) {
    if (state.currentStep == 1) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => notifier.nextStep(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Personalization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await notifier.completeOnboarding(isGuest: true);
              if (mounted) context.go('/home');
            },
            child: Text(
              'Continue as Guest (Skip to Dashboard)',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    if (state.currentStep == 12) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await notifier.completeOnboarding(isGuest: true);
                if (mounted) context.go('/home');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Free Fitness Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await notifier.completeOnboarding(isGuest: true);
              if (mounted) context.go('/home');
            },
            child: Text(
              'Finish as Offline Guest',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => notifier.nextStep(),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
