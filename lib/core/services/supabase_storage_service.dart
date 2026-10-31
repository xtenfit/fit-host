import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'image_compression_service.dart';

/// Standard storage bucket identifiers in Fit Host.
abstract final class StorageBuckets {
  static const String avatars = 'avatars';
  static const String progressPhotos = 'progress-photos';
  static const String diaryAttachments = 'diary-attachments';
  static const String workoutAttachments = 'workout-attachments';
}

/// Represents a managed media file stored in Supabase and cached locally.
class ManagedMediaFile {
  final String bucket;
  final String storagePath;
  final String? localFilePath;
  final String? publicOrSignedUrl;
  final int fileSizeBytes;
  final DateTime updatedAt;

  const ManagedMediaFile({
    required this.bucket,
    required this.storagePath,
    this.localFilePath,
    this.publicOrSignedUrl,
    required this.fileSizeBytes,
    required this.updatedAt,
  });
}

/// Full-stack mobile and cloud file handling service for Supabase Storage.
/// Provides compression, authenticated user isolation, local disk caching,
/// signed URL resolution, and clean deletion.
class SupabaseFileStorageService {
  final SupabaseClient? _supabase;
  final Map<String, ({String url, DateTime expiresAt})> _signedUrlCache = {};
  static const Duration _signedUrlTtl = Duration(hours: 1);

  SupabaseFileStorageService([SupabaseClient? client])
    : _supabase = client ?? _safeGetSupabaseClient();

  static SupabaseClient? _safeGetSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Returns canonical user-isolated storage path: `{userId}/{fileName}`.
  String generateStoragePath({
    required String userId,
    required String fileName,
    String? bucket,
  }) {
    return '$userId/$fileName';
  }

  /// Returns the persistent local cache directory for storage files.
  Future<Directory> _getCacheDirectory(String bucket, String userId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'storage_cache', bucket, userId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Uploads a progress photo with compression, local caching, and remote storage.
  /// Returns the remote storage path (e.g., `{userId}/photo_{uuid}.webp`).
  Future<ManagedMediaFile?> uploadProgressPhoto({
    required File sourceFile,
    required String userId,
    String? customId,
    String poseType = 'front',
  }) async {
    final fileId = customId ?? const Uuid().v4();
    final fileName = '${poseType}_$fileId.webp';
    final storagePath = '$userId/$fileName';

    return uploadImage(
      sourceFile: sourceFile,
      bucket: StorageBuckets.progressPhotos,
      userId: userId,
      storagePath: storagePath,
      maxWidth: 1280,
      maxHeight: 1280,
      quality: 85,
    );
  }

  /// Uploads a user avatar with compression and updates local cache.
  /// Returns the remote storage path or public URL.
  Future<ManagedMediaFile?> uploadAvatar({
    required File sourceFile,
    required String userId,
  }) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.webp';
    final storagePath = '$userId/$fileName';

    return uploadImage(
      sourceFile: sourceFile,
      bucket: StorageBuckets.avatars,
      userId: userId,
      storagePath: storagePath,
      maxWidth: 512,
      maxHeight: 512,
      quality: 90,
    );
  }

