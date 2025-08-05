import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import '../Model/Music.dart';
import '../Model/User.dart';
import '../Application.dart';
import '../utils/CacheManager.dart';
import 'dart:io';

class MiniAudioController {
  static final MiniAudioController _instance =
      MiniAudioController._privateConstructor();
  static MiniAudioController get instance => _instance;

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
  VoidCallback? onStateChanged;
  VoidCallback? onTrackChanged;

  MiniAudioController._privateConstructor();

  // Initialize the mini player with data from PlayPage
  void initializeFromPlayPage({
    required AudioPlayer audioPlayer,
    required Music currentTrack,
    required User user,
    required List<Music> playlist,
    required int currentTrackIndex,
  }) {
    _audioPlayer = audioPlayer;
    _currentTrack = currentTrack;
    _currentUser = user;
    _playlist = playlist;
    _currentTrackIndex = currentTrackIndex;

    // Trigger initial state change to show mini player immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onStateChanged?.call();
    });

    // Set up listeners
    _audioPlayer!.positionStream.listen((position) {
      _position = position;
      this.onStateChanged?.call();
    });

    _audioPlayer!.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        this.onStateChanged?.call();
      }
    });

    _audioPlayer!.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      this.onStateChanged?.call();
    });

    // Listen for song completion
    _audioPlayer!.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _autoAdvanceToNext();
      }
    });
  }

  // Getters for UI
  Music? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasTrack => _currentTrack != null;
  List<Music> get playlist => _playlist;

  // Set callbacks for UI updates
  void setCallbacks({
    required VoidCallback onStateChanged,
    required VoidCallback onTrackChanged,
  }) {
    this.onStateChanged = onStateChanged;
    this.onTrackChanged = onTrackChanged;
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
    onTrackChanged?.call();

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Previous track
  void previousTrack() async {
    if (_playlist.isEmpty || _playlist.length <= 1) return;

    await _audioPlayer?.pause();
    _currentTrackIndex = (_currentTrackIndex + 1) % _playlist.length;

    // Update current track immediately for UI
    _currentTrack = _playlist[_currentTrackIndex];
    onTrackChanged?.call();

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Auto advance to next track
  void _autoAdvanceToNext() async {
    if (_playlist.isEmpty || _playlist.length <= 1) return;

    _currentTrackIndex =
        (_currentTrackIndex - 1 + _playlist.length) % _playlist.length;

    // Update current track immediately for UI
    _currentTrack = _playlist[_currentTrackIndex];
    onTrackChanged?.call();

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Load and play track
  Future<void> _loadAndPlayTrack(Music track) async {
    try {
      _isLoading = true;
      onStateChanged?.call();

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
          onTrackChanged?.call();
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
              onTrackChanged?.call();
            }
          }
        } else {
          _isPlaying = false;
        }
      }

      _isLoading = false;
      onStateChanged?.call();
    } catch (e) {
      print('Error loading track in mini player: $e');
      _isPlaying = false;
      _isLoading = false;
      onStateChanged?.call();
    }
  }

  // Dispose
  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _currentTrack = null;
    _currentUser = null;
    _playlist.clear();
    onStateChanged = null;
    onTrackChanged = null;
  }

  // Format duration
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
