import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Model/Playlist.dart';
import 'TcpClient.dart';
import 'Application.dart';
import 'PlaylistTracksPage.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'utils/SnackBarUtils.dart';

class PlaylistsPage extends StatefulWidget {
  final User user;
  final Function(int) onNavigateToPage;

  const PlaylistsPage({
    super.key, 
    required this.user, 
    required this.onNavigateToPage,
  });

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late TcpClient _tcpClient;
  List<Playlist> _playlists = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
    _fetchPlaylistsFromServer();
  }

  Future<void> _fetchPlaylistsFromServer() async {
    setState(() {
      _isLoading = true;
    });
    final playlists = await _tcpClient.getUserPlaylists(widget.user);
    setState(() {
      _playlists = playlists;
      widget.user.playlists
        ..clear()
        ..addAll(playlists);
      _isLoading = false;
    });
  }

  Future<void> _refreshPlaylists() async {
    await _fetchPlaylistsFromServer();
  }

  Future<void> _createPlaylist() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      SnackBarUtils.showErrorSnackBar(context, 'Please enter a playlist name');
      return;
    }

    final newPlaylist = Playlist(name: name, description: description);

    final response = await _tcpClient.uploadPlaylist(widget.user, newPlaylist);

    if (response['status'] == 'uploadPlaylistSuccess') {
      _nameController.clear();
      _descriptionController.clear();
      await _fetchPlaylistsFromServer();
      SnackBarUtils.showSuccessSnackBar(context, 'Playlist created successfully');
    } else {
      SnackBarUtils.showErrorSnackBar(context, response['message'] ?? 'Failed to create playlist');
    }
  }

  Future<void> _showCreatePlaylistDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);
    
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark 
                ? Colors.grey.shade900.withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(Icons.playlist_add, size: 48, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Create New Playlist',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  height: 2,
                  width: 40,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [Colors.purple[300]!, Colors.pink[300]!]
                          : [primaryColor, primaryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
            content: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Playlist Name',
                      labelStyle: TextStyle(color: primaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: isDark ? Colors.purple[200]! : primaryColor.withOpacity(0.6),
                          width: 1.4,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: primaryColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Playlist Description',
                      labelStyle: TextStyle(color: primaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: isDark ? Colors.purple[200]! : primaryColor.withOpacity(0.6),
                          width: 1.4,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: primaryColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
                child: const Text('Cancel'),
              ),
              SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [Colors.purple[400]!, Colors.pink[300]!]
                        : [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createPlaylist();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Create', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _onPlaylistLongPress(
    BuildContext context,
    Playlist playlist,
  ) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.playlist_play, color: Colors.blue),
                  title: Text('Open Playlist', 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  onTap: () => Navigator.pop(context, 'open'),
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Playlist', 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('Playlist Info', 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  onTap: () => Navigator.pop(context, 'info'),
                ),
              ],
            ),
          ),
    );

    if (result == 'open') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  PlaylistTracksPage(user: widget.user, playlist: playlist),
        ),
      );
    } else if (result == 'delete') {
      await _deletePlaylist(playlist);
    } else if (result == 'info') {
      _showPlaylistInfo(context, playlist);
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    try {
      final response = await _tcpClient.removePlaylist(
        user: widget.user,
        playlist: playlist,
      );

      if (response['status'] == 'removePlaylistSuccess') {
        setState(() {
          _playlists.remove(playlist);
          widget.user.playlists.remove(playlist);
        });
        SnackBarUtils.showSuccessSnackBar(context, 'Playlist "${playlist.name}" deleted');
      } else {
        SnackBarUtils.showErrorSnackBar(context, response['message'] ?? 'Failed to delete playlist');
      }
    } catch (e) {
      print('Error deleting playlist: $e');
      SnackBarUtils.showErrorSnackBar(context, 'Error deleting playlist');
    }
  }

  void _showPlaylistInfo(BuildContext context, Playlist playlist) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder:
          (context) => Dialog(
            backgroundColor: isDark 
                ? Theme.of(context).colorScheme.surface.withOpacity(0.85)
                : Colors.white.withOpacity(0.95),
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
                        Icons.playlist_play,
                        color: Application.instance.getPlaylistColor(
                          playlist.id,
                        ),
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Playlist Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 24,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _detailsRow('Name', playlist.name, isDark),
                  _detailsRow('Description', playlist.description, isDark),
                  _detailsRow('Tracks', '${playlist.tracks.length} songs', isDark),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _detailsRow(String label, String value, bool isDark) {
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
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Color(0xFFf8f5f0),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Color(0xFFf8f5f0),
        title: Row(
          children: [
            Icon(Icons.queue_music, size: 28, color: primaryColor),
            SizedBox(width: 10),
            Text('Your Playlists', 
              style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: primaryColor),
            onPressed: _showCreatePlaylistDialog,
            iconSize: 30,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : RefreshIndicator(
                onRefresh: _refreshPlaylists,
                color: primaryColor,
                backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                strokeWidth: 3,
                child:
                    _playlists.isEmpty
                        ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.playlist_play,
                                      size: 64,
                                      color: isDark ? Colors.grey : Colors.grey[600],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No playlists yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isDark ? Colors.grey : Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Create a playlist to start organizing your music',
                                      style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            final color = Application.instance.getPlaylistColor(
                              playlist.id,
                            );
                                                         return Container(
                               margin: const EdgeInsets.fromLTRB(5, 10, 5, 2),
                               decoration: BoxDecoration(
                                 color: isDark 
                                     ? Colors.grey.shade900.withOpacity(0.4)
                                     : Colors.white.withOpacity(0.8),
                                 borderRadius: BorderRadius.circular(18),
                                 border: Border.all(
                                   color: isDark ? color : primaryColor, 
                                   width: 2.2
                                 ),
                                 boxShadow: isDark ? null : [
                                   BoxShadow(
                                     color: Colors.black.withOpacity(0.1),
                                     blurRadius: 8,
                                     offset: Offset(0, 2),
                                   ),
                                 ],
                               ),
                              child: ListTile(
                                                                 leading: Icon(
                                   Icons.playlist_play,
                                   size: 26,
                                   color: isDark ? color : primaryColor,
                                 ),
                                                                 title: Text(
                                   playlist.name,
                                   style: TextStyle(
                                     color: isDark ? color : primaryColor,
                                     fontWeight: FontWeight.w600,
                                     fontSize: 20,
                                   ),
                                 ),
                                subtitle: Row(
                                  children: [
                                    SizedBox(width: 5),
                                    Text(
                                      playlist.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '${playlist.tracks.length} tracks',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PlaylistTracksPage(
                                            user: widget.user,
                                            playlist: playlist,
                                          ),
                                    ),
                                  );
                                },
                                onLongPress:
                                    () =>
                                        _onPlaylistLongPress(context, playlist),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
