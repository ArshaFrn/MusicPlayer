import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Model/Music.dart';
import 'Application.dart';
import 'TcpClient.dart';
import 'utils/AudioController.dart';
import 'PlayPage.dart';

class SearchPage extends StatefulWidget {
  final User _user;

  const SearchPage({super.key, required User user}) : _user = user;

  @override
  State<SearchPage> createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  final Application application = Application.instance;
  String _searchQuery = '';
  List<Music> _searchResults = [];

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _searchResults =
      value.isEmpty ? [] : application.searchTracks(widget._user, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by title, artist, or album...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: Colors.white, fontSize: 17),
                  onChanged: _onSearchChanged,
                ),
              ),
              Icon(Icons.search, color: Colors.white70),
              SizedBox(width: 10),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Container(
        color: Colors.black.withOpacity(0.13),
        child:
        _searchQuery.isEmpty
            ? Center(
          child: Text(
            'Start typing to search your library.',
            style: TextStyle(
              fontSize: 20,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        )
            : _searchResults.isEmpty
            ? Center(
          child: Text(
            'No results found.',
            style: TextStyle(
              fontSize: 20,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        )
            : ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final music = _searchResults[index];
            final isLiked = music.isLiked;
            return ListTile(
              onTap: () => _onTrackTap(context, music),
              onLongPress: () => _onTrackLongPress(context, music),
              leading: Icon(Icons.music_note),
              title: Text(music.title),
              subtitle: Text(
                '${music.artist.name} • ${music.album.title}',
              ),
              trailing: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder:
                    (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: GestureDetector(
                  key: ValueKey<bool>(isLiked),
                  onTap: () => _onLikeTap(music),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: application.getUniqueColor(music.id),
                    size: 25,
                  ),
                ),
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
        user: widget._user,
        music: music,
      );
      if (!success) {
        print("Error Playing The Song");
      }
    } else if (result == 'delete') {
      await application.deleteMusic(
        context: context,
        user: widget._user,
        music: music,
      );
      setState(() {}); //Refresh UI
    } else if (result == 'details') {
      application.showMusicDetailsDialog(context, music);
    }
  }

  Future<void> _onLikeTap(Music music) async {
    final success = await application.toggleLike(widget._user, music);
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
              user: widget._user,
              playlist: widget._user.tracks,
            ),
          ),
        );
        return;
      }

      // Handle music playback logic
      final success = await application.handleMusicPlayback(
        context: context,
        user: widget._user,
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
