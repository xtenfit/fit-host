import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/exercise_submission.dart';
import '../../domain/models/workout_models.dart';
import '../../data/repositories/exercise_submission_repository_impl.dart';

class ExerciseContributionSheet extends ConsumerStatefulWidget {
  final ExerciseEntity? targetExercise; // If provided, this is a correction
  final VoidCallback? onSubmitted;

  const ExerciseContributionSheet({
    super.key,
    this.targetExercise,
    this.onSubmitted,
  });

  @override
  ConsumerState<ExerciseContributionSheet> createState() =>
      _ExerciseContributionSheetState();
}

class _ExerciseContributionSheetState
    extends ConsumerState<ExerciseContributionSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _equipmentController;
  late TextEditingController _targetMuscleController;
  late TextEditingController _secondaryMusclesController;
  late TextEditingController _instructionsController;
  late TextEditingController _safetyNotesController;
  late TextEditingController _rationaleController;

  late String _selectedCategory;
  late String _selectedDifficulty;
  late String _selectedMovementType;
  late String _selectedAudience;

  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Full Body',
  ];

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _movementTypes = ['Compound', 'Isolation'];
  final List<String> _audiences = [
    'universal',
    'male_specific',
    'female_specific',
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.targetExercise;

    _nameController = TextEditingController(text: ex?.name ?? '');
    _equipmentController = TextEditingController(
      text: ex?.equipment ?? 'Dumbbell',
    );
    _targetMuscleController = TextEditingController(
      text: ex?.targetMuscle ?? 'Chest',
    );
    _secondaryMusclesController = TextEditingController(
      text: ex?.secondaryMuscles.join(', ') ?? '',
    );
    _instructionsController = TextEditingController(
      text: ex?.instructions ?? '',
    );
    _safetyNotesController = TextEditingController(text: ex?.safetyNotes ?? '');
    _rationaleController = TextEditingController();

    _selectedCategory = ex?.category ?? 'Chest';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Chest';
    }

    _selectedDifficulty = ex?.difficultyLevel ?? 'Intermediate';
    if (!_difficulties.contains(_selectedDifficulty)) {
      _selectedDifficulty = 'Intermediate';
    }

    _selectedMovementType = ex?.movementType ?? 'Compound';
    if (!_movementTypes.contains(_selectedMovementType)) {
      _selectedMovementType = 'Compound';
    }

    _selectedAudience = ex?.audienceSuitability ?? 'universal';
    if (!_audiences.contains(_selectedAudience)) {
      _selectedAudience = 'universal';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    _targetMuscleController.dispose();
    _secondaryMusclesController.dispose();
    _instructionsController.dispose();
    _safetyNotesController.dispose();
    _rationaleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final secMuscles = _secondaryMusclesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final isCorrection = widget.targetExercise != null;
    final submission = ExerciseSubmission(
      id: const Uuid().v4(),
      submissionType: isCorrection
          ? SubmissionType.correction
          : SubmissionType.newExercise,
      targetExerciseId: widget.targetExercise?.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      equipment: _equipmentController.text.trim(),
      targetMuscle: _targetMuscleController.text.trim(),
      secondaryMuscles: secMuscles,
      instructions: _instructionsController.text.trim(),
      safetyNotes: _safetyNotesController.text.trim().isNotEmpty
          ? _safetyNotesController.text.trim()
          : null,
      difficultyLevel: _selectedDifficulty,
      movementType: _selectedMovementType,
      audienceSuitability: _selectedAudience,
      suggestedRationale: _rationaleController.text.trim(),
      submittedBy: 'guest',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      duplicateHash: '',
    );

    try {
      final repo = ref.read(exerciseSubmissionRepositoryProvider);
      await repo.createSubmission(submission);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCorrection
                  ? 'Correction submitted for moderation review!'
                  : 'New exercise submitted for moderation review!',
            ),
            backgroundColor: AppColors.limeGreenDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('Bad state: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCorrection = widget.targetExercise != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (sheetContext, scrollController) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrection
                                ? 'Suggest Exercise Correction'
                                : 'Propose Community Exercise',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCorrection
                                ? 'Refine instructions, form, or muscle accuracy'
                                : 'Contribute a new movement to Fit Host Wiki',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Wiki Policy & Verification Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.limeGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: AppColors.limeGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fit Host Wiki Moderation Policy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All contributions are reviewed by moderators prior to public catalog ingestion. '
                              'Original licensing and rights provenance cannot be altered. Never submit medical claims.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warmCoral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warmCoral),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.warmCoral,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warmCoral,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Exercise Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name *',
                    hintText: 'e.g. Bulgarian Split Squat with Dumbbells',
                    prefixIcon: Icon(Icons.fitness_center_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Exercise name is required';
                    }
                    if (val.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Category & Difficulty Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          prefixIcon: Icon(Icons.speed_rounded),
                        ),
                        items: _difficulties
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDifficulty = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Equipment & Movement Type Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _equipmentController,
                        decoration: const InputDecoration(
                          labelText: 'Equipment *',
                          hintText: 'e.g. Barbell, Dumbbell, Cable',
                          prefixIcon: Icon(Icons.handyman_outlined),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Equipment is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedMovementType,
                        decoration: const InputDecoration(
                          labelText: 'Movement',
                          prefixIcon: Icon(Icons.sync_alt_rounded),
                        ),
                        items: _movementTypes
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMovementType = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Target Muscle & Secondary Muscles
                TextFormField(
                  controller: _targetMuscleController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Target Muscle *',
                    hintText: 'e.g. Pectoralis Major, Quadriceps, Lats',
                    prefixIcon: Icon(Icons.accessibility_new_rounded),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Target muscle is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _secondaryMusclesController,
                  decoration: const InputDecoration(
                    labelText: 'Secondary / Synergist Muscles',
                    hintText: 'e.g. Triceps, Front Deltoids (comma-separated)',
                    prefixIcon: Icon(Icons.group_work_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Audience Suitability Dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedAudience,
                  decoration: const InputDecoration(
                    labelText: 'Audience Suitability',
                    prefixIcon: Icon(Icons.public_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'universal',
                      child: Text(
                        'Universal (All Athletes)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const DropdownMenuItem(
                      value: 'male_specific',
                      child: Text(
                        'Male Specific Focus',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const DropdownMenuItem(
                      value: 'female_specific',
                      child: Text(
                        'Female Specific Focus',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAudience = val);
                  },
                ),
                const SizedBox(height: 12),

                // Step-by-step Instructions
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Instructions & Form Guidance *',
                    hintText:
                        'Detailed step-by-step guidance on setup, movement path, and completion.',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Instructions are required';
                    }
                    if (val.trim().length < 15) {
                      return 'Please provide at least 15 characters of form guidance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Safety Notes
                TextFormField(
                  controller: _safetyNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Safety & Injury Prevention Notes',
                    hintText:
                        'e.g. Keep wrists stacked; avoid hyperextending lumbar spine.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Suggestion Rationale
                TextFormField(
                  controller: _rationaleController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isCorrection
                        ? 'Rationale for Correction *'
                        : 'Submission Notes',
                    hintText: isCorrection
                        ? 'Why is this correction necessary? (e.g. clarifies grip width, fixes wrong synergist)'
                        : 'Optional references or contextual details for moderators.',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) {
                    if (isCorrection && (val == null || val.trim().isEmpty)) {
                      return 'Please explain the rationale for this correction';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting to Moderation...'
                          : isCorrection
                          ? 'Submit Correction for Review'
                          : 'Submit Exercise for Review',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
