import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/auth/auth_state_machine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../data/services/gemini_nutrition_service.dart';
import '../../domain/models/photo_meal_draft.dart';
import 'food_search_screen.dart';
import 'quantity_entry_screen.dart';

class PhotoMealScreen extends ConsumerStatefulWidget {
  const PhotoMealScreen({super.key});

  @override
  ConsumerState<PhotoMealScreen> createState() => _PhotoMealScreenState();
}

class _PhotoMealScreenState extends ConsumerState<PhotoMealScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Launch camera automatically on screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authStateMachineProvider).value?.isAuthenticated == true) {
        _pickImage(ImageSource.camera);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        if (_imageFile == null && mounted) {
          // User canceled initial camera take
          return;
        }
        return;
      }

      final compressed = await ImageCompressionService.compressImage(
        File(pickedFile.path),
      );

      setState(() {
        _imageFile = compressed;
        _errorMessage = null;
      });

      await _analyzeMeal(compressed.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to access camera: $e';
        });
      }
    }
  }

  Future<void> _analyzeMeal(String imagePath) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final geminiService = ref.read(geminiNutritionServiceProvider);
      final draft = await geminiService.analyzeMealPhoto(imagePath);

      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      if (draft.confidence < 0.5 || draft.estimatedIngredients.isEmpty) {
        _showLowConfidenceDialog(draft);
      } else {
        // High confidence result
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => QuantityEntryScreen(photoDraft: draft),
          ),
        );
        if (saved == true && mounted) {
          context.pop(true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Failed to analyze meal photo: $e';
      });
    }
  }

  Future<void> _showLowConfidenceDialog(PhotoMealDraft? draft) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.electricCyan),
              SizedBox(width: 8),
              Text('Uncertain Meal'),
            ],
          ),
          content: Text(
            'We couldn\'t clearly identify all ingredients in this photo with high confidence.\n\nWould you like to search manually or try with another photo?',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('retake'),
              child: const Text('Retake Photo'),
            ),
            if (draft != null && draft.estimatedIngredients.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('edit_anyway'),
                child: const Text('Edit Anyway'),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop('manual'),
              child: const Text('Enter Manually'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (choice == 'retake') {
      _pickImage(ImageSource.camera);
    } else if (choice == 'manual') {
      final res = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const FoodSearchScreen()));
      if (res == true && mounted) {
        context.pop(true);
      }
    } else if (choice == 'edit_anyway' && draft != null) {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => QuantityEntryScreen(photoDraft: draft),
        ),
      );
      if (saved == true && mounted) {
        context.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(authStateMachineProvider).value?.isGuest ?? true;
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Snap Meal'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'AI meal photos require an account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use Type / Search to log food locally as a guest.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.push('/auth/sign-up'),
                  child: const Text('Create free account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Snap Meal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            tooltip: 'Choose from Gallery',
            onPressed: _isAnalyzing
                ? null
                : () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image Preview or Empty State
          if (_imageFile != null)
            Image.file(
              _imageFile!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Snap a photo of your plate or beverage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gemini Vision will detect items & estimate macros',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_rounded),
                    label: const Text('Open Camera'),
                  ),
                ],
              ),
            ),

          // Analyzing Backdrop and Indicator
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.electricCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Analyzing Meal Photo...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Detecting ingredients, portion sizes, and macro profiles with Gemini 1.5 Flash',
                        textAlign: TextAlign.center,
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
            ),

          // Error Overlay
          if (_errorMessage != null && !_isAnalyzing)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          child: const Text(
                            'Retake',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            context.push('/nutrition/search-food');
                          },
                          child: const Text(
                            'Enter Manually',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _imageFile != null && !_isAnalyzing
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retake'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _analyzeMeal(_imageFile!.path),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Re-Analyze'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
