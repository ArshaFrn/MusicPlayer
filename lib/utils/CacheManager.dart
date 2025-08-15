import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../Model/Music.dart';
import '../Model/User.dart';
import '../TcpClient.dart';

/// CacheManager is responsible for persistent on-disk caching of music files.
///
/// Design highlights:
/// - Per-user cache lives under: <app-documents>/<username>/cache/
/// - File naming: "<music.id>_<sanitizedTitle>.<extension>"
///   using a sanitized title to avoid filesystem-invalid characters
/// - Non-destructive policy: downloads do NOT clear earlier cache entries
/// - Manual cache clearing only via clearCache(user)
/// - Helpers exposed:
///   - ensureCached: idempotently returns path (downloads if needed)
///   - isMusicCached / getCachedMusicPath
///   - size and info helpers for UI
///
/// Caveat: If clearCache is invoked while a track is playing from disk,
/// the underlying file may be deleted by the time the player streams it,
/// which can interrupt playback. Coordinate with playback logic if needed.
class CacheManager {
  static final CacheManager _instance = CacheManager._privateConstructor();

  CacheManager._privateConstructor();

  static CacheManager get instance => _instance;

  // Cache directory structure: appdir/user/cache/
  Future<Directory> _getCacheDirectory(User user) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String userCachePath = '${appDocDir.path}/${user.username}/cache';
    final Directory userCacheDir = Directory(userCachePath);

    if (!await userCacheDir.exists()) {
      await userCacheDir.create(recursive: true);
    }

