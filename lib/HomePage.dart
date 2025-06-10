import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:second/User.dart';
import 'package:second/TcpClient.dart';
import 'SignUpPage.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int _selectedIndex = 0;
  late User _currentUser;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _pages = [
      Center(
        child: Text("Library", style: TextStyle(fontSize: 24)),
      ),
      Center(
        child: Text("Playlists", style: TextStyle(fontSize: 24)),
      ),
      Center(
        child: Text("Search", style: TextStyle(fontSize: 24)),
      ), 
      Center(
        child: Icon(Icons.add_circle, size: 60, color: Colors.deepPurple),
      ), 
      Center(
        child: Builder(
          builder:
              (context) => ElevatedButton(
                onPressed: () async {
                  _logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: Text("Log out"),
              ),
        ),
      ),
    ];
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // ! Retrieve user data
    final username = prefs.getString('username') ?? 'Unknown';
    final email = prefs.getString('email') ?? 'Unknown';
    final fullname = prefs.getString('fullname') ?? 'Unknown';
    final password = prefs.getString('password') ?? '';
    final registrationDateString = prefs.getString('registrationDate') ?? '';
    final profileImageUrl = prefs.getString('profileImageUrl') ?? '';
    final registrationDate =
        registrationDateString.isNotEmpty
            ? DateTime.parse(registrationDateString)
            : DateTime.now();

    setState(() {
      _currentUser = User(
        username: username,
        email: email,
        fullname: fullname,
        password: password,
        registrationDate: registrationDate,
      );
      _currentUser.setProfileImageUrl(profileImageUrl ?? '');
    });

    print("User loaded: ${_currentUser.username}");
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LogInPage(title: 'Hertz')),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _pages[_selectedIndex],
    bottomNavigationBar: BottomNavigationBar(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white60,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.shifting,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music),
          label: "Library",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.playlist_play),
          label: "Playlists",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: "Search",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          label: "Add",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    ),
  );
}
}
