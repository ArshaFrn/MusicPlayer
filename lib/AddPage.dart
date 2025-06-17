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
            Text(
              "Add Music",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "User: ${widget._user.fullname}",
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 72, 9, 145),
              Color.fromARGB(255, 123, 31, 162),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _handlePickMusicFile,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 36, // Bigger icon
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                style: TextStyle(fontSize: 16, color: Colors.white),
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