import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../Model/Music.dart';
import '../Model/User.dart';
import '../utils/CacheManager.dart';
import 'dart:io';

class AudioController {
  static final AudioController _instance =
      AudioController._privateConstructor();

  static AudioController get instance => _instance;

  AudioPlayer? _audioPlayer;
  Music? _currentTrack;
  User? _currentUser;
  List<Music> _playlist = [];
  int _currentTrackIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Callbacks for UI updates
  final List<VoidCallback> _onStateChangedListeners = [];
  final List<VoidCallback> _onTrackChangedListeners = [];

  AudioController._privateConstructor() {
    _audioPlayer = AudioPlayer();
    _setupAudioPlayerListeners();
  }

  // Set up audio player listeners
  void _setupAudioPlayerListeners() {
    _audioPlayer!.positionStream.listen((position) {
      _position = position;
      _notifyStateChanged();
    });

    _audioPlayer!.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        _notifyStateChanged();
      }
    });

    _audioPlayer!.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      _notifyStateChanged();

      // Listen for song completion
      if (state.processingState == ProcessingState.completed) {
        _autoAdvanceToNext();
      }
    });
  }

  // Notify all state changed listeners
  void _notifyStateChanged() {
    for (final listener in _onStateChangedListeners) {
      listener();
    }
  }

  // Notify all track changed listeners
  void _notifyTrackChanged() {
    for (final listener in _onTrackChangedListeners) {
      listener();
    }
  }

  // Initialize the audio controller with a track and playlist
  Future<void> initialize({
    required Music currentTrack,
    required User user,
    List<Music>? playlist,
    int? currentTrackIndex,
  }) async {
    _currentTrack = currentTrack;
    _currentUser = user;
    _playlist = playlist ?? user.tracks;

    if (_playlist.isEmpty) {
      _playlist = [currentTrack];
    }

    _currentTrackIndex =
        currentTrackIndex ??
        _playlist.indexWhere((track) => track.id == currentTrack.id);

    if (_currentTrackIndex == -1) _currentTrackIndex = 0;

    // Trigger initial state change
    // We don't immediately notify listeners to avoid calling setState during build
    // The listeners will be notified when the track is loaded and played

    // Load and play the current track
    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Getters for UI
  Music? get currentTrack => _currentTrack;

  User? get currentUser => _currentUser;

  bool get isPlaying => _isPlaying;

  bool get isLoading => _isLoading;

  Duration get position => _position;

  Duration get duration => _duration;

  bool get hasTrack => _currentTrack != null;

  List<Music> get playlist => _playlist;

  int get currentTrackIndex => _currentTrackIndex;

  // Add listeners for UI updates
  void addOnStateChangedListener(VoidCallback listener) {
    _onStateChangedListeners.add(listener);
  }

  void removeOnStateChangedListener(VoidCallback listener) {
    _onStateChangedListeners.remove(listener);
  }

  void addOnTrackChangedListener(VoidCallback listener) {
    _onTrackChangedListeners.add(listener);
  }

  void removeOnTrackChangedListener(VoidCallback listener) {
    _onTrackChangedListeners.remove(listener);
  }

  // Play/Pause functionality
  void playPause() {
    if (_isPlaying) {
      _audioPlayer?.pause();
    } else {
      _audioPlayer?.play();
    }
  }

  // Next track
  void nextTrack() async {
    if (_playlist.isEmpty || _playlist.length <= 1) return;

    await _audioPlayer?.pause();

    _currentTrackIndex =
        (_currentTrackIndex - 1 + _playlist.length) % _playlist.length;

    // Update current track immediately for UI
    _currentTrack = _playlist[_currentTrackIndex];
    // Defer notification to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyTrackChanged();
    });

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Previous track
  void previousTrack() async {
    if (_playlist.isEmpty || _playlist.length <= 1) return;

    await _audioPlayer?.pause();
    _currentTrackIndex = (_currentTrackIndex + 1) % _playlist.length;

    // Update current track immediately for UI
    _currentTrack = _playlist[_currentTrackIndex];
    // Defer notification to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyTrackChanged();
    });

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Auto advance to next track
  void _autoAdvanceToNext() async {
    if (_playlist.isEmpty || _playlist.length <= 1) return;

    _currentTrackIndex =
        (_currentTrackIndex - 1 + _playlist.length) % _playlist.length;

    // Update current track immediately for UI
    _currentTrack = _playlist[_currentTrackIndex];
    // Defer notification to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyTrackChanged();
    });

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Load and play track
  Future<void> _loadAndPlayTrack(Music track) async {
    try {
      _isLoading = true;
      // Defer notification to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyStateChanged();
      });

      final cacheManager = CacheManager.instance;
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        _currentUser!,
        track,
      );

      if (cachedPath != null && File(cachedPath).existsSync()) {
        await _audioPlayer!.setFilePath(cachedPath);
        await _audioPlayer!.play();
        // Only update track if it hasn't been set already
        if (_currentTrack?.id != track.id) {
          _currentTrack = track;
          // Defer notification to avoid calling setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _notifyTrackChanged();
          });
        }
      } else {
        // Download track
        final bool downloadSuccess = await cacheManager.downloadAndCacheMusic(
          user: _currentUser!,
          music: track,
        );

        if (downloadSuccess) {
          final String? newCachedPath = await cacheManager.getCachedMusicPath(
            _currentUser!,
            track,
          );

          if (newCachedPath != null && File(newCachedPath).existsSync()) {
            await _audioPlayer!.setFilePath(newCachedPath);
            await _audioPlayer!.play();
            // Only update track if it hasn't been set already
            if (_currentTrack?.id != track.id) {
              _currentTrack = track;
              // Defer notification to avoid calling setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _notifyTrackChanged();
              });
            }
          }
        } else {
          _isPlaying = false;
        }
      }

      _isLoading = false;
      // Defer notification to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyStateChanged();
      });
    } catch (e) {
      print('Error loading track in audio controller: $e');
      _isPlaying = false;
      _isLoading = false;
      // Defer notification to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyStateChanged();
      });
    }
  }

  // Seek to position
  void seekTo(Duration position) {
    _audioPlayer?.seek(position);
  }

  // Dispose
  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _currentTrack = null;
    _currentUser = null;
    _playlist.clear();
    _onStateChangedListeners.clear();
    _onTrackChangedListeners.clear();
  }

  // Format duration
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
