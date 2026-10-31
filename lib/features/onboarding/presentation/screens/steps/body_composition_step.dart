import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';

class BodyCompositionStep extends StatefulWidget {
  final double? weightKg;
  final double? bodyFatPercentage;
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;
  final double? neckCm;
  final double? armsCm;
  final double? thighsCm;
  final double? calvesCm;
  final double? shouldersCm;
  final String? notes;
  final bool useMetricUnits;
  final Function({
    double? weightKg,
    double? bodyFatPercentage,
    double? waistCm,
    double? hipCm,
    double? chestCm,
    double? armsCm,
    double? thighsCm,
    double? calvesCm,
    double? neckCm,
    double? shouldersCm,
    String? notes,
  })
  onChanged;

  const BodyCompositionStep({
    super.key,
    this.weightKg,
    this.bodyFatPercentage,
    this.waistCm,
    this.hipCm,
    this.chestCm,
    this.neckCm,
    this.armsCm,
    this.thighsCm,
    this.calvesCm,
    this.shouldersCm,
    this.notes,
    this.useMetricUnits = true,
    required this.onChanged,
  });

  @override
  State<BodyCompositionStep> createState() => _BodyCompositionStepState();
}

class _BodyCompositionStepState extends State<BodyCompositionStep> {
  late bool _useInches;
  late DateTime _measuredAt;

  late TextEditingController _weightCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _waistCtrl;
  late TextEditingController _chestCtrl;
  late TextEditingController _hipCtrl;
  late TextEditingController _armsCtrl;
  late TextEditingController _thighsCtrl;
  late TextEditingController _calvesCtrl;
  late TextEditingController _neckCtrl;
  late TextEditingController _shouldersCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _useInches = !widget.useMetricUnits;
    _measuredAt = DateTime.now();

    final wKg = widget.weightKg;
    _weightCtrl = TextEditingController(
      text: wKg != null && wKg > 0
          ? (_useInches
                ? (wKg * 2.20462).toStringAsFixed(1)
                : wKg.toStringAsFixed(1))
          : '',
    );
    _fatCtrl = TextEditingController(
      text: widget.bodyFatPercentage != null && widget.bodyFatPercentage! > 0
          ? (widget.bodyFatPercentage! % 1 == 0
                ? widget.bodyFatPercentage!.toInt().toString()
                : widget.bodyFatPercentage!.toStringAsFixed(1))
          : '',
    );
    _waistCtrl = TextEditingController(
      text: _formatCircumference(widget.waistCm),
    );
    _chestCtrl = TextEditingController(
      text: _formatCircumference(widget.chestCm),
    );
    _hipCtrl = TextEditingController(text: _formatCircumference(widget.hipCm));
    _armsCtrl = TextEditingController(
      text: _formatCircumference(widget.armsCm),
    );
    _thighsCtrl = TextEditingController(
      text: _formatCircumference(widget.thighsCm),
    );
    _calvesCtrl = TextEditingController(
      text: _formatCircumference(widget.calvesCm),
    );
    _neckCtrl = TextEditingController(
      text: _formatCircumference(widget.neckCm),
    );
    _shouldersCtrl = TextEditingController(
      text: _formatCircumference(widget.shouldersCm),
    );
    _notesCtrl = TextEditingController(text: widget.notes ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _fatCtrl.dispose();
    _waistCtrl.dispose();
    _chestCtrl.dispose();
    _hipCtrl.dispose();
    _armsCtrl.dispose();
    _thighsCtrl.dispose();
    _calvesCtrl.dispose();
    _neckCtrl.dispose();
    _shouldersCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatCircumference(double? cm) {
    if (cm == null || cm <= 0) return '';
    if (_useInches) {
      final val = ((cm / 2.54) * 10).round() / 10;
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
    } else {
      final val = (cm * 10).round() / 10;
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
    }
  }

  double? _parseCircumference(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null || parsed <= 0) return null;
    return _useInches ? parsed * 2.54 : parsed;
  }

  void _syncControllersOnUnitToggle() {
    _waistCtrl.text = _formatCircumference(
      _parseCircumference(_waistCtrl.text),
    );
    _chestCtrl.text = _formatCircumference(
      _parseCircumference(_chestCtrl.text),
    );
    _hipCtrl.text = _formatCircumference(_parseCircumference(_hipCtrl.text));
    _armsCtrl.text = _formatCircumference(_parseCircumference(_armsCtrl.text));
    _thighsCtrl.text = _formatCircumference(
      _parseCircumference(_thighsCtrl.text),
    );
    _calvesCtrl.text = _formatCircumference(
      _parseCircumference(_calvesCtrl.text),
    );
    _neckCtrl.text = _formatCircumference(_parseCircumference(_neckCtrl.text));
    _shouldersCtrl.text = _formatCircumference(
      _parseCircumference(_shouldersCtrl.text),
    );
  }

