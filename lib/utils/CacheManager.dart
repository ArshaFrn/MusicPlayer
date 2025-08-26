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

  Future<Directory> _getCacheDirectory(User user) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String userCachePath = '${appDocDir.path}/${user.username}/cache';
    final Directory userCacheDir = Directory(userCachePath);

    if (!await userCacheDir.exists()) {
      await userCacheDir.create(recursive: true);
    }

    return userCacheDir;
  }

  Future<String> getCacheFilePath(User user, Music music) async {
    final Directory cacheDir = await _getCacheDirectory(user);

    // Clean the title
    final String cleanTitle = music.title.replaceAll(RegExp(r'[^\w\s-]'), '_');

    final String fileName = '${music.id}_$cleanTitle.${music.extension}';
    return '${cacheDir.path}/$fileName';
  }

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

  Future<void> clearCache(User user) async {
    try {
      final Directory cacheDir = await _getCacheDirectory(user);

      if (await cacheDir.exists()) {
        final List<FileSystemEntity> files = await cacheDir.list().toList();

        int deletedCount = 0;
        int totalSize = 0;

        for (final FileSystemEntity file in files) {
          if (file is File) {
            final String fileName = file.path.split('/').last;
            final int fileSize = await file.length();
            totalSize += fileSize;

            await file.delete();
            deletedCount++;
          }
        }

        print('Total files deleted: $deletedCount');
      } else {
        print('Cache directory does not exist for user: ${user.username}');
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// If the file is missing, it will be downloaded.
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

      // Download music
      final TcpClient tcpClient = TcpClient(
        serverAddress: '192.168.43.173',
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

      final bool success = await saveToCache(user, music, base64Data);
      if (!success) return null;

      final String newFilePath = await getCacheFilePath(user, music);
      music.filePath = newFilePath;
      return newFilePath;
    } catch (e) {
      print('Error ensuring cached: $e');
      return null;
    }
  }

  Future<bool> downloadAndCacheMusic({
    required User user,
    required Music music,
  }) async {
    try {
      print('Starting download and cache for: ${music.title}');

      final TcpClient tcpClient = TcpClient(
        serverAddress: '192.168.43.173',
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

      final bool success = await saveToCache(user, music, base64Data);

      if (success) {
        print('Successfully cached: ${music.title}');
        final String newFilePath = await getCacheFilePath(user, music);
        music.filePath = newFilePath;
      }

      return success;
    } catch (e) {
      print('Error downloading and caching music: $e');
      return false;
    }
  }

  Future<bool> downloadAndCacheMusicForSharing({
    required User user,
    required Music music,
  }) async {
    try {
      return await downloadAndCacheMusic(user: user, music: music);
    } catch (e) {
      print('Error downloading and caching music for sharing: $e');
      return false;
    }
  }


  Future<bool> saveToCache(User user, Music music, String base64Data) async {
    try {
      final String cacheFilePath = await getCacheFilePath(user, music);
      final File cacheFile = File(cacheFilePath);

      print('Saving to cache path: $cacheFilePath');

      final List<int> bytes = base64Decode(base64Data);
      print('Decoded ${bytes.length} bytes from base64');

      await cacheFile.writeAsBytes(bytes);

      final int fileSize = await cacheFile.length();

      if (fileSize > 0) {
        print('Cache file verified successfully');
        return true;
      } else {
        print('Cache file is empty, saving failed!');
        return false;
      }
    } catch (e) {
      print('Error saving to cache: $e');
      return false;
    }
  }

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

  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
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
