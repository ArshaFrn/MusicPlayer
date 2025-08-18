import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Model/Playlist.dart';
import 'Model/Music.dart';
import 'TcpClient.dart';
import 'Application.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';

class AddTrackToPlaylistDialog extends StatefulWidget {
  final User user;
  final Playlist playlist;
  final TcpClient tcpClient;
  final VoidCallback onTrackAdded;

  const AddTrackToPlaylistDialog({
    super.key,
    required this.user,
    required this.playlist,
    required this.tcpClient,
    required this.onTrackAdded,
  });

  @override
  State<AddTrackToPlaylistDialog> createState() =>
      _AddTrackToPlaylistDialogState();
}

class _AddTrackToPlaylistDialogState extends State<AddTrackToPlaylistDialog> {
  List<Music> _userTracks = [];
  bool _isLoading = true;
  final Application _application = Application.instance;

  @override
  void initState() {
    super.initState();
    _loadUserTracks();
  }

  Future<void> _loadUserTracks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tracks = await widget.tcpClient.getUserMusicList(widget.user);

      // Filter out tracks that are already in the playlist
      final playlistTrackIds = widget.playlist.tracks.map((t) => t.id).toSet();
      final availableTracks =
          tracks
              .where((track) => !playlistTrackIds.contains(track.id))
              .toList();

      setState(() {
        _userTracks = availableTracks;
        // Sync like states for available tracks
        _application.syncLikeState(widget.user, _userTracks);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTrackToPlaylist(Music track) async {
    try {
      final response = await widget.tcpClient.addSongToPlaylist(
        user: widget.user,
        playlist: widget.playlist,
        music: track,
      );

      if (response['status'] == 'addSongToPlaylistSuccess') {
        // Remove the track from available tracks
        setState(() {
          _userTracks.remove(track);
        });

        // Update the user's playlist object in frontend
        final userPlaylist = widget.user.playlists.firstWhere(
          (p) => p.id == widget.playlist.id,
          orElse: () => widget.playlist,
        );
        if (userPlaylist != widget.playlist) {
          userPlaylist.tracks.add(track);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added "${track.title}" to playlist',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade800,
            duration: Duration(seconds: 2),
          ),
        );

        // Call the callback to refresh the playlist
        widget.onTrackAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to add track to playlist',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error adding track to playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding track to playlist'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);
    final playlistColor = isDark ? _application.getPlaylistColor(widget.playlist.id) : primaryColor;
    
    return Dialog(
      backgroundColor: isDark 
          ? Colors.grey.shade900.withOpacity(0.95)
          : Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade100.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: playlistColor,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // make the playlist name (just playlist name) based on the color of the playlist
                        Text(
                          widget.playlist.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: playlistColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Select tracks from your library',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54, 
                            fontSize: 14
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close, 
                      color: isDark ? Colors.white70 : Colors.black54
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tracks List
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _userTracks.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: isDark ? Colors.grey : Colors.grey[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tracks available to add',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'All your tracks are already in this playlist',
                              style: TextStyle(
                                color: isDark ? Colors.grey : Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _userTracks.length,
                        itemBuilder: (context, index) {
                          final track = _userTracks[index];
                          return ListTile(
                            onTap:
                                () => _addTrackToPlaylist(
                                  track,
                                ), // ← Add tap handler to entire tile
                            leading: Icon(
                              Icons.music_note,
                              color: _application.getUniqueColor(track.id, context: context),
                            ),
                            title: Text(
                              track.title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              track.artist.name,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _application.formatDuration(
                                    track.durationInSeconds,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: playlistColor,
                                  ),
                                  onPressed: () => _addTrackToPlaylist(track),
                                  tooltip: 'Add to playlist',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
