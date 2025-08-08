import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Model/Playlist.dart';
import 'Model/Music.dart';
import 'TcpClient.dart';
import 'Application.dart';
import 'PlayPage.dart';
import 'utils/AudioController.dart';
import 'utils/CacheManager.dart';
import 'AddTrackToPlaylistDialog.dart';
import 'widgets/MiniPlayer.dart';

class PlaylistTracksPage extends StatefulWidget {
  final User user;
  final Playlist playlist;

  const PlaylistTracksPage({
    super.key,
    required this.user,
    required this.playlist,
  });

  @override
  State<PlaylistTracksPage> createState() => _PlaylistTracksPageState();
}

class _PlaylistTracksPageState extends State<PlaylistTracksPage> {
  late TcpClient _tcpClient;
  List<Music> _tracks = [];
  bool _isLoading = true;
  final Application _application = Application.instance;

  @override
  void initState() {
    super.initState();
    _tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
    _loadPlaylistTracks();
  }

  Future<void> _loadPlaylistTracks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh the playlist data from server
      final playlists = await _tcpClient.getUserPlaylists(widget.user);
      final updatedPlaylist = playlists.firstWhere(
        (p) => p.id == widget.playlist.id,
        orElse: () => widget.playlist,
      );

      setState(() {
        _tracks = updatedPlaylist.tracks;
        // Sync like states for playlist tracks
        _application.syncLikeState(widget.user, _tracks);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading playlist tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPlaylist() async {
    await _loadPlaylistTracks();
  }

  Future<void> _onTrackTap(BuildContext context, Music music) async {
    try {
      // Check if the audio controller is already playing the same song from the same playlist
      final audioController = AudioController.instance;
      if (audioController.hasTrack &&
          audioController.currentTrack!.id == music.id &&
          audioController.playlist == _tracks) {
        // The same song from the same playlist is already playing, navigate to PlayPage without reinitializing
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PlayPage(
                  music: music,
                  user: widget.user,
                  playlist: _tracks,
                ),
          ),
        );
        return;
      }

      // Always restart playback when playing from playlist (even if same song from different playlist)
      await _handlePlaylistMusicPlayback(context, music);
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

  Future<void> _handlePlaylistMusicPlayback(
    BuildContext context,
    Music music,
  ) async {
    try {
      final CacheManager cacheManager = CacheManager.instance;

      // Check if music is already cached
      final bool isCached = await cacheManager.isMusicCached(
        widget.user,
        music,
      );

      if (isCached) {
        print('Playing cached music from playlist: ${music.title}');
        final String? cachedPath = await cacheManager.getCachedMusicPath(
          widget.user,
          music,
        );
        if (cachedPath != null) {
          // Navigate to play page with playlist tracks
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PlayPage(
                    music: music,
                    user: widget.user,
                    playlist:
                        _tracks, // Use playlist tracks instead of user.tracks
                  ),
            ),
          );
          return;
        }
      }

      // Music is not cached, download and cache it
      print('Downloading and caching music from playlist: ${music.title}');

      // Show loading indicator
      _application.showDownloadingSnackBar(
        context,
        'Downloading ${music.title}...',
      );

      // Download and cache the music
      final bool downloadSuccess = await cacheManager.downloadAndCacheMusic(
        user: widget.user,
        music: music,
      );

      if (downloadSuccess) {
        _application.hideSnackBar(context);

        // Navigate to play page with playlist tracks
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PlayPage(
                  music: music,
                  user: widget.user,
                  playlist:
                      _tracks, // Use playlist tracks instead of user.tracks
                ),
          ),
        );
      } else {
        _application.hideSnackBar(context);
        _application.showPlaybackErrorSnackBar(
          context,
          'Failed to download music',
        );
      }
    } catch (e) {
      print('Error handling playlist music playback: $e');
      _application.hideSnackBar(context);
    }
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
                  leading: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.orange,
                  ),
                  title: Text('Remove from Playlist'),
                  onTap: () => Navigator.pop(context, 'remove'),
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
      await _handlePlaylistMusicPlayback(context, music);
    } else if (result == 'remove') {
      await _removeTrackFromPlaylist(music);
    } else if (result == 'details') {
      _application.showMusicDetailsDialog(context, music);
    }
  }

  Future<void> _removeTrackFromPlaylist(Music music) async {
    try {
      final response = await _tcpClient.deleteSongFromPlaylist(
        user: widget.user,
        playlist: widget.playlist,
        music: music,
      );

      if (response['status'] == 'deleteSongFromPlaylistSuccess') {
        setState(() {
          _tracks.remove(music);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Track removed from playlist'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to remove track'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error removing track from playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing track'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddTrackDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddTrackToPlaylistDialog(
            user: widget.user,
            playlist: widget.playlist,
            tcpClient: _tcpClient,
            onTrackAdded: () {
              _loadPlaylistTracks(); // Refresh the playlist after adding track
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistColor = _application.getPlaylistColor(widget.playlist.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.playlist_play, color: playlistColor, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.playlist.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_tracks.length} tracks',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: playlistColor, size: 30),
            onPressed: _showAddTrackDialog,
            tooltip: 'Add Track to Playlist',
          ),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.1,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _refreshPlaylist,
                      color: Colors.purple,
                      backgroundColor: Colors.grey[900],
                      strokeWidth: 3,
                      child:
                          _tracks.isEmpty
                              ? ListView(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.7,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.playlist_play,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No tracks in this playlist',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Add some tracks to get started',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                itemCount: _tracks.length,
                                itemBuilder: (context, index) {
                                  final music = _tracks[index];
                                  final isLiked = music.isLiked;
                                  return ListTile(
                                    onTap: () => _onTrackTap(context, music),
                                    onLongPress:
                                        () => _onTrackLongPress(context, music),
                                    leading: Icon(
                                      Icons.music_note,
                                      color: _application.getUniqueColor(
                                        music.id,
                                      ),
                                    ),
                                    title: Text(
                                      music.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      music.artist.name,
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _application.formatDuration(
                                            music.durationInSeconds,
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        AnimatedSwitcher(
                                          duration: Duration(milliseconds: 400),
                                          transitionBuilder:
                                              (child, animation) =>
                                                  ScaleTransition(
                                                    scale: animation,
                                                    child: child,
                                                  ),
                                          child: GestureDetector(
                                            key: ValueKey<bool>(isLiked),
                                            onTap: () async {
                                              final success = await _application
                                                  .toggleLike(
                                                    widget.user,
                                                    music,
                                                  );
                                              if (success) {
                                                setState(() {});
                                              }
                                            },
                                            child: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: _application
                                                  .getUniqueColor(music.id),
                                              size: 25,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 55), // ← Add bottom margin
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
