import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../Model/Music.dart';
import '../Model/User.dart';
import '../TcpClient.dart';

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

  /// Get the cache file path for a specific music track
  Future<String> getCacheFilePath(User user, Music music) async {
    final Directory cacheDir = await _getCacheDirectory(user);

    // Clean the title to ensure it's safe for file naming
    final String cleanTitle = music.title.replaceAll(RegExp(r'[^\w\s-]'), '_');

    final String fileName = '${music.id}_$cleanTitle.${music.extension}';
    return '${cacheDir.path}/$fileName';
  }

  /// Check if a music track is cached
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

  /// Clear all cached music files for a user
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

  /// Download and cache a music track
  Future<bool> downloadAndCacheMusic({
    required User user,
    required Music music,
  }) async {
    try {
      print('Starting download and cache for: ${music.title}');

      // Clear existing cache before downloading new track
      print('🔄 Clearing previous cache before downloading new track...');
      await clearCache(user);
      print('✅ Previous cache cleared successfully');

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

  /// Save base64 data to cache file
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

  /// Save base64 data to cache file (private version)
  Future<bool> _saveToCache(User user, Music music, String base64Data) async {
    return saveToCache(user, music, base64Data);
  }

  /// Get cached music file path
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

  /// Get cache size for a user
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

  /// Format cache size for display
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get cache info for a user
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
