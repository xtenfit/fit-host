import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/features/progress/domain/models/body_measurement.dart';
import 'package:fit_host/features/progress/domain/models/measurement_delta.dart';
import 'package:fit_host/features/progress/presentation/controllers/progress_providers.dart';
import 'package:fit_host/core/services/analytics_service.dart';

class BodyMeasurementsScreen extends ConsumerWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(bodyMeasurementsStreamProvider);
    final delta = ref.watch(measurementProgressDeltaProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Measurements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Log Measurement',
            onPressed: () => _showLogMeasurementSheet(context, ref),
          ),
        ],
      ),
      body: measurementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading measurements: $err')),
        data: (measurements) {
          if (measurements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.straighten_rounded,
                        size: 48,
                        color: AppColors.limeGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Measurements Logged',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your weight, body fat percentage, and tape measurements over time to visualize your physical transformation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showLogMeasurementSheet(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Log First Measurement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Overall Progress Delta Hero Card
              if (delta != null) ...[
                _buildDeltaSummaryCard(context, delta, isDark),
                const SizedBox(height: 24),
              ],

              // Latest Measurement Highlight
              _buildLatestHighlightCard(context, measurements.first, isDark),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Measurement History',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${measurements.length} logs',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...measurements.map(
                (m) => _buildMeasurementItem(context, ref, m, isDark),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogMeasurementSheet(context, ref),
        backgroundColor: AppColors.limeGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Log Metric',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDeltaSummaryCard(
    BuildContext context,
    MeasurementProgressDelta delta,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132A22), const Color(0xFF0F1E24)]
              : [const Color(0xFFE8FDF3), const Color(0xFFEFFBF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.limeGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transformation Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.limeGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${delta.elapsedDays} Days Progress',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (delta.weightDeltaKg != null)
                Expanded(
                  child: _buildDeltaPill(
                    label: 'Weight',
                    value:
                        '${delta.weightDeltaKg! > 0 ? '+' : ''}${delta.weightDeltaKg!.toStringAsFixed(1)} kg',
                    isPositiveImprovement: delta.weightDeltaKg! <= 0,
                    isDark: isDark,
                  ),
                ),
              if (delta.bodyFatDelta != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDeltaPill(
                    label: 'Body Fat',
                    value:
                        '${delta.bodyFatDelta! > 0 ? '+' : ''}${delta.bodyFatDelta!.toStringAsFixed(1)}%',
                    isPositiveImprovement: delta.bodyFatDelta! <= 0,
                    isDark: isDark,
                  ),
                ),
              ],
              if (delta.waistDeltaCm != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDeltaPill(
                    label: 'Waist',
                    value:
                        '${delta.waistDeltaCm! > 0 ? '+' : ''}${delta.waistDeltaCm!.toStringAsFixed(1)} cm',
                    isPositiveImprovement: delta.waistDeltaCm! <= 0,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaPill({
    required String label,
    required String value,
    required bool isPositiveImprovement,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isPositiveImprovement
                  ? AppColors.limeGreen
                  : AppColors.warmCoral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestHighlightCard(
    BuildContext context,
    BodyMeasurement m,
    bool isDark,
  ) {
    final dateFormat = DateFormat('EEEE, MMM d, y');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Current Status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(m.measuredAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (m.weightKg != null)
                Expanded(
                  child: _buildMetricTile(
                    label: 'Weight',
                    value: '${m.weightKg!.toStringAsFixed(1)} kg',
                    isDark: isDark,
                  ),
                ),
              if (m.bodyFatPercentage != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Body Fat',
                    value: '${m.bodyFatPercentage!.toStringAsFixed(1)}%',
                    isDark: isDark,
                  ),
                ),
              ],
              if (m.waistCm != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Waist',
                    value: '${m.waistCm!.toStringAsFixed(1)} cm',
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
          if (m.chestCm != null || m.armsCm != null || m.thighsCm != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (m.chestCm != null)
                  _buildSubTag(
                    'Chest: ${m.chestCm!.toStringAsFixed(1)} cm',
                    isDark,
                  ),
                if (m.hipsCm != null)
                  _buildSubTag(
                    'Hips: ${m.hipsCm!.toStringAsFixed(1)} cm',
                    isDark,
                  ),
                if (m.armsCm != null)
                  _buildSubTag(
                    'Arms: ${m.armsCm!.toStringAsFixed(1)} cm',
                    isDark,
                  ),
                if (m.thighsCm != null)
                  _buildSubTag(
                    'Thighs: ${m.thighsCm!.toStringAsFixed(1)} cm',
                    isDark,
                  ),
                if (m.shouldersCm != null)
                  _buildSubTag(
                    'Shoulders: ${m.shouldersCm!.toStringAsFixed(1)} cm',
                    isDark,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222B27) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildMeasurementItem(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement m,
    bool isDark,
  ) {
    final dateFormat = DateFormat('MMM d, y');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dateFormat.format(m.measuredAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: Colors.redAccent.withValues(alpha: 0.8),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Log'),
                      content: const Text(
                        'Are you sure you want to remove this measurement entry?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(bodyMeasurementRepositoryProvider)
                        .deleteMeasurement(m.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (m.weightKg != null)
                _buildMeasurementChip(
                  Icons.scale_rounded,
                  '${m.weightKg!.toStringAsFixed(1)} kg',
                  isDark,
                ),
              if (m.bodyFatPercentage != null)
                _buildMeasurementChip(
                  Icons.pie_chart_outline_rounded,
                  '${m.bodyFatPercentage!.toStringAsFixed(1)}%',
                  isDark,
                ),
              if (m.waistCm != null)
                _buildMeasurementChip(
                  Icons.straighten_rounded,
                  'Waist: ${m.waistCm!.toStringAsFixed(1)} cm',
                  isDark,
                ),
              if (m.chestCm != null)
                _buildMeasurementChip(
                  Icons.fitness_center_rounded,
                  'Chest: ${m.chestCm!.toStringAsFixed(1)} cm',
                  isDark,
                ),
              if (m.armsCm != null)
                _buildMeasurementChip(
                  Icons.sports_gymnastics_rounded,
                  'Arms: ${m.armsCm!.toStringAsFixed(1)} cm',
                  isDark,
                ),
            ],
          ),
          if (m.notes != null && m.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              m.notes!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementChip(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.limeGreen),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showLogMeasurementSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LogMeasurementSheet(),
    );
  }
}

class LogMeasurementSheet extends ConsumerStatefulWidget {
  const LogMeasurementSheet({super.key});

  @override
  ConsumerState<LogMeasurementSheet> createState() =>
      _LogMeasurementSheetState();
}

class _LogMeasurementSheetState extends ConsumerState<LogMeasurementSheet> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _hipsController = TextEditingController();
  final _armsController = TextEditingController();
  final _thighsController = TextEditingController();
  final _calvesController = TextEditingController();
  final _neckController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _measuredAt = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _hipsController.dispose();
    _armsController.dispose();
    _thighsController.dispose();
    _calvesController.dispose();
    _neckController.dispose();
    _shouldersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Record Measurements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  child: Text(
                    DateFormat('MMM d, y').format(_measuredAt),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Primary Metrics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _weightController,
                        label: 'Weight',
                        suffix: 'kg',
                        icon: Icons.scale_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _bodyFatController,
                        label: 'Body Fat',
                        suffix: '%',
                        icon: Icons.pie_chart_outline_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Circumference Tape (cm)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _waistController,
                        label: 'Waist',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _chestController,
                        label: 'Chest',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _hipsController,
                        label: 'Hips',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _armsController,
                        label: 'Arms / Biceps',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _thighsController,
                        label: 'Thighs',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _calvesController,
                        label: 'Calves',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _neckController,
                        label: 'Neck',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _shouldersController,
                        label: 'Shoulders',
                        suffix: 'cm',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (e.g. morning fasted weigh-in)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveMeasurement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save Measurement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    IconData? icon,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _saveMeasurement() async {
    final weight = double.tryParse(_weightController.text.trim());
    final bf = double.tryParse(_bodyFatController.text.trim());
    final waist = double.tryParse(_waistController.text.trim());
    final chest = double.tryParse(_chestController.text.trim());
    final hips = double.tryParse(_hipsController.text.trim());
    final arms = double.tryParse(_armsController.text.trim());
    final thighs = double.tryParse(_thighsController.text.trim());
    final calves = double.tryParse(_calvesController.text.trim());
    final neck = double.tryParse(_neckController.text.trim());
    final shoulders = double.tryParse(_shouldersController.text.trim());
    final notes = _notesController.text.trim();

    if (weight == null &&
        bf == null &&
        waist == null &&
        chest == null &&
        hips == null &&
        arms == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter at least one measurement (e.g. weight or waist).',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final measurement = BodyMeasurement(
        id: const Uuid().v4(),
        userId: 'guest',
        measuredAt: _measuredAt,
        weightKg: weight,
        bodyFatPercentage: bf,
        waistCm: waist,
        chestCm: chest,
        hipsCm: hips,
        armsCm: arms,
        thighsCm: thighs,
        calvesCm: calves,
        neckCm: neck,
        shouldersCm: shoulders,
        notes: notes.isNotEmpty ? notes : null,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await ref
          .read(bodyMeasurementRepositoryProvider)
          .recordMeasurement(measurement);
      AnalyticsService.instance
          .track(AnalyticsEvents.bodyMeasurementLogged)
          .ignore();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurement recorded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save measurement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
