import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '/Model/Music.dart';
import '/Model/User.dart';
import '/utils/CacheManager.dart';
import 'dart:io';
import '/TcpClient.dart';

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

  final List<VoidCallback> _onStateChangedListeners = [];
  final List<VoidCallback> _onTrackChangedListeners = [];

  AudioController._privateConstructor() {
    _audioPlayer = AudioPlayer();
    _setupAudioPlayerListeners();
  }

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

      if (state.processingState == ProcessingState.completed) {
        _autoAdvanceToNext();
      }
    });
  }

  void _notifyStateChanged() {
    for (final listener in _onStateChangedListeners) {
      listener();
    }
  }

  void _notifyTrackChanged() {
    for (final listener in _onTrackChangedListeners) {
      listener();
    }
  }

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

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  Music? get currentTrack => _currentTrack;
  User? get currentUser => _currentUser;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasTrack => _currentTrack != null;
  List<Music> get playlist => _playlist;
  int get currentTrackIndex => _currentTrackIndex;

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

  // Play/Pause
  void playPause() {
    if (_isPlaying) {
      _audioPlayer?.pause();
    } else {
      _audioPlayer?.play();
    }
  }

  Future<void> stopAndReset() async {
    try {
      await _audioPlayer?.stop();
    } catch (_) {}
    _isPlaying = false;
    _isLoading = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentTrack = null;
    _currentUser = _currentUser;
    _playlist = [];
    _currentTrackIndex = 0;
    _notifyTrackChanged();
    _notifyStateChanged();
  }

  // Next track
  void nextTrack() async {
    if (_playlist.isEmpty || _playlist.length <= 1) return;

    await _audioPlayer?.pause();

    _currentTrackIndex =
        (_currentTrackIndex - 1 + _playlist.length) % _playlist.length;

    _currentTrack = _playlist[_currentTrackIndex];
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

    _currentTrack = _playlist[_currentTrackIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyTrackChanged();
    });

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  // Auto advanc
  void _autoAdvanceToNext() async {
    if (_playlist.isEmpty || _playlist.length <= 1) return;

    _currentTrackIndex =
        (_currentTrackIndex - 1 + _playlist.length) % _playlist.length;

    _currentTrack = _playlist[_currentTrackIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyTrackChanged();
    });

    await _loadAndPlayTrack(_playlist[_currentTrackIndex]);
  }

  Future<void> _loadAndPlayTrack(Music track) async {
    try {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyStateChanged();
      });

      final tcpClient = TcpClient(serverAddress: "192.168.43.173", serverPort: 12345);
      await tcpClient.updateRecentlyPlayed(currentUser!.username, track.id);
      currentUser!.recentlyPlayed.add(track);

      final cacheManager = CacheManager.instance;
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        _currentUser!,
        track,
      );

      if (cachedPath != null && File(cachedPath).existsSync()) {
        await _audioPlayer!.setFilePath(cachedPath);
        await _audioPlayer!.play();
        if (_currentTrack?.id != track.id) {
          _currentTrack = track;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _notifyTrackChanged();
          });
        }
      } else {
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
            if (_currentTrack?.id != track.id) {
              _currentTrack = track;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyStateChanged();
      });
    } catch (e) {
      print('Error loading track in audio controller: $e');
      _isPlaying = false;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyStateChanged();
      });
    }
  }

  void seekTo(Duration position) {
    _audioPlayer?.seek(position);
  }

  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _currentTrack = null;
    _currentUser = null;
    _playlist.clear();
    _onStateChangedListeners.clear();
    _onTrackChangedListeners.clear();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
