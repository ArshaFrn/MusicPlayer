import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Model/Playlist.dart';

class PlaylistsPage extends StatefulWidget {
  final User _user;
  final Playlist? staticPlaylist;

  const PlaylistsPage({super.key, required User user, this.staticPlaylist}) : _user = user;

  @override
  State<PlaylistsPage> createState() => _PlaylistsPage();
}

class _PlaylistsPage extends State<PlaylistsPage> {
  
  @override
  Widget build(BuildContext context) {
    //listview
    return Scaffold(
    );
  }
}