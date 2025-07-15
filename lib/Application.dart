import 'dart:convert';
import 'dart:io';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Model/Artist.dart';
import 'Model/Album.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'TcpClient.dart';
import 'LibraryPage.dart';

// Applicaation Flow Controller

enum filterOption { dateModified, az, za, duration, favourite }

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
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return null;
    return path.substring(lastDot);
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
      final bytes = base64Decode(base64String);

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String userDirPath = '${appDocDir.path}\\${user.username}\\musics';
      final Directory userDir = Directory(userDirPath);
      if (!await userDir.exists()) {
        await userDir.create(recursive: true);
      }

      final String ext = extension;
      final String fileName = '${music.title}.$ext';
      final String filePath = '$userDirPath\\$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      music.filePath = filePath;
      return true;
    } catch (e) {
      print('Error decoding and saving music file: $e');
      return false;
    }
  }

  Future<bool> downloadAndSaveMusic({
    required TcpClient tcpClient,
    required User user,
    required Music music,
  }) async {
    final base64 = await tcpClient.getMusicBase64(user: user, music: music);
    if (base64 == null) {
      print('Failed to get base64 music from server.');
      return false;
    }
    return await decodeFile(
      base64String: base64,
      user: user,
      music: music,
      extension: music.extension,
    );
  }

  Future<Map<String, dynamic>?> extractMetadata(File file) async {
    try {
      final metadata = await readMetadata(file, getImage: false);

      final title =
          metadata.title?.trim() ?? file.uri.pathSegments.last.split('.').first;
      final artist = metadata.artist?.trim() ?? 'Unknown Artist';
      final duration = metadata.duration?.inSeconds ?? 0;
      final album = metadata.album?.trim() ?? 'Unknown Album';
      final genreList = metadata.genres;
      final genre =
          (genreList != null && genreList.isNotEmpty)
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
      filePath: '', // File path will be set later
      extension: extension,
    );
  }

  Future<bool> likeSong(User user, Music music) async {
    final tcpClient = TcpClient(serverAddress: "10.0.2.2", serverPort: 12345);
    final response = await tcpClient.likeSong(user: user, music: music);
    if (response['status'] == 'likeSuccess') {
      music.isLiked = true;
      music.likeCount += 1;
      if (!user.likedSongs.contains(music)) {
        user.likedSongs.add(music);
      }
      return true;
    } else {
      print('Failed to like: ${response['message']}');
      return false;
    }
  }

  Future<bool> dislikeSong(User user, Music music) async {
    final tcpClient = TcpClient(serverAddress: "10.0.2.2", serverPort: 12345);
    final response = await tcpClient.dislikeSong(user: user, music: music);
    if (response['status'] == 'dislikeSuccess') {
      music.isLiked = false;
      music.likeCount = (music.likeCount > 0) ? music.likeCount - 1 : 0;
      user.likedSongs.remove(music);
      return true;
    } else {
      print('Failed to dislike: ${response['message']}');
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

  List<Music> searchTracks(User user, String query) {
    final lowerQuery = query.toLowerCase();
    return user.tracks.where((music) {
      return music.title.toLowerCase().contains(lowerQuery) ||
          music.artist.name.toLowerCase().contains(lowerQuery) ||
          music.album.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Color getUniqueColor(int id) {
    return _colorList[id.abs() % _colorList.length];
  }

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
    switch (option) {
      case filterOption.az:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case filterOption.za:
        sorted.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case filterOption.duration:
        sorted.sort(
          (a, b) => b.durationInSeconds.compareTo(a.durationInSeconds),
        );
        break;
      case filterOption.favourite:
        sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;
      case filterOption.dateModified:
      default:
        sorted.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
    }
    return sorted;
  }

  Future<bool> deleteMusic({
    required BuildContext context,
    required User user,
    required Music music,
  }) async {
    final tcpClient = TcpClient(serverAddress: "10.0.2.2", serverPort: 12345);
    final response = await tcpClient.deleteMusic(user: user, music: music);
    if (response['status'] == 'deleteMusicSuccess') {
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
}
