import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/food_item.dart';
import '../widgets/user_food_form_sheet.dart';
import 'quantity_entry_screen.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<FoodItem> _results = [];
  bool _isLoading = false;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialFoods();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialFoods() async {
    setState(() => _isLoading = true);
    try {
      final recents = await ref.read(foodRepositoryProvider).getRecentFoods(limit: 15);
      if (mounted) {
        setState(() {
          _results = recents;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _loadInitialFoods();
      setState(() => _activeQuery = '');
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      setState(() {
        _isLoading = true;
        _activeQuery = trimmed;
      });

      try {
        final matches = await ref.read(foodRepositoryProvider).searchFoods(trimmed);
        if (mounted && _activeQuery == trimmed) {
          setState(() {
            _results = matches;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _openCustomFoodSheet() async {
    final newFood = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UserFoodFormSheet(),
    );

    if (newFood != null && mounted) {
      final logged = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => QuantityEntryScreen(food: newFood),
        ),
      );
      if (logged == true && mounted) {
        context.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Foods'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search food, brand, or barcode...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.limeGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.limeGreen),
              )
            else
              const SizedBox(height: 2),

            // Header info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _activeQuery.isEmpty ? 'RECENT / POPULAR FOODS' : 'SEARCH RESULTS (${_results.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  if (_activeQuery.isNotEmpty)
                    Text(
                      'Per 100g',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: _results.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 54,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _activeQuery.isEmpty ? 'No recent foods yet' : 'No items matching "$_activeQuery"',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try a different keyword or create a custom item.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.limeGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: _openCustomFoodSheet,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Custom Food'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final food = _results[index];
                        return _buildFoodTile(context, food, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.limeGreen,
                    side: const BorderSide(color: AppColors.limeGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openCustomFoodSheet,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text(
                    '+ Add Custom Food',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodTile(BuildContext context, FoodItem food, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final logged = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => QuantityEntryScreen(food: food),
              ),
            );
            if (logged == true && context.mounted) {
              context.pop(true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon or avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _getSourceBadge(food.source),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and brand
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (food.brand != null && food.brand!.isNotEmpty) ...[
                            Text(
                              food.brand!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const Text(' • '),
                          ],
                          Text(
                            '${food.caloriesPer100g.round()} kcal',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.limeGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Macro pill badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'P: ${food.proteinPer100g.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'C: ${food.carbsPer100g.toStringAsFixed(0)}g  F: ${food.fatsPer100g.toStringAsFixed(0)}g',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSourceBadge(FoodSource source) {
    switch (source) {
      case FoodSource.seeded:
        return '🥗';
      case FoodSource.openfoodfacts:
        return '📦';
      case FoodSource.gemini:
        return '📸';
      case FoodSource.user_custom:
        return '⭐';
    }
  }
}
