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
        allowedExtensions: ['mp3', 'wav', 'aac', 'flac', 'ogg'],
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

  Future<String?> encodeFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Failed to read and encode file: $e");
      return null;
    }
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

    return Music(
      title: title,
      artist: artist,
      genre: genre,
      durationInSeconds: duration,
      releaseDate: releaseDate,
      album: album,
      filePath: file.path,
    );
  }

  bool toggleLike(User user, Music music) {
    if (user.likedSongs.contains(music)) {
      user.likedSongs.remove(music);
      music.isLiked = false;
      music.likeCount--;
      return false;
    } else {
      user.likedSongs.add(music);
      music.isLiked = true;
      music.likeCount++;
      return true;
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
        sorted.sort(
            (a,b) => b.likeCount.compareTo(a.likeCount),
        );
        break;
      case filterOption.dateModified:
      default:
        sorted.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
    }
    return sorted;
  }
}
