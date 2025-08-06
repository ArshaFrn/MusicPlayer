import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Model/Playlist.dart';
import 'TcpClient.dart';

class PlaylistsPage extends StatefulWidget {
  final User _user;

  const PlaylistsPage({super.key, required User user}) : _user = user;

  @override
  State<PlaylistsPage> createState() => _PlaylistsPage();
}

class _PlaylistsPage extends State<PlaylistsPage> {
  late TcpClient _tcpClient;
  late List<Playlist> _playlists;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = true;
  static bool _hasFetchedPlaylists = false;

  @override
  void initState() {
    super.initState();
    _tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
    if (!_hasFetchedPlaylists) {
      _fetchPlaylistsFromServer();
      _hasFetchedPlaylists = true;
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPlaylistsFromServer() async {
    setState(() {
      _isLoading = true;
    });
    final playlists = await _tcpClient.getUserPlaylists(widget._user);
    setState(() {
      _playlists = playlists;
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

    final newPlaylist = Playlist(
      name: name,
      description: description,
    );

    final response = await _tcpClient.uploadPlaylist(widget._user, newPlaylist);

    if (response['status'] == 'uploadPlaylistSuccess') {
      _nameController.clear();
      _descriptionController.clear();
      await _fetchPlaylistsFromServer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to create playlist')),
      );
    }
  }

  Future<void> _showCreatePlaylistDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            const Icon(
              Icons.playlist_add,
              size: 48,
              color: Colors.purple,
            ),
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
                    borderSide: BorderSide(color: Colors.purple[200]!,width: 1.4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.purple,width: 1.6),
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
                    borderSide: BorderSide(color: Colors.purple[200]!,width: 1.4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.purple,width: 1.6),
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            child: const Text('Cancel'),
          ),
          SizedBox(width: 10,),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Create',
                style: TextStyle(fontSize: 16),
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
            color: Colors.purple[200],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPlaylists,
              color: Colors.purple,
              backgroundColor: Colors.grey[900],
              strokeWidth: 3,
              child: _playlists.isEmpty
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
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
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
                        return ListTile(
                          leading: const Icon(Icons.playlist_play),
                          title: Text(playlist.name),
                          subtitle: Text(
                            playlist.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text('${playlist.tracks.length} tracks'),
                          onTap: () {
                            // TODO: Navigate to playlist details page
                          },
                        );
                      },
                    ),
            ),
    );
  }
}