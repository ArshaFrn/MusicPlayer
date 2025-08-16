import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    try {
      // Clean artist name and title for URL
      final artistName = Uri.encodeComponent(widget.music.artist.name.trim());
      final songTitle = Uri.encodeComponent(widget.music.title.trim());
      
      // Construct the API URL
      final apiUrl = 'https://api.lyrics.ovh/v1/$artistName/$songTitle';
      
      print('Fetching lyrics from: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if lyrics field exists and is not empty
        if (data['lyrics'] != null && data['lyrics'].toString().isNotEmpty) {
          String lyrics = data['lyrics'].toString();
          
          // Clean up the lyrics - remove extra whitespace and format
          lyrics = lyrics.trim();
          
          // Replace common HTML-like entities
          lyrics = lyrics.replaceAll('&amp;', '&');
          lyrics = lyrics.replaceAll('&lt;', '<');
          lyrics = lyrics.replaceAll('&gt;', '>');
          lyrics = lyrics.replaceAll('&quot;', '"');
          lyrics = lyrics.replaceAll('&#39;', "'");
          
          return lyrics;
        }
      } else if (response.statusCode == 404) {
        // Handle 404 response with error message
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            print('Lyrics API error: ${errorData['error']}');
          }
        } catch (e) {
          print('Error parsing 404 response: $e');
        }
        print('Lyrics not found for ${widget.music.title} by ${widget.music.artist.name}');
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching lyrics from API: $e');
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
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
                  colors: themeProvider.isDarkMode 
                    ? [Color(0xFF1A1A1A), Color(0xFF0D0D0D), Colors.black]
                    : [Colors.white, Color(0xFFf8f9fa), Color(0xFFf1f3f4)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // App Bar with navigation arrows
                    _buildAppBar(themeProvider),
                    
                    SizedBox(height: 30),
                    
                    // Lyrics content
                    Expanded(
                      child: _buildLyricsContent(themeProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ThemeProvider themeProvider) {
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
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              size: 30,
            ),
          ),
          
          Expanded(
            child: Text(
              'Lyrics',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
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
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(ThemeProvider themeProvider) {
    if (_isLoadingLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997),
            ),
            SizedBox(height: 20),
            Text(
              "Loading lyrics...",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87, 
                fontSize: 16
              ),
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
              color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              "Lyrics not available",
              style: TextStyle(
                fontSize: 18,
                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "We couldn't find lyrics for this song",
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchLyrics,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997),
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
                color: themeProvider.isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: (themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997)).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.music.title,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.music.artist.name,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.music.album?.name != null) ...[
                    SizedBox(height: 4),
                    Text(
                      widget.music.album!.name,
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white60 : Colors.black45,
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
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
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
