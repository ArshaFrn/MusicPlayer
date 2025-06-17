import 'package:flutter/material.dart';
import 'Model/User.dart';

class PlaylistsPage extends StatefulWidget {
  final User _user;

  const PlaylistsPage({super.key, required User user}) : _user = user;

  @override
  State<PlaylistsPage> createState() => _PlaylistsPage();
}

class _PlaylistsPage extends State<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Playlists for ${widget._user.username}",
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}