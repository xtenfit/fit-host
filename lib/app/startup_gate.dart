import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/startup_gate_service.dart';
import '../core/services/supabase_service.dart';
import '../features/profile/presentation/controllers/user_profile_controller.dart';

class StartupGateNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final gateService = ref.watch(startupGateServiceProvider);
    final authState = ref.watch(authProvider);
    final authStatus = authState.status;
    final user = authState.user;
    final profile = ref.watch(userProfileProvider);

    if (authStatus == AuthStatus.initialLoading) {
      return '/startup-gate';
    }

    final isAuth =
        authStatus == AuthStatus.authenticated ||
        authStatus == AuthStatus.offlineGrace;

    return gateService.determineInitialRoute(
      isAuthenticated: isAuth,
      isProfileSetupCompleted: profile.isProfileSetupCompleted,
      userId: user?.id,
    );
  }

  Future<void> setFirstLaunchCompleted(bool completed) async {
    await ref
        .read(startupGateServiceProvider)
        .setFirstLaunchCompleted(completed);
    ref.invalidateSelf();
  }

  Future<void> setAuthDecisionMade(bool made) async {
    await ref.read(startupGateServiceProvider).setAuthDecisionMade(made);
    ref.invalidateSelf();
  }

  Future<void> resetOnboarding() async {
    await ref.read(startupGateServiceProvider).resetOnboarding();
    ref.invalidateSelf();
  }
}

final startupGateProvider = AsyncNotifierProvider<StartupGateNotifier, String>(
  StartupGateNotifier.new,
);
