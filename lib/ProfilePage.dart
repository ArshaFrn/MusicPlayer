import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:second/main.dart';
import 'User.dart';

class ProfilePage extends StatefulWidget {
  final User _user;
  const ProfilePage({super.key, required User user}) : _user = user;

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LogInPage(title: 'Hertz')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text("Log out"),
          ),
        ],
      ),
    );
  }
}
