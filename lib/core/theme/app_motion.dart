import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// AppMotion: Centralized Apple iOS & Framer-Motion physics tokens & widgets.
class AppMotion {
  // Apple iOS Spring & Physics Curves
  static const Curve iosSpring = Curves.easeOutCubic;
  static const Curve iosSpringBounce = Curves.easeOutBack;
  static const Curve iosModal = Curves.easeOutQuart;
  static const Curve iosDecelerate = Curves.fastLinearToSlowEaseIn;

  // Motion Durations
  static const Duration durationFast = Duration(milliseconds: 140);
  static const Duration durationNormal = Duration(milliseconds: 240);
  static const Duration durationPage = Duration(milliseconds: 320);
  static const Duration durationModal = Duration(milliseconds: 380);

  // Haptics Helpers
  static void tapHaptic() {
    HapticFeedback.lightImpact();
  }

  static void selectHaptic() {
    HapticFeedback.selectionClick();
  }

  static void successHaptic() {
    HapticFeedback.mediumImpact();
  }
}

/// BouncyTap: Framer-Motion spring press widget.
/// Gently scales down on press with haptic feedback, and bounces back with spring physics.
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;
  final bool enableHaptics;
  final HitTestBehavior behavior;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
      reverseCurve: AppMotion.iosSpringBounce,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (widget.enableHaptics) {
      AppMotion.tapHaptic();
    }
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    if (!interactive) return widget.child;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: widget.onLongPress != null
            ? () {
                if (widget.enableHaptics) {
                  AppMotion.successHaptic();
                }
                widget.onLongPress?.call();
              }
            : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// FramerSlideIn: Staggered entrance animation for cards and list items.
class FramerSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  const FramerSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.beginOffset = const Offset(0, 18),
    this.curve = AppMotion.iosDecelerate,
  });

  @override
  State<FramerSlideIn> createState() => _FramerSlideInState();
}

class _FramerSlideInState extends State<FramerSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// AppleTransitions: Page transitions matching Apple iOS feel with Framer-motion physics.
class AppleTransitions {
  /// Builds an authentic iOS-style page transition with Cupertino slide, parallax and barrier.
  static Page<T> iosPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: AppMotion.durationPage,
      reverseTransitionDuration: const Duration(milliseconds: 280),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming screen slides from right with iOS deceleration
        final primarySlide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppMotion.iosDecelerate,
          reverseCurve: Curves.easeInCubic,
        ));

        // Outgoing screen has iOS parallax shift to left and subtle fade
        final secondarySlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.25, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppMotion.iosDecelerate,
          reverseCurve: Curves.easeInCubic,
        ));

        final secondaryFade = Tween<double>(
          begin: 1.0,
          end: 0.88,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.linear,
        ));

        return SlideTransition(
          position: secondarySlide,
          child: FadeTransition(
            opacity: secondaryFade,
            child: SlideTransition(
              position: primarySlide,
              child: RepaintBoundary(child: child),
            ),
          ),
        );
      },
    );
  }

  /// Builds an authentic iOS modal sheet transition (slide from bottom with spring).
  static Page<T> iosModal<T>({
    required Widget child,
    required LocalKey key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: AppMotion.durationModal,
      reverseTransitionDuration: const Duration(milliseconds: 300),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideUp = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppMotion.iosModal,
          reverseCurve: Curves.easeInCubic,
        ));

        final fade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));

        return SlideTransition(
          position: slideUp,
          child: FadeTransition(
            opacity: fade,
            child: RepaintBoundary(child: child),
          ),
        );
      },
    );
  }

  /// Builds a fluid Framer-Motion crossfade with subtle scale for tabs / windows.
  static Widget buildWindowSwitchTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    final scale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppMotion.iosDecelerate,
      ),
    );

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    return RepaintBoundary(
      child: FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      ),
    );
  }
}