    return userCacheDir;
  }

  /// Returns the deterministic on-disk path for a given user's track.
  /// The title is sanitized to keep the filename filesystem-safe.
  Future<String> getCacheFilePath(User user, Music music) async {
    final Directory cacheDir = await _getCacheDirectory(user);

    // Clean the title to ensure it's safe for file naming
    final String cleanTitle = music.title.replaceAll(RegExp(r'[^\w\s-]'), '_');

    final String fileName = '${music.id}_$cleanTitle.${music.extension}';
    return '${cacheDir.path}/$fileName';
  }

  /// Checks existence and non-zero size to consider a track cached.
  Future<bool> isMusicCached(User user, Music music) async {
    try {
      final String cacheFilePath = await getCacheFilePath(user, music);
      final File cacheFile = File(cacheFilePath);

      if (await cacheFile.exists()) {
        final int fileSize = await cacheFile.length();
        return fileSize > 0;
      }
      return false;
    } catch (e) {
      print('Error checking cache: $e');
      return false;
    }
  }

  /// Deletes all cached tracks for a user.
  ///
  /// WARNING: If a track is currently playing from disk, deleting its file
  /// may interrupt playback. Consider guarding this call at the UI layer.
  Future<void> clearCache(User user) async {
    try {
      final Directory cacheDir = await _getCacheDirectory(user);

      print('=== CACHE CLEARING STARTED ===');
      print('User: ${user.username}');
      print('Cache directory: ${cacheDir.path}');

      if (await cacheDir.exists()) {
        final List<FileSystemEntity> files = await cacheDir.list().toList();
        print('Found ${files.length} files in cache directory');

        int deletedCount = 0;
        int totalSize = 0;

        for (final FileSystemEntity file in files) {
          if (file is File) {
            final String fileName = file.path.split('/').last;
            final int fileSize = await file.length();
            totalSize += fileSize;

            await file.delete();
            print('🗑️  Deleted: $fileName (${fileSize} bytes)');
            deletedCount++;
          }
        }

        print('=== CACHE CLEARING COMPLETED ===');
        print('Total files deleted: $deletedCount');
        print('Total size freed: ${formatCacheSize(totalSize)}');
        print('Cache cleared for user: ${user.username}');
        print('================================');
      } else {
        print('Cache directory does not exist for user: ${user.username}');
      }
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Idempotently ensures a track is cached and returns the cached file path.
  /// If the file is missing, it will be downloaded and persisted.
  Future<String?> ensureCached({
    required User user,
    required Music music,
  }) async {
    try {
      if (await isMusicCached(user, music)) {
        final path = await getCacheFilePath(user, music);
        music.filePath = path; // harmless bookkeeping
        return path;
      }

      // Download music from server
      final TcpClient tcpClient = TcpClient(
        serverAddress: '10.0.2.2',
        serverPort: 12345,
      );
      print('Downloading from server (ensureCached)...');
      final String? base64Data = await tcpClient.getMusicBase64(
        user: user,
        music: music,
      );

      if (base64Data == null) {
        print('Failed to get base64 data from server');
        return null;
      }

      // Decode and save to cache
      final bool success = await saveToCache(user, music, base64Data);
      if (!success) return null;

      final String newFilePath = await getCacheFilePath(user, music);
      music.filePath = newFilePath; // keep field in sync for diagnostics
      return newFilePath;
    } catch (e) {
      print('Error ensuring cached: $e');
      return null;
    }
  }

  /// Downloads and caches a track without removing older cache entries.
  /// Returns true on success.
  Future<bool> downloadAndCacheMusic({
    required User user,
    required Music music,
  }) async {
    try {
      print('Starting download and cache for: ${music.title}');

      // Do NOT clear cache here. We keep previously cached tracks.

      // Download music from server
      final TcpClient tcpClient = TcpClient(
        serverAddress: '10.0.2.2',
        serverPort: 12345,
      );
      print('Downloading from server...');
      final String? base64Data = await tcpClient.getMusicBase64(
        user: user,
        music: music,
      );

      if (base64Data == null) {
        print('Failed to get base64 data from server');
        return false;
      }

      print('Received base64 data, length: ${base64Data.length}');

      // Decode and save to cache
      final bool success = await saveToCache(user, music, base64Data);

      if (success) {
        print('Successfully cached: ${music.title}');
        // Update music file path to point to cache
        final String newFilePath = await getCacheFilePath(user, music);
        music.filePath = newFilePath;
        print('📁 Updated music file path: ${music.filePath}');
        print('✅ Cache operation completed successfully');
      }

      return success;
    } catch (e) {
      print('Error downloading and caching music: $e');
      return false;
    }
  }

  /// Alias of downloadAndCacheMusic to emphasize non-destructive sharing path.
  Future<bool> downloadAndCacheMusicForSharing({
    required User user,
    required Music music,
  }) async {
    try {
      // Implemented same as downloadAndCacheMusic for unified non-destructive behavior
      return await downloadAndCacheMusic(user: user, music: music);
    } catch (e) {
      print('Error downloading and caching music for sharing: $e');
      return false;
    }
  }

  /// Writes the base64 music data to the deterministic cache file path.
  /// Verifies a non-zero size write before returning success.
  Future<bool> saveToCache(User user, Music music, String base64Data) async {
    try {
      final String cacheFilePath = await getCacheFilePath(user, music);
      final File cacheFile = File(cacheFilePath);

      print('Saving to cache path: $cacheFilePath');

      // Decode base64 to bytes
      final List<int> bytes = base64Decode(base64Data);
      print('Decoded ${bytes.length} bytes from base64');

      // Write to cache file
      await cacheFile.writeAsBytes(bytes);

      // Verify file was written
      final int fileSize = await cacheFile.length();
      print('Saved to cache: $cacheFilePath (${fileSize} bytes)');

      if (fileSize > 0) {
        print('Cache file verified successfully');
        return true;
      } else {
        print('Cache file is empty, saving failed');
        return false;
      }
    } catch (e) {
      print('Error saving to cache: $e');
      return false;
    }
  }

  /// Private passthrough retained for backward compatibility.
  Future<bool> _saveToCache(User user, Music music, String base64Data) async {
    return saveToCache(user, music, base64Data);
  }

  /// Returns the cached path (if present) or null.
  Future<String?> getCachedMusicPath(User user, Music music) async {
    try {
      if (await isMusicCached(user, music)) {
        return await getCacheFilePath(user, music);
      }
      return null;
    } catch (e) {
      print('Error getting cached music path: $e');
      return null;
    }
  }

  /// Computes total cache size (bytes) for the given user.
  Future<int> getCacheSize(User user) async {
    try {
      final Directory cacheDir = await _getCacheDirectory(user);
      int totalSize = 0;

      if (await cacheDir.exists()) {
        await for (final FileSystemEntity entity in cacheDir.list(
          recursive: true,
        )) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  /// Pretty-prints a byte size for display.
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Returns cache statistics useful for UI/diagnostics.
  Future<Map<String, dynamic>> getCacheInfo(User user) async {
    try {
      final Directory cacheDir = await _getCacheDirectory(user);
      final int size = await getCacheSize(user);
      final List<FileSystemEntity> files = await cacheDir.list().toList();

      return {
        'size': size,
        'formattedSize': formatCacheSize(size),
        'fileCount': files.length,
        'cachePath': cacheDir.path,
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {
        'size': 0,
        'formattedSize': '0 B',
        'fileCount': 0,
        'cachePath': '',
      };
    }
  }
}
