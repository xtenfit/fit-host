import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../reminders/data/alarm_sound_service.dart';

class PlanSummaryRevealCard extends StatefulWidget {
  final String planTitle;
  final String dailyTime;
  final String experienceLevel;
  final String targetArea;
  final String equipment;
  final String gender;
  final VoidCallback? onStart;
  final VoidCallback? onGoToHome;
  final Widget? extraContent;
  final bool isDark;
  final bool showActionButtons;
  final bool isScrollable;

  const PlanSummaryRevealCard({
    super.key,
    required this.planTitle,
    required this.dailyTime,
    required this.experienceLevel,
    required this.targetArea,
    required this.equipment,
    this.gender = 'male',
    this.onStart,
    this.onGoToHome,
    this.extraContent,
    this.isDark = true,
    this.showActionButtons = true,
    this.isScrollable = true,
  });

  @override
  State<PlanSummaryRevealCard> createState() => _PlanSummaryRevealCardState();
}

class _PlanSummaryRevealCardState extends State<PlanSummaryRevealCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _badgeScale;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _tilesFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _badgeScale = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );

    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _tilesFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _animController.forward();
    unawaited(
      AlarmSoundService().previewSound('victory_fanfare', boostVolume: true),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFemale = widget.gender.toLowerCase() == 'female';
    final coachAsset = isFemale
        ? 'assets/images/setup/female_fitness_coach.png'
        : 'assets/images/setup/male_fitness_coach.png';
    final trainerAsset = isFemale
        ? 'assets/images/setup/female_fitness_trainer.png'
        : 'assets/images/setup/male_fitness_trainer.png';

    final textPrimary = widget.isDark
        ? Colors.white
        : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Top Coach / Achievement Badge Icon
        ScaleTransition(
          scale: _badgeScale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF00E676), Color(0xFF0062FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0062FF).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                coachAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF121A16),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    size: 40,
                    color: Color(0xFF00E676),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Bold Success Heading
        Text(
          'Your plan is ready!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // 3. Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'We have selected this plan that suits you best',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 4. Branded Plan Summary Card (Inspired by Screenshot 2)
        FadeTransition(
          opacity: _cardFade,
          child: SlideTransition(
            position: _cardSlide,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0062FF), Color(0xFF0038A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0062FF).withValues(alpha: 0.4),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Trainer silhouette illustration on right side
                  Positioned(
                    right: -12,
                    top: 10,
                    bottom: 0,
                    child: Image.asset(
                      trainerAsset,
                      fit: BoxFit.contain,
                      height: 280,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 80),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "CUSTOMIZED FOR YOU" Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD8B2),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'CUSTOMIZED FOR YOU',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Color(0xFF6B2D00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Plan Title
                        SizedBox(
                          width: 220,
                          child: Text(
                            widget.planTitle.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2x2 Grid of Stat Tiles
                        FadeTransition(
                          opacity: _tilesFade,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFrostedStatTile(
                                      icon: Icons.calendar_today_rounded,
                                      value: widget.dailyTime,
                                      label: 'Daily Time',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildFrostedStatTile(
                                      icon: Icons.bar_chart_rounded,
                                      value: widget.experienceLevel,
                                      label: 'Level',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFrostedStatTile(
                                      icon: Icons.track_changes_rounded,
                                      value: widget.targetArea,
                                      label: 'Target area',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildFrostedStatTile(
                                      icon: Icons.check_circle_rounded,
                                      value: widget.equipment,
                                      label: 'Equipment',
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
        const SizedBox(height: 20),

        // Extra details / nutrition if provided
        if (widget.extraContent != null) ...[
          widget.extraContent!,
          const SizedBox(height: 16),
        ],

        // 5. Bottom Primary Action CTA
        if (widget.showActionButtons) ...[
          PrimaryButton(text: 'START NOW', onPressed: widget.onStart),
          const SizedBox(height: 12),

          // 6. Secondary Action Link: Go to homepage
          if (widget.onGoToHome != null)
            TextButton(
              onPressed: widget.onGoToHome,
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
              child: const Text(
                'Go to homepage',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ],
    );

    if (!widget.isScrollable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: content,
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: content,
    );
  }

  Widget _buildFrostedStatTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
