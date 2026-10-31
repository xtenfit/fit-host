import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/features/progress/domain/models/progress_photo.dart';
import 'package:fit_host/features/progress/presentation/controllers/progress_providers.dart';

class ProgressGalleryScreen extends ConsumerStatefulWidget {
  const ProgressGalleryScreen({super.key});

  @override
  ConsumerState<ProgressGalleryScreen> createState() =>
      _ProgressGalleryScreenState();
}

class _ProgressGalleryScreenState extends ConsumerState<ProgressGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<PhotoPoseType?> _tabs = [
    null, // All
    PhotoPoseType.front,
    PhotoPoseType.side,
    PhotoPoseType.back,
    PhotoPoseType.other,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photo Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_rounded),
            tooltip: 'Before & After Compare',
            onPressed: () => _openComparisonView(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded),
            tooltip: 'Add Photo',
            onPressed: () => _showAddPhotoSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.limeGreen,
          labelColor: AppColors.limeGreen,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          tabs: const [
            Tab(text: 'All Poses'),
            Tab(text: 'Front'),
            Tab(text: 'Side Profile'),
            Tab(text: 'Back View'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((pose) => _PhotoGridView(poseType: pose)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPhotoSheet(context),
        backgroundColor: AppColors.limeGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text(
          'New Photo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _openComparisonView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BeforeAfterComparisonSheet(),
    );
  }

  void _showAddPhotoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddProgressPhotoSheet(),
    );
  }
}

