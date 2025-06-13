import 'package:flutter/material.dart';
import 'User.dart';

class AddPage extends StatefulWidget {
  final User _user;

  const AddPage({super.key, required User user}) : _user = user;

  @override
  State<AddPage> createState() => _AddPage();
}

class _AddPage extends State<AddPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle, size: 60, color: Colors.deepPurple),
          Text(
            "Add something for ${widget._user.username}",
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}