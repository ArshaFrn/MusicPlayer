import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';
import 'TcpClient.dart';
import 'utils/AudioController.dart';
import 'PlayPage.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'widgets/MiniPlayer.dart';

class RecentlyPlayedPage extends StatefulWidget {
  final User user;
  final VoidCallback? onBackPressed;

  const RecentlyPlayedPage({super.key, required this.user, this.onBackPressed});

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Color(0xFFf8f5f0),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Color(0xFFf8f5f0),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          children: [
            Icon(Icons.history, color: primaryColor, size: 24),
            const SizedBox(width: 5),
            Text(
              "Recently Played",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                fontSize: 24,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
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
                              leading: Icon(
                                Icons.music_note,
                                color: application.getUniqueColor(
                                  music.id,
                                  context: context,
                                ),
                              ),
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
                                          context: context,
                                        ),
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              iconColor: application.getUniqueColor(
                                music.id,
                                context: context,
                              ),
                            );
                          },
                        ),
              ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return BottomNavigationBar(
                selectedItemColor:
                    themeProvider.isDarkMode ? Colors.white : Colors.white,
                unselectedItemColor:
                    themeProvider.isDarkMode ? Colors.white60 : Colors.white60,
                backgroundColor:
                    themeProvider.isDarkMode ? Colors.black : Color(0xFFfc6997),
                currentIndex: 3, // Profile index
                onTap: (index) {
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  }
                },
                type: BottomNavigationBarType.shifting,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_music),
                    label: "Library",
                    backgroundColor:
                        themeProvider.isDarkMode
                            ? Colors.black
                            : Color(0xFFfc6997),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.playlist_play),
                    label: "Playlists",
                    backgroundColor:
                        themeProvider.isDarkMode
                            ? Colors.black
                            : Color(0xFFfc6997),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle),
                    label: "Add",
                    backgroundColor:
                        themeProvider.isDarkMode
                            ? Colors.black
                            : Color(0xFFfc6997),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile",
                    backgroundColor:
                        themeProvider.isDarkMode
                            ? Colors.black
                            : Color(0xFFfc6997),
                  ),
                ],
              );
            },
          ),
        ],
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
    if (result == 'share') {
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
