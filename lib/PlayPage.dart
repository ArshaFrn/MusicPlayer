import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';

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
  AudioPlayer? _audioPlayer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _albumArtPath;
  Uint8List? _albumArtBytes;
  int _currentTrackIndex = 0;
  List<Music> _playlist = [];
  int? _lastExtractedTrackId;

  @override
  void initState() {
    super.initState();
    _initializePlayback();
  }

  Future<void> _initializePlayback() async {
    try {
      // Initialize playlist
      _playlist = widget.playlist ?? widget.user.tracks;
      if (_playlist.isEmpty) {
        _playlist = [widget.music];
      }
      _currentTrackIndex = _playlist.indexWhere(
        (track) => track.id == widget.music.id,
      );
      if (_currentTrackIndex == -1) _currentTrackIndex = 0;

      // Initialize audio player
      _audioPlayer = AudioPlayer();

      // Set up audio player listeners
      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer!.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading =
                state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;
          });
        }
      });

      // Load and play the current track
      await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
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

  Future<void> _loadAndPlayTrack(Music track) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get cached file path
      final cacheManager = application.cacheManager;
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        widget.user,
        track,
      );

      if (cachedPath != null && File(cachedPath).existsSync()) {
        // Extract album art immediately when we have the file path
        await _extractAlbumArt();

        await _audioPlayer!.setFilePath(cachedPath);
        await _audioPlayer!.play();
      } else {
        throw Exception('Track not found in cache');
      }
    } catch (e) {
      print('Error loading track: $e');
      rethrow;
    }
  }

  Future<void> _extractAlbumArt() async {
    try {
      final currentTrackId = _playlist[_currentTrackIndex].id;

      // Don't re-extract if we already have album art for this track
      if (_lastExtractedTrackId == currentTrackId && _albumArtBytes != null) {
        print('Album art already exists for track: $currentTrackId');
        return;
      }

      final cacheManager = application.cacheManager;
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        widget.user,
        _playlist[_currentTrackIndex],
      );

      if (cachedPath != null && File(cachedPath).existsSync()) {
        // Extract album art from the audio file metadata
        final metadata = await readMetadata(File(cachedPath), getImage: true);

        if (metadata.pictures.isNotEmpty) {
          // Get the first picture (usually the album art)
          final picture = metadata.pictures.first;
          final imageData = picture.bytes;

          if (imageData != null && imageData.isNotEmpty) {
            setState(() {
              _albumArtBytes = imageData;
              _albumArtPath = null; // Clear file path since we're using bytes
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
        _lastExtractedTrackId = _playlist[_currentTrackIndex].id;
      });
    }
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer?.pause();
    } else {
      _audioPlayer?.play();
    }
  }

  void _seekTo(Duration position) {
    _audioPlayer?.seek(position);
  }

  void _nextTrack() {
    // TODO: Implement proper next track logic
  }

  void _previousTrack() {
    // TODO: Implement proper previous track logic
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();

    // Clean up album art bytes
    _albumArtBytes = null;
    _albumArtPath = null;
    _lastExtractedTrackId = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack =
        _playlist.isNotEmpty ? _playlist[_currentTrackIndex] : widget.music;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
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
              // App Bar
              _buildAppBar(),

              SizedBox(height: 30),

              // Album Art
              _buildAlbumArt(currentTrack),

              SizedBox(height: 37),

              // Track Info
              _buildTrackInfo(currentTrack),

              SizedBox(height: 40),

              // Progress Bar
              _buildProgressBar(),

              SizedBox(height: 50),

              // Control Buttons
              _buildControlButtons(),
            ],
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 30,
            ),
          ),
          Expanded(
            child: Text(
              'Now Playing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Add more options
            },
            icon: Icon(Icons.more_vert, color: Colors.white, size: 30),
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

  Widget _buildTrackInfo(Music track) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Text(
            track.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 5),
          Text(
            track.artist.name,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Progress Bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Color(0xFF8B008B),
              inactiveTrackColor: Colors.white24,
              thumbColor: Color(0xFF4B0082),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 4,
            ),
            child: Slider(
              value:
                  _duration.inMilliseconds > 0
                      ? _position.inMilliseconds.toDouble()
                      : 0.0,
              max: _duration.inMilliseconds.toDouble(),
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
                  _formatDuration(_position),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(
                    0xFF4B0082,
                  ).withOpacity(_playlist.length > 1 ? 0.4 : 0.15),
                  Color(
                    0xFF8B008B,
                  ).withOpacity(_playlist.length > 1 ? 0.4 : 0.15),
                ],
              ),
            ),
            child: IconButton(
              onPressed: _playlist.length > 1 ? _previousTrack : null,
              icon: Icon(
                Icons.skip_previous,
                color: _playlist.length > 1 ? Colors.white : Colors.white38,
                size: 35,
              ),
            ),
          ),

          // Play/Pause Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8B008B), Color(0xFF4B0082)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B008B).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _playPause,
              icon:
                  _isLoading
                      ? SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 45,
                      ),
            ),
          ),

          // Next Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(
                    0xFF4B0082,
                  ).withOpacity(_playlist.length > 1 ? 0.4 : 0.15),
                  Color(
                    0xFF8B008B,
                  ).withOpacity(_playlist.length > 1 ? 0.4 : 0.15),
                ],
              ),
            ),
            child: IconButton(
              onPressed: _playlist.length > 1 ? _nextTrack : null,
              icon: Icon(
                Icons.skip_next,
                color: _playlist.length > 1 ? Colors.white : Colors.white38,
                size: 35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
