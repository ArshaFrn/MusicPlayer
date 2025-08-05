import 'package:flutter/material.dart';
import '../utils/MiniAudioController.dart';
import '../Application.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final MiniAudioController _miniController = MiniAudioController.instance;
  final Application _application = Application.instance;

  @override
  void initState() {
    super.initState();
    _miniController.setCallbacks(
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      onTrackChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    // Force a rebuild after a short delay to ensure the mini player shows up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _miniController.hasTrack) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show if there's a track playing
    if (!_miniController.hasTrack) {
      return SizedBox.shrink();
    }

    final currentTrack = _miniController.currentTrack!;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: Colors.purple.shade800, width: 0.7),
          bottom: BorderSide(color: Colors.purple.shade800, width: 0.7),
          left: BorderSide(color: Colors.purple.shade800, width: 0.7),
          right: BorderSide(color: Colors.purple.shade800, width: 0.7),
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
              size: 24,
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
                  fontSize: 14,
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
                _miniController.playlist.length > 1
                    ? _miniController.previousTrack
                    : null,
            icon: Icon(
              Icons.skip_previous,
              color:
                  _miniController.playlist.length > 1
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
                _miniController.isLoading ? null : _miniController.playPause,
            icon:
                _miniController.isLoading
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
                      _miniController.isPlaying
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
                _miniController.playlist.length > 1
                    ? _miniController.nextTrack
                    : null,
            icon: Icon(
              Icons.skip_next,
              color:
                  _miniController.playlist.length > 1
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
    );
  }
}
