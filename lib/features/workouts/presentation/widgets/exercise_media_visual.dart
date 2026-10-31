import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/exercise_media_service.dart';
import '../../../../core/theme/app_colors.dart';

enum ExerciseMediaVisualMode {
  /// Small thumbnail for list items and exercise picker tiles (48x48 to 64x64)
  thumbnail,

  /// Interactive animated GIF player with looping and pause/play controls
  player,

  /// Hero visual banner for workout active screens and modal headers
  hero,
}

/// A premium, responsive exercise visual widget that renders exercise animated GIFs
/// and 180x180 thumbnails from remote CDN storage with disk caching, offline fallbacks,
/// request cancellation, and graceful error handling.
class ExerciseMediaVisual extends StatefulWidget {
  final String? mediaAnimationUrl;
  final String? mediaThumbnailUrl;
  final String? imageAsset;
  final String? anatomyAsset;
  final String category;
  final String exerciseName;
  final ExerciseMediaVisualMode mode;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showBadge;
  final bool isDark;
  final VoidCallback? onTap;

  const ExerciseMediaVisual({
    super.key,
    this.mediaAnimationUrl,
    this.mediaThumbnailUrl,
    this.imageAsset,
    this.anatomyAsset,
    required this.category,
    required this.exerciseName,
    this.mode = ExerciseMediaVisualMode.thumbnail,
    this.width,
    this.height,
    this.borderRadius,
    this.showBadge = true,
    this.isDark = true,
    this.onTap,
  });

  @override
  State<ExerciseMediaVisual> createState() => _ExerciseMediaVisualState();
}

class _ExerciseMediaVisualState extends State<ExerciseMediaVisual> {
  bool _isPlaying = true;
  bool _isShowingAnatomy = false;

  File? _cachedThumbFile;
  File? _cachedAnimFile;
  bool _isLoadingThumb = false;
  bool _isLoadingAnim = false;
  bool _thumbFailed = false;
  bool _animFailed = false;

  CancelToken? _cancelToken;

  static const String _fallbackCdnBase =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/master/';

  @override
  void initState() {
    super.initState();
    _cancelToken = CancelToken();
    _loadMedia();
  }

  @override
  void didUpdateWidget(covariant ExerciseMediaVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaThumbnailUrl != widget.mediaThumbnailUrl ||
        oldWidget.mediaAnimationUrl != widget.mediaAnimationUrl ||
        oldWidget.mode != widget.mode) {
      _cancelToken?.cancel('Widget updated');
      _cancelToken = CancelToken();
      _cachedThumbFile = null;
      _cachedAnimFile = null;
      _thumbFailed = false;
      _animFailed = false;
      _loadMedia();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Widget disposed');
    super.dispose();
  }

