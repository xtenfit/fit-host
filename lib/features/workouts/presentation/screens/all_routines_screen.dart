import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/workout_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_models.dart';
import '../controllers/workout_providers.dart';

class AllRoutinesScreen extends ConsumerStatefulWidget {
  const AllRoutinesScreen({super.key});

  @override
  ConsumerState<AllRoutinesScreen> createState() => _AllRoutinesScreenState();
}

class _AllRoutinesScreenState extends ConsumerState<AllRoutinesScreen> {
  String _selectedCategory = 'All';
  String _typeFilter = 'All'; // 'All', 'Templates', 'Custom'
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Strength',
    'Hypertrophy',
    'Cardio',
    'HIIT',
    'Bodyweight',
    'Calisthenics',
    'Mobility',
  ];

  void _startRoutine(RoutineEntity routine) {
    ref.read(activeWorkoutProvider.notifier).startFromRoutine(routine);
    if (mounted) {
      context.push('/active-workout');
    }
  }

  Future<void> _duplicateRoutine(RoutineEntity routine) async {
    try {
      final copyName = '${routine.name} (Copy)';
      await ref
          .read(routineRepositoryProvider)
          .duplicateRoutine(routine.id, newName: copyName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routine duplicated: "$copyName"'),
            backgroundColor: AppColors.limeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate routine: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoutine(RoutineEntity routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine?'),
        content: Text(
          'Are you sure you want to delete "${routine.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(routineRepositoryProvider).deleteRoutine(routine.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Routine "${routine.name}" deleted.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting routine: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final routinesAsync = ref.watch(routinesStreamProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Workout Routines & Plans',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Routine',
            onPressed: () => context.push('/routines/builder'),
          ),
          IconButton(
            icon: const Icon(Icons.fitness_center_rounded),
            tooltip: 'Start Empty Workout',
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).startNewWorkout();
              context.push('/active-workout');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.limeGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Routine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => context.push('/routines/builder'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search routines, splits or muscle targets...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkSurfaceBorder
                          : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkSurfaceBorder
                          : AppColors.lightSurfaceBorder,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Filter Tabs: All vs Templates vs Custom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildTypeTab('All', isDark),
                  const SizedBox(width: 8),
                  _buildTypeTab('Templates', isDark),
                  const SizedBox(width: 8),
                  _buildTypeTab('Custom', isDark),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 3. Category Filter Pills
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (ctx, idx) {
                  final cat = _categories[idx];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      selectedColor: AppColors.limeGreen,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.limeGreen
                            : (isDark
                                  ? AppColors.darkSurfaceBorder
                                  : AppColors.lightSurfaceBorder),
                      ),
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // 4. Routines List Stream
            Expanded(
              child: routinesAsync.when(
                data: (allRoutines) {
                  final filtered = allRoutines.where((r) {
                    // Type filter
                    if (_typeFilter == 'Templates' && !r.isTemplate) {
                      return false;
                    }
                    if (_typeFilter == 'Custom' && r.isTemplate) return false;

                    // Category filter
                    if (_selectedCategory != 'All' &&
                        r.category != _selectedCategory) {
                      return false;
                    }

                    // Search query
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      final matchesName = r.name.toLowerCase().contains(q);
                      final matchesDesc = (r.description ?? '')
                          .toLowerCase()
                          .contains(q);
                      final matchesEx = r.exercises.any(
                        (e) => e.exerciseName.toLowerCase().contains(q),
                      );
                      if (!matchesName && !matchesDesc && !matchesEx) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
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
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching routines found'
                                : (_typeFilter == 'Custom'
                                      ? 'No custom routines yet'
                                      : 'No routines found'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _typeFilter == 'Custom'
                                ? 'Tap "+ New Routine" below to build your first routine.'
                                : 'Try adjusting your search query or category filters.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final r = filtered[idx];
                      return _buildRoutineCard(r, isDark);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.limeGreen),
                ),
                error: (err, _) =>
                    Center(child: Text('Error loading routines: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, bool isDark) {
    final isSelected = _typeFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _typeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.limeGreen.withValues(alpha: 0.2)
                    : const Color(0xFFDCFCE7))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.limeGreen : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? AppColors.limeGreen : const Color(0xFF166534))
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineCard(RoutineEntity r, bool isDark) {
    final exercisesPreview = r.exercises.isNotEmpty
        ? r.exercises.map((e) => e.exerciseName).take(3).join(', ') +
              (r.exercises.length > 3 ? ' +${r.exercises.length - 3} more' : '')
        : 'Empty routine';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _startRoutine(r),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.limeGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (r.isTemplate)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.electricCyan.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TEMPLATE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.electricCyan,
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              onSelected: (action) {
                                if (action == 'edit') {
                                  context.push('/routines/builder?id=${r.id}');
                                } else if (action == 'duplicate') {
                                  _duplicateRoutine(r);
                                } else if (action == 'delete') {
                                  _deleteRoutine(r);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit Routine'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Duplicate'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.limeGreen.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.limeGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${r.estimatedMinutes} mins • ${r.exercises.length} exercises',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (r.description != null && r.description!.isNotEmpty) ...[
                Text(
                  r.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                exercisesPreview,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${r.exercises.fold<int>(0, (sum, e) => sum + e.sets.length)} total sets',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'Start Workout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    onPressed: () => _startRoutine(r),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
