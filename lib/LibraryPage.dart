import 'package:flutter/material.dart';
import 'package:second/Music.dart';
import 'User.dart';

class LibraryPage extends StatefulWidget {
  final User user;

  const LibraryPage({super.key, required this.user});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    var tracks = widget.user.tracks;

    return Scaffold(
      body:
          tracks.isEmpty
              ? Center(
                child: Text(
                  "No tracks available :(\nPlease add some music to your library.",
                  style: TextStyle(
                    fontSize: 19,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    height: 1.9,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final music = tracks[index];
                  return ListTile(
                    leading: Icon(Icons.music_note),
                    title: Text(music.title),
                    subtitle: Text(music.artist.name),
                    trailing: Text(
                      _formatDuration(music.durationInSeconds),
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
