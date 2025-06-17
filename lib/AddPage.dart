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
              onPressed: () async {
                final file = await application.pickMusicFile();
                if (file != null) {
                  final music = await application.buildMusicObject(application, file);
                  if (music != null) {
                    setState(() {
                      widget._user.tracks.add(music);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Added: ${music.title}")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to create music object.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("No file selected.")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
