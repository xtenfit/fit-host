import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/guest_account_claim_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/startup_gate_service.dart';
import '../../../profile/presentation/controllers/user_profile_controller.dart';

class AuthNavigationHelper {
  static bool _isNavigatingGlobal = false;

  /// Checks whether an account user has existing setup completed in DB,
  /// routing existing users to /home and new users to /setup-wizard.
  /// Uses top-level appRouter.go to guarantee instant navigation without context unmount issues.
  static Future<void> checkAccountSetupAndNavigate(
    BuildContext? context,
    WidgetRef ref,
    String userId,
  ) async {
    if (_isNavigatingGlobal) return;
    _isNavigatingGlobal = true;

    try {
      final gateService = ref.read(startupGateServiceProvider);
      await gateService.setFirstLaunchCompleted(true);
      await gateService.setAuthDecisionMade(true);
      await gateService.setAccountOnboardingCompleted(userId, true);
      await gateService.setWizardSkipped(true);
      await gateService.clearWizardDraftStep();
      await ref
          .read(permissionServiceProvider)
          .setPermissionSetupCompleted(true);

      // Cancel any pending setup wizard reminder notifications
      NotificationService.instance.cancelWizardSetupNotifications().ignore();

      // 1. Fast, non-blocking local guest data claiming (runs in < 20ms)
      try {
        final claimService = ref.read(guestAccountClaimServiceProvider);
        final breakdown = await claimService.getGuestRecordBreakdown();
        if (breakdown.hasRecords) {
          debugPrint(
            '[AuthNavigationHelper] Fast local migration for ${breakdown.totalRecords} records...',
          );
          await claimService.claimGuestDataLocallyFast(userId);
        }
      } catch (e) {
        debugPrint('[AuthNavigationHelper] Fast local claim notice: $e');
      }

      // 2. Check local Profile Repository in DB
      bool isCompleted = false;
      try {
        final profileRepo = ref.read(userProfileRepositoryProvider);
        final localProfile = await profileRepo.loadProfile();
        if (localProfile.isProfileSetupCompleted) {
          isCompleted = true;
        }
      } catch (e) {
        debugPrint('[AuthNavigationHelper] Local profile check: $e');
      }

      // 3. If not completed locally, quick check remote Supabase DB profiles table (1.5s max)
      if (!isCompleted) {
        try {
          final client = Supabase.instance.client;
          final response = await client
              .from('profiles')
              .select(
                'is_profile_setup_completed, height_cm, weight_kg, fitness_goal, display_name',
              )
              .match({'id': userId})
              .maybeSingle()
              .timeout(const Duration(milliseconds: 1500));

          if (response != null) {
            final isMarkedDone = response['is_profile_setup_completed'] == true;
            final hasProfileData =
                (response['height_cm'] != null &&
                    (response['height_cm'] as num) > 0) ||
                (response['fitness_goal'] != null &&
                    (response['fitness_goal'] as String).isNotEmpty &&
                    response['fitness_goal'] != 'maintain_weight');

            if (isMarkedDone || hasProfileData) {
              isCompleted = true;
              client
                  .from('profiles')
                  .update({'is_profile_setup_completed': true})
                  .match({'id': userId})
                  .ignore();
              ref.read(userProfileProvider.notifier).reloadProfile().ignore();
            }
          }
        } catch (e) {
          debugPrint('[AuthNavigationHelper] Remote Supabase check notice: $e');
        }
      }

      // 4. Also check device account onboarding flag
      if (!isCompleted) {
        final accountDone = await gateService.isAccountOnboardingCompleted(
          userId,
        );
        if (accountDone) {
          isCompleted = true;
        }
      }

      final targetRoute = isCompleted ? '/home' : '/setup-wizard';
      debugPrint(
        '[AuthNavigationHelper] Navigating immediately to: $targetRoute',
      );

      // CRITICAL: Guaranteed navigation using appRouter.go directly!
      // This wipes all pushed auth screens, eliminates auth screen repetition,
      // and guarantees navigation even if the local widget context unmounted!
      appRouter.go(targetRoute);
    } catch (e) {
      debugPrint('[AuthNavigationHelper] Navigation error: $e');
      // Failsafe: ALWAYS navigate to /home rather than leaving user stuck!
      appRouter.go('/home');
    } finally {
      Future.delayed(const Duration(milliseconds: 800), () {
        _isNavigatingGlobal = false;
      });
    }
  }
}
