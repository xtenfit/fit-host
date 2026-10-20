import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/database/database.dart';
import '../data/daily_diary_repository.dart';
import '../data/diary_todo_service.dart';
import 'controllers/daily_diary_controller.dart';
import 'widgets/voice_memo_widget.dart';
import 'widgets/daily_todo_checklist_widget.dart';

class DailyDiaryScreen extends ConsumerStatefulWidget {
  const DailyDiaryScreen({super.key});

  @override
  ConsumerState<DailyDiaryScreen> createState() => _DailyDiaryScreenState();
}

class _DailyDiaryScreenState extends ConsumerState<DailyDiaryScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All Logs', 'icon': Icons.apps_rounded, 'color': AppColors.electricCyan},
    {'id': 'work', 'label': 'Work & Career', 'icon': Icons.work_rounded, 'color': Colors.blueAccent},
    {'id': 'professional', 'label': 'Professional', 'icon': Icons.business_center_rounded, 'color': Colors.indigoAccent},
    {'id': 'fitness', 'label': 'Fitness & Body', 'icon': Icons.fitness_center_rounded, 'color': AppColors.limeGreen},
    {'id': 'personal', 'label': 'Personal Life', 'icon': Icons.self_improvement_rounded, 'color': AppColors.warmCoral},
    {'id': 'ideas', 'label': 'Ideas & Insights', 'icon': Icons.lightbulb_rounded, 'color': Color(0xFFF59E0B)},
  ];

  static const List<Map<String, dynamic>> _moods = [
    {'id': 'productive', 'label': 'Productive', 'icon': Icons.trending_up_rounded, 'color': AppColors.limeGreen},
    {'id': 'focused', 'label': 'Focused', 'icon': Icons.center_focus_strong_rounded, 'color': Colors.blueAccent},
    {'id': 'energized', 'label': 'Energized', 'icon': Icons.bolt_rounded, 'color': Color(0xFFFFB300)},
    {'id': 'calm', 'label': 'Calm', 'icon': Icons.spa_rounded, 'color': Colors.teal},
    {'id': 'tired', 'label': 'Exhausted', 'icon': Icons.battery_alert_rounded, 'color': AppColors.warmCoral},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDiarySheet({DailyDiaryEntry? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditDiarySheet(
        existingEntry: existing,
        categories: _categories.where((c) => c['id'] != 'all').toList(),
        moods: _moods,
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    final cat = _categories.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => _categories.first,
    );
    return cat['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedCategory = ref.watch(diarySelectedCategoryProvider);
    final entriesAsync = ref.watch(diaryEntriesStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Daily Work & Life Diary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDiarySheet(),
        backgroundColor: AppColors.limeGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.edit_note_rounded, size: 22),
        label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E172B), const Color(0xFF131722)]
                      : [const Color(0xFFF7F0FF), Colors.white],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.book_rounded, color: Color(0xFFA855F7), size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Life & Career Reflection',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'v1.2.2v2',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFA855F7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Track work breakthroughs, professional duties, workouts, and personal thoughts with text notes and audio voice memos stored locally in your encrypted vault.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily To-Do Checklist (Focus & Habits)
            DailyTodoChecklistWidget(
              dateKey: ref.watch(todayDiaryDateKeyProvider),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(diarySearchQueryProvider.notifier).state = val.trim(),
              decoration: InputDecoration(
                hintText: 'Search notes, work logs, mood...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(diarySearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = selectedCategory == cat['id'];
                  final Color cColor = cat['color'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(cat['icon'], size: 16, color: isSelected ? Colors.black : cColor),
                      label: Text(cat['label']),
                      selectedColor: cColor,
                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.black
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      side: BorderSide(
                        color: isSelected ? cColor : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                      ),
                      onSelected: (val) {
                        if (val) {
                          ref.read(diarySelectedCategoryProvider.notifier).state = cat['id'];
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Entries List
            entriesAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error loading diary entries: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'No Diary Entries Yet',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "+ New Entry" below to record your first work note or audio voice memo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: entries.map((entry) {
                    final catColor = _getCategoryColor(entry.category);
                    final dateStr = '${entry.entryDate.year}-${entry.entryDate.month.toString().padLeft(2, '0')}-${entry.entryDate.day.toString().padLeft(2, '0')}';
                    final timeStr = '${entry.entryDate.hour.toString().padLeft(2, '0')}:${entry.entryDate.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Category, Mood, Date, Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      entry.category.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: catColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      entry.mood,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$dateStr • $timeStr',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz_rounded, size: 20),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showAddEditDiarySheet(existing: entry);
                                      } else if (val == 'delete') {
                                        ref.read(dailyDiaryRepositoryProvider).deleteEntry(entry.id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Note')),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Note', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Title
                          Text(
                            entry.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),

                          // Content Body
                          Text(
                            entry.content,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),

                          // Voice Memo Player if attached
                          if (entry.voiceMemoPath != null && entry.voiceMemoPath!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            VoiceMemoPlayerWidget(
                              audioPath: entry.voiceMemoPath!,
                              totalDurationSeconds: entry.voiceMemoDurationSeconds,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _AddEditDiarySheet extends ConsumerStatefulWidget {
  final DailyDiaryEntry? existingEntry;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> moods;

  const _AddEditDiarySheet({
    this.existingEntry,
    required this.categories,
    required this.moods,
  });

  @override
  ConsumerState<_AddEditDiarySheet> createState() => _AddEditDiarySheetState();
}

class _AddEditDiarySheetState extends ConsumerState<_AddEditDiarySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _selectedCategory;
  late String _selectedMood;
  String? _attachedVoicePath;
  int? _attachedVoiceDuration;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _contentController = TextEditingController(text: e?.content ?? '');
    _selectedCategory = e?.category ?? 'work';
    _selectedMood = e?.mood ?? 'productive';
    _attachedVoicePath = e?.voiceMemoPath;
    _attachedVoiceDuration = e?.voiceMemoDurationSeconds;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an entry title.')),
      );
      return;
    }

    final repo = ref.read(dailyDiaryRepositoryProvider);

    if (widget.existingEntry != null) {
      await repo.updateEntry(
        id: widget.existingEntry!.id,
        title: title,
        content: content,
        category: _selectedCategory,
        mood: _selectedMood,
        voiceMemoPath: _attachedVoicePath,
        voiceMemoDurationSeconds: _attachedVoiceDuration,
      );
    } else {
      await repo.addEntry(
        title: title,
        content: content,
        category: _selectedCategory,
        mood: _selectedMood,
        voiceMemoPath: _attachedVoicePath,
        voiceMemoDurationSeconds: _attachedVoiceDuration,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingEntry != null ? '✅ Entry updated!' : '✅ Diary note saved!'),
          backgroundColor: AppColors.limeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingEntry != null ? 'Edit Diary Note' : 'New Life & Work Log',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title / Highlight',
                hintText: 'e.g. Q4 Strategy Sprint, Leg Day PR, Client Call...',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            // Category Chips
            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.categories.map((c) {
                  final isSelected = _selectedCategory == c['id'];
                  final Color col = c['color'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(c['label']),
                      selectedColor: col,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = c['id']);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Mood Chips
            const Text('Current Mood & State', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.moods.map((m) {
                  final isSelected = _selectedMood == m['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(m['icon'], size: 14, color: isSelected ? Colors.black : m['color']),
                      label: Text(m['label']),
                      selectedColor: m['color'],
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedMood = m['id']);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Note Content
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Reflection Notes & Observations',
                hintText: 'Describe key achievements, work deliverables, mental state, or fitness outcomes...',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),

            // Voice Memo Attachment section
            if (_attachedVoicePath != null) ...[
              VoiceMemoPlayerWidget(
                audioPath: _attachedVoicePath!,
                totalDurationSeconds: _attachedVoiceDuration,
                onDelete: () {
                  setState(() {
                    _attachedVoicePath = null;
                    _attachedVoiceDuration = null;
                  });
                },
              ),
              const SizedBox(height: 12),
            ] else ...[
              VoiceMemoRecorderWidget(
                onRecordingComplete: (path, dur) {
                  setState(() {
                    _attachedVoicePath = path;
                    _attachedVoiceDuration = dur;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  widget.existingEntry != null ? 'Update Diary Note' : 'Save Diary Entry',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
