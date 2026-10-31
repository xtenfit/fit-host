import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class AnimatedGenderSelector extends StatefulWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderSelected;
  final bool isDark;
  final bool showPreferNotToSay;
  final String heading;
  final String subtitle;

  const AnimatedGenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
    this.isDark = true,
    this.showPreferNotToSay = true,
    this.heading = "What's your gender?",
    this.subtitle = 'Let us know you better',
  });

  @override
  State<AnimatedGenderSelector> createState() => _AnimatedGenderSelectorState();
}

class _AnimatedGenderSelectorState extends State<AnimatedGenderSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _select(String gender) {
    if (widget.selectedGender != gender) {
      HapticFeedback.lightImpact();
      widget.onGenderSelected(gender);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMale = widget.selectedGender == 'male';
    final isFemale = widget.selectedGender == 'female';
    final isNeutral = widget.selectedGender == 'prefer_not_to_say';

    final textPrimary = widget.isDark
        ? Colors.white
        : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine available vertical room
            final totalHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 500.0;
            final isCompact = totalHeight < 480;
            final stageHeight = (totalHeight * 0.58).clamp(220.0, 360.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: totalHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: isCompact ? 8 : 16),
                        // 1. Heading
                        Text(
                          widget.heading,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 24 : 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 2. Subtitle
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 15,
                            fontWeight: FontWeight.w400,
                            color: textSecondary,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: isCompact ? 12 : 24),

                        // 3. Animated Athletic Character Stage
                        SizedBox(
                          height: stageHeight,
                          width: double.infinity,
                          child: GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity != null) {
                                if (details.primaryVelocity! < -100) {
                                  // Swiped left -> switch to female
                                  _select('female');
                                } else if (details.primaryVelocity! > 100) {
                                  // Swiped right -> switch to male
                                  _select('male');
                                }
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Dynamic Slanted Backdrop Accent (Behind selected active figure)
                                AnimatedAlign(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  alignment: isFemale
                                      ? Alignment.center
                                      : (isMale
                                            ? Alignment.center
                                            : const Alignment(0, -0.2)),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: (isMale || isFemale) ? 1.0 : 0.0,
                                    child: Transform.rotate(
                                      angle: isFemale ? 0.08 : -0.08,
                                      child: Container(
                                        width: stageHeight * 0.58,
                                        height: stageHeight * 0.72,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0062FF),
                                              Color(0xFF00E5FF),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            36,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF0062FF,
                                              ).withValues(alpha: 0.35),
                                              blurRadius: 28,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Inactive Background Silhouette: Male (when female is selected)
                                if (isFemale)
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 380),
                                    curve: Curves.easeOutCubic,
                                    left: constraints.maxWidth * 0.04,
                                    bottom: 0,
                                    top: stageHeight * 0.12,
                                    child: GestureDetector(
                                      onTap: () => _select('male'),
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        opacity: 0.45,
                                        child: Transform.scale(
                                          scale: 0.82,
                                          alignment: Alignment.bottomCenter,
                                          child: _buildModelImage(
                                            'assets/images/setup/male_model.png',
                                            Icons.male_rounded,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Inactive Background Silhouette: Female (when male is selected)
                                if (isMale || isNeutral)
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 380),
                                    curve: Curves.easeOutCubic,
                                    right: constraints.maxWidth * 0.04,
                                    bottom: 0,
                                    top: stageHeight * 0.12,
                                    child: GestureDetector(
                                      onTap: () => _select('female'),
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        opacity: isNeutral ? 0.6 : 0.45,
                                        child: Transform.scale(
                                          scale: 0.82,
                                          alignment: Alignment.bottomCenter,
                                          child: _buildModelImage(
                                            'assets/images/setup/female_model.png',
                                            Icons.female_rounded,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Active Foreground Centered Model
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.easeOutCubic,
                                  top: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Tapping active figure keeps or toggles
                                      if (isMale) {
                                        _select('male');
                                      } else if (isFemale) {
                                        _select('female');
                                      } else {
                                        _select('male');
                                      }
                                    },
                                    child: AnimatedScale(
                                      scale: (isMale || isFemale) ? 1.0 : 0.9,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutBack,
                                      child: _buildModelImage(
                                        isFemale
                                            ? 'assets/images/setup/female_model.png'
                                            : 'assets/images/setup/male_model.png',
                                        isFemale
                                            ? Icons.female_rounded
                                            : Icons.male_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Gender Selection Switcher / Pills (Accessible & Discoverable)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPillTab(
                              id: 'male',
                              label: 'Male',
                              icon: Icons.male_rounded,
                              isSelected: isMale,
                              textPrimary: textPrimary,
                            ),
                            const SizedBox(width: 16),
                            _buildPillTab(
                              id: 'female',
                              label: 'Female',
                              icon: Icons.female_rounded,
                              isSelected: isFemale,
                              textPrimary: textPrimary,
                            ),
                          ],
                        ),

                        if (widget.showPreferNotToSay) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => _select('prefer_not_to_say'),
                            style: TextButton.styleFrom(
                              foregroundColor: isNeutral
                                  ? const Color(0xFF00E676)
                                  : textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                            ),
                            child: Text(
                              'Prefer not to say',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isNeutral
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                decoration: isNeutral
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModelImage(String assetPath, IconData fallbackIcon) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 140,
        height: 240,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, size: 80, color: const Color(0xFF00E676)),
      ),
    );
  }

  Widget _buildPillTab({
    required String id,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color textPrimary,
  }) {
    return InkWell(
      onTap: () => _select(id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0062FF).withValues(alpha: 0.2)
              : (widget.isDark
                    ? const Color(0xFF121A16)
                    : Colors.grey.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0062FF)
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF00E5FF)
                  : textPrimary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
