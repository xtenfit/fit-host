import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for client-side lossless / near-lossless image compression before
/// uploads to Supabase Storage or AI analysis endpoints.
class ImageCompressionService {
  const ImageCompressionService();

  /// Compresses an image file to WebP format (or JPEG if WebP is unavailable),
  /// constraining resolution to [maxWidth]x[maxHeight] with quality [quality].
  ///
  /// Target: < 200 KB per photo without visible quality loss.
  static Future<File> compressImage(
    File sourceFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
    CompressFormat format = CompressFormat.webp,
  }) async {
    try {
      final originalSize = await sourceFile.length();
      final tempDir = await getTemporaryDirectory();
      final ext = format == CompressFormat.webp ? '.webp' : '.jpg';
      final targetPath = p.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(sourceFile.path)}$ext',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        targetPath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: format,
        keepExif: false,
      );

      if (result == null) {
        debugPrint('[ImageCompression] Warning: Compression returned null, using original file.');
        return sourceFile;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      // If compression somehow produced a larger file, keep the original
      if (compressedSize >= originalSize) {
        debugPrint(
          '[ImageCompression] Compressed size ($compressedSize bytes) >= original ($originalSize bytes). Keeping original.',
        );
        return sourceFile;
      }

      final savedPercent = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
      debugPrint(
        '[ImageCompression] Successfully compressed image: ${(originalSize / 1024).toStringAsFixed(0)}KB -> ${(compressedSize / 1024).toStringAsFixed(0)}KB ($savedPercent% smaller)',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('[ImageCompression] Error during compression: $e. Falling back to original.');
      return sourceFile;
    }
  }

  /// Compresses raw image bytes in memory.
  static Future<Uint8List> compressBytes(
    Uint8List sourceBytes, {
    int minWidth = 1024,
    int minHeight = 1024,
    int quality = 85,
    CompressFormat format = CompressFormat.webp,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        sourceBytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: format,
      );

      if (result.length >= sourceBytes.length) {
        return sourceBytes;
      }

      return result;
    } catch (e) {
      debugPrint('[ImageCompression] Error compressing bytes: $e');
      return sourceBytes;
    }
  }

  /// Compresses and uploads an image to a Supabase Storage bucket.
  /// Returns the public URL of the uploaded image if successful.
  static Future<String?> compressAndUploadToSupabase({
    required File file,
    required String bucketName,
    required String pathInBucket,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    final compressed = await compressImage(
      file,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
      format: CompressFormat.webp,
    );

    try {
      final client = Supabase.instance.client;
      await client.storage.from(bucketName).upload(
            pathInBucket,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/webp',
              upsert: true,
            ),
          );
      return client.storage.from(bucketName).getPublicUrl(pathInBucket);
    } catch (e) {
      debugPrint('[ImageCompression] Supabase storage upload skipped or failed: $e');
      return null;
    }
  }
}
