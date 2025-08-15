import 'package:flutter/material.dart';
import '../utils/AudioController.dart';
import '../Application.dart';
import '../PlayPage.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioController _audioController = AudioController.instance;
  final Application _application = Application.instance;

  @override
  void initState() {
    super.initState();
    _audioController.addOnStateChangedListener(_onStateChanged);
    _audioController.addOnTrackChangedListener(_onTrackChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _audioController.hasTrack) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _audioController.removeOnStateChangedListener(_onStateChanged);
    _audioController.removeOnTrackChangedListener(_onTrackChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTrackChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show if there's a track playing
    if (!_audioController.hasTrack) {
      return SizedBox.shrink();
    }

    final currentTrack = _audioController.currentTrack!;
    final playlist = _audioController.playlist;

    return GestureDetector(
      onTap: () {
        // Navigate to PlayPage with the current track
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayPage(
              music: currentTrack,
              user: _audioController.currentUser!,
              playlist: playlist,
            ),
          ),
        );
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          border: Border(
            top: BorderSide(color: Colors.purple.shade800, width: 1),
            bottom: BorderSide(color: Colors.purple.shade800, width: 1),
            left: BorderSide(color: Colors.purple.shade800, width: 1),
            right: BorderSide(color: Colors.purple.shade800, width: 1),
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Row(
          children: [
            // Music Icon
            Container(
              margin: EdgeInsets.only(left: 16),
              child: Icon(
                Icons.music_note,
                color: _application.getUniqueColor(currentTrack.id),
                size: 25,
              ),
            ),

            // Music Name
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  currentTrack.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Previous Button
            IconButton(
              onPressed:
                  playlist.length > 1
                      ? _audioController.previousTrack
                      : null,
              icon: Icon(
                Icons.skip_previous,
                color:
                    playlist.length > 1
                        ? _application.getUniqueColor(currentTrack.id)
                        : Colors.white38,
                size: 28,
              ),
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(),
            ),

            // Play/Pause Button
            IconButton(
              onPressed:
                  _audioController.isLoading ? null : _audioController.playPause,
              icon:
                  _audioController.isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _application.getUniqueColor(currentTrack.id),
                          ),
                        ),
                      )
                      : Icon(
                        _audioController.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: _application.getUniqueColor(currentTrack.id),
                        size: 32,
                      ),
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(),
            ),

            // Next Button
            IconButton(
              onPressed:
                  playlist.length > 1
                      ? _audioController.nextTrack
                      : null,
              icon: Icon(
                Icons.skip_next,
                color:
                    playlist.length > 1
                        ? _application.getUniqueColor(currentTrack.id)
                        : Colors.white38,
                size: 28,
              ),
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(),
            ),

            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
