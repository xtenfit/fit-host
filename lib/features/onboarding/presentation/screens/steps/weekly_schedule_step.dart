import 'package:flutter/material.dart';
import '../../../../profile/domain/models/profile_constants.dart';

class WeeklyScheduleStep extends StatefulWidget {
  final int workoutDaysPerWeek;
  final List<int> selectedWeekdays;
  final bool usesEveryDay;
  final int sessionDurationMinutes;
  final Function({
    int? daysPerWeek,
    List<int>? weekdays,
    bool? usesEveryDay,
    int? durationMinutes,
  }) onChanged;

  const WeeklyScheduleStep({
    super.key,
    required this.workoutDaysPerWeek,
    required this.selectedWeekdays,
    required this.usesEveryDay,
    required this.sessionDurationMinutes,
    required this.onChanged,
  });

  @override
  State<WeeklyScheduleStep> createState() => _WeeklyScheduleStepState();
}

class _WeeklyScheduleStepState extends State<WeeklyScheduleStep> {
  late int _daysPerWeek;
  late List<int> _selectedDays;
  late int _durationMinutes;
  late bool _isCustomDuration;
  late TextEditingController _customDurationCtrl;

  @override
  void initState() {
    super.initState();
    _daysPerWeek = widget.workoutDaysPerWeek;
    _selectedDays = List<int>.from(widget.selectedWeekdays);
    _durationMinutes = widget.sessionDurationMinutes;
    _isCustomDuration = ![15, 30, 45, 60, 90].contains(_durationMinutes);
    _customDurationCtrl =
        TextEditingController(text: _durationMinutes.toString());
  }

  @override
  void dispose() {
    _customDurationCtrl.dispose();
    super.dispose();
  }

  void _onSliderChanged(double val) {
    final count = val.round().clamp(1, 7);
    final autoSelected = List<int>.generate(count, (i) => i);
    setState(() {
      _daysPerWeek = count;
      _selectedDays = autoSelected;
    });
    widget.onChanged(
      daysPerWeek: count,
      weekdays: autoSelected,
      usesEveryDay: count == 7,
    );
  }

  void _onDayToggled(int dayIndex) {
    setState(() {
      if (_selectedDays.contains(dayIndex)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(dayIndex);
        }
      } else {
        _selectedDays.add(dayIndex);
        _selectedDays.sort();
      }
      _daysPerWeek = _selectedDays.length;
    });
    widget.onChanged(
      daysPerWeek: _selectedDays.length,
      weekdays: _selectedDays,
      usesEveryDay: _selectedDays.length == 7,
    );
  }

  void _setEveryDay() {
    final allDays = [0, 1, 2, 3, 4, 5, 6];
    setState(() {
      _daysPerWeek = 7;
      _selectedDays = allDays;
    });
    widget.onChanged(
      daysPerWeek: 7,
      weekdays: allDays,
      usesEveryDay: true,
    );
  }

  void _setCustomDuration(int mins) {
    final clamped = mins.clamp(5, 180);
    setState(() {
      _durationMinutes = clamped;
      _customDurationCtrl.text = clamped.toString();
    });
    widget.onChanged(durationMinutes: clamped);
  }

  @override
  Widget build(BuildContext context) {
    final isEveryDay = _daysPerWeek == 7;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan your week',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick days and session length. You can always change later.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 28),

          // SECTION A: DAYS PER WEEK
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DAYS PER WEEK',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF8FA396),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEveryDay ? 'Every day' : '$_daysPerWeek days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1..7 Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _daysPerWeek.toDouble().clamp(1.0, 7.0),
                    min: 1.0,
                    max: 7.0,
                    divisions: 6,
                    onChanged: _onSliderChanged,
                  ),
                ),
                const SizedBox(height: 12),

                // 7 Day Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final dayLabel = kWeekdayLabels[i];
                    final isSelected = _selectedDays.contains(i);

                    return GestureDetector(
                      onTap: () => _onDayToggled(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00E676)
                              : const Color(0xFF0A0F0D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF0A0F0D)
                                  : const Color(0xFFF0F6F2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _setEveryDay,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00E676),
                        side: BorderSide(
                          color: isEveryDay
                              ? const Color(0xFF00E676)
                              : const Color(0xFF00E676).withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Every Day'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedDays = [0, 2, 4]; // Mon, Wed, Fri
                          _daysPerWeek = 3;
                        });
                        widget.onChanged(
                          daysPerWeek: 3,
                          weekdays: _selectedDays,
                          usesEveryDay: false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8FA396),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Custom Days'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION B: SESSION DURATION
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121A16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SESSION DURATION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF8FA396),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_durationMinutes min',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Slider 15..120
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E676),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                    thumbColor: const Color(0xFF00E676),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _durationMinutes.toDouble().clamp(15.0, 120.0),
                    min: 15.0,
                    max: 120.0,
                    divisions: 21, // 5 min steps
                    onChanged: (val) {
                      final m = (val / 5).round() * 5;
                      setState(() {
                        _durationMinutes = m;
                        _isCustomDuration = false;
                        _customDurationCtrl.text = m.toString();
                      });
                      widget.onChanged(durationMinutes: m);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Chips: 15, 30, 45, 60, 90, Custom
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...[15, 30, 45, 60, 90].map((mins) {
                      final isSel = !_isCustomDuration && _durationMinutes == mins;
                      return ChoiceChip(
                        label: Text('$mins min'),
                        selected: isSel,
                        onSelected: (_) {
                          setState(() {
                            _isCustomDuration = false;
                            _durationMinutes = mins;
                            _customDurationCtrl.text = mins.toString();
                          });
                          widget.onChanged(durationMinutes: mins);
                        },
                        selectedColor: const Color(0xFF00E676),
                        backgroundColor: const Color(0xFF0A0F0D),
                        labelStyle: TextStyle(
                          color: isSel
                              ? const Color(0xFF0A0F0D)
                              : const Color(0xFFF0F6F2),
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSel
                                ? const Color(0xFF00E676)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _isCustomDuration,
                      onSelected: (_) {
                        setState(() {
                          _isCustomDuration = true;
                        });
                      },
                      selectedColor: const Color(0xFF00E676),
                      backgroundColor: const Color(0xFF0A0F0D),
                      labelStyle: TextStyle(
                        color: _isCustomDuration
                            ? const Color(0xFF0A0F0D)
                            : const Color(0xFFF0F6F2),
                        fontWeight:
                            _isCustomDuration ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _isCustomDuration
                              ? const Color(0xFF00E676)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_isCustomDuration) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customDurationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Minutes (5–180)',
                            labelStyle: const TextStyle(
                                color: Color(0xFF8FA396), fontSize: 13),
                            suffixText: 'min',
                            suffixStyle:
                                const TextStyle(color: Color(0xFF00E676)),
                            filled: true,
                            fillColor: const Color(0xFF0A0F0D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF00E676)),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val.trim());
                            if (parsed != null &&
                                parsed >= 5 &&
                                parsed <= 180) {
                              _setCustomDuration(parsed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
