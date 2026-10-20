import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/app/startup_gate.dart';

class StartupGateScreen extends ConsumerWidget {
  const StartupGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<String>>(startupGateProvider, (prev, next) {
      if (next.hasValue &&
          next.value != '/startup-gate' &&
          context.mounted) {
        context.go(next.value!);
      }
    });

    final gateState = ref.watch(startupGateProvider);
    gateState.whenData((route) {
      if (route != '/startup-gate') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(route);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Image.asset(
          'assets/images/branding/icon.png',
          width: 72,
          height: 72,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: AppColors.limeGreen,
          ),
        ),
      ),
    );
  }
}
