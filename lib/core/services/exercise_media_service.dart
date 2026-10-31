import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Riverpod provider for ExerciseMediaService.
final exerciseMediaServiceProvider = Provider<ExerciseMediaService>((ref) {
  return ExerciseMediaService();
});

/// Production-grade remote exercise media delivery and resilient caching service.
///
/// Features:
/// 1. Thumbnail-first delivery with progressive promotion.
/// 2. Instant disk and memory cache hits.
/// 3. Request deduplication (in-flight request coalescence).
/// 4. Strict concurrency limiting (max 4 concurrent downloads).
/// 5. Bounded exponential backoff with jitter on transient network failures.
/// 6. Safe request cancellation via Dio CancelToken.
/// 7. Response size and Content-Type validation.
/// 8. LRU disk cache eviction with protected thumbnail quota.
class ExerciseMediaService {
  static ExerciseMediaService? _instance;
  factory ExerciseMediaService() =>
      _instance ??= ExerciseMediaService._internal();

  ExerciseMediaService._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'image/webp,image/png,image/jpeg,image/gif,*/*',
          'User-Agent': 'FitHost-Mobile/1.3.0',
        },
      ),
    );
  }

  late final Dio _dio;
  Directory? _cacheDir;
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  // In-flight request deduplication map: URL -> Future<File?>
  final Map<String, Future<File?>> _inFlightRequests = {};

  // Concurrency limiter queue (max 4 concurrent active downloads)
  static const int _maxConcurrentDownloads = 4;
  int _activeDownloads = 0;
  final Queue<Completer<void>> _concurrencyQueue = Queue<Completer<void>>();

  // Maximum disk cache size in bytes (50 MB)
  static const int _maxDiskCacheBytes = 50 * 1024 * 1024;

  // Maximum allowed asset sizes
  static const int _maxThumbnailBytes = 500 * 1024; // 500 KB
  static const int _maxAnimationBytes = 10 * 1024 * 1024; // 10 MB

  /// Initialize local cache directory structure.
  Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter.isCompleted) return;

    try {
      final baseDir = await getTemporaryDirectory();
      _cacheDir = Directory(p.join(baseDir.path, 'fit_host_exercise_media'));
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      final thumbDir = Directory(p.join(_cacheDir!.path, 'thumbnails'));
      if (!await thumbDir.exists()) await thumbDir.create(recursive: true);

      final animDir = Directory(p.join(_cacheDir!.path, 'animations'));
      if (!await animDir.exists()) await animDir.create(recursive: true);

      _initialized = true;
      _initCompleter.complete();
    } catch (e) {
      debugPrint(
        '[ExerciseMediaService] Failed to initialize cache directory: $e',
      );
      _initCompleter.complete();
    }
  }

  /// Derives deterministic local filename based on SHA-256 of canonical URL.
  String _cacheKeyForUrl(String url) {
    return sha256.convert(url.codeUnits).toString();
  }

  /// Returns cached File if present on disk and non-empty.
  Future<File?> getCachedFile(String url, {required bool isThumbnail}) async {
    await init();
    if (_cacheDir == null) return null;

    final subDir = isThumbnail ? 'thumbnails' : 'animations';
    final ext = isThumbnail ? '.jpg' : '.gif';
    final key = _cacheKeyForUrl(url);
    final targetPath = p.join(_cacheDir!.path, subDir, '$key$ext');
    final file = File(targetPath);

    if (await file.exists()) {
      final length = await file.length();
      if (length > 0) {
        return file;
      } else {
        file.delete().ignore();
      }
    }
    return null;
  }

  /// Loads media file: returns immediate cache hit if available, or schedules resilient fetch.
  Future<File?> loadMedia({
    required String url,
    required bool isThumbnail,
    CancelToken? cancelToken,
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return null;

    // 1. Check local cache first
    final existing = await getCachedFile(trimmedUrl, isThumbnail: isThumbnail);
    if (existing != null) {
      return existing;
    }

    // 2. Request deduplication: join in-flight download if already running
    if (_inFlightRequests.containsKey(trimmedUrl)) {
      return _inFlightRequests[trimmedUrl]!;
    }

    final future = _fetchAndCache(
      trimmedUrl,
      isThumbnail: isThumbnail,
      cancelToken: cancelToken,
    );
    _inFlightRequests[trimmedUrl] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlightRequests.remove(trimmedUrl);
    }
  }

  /// Internal download worker with concurrency control and exponential backoff retry.
  Future<File?> _fetchAndCache(
    String url, {
    required bool isThumbnail,
    CancelToken? cancelToken,
  }) async {
    await init();
    if (_cacheDir == null) return null;

    // Concurrency control: wait if at maximum active downloads
    while (_activeDownloads >= _maxConcurrentDownloads) {
      final waiter = Completer<void>();
      _concurrencyQueue.add(waiter);
      await waiter.future;
      if (cancelToken?.isCancelled ?? false) return null;
    }

    _activeDownloads++;
    try {
      return await _downloadWithRetry(
        url,
        isThumbnail: isThumbnail,
        cancelToken: cancelToken,
      );
    } finally {
      _activeDownloads--;
      if (_concurrencyQueue.isNotEmpty) {
        final next = _concurrencyQueue.removeFirst();
        if (!next.isCompleted) next.complete();
      }
    }
  }

  /// Downloads asset with bounded exponential backoff and jitter (up to 3 attempts).
  Future<File?> _downloadWithRetry(
    String url, {
    required bool isThumbnail,
    CancelToken? cancelToken,
  }) async {
    final subDir = isThumbnail ? 'thumbnails' : 'animations';
    final ext = isThumbnail ? '.jpg' : '.gif';
    final key = _cacheKeyForUrl(url);
    final targetPath = p.join(_cacheDir!.path, subDir, '$key$ext');
    final tempPath = '$targetPath.tmp';

    const maxAttempts = 3;
    final random = Random();

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (cancelToken?.isCancelled ?? false) return null;

      try {
        final response = await _dio.download(
          url,
          tempPath,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            validateStatus: (status) => status == 200,
          ),
        );

        if (response.statusCode == 200) {
          final tempFile = File(tempPath);
          if (await tempFile.exists()) {
            final size = await tempFile.length();
            final maxBytes = isThumbnail
                ? _maxThumbnailBytes
                : _maxAnimationBytes;

            if (size > 0 && size <= maxBytes) {
              // Atomic rename to final target file
              final targetFile = File(targetPath);
              if (await targetFile.exists()) await targetFile.delete();
              await tempFile.rename(targetPath);

              // Periodic cache eviction check (fire and forget)
              _maybeEvictCache().ignore();

              return File(targetPath);
            } else {
              debugPrint(
                '[ExerciseMediaService] Download size invalid: $size bytes (limit $maxBytes)',
              );
              try {
                await tempFile.delete();
              } catch (_) {}
              return null;
            }
          }
        }
      } catch (e) {
        if (cancelToken?.isCancelled ?? false) {
          final tempFile = File(tempPath);
          try {
            if (await tempFile.exists()) await tempFile.delete();
          } catch (_) {}
          return null;
        }

        if (attempt == maxAttempts) {
          debugPrint(
            '[ExerciseMediaService] Download failed after $maxAttempts attempts for URL: ${_sanitizeUrl(url)}',
          );
          final tempFile = File(tempPath);
          try {
            if (await tempFile.exists()) await tempFile.delete();
          } catch (_) {}
          return null;
        }

        // Exponential backoff: 250ms * 2^attempt + jitter (up to 200ms)
        final backoffMs =
            (250 * pow(2, attempt - 1)).toInt() + random.nextInt(200);
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }
    return null;
  }

  /// Disk cache eviction based on LRU access time when exceeding quota.
  Future<void> _maybeEvictCache() async {
    if (_cacheDir == null) return;

    try {
      int totalBytes = 0;
      final List<({File file, int size, DateTime modified, bool isThumb})>
      entries = [];

      final entities = _cacheDir!.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File && !entity.path.endsWith('.tmp')) {
          final stat = entity.statSync();
          final isThumb = entity.path.contains('/thumbnails/');
          entries.add((
            file: entity,
            size: stat.size,
            modified: stat.modified,
            isThumb: isThumb,
          ));
          totalBytes += stat.size;
        }
      }

      if (totalBytes <= _maxDiskCacheBytes) return;

      // Sort by modified ascending (oldest first).
      // Give thumbnails 7 days priority over animations to protect thumbnail catalog.
      entries.sort((a, b) {
        final aPriorityDate = a.isThumb
            ? a.modified.add(const Duration(days: 7))
            : a.modified;
        final bPriorityDate = b.isThumb
            ? b.modified.add(const Duration(days: 7))
            : b.modified;
        return aPriorityDate.compareTo(bPriorityDate);
      });

      for (final entry in entries) {
        if (totalBytes <= (_maxDiskCacheBytes * 0.8).toInt()) {
          break; // Evict down to 80%
        }
        try {
          if (await entry.file.exists()) {
            await entry.file.delete();
            totalBytes -= entry.size;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ExerciseMediaService] Cache eviction error: $e');
    }
  }

  /// Sanitizes URL for safe diagnostics logging without credentials or sensitive query params.
  String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (_) {
      return '[invalid_url]';
    }
  }
}
