import 'package:flutter/material.dart';

class BodyCompositionStep extends StatefulWidget {
  final double? bodyFatPercentage;
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;
  final double? neckCm;
  final Function({
    double? bodyFatPercentage,
    double? waistCm,
    double? hipCm,
    double? chestCm,
    double? neckCm,
  }) onChanged;

  const BodyCompositionStep({
    super.key,
    this.bodyFatPercentage,
    this.waistCm,
    this.hipCm,
    this.chestCm,
    this.neckCm,
    required this.onChanged,
  });

  @override
  State<BodyCompositionStep> createState() => _BodyCompositionStepState();
}

class _BodyCompositionStepState extends State<BodyCompositionStep> {
  late TextEditingController _fatCtrl;
  late TextEditingController _waistCtrl;
  late TextEditingController _hipCtrl;
  late TextEditingController _chestCtrl;
  late TextEditingController _neckCtrl;

  @override
  void initState() {
    super.initState();
    _fatCtrl = TextEditingController(
        text: widget.bodyFatPercentage != null
            ? widget.bodyFatPercentage!.toStringAsFixed(1)
            : '');
    _waistCtrl = TextEditingController(
        text: widget.waistCm != null ? widget.waistCm!.toStringAsFixed(0) : '');
    _hipCtrl = TextEditingController(
        text: widget.hipCm != null ? widget.hipCm!.toStringAsFixed(0) : '');
    _chestCtrl = TextEditingController(
        text: widget.chestCm != null ? widget.chestCm!.toStringAsFixed(0) : '');
    _neckCtrl = TextEditingController(
        text: widget.neckCm != null ? widget.neckCm!.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _fatCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _chestCtrl.dispose();
    _neckCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final fat = double.tryParse(_fatCtrl.text.trim());
    final waist = double.tryParse(_waistCtrl.text.trim());
    final hip = double.tryParse(_hipCtrl.text.trim());
    final chest = double.tryParse(_chestCtrl.text.trim());
    final neck = double.tryParse(_neckCtrl.text.trim());

    widget.onChanged(
      bodyFatPercentage: fat,
      waistCm: waist,
      hipCm: hip,
      chestCm: chest,
      neckCm: neck,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Optional: Body composition',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Color(0xFFF0F6F2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Skip if you don't know these — we'll estimate.",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Color(0xFF8FA396),
            ),
          ),
          const SizedBox(height: 28),

          // 2-column grid
          Row(
            children: [
              Expanded(
                child: _buildInputTile(
                  label: 'BODY FAT %',
                  unit: '%',
                  controller: _fatCtrl,
                  hint: '3 - 60',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputTile(
                  label: 'WAIST',
                  unit: 'cm',
                  controller: _waistCtrl,
                  hint: 'e.g. 82',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInputTile(
                  label: 'HIP',
                  unit: 'cm',
                  controller: _hipCtrl,
                  hint: 'e.g. 96',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputTile(
                  label: 'CHEST',
                  unit: 'cm',
                  controller: _chestCtrl,
                  hint: 'e.g. 102',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInputTile(
            label: 'NECK',
            unit: 'cm',
            controller: _neckCtrl,
            hint: 'e.g. 38',
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF00E676), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Measurements help refine US Navy body fat estimation and muscle balance.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8FA396),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputTile({
    required String label,
    required String unit,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF8FA396),
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8FA396),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF0F6F2),
            ),
            decoration: InputDecoration(
              hintText: 'Skip if unknown',
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8FA396).withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _notify(),
          ),
        ],
      ),
    );
  }
}
