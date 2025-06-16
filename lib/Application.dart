import 'dart:convert';
import 'dart:io';
import 'Music.dart';
import 'User.dart';
import 'package:file_picker/file_picker.dart';

// Applicaation Flow Controller
class Application {
  static final Application _instance = Application._privateConstructor();

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

  Future<String?> readAndEncodeFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Failed to read and encode file: $e");
      return null;
    }
  }

  bool likeMusic(User user, Music music) {
    if (user.likedSongs.contains(music)) {
      unlikeMusic(user, music);
      return false;
    }
    user.likedSongs.add(music);
    return true;
  }

  bool unlikeMusic(User user, Music music) {
    if (!user.likedSongs.contains(music)) {
      likeMusic(user, music);
      return false;
    }
    user.likedSongs.remove(music);
    return true;
  }
}
