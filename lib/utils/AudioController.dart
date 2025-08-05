import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:async';
import '../Model/Music.dart';
import '../Model/User.dart';
import '../Application.dart';

class AudioController {
  static final AudioController _instance =
      AudioController._privateConstructor();

  AudioController._privateConstructor();

  static AudioController get instance => _instance;

  AudioPlayer? _audioPlayer;
  Music? _currentTrack;
  User? _currentUser;
  List<Music>? _playlist;
  int _currentTrackIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Stream controllers for UI updates
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Music?> _currentTrackController =
      StreamController<Music?>.broadcast();

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  Music? get currentTrack => _currentTrack;
  User? get currentUser => _currentUser;
  List<Music>? get playlist => _playlist;
  int get currentTrackIndex => _currentTrackIndex;

  // Streams
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<Music?> get currentTrackStream => _currentTrackController.stream;

  Future<void> initializeAudioPlayer() async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();

      // Set up listeners
      _audioPlayer!.positionStream.listen((position) {
        _position = position;
        _positionController.add(position);
      });

      _audioPlayer!.durationStream.listen((duration) {
        if (duration != null) {
          _duration = duration;
          _durationController.add(duration);
        }
      });

      _audioPlayer!.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        _isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        _isPlayingController.add(_isPlaying);

        // Auto-advance to next track when current track completes
        if (state.processingState == ProcessingState.completed) {
          _autoAdvanceToNext();
        }
      });
    }
  }

  Future<void> playTrack(
    Music track,
    User user, {
    List<Music>? playlist,
  }) async {
    try {
      await initializeAudioPlayer();

      _currentTrack = track;
      _currentUser = user;
      _playlist = playlist ?? user.tracks;

      // Find current track index
      if (_playlist != null) {
        _currentTrackIndex = _playlist!.indexWhere((t) => t.id == track.id);
        if (_currentTrackIndex == -1) _currentTrackIndex = 0;
      }

      _currentTrackController.add(_currentTrack);

      // Get cached file path
      final cacheManager = Application.instance.cacheManager;
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        user,
        track,
      );

      if (cachedPath != null && File(cachedPath).existsSync()) {
        await _audioPlayer!.setFilePath(cachedPath);
        await _audioPlayer!.play();
      } else {
        // Download and cache the track
        final bool downloadSuccess = await cacheManager.downloadAndCacheMusic(
          user: user,
          music: track,
        );

        if (downloadSuccess) {
          final String? newCachedPath = await cacheManager.getCachedMusicPath(
            user,
            track,
          );
          if (newCachedPath != null && File(newCachedPath).existsSync()) {
            await _audioPlayer!.setFilePath(newCachedPath);
            await _audioPlayer!.play();
          }
        }
      }
    } catch (e) {
      print('Error playing track: $e');
    }
  }

  void playPause() {
    if (_isPlaying) {
      _audioPlayer?.pause();
    } else {
      _audioPlayer?.play();
    }
  }

  void nextTrack() async {
    if (_playlist == null || _playlist!.isEmpty || _playlist!.length <= 1)
      return;

    await _audioPlayer?.pause();

    _currentTrackIndex = (_currentTrackIndex + 1) % _playlist!.length;
    await playTrack(_playlist![_currentTrackIndex], _currentUser!);
  }

  void previousTrack() async {
    if (_playlist == null || _playlist!.isEmpty || _playlist!.length <= 1)
      return;

    await _audioPlayer?.pause();

    _currentTrackIndex =
        (_currentTrackIndex - 1 + _playlist!.length) % _playlist!.length;
    await playTrack(_playlist![_currentTrackIndex], _currentUser!);
  }

  void _autoAdvanceToNext() async {
    if (_playlist == null || _playlist!.isEmpty || _playlist!.length <= 1)
      return;

    _currentTrackIndex = (_currentTrackIndex + 1) % _playlist!.length;
    await playTrack(_playlist![_currentTrackIndex], _currentUser!);
  }

  void seekTo(Duration position) {
    _audioPlayer?.seek(position);
  }

  void stop() {
    _audioPlayer?.stop();
    _isPlaying = false;
    _isPlayingController.add(false);
  }

  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _currentTrack = null;
    _currentUser = null;
    _playlist = null;
    _currentTrackIndex = 0;
    _isPlaying = false;
    _isLoading = false;
    _position = Duration.zero;
    _duration = Duration.zero;

    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _currentTrackController.close();
  }
}
