import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fit_host/core/theme/app_colors.dart';

/// A sleek, high-precision Apple-style horizontal ruler slider.
/// Features calibrated major and minor ticks, magnetic snap feel, and real-time readout.
class InteractiveRulerSlider extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double step;
  final ValueChanged<double> onChanged;
  final String unit;
  final int fractionDigits;

  const InteractiveRulerSlider({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    this.step = 1.0,
    required this.onChanged,
    this.unit = '',
    this.fractionDigits = 0,
  });

  @override
  State<InteractiveRulerSlider> createState() => _InteractiveRulerSliderState();
}

class _InteractiveRulerSliderState extends State<InteractiveRulerSlider> {
  late ScrollController _scrollController;
  final double _itemWidth = 14.0; // width per step
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = ((widget.value - widget.minValue) / widget.step).clamp(0, _totalSteps).toDouble();
    _scrollController = ScrollController(
      initialScrollOffset: initialIndex * _itemWidth,
    );
  }

  int get _totalSteps => ((widget.maxValue - widget.minValue) / widget.step).round();

  @override
  void didUpdateWidget(covariant InteractiveRulerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isUserScrolling && (oldWidget.value != widget.value || oldWidget.minValue != widget.minValue || oldWidget.maxValue != widget.maxValue)) {
      final targetIndex = ((widget.value - widget.minValue) / widget.step).clamp(0, _totalSteps).toDouble();
      final targetOffset = targetIndex * _itemWidth;
      if (_scrollController.hasClients && (_scrollController.offset - targetOffset).abs() > 2) {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final index = (offset / _itemWidth).round().clamp(0, _totalSteps);
    final calculatedValue = widget.minValue + (index * widget.step);
    if ((calculatedValue - widget.value).abs() > 0.001) {
      HapticFeedback.selectionClick();
      widget.onChanged(calculatedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final halfScreenWidth = screenWidth / 2;

        return SizedBox(
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ruler Ticks View
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    if (notification.dragDetails != null) {
                      _isUserScrolling = true;
                    }
                  } else if (notification is ScrollUpdateNotification) {
                    _onScroll();
                  } else if (notification is ScrollEndNotification) {
                    if (_isUserScrolling) {
                      _isUserScrolling = false;
                      _snapToNearestStep();
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: halfScreenWidth - (_itemWidth / 2)),
                  itemCount: _totalSteps + 1,
                  itemBuilder: (context, index) {
                    final isMajor = index % 5 == 0;
                    final isNumbered = index % 10 == 0 || (_totalSteps <= 20 && isMajor);
                    final tickValue = widget.minValue + (index * widget.step);

                    return SizedBox(
                      width: _itemWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isNumbered) ...[
                            Text(
                              tickValue.toStringAsFixed(widget.fractionDigits),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextTertiary,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ] else ...[
                            const SizedBox(height: 20),
                          ],
                          Container(
                            width: isMajor ? 2.0 : 1.2,
                            height: isMajor ? 26 : 14,
                            decoration: BoxDecoration(
                              color: isMajor
                                  ? (isDark ? Colors.white60 : Colors.black45)
                                  : (isDark ? Colors.white24 : Colors.black12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Center Pointer Needle
              IgnorePointer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 3.5,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.limeGreen.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // Left & Right Edge Fades (Apple-style gradient mask)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 40,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          (isDark ? AppColors.darkBackground : AppColors.lightBackground).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 40,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? AppColors.darkBackground : AppColors.lightBackground).withValues(alpha: 0.0),
                          isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSnapping = false;

  void _snapToNearestStep() {
    if (!_scrollController.hasClients || _isSnapping) return;
    final offset = _scrollController.offset;
    final index = (offset / _itemWidth).round().clamp(0, _totalSteps);
    final targetOffset = index * _itemWidth;
    if ((offset - targetOffset).abs() < 1.0) return;

    _isSnapping = true;
    _scrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          _isSnapping = false;
        });
  }
}
