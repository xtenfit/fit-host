import 'package:flutter/material.dart';

/// Interactive Anatomical Pointer Diagram
/// Renders an athletic model with connecting pointer lines and target anchors.
/// Supports gender-specific branching with up to 10 body parts for male and female.
/// Full body selection automatically selects all body parts.
/// Uses locked tokens: Surface #121A16, Primary #00E676, Radius 12.
class AnatomyPointerDiagram extends StatelessWidget {
  final Set<String> selectedAreas;
  final ValueChanged<String> onToggleArea;
  final String gender; // 'male' or 'female'

  const AnatomyPointerDiagram({
    super.key,
    required this.selectedAreas,
    required this.onToggleArea,
    this.gender = 'male',
  });

  static const double containerHeight = 520.0;
  static const double buttonWidth = 146.0;
  static const double buttonHeight = 35.0;
  static const double verticalSpacing = 11.5;
  static const double topPadding = 10.0;

  List<Map<String, dynamic>> _buildOptions(bool isFemale) {
    if (isFemale) {
      return [
        {
          'id': 'full_body',
          'title': 'Full Body',
          'hasLine': false,
          'btnCenterY': topPadding + (buttonHeight / 2),
        },
        {
          'id': 'arms',
          'title': 'Arms & Shoulders',
          'hasLine': true,
          'anchorX': 0.61,
          'anchorY': 0.26,
          'btnCenterY': topPadding + 1 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'chest',
          'title': 'Chest & Decollete',
          'hasLine': true,
          'anchorX': 0.71,
          'anchorY': 0.28,
          'btnCenterY': topPadding + 2 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'back',
          'title': 'Back & Posture',
          'hasLine': true,
          'anchorX': 0.66,
          'anchorY': 0.32,
          'btnCenterY': topPadding + 3 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'abs',
          'title': 'Abs & Flat Belly',
          'hasLine': true,
          'anchorX': 0.73,
          'anchorY': 0.38,
          'btnCenterY': topPadding + 4 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'waist',
          'title': 'Waist & Hourglass',
          'hasLine': true,
          'anchorX': 0.68,
          'anchorY': 0.42,
          'btnCenterY': topPadding + 5 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'hips',
          'title': 'Hips & Pelvis',
          'hasLine': true,
          'anchorX': 0.71,
          'anchorY': 0.47,
          'btnCenterY': topPadding + 6 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'glutes',
          'title': 'Glutes & Booty',
          'hasLine': true,
          'anchorX': 0.76,
          'anchorY': 0.52,
          'btnCenterY': topPadding + 7 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'hamstrings',
          'title': 'Hamstrings',
          'hasLine': true,
          'anchorX': 0.72,
          'anchorY': 0.61,
          'btnCenterY': topPadding + 8 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'thighs',
          'title': 'Thighs & Quads',
          'hasLine': true,
          'anchorX': 0.67,
          'anchorY': 0.65,
          'btnCenterY': topPadding + 9 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'calves',
          'title': 'Calves & Ankles',
          'hasLine': true,
          'anchorX': 0.68,
          'anchorY': 0.81,
          'btnCenterY': topPadding + 10 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
      ];
    } else {
      return [
        {
          'id': 'full_body',
          'title': 'Full Body',
          'hasLine': false,
          'btnCenterY': topPadding + (buttonHeight / 2),
        },
        {
          'id': 'shoulders',
          'title': 'Shoulders & Delts',
          'hasLine': true,
          'anchorX': 0.62,
          'anchorY': 0.21,
          'btnCenterY': topPadding + 1 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'chest',
          'title': 'Chest',
          'hasLine': true,
          'anchorX': 0.71,
          'anchorY': 0.28,
          'btnCenterY': topPadding + 2 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'arms',
          'title': 'Biceps & Arms',
          'hasLine': true,
          'anchorX': 0.59,
          'anchorY': 0.32,
          'btnCenterY': topPadding + 3 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'back',
          'title': 'Upper Back & Lats',
          'hasLine': true,
          'anchorX': 0.65,
          'anchorY': 0.34,
          'btnCenterY': topPadding + 4 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'abs',
          'title': 'Abs & Six-Pack',
          'hasLine': true,
          'anchorX': 0.73,
          'anchorY': 0.37,
          'btnCenterY': topPadding + 5 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'obliques',
          'title': 'Obliques & Core',
          'hasLine': true,
          'anchorX': 0.68,
          'anchorY': 0.41,
          'btnCenterY': topPadding + 6 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'triceps',
          'title': 'Triceps & Forearms',
          'hasLine': true,
          'anchorX': 0.58,
          'anchorY': 0.43,
          'btnCenterY': topPadding + 7 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'glutes',
          'title': 'Glutes & Hamstrings',
          'hasLine': true,
          'anchorX': 0.75,
          'anchorY': 0.52,
          'btnCenterY': topPadding + 8 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'quads',
          'title': 'Quads & Thighs',
          'hasLine': true,
          'anchorX': 0.69,
          'anchorY': 0.64,
          'btnCenterY': topPadding + 9 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
        {
          'id': 'calves',
          'title': 'Calves & Lower Legs',
          'hasLine': true,
          'anchorX': 0.68,
          'anchorY': 0.80,
          'btnCenterY': topPadding + 10 * (buttonHeight + verticalSpacing) + (buttonHeight / 2),
        },
      ];
    }
  }

  bool _isItemActive(String id, List<Map<String, dynamic>> options) {
    final lowerId = id.toLowerCase();
    final hasFullBody = selectedAreas.contains('full_body') ||
        selectedAreas.contains('full body');

    if (lowerId == 'full_body') {
      if (hasFullBody) return true;
      final partIds = options
          .where((o) => o['hasLine'] == true)
          .map((o) => o['id'] as String)
          .toList();
      return partIds.isNotEmpty && partIds.every((pid) => _isPartActive(pid));
    }

    if (hasFullBody) return true;
    return _isPartActive(lowerId);
  }

  bool _isPartActive(String partId) {
    if (selectedAreas.contains(partId)) return true;
    if (partId == 'arms' && selectedAreas.contains('arm')) return true;
    if (partId == 'arm' && selectedAreas.contains('arms')) return true;
    if ((partId == 'quads' || partId == 'thighs') &&
        (selectedAreas.contains('leg') || selectedAreas.contains('legs'))) {
      return true;
    }
    if ((partId == 'leg' || partId == 'legs') &&
        (selectedAreas.contains('quads') || selectedAreas.contains('thighs'))) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFemale = gender.toLowerCase() == 'female';

    final modelAsset = isFemale
        ? 'assets/images/setup/female_model.png'
        : 'assets/images/setup/male_model.png';

    final options = _buildOptions(isFemale);

    return SizedBox(
      height: containerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Model cutout image on the right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 205,
            child: Image.asset(
              modelAsset,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.accessibility_new_rounded,
                  size: 140,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
          ),

          // Custom Painter for Connector Lines & Anchor Rings
          Positioned.fill(
            child: CustomPaint(
              painter: _AnatomyPointerLinesPainter(
                selectedAreas: selectedAreas,
                isDark: isDark,
                isFemale: isFemale,
                options: options,
              ),
            ),
          ),

          // Action Buttons Column on Left
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final opt = entry.value;
            final id = opt['id'] as String;
            final title = opt['title'] as String;
            final isSelected = _isItemActive(id, options);
            final btnTop = topPadding + index * (buttonHeight + verticalSpacing);

            return Positioned(
              left: 0,
              top: btnTop,
              width: buttonWidth,
              height: buttonHeight,
              child: InkWell(
                onTap: () => onToggleArea(id),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00E676)
                        : (isDark ? const Color(0xFF121A16) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : (isDark ? const Color(0xFF1F2D26) : const Color(0xFFE5E7EB)),
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? const Color(0xFF0A0F0D)
                                : (isDark ? Colors.white : const Color(0xFF111827)),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Color(0xFF0A0F0D),
                        )
                      else if (id == 'full_body')
                        Icon(
                          Icons.all_inclusive_rounded,
                          size: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
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
}

class _AnatomyPointerLinesPainter extends CustomPainter {
  final Set<String> selectedAreas;
  final bool isDark;
  final bool isFemale;
  final List<Map<String, dynamic>> options;

  _AnatomyPointerLinesPainter({
    required this.selectedAreas,
    required this.isDark,
    required this.isFemale,
    required this.options,
  });

  bool _isItemActive(String id) {
    final lowerId = id.toLowerCase();
    final hasFullBody = selectedAreas.contains('full_body') ||
        selectedAreas.contains('full body');

    if (lowerId == 'full_body') {
      if (hasFullBody) return true;
      final partIds = options
          .where((o) => o['hasLine'] == true)
          .map((o) => o['id'] as String)
          .toList();
      return partIds.isNotEmpty && partIds.every((pid) => _isPartActive(pid));
    }

    if (hasFullBody) return true;
    return _isPartActive(lowerId);
  }

  bool _isPartActive(String partId) {
    if (selectedAreas.contains(partId)) return true;
    if (partId == 'arms' && selectedAreas.contains('arm')) return true;
    if (partId == 'arm' && selectedAreas.contains('arms')) return true;
    if ((partId == 'quads' || partId == 'thighs') &&
        (selectedAreas.contains('leg') || selectedAreas.contains('legs'))) {
      return true;
    }
    if ((partId == 'leg' || partId == 'legs') &&
        (selectedAreas.contains('quads') || selectedAreas.contains('thighs'))) {
      return true;
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const buttonRightX = AnatomyPointerDiagram.buttonWidth;
    final totalHeight = size.height;

    final lineConfigs = options.where((opt) => opt['hasLine'] == true).toList();

    for (final cfg in lineConfigs) {
      final id = cfg['id'] as String;
      final isSelected = _isItemActive(id);
      final btnY = cfg['btnCenterY'] as double;
      final anchorX = (cfg['anchorX'] as double) * size.width;
      final anchorY = (cfg['anchorY'] as double) * totalHeight;

      final lineColor = isSelected
          ? const Color(0xFF00E676)
          : (isDark ? const Color(0xFF2C3932) : const Color(0xFF9CA3AF));
      final lineThickness = isSelected ? 2.2 : 1.0;

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = lineThickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(buttonRightX, btnY);

      if ((btnY - anchorY).abs() < 4) {
        path.lineTo(anchorX, anchorY);
      } else {
        final midX = buttonRightX + ((anchorX - buttonRightX) * 0.42);
        path.lineTo(midX, btnY);
        path.lineTo(midX, anchorY);
        path.lineTo(anchorX, anchorY);
      }
      canvas.drawPath(path, linePaint);

      // Outer Glow when active
      if (isSelected) {
        final glowPaint = Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: 0.38)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
        canvas.drawCircle(Offset(anchorX, anchorY), 12, glowPaint);
      }

      // Outer Ring
      final outerRingPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 : 1.4;
      canvas.drawCircle(Offset(anchorX, anchorY), isSelected ? 6.5 : 4.5, outerRingPaint);

      // Inner Center Dot
      final innerDotPaint = Paint()
        ..color = isSelected ? const Color(0xFF00E676) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(anchorX, anchorY), isSelected ? 3.0 : 1.8, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomyPointerLinesPainter oldDelegate) {
    return oldDelegate.selectedAreas != selectedAreas ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isFemale != isFemale;
  }
}
