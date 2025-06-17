import 'package:flutter/material.dart';
import 'Model/User.dart';

class SearchPage extends StatefulWidget {
  final User _user;

  const SearchPage({super.key, required User user}) : _user = user;

  @override
  State<SearchPage> createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Search for ${widget._user.username}",
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}