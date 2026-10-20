import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/services/startup_gate_service.dart';
import '../../../../core/services/permission_service.dart';
import '../domain/models/onboarding_models.dart';
import 'controllers/onboarding_controller.dart';

// Modular Step Widgets
import 'screens/steps/welcome_step.dart';
import 'screens/steps/basics_step.dart';
import 'screens/steps/about_you_step.dart';
import 'screens/steps/your_body_step.dart';
import 'screens/steps/body_composition_step.dart';
import 'screens/steps/main_goal_step.dart';
import 'screens/steps/target_timeline_step.dart';
import 'screens/steps/focus_areas_step.dart';
import 'screens/steps/gender_specific_goals_step.dart';
import 'screens/steps/experience_step.dart';
import 'screens/steps/location_step.dart';
import 'screens/steps/equipment_step.dart';
import 'screens/steps/weekly_schedule_step.dart';
import 'screens/steps/diet_step.dart';
import 'screens/steps/meals_step.dart';
import 'screens/steps/hydration_step.dart';
import 'screens/steps/lifestyle_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int kTotalWizardSteps = 16;

  bool _isStepSkippable(int step, bool isGenderBranch) {
    // Skip is hidden on steps 1, 2, 15, 16 (mandatory). Shown elsewhere.
    if (step == 1 || step == 2 || step == 15 || step == 16 || step >= 17) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // HEADER (Steps 2..16)
              if (state.currentStep > 1 && state.currentStep <= kTotalWizardSteps) ...[
                _buildHeader(state, notifier),
                const SizedBox(height: 16),
              ],

              // STEP BODY
              Expanded(
                child: _buildStepContent(state, notifier),
              ),

              // BOTTOM BUTTONS (Steps 2..17)
              if (state.currentStep > 1) ...[
                const SizedBox(height: 16),
                _buildBottomControls(state, notifier),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(OnboardingState state, OnboardingNotifier notifier) {
    final double progress = (state.currentStep / kTotalWizardSteps.toDouble()).clamp(0.0, 1.0);
    final bool showSkip = _isStepSkippable(state.currentStep, state.isGenderBranch);
    final String stepBadgeText = state.isGenderBranch
        ? 'Step 8b of $kTotalWizardSteps'
        : 'Step ${state.currentStep} of $kTotalWizardSteps';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFF0F6F2), size: 22),
              onPressed: () => notifier.previousStep(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            // Step Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                stepBadgeText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00E676),
                ),
              ),
            ),

            // Skip button
            if (showSkip)
              TextButton(
                onPressed: () => notifier.skipStep(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8FA396),
                  ),
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 12),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(OnboardingState state, OnboardingNotifier notifier) {
    if (state.currentStep == 1) {
      return WelcomeStep(
        onStart: () => notifier.nextStep(),
        onContinueAsGuest: () {
          notifier.nextStep();
        },
      );
    }

    if (state.currentStep == 2) {
      return BasicsStep(
        selectedGender: state.gender,
        onGenderSelected: (gender) {
          notifier.setGender(gender);
        },
      );
    }

    if (state.currentStep == 3) {
      return AboutYouStep(
        age: state.age,
        onAgeChanged: (age) {
          notifier.updatePhysicalProfile(age: age);
        },
      );
    }

    if (state.currentStep == 4) {
      return YourBodyStep(
        heightCm: state.heightCm,
        weightKg: state.weightKg,
        useMetricUnits: state.useMetricUnits,
        onChanged: ({heightCm, weightKg, useMetricUnits}) {
          notifier.updatePhysicalProfile(
            heightCm: heightCm,
            weightKg: weightKg,
            useMetricUnits: useMetricUnits,
          );
        },
      );
    }

    if (state.currentStep == 5) {
      return BodyCompositionStep(
        bodyFatPercentage: state.bodyFatPercentage,
        waistCm: state.waistCm,
        hipCm: state.hipCm,
        chestCm: state.chestCm,
        neckCm: state.neckCm,
        onChanged: ({bodyFatPercentage, waistCm, hipCm, chestCm, neckCm}) {
          notifier.updateBodyComposition(
            bodyFatPercentage: bodyFatPercentage,
            waistCm: waistCm,
            hipCm: hipCm,
            chestCm: chestCm,
            neckCm: neckCm,
          );
        },
      );
    }

    if (state.currentStep == 6) {
      return MainGoalStep(
        selectedGoals: state.goals,
        onGoalSelected: (goal) {
          notifier.toggleGoal(goal);
        },
      );
    }

    if (state.currentStep == 7) {
      return TargetTimelineStep(
        currentWeightKg: state.weightKg,
        targetWeightKg: state.targetWeightKg ?? state.weightKg,
        targetWeeks: state.targetWeeks,
        useMetricUnits: state.useMetricUnits,
        onChanged: ({targetWeightKg, targetWeeks}) {
          notifier.setTargetTimeline(
            targetWeightKg: targetWeightKg,
            targetWeeks: targetWeeks,
          );
        },
      );
    }

    if (state.currentStep == 8) {
      if (state.isGenderBranch) {
        return GenderSpecificGoalsStep(
          gender: state.gender,
          selectedGoals: state.genderSpecificGoals,
          onToggle: (goal) {
            notifier.toggleGenderSpecificGoal(goal);
          },
        );
      }
      return FocusAreasStep(
        selectedFocusAreas: state.focusAreas,
        onToggle: (area) {
          notifier.toggleFocusArea(area);
        },
      );
    }

    if (state.currentStep == 9) {
      return ExperienceStep(
        selectedLevel: state.experienceLevel,
        onSelected: (level) {
          notifier.setExperienceLevel(level);
        },
      );
    }

    if (state.currentStep == 10) {
      return LocationStep(
        selectedLocations: state.workoutLocations,
        onToggle: (loc) {
          notifier.toggleWorkoutLocation(loc);
        },
      );
    }

    if (state.currentStep == 11) {
      return EquipmentStep(
        selectedEquipment: state.equipment,
        onToggle: (item) {
          notifier.toggleEquipment(item);
        },
      );
    }

    if (state.currentStep == 12) {
      return WeeklyScheduleStep(
        workoutDaysPerWeek: state.workoutDaysPerWeek,
        selectedWeekdays: state.selectedWeekdays,
        usesEveryDay: state.usesEveryDay,
        sessionDurationMinutes: state.sessionDurationMinutes,
        onChanged: ({daysPerWeek, weekdays, usesEveryDay, durationMinutes}) {
          if (durationMinutes != null) {
            notifier.setSessionDuration(durationMinutes);
          }
          if (daysPerWeek != null) {
            notifier.setWeeklySchedule(
              days: daysPerWeek,
              weekdays: weekdays,
              usesEveryDay: usesEveryDay,
            );
          }
        },
      );
    }

    if (state.currentStep == 13) {
      return DietStep(
        selectedDiet: state.dietPreference,
        allergies: state.allergies,
        onChanged: ({diet, allergies}) {
          if (diet != null) notifier.setDietPreference(diet);
          if (allergies != null) notifier.setAllergies(allergies);
        },
      );
    }

    if (state.currentStep == 14) {
      return MealsStep(
        mealsPerDay: state.mealsPerDay,
        mealSchedules: state.mealSchedules,
        onMealsCountChanged: (count) {
          notifier.setMealsPerDay(count);
        },
        onUpdateMeal: (idx, name, time) {
          notifier.updateMealScheduleItem(idx, name, time);
        },
        onAddCustomMeal: () {
          notifier.updateMealScheduleItem(
            state.mealSchedules.length,
            'Meal ${state.mealSchedules.length + 1}',
            '03:00 PM',
          );
        },
      );
    }

    if (state.currentStep == 15) {
      return HydrationStep(
        dailyWaterMl: state.dailyWaterMl,
        reminderFrequencyHours: state.reminderFrequencyHours,
        quietHoursStart: state.quietHoursStart,
        quietHoursEnd: state.quietHoursEnd,
        onChanged: ({dailyWaterMl, reminderFrequencyHours, quietHoursStart, quietHoursEnd}) {
          notifier.setHydrationTarget(
            dailyWaterMl: dailyWaterMl,
            reminderFrequencyHours: reminderFrequencyHours,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
          );
        },
      );
    }

    if (state.currentStep == 16) {
      return LifestyleStep(
        activityLevel: state.activityLevel,
        sleepHours: state.sleepHours,
        workHours: state.workHours,
        stressLevel: state.stressLevel,
        onChanged: ({activityLevel, sleepHours, workHours, stressLevel}) {
          notifier.setLifestyle(
            activityLevel: activityLevel,
            sleepHours: sleepHours,
            workHours: workHours,
            stressLevel: stressLevel,
          );
        },
      );
    }

    // Step 17+: Plan Ready summary & Account Decision
    return _buildPlanReadyAndAccountDecision(state, notifier);
  }

  Widget _buildPlanReadyAndAccountDecision(OnboardingState state, OnboardingNotifier notifier) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 40),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Your Plan is Ready',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF0F6F2),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Customized architecture engineered for your physiology.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8FA396),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Daily Targets Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAILY NUTRITIONAL ARCHITECTURE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF8FA396),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroItem('Calories', '${state.estimatedDailyCalories}', 'kcal', const Color(0xFF29B6F6)),
                    _buildMacroItem('Protein', '${state.recommendedProteinGrams}g', 'build', const Color(0xFF00E676)),
                    _buildMacroItem('Carbs', '${state.recommendedCarbsGrams}g', 'fuel', const Color(0xFFFFD54F)),
                    _buildMacroItem('Fats', '${state.recommendedFatsGrams}g', 'essential', const Color(0xFFFF8A65)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Training Protocol Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROGRAMMED ROUTINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF8FA396),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF00E676), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.recommendedWorkoutPlanName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF0F6F2),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${state.workoutDaysPerWeek} days/week • ${state.sessionDurationMinutes} min/session',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8FA396),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recovery & Hydration Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('💧 Hydration Goal', style: TextStyle(color: Color(0xFFF0F6F2), fontWeight: FontWeight.w600)),
                    Text('${state.dailyWaterMl} ml/day', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 20, color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🌙 Recovery Sleep', style: TextStyle(color: Color(0xFFF0F6F2), fontWeight: FontWeight.w600)),
                    Text('${state.sleepHours} hrs/night', style: const TextStyle(color: Color(0xFFF0F6F2), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, String subtitle, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF0F6F2),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF8FA396),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(OnboardingState state, OnboardingNotifier notifier) {
    // Terminal Screen (Step 17+): Account Decision
    if (state.currentStep >= 17) {
      return Column(
        children: [
          PrimaryButton(
            text: 'Create Account',
            onPressed: () async {
              await notifier.completeOnboarding(isGuest: false);
              await ref.read(startupGateServiceProvider).setFirstLaunchCompleted(true);
              if (mounted) context.push('/auth/sign-up');
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF0F6F2),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await notifier.completeOnboarding(isGuest: false);
                await ref.read(startupGateServiceProvider).setFirstLaunchCompleted(true);
                if (mounted) context.push('/auth/sign-in');
              },
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => _confirmContinueAsGuest(notifier),
            child: const Text(
              'Continue as Guest',
              style: TextStyle(
                color: Color(0xFF8FA396),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    // Step 2 validation: Gender required before continuing
    final bool isStep2Valid = state.currentStep != 2 || state.gender != null;

    return PrimaryButton(
      text: state.currentStep == 16 ? 'View My Plan →' : 'Continue →',
      onPressed: isStep2Valid
          ? () async {
              if (state.currentStep == 15 || state.currentStep == 16) {
                await PermissionService.instance.requestReminderPermissions(context);
              }
              notifier.nextStep();
            }
          : null,
    );
  }

  Future<void> _confirmContinueAsGuest(OnboardingNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121A16),
        title: const Text(
          'Continue as Guest?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF0F6F2)),
        ),
        content: const Text(
          'Guest data stays on this device only. You can create an account later to sync.',
          style: TextStyle(color: Color(0xFF8FA396)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8FA396))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: const Color(0xFF0A0F0D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await notifier.completeOnboarding(isGuest: true);
      await ref.read(startupGateServiceProvider).setFirstLaunchCompleted(true);
      await ref.read(startupGateServiceProvider).setAuthDecisionMade(true);
      if (mounted) context.go('/profile-setup');
    }
  }
}

typedef OnboardingWizardScreen = OnboardingScreen;
