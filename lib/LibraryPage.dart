import 'dart:math';

import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';
import 'SearchPage.dart';
import 'TcpClient.dart';
import 'utils/AudioController.dart';
import 'PlayPage.dart';

class LibraryPage extends StatefulWidget {
  final User user;

  const LibraryPage({super.key, required this.user});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final Application application = Application.instance;
  filterOption _selectedSort = filterOption.dateModified;
  bool _isLoading = true;
  static bool _hasFetchedTracks = false;

  @override
  void initState() {
    super.initState();
    if (!_hasFetchedTracks) {
      _fetchTracksFromServer();
      _hasFetchedTracks = true;
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTracksFromServer() async {
    setState(() {
      _isLoading = true;
    });
    final tcpClient = TcpClient(
      serverAddress: '10.0.2.2',
      serverPort: 12345,
    );
    final tracks = await tcpClient.getUserMusicList(widget.user);
    final likedSongIds = await tcpClient.getUserLikedSongs(widget.user);

    setState(() {
      widget.user.tracks
        ..clear()
        ..addAll(tracks);

      widget.user.likedSongs
        ..clear()
        ..addAll(tracks.where((track) => likedSongIds.contains(track.id)));

      for (final track in widget.user.tracks) {
        track.isLiked = likedSongIds.contains(track.id);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var tracks = application.sortTracks(widget.user.tracks, _selectedSort);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.library_music, color: Colors.white, size: 24),
            const SizedBox(width: 5),
            const Text(
              "Library",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            tooltip: "Search",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchPage(user: widget.user),
                ),
              );
            },
          ),
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 17,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
              ),
            ),
            child: PopupMenuButton<filterOption>(
              icon: Icon(Icons.filter_list, color: Colors.white70),
              tooltip: "Filter",
              onSelected: (option) {
                setState(() {
                  _selectedSort = option;
                });
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: filterOption.dateModified,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.purpleAccent,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text('Date Modified')),
                          if (_selectedSort == filterOption.dateModified)
                            Icon(Icons.check, color: Colors.purple, size: 20),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: filterOption.az,
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text('A-Z')),
                          if (_selectedSort == filterOption.az)
                            Icon(Icons.check, color: Colors.purple, size: 20),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: filterOption.za,
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text('Z-A')),
                          if (_selectedSort == filterOption.za)
                            Icon(Icons.check, color: Colors.purple, size: 20),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: filterOption.duration,
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text('Duration')),
                          if (_selectedSort == filterOption.duration)
                            Icon(Icons.check, color: Colors.purple, size: 20),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: filterOption.favourite,
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Text('Like Count')),
                          if (_selectedSort == filterOption.favourite)
                            Icon(Icons.check, color: Colors.purple, size: 22),
                        ],
                      ),
                    ),
                  ],
              offset: Offset(0, 46),
              elevation: 17,
              padding: EdgeInsets.symmetric(vertical: 6),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.storage, color: Colors.white70),
            tooltip: "Cache Management",
            onPressed: () {
              application.showCacheManagementDialog(context, widget.user);
            },
          ),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.1,
      ),

      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchTracksFromServer,
                child:
                    tracks.isEmpty
                        ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Text(
                                  "No tracks available :(\nPlease add some music to your library",
                                  style: TextStyle(
                                    fontSize: 19,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                    height: 1.9,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          itemCount: tracks.length,
                          itemBuilder: (context, index) {
                            final music = tracks[index];
                            final isLiked = music.isLiked;
                            return ListTile(
                              onTap: () => _onTrackTap(context, music),
                              onLongPress:
                                  () => _onTrackLongPress(context, music),
                              leading: Icon(Icons.music_note),
                              title: Text(music.title),
                              subtitle: Text(music.artist.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    application.formatDuration(
                                      music.durationInSeconds,
                                    ),
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  SizedBox(width: 15),
                                  AnimatedSwitcher(
                                    duration: Duration(milliseconds: 400),
                                    transitionBuilder:
                                        (child, animation) => ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                    child: GestureDetector(
                                      key: ValueKey<bool>(isLiked),
                                      onTap: () => _onLikeTap(music),
                                      child: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: application.getUniqueColor(
                                          music.id,
                                        ),
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              iconColor: application.getUniqueColor(music.id),
                            );
                          },
                        ),
              ),
    );
  }

  Future<void> _onTrackLongPress(BuildContext context, Music music) async {
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
        user: widget.user,
        music: music,
      );
      if (!success) {
        print("Error Playing The Song");
      }
    } else if (result == 'delete') {
      await application.deleteMusic(
        context: context,
        user: widget.user,
        music: music,
      );
      setState(() {});
    } else if (result == 'details') {
      application.showMusicDetailsDialog(context, music);
    }
  }

  Future<void> _onLikeTap(Music music) async {
    final success = await application.toggleLike(widget.user, music);
    if (success) {
      setState(() {});
    }
  }

  /// Handles tap events on music tracks
  Future<void> _onTrackTap(BuildContext context, Music music) async {
    try {
      // Check if the audio controller is already playing the same song
      final audioController = AudioController.instance;
      if (audioController.hasTrack &&
          audioController.currentTrack!.id == music.id) {
        // The same song is already playing, navigate to PlayPage without reinitializing
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayPage(
              music: music,
              user: widget.user,
              playlist: widget.user.tracks,
            ),
          ),
        );
        return;
      }

      // Handle music playback logic
      final success = await application.handleMusicPlayback(
        context: context,
        user: widget.user,
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
}
