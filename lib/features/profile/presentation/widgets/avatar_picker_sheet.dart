import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fit_host/core/theme/app_colors.dart';
import 'package:fit_host/core/services/image_compression_service.dart';

class AvatarOption {
  final String id;
  final String label;
  final String? assetPath;
  final String genderCategory; // 'male', 'female', 'neutral', 'dynamic'

  const AvatarOption({
    required this.id,
    required this.label,
    this.assetPath,
    required this.genderCategory,
  });
}

const List<AvatarOption> kAllAvatarOptions = [
  AvatarOption(
    id: 'avatar_male_1',
    label: 'Male Athlete 1',
    assetPath: 'assets/images/avatars/avatar_male_1.png',
    genderCategory: 'male',
  ),
  AvatarOption(
    id: 'avatar_male_2',
    label: 'Male Athlete 2',
    assetPath: 'assets/images/avatars/avatar_male_2.png',
    genderCategory: 'male',
  ),
  AvatarOption(
    id: 'avatar_female_1',
    label: 'Female Athlete 1',
    assetPath: 'assets/images/avatars/avatar_female_1.png',
    genderCategory: 'female',
  ),
  AvatarOption(
    id: 'avatar_female_2',
    label: 'Female Athlete 2',
    assetPath: 'assets/images/avatars/avatar_female_2.png',
    genderCategory: 'female',
  ),
  AvatarOption(
    id: 'avatar_neutral',
    label: 'Neutral Athlete',
    assetPath: 'assets/images/avatars/avatar_neutral.png',
    genderCategory: 'neutral',
  ),
  AvatarOption(
    id: 'initial',
    label: 'Initial Letter',
    assetPath: null,
    genderCategory: 'dynamic',
  ),
];

List<AvatarOption> getAvailableAvatarOptions(String? userGender) {
  final g = (userGender ?? '').trim().toLowerCase();
  if (g == 'male') {
    return kAllAvatarOptions
        .where((o) =>
            o.genderCategory == 'male' ||
            o.genderCategory == 'neutral' ||
            o.genderCategory == 'dynamic')
        .toList();
  } else if (g == 'female') {
    return kAllAvatarOptions
        .where((o) =>
            o.genderCategory == 'female' ||
            o.genderCategory == 'neutral' ||
            o.genderCategory == 'dynamic')
        .toList();
  }
  return kAllAvatarOptions;
}

String? getAvatarAssetPath(String? avatarId) {
  if (avatarId == null || avatarId.isEmpty || avatarId == 'initial') {
    return null;
  }
  final normalized =
      avatarId.startsWith('avatar_') ? avatarId : 'avatar_$avatarId';
  for (final opt in kAllAvatarOptions) {
    if (opt.id == normalized || opt.id == avatarId) {
      return opt.assetPath;
    }
  }
  return null;
}

class AppAvatar extends StatelessWidget {
  final String? avatarId;
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.avatarId,
    this.avatarUrl,
    required this.name,
    this.radius = 28,
    this.borderColor,
    this.borderWidth = 2,
    this.onTap,
  });

  Widget _buildAsset(String path) {
    return ClipOval(
      child: Image.asset(
        path,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialFallback(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = getAvatarAssetPath(avatarId);
    final borderCol = borderColor ?? AppColors.limeGreen;

    Widget content;
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      final cleanUrl = avatarUrl!.trim();
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        content = ClipOval(
          child: Image.network(
            cleanUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                assetPath != null ? _buildAsset(assetPath) : _buildInitialFallback(),
          ),
        );
      } else if (!kIsWeb && File(cleanUrl).existsSync()) {
        content = ClipOval(
          child: Image.file(
            File(cleanUrl),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                assetPath != null ? _buildAsset(assetPath) : _buildInitialFallback(),
          ),
        );
      } else {
        content = _buildAsset(cleanUrl);
      }
    } else if (!kIsWeb && avatarId != null && avatarId!.isNotEmpty && File(avatarId!).existsSync()) {
      content = ClipOval(
        child: Image.file(
          File(avatarId!),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              assetPath != null ? _buildAsset(assetPath) : _buildInitialFallback(),
        ),
      );
    } else if (assetPath != null) {
      content = _buildAsset(assetPath);
    } else {
      content = _buildInitialFallback();
    }

    final container = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderCol, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderCol.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }

  Widget _buildInitialFallback() {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A';
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF1B2F25), Color(0xFF0F1A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w900,
            color: AppColors.limeGreen,
          ),
        ),
      ),
    );
  }
}