class _PhotoGridView extends ConsumerWidget {
  final PhotoPoseType? poseType;
  const _PhotoGridView({required this.poseType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(progressPhotosStreamProvider(poseType));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading photos: $err')),
      data: (photos) {
        if (photos.isEmpty) {
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
                      Icons.photo_library_outlined,
                      size: 48,
                      color: AppColors.limeGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    poseType != null
                        ? 'No ${poseType!.label} Photos'
                        : 'No Progress Photos Logged',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consistent visual check-ins provide tangible proof of your body composition changes over months of training.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return _buildPhotoCard(context, ref, photo, isDark);
          },
        );
      },
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    WidgetRef ref,
    ProgressPhoto photo,
    bool isDark,
  ) {
    final file = File(photo.photoPath);
    final exists = file.existsSync();
    final dateFormat = DateFormat('MMM d, y');

    return GestureDetector(
      onTap: () => _openPhotoDetail(context, ref, photo),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkSurfaceBorder
                : AppColors.lightSurfaceBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (exists)
              Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(photo),
              )
            else
              _buildPlaceholder(photo),

            // Top Gradient & Pose Badge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        photo.poseType.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.limeGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (photo.weightKgAtPhoto != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${photo.weightKgAtPhoto!.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Info Gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateFormat.format(photo.takenAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (photo.notes != null && photo.notes!.isNotEmpty)
                      Text(
                        photo.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ProgressPhoto photo) {
    return Container(
      color: const Color(0xFF1B2321),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 36,
              color: AppColors.limeGreen,
            ),
            const SizedBox(height: 6),
            Text(
              photo.poseType.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhotoDetail(
    BuildContext context,
    WidgetRef ref,
    ProgressPhoto photo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101614),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                title: Text(
                  '${photo.poseType.label} • ${DateFormat('MMM d, y').format(photo.takenAt)}',
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Photo'),
                          content: const Text(
                            'Are you sure you want to delete this progress photo?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
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
                            .deleteProgressPhoto(photo.id);
                        if (context.mounted) Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
              Flexible(
                child: File(photo.photoPath).existsSync()
                    ? Image.file(File(photo.photoPath), fit: BoxFit.contain)
                    : Container(
                        height: 250,
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
              if (photo.weightKgAtPhoto != null || photo.notes != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (photo.weightKgAtPhoto != null)
                        Text(
                          'Weight: ${photo.weightKgAtPhoto!.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: AppColors.limeGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const Spacer(),
                      if (photo.notes != null)
                        Expanded(
                          child: Text(
                            photo.notes!,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddProgressPhotoSheet extends ConsumerStatefulWidget {
  const AddProgressPhotoSheet({super.key});

  @override
  ConsumerState<AddProgressPhotoSheet> createState() =>
      _AddProgressPhotoSheetState();
}

class _AddProgressPhotoSheetState extends ConsumerState<AddProgressPhotoSheet> {
  final _picker = ImagePicker();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  XFile? _selectedImage;
  PhotoPoseType _poseType = PhotoPoseType.front;
  DateTime _takenAt = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        setState(() => _selectedImage = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  'Add Progress Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _takenAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => _takenAt = picked);
                    }
                  },
                  child: Text(
                    DateFormat('MMM d, y').format(_takenAt),
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
                // Image Picker Preview
                GestureDetector(
                  onTap: () => _showImageSourceDialog(context),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurfaceBorder
                            : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                size: 40,
                                color: AppColors.limeGreen.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to Take or Upload Photo',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Camera or Photo Library',
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
                ),
                const SizedBox(height: 16),

                // Pose Type Segmented Selector
                const Text(
                  'Pose Perspective',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PhotoPoseType.values.map((pose) {
                    final isSelected = _poseType == pose;
                    return ChoiceChip(
                      label: Text(pose.label),
                      selected: isSelected,
                      selectedColor: AppColors.limeGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : null,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _poseType = pose);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Optional Weight Field
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Body Weight at Check-in (Optional)',
                    suffixText: 'kg',
                    prefixIcon: const Icon(Icons.scale_rounded, size: 18),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (e.g. End of 12-week hypertrophy block)',
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
                    onPressed: _isSaving ? null : _savePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text(
                            'Save Progress Photo',
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

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Photo Library'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or capture a photo first.'),
        ),
      );
      return;
    }

    final sourceFile = File(_selectedImage!.path);
    final extension = _selectedImage!.path.split('.').last.toLowerCase();
    const supportedExtensions = {'jpg', 'jpeg', 'png', 'heic', 'heif'};
    if (!supportedExtensions.contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use a JPG, PNG, or HEIC image.')),
      );
      return;
    }
    final sourceSize = await sourceFile.length();
    if (!mounted) return;
    const maxPhotoBytes = 10 * 1024 * 1024;
    if (sourceSize == 0 || sourceSize > maxPhotoBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos must be between 1 byte and 10 MB.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Copy to persistent application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/progress_photos');
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final fileName =
          'progress_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}.jpg';
      final savedFile = await sourceFile.copy('${photoDir.path}/$fileName');

      final weight = double.tryParse(_weightController.text.trim());
      final notes = _notesController.text.trim();

      final currentUserId = ref.read(authProvider).user?.id ?? 'guest';

      final photo = ProgressPhoto(
        id: const Uuid().v4(),
        userId: currentUserId,
        takenAt: _takenAt,
        photoPath: savedFile.path,
        poseType: _poseType,
        weightKgAtPhoto: weight,
        notes: notes.isNotEmpty ? notes : null,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await ref.read(bodyMeasurementRepositoryProvider).addProgressPhoto(photo);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Progress photo saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save photo: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class BeforeAfterComparisonSheet extends ConsumerStatefulWidget {
  const BeforeAfterComparisonSheet({super.key});

  @override
  ConsumerState<BeforeAfterComparisonSheet> createState() =>
      _BeforeAfterComparisonSheetState();
}

class _BeforeAfterComparisonSheetState
    extends ConsumerState<BeforeAfterComparisonSheet> {
  ProgressPhoto? _beforePhoto;
  ProgressPhoto? _afterPhoto;

  @override
  Widget build(BuildContext context) {
    final allPhotosAsync = ref.watch(allProgressPhotosStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
                  'Side-by-Side Transformation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          allPhotosAsync.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Expanded(child: Center(child: Text('Error: $e'))),
            data: (photos) {
              if (photos.length < 2) {
                return const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Upload at least 2 progress photos to compare before & after body transformations.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              // Auto-initialize if null
              _beforePhoto ??= photos.last; // oldest
              _afterPhoto ??= photos.first; // newest

              final dateFormat = DateFormat('MMM d, y');
              final daysBetween = _afterPhoto!.takenAt
                  .difference(_beforePhoto!.takenAt)
                  .inDays
                  .abs();
              final weightDelta =
                  (_beforePhoto!.weightKgAtPhoto != null &&
                      _afterPhoto!.weightKgAtPhoto != null)
                  ? _afterPhoto!.weightKgAtPhoto! -
                        _beforePhoto!.weightKgAtPhoto!
                  : null;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Transformation Metric Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Elapsed Time',
                                  style: TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$daysBetween Days',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            if (weightDelta != null)
                              Column(
                                children: [
                                  const Text(
                                    'Weight Delta',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${weightDelta > 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: weightDelta <= 0
                                          ? AppColors.limeGreen
                                          : AppColors.warmCoral,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Side by side viewer
                      Expanded(
                        child: Row(
                          children: [
                            // Before Photo Pane
                            Expanded(
                              child: _buildComparisonPane(
                                title: 'BEFORE',
                                photo: _beforePhoto!,
                                dateFormat: dateFormat,
                                isDark: isDark,
                                onPickAnother: () =>
                                    _pickPhotoDialog(context, photos, (p) {
                                      setState(() => _beforePhoto = p);
                                    }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // After Photo Pane
                            Expanded(
                              child: _buildComparisonPane(
                                title: 'AFTER',
                                photo: _afterPhoto!,
                                dateFormat: dateFormat,
                                isDark: isDark,
                                onPickAnother: () =>
                                    _pickPhotoDialog(context, photos, (p) {
                                      setState(() => _afterPhoto = p);
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonPane({
    required String title,
    required ProgressPhoto photo,
    required DateFormat dateFormat,
    required bool isDark,
    required VoidCallback onPickAnother,
  }) {
    final file = File(photo.photoPath);
    final exists = file.existsSync();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: title == 'BEFORE'
                    ? Colors.amber.withValues(alpha: 0.2)
                    : AppColors.limeGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: title == 'BEFORE' ? Colors.amber : AppColors.limeGreen,
                ),
              ),
            ),
            InkWell(
              onTap: onPickAnother,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.electricCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSurfaceBorder
                    : AppColors.lightSurfaceBorder,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: exists
                ? Image.file(file, fit: BoxFit.cover, width: double.infinity)
                : Container(
                    color: Colors.black26,
                    child: Center(
                      child: Text(
                        photo.poseType.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dateFormat.format(photo.takenAt),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        if (photo.weightKgAtPhoto != null)
          Text(
            '${photo.weightKgAtPhoto!.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
      ],
    );
  }

  void _pickPhotoDialog(
    BuildContext context,
    List<ProgressPhoto> photos,
    Function(ProgressPhoto) onSelect,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Photo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: photos.length,
            itemBuilder: (c, idx) {
              final p = photos[idx];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.limeGreen.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.limeGreen,
                  ),
                ),
                title: Text(
                  '${p.poseType.label} • ${DateFormat('MMM d, y').format(p.takenAt)}',
                ),
                subtitle: p.weightKgAtPhoto != null
                    ? Text('${p.weightKgAtPhoto} kg')
                    : null,
                onTap: () {
                  onSelect(p);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
