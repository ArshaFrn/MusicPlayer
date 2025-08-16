import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Model/Playlist.dart';
import 'TcpClient.dart';
import 'Application.dart';
import 'PlaylistTracksPage.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name')),
      );
      return;
    }

    final newPlaylist = Playlist(name: name, description: description);

    final response = await _tcpClient.uploadPlaylist(widget.user, newPlaylist);

    if (response['status'] == 'uploadPlaylistSuccess') {
      _nameController.clear();
      _descriptionController.clear();
      await _fetchPlaylistsFromServer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to create playlist'),
        ),
      );
    }
  }

  Future<void> _showCreatePlaylistDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                const Icon(Icons.playlist_add, size: 48, color: Colors.purple),
                const SizedBox(height: 16),
                const Text(
                  'Create New Playlist',
                  style: TextStyle(
                    color: Colors.white,
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
                      colors: [Colors.purple[300]!, Colors.pink[300]!],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
            content: Container(
              //color
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Playlist Name',
                      labelStyle: const TextStyle(color: Color(0xFFEE00DA)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.purple[200]!,
                          width: 1.4,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.purple,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Playlist Description',
                      labelStyle: const TextStyle(color: Color(0xFFEE00DA)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.purple[200]!,
                          width: 1.4,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.purple,
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
                    colors: [Colors.purple[400]!, Colors.pink[300]!],
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
    final result = await showModalBottomSheet<String>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.playlist_play, color: Colors.blue),
                  title: Text('Open Playlist'),
                  onTap: () => Navigator.pop(context, 'open'),
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Playlist'),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('Playlist Info'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "${playlist.name}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete playlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting playlist'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPlaylistInfo(BuildContext context, Playlist playlist) {
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
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _detailsRow('Name', playlist.name),
                  _detailsRow('Description', playlist.description),
                  _detailsRow('Tracks', '${playlist.tracks.length} songs'),
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

  Widget _detailsRow(String label, String value) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.queue_music, size: 28),
            SizedBox(width: 10),
            Text('Your Playlists'),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePlaylistDialog,
            color: Colors.pinkAccent,
            iconSize: 30,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshPlaylists,
                color: Colors.purple,
                backgroundColor: Colors.grey[900],
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
                                    const Icon(
                                      Icons.playlist_play,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No playlists yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Create a playlist to start organizing your music',
                                      style: TextStyle(color: Colors.grey),
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
                                color: Colors.grey.shade900.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: color, width: 2.2),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.playlist_play,
                                  size: 26,
                                  color: color,
                                ),
                                title: Text(
                                  playlist.name,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    const SizedBox(width: 5),
                                    Text(
                                      playlist.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '${playlist.tracks.length} tracks',
                                  style: const TextStyle(fontSize: 15),
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
