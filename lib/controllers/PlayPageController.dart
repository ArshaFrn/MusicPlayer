import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'dart:io';
import 'dart:typed_data';
import '../Model/Music.dart';
import '../Model/User.dart';
import '../Application.dart';
import '../utils/AudioController.dart';

class PlayPageController {
  final Music music;
  final User user;
  final List<Music>? playlist;
  final Application application;
  final AudioController audioController;
  
  String? albumArtPath;
  Uint8List? albumArtBytes;
  int? lastExtractedTrackId;
  bool isExtractingAlbumArt = false;

  PlayPageController({
    required this.music,
    required this.user,
    this.playlist,
  }) : application = Application.instance,
       audioController = AudioController.instance;

  Future<void> initializePlayback() async {
    try {
      // Set up callbacks for UI updates
      audioController.addOnStateChangedListener(onStateChanged);
      audioController.addOnTrackChangedListener(onTrackChanged);

      // Check if the audio controller is already playing the same song from the same playlist
      if (audioController.hasTrack &&
          audioController.currentTrack!.id == music.id &&
          audioController.playlist == playlist) {
        // The same song from the same playlist is already playing, don't reinitialize
        print(
          'Same song from same playlist is already playing, not reinitializing',
        );
        return;
      }

      // Initialize the audio controller with the new song
      await audioController.initialize(
        currentTrack: music,
        user: user,
        playlist: playlist,
      );
    } catch (e) {
      print('Error initializing playback: $e');
      throw e;
    }
  }

  void onStateChanged() {
    // Extract album art only when the track is first loaded (not during playback)
    if (!audioController.isLoading &&
        audioController.hasTrack &&
        lastExtractedTrackId != audioController.currentTrack?.id) {
      extractAlbumArt();
    }
  }

  void onTrackChanged() {
    // Clear album art when track changes
    albumArtBytes = null;
    albumArtPath = null;
    lastExtractedTrackId = null;
    // Extract album art for the new track
    // We'll extract it when the track is loaded, not immediately
  }

  Future<void> showMoreOptions(BuildContext context) async {
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
      final currentTrack = audioController.currentTrack;
      if (currentTrack != null) {
        await application.shareMusic(
          context: context,
          user: user,
          music: currentTrack,
        );
      }
    } else if (result == 'details') {
      final currentTrack = audioController.currentTrack;
      if (currentTrack != null) {
        application.showMusicDetailsDialog(context, currentTrack);
      }
    }
  }

  Future<void> extractAlbumArt() async {
    // Prevent multiple simultaneous extraction attempts
    if (isExtractingAlbumArt) return;

    try {
      isExtractingAlbumArt = true;

      final currentTrack = audioController.currentTrack;
      if (currentTrack == null) return;

      final currentTrackId = currentTrack.id;

      // Early return if we already have album art for this track
      if (lastExtractedTrackId == currentTrackId && albumArtBytes != null) {
        return;
      }

      final cacheManager = application.cacheManager;
      final String? cachedPath = await cacheManager.getCachedMusicPath(
        user,
        currentTrack,
      );

      if (cachedPath != null && File(cachedPath).existsSync()) {
        final metadata = await readMetadata(File(cachedPath), getImage: true);

        if (metadata.pictures.isNotEmpty) {
          final picture = metadata.pictures.first;
          final imageData = picture.bytes;

          if (imageData != null && imageData.isNotEmpty) {
            albumArtBytes = imageData;
            albumArtPath = null;
            lastExtractedTrackId = currentTrackId;

            print(
              'Album art extracted and stored in memory for track: $currentTrackId',
            );
          }
        } else {
          print('No album art found in metadata');
          albumArtBytes = null;
          albumArtPath = null;
          lastExtractedTrackId = currentTrackId;
        }
      }
    } catch (e) {
      print('Error extracting album art: $e');
      albumArtBytes = null;
      albumArtPath = null;
      lastExtractedTrackId = audioController.currentTrack?.id;
    } finally {
      isExtractingAlbumArt = false;
    }
  }

  void seekTo(Duration position) {
    audioController.seekTo(position);
  }

  String formatDuration(Duration duration) {
    return audioController.formatDuration(duration);
  }

  void dispose() {
    audioController.removeOnStateChangedListener(onStateChanged);
    audioController.removeOnTrackChangedListener(onTrackChanged);

    // Clean up album art bytes
    albumArtBytes = null;
    albumArtPath = null;
    lastExtractedTrackId = null;
    isExtractingAlbumArt = false;
  }
}
