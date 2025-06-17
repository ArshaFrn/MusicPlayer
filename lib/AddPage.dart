import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'Application.dart';

class AddPage extends StatefulWidget {
  final User _user;
  const AddPage({super.key, required User user}) : _user = user;

  @override
  State<AddPage> createState() => _AddPage();
}

class _AddPage extends State<AddPage> {
  final Application application = Application.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Add Music"),
            Text("User: ${widget._user.fullname}"),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Pick Music File"),
              onPressed: _handlePickMusicFile,
            ),
          ],
        ),
      ),
    );
  }

Future<void> _handlePickMusicFile() async {
  final file = await application.pickMusicFile();
  if (file != null) {
    final music = await application.buildMusicObject(file);
    if (music != null) {
      if (widget._user.tracks.any((track) => track.id == music.id)) {
        _showSnackBar(
          context,
          "Track '${music.title}' already exists in your library.",
          Icons.warning,
          Colors.orange,
        );
        return;
      }

      // Add the track if it doesn't exist
      setState(() {
        widget._user.tracks.add(music);
      });
      _showSnackBar(
        context,
        "Added: ${music.title}",
        Icons.check_circle,
        Colors.green,
      );
    } else {
      _showSnackBar(
        context,
        "Failed to create music object.",
        Icons.error,
        Colors.red,
      );
    }
  } else {
    _showSnackBar(
      context,
      "No file selected.",
      Icons.warning,
      Colors.orange,
    );
  }
}

  void _showSnackBar(BuildContext context, String message, IconData icon, Color iconColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16,color: Colors.white),
              ),
            ),
          ],
        ),
      backgroundColor: Color.fromARGB(255, 60, 5, 122),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(14),
      ),
    );
  }
}