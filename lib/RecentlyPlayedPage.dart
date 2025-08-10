import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';
import 'TcpClient.dart';

class RecentlyPlayedPage extends StatefulWidget {
  final User user;

  const RecentlyPlayedPage({super.key, required this.user});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  final Application application = Application.instance;
  bool _isLoading = true;
  List<Music> _recentlyPlayedTracks = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentlyPlayedTracks();
  }

  Future<void> _fetchRecentlyPlayedTracks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);

      // Get recently played music objects from server
      final recentlyPlayedMusic = await tcpClient.getRecentlyPlayedSongs(
        widget.user.username,
      );

      // Create a map to maintain order and remove duplicates
      final Map<int, Music> uniqueTracks = {};
      for (final music in recentlyPlayedMusic) {
        uniqueTracks[music.id] = music;
      }

      // Convert back to list maintaining order (newer first)
      final orderedTracks = uniqueTracks.values.toList();

      setState(() {
        _recentlyPlayedTracks = orderedTracks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching recently played tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.white, size: 24),
            const SizedBox(width: 5),
            const Text(
              "Recently Played",
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.1,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchRecentlyPlayedTracks,
                child:
                    _recentlyPlayedTracks.isEmpty
                        ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Text(
                                  "No recently played tracks :(\nStart listening to some music!",
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
                          itemCount: _recentlyPlayedTracks.length,
                          itemBuilder: (context, index) {
                            final music = _recentlyPlayedTracks[index];
                            final isLiked = music.isLiked;
                            return ListTile(
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

  Future<void> _onLikeTap(Music music) async {
    final success = await application.toggleLike(widget.user, music);
    if (success) {
      // Refresh the list to show the updated state
      _fetchRecentlyPlayedTracks();
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
                  leading: Icon(Icons.share, color: Colors.green),
                  title: Text('Share'),
                  onTap: () => Navigator.pop(context, 'share'),
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
    } else if (result == 'share') {
      await application.shareMusic(
        context: context,
        user: widget.user,
        music: music,
      );
    } else if (result == 'details') {
      application.showMusicDetailsDialog(context, music);
    }
  }
}