  /// Generic image uploader with compression, user path isolation, and local caching.
  Future<ManagedMediaFile?> uploadImage({
    required File sourceFile,
    required String bucket,
    required String userId,
    required String storagePath,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // 1. Compress image to WebP
      final compressed = await ImageCompressionService.compressImage(
        sourceFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

      // 2. Cache compressed file locally
      final cacheDir = await _getCacheDirectory(bucket, userId);
      final localTarget = File(p.join(cacheDir.path, p.basename(storagePath)));
      await compressed.copy(localTarget.path);

      final fileSize = await localTarget.length();

      // 3. Upload to Supabase Storage if authenticated and online
      String? remoteUrl;
      if (_supabase != null && userId != 'guest') {
        try {
          await _supabase.storage
              .from(bucket)
              .upload(
                storagePath,
                localTarget,
                fileOptions: const FileOptions(
                  contentType: 'image/webp',
                  upsert: true,
                ),
              );

          // Get URL
          remoteUrl = await getFileUrl(
            bucket: bucket,
            storagePath: storagePath,
          );
          debugPrint(
            '[FileStorage] Successfully uploaded $storagePath to $bucket ($fileSize bytes)',
          );
        } catch (e) {
          debugPrint('[FileStorage] Remote upload error (cached locally): $e');
        }
      }

      return ManagedMediaFile(
        bucket: bucket,
        storagePath: storagePath,
        localFilePath: localTarget.path,
        publicOrSignedUrl: remoteUrl,
        fileSizeBytes: fileSize,
        updatedAt: DateTime.now().toUtc(),
      );
    } catch (e) {
      debugPrint('[FileStorage] Failed to upload image: $e');
      return null;
    }
  }

  /// Uploads binary audio bytes (e.g. voice memo for diary) to Supabase Storage.
  Future<ManagedMediaFile?> uploadVoiceMemo({
    required Uint8List audioBytes,
    required String userId,
    required String entryId,
    String extension = 'm4a',
  }) async {
    try {
      final fileName =
          'memo_${entryId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = '$userId/$fileName';

      // Cache locally
      final cacheDir = await _getCacheDirectory(
        StorageBuckets.diaryAttachments,
        userId,
      );
      final localFile = File(p.join(cacheDir.path, fileName));
      await localFile.writeAsBytes(audioBytes);

      String? remoteUrl;
      if (_supabase != null && userId != 'guest') {
        try {
          await _supabase.storage
              .from(StorageBuckets.diaryAttachments)
              .uploadBinary(
                storagePath,
                audioBytes,
                fileOptions: FileOptions(
                  contentType: extension == 'm4a' ? 'audio/mp4' : 'audio/mpeg',
                  upsert: true,
                ),
              );
          remoteUrl = await getFileUrl(
            bucket: StorageBuckets.diaryAttachments,
            storagePath: storagePath,
          );
        } catch (e) {
          debugPrint('[FileStorage] Remote voice memo upload notice: $e');
        }
      }

      return ManagedMediaFile(
        bucket: StorageBuckets.diaryAttachments,
        storagePath: storagePath,
        localFilePath: localFile.path,
        publicOrSignedUrl: remoteUrl,
        fileSizeBytes: audioBytes.length,
        updatedAt: DateTime.now().toUtc(),
      );
    } catch (e) {
      debugPrint('[FileStorage] Failed to upload voice memo: $e');
      return null;
    }
  }

  /// Resolves an accessible URL for a stored file.
  /// For public buckets (e.g. avatars), returns public URL.
  /// For private buckets (e.g. progress-photos), generates and caches a signed URL.
  Future<String?> getFileUrl({
    required String bucket,
    required String storagePath,
    Duration expiresIn = _signedUrlTtl,
  }) async {
    if (_supabase == null) return null;

    final cacheKey = '$bucket:$storagePath';
    final cached = _signedUrlCache[cacheKey];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.url;
    }

    try {
      if (bucket == StorageBuckets.avatars) {
        final url = _supabase.storage.from(bucket).getPublicUrl(storagePath);
        _signedUrlCache[cacheKey] = (
          url: url,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );
        return url;
      }

      // Private buckets require signed URLs
      final signedUrl = await _supabase.storage
          .from(bucket)
          .createSignedUrl(storagePath, expiresIn.inSeconds);

      _signedUrlCache[cacheKey] = (
        url: signedUrl,
        expiresAt: DateTime.now().add(expiresIn - const Duration(minutes: 5)),
      );
      return signedUrl;
    } catch (e) {
      debugPrint(
        '[FileStorage] Error resolving URL for $bucket/$storagePath: $e',
      );
      return null;
    }
  }

  /// Downloads a remote file to local disk cache if not already present.
  /// Returns the local [File].
  Future<File?> getOrDownloadFile({
    required String bucket,
    required String storagePath,
    required String userId,
  }) async {
    final cacheDir = await _getCacheDirectory(bucket, userId);
    final localFile = File(p.join(cacheDir.path, p.basename(storagePath)));

    if (localFile.existsSync() && localFile.lengthSync() > 0) {
      return localFile;
    }

    if (_supabase == null || userId == 'guest') {
      return null;
    }

    try {
      final bytes = await _supabase.storage.from(bucket).download(storagePath);
      await localFile.writeAsBytes(bytes);
      debugPrint(
        '[FileStorage] Downloaded and cached $storagePath locally (${bytes.length} bytes)',
      );
      return localFile;
    } catch (e) {
      debugPrint(
        '[FileStorage] Error downloading $storagePath from $bucket: $e',
      );
      return null;
    }
  }

  /// Deletes a file from local disk cache and remote Supabase Storage.
  Future<void> deleteFile({
    required String bucket,
    required String storagePath,
    required String userId,
  }) async {
    _signedUrlCache.remove('$bucket:$storagePath');

    // 1. Delete local cached copy
    try {
      final cacheDir = await _getCacheDirectory(bucket, userId);
      final localFile = File(p.join(cacheDir.path, p.basename(storagePath)));
      if (localFile.existsSync()) {
        localFile.deleteSync();
      }
    } catch (e) {
      debugPrint('[FileStorage] Local delete notice: $e');
    }

    // 2. Delete from Supabase Storage
    if (_supabase != null && userId != 'guest') {
      try {
        await _supabase.storage.from(bucket).remove([storagePath]);
        debugPrint(
          '[FileStorage] Deleted remote file $storagePath from $bucket',
        );
      } catch (e) {
        debugPrint('[FileStorage] Remote delete notice: $e');
      }
    }
  }
}

final supabaseFileStorageServiceProvider = Provider<SupabaseFileStorageService>(
  (ref) {
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {}
    return SupabaseFileStorageService(client);
  },
);
