import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/workout_repository.dart'
    show routineRepositoryProvider;
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';
import '../controllers/workout_providers.dart';
import '../widgets/exercise_picker_sheet.dart';

class RoutineBuilderScreen extends ConsumerStatefulWidget {
  final String? routineId;

  const RoutineBuilderScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _BuilderExercise {
  final String id;
  final ExerciseEntity exercise;
  List<RoutineSetEntity> sets;
  String? notes;
  int restSeconds;

  _BuilderExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    this.notes,
    this.restSeconds = 90,
  });
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;

  String _selectedCategory = 'Strength';
  bool _isLoading = true;
  bool _isSaving = false;
  RoutineEntity? _existingRoutine;

  final List<_BuilderExercise> _exercises = [];

  final List<String> _categories = [
    'Strength',
    'Hypertrophy',
    'Cardio',
    'HIIT',
    'Bodyweight',
    'Calisthenics',
    'Mobility',
    'Endurance',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _durationController = TextEditingController(text: '45');
    _loadInitialData();
  }

  @override
  void didUpdateWidget(RoutineBuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routineId != widget.routineId) {
      _isLoading = true;
      _exercises.clear();
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.routineId != null) {
      final repo = ref.read(routineRepositoryProvider);
      final routine = await repo.getRoutineById(widget.routineId!);
      if (routine != null && mounted) {
        _existingRoutine = routine;
        _titleController.text = routine.name;
        _descriptionController.text = routine.description ?? '';
        _durationController.text = routine.estimatedMinutes.toString();
        if (_categories.contains(routine.category)) {
          _selectedCategory = routine.category;
        }

        // Fetch exercise definitions for each routine exercise
        final allExercises = await ref
            .read(workoutRepositoryProvider)
            .getExercises();
        final exMap = {for (var e in allExercises) e.id: e};

        for (final re in routine.exercises) {
          final def =
              exMap[re.exerciseId] ??
              ExerciseEntity(
                id: re.exerciseId,
                name: re.exerciseName,
                category: routine.category,
                targetMuscle: 'General',
                equipment: 'None',
                instructions: 'Proper execution.',
                createdAt: DateTime.now(),
              );

          _exercises.add(
            _BuilderExercise(
              id: re.id,
              exercise: def,
              sets: List.from(re.sets),
              notes: re.notes,
              restSeconds: re.restSeconds ?? 90,
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _addExercise(ExerciseEntity exercise) {
    setState(() {
      final exerciseId = _uuid.v4();
      _exercises.add(
        _BuilderExercise(
          id: exerciseId,
          exercise: exercise,
          restSeconds: 90,
          sets: [
            RoutineSetEntity(
              id: _uuid.v4(),
              routineExerciseId: exerciseId,
              setNumber: 1,
              targetWeightKg: 20.0,
              targetReps: 10,
              targetMinReps: 8,
              targetMaxReps: 12,
              setType: 'normal',
              restSeconds: 90,
            ),
            RoutineSetEntity(
              id: _uuid.v4(),
              routineExerciseId: exerciseId,
              setNumber: 2,
              targetWeightKg: 20.0,
              targetReps: 10,
              targetMinReps: 8,
              targetMaxReps: 12,
              setType: 'normal',
              restSeconds: 90,
            ),
            RoutineSetEntity(
              id: _uuid.v4(),
              routineExerciseId: exerciseId,
              setNumber: 3,
              targetWeightKg: 20.0,
              targetReps: 10,
              targetMinReps: 8,
              targetMaxReps: 12,
              setType: 'normal',
              restSeconds: 90,
            ),
          ],
        ),
      );
    });
  }

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      final ex = _exercises[exerciseIndex];
      final nextSetNumber = ex.sets.length + 1;
      final prevSet = ex.sets.isNotEmpty ? ex.sets.last : null;

      ex.sets.add(
        RoutineSetEntity(
          id: _uuid.v4(),
          routineExerciseId: ex.id,
          setNumber: nextSetNumber,
          targetWeightKg: prevSet?.targetWeightKg ?? 20.0,
          targetReps: prevSet?.targetReps ?? 10,
          targetMinReps: prevSet?.targetMinReps ?? 8,
          targetMaxReps: prevSet?.targetMaxReps ?? 12,
          targetDurationSeconds: prevSet?.targetDurationSeconds,
          targetRpe: prevSet?.targetRpe,
          setType: prevSet?.setType ?? 'normal',
          restSeconds: prevSet?.restSeconds ?? 90,
        ),
      );
    });
  }

  void _removeSetFromExercise(int exerciseIndex, int setIndex) {
    setState(() {
      final ex = _exercises[exerciseIndex];
      ex.sets.removeAt(setIndex);
      // Re-index remaining sets
      for (var i = 0; i < ex.sets.length; i++) {
        final s = ex.sets[i];
        ex.sets[i] = RoutineSetEntity(
          id: s.id,
          routineExerciseId: s.routineExerciseId,
          setNumber: i + 1,
          targetWeightKg: s.targetWeightKg,
          targetReps: s.targetReps,
          targetMinReps: s.targetMinReps,
          targetMaxReps: s.targetMaxReps,
          targetDurationSeconds: s.targetDurationSeconds,
          targetRpe: s.targetRpe,
          setType: s.setType,
          restSeconds: s.restSeconds,
        );
      }
    });
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise to your routine.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final routineId = _existingRoutine?.id ?? _uuid.v4();
      final estimatedMins = int.tryParse(_durationController.text.trim()) ?? 45;

      final routineExercises = <RoutineExerciseEntity>[];
      for (var i = 0; i < _exercises.length; i++) {
        final bEx = _exercises[i];
        final rExId = bEx.id.isNotEmpty ? bEx.id : _uuid.v4();

        final routineSets = <RoutineSetEntity>[];
        for (var sIdx = 0; sIdx < bEx.sets.length; sIdx++) {
          final s = bEx.sets[sIdx];
          routineSets.add(
            RoutineSetEntity(
              id: s.id.isNotEmpty ? s.id : _uuid.v4(),
              routineExerciseId: rExId,
              setNumber: sIdx + 1,
              targetWeightKg: s.targetWeightKg,
              targetReps: s.targetReps,
              targetMinReps: s.targetMinReps,
              targetMaxReps: s.targetMaxReps,
              targetDurationSeconds: s.targetDurationSeconds,
              targetRpe: s.targetRpe,
              setType: s.setType,
              restSeconds: s.restSeconds,
            ),
          );
        }

        routineExercises.add(
          RoutineExerciseEntity(
            id: rExId,
            routineId: routineId,
            exerciseId: bEx.exercise.id,
            exerciseName: bEx.exercise.name,
            category: bEx.exercise.category,
            orderIndex: i,
            notes: bEx.notes,
            restSeconds: bEx.restSeconds,
            sets: routineSets,
          ),
        );
      }

      final routine = RoutineEntity(
        id: routineId,
        userId: _existingRoutine?.userId ?? 'current_user',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        durationMinutes: estimatedMins,
        isCustom: !(_existingRoutine?.isTemplate ?? false),
        exercises: routineExercises,
        createdAt: _existingRoutine?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(routineRepositoryProvider).saveRoutine(routine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingRoutine == null
                  ? 'Routine "${routine.name}" created successfully!'
                  : 'Routine "${routine.name}" updated!',
            ),
            backgroundColor: AppColors.limeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save routine: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openExercisePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExercisePickerSheet(
        onExercisesSelected: (selectedList) {
          Navigator.pop(ctx);
          for (final ex in selectedList) {
            _addExercise(ex);
          }
        },
        onExerciseSelected: (selectedEx) {
          Navigator.pop(ctx);
          _addExercise(selectedEx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Routine Builder')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.limeGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          _existingRoutine == null ? 'Create Routine' : 'Edit Routine',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _saveRoutine,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.limeGreen,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    // Section 1: Routine Metadata Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : Colors.white,
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
                          const Text(
                            'Routine Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Routine Name',
                              hintText: 'e.g. Upper Body Hypertrophy',
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter a routine name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              hintText:
                                  'e.g. Focus on chest overload and shoulder volume',
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              // Category Dropdown
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.darkBackground
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _categories.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCategory = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Duration Input
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Duration',
                                    suffixText: 'min',
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.darkBackground
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Exercises & Sets Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exercises (${_exercises.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openExercisePicker,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: AppColors.limeGreen,
                          ),
                          label: const Text(
                            'Add Exercise',
                            style: TextStyle(
                              color: AppColors.limeGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Empty State or Reorderable Exercises List
                    if (_exercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkSurfaceBorder
                                : AppColors.lightSurfaceBorder,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Exercises Added Yet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap "Add Exercise" to select movements from the catalog.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.limeGreen,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _openExercisePicker,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text(
                                'Browse Exercise Catalog',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exercises.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setState(() {
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, exIdx) {
                          final bEx = _exercises[exIdx];
                          return _buildExerciseCard(
                            key: ValueKey(bEx.id),
                            bEx: bEx,
                            exIndex: exIdx,
                            isDark: isDark,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkSurfaceBorder
                  : AppColors.lightSurfaceBorder,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openExercisePicker,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Exercise'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveRoutine,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _existingRoutine == null
                        ? 'Create Routine'
                        : 'Save Routine',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required Key key,
    required _BuilderExercise bEx,
    required int exIndex,
    required bool isDark,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
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
          // Card Header with Drag Handle, Exercise Title, and Menu
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: exIndex,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bEx.exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bEx.exercise.targetMuscle} • ${bEx.exercise.equipment}',
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
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  tooltip: 'Remove Exercise',
                  onPressed: () {
                    setState(() {
                      _exercises.removeAt(exIndex);
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Sets Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 36,
                  child: Text(
                    'SET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 76,
                  child: Text(
                    'TYPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'KG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 60,
                  child: Text(
                    'REST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // Sets rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bEx.sets.length,
            itemBuilder: (ctx, setIdx) {
              final s = bEx.sets[setIdx];
              return _buildSetRow(
                exerciseIndex: exIndex,
                setIndex: setIdx,
                set: s,
                isDark: isDark,
              );
            },
          ),

          // Add set button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _addSetToExercise(exIndex),
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.limeGreen,
                  ),
                  label: const Text(
                    'Add Set',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ),
                Text(
                  '${bEx.sets.length} sets configured',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow({
    required int exerciseIndex,
    required int setIndex,
    required RoutineSetEntity set,
    required bool isDark,
  }) {
    final targetWeight = set.targetWeightKg ?? 20.0;
    final targetReps = set.targetReps;
    final restSeconds = set.restSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: setIndex.isOdd
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.02))
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Set #
          SizedBox(
            width: 36,
            child: Text(
              '${setIndex + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          // Set Type Dropdown
          SizedBox(
            width: 76,
            child: DropdownButton<String>(
              value: set.setType,
              isDense: true,
              isExpanded: true,
              iconSize: 14,
              padding: EdgeInsets.zero,
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: set.setType == 'warmup'
                    ? const Color(0xFFFFB300)
                    : (set.setType == 'drop'
                          ? const Color(0xFFAB47BC)
                          : (set.setType == 'failure'
                                ? AppColors.error
                                : AppColors.limeGreen)),
              ),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'warmup', child: Text('Warmup')),
                DropdownMenuItem(value: 'drop', child: Text('Drop')),
                DropdownMenuItem(value: 'failure', child: Text('Failure')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _exercises[exerciseIndex].sets[setIndex] = set.copyWith(
                      setType: val,
                    );
                  });
                }
              },
            ),
          ),
          // Weight KG Input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                initialValue: targetWeight.toStringAsFixed(
                  targetWeight % 1 == 0 ? 0 : 1,
                ),
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    _exercises[exerciseIndex].sets[setIndex] = set.copyWith(
                      targetWeightKg: parsed,
                    );
                  }
                },
              ),
            ),
          ),
          // Reps Input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                initialValue: targetReps.toString(),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    _exercises[exerciseIndex].sets[setIndex] = set.copyWith(
                      targetReps: parsed,
                      targetMinReps: (parsed - 2).clamp(1, 99),
                      targetMaxReps: parsed,
                    );
                  }
                },
              ),
            ),
          ),
          // Rest Seconds Input
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                initialValue: restSeconds.toString(),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: 's',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    _exercises[exerciseIndex].sets[setIndex] = set.copyWith(
                      restSeconds: parsed,
                    );
                  }
                },
              ),
            ),
          ),
          // Delete Set
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.grey,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => _removeSetFromExercise(exerciseIndex, setIndex),
            ),
          ),
        ],
      ),
    );
  }
}
