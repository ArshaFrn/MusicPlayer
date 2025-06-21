import 'dart:math';

import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';

class LibraryPage extends StatefulWidget {
  final User user;

  const LibraryPage({super.key, required this.user});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final Application application = Application.instance;
  final List<Color> _colorList = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.yellow,
    Colors.brown,
    Colors.cyan,
    Colors.indigo,
    Colors.amber,
    Colors.lime,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.blueGrey,
    Colors.tealAccent,
    Colors.cyanAccent,
  ];

  @override
  Widget build(BuildContext context) {
    var tracks = widget.user.tracks;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.library_music, color: Colors.white, size: 24),
            const SizedBox(width: 5),
            const Text(
              "Library",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            tooltip: "Search",
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            tooltip: "Filter",
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.white70),
            tooltip: "Shuffle",
            onPressed: null,
          ),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.1,
      ),
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
                  final isLiked = music.isLiked;
                  return ListTile(
                    onTap: (){},
                    leading: Icon(Icons.music_note),
                    title: Text(music.title),
                    subtitle: Text(music.artist.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatDuration(music.durationInSeconds),style: TextStyle(fontSize: 11),),
                        SizedBox(width: 15),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 400),
                          transitionBuilder:
                              (child, animation) => ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                          child: GestureDetector(
                            key: ValueKey<bool>(isLiked),
                            onTap: () => _onLikeTap(music),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _getUniqueColor(music.id),
                              size: 25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    iconColor: _getUniqueColor(music.id),
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

  Color _getUniqueColor(int id) {
    return _colorList[id.abs() % _colorList.length];
  }

  void _onLikeTap(Music music) {
    setState(() {
      application.toggleLike(widget.user, music);
    });
  }
}