class AvatarPickerSheet extends StatelessWidget {
  final String? currentAvatarId;
  final String userGender;
  final String userName;
  final ValueChanged<String> onSelected;

  const AvatarPickerSheet({
    super.key,
    required this.currentAvatarId,
    required this.userGender,
    required this.userName,
    required this.onSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String? currentAvatarId,
    required String userGender,
    required String userName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AvatarPickerSheet(
        currentAvatarId: currentAvatarId,
        userGender: userGender,
        userName: userName,
        onSelected: (id) => Navigator.of(ctx).pop(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = getAvailableAvatarOptions(userGender);
    final selectedId = currentAvatarId ?? 'initial';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Your Avatar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.limeGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${userGender.toUpperCase()} FILTER',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.limeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select a profile persona or your dynamic monogram initials.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Options Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = selectedId == opt.id ||
                  (selectedId.replaceFirst('avatar_', '') == opt.id.replaceFirst('avatar_', ''));

              return GestureDetector(
                onTap: () => onSelected(opt.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isSelected
                            ? AppColors.limeGreen.withValues(alpha: 0.12)
                            : AppColors.darkSurface)
                        : (isSelected
                            ? AppColors.limeGreen.withValues(alpha: 0.15)
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.limeGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AppAvatar(
                            avatarId: opt.id,
                            name: userName,
                            radius: 28,
                            borderColor: isSelected ? AppColors.limeGreen : Colors.grey.shade600,
                          ),
                          if (isSelected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.limeGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opt.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.limeGreen
                              : (isDark ? Colors.white70 : Colors.black87),
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
}

Future<String?> showPhotoOrAvatarPicker(
  BuildContext context, {
  required String? currentAvatarId,
  required String userGender,
  required String userName,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Profile Photo & Avatar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Capture with camera, upload from gallery, or choose an avatar',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Option 1: Camera
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.limeGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.limeGreen, size: 22),
            ),
            title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Capture your athletic progress photo', style: TextStyle(fontSize: 12)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => Navigator.of(ctx).pop('camera'),
          ),
          const SizedBox(height: 6),

          // Option 2: Gallery
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.electricCyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_rounded, color: AppColors.electricCyan, size: 22),
            ),
            title: const Text('Upload from Photo Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Select a portrait from your device', style: TextStyle(fontSize: 12)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => Navigator.of(ctx).pop('gallery'),
          ),
          const SizedBox(height: 6),

          // Option 3: Stylized Avatar
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.purpleAccent, size: 22),
            ),
            title: const Text('Choose Stylized Avatar', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Select one of our illustrated athlete characters', style: TextStyle(fontSize: 12)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => Navigator.of(ctx).pop('avatar'),
          ),
        ],
      ),
    ),
  );

  if (action == 'camera') {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile != null) {
        final compressed = await ImageCompressionService.compressImage(File(xFile.path));
        return compressed.path;
      }
    } catch (e) {
      debugPrint('[AvatarPicker] Camera capture error: $e');
    }
  } else if (action == 'gallery') {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile != null) {
        final compressed = await ImageCompressionService.compressImage(File(xFile.path));
        return compressed.path;
      }
    } catch (e) {
      debugPrint('[AvatarPicker] Gallery pick error: $e');
    }
  } else if (action == 'avatar') {
    if (context.mounted) {
      return await AvatarPickerSheet.show(
        context,
        currentAvatarId: currentAvatarId,
        userGender: userGender,
        userName: userName,
      );
    }
  }

  return null;
}

