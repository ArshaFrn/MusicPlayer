import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'utils/AudioController.dart';

class LyricsPage extends StatefulWidget {
  final Music music;
  final User user;
  final List<Music>? playlist;

  const LyricsPage({
    super.key,
    required this.music,
    required this.user,
    this.playlist,
  });

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  String _lyrics = '';
  bool _isLoadingLyrics = true;
  bool _lyricsNotFound = false;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoadingLyrics = true;
      _lyricsNotFound = false;
    });

    try {
      // Try to get lyrics from cache first
      final cachedLyrics = await _getCachedLyrics();
      if (cachedLyrics.isNotEmpty) {
        setState(() {
          _lyrics = cachedLyrics;
          _isLoadingLyrics = false;
        });
        return;
      }

      // If not cached, try to fetch from API
      final lyrics = await _fetchLyricsFromAPI();
      if (lyrics.isNotEmpty) {
        setState(() {
          _lyrics = lyrics;
          _isLoadingLyrics = false;
        });
        // Cache the lyrics
        await _cacheLyrics(lyrics);
      } else {
        setState(() {
          _lyricsNotFound = true;
          _isLoadingLyrics = false;
        });
      }
    } catch (e) {
      print('Error fetching lyrics: $e');
      setState(() {
        _lyricsNotFound = true;
        _isLoadingLyrics = false;
      });
    }
  }

  Future<String> _getCachedLyrics() async {
    // Implementation for getting cached lyrics
    // You can use SharedPreferences or a local database
    return '';
  }

  Future<void> _cacheLyrics(String lyrics) async {
    // Implementation for caching lyrics
    // You can use SharedPreferences or a local database
  }

  Future<String> _fetchLyricsFromAPI() async {
    // For now, return placeholder lyrics
    // In a real implementation, you would integrate with Genius, Musixmatch, or another API
    await Future.delayed(Duration(seconds: 1)); // Simulate API call
    
    return '''
[Verse 1]
This is a placeholder for the lyrics of "${widget.music.title}"
by ${widget.music.artist.name}

[Chorus]
The actual lyrics would be fetched from a lyrics API
such as Genius or Musixmatch

[Verse 2]
This is just sample text to show the layout
of how lyrics would appear on this page

[Bridge]
You can implement the actual lyrics fetching
by integrating with your preferred lyrics API

[Outro]
End of sample lyrics
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: (details) {
          // Swipe left to go back to music player
          if (details.delta.dx < -50) {
            Navigator.pop(context);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D), Colors.black],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar with navigation arrows
                _buildAppBar(),
                
                SizedBox(height: 30),
                
                // Lyrics content
                Expanded(
                  child: _buildLyricsContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Left arrow to go back to music player
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          Expanded(
            child: Text(
              'Lyrics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Right arrow (for future use - could go to next song)
          IconButton(
            onPressed: () {
              // Could implement next song functionality
            },
            icon: Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent() {
    if (_isLoadingLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF8456FF)),
            SizedBox(height: 20),
            Text(
              "Loading lyrics...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_lyricsNotFound) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Colors.grey[600],
            ),
            SizedBox(height: 16),
            Text(
              "Lyrics not available",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "We couldn't find lyrics for this song",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchLyrics,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8456FF),
                foregroundColor: Colors.white,
              ),
              child: Text("Try Again"),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song info header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Color(0xFF8456FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.music.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.music.artist.name,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.music.album?.name != null) ...[
                    SizedBox(height: 4),
                    Text(
                      widget.music.album!.name,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Lyrics text
            Text(
              _lyrics,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
