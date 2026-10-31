import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'image_compression_service.dart';
import 'supabase_storage_service.dart';

/// Manages profile avatar image processing, compression, persistent device storage,
/// and selective Supabase database/storage synchronization.
class ProfileAvatarService {
  static const String _avatarFolderName = 'profile_avatars';
  static const int avatarDimension = 512;
  static const int avatarQuality = 85;

  /// Checks if the avatar identifier represents a bundled asset, preset, or monogram.
  static bool isAssetAvatar(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) return true;
    final trimmed = avatarId.trim();
    if (trimmed == 'initial' || trimmed == 'default') return true;
    if (trimmed.startsWith('assets/')) return true;
    if (trimmed.startsWith('avatar_male_') ||
        trimmed.startsWith('avatar_female_') ||
        trimmed == 'avatar_neutral' ||
        trimmed == 'male_1' ||
        trimmed == 'male_2' ||
        trimmed == 'female_1' ||
        trimmed == 'female_2' ||
        trimmed == 'neutral') {
      return true;
    }
    return false;
  }

  /// Checks if the avatar identifier represents the default, unconfigured profile image.
  static bool isDefaultProfileImage(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) return true;
    final trimmed = avatarId.trim().toLowerCase();
    return trimmed == 'initial' || trimmed == 'default';
  }

  /// Checks if the avatar is a custom image stored on the local device.
  static bool isCustomDeviceAvatar(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) return false;
    final trimmed = avatarId.trim();
    if (isAssetAvatar(trimmed)) return false;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return false;
    }
    return true;
  }

  /// Returns the persistent directory used to store the user's own profile avatar.
  static Future<Directory> getDeviceAvatarDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _avatarFolderName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Resizes, compresses, and stores the user's custom photo in persistent device storage.
  /// Enforces avatar dimensions (512x512) and cleans up any previous avatar files.
  static Future<File> processAndStoreDeviceAvatar(File sourceFile) async {
    try {
      // 1. Compress and resize to 512x512 WebP (or JPEG fallback)
      final compressed = await ImageCompressionService.compressImage(
        sourceFile,
        maxWidth: avatarDimension,
        maxHeight: avatarDimension,
        quality: avatarQuality,
        format: CompressFormat.webp,
      );

      // 2. Target permanent storage directory
      final targetDir = await getDeviceAvatarDirectory();

      // Clean up previous avatar files so device storage only holds the active photo
      try {
        final existingFiles = targetDir.listSync();
        for (final entity in existingFiles) {
          if (entity is File) {
            entity.deleteSync();
          }
        }
      } catch (_) {}

      final ext = p.extension(compressed.path).isNotEmpty
          ? p.extension(compressed.path)
          : '.webp';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
      final persistentFile = File(p.join(targetDir.path, fileName));

      final saved = await compressed.copy(persistentFile.path);
      debugPrint(
        '[ProfileAvatarService] Stored custom avatar in device store: ${saved.path} (${await saved.length()} bytes)',
      );

      // Clean up temporary compressed file if different from target
      if (compressed.path != saved.path && compressed.existsSync()) {
        try {
          compressed.deleteSync();
        } catch (_) {}
      }

      return saved;
    } catch (e) {
      debugPrint(
        '[ProfileAvatarService] Error processing device avatar: $e. Using source.',
      );
      return sourceFile;
    }
  }

  /// Clears any custom avatar from persistent device store.
  /// Called when the user chooses a bundled asset avatar or default monogram,
  /// ensuring files are stored ONLY when the user keeps their own profile image.
  static Future<void> clearDeviceAvatarStore() async {
    try {
      final targetDir = await getDeviceAvatarDirectory();
      if (targetDir.existsSync()) {
        final existingFiles = targetDir.listSync();
        for (final entity in existingFiles) {
          if (entity is File) {
            entity.deleteSync();
          }
        }
      }
      debugPrint(
        '[ProfileAvatarService] Cleared device store as user selected asset/default avatar.',
      );
    } catch (e) {
      debugPrint(
        '[ProfileAvatarService] Notice clearing device avatar store: $e',
      );
    }
  }

  /// Uploads the local custom avatar file to Supabase Storage ('avatars' bucket)
  /// and returns the public remote URL.
  /// If [localOrRemotePath] is already a remote URL or an asset avatar, returns it directly.
  static Future<String?> syncAvatarToRemoteStorage({
    required String userId,
    required String? localOrRemotePath,
    SupabaseClient? client,
  }) async {
    if (localOrRemotePath == null || localOrRemotePath.isEmpty) {
      return null;
    }

    final trimmed = localOrRemotePath.trim();

    // 1. If it's a bundled asset image or default monogram, DO NOT upload to cloud storage
    if (isAssetAvatar(trimmed)) {
      debugPrint(
        '[ProfileAvatarService] Asset/default avatar ($trimmed): skipping cloud storage upload.',
      );
      return trimmed;
    }

    // 2. If it's already a remote cloud URL, return directly
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // 3. If guest user, retain local device path without remote upload
    if (userId.isEmpty || userId == 'guest') {
      return trimmed;
    }

    final supabaseClient = client ?? _safeGetSupabaseClient();
    if (supabaseClient == null) {
      return trimmed;
    }

    // 4. Upload local file to Supabase Storage avatars bucket
    final localFile = File(trimmed);
    if (!localFile.existsSync()) {
      debugPrint(
        '[ProfileAvatarService] Local avatar file does not exist at $trimmed',
      );
      return trimmed;
    }

    try {
      final storagePath = '$userId/avatar_$userId.webp';

      await supabaseClient.storage
          .from(StorageBuckets.avatars)
          .upload(
            storagePath,
            localFile,
            fileOptions: const FileOptions(
              contentType: 'image/webp',
              upsert: true,
            ),
          );

      final publicUrl = supabaseClient.storage
          .from(StorageBuckets.avatars)
          .getPublicUrl(storagePath);

      debugPrint(
        '[ProfileAvatarService] Successfully uploaded avatar to $publicUrl',
      );
      return publicUrl;
    } catch (e) {
      debugPrint('[ProfileAvatarService] Cloud storage upload notice: $e');
      return trimmed;
    }
  }

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
