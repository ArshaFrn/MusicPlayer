import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';
import 'SearchPage.dart';
import 'TcpClient.dart';

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
  bool _isRefreshing = false;
  bool _isAscending = false; // false = descending, true = ascending

  @override
  void initState() {
    super.initState();
    _fetchTracksFromServer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible
    _fetchTracksFromServer();
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when widget updates (e.g., when returning from other pages)
    if (oldWidget.user != widget.user) {
      _fetchTracksFromServer();
    }
  }

  Future<void> _fetchTracksFromServer() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous requests
    
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });
    
    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final tracks = await tcpClient.getUserMusicList(widget.user);
      final likedSongIds = await tcpClient.getUserLikedSongs(widget.user);

      setState(() {
        widget.user.tracks
          ..clear()
          ..addAll(tracks);

        // Update likedSongs list based on fetched liked song IDs
        widget.user.likedSongs
          ..clear()
          ..addAll(tracks.where((track) => likedSongIds.contains(track.id)));

        // Update isLiked field for each track
        for (final track in widget.user.tracks) {
          track.isLiked = likedSongIds.contains(track.id);
        }

        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      print('Error fetching tracks: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshLibrary() async {
    await _fetchTracksFromServer();
  }

  @override
  Widget build(BuildContext context) {
    var tracks = application.sortTracks(widget.user.tracks, _selectedSort, isAscending: _isAscending);

    return Scaffold(
      appBar: AppBar(
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
          IconButton(
            icon: Icon(
              _isRefreshing ? Icons.refresh : Icons.refresh_outlined,
              color: _isRefreshing ? Colors.orange : Colors.white70,
            ),
            tooltip: "Refresh Library",
            onPressed: _isRefreshing ? null : _refreshLibrary,
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
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, color: Colors.white70),
                  if (_selectedSort != filterOption.dateModified) // Show arrow if not default sort
                    Icon(
                      _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.orange,
                      size: 16,
                    ),
                ],
              ),
              tooltip: "Filter",
              onSelected: (option) {
                setState(() {
                  if (_selectedSort == option) {
                    // Same option selected - toggle ascending/descending
                    _isAscending = !_isAscending;
                  } else {
                    // Different option selected - reset to ascending
                    _selectedSort = option;
                    _isAscending = true;
                  }
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
                            Icon(
                              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.purple,
                              size: 20,
                            ),
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
                            Icon(
                              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.purple,
                              size: 20,
                            ),
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
                            Icon(
                              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.purple,
                              size: 20,
                            ),
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
                            Icon(
                              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.purple,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ],
              offset: Offset(0, 46),
              elevation: 17,
              padding: EdgeInsets.symmetric(vertical: 6),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white70),
            tooltip: "More Options",
            onSelected: (value) {
              if (value == 'cache') {
                application.showCacheManagementDialog(context, widget.user);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cache',
                child: Row(
                  children: [
                    Icon(Icons.storage, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Cache Management'),
                  ],
                ),
              ),
            ],
          ),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.1,
      ),

      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshLibrary,
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
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.music_note),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _onLikeTap(music),
                                    child: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: application.getUniqueColor(
                                        music.id,
                                      ),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                music.title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Text(
                                music.artist.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              trailing: Text(
                                application.formatDuration(
                                  music.durationInSeconds,
                                ),
                                style: TextStyle(fontSize: 10),
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
      // Handle music playback logic
      final success = await application.handleMusicPlayback(
        context: context,
        user: widget.user,
        music: music,
      );

      if (!success) {
        // If playback failed, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play ${music.title}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (result == 'delete') {
      await application.deleteMusic(
        context: context,
        user: widget.user,
        music: music,
      );
      setState(() {}); //Refresh UI
    } else if (result == 'details') {
      application.showMusicDetailsDialog(context, music);
    }
  }

  Future<void> _onLikeTap(Music music) async {
    final success = await application.toggleLike(widget.user, music);
    if (success) {
      setState(() {}); // Only update UI if server operation was successful
    }
  }

  /// Handles tap events on music tracks
  Future<void> _onTrackTap(BuildContext context, Music music) async {
    try {
      // Handle music playback logic
      final success = await application.handleMusicPlayback(
        context: context,
        user: widget.user,
        music: music,
      );

      if (!success) {
        // If playback failed, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play ${music.title}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
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
