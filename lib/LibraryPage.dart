import 'package:flutter/material.dart';
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
    return Center(
      child: Text(
        "Welcome to the Library, ${widget.user.username}!",
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}