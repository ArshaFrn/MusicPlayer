import 'package:flutter/material.dart';
import 'User.dart';
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
    //User can add music locally or online
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
                  final metaData = await application.extractMetadata(file);
                  final base64Data = await application.readAndEncodeFile(file);
                  if (base64Data != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Picked file: ${file.path}")),
                    );
                    print("metaData : $metaData");
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to encode file.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("No file selected.")));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
