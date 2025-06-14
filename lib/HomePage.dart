import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'User.dart';
import 'TcpClient.dart';
import 'SignUpPage.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LibraryPage.dart';
import 'PlaylistsPage.dart';
import 'SearchPage.dart';
import 'AddPage.dart';
import 'ProfilePage.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int _selectedIndex = 0;
  late User _user;
  late List<Widget> _pages;
  bool _isUserLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    final registrationDate = registrationDateString.isNotEmpty
        ? DateTime.parse(registrationDateString)
        : DateTime.now();

    setState(() {
      _user = User(
        username: username,
        email: email,
        fullname: fullname,
        password: password,
        registrationDate: registrationDate,
      );
      _user.setProfileImageUrl(profileImageUrl);

      _pages = [
        LibraryPage(user: _user),
        PlaylistsPage(user: _user),
        SearchPage(user: _user),
        AddPage(user: _user),
        ProfilePage(user: _user),
      ];
      _isUserLoaded = true;
    });

    print("User loaded: ${_user.username}");
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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