  String? _resolveUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    // Prefer fallback direct GitHub CDN if custom domain is not yet active
    return '$_fallbackCdnBase$cleanPath';
  }

  void _loadMedia() {
    final thumbUrl = _resolveUrl(widget.mediaThumbnailUrl);
    final animUrl = _resolveUrl(widget.mediaAnimationUrl);

    if (thumbUrl != null) {
      _loadThumbnail(thumbUrl);
    }
    if ((widget.mode == ExerciseMediaVisualMode.player ||
            widget.mode == ExerciseMediaVisualMode.hero) &&
        animUrl != null) {
      _loadAnimation(animUrl);
    }
  }

  Future<void> _loadThumbnail(String url) async {
    final service = ExerciseMediaService();
    // 1. Instant cache check
    final cached = await service.getCachedFile(url, isThumbnail: true);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _cachedThumbFile = cached;
        _isLoadingThumb = false;
        _thumbFailed = false;
      });
      return;
    }

    // 2. Fetch remote media
    setState(() {
      _isLoadingThumb = true;
      _thumbFailed = false;
    });

    try {
      final file = await service.loadMedia(
        url: url,
        isThumbnail: true,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      setState(() {
        _cachedThumbFile = file;
        _isLoadingThumb = false;
        _thumbFailed = (file == null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingThumb = false;
        _thumbFailed = true;
      });
    }
  }

  Future<void> _loadAnimation(String url) async {
    final service = ExerciseMediaService();
    // 1. Instant cache check
    final cached = await service.getCachedFile(url, isThumbnail: false);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _cachedAnimFile = cached;
        _isLoadingAnim = false;
        _animFailed = false;
      });
      return;
    }

    // 2. Fetch remote media
    setState(() {
      _isLoadingAnim = true;
      _animFailed = false;
    });

    try {
      final file = await service.loadMedia(
        url: url,
        isThumbnail: false,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      setState(() {
        _cachedAnimFile = file;
        _isLoadingAnim = false;
        _animFailed = (file == null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingAnim = false;
        _animFailed = true;
      });
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center_rounded;
      case 'back':
        return Icons.accessibility_new_rounded;
      case 'legs':
      case 'upper legs':
      case 'lower legs':
        return Icons.directions_walk_rounded;
      case 'arms':
      case 'upper arms':
      case 'lower arms':
        return Icons.sports_kabaddi_rounded;
      case 'shoulders':
        return Icons.accessibility_rounded;
      case 'core':
      case 'waist':
      case 'abs':
        return Icons.shield_rounded;
      case 'cardio':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  void _openFullScreenViewer(
    BuildContext context,
    String? resolvedUrl,
    File? cachedFile,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF14181F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.limeGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.exerciseName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (cachedFile != null)
                          Image.file(
                            cachedFile,
                            height: 220,
                            fit: BoxFit.contain,
                          )
                        else if (resolvedUrl != null)
                          Image.network(
                            resolvedUrl,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                _buildFallbackIcon(size: 48),
                          )
                        else
                          _buildFallbackIcon(size: 48),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Motion Visual: Gym visual • Licensed exercise dataset',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case ExerciseMediaVisualMode.thumbnail:
        return _buildThumbnail(context);
      case ExerciseMediaVisualMode.player:
        return _buildPlayer(context);
      case ExerciseMediaVisualMode.hero:
        return _buildHero(context);
    }
  }

  Widget _buildThumbnail(BuildContext context) {
    final w = widget.width ?? 52.0;
    final h = widget.height ?? 52.0;
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    final resolvedThumb =
        _resolveUrl(widget.mediaThumbnailUrl) ??
        _resolveUrl(widget.mediaAnimationUrl);

    Widget content;

    if (widget.imageAsset != null && widget.imageAsset!.isNotEmpty) {
      content = Image.asset(
        widget.imageAsset!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallbackIcon(size: w * 0.45),
      );
    } else if (_cachedThumbFile != null) {
      content = Image.file(
        _cachedThumbFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallbackIcon(size: w * 0.45),
      );
    } else if (_isLoadingThumb) {
      content = Center(
        child: SizedBox(
          width: w * 0.35,
          height: w * 0.35,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: widget.isDark
                ? AppColors.limeGreen
                : AppColors.limeGreenDark,
          ),
        ),
      );
    } else if (resolvedThumb != null && !_thumbFailed) {
      content = Image.network(
        resolvedThumb,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallbackIcon(size: w * 0.45),
      );
    } else {
      content = _buildFallbackIcon(size: w * 0.45);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: w,
        height: h,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF14181F) : Colors.white,
          borderRadius: radius,
          border: Border.all(
            color: widget.isDark
                ? AppColors.darkSurfaceBorder
                : AppColors.lightSurfaceBorder,
          ),
        ),
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final h = widget.height ?? 220.0;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    final resolvedGif = _resolveUrl(widget.mediaAnimationUrl);
    final resolvedThumb = _resolveUrl(widget.mediaThumbnailUrl);

    Widget playerMedia;

    if (_isShowingAnatomy && widget.anatomyAsset != null) {
      playerMedia = Image.asset(
        widget.anatomyAsset!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallbackIcon(size: 48),
      );
    } else if (widget.imageAsset != null && widget.imageAsset!.isNotEmpty) {
      playerMedia = Image.asset(
        widget.imageAsset!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallbackIcon(size: 48),
      );
    } else if (_isPlaying && _cachedAnimFile != null) {
      playerMedia = GestureDetector(
        onTap: () =>
            _openFullScreenViewer(context, resolvedGif, _cachedAnimFile),
        child: Image.file(
          _cachedAnimFile!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildFallbackIcon(size: 48),
        ),
      );
    } else if (_cachedThumbFile != null) {
      playerMedia = GestureDetector(
        onTap: () =>
            _openFullScreenViewer(context, resolvedThumb, _cachedThumbFile),
        child: Image.file(
          _cachedThumbFile!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildFallbackIcon(size: 48),
        ),
      );
    } else if (_isLoadingAnim || _isLoadingThumb) {
      playerMedia = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.limeGreen,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading exercise demonstration...',
              style: TextStyle(
                fontSize: 11,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    } else if (resolvedGif != null && !_animFailed && _isPlaying) {
      playerMedia = GestureDetector(
        onTap: () => _openFullScreenViewer(context, resolvedGif, null),
        child: Image.network(
          resolvedGif,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildFallbackIcon(size: 48),
        ),
      );
    } else if (resolvedThumb != null && !_thumbFailed) {
      playerMedia = GestureDetector(
        onTap: () => _openFullScreenViewer(context, resolvedThumb, null),
        child: Image.network(
          resolvedThumb,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildFallbackIcon(size: 48),
        ),
      );
    } else {
      playerMedia = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFallbackIcon(size: 44),
            const SizedBox(height: 6),
            Text(
              widget.category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            if (resolvedGif != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _loadMedia(),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: AppColors.limeGreen,
                ),
                label: const Text(
                  'Retry download',
                  style: TextStyle(color: AppColors.limeGreen, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: h,
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF101419)
            : const Color(0xFFF1F5F9),
        borderRadius: radius,
        border: Border.all(
          color: widget.isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            playerMedia,

            // Top Badges
            if (widget.showBadge)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.limeGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? AppColors.limeGreen
                              : AppColors.darkTextSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isShowingAnatomy
                            ? 'ANATOMY'
                            : (_isPlaying ? 'ANIMATED FORM' : 'PAUSED'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Right Controls (Play/Pause, Anatomy Toggle, Fullscreen)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.anatomyAsset != null)
                    IconButton(
                      iconSize: 20,
                      tooltip: _isShowingAnatomy
                          ? 'Show Motion'
                          : 'Show Anatomy',
                      icon: Icon(
                        _isShowingAnatomy
                            ? Icons.animation_rounded
                            : Icons.accessibility_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isShowingAnatomy = !_isShowingAnatomy;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.all(6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (resolvedGif != null && !_isShowingAnatomy) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      iconSize: 20,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                          if (_isPlaying && _cachedAnimFile == null) {
                            _loadAnimation(resolvedGif);
                          }
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.all(6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                  if (resolvedGif != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      iconSize: 20,
                      tooltip: 'Full Screen',
                      icon: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => _openFullScreenViewer(
                        context,
                        resolvedGif,
                        _cachedAnimFile,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.all(6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return _buildPlayer(context);
  }

  Widget _buildFallbackIcon({required double size}) {
    return Center(
      child: Icon(
        _getCategoryIcon(widget.category),
        size: size,
        color: widget.isDark ? AppColors.limeGreen : AppColors.limeGreenDark,
      ),
    );
  }
}
