import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';


class FavouritesPage extends StatefulWidget {
  final User user;

  const FavouritesPage({super.key, required this.user});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final Application application = Application.instance;
  bool _isLoading = true;
  List<Music> _favouriteTracks = [];

  @override
  void initState() {
    super.initState();
    _fetchFavouriteTracks();
  }

  Future<void> _fetchFavouriteTracks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, sync the like state with the user's liked songs list
      _syncLikeState();

      // Filter user's tracks to get only liked ones
      final favouriteTracks =
          widget.user.tracks.where((track) => track.isLiked).toList();

      setState(() {
        _favouriteTracks = favouriteTracks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching favourite tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Synchronizes the like state of music tracks with the user's liked songs
  void _syncLikeState() {
    application.syncLikeState(widget.user, widget.user.tracks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 24),
            const SizedBox(width: 5),
            const Text(
              "Favourites",
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
                onRefresh: _fetchFavouriteTracks,
                child:
                    _favouriteTracks.isEmpty
                        ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Text(
                                  "No favourite tracks :(\nLike some songs to see them here!",
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
                          itemCount: _favouriteTracks.length,
                          itemBuilder: (context, index) {
                            final music = _favouriteTracks[index];
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
                                          context: context,
                                        ),
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              iconColor: application.getUniqueColor(music.id, context: context),
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

  Future<void> _onLikeTap(Music music) async {
    final success = await application.toggleLike(widget.user, music);
    if (success) {
      // Refresh the list to show the updated state
      _fetchFavouriteTracks();
    }
  }
}
