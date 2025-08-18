import 'package:flutter/material.dart';
import '../Model/Music.dart';
import '../Model/User.dart';
import '../Application.dart';
import '../TcpClient.dart';
import '../PlayPage.dart';
import '../utils/AudioController.dart';

class LibraryPageController {
  final User user;
  final Application application;
  
  filterOption selectedSort = filterOption.dateModifiedDesc;
  bool isLoading = true;
  String selectedCategory = 'Songs'; // Track selected category

  // Category options
  final List<String> categories = ['Songs', 'Singers', 'Albums', 'Years'];

  LibraryPageController({
    required this.user,
  }) : application = Application.instance;

  Future<void> fetchTracksFromServer() async {
    isLoading = true;
    
    final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
    final tracks = await tcpClient.getUserMusicList(user);
    final likedSongIds = await tcpClient.getUserLikedSongs(user);

    user.tracks
      ..clear()
      ..addAll(tracks);

    user.likedSongs
      ..clear()
      ..addAll(tracks.where((track) => likedSongIds.contains(track.id)));

    for (final track in user.tracks) {
      track.isLiked = likedSongIds.contains(track.id);
    }
    
    isLoading = false;
  }

  List<Music> getSortedTracks() {
    return application.sortTracks(user.tracks, selectedSort);
  }

  void updateSort(filterOption newSort) {
    // If the same base sort is selected, toggle between ascending and descending
    if (application.getBaseSort(selectedSort) ==
        application.getBaseSort(newSort)) {
      selectedSort = application.getOppositeSort(selectedSort);
    } else {
      selectedSort = newSort;
    }
  }

  void updateCategory(String category) {
    selectedCategory = category;
  }

  Future<bool> onLikeTap(Music music) async {
    final success = await application.toggleLike(user, music);
    return success;
  }

  Future<void> onTrackTap(BuildContext context, Music music) async {
    try {
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
        return;
      }

      // Handle music playback logic
      final success = await application.handleMusicPlayback(
        context: context,
        user: user,
        music: music,
      );

      if (!success) {
        print("Error Playing The Song");
      }
    } catch (e) {
      print('Error handling track tap: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing music'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> onTrackLongPress(BuildContext context, Music music) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.play_arrow, color: Colors.blue),
                  title: Text('Play'),
                  onTap: () => Navigator.pop(context, 'play'),
                ),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.green),
                  title: Text('Download'),
                  onTap: () => Navigator.pop(context, 'download'),
                ),
                if (!music.isPublic) ListTile(
                  leading: Icon(Icons.public, color: Colors.orange),
                  title: Text('Make Public'),
                  onTap: () => Navigator.pop(context, 'make_public'),
                ),
                ListTile(
                  leading: Icon(Icons.share, color: Colors.green),
                  title: Text('Share'),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('Details'),
                  onTap: () => Navigator.pop(context, 'details'),
                ),
              ],
            ),
          ),
    );
    
    if (result == 'play') {
      final success = await application.handleMusicPlayback(
        context: context,
        user: user,
        music: music,
      );
      if (!success) {
        print("Error Playing The Song");
      }
    } else if (result == 'download') {
      await downloadMusic(context, music);
    } else if (result == 'make_public') {
      await makeMusicPublic(context, music);
    } else if (result == 'share') {
      await application.shareMusic(
        context: context,
        user: user,
        music: music,
      );
    } else if (result == 'delete') {
      await application.deleteMusic(
        context: context,
        user: user,
        music: music,
      );
    } else if (result == 'details') {
      application.showMusicDetailsDialog(context, music);
    }
  }

  Future<void> downloadMusic(BuildContext context, Music music) async {
    try {
      // Show download progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloading ${music.title}..."),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Implement download logic here
      // You can use the existing cache system or create a separate download manager
      final success = await application.downloadMusic(user, music);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${music.title} downloaded successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to download ${music.title}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error downloading: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> makeMusicPublic(BuildContext context, Music music) async {
    try {
      // Show making public progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Making ${music.title} public..."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Implement make public logic here
      final success = await application.makeMusicPublic(user, music);
      
      if (success) {
        music.isPublic = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${music.title} is now public!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to make ${music.title} public"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error making public: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void showCacheManagementDialog(BuildContext context) {
    application.showCacheManagementDialog(context, user);
  }

  void dispose() {
    // Clean up if needed
  }
}