  void _notify() {
    final weightRaw = double.tryParse(_weightCtrl.text.trim());
    double? weightKg;
    if (weightRaw != null && weightRaw > 0) {
      weightKg = _useInches ? weightRaw / 2.20462 : weightRaw;
    }

    final fat = double.tryParse(_fatCtrl.text.trim());
    final waist = _parseCircumference(_waistCtrl.text);
    final hip = _parseCircumference(_hipCtrl.text);
    final chest = _parseCircumference(_chestCtrl.text);
    final arms = _parseCircumference(_armsCtrl.text);
    final thighs = _parseCircumference(_thighsCtrl.text);
    final calves = _parseCircumference(_calvesCtrl.text);
    final neck = _parseCircumference(_neckCtrl.text);
    final shoulders = _parseCircumference(_shouldersCtrl.text);
    final notes = _notesCtrl.text.trim();

    widget.onChanged(
      weightKg: weightKg,
      bodyFatPercentage: fat,
      waistCm: waist,
      hipCm: hip,
      chestCm: chest,
      armsCm: arms,
      thighsCm: thighs,
      calvesCm: calves,
      neckCm: neck,
      shouldersCm: shoulders,
      notes: notes.isNotEmpty ? notes : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = _useInches ? 'in' : 'cm';
    final weightUnit = _useInches ? 'lbs' : 'kg';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Date Picker Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record Measurements',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF0F6F2),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Optional: Baseline calibration & body composition',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8FA396)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _measuredAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    setState(() => _measuredAt = picked);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  foregroundColor: AppColors.electricBlue,
                ),
                child: Text(
                  DateFormat('MMM d, y').format(_measuredAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary Metrics (Weight & Body Fat)
          const Text(
            'Primary Metrics',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _weightCtrl,
                  label: 'Weight',
                  suffix: weightUnit,
                  icon: Icons.scale_rounded,
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _fatCtrl,
                  label: 'Body Fat',
                  suffix: '%',
                  icon: Icons.pie_chart_outline_rounded,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Circumference Tape Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _useInches
                    ? 'Circumference Tape (in)'
                    : 'Circumference Tape (cm)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F6F2),
                ),
              ),
              _buildUnitToggle(
                option1: 'in',
                option2: 'cm',
                isOption1: _useInches,
                onToggle: (val) {
                  setState(() {
                    _useInches = val;
                    _syncControllersOnUnitToggle();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 1: Waist, Chest
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _waistCtrl,
                  label: 'Waist',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _chestCtrl,
                  label: 'Chest',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Hips, Arms / Biceps
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _hipCtrl,
                  label: 'Hips',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _armsCtrl,
                  label: 'Arms / Biceps',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Thighs, Calves
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _thighsCtrl,
                  label: 'Thighs',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _calvesCtrl,
                  label: 'Calves',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 4: Neck, Shoulders
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _neckCtrl,
                  label: 'Neck',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _shouldersCtrl,
                  label: 'Shoulders',
                  suffix: unit,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: Color(0xFFF0F6F2)),
            decoration: InputDecoration(
              labelText: 'Notes (e.g. morning fasted weigh-in)',
              labelStyle: const TextStyle(
                color: Color(0xFF8FA396),
                fontSize: 13,
              ),
              floatingLabelStyle: const TextStyle(
                color: AppColors.electricBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color(0xFF161F1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.electricBlue,
                  width: 1.8,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    IconData? icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF0F6F2),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8FA396), fontSize: 13),
        floatingLabelStyle: const TextStyle(
          color: AppColors.electricBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Color(0xFF8FA396), fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: const Color(0xFF8FA396))
            : null,
        filled: true,
        fillColor: const Color(0xFF161F1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.electricBlue,
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildUnitToggle({
    required String option1,
    required String option2,
    required bool isOption1,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onToggle(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOption1 ? const Color(0xFF00E676) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                option1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOption1 ? Colors.black : const Color(0xFF8FA396),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onToggle(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !isOption1
                    ? const Color(0xFF00E676)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                option2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !isOption1 ? Colors.black : const Color(0xFF8FA396),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
