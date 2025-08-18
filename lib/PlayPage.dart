import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';
import 'utils/AudioController.dart';

import 'utils/ThemeProvider.dart';
import 'package:provider/provider.dart';

class PlayPage extends StatefulWidget {
  final Music music;
  final User user;
  final List<Music>? playlist;

  const PlayPage({
    super.key,
    required this.music,
    required this.user,
    this.playlist,
  });

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  final Application application = Application.instance;
  final AudioController _audioController = AudioController.instance;
  String? _albumArtPath;
  Uint8List? _albumArtBytes;
  int? _lastExtractedTrackId;
  bool _isExtractingAlbumArt = false;

  @override
  void initState() {
    super.initState();
    _initializePlayback();
  }

  Future<void> _initializePlayback() async {
    try {
      // Set up callbacks for UI updates
      _audioController.addOnStateChangedListener(_onStateChanged);
      _audioController.addOnTrackChangedListener(_onTrackChanged);

      // Check if the audio controller is already playing the same song from the same playlist
      if (_audioController.hasTrack &&
          _audioController.currentTrack!.id == widget.music.id &&
          _audioController.playlist == widget.playlist) {
        // The same song from the same playlist is already playing, don't reinitialize
        print(
          'Same song from same playlist is already playing, not reinitializing',
        );
        return;
      }

      // Initialize the audio controller with the new song
      await _audioController.initialize(
        currentTrack: widget.music,
        user: widget.user,
        playlist: widget.playlist,
      );
    } catch (e) {
      print('Error initializing playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading track: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioController.removeOnStateChangedListener(_onStateChanged);
    _audioController.removeOnTrackChangedListener(_onTrackChanged);

    // Clean up album art bytes
    _albumArtBytes = null;
    _albumArtPath = null;
    _lastExtractedTrackId = null;
    _isExtractingAlbumArt = false;

    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});

      // Extract album art only when the track is first loaded (not during playback)
      if (!_audioController.isLoading &&
          _audioController.hasTrack &&
          _lastExtractedTrackId != _audioController.currentTrack?.id) {
        _extractAlbumArt();
      }
    }
  }

  void _onTrackChanged() {
    if (mounted) {
      setState(() {
        // Clear album art when track changes
        _albumArtBytes = null;
        _albumArtPath = null;
        _lastExtractedTrackId = null;
      });
      // Extract album art for the new track
      // We'll extract it when the track is loaded, not immediately
    }
  }

  Future<void> _showMoreOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey.shade900.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.share, color: Colors.green),
                  title: Text('Share', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue),
                  title: Text(
                    'Track Details',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, 'details'),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
    );

    if (result == 'share') {
      final currentTrack = _audioController.currentTrack;
      if (currentTrack != null) {
        await application.shareMusic(
          context: context,
          user: widget.user,
          music: currentTrack,
        );
      }
    } else if (result == 'details') {
      final currentTrack = _audioController.currentTrack;
      if (currentTrack != null) {
        application.showMusicDetailsDialog(context, currentTrack);
      }
    }
  }

  Future<void> _extractAlbumArt() async {
    // Prevent multiple simultaneous extraction attempts
    if (_isExtractingAlbumArt) return;

    try {
      _isExtractingAlbumArt = true;

      final currentTrack = _audioController.currentTrack;
      if (currentTrack == null) return;

      final currentTrackId = currentTrack.id;

      // Early return if we already have album art for this track
      if (_lastExtractedTrackId == currentTrackId && _albumArtBytes != null) {
        return;
      }

      final cacheManager = application.cacheManager;
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        widget.user,
        currentTrack,
      );

      if (cachedPath != null && File(cachedPath).existsSync()) {
        final metadata = await readMetadata(File(cachedPath), getImage: true);

        if (metadata.pictures.isNotEmpty) {
          final picture = metadata.pictures.first;
          final imageData = picture.bytes;

          if (imageData != null && imageData.isNotEmpty) {
            setState(() {
              _albumArtBytes = imageData;
              _albumArtPath = null;
              _lastExtractedTrackId = currentTrackId;
            });

            print(
              'Album art extracted and stored in memory for track: $currentTrackId',
            );
          }
        } else {
          print('No album art found in metadata');
          setState(() {
            _albumArtBytes = null;
            _albumArtPath = null;
            _lastExtractedTrackId = currentTrackId;
          });
        }
      }
    } catch (e) {
      print('Error extracting album art: $e');
      setState(() {
        _albumArtBytes = null;
        _albumArtPath = null;
        _lastExtractedTrackId = _audioController.currentTrack?.id;
      });
    } finally {
      _isExtractingAlbumArt = false;
    }
  }

  void _seekTo(Duration position) {
    _audioController.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    return _audioController.formatDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final currentTrack = _audioController.currentTrack;
        if (currentTrack == null) {
          return Scaffold(
            backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
            body: Center(
              child: Text(
                'No track selected',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onPanUpdate: (details) {
            // Swipe down to minimize
            if (details.delta.dy > 50) {
              Navigator.pop(context);
            }
          },
          child: Scaffold(
            backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
            body: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D), Colors.black],
                      )
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.grey[50]!, Colors.grey[100]!],
                      ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    _buildAppBar(themeProvider),

                    SizedBox(height: 30),

                    // Album Art
                    _buildAlbumArt(currentTrack),

                    SizedBox(height: 37),

                    // Track Info
                    _buildTrackInfo(currentTrack, themeProvider),

                    SizedBox(height: 40),

                    // Progress Bar
                    _buildProgressBar(themeProvider),

                    SizedBox(height: 50),

                    // Control Buttons
                    _buildControlButtons(themeProvider),
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
          // Down arrow to minimize (can also be triggered by swipe down)
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              size: 30,
            ),
          ),
          Expanded(
            child: Text(
              'Now Playing',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildAlbumArt(Music track) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF8B008B).withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Color(0xFF4B0082).withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child:
                _albumArtBytes != null
                    ? Image.memory(
                      _albumArtBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading album art from memory: $error');
                        // Clear the invalid bytes and show default
                        setState(() {
                          _albumArtBytes = null;
                        });
                        return _buildDefaultAlbumArt();
                      },
                    )
                    : _buildDefaultAlbumArt(),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B008B), Color(0xFF4B0082)],
        ),
      ),
      child: Icon(Icons.music_note, color: Colors.white, size: 80),
    );
  }

  Widget _buildTrackInfo(Music track, ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Song title with responsive font size
          LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  track.title,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          SizedBox(height: 5),
          // Artist name with responsive font size
          LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  track.artist.name,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Progress Bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: themeProvider.isDarkMode ? Color(0xFFC300C3) : Color(0xFFfc6997),
              inactiveTrackColor: themeProvider.isDarkMode ? Colors.white24 : Colors.black12,
              thumbColor: themeProvider.isDarkMode ? Color(0xFF6E00B8) : Color(0xFFfc6997),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 4,
            ),
            child: Slider(
              value:
                  _audioController.duration.inMilliseconds > 0
                      ? (_audioController.position.inMilliseconds.toDouble())
                          .clamp(
                            0.0,
                            _audioController.duration.inMilliseconds.toDouble(),
                          )
                      : 0.0,
              max: _audioController.duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),

          // Time Labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_audioController.position),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54, 
                    fontSize: 14
                  ),
                ),
                Text(
                  _formatDuration(_audioController.duration),
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54, 
                    fontSize: 14
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      height: 80, // Fixed height for consistent positioning
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous Button
          Container(
            width: 60, // Fixed width
            height: 60, // Fixed height
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [
                        Color(0xFF4B0082).withOpacity(0.75),
                        Color(0xFF8B008B).withOpacity(0.95),
                      ]
                    : [
                        Color(0xFFfc6997).withOpacity(0.75),
                        Color(0xFFfc6997).withOpacity(0.95),
                      ],
              ),
            ),
            child: IconButton(
              onPressed:
                  _audioController.playlist.length > 1
                      ? _audioController.previousTrack
                      : null,
              icon: Icon(
                Icons.skip_previous,
                color:
                    _audioController.playlist.length > 1
                        ? Colors.white
                        : Colors.white38,
                size: 35,
              ),
            ),
          ),

          // Play/Pause Button
          Container(
            width: 80, // Fixed width
            height: 80, // Fixed height
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [Color(0xFF8B008B), Color(0xFF4B0082)]
                    : [Color(0xFFfc6997), Color(0xFFfc6997)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (themeProvider.isDarkMode ? Color(0xFF8B008B) : Color(0xFFfc6997)).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: IconButton(
              onPressed:
                  _audioController.isLoading
                      ? null
                      : _audioController.playPause,
              icon:
                  _audioController.isLoading
                      ? SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997),
                          ),
                        ),
                      )
                      : Icon(
                        _audioController.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 45,
                      ),
            ),
          ),

          // Next Button
          Container(
            width: 60, // Fixed width
            height: 60, // Fixed height
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [
                        Color(0xFF4B0082).withOpacity(0.75),
                        Color(0xFF8B008B).withOpacity(0.95),
                      ]
                    : [
                        Color(0xFFfc6997).withOpacity(0.75),
                        Color(0xFFfc6997).withOpacity(0.95),
                      ],
              ),
            ),
            child: IconButton(
              onPressed:
                  _audioController.playlist.length > 1
                      ? _audioController.nextTrack
                      : null,
              icon: Icon(
                Icons.skip_next,
                color:
                    _audioController.playlist.length > 1
                        ? Colors.white
                        : Colors.white38,
                size: 35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
