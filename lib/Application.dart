import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Model/Artist.dart';
import 'Model/Album.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'TcpClient.dart';
import 'utils/CacheManager.dart';
import 'utils/AudioController.dart';
import 'PlayPage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'package:flutter/services.dart';
// Applicaation Flow Controller

enum filterOption {
  dateModifiedDesc,
  dateModifiedAsc,
  titleAsc,
  titleDesc,
  artistAsc,
  artistDesc,
  albumAsc,
  albumDesc,
  durationDesc,
  durationAsc,
  likeCountDesc,
  likeCountAsc,
}

class Application {
  static final Application _instance = Application._privateConstructor();

  final List<Color> _colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.yellow,
    Colors.brown,
    Colors.cyan,
    Colors.indigo,
    Colors.amber,
    Colors.lime,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.blueGrey,
    Colors.tealAccent,
    Colors.cyanAccent,
    Color(0xFF1A237E),
    Color(0xFF00B8D4),
    Color(0xFFB388FF),
    Color(0xFFFF8A65),
    Color(0xFF43A047),
    Color(0xFF8D6E63),
    Color(0xFF37474F),
    Color(0xFF00C853),
    Color(0xFFFFD600),
    Color(0xFFAA00FF),
    Color(0xFF6200EA),
    Color(0xFF00E5FF),
    Color(0xFFFF1744),
    Color(0xFF304FFE),
    Color(0xFF00BFAE),
    Color(0xFFFFC400),
    Color(0xFF0091EA),
    Color(0xFF64DD17),
    Color(0xFFDD2C00),
  ];

  Application._privateConstructor();

  static Application get instance => _instance;

  CacheManager get cacheManager => CacheManager.instance;

  Future<File?> pickMusicFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'flac'],
        allowMultiple: false,
        dialogTitle: 'Select a Music File',
      );

      if (result == null || result.files.isEmpty) {
        print("User canceled file picking.");
        return null;
      }

      final file = result.files.first;

      if (file.path == null) {
        print("Selected file path is null.");
        return null;
      }

      final selectedFile = File(file.path!);

      return selectedFile;
    } catch (e) {
      print("Error while picking music file: $e");
      return null;
    }
  }

  String? getFileExtension(String path) {
    // Use path package to properly extract file extension
    final String extension = p.extension(path);
    return extension.isEmpty ? null : extension;
  }

  Future<String?> encodeFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Failed to read and encode file: $e");
      return null;
    }
  }

  Future<bool> decodeFile({
    required String base64String,
    required User user,
    required Music music,
    required String extension,
  }) async {
    try {
      final CacheManager cacheManager = CacheManager.instance;
      await cacheManager.clearCache(user);
      final bool success = await cacheManager.saveToCache(
        user,
        music,
        base64String,
      );
      if (success) {
        music.filePath = await cacheManager.getCacheFilePath(user, music);
        print('File saved to cache: ${music.filePath}');
      }
      return success;
    } catch (e) {
      print('Error decoding and saving music file: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> extractMetadata(File file) async {
    try {
      final metadata = await readMetadata(file, getImage: false);

      final title =
          metadata.title?.trim() ?? p.basenameWithoutExtension(file.path);
      final artist = metadata.artist?.trim() ?? 'Unknown Artist';
      final duration = metadata.duration?.inSeconds ?? 0;
      final album = metadata.album?.trim() ?? 'Unknown Album';
      final genreList = metadata.genres;
      final genre =
          (genreList.isNotEmpty)
              ? genreList.first
              : 'Unknown Genre';
      final releaseDate = metadata.year?.toString() ?? 'Unknown';
      return {
        'title': title,
        'artist': artist,
        'duration': duration,
        'genre': genre,
        'album': album,
        'releaseDate': releaseDate,
      };
    } catch (e) {
      print("Error extracting metadata: $e");
      return null;
    }
  }

  Future<Music?> buildMusicObject(File file) async {
    final metadata = await extractMetadata(file);
    if (metadata == null) {
      print("Failed to extract metadata from the file.");
      return null;
    }

    final title = metadata['title'] as String;
    final artistName = metadata['artist'] as String;
    final duration = metadata['duration'] as int;
    final genre = metadata['genre'] as String;
    final albumName = metadata['album'] as String;
    final releaseDateStr = metadata['releaseDate'] as String;

    final artist = Artist(name: artistName);
    final album = Album(title: albumName, artist: artist);
    final releaseDate = DateTime.tryParse(releaseDateStr) ?? DateTime.now();
    final extension = getFileExtension(file.path) ?? 'mp3';

    return Music(
      title: title,
      artist: artist,
      genre: genre,
      durationInSeconds: duration,
      releaseDate: releaseDate,
      album: album,
      filePath: '', // File path will be set later by decodeFile
      extension: extension,
      isPublic: false, // Default to public
    );
  }

  Future<bool> likeSong(User user, Music music) async {
    final tcpClient = TcpClient(serverAddress: "10.0.2.2", serverPort: 12345);
    final response = await tcpClient.likeSong(user: user, music: music);
    if (response['status'] == 'likeSuccess') {
      music.isLiked = true;
      music.likeCount += 1;
      // Add the music object to likedSongs list
      if (!user.likedSongs.contains(music)) {
        user.likedSongs.add(music);
      }
      return true;
    } else if (response['status'] == 'alreadyLiked') {
      music.isLiked = true;
      if (!user.likedSongs.contains(music)) {
        user.likedSongs.add(music);
      }
      return true;
    } else {
      return false;
    }
  }

  Future<bool> dislikeSong(User user, Music music) async {
    final tcpClient = TcpClient(serverAddress: "10.0.2.2", serverPort: 12345);
    final response = await tcpClient.dislikeSong(user: user, music: music);
    if (response['status'] == 'dislikeSuccess') {
      music.isLiked = false;
      music.likeCount = (music.likeCount > 0) ? music.likeCount - 1 : 0;
      // Remove the music object from likedSongs list
      user.likedSongs.removeWhere((likedMusic) => likedMusic.id == music.id);
      return true;
    } else if (response['status'] == 'NotLiked') {
      // Song is not liked, ensure local state is correct
      music.isLiked = false;
      user.likedSongs.removeWhere((likedMusic) => likedMusic.id == music.id);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> toggleLike(User user, Music music) async {
    if (!music.isLiked) {
      return await likeSong(user, music);
    } else {
      return await dislikeSong(user, music);
    }
  }

  /// Synchronizes the like state of music tracks with the user's liked songs
  void syncLikeState(User user, List<Music> tracks) {
    for (Music track in tracks) {
      bool isLiked = user.likedSongs.any(
        (likedMusic) => likedMusic.id == track.id,
      );
      track.isLiked = isLiked;
    }
  }

  List<Music> searchTracks(User user, String query) {
    final lowerQuery = query.toLowerCase();
    return user.tracks.where((music) {
      return music.title.toLowerCase().contains(lowerQuery) ||
          music.artist.name.toLowerCase().contains(lowerQuery) ||
          music.album.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Color getUniqueColor(int id, {BuildContext? context}) {
    if (context != null) {
      try {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        if (themeProvider.isLightMode) {
          // Use pink shades for light theme
          final List<Color> lightColors = [
            Color(0xFFfc6997), // Main pink
            Color(0xFFff6b9d), // Lighter pink
            Color(0xFFff8fab), // Soft pink
            Color(0xFFff6b8a), // Coral pink
            Color(0xFFff7eb3), // Rose pink
            Color(0xFFff6b95), // Deep pink
            Color(0xFFff8fa3), // Light rose
            Color(0xFFff6b8f), // Medium pink
          ];
          return lightColors[id.abs() % lightColors.length];
        }
      } catch (e) {
        // Fallback to default colors if Provider is not available
      }
    }
    return _colorList[id.abs() % _colorList.length];
  }

  Color getPlaylistColor(int id, {BuildContext? context}) => getUniqueColor(id, context: context);

  void showMusicDetailsDialog(BuildContext context, Music music) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder:
          (context) => Dialog(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Track Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  detailsRow('Title', music.title),
                  detailsRow('Artist', music.artist.name),
                  detailsRow('Album', music.album.title),
                  detailsRow('Genre', music.genre),
                  detailsRow(
                    'Duration',
                    formatDuration(music.durationInSeconds),
                  ),
                  detailsRow(
                    'Release',
                    music.releaseDate.toString().split(' ').first,
                  ),
                  detailsRow(
                    'Added',
                    music.addedDate.toString().split(' ').first,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.purpleAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget detailsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<Music> sortTracks(List<Music> tracks, filterOption option) {
    final sorted = List<Music>.from(tracks);

    final baseSort = getBaseSort(option);
    final isAsc = isAscending(option);

    switch (baseSort) {
      case filterOption.dateModifiedDesc:
        sorted.sort(
          (a, b) =>
              isAsc
                  ? a.addedDate.compareTo(b.addedDate)
                  : b.addedDate.compareTo(a.addedDate),
        );
        break;
      case filterOption.titleAsc:
        sorted.sort(
          (a, b) =>
              isAsc
                  ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
                  : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case filterOption.artistAsc:
        sorted.sort(
          (a, b) =>
              isAsc
                  ? a.artist.name.toLowerCase().compareTo(b.artist.name.toLowerCase())
                  : b.artist.name.toLowerCase().compareTo(a.artist.name.toLowerCase()),
        );
        break;
      case filterOption.albumAsc:
        sorted.sort(
          (a, b) =>
              isAsc
                  ? (a.album.name ?? '').toLowerCase().compareTo((b.album.name ?? '').toLowerCase())
                  : (b.album.name ?? '').toLowerCase().compareTo((a.album.name ?? '').toLowerCase()),
        );
        break;
      case filterOption.durationDesc:
        sorted.sort(
          (a, b) =>
              isAsc
                  ? a.durationInSeconds.compareTo(b.durationInSeconds)
                  : b.durationInSeconds.compareTo(a.durationInSeconds),
        );
        break;
      case filterOption.likeCountDesc:
        sorted.sort(
          (a, b) =>
              isAsc
                  ? a.likeCount.compareTo(b.likeCount)
                  : b.likeCount.compareTo(a.likeCount),
        );
        break;
      default:
        sorted.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
    }
    return sorted;
  }

  filterOption getOppositeSort(filterOption currentSort) {
    switch (currentSort) {
      case filterOption.dateModifiedDesc:
        return filterOption.dateModifiedAsc;
      case filterOption.dateModifiedAsc:
        return filterOption.dateModifiedDesc;
      case filterOption.titleAsc:
        return filterOption.titleDesc;
      case filterOption.titleDesc:
        return filterOption.titleAsc;
      case filterOption.artistAsc:
        return filterOption.artistDesc;
      case filterOption.artistDesc:
        return filterOption.artistAsc;
      case filterOption.albumAsc:
        return filterOption.albumDesc;
      case filterOption.albumDesc:
        return filterOption.albumAsc;
      case filterOption.durationDesc:
        return filterOption.durationAsc;
      case filterOption.durationAsc:
        return filterOption.durationDesc;
      case filterOption.likeCountDesc:
        return filterOption.likeCountAsc;
      case filterOption.likeCountAsc:
        return filterOption.likeCountDesc;
      default:
        return filterOption.dateModifiedDesc; // Default fallback
    }
  }

  /// for display purposes
  filterOption getBaseSort(filterOption sort) {
    switch (sort) {
      case filterOption.dateModifiedDesc:
      case filterOption.dateModifiedAsc:
        return filterOption.dateModifiedDesc;
      case filterOption.titleAsc:
      case filterOption.titleDesc:
        return filterOption.titleAsc;
      case filterOption.artistAsc:
      case filterOption.artistDesc:
        return filterOption.artistAsc;
      case filterOption.albumAsc:
      case filterOption.albumDesc:
        return filterOption.albumAsc;
      case filterOption.durationDesc:
      case filterOption.durationAsc:
        return filterOption.durationDesc;
      case filterOption.likeCountDesc:
      case filterOption.likeCountAsc:
        return filterOption.likeCountDesc;
      default:
        return filterOption.dateModifiedDesc; // Default fallback
    }
  }

  bool isAscending(filterOption sort) {
    switch (sort) {
      case filterOption.dateModifiedAsc:
      case filterOption.titleAsc:
      case filterOption.artistAsc:
      case filterOption.albumAsc:
      case filterOption.durationAsc:
      case filterOption.likeCountAsc:
        return true;
      default:
        return false;
    }
  }

  Future<bool> deleteMusic({
    required BuildContext context,
    required User user,
    required Music music,
  }) async {
    final tcpClient = TcpClient(serverAddress: "10.0.2.2", serverPort: 12345);
    final response = await tcpClient.removeMusic(user: user, music: music);
    if (response['status'] == 'removeMusicSuccess') {
      user.tracks.remove(music);
      _showDeleteSnackBar(context, music.title);
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete track: ${response['message']}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void _showDeleteSnackBar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Track "$title" deleted!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis, //"text is too lon..."
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 52, 21, 57),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        duration: Duration(seconds: 2),
        elevation: 15,
      ),
    );
  }

  /// Handles music playback using cache system
  Future<bool> handleMusicPlayback({
    required BuildContext context,
    required User user,
    required Music music,
  }) async {
    try {
      final CacheManager cacheManager = CacheManager.instance;

      // Check if music is already cached
      final bool isCached = await cacheManager.isMusicCached(user, music);

      if (isCached) {
        print('Playing cached music: ${music.title}');
        final String? cachedPath = await cacheManager.getCachedMusicPath(
          user,
          music,
        );
        if (cachedPath != null) {
          // Check if the audio controller is already playing the same song
          final audioController = AudioController.instance;
          if (audioController.hasTrack &&
              audioController.currentTrack!.id == music.id) {
            // The same song is already playing, navigate to PlayPage without reinitializing
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PlayPage(
                      music: music,
                      user: user,
                      playlist: user.tracks,
                    ),
              ),
            );
            return true;
          }

          //Navigate to play page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PlayPage(music: music, user: user, playlist: user.tracks),
            ),
          );
          return true;
        }
      }
      print('Ensuring cached: ${music.title}');

      // Show loading indicator
      _showDownloadingSnackBar(context, 'Downloading ${music.title}...');

      // Ensure cached
      final String? cachedPath = await cacheManager.ensureCached(
        user: user,
        music: music,
      );

      if (cachedPath != null) {
        _hideSnackBar(context);
        // Check if the audio controller is already playing the same song
        final audioController = AudioController.instance;
        if (audioController.hasTrack &&
            audioController.currentTrack!.id == music.id) {
          // The same song is already playing, navigate to PlayPage without reinitializing
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PlayPage(music: music, user: user, playlist: user.tracks),
            ),
          );
          return true;
        }

        //Navigate to play page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    PlayPage(music: music, user: user, playlist: user.tracks),
          ),
        );
        return true;
      } else {
        _hideSnackBar(context);
        _showPlaybackErrorSnackBar(context, 'Failed to download music');
        return false;
      }
    } catch (e) {
      print('Error handling music playback: $e');
      _hideSnackBar(context);
      return false;
    }
  }

  /// Shows a snackbar indicating download is in progress
  void _showDownloadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        duration: Duration(seconds: 30), // Long duration for download
        elevation: 15,
      ),
    );
  }

  /// Shows a snackbar for successful playback
  void _showPlaybackSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        duration: Duration(seconds: 3),
        elevation: 15,
      ),
    );
  }

  /// Shows a snackbar for playback errors
  void _showPlaybackErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        duration: Duration(seconds: 3),
        elevation: 15,
      ),
    );
  }

  /// Hides the current snackbar
  void _hideSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Public methods for snackbar management
  void showDownloadingSnackBar(BuildContext context, String message) {
    _showDownloadingSnackBar(context, message);
  }

  void hideSnackBar(BuildContext context) {
    _hideSnackBar(context);
  }

  void showPlaybackSuccessSnackBar(BuildContext context, String message) {
    _showPlaybackSuccessSnackBar(context, message);
  }

  void showPlaybackErrorSnackBar(BuildContext context, String message) {
    _showPlaybackErrorSnackBar(context, message);
  }

  /// Clear cache for a user (stops playback safely before deleting files)
  Future<void> clearUserCache(User user) async {
    try {
      // Stop playback and reset the audio controller to avoid deleting a file in use
      await AudioController.instance.stopAndReset();

      final CacheManager cacheManager = CacheManager.instance;
      await cacheManager.clearCache(user);
      print('Cache cleared for user: ${user.username}');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get cache information for a user
  Future<Map<String, dynamic>> getCacheInfo(User user) async {
    try {
      final CacheManager cacheManager = CacheManager.instance;
      return await cacheManager.getCacheInfo(user);
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

  /// Show cache management dialog
  void showCacheManagementDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder:
          (context) => FutureBuilder<Map<String, dynamic>>(
            future: getCacheInfo(user),
            builder: (context, snapshot) {
              final cacheInfo =
                  snapshot.data ??
                  {
                    'size': 0,
                    'formattedSize': '0 B',
                    'fileCount': 0,
                    'cachePath': '',
                  };

              return Dialog(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage, color: Colors.blueGrey, size: 30),
                          SizedBox(width: 10),
                          Text(
                            'Cache Management',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      detailsRow('Cache Size', cacheInfo['formattedSize']),
                      detailsRow('Files Cached', '${cacheInfo['fileCount']}'),
                      detailsRow('Cache Path', cacheInfo['cachePath']),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await clearUserCache(user);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cache cleared successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                            ),
                            label: Text('Clear Cache'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Close',
                              style: TextStyle(color: Colors.purpleAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  /// Share music functionality
  Future<bool> shareMusic({
    required BuildContext context,
    required User user,
    required Music music,
  }) async {
    try {
      // Check if music is already cached
      final bool isCached = await cacheManager.isMusicCached(user, music);

      if (!isCached) {
        // Show downloading indicator
        _showDownloadingSnackBar(
          context,
          'Downloading ${music.title} for sharing...',
        );

        // Download and cache the music without clearing existing cache
        final bool downloadSuccess = await cacheManager
            .downloadAndCacheMusicForSharing(user: user, music: music);

        if (!downloadSuccess) {
          _hideSnackBar(context);
          _showPlaybackErrorSnackBar(
            context,
            'Failed to download music for sharing',
          );
          return false;
        }

        _hideSnackBar(context);
      }

      // Get the cached file path
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        user,
        music,
      );

      if (cachedPath == null || !File(cachedPath).existsSync()) {
        _showPlaybackErrorSnackBar(context, 'Music file not found');
        return false;
      }

      // Share the music file with custom filename (just the title)
      await Share.shareXFiles(
        [XFile(cachedPath, name: '${music.title}.${music.extension}')],
        text: 'Check out this song: ${music.title} by ${music.artist.name}',
        subject: 'Music Share: ${music.title}',
      );

      _showPlaybackSuccessSnackBar(context, 'Music shared successfully!');
      return true;
    } catch (e) {
      print('Error sharing music: $e');
      _hideSnackBar(context);
      _showPlaybackErrorSnackBar(context, 'Failed to share music: $e');
      return false;
    }
  }

  Future<bool> downloadMusic(User user, Music music) async {
    try {
      // Use the existing cache system to download and cache the music
      final cachedPath = await cacheManager.ensureCached(user: user, music: music);
      if (cachedPath == null) return false;

      // Also export to device public Music directory (Android, via MethodChannel)
      try {
        final file = File(cachedPath);
        if (await file.exists()) {
          final bytes = Uint8List.fromList(await file.readAsBytes());
          final mimeType = _mimeTypeForExtension(music.extension);
          const MethodChannel channel = MethodChannel('hertz/media_store');
          final savedUri = await channel.invokeMethod<String>('saveAudioToPublic', {
            'fileName': '${music.title}.${music.extension}',
            'mimeType': mimeType,
            'bytes': bytes,
          });
          print('Saved to device (MediaStore): $savedUri');
        }
      } catch (e) {
        print('Error exporting to MediaStore: $e');
        // Non-fatal: caching already succeeded
      }

      return true;
    } catch (e) {
      print('Error downloading music: $e');
      return false;
    }
  }

  String _mimeTypeForExtension(String ext) {
    final lower = ext.toLowerCase();
    switch (lower) {
      case 'mp3':
        return 'audio/mpeg';
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'flac':
        return 'audio/flac';
      case 'm4a':
        return 'audio/mp4';
      default:
        return 'audio/*';
    }
  }

  Future<bool> makeMusicPublic(User user, Music music) async {
    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.makeMusicPublic(user.username, music.id);
      
      if (response['status'] == 'makeMusicPublicSuccess' || response['status'] == 'success') {
        music.isPublic = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Error making music public: $e');
      return false;
    }
  }
}
