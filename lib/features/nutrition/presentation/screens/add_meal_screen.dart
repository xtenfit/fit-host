import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state_machine.dart';
import '../../../auth/presentation/dialogs/feature_upsell_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/food_item.dart';
import 'quantity_entry_screen.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  List<FoodItem> _recentFoods = [];
  bool _isLoadingRecents = true;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    try {
      final recents = await ref
          .read(foodRepositoryProvider)
          .getRecentFoods(limit: 8);
      if (mounted) {
        setState(() {
          _recentFoods = recents;
          _isLoadingRecents = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecents = false);
      }
    }
  }

  Future<void> _openAccountFeature({
    required String title,
    required String description,
    required IconData icon,
  }) async {
    final auth = ref.read(authStateMachineProvider).value;
    if (auth?.isAuthenticated == true) {
      if (mounted) {
        context.push(
          title == 'Barcode scanning'
              ? '/nutrition/scan-barcode'
              : '/nutrition/snap-meal',
        );
      }
      return;
    }

    await FeatureUpsellSheet.show(
      context,
      title: title,
      description: description,
      icon: icon,
      benefits: const [
        'Keep your nutrition diary on this device while using guest mode',
        'Unlock barcode scanning and AI-assisted meal analysis',
        'Preserve your guest records when you create an account',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Meal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  Text(
                    'How would you like to log?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Scan Barcode
                  _buildOptionCard(
                    context: context,
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Scan Barcode',
                    subtitle:
                        'Instant nutritional facts lookup from packaged goods',
                    accentColor: AppColors.limeGreen,
                    onTap: () => _openAccountFeature(
                      title: 'Barcode scanning',
                      description:
                          'Create an account to use barcode lookup while keeping your existing guest diary.',
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option 2: Snap Meal (Gemini Vision)
                  _buildOptionCard(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    title: 'Snap Meal',
                    subtitle: 'AI photo breakdown into ingredients and macros',
                    accentColor: AppColors.electricCyan,
                    badge: 'Gemini AI',
                    onTap: () => _openAccountFeature(
                      title: 'AI meal photos',
                      description:
                          'AI photo analysis is available for account holders. Your guest food logs remain local.',
                      icon: Icons.camera_alt_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option 3: Describe Meal (AI Smart Text)
                  _buildOptionCard(
                    context: context,
                    icon: Icons.auto_awesome_rounded,
                    title: 'Describe Meal',
                    subtitle:
                        'Type "2 rotis, dal, and 150g curd" for instant AI parsing',
                    accentColor: AppColors.amberWarning,
                    badge: 'AI Text',
                    onTap: () async {
                      final auth = ref.read(authStateMachineProvider).value;
                      if (auth?.isAuthenticated == true) {
                        _showDescribeMealDialog(context);
                      } else {
                        await _openAccountFeature(
                          title: 'AI meal descriptions',
                          description:
                              'Create an account to turn meal descriptions into nutrition entries.',
                          icon: Icons.auto_awesome_rounded,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Option 4: Type / Search
                  _buildOptionCard(
                    context: context,
                    icon: Icons.search_rounded,
                    title: 'Type / Search',
                    subtitle:
                        'Search database of 120+ staples or create custom items',
                    accentColor: AppColors.electricBlueLight,
                    onTap: () => context.push('/nutrition/search-food'),
                  ),
                ],
              ),
            ),

            // Bottom Section: Recent Foods
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Foods',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingRecents)
                    const SizedBox(
                      height: 38,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_recentFoods.isEmpty)
                    Text(
                      'No meals logged yet. Start scanning above!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _recentFoods.map((food) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightSurfaceElevated,
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkSurfaceBorder
                                    : AppColors.lightSurfaceBorder,
                              ),
                              label: Text(
                                food.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              avatar: const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: AppColors.limeGreen,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        QuantityEntryScreen(food: food),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.electricCyan.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.electricCyan,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDescribeMealDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = TextEditingController();
    bool isAnalyzing = false;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.amberWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 20,
                          color: AppColors.amberWarning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Describe Your Meal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'AI converts natural language into verified macros',
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
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Two rotis, one bowl of dal, and 150g curd\nor: 1 banana and 250ml milk',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkSurfaceBorder
                              : AppColors.lightSurfaceBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.amberWarning,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick suggestion chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickChip(
                          '2 rotis & dal',
                          () => setModalState(
                            () => controller.text =
                                'Two rotis and one bowl of dal',
                          ),
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          '1 banana & milk',
                          () => setModalState(
                            () => controller.text = 'One banana and 250ml milk',
                          ),
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          'Paneer & paratha',
                          () => setModalState(
                            () => controller.text =
                                '100g paneer bhurji and 2 parathas',
                          ),
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          'Oats & berries',
                          () => setModalState(
                            () => controller.text =
                                '40g oats with milk and berries',
                          ),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberWarning,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isAnalyzing
                          ? null
                          : () async {
                              final text = controller.text.trim();
                              if (text.isEmpty) {
                                setModalState(() {
                                  localError = 'Please describe what you ate';
                                });
                                return;
                              }

                              setModalState(() {
                                isAnalyzing = true;
                                localError = null;
                              });

                              try {
                                final service = ref.read(
                                  geminiNutritionServiceProvider,
                                );
                                final draft = await service.analyzeMealText(
                                  text,
                                );

                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop(); // Close sheet

                                if (context.mounted) {
                                  final saved = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => QuantityEntryScreen(
                                            photoDraft: draft,
                                          ),
                                        ),
                                      );

                                  if (saved == true && context.mounted) {
                                    context.pop(true);
                                  }
                                }
                              } catch (e) {
                                setModalState(() {
                                  isAnalyzing = false;
                                  localError = 'Failed to parse meal: $e';
                                });
                              }
                            },
                      child: isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Analyze & Log Meal',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isDark) {
    return ActionChip(
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      backgroundColor: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightSurfaceElevated,
      side: BorderSide(
        color: isDark
            ? AppColors.darkSurfaceBorder
            : AppColors.lightSurfaceBorder,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      onPressed: onTap,
    );
  }
}
