import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_host/app/startup_gate.dart';

/// Apple-style Premium Splash Screen with staged intro animations:
/// 1. Screen is #0A0F0D
/// 2. Fit Host emblem (`assets/images/fit_host_icon.png`) fades in and scales
///    from 0.8 to 1.0 with an `easeOutBack` curve (800ms)
/// 3. Wordmark "FIT HOST" slides up 20px and fades in (400ms delay)
/// 4. Tagline fades in (200ms after wordmark = 600ms delay)
/// 5. After 2 seconds total, navigates to the startup gate destination (Wizard or Home)
class SplashScreen extends ConsumerStatefulWidget {
  final bool autoNavigate;
  final Duration? duration;

  const SplashScreen({
    super.key,
    this.autoNavigate = true,
    this.duration,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navigationTimer;
  String? _resolvedTargetRoute;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _preloadTargetRoute();
    if (widget.autoNavigate) {
      _scheduleNavigation();
    }
  }

  void _preloadTargetRoute() {
    ref.read(startupGateProvider.future).timeout(
      const Duration(milliseconds: 1200),
      onTimeout: () => '/home',
    ).then((route) {
      _resolvedTargetRoute = route;
    }).catchError((_) {
      _resolvedTargetRoute = '/home';
    });
  }

  void _navigateNow([String? fallbackRoute]) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navigationTimer?.cancel();
    final route = _resolvedTargetRoute ?? fallbackRoute ?? '/home';
    context.go(route);
  }

  void _scheduleNavigation() {
    final navDuration = widget.duration ?? const Duration(milliseconds: 1500);
    _navigationTimer = Timer(navDuration, () async {
      if (!mounted || _navigated) return;
      try {
        final targetRoute = _resolvedTargetRoute ??
            await ref.read(startupGateProvider.future).timeout(
                  const Duration(milliseconds: 600),
                  onTimeout: () => '/home',
                );
        _navigateNow(targetRoute);
      } catch (e) {
        _navigateNow('/home');
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kDarkBackground = Color(0xFF0A0F0D);
    const kTextPrimary = Color(0xFFF0F6F2);
    const kBrandGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: kDarkBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateNow(),
        child: Stack(
          children: [
          // Ambient luminous background glow
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kBrandGreen.withValues(alpha: 0.12),
                    kDarkBackground.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Staged animated branding elements
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Fit Host Hex-Dumbbell Icon:
                // Fades in and scales up 0.8 -> 1.0 with easeOutBack (800ms)
                Image.asset(
                  'assets/images/fit_host_icon.png',
                  width: 108,
                  height: 108,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121A16),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: kBrandGreen.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 56,
                      color: kBrandGreen,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 24),

                // 2. Wordmark "FIT HOST":
                // Slides up 20px and fades in (400ms delay, 600ms duration)
                const Text(
                  'FIT HOST',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontFamilyFallback: ['Inter', 'SF Pro Display', 'Helvetica', 'sans-serif'],
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.5,
                    color: kTextPrimary,
                    height: 1.1,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .moveY(
                      begin: 20,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 10),

                // 3. Tagline:
                // Fades in 200ms after wordmark begins (600ms delay, 500ms duration)
                const Text(
                  'PERFORMANCE & LONGEVITY',
                  style: TextStyle(
                    fontFamily: 'Arial',
                    fontFamilyFallback: ['Inter', 'SF Pro Display', 'Helvetica', 'sans-serif'],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.8,
                    color: kBrandGreen,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .moveY(
                      begin: 8,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
