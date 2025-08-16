import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Model/User.dart';
import 'TcpClient.dart';
import 'SignUpPage.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LibraryPage.dart';
import 'PlaylistsPage.dart';
import 'SearchPage.dart';
import 'AddPage.dart';
import 'ProfilePage.dart';
import 'widgets/MiniPlayer.dart';
import 'FavouritesPage.dart';
import 'RecentlyPlayedPage.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final registrationDate =
        registrationDateString.isNotEmpty
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
        LibraryPage(user: _user, onNavigateToPage: navigateToPage),
        PlaylistsPage(user: _user, onNavigateToPage: navigateToPage),
        AddPage(user: _user, onNavigateToPage: navigateToPage),
        ProfilePage(user: _user, onNavigateToPage: navigateToPage),
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

  // Method to navigate to specific pages while keeping navigation bar
  void navigateToPage(int pageIndex) {
    setState(() {
      _selectedIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

          return Scaffold(
        body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(),

          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return BottomNavigationBar(
                selectedItemColor: themeProvider.isDarkMode ? Colors.white : Colors.white,
                unselectedItemColor: themeProvider.isDarkMode ? Colors.white60 : Colors.white60,
                backgroundColor: themeProvider.isDarkMode ? Colors.black : Color(0xFFfc6997),
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.shifting,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_music),
                    label: "Library",
                    backgroundColor: themeProvider.isDarkMode ? Colors.black : Color(0xFFfc6997),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.playlist_play),
                    label: "Playlists",
                    backgroundColor: themeProvider.isDarkMode ? Colors.black : Color(0xFFfc6997),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle),
                    label: "Add",
                    backgroundColor: themeProvider.isDarkMode ? Colors.black : Color(0xFFfc6997),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile",
                    backgroundColor: themeProvider.isDarkMode ? Colors.black : Color(0xFFfc6997),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
