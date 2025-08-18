import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:second/main.dart';
import 'ChangePasswordPage.dart';
import 'Model/Playlist.dart';
import 'Model/User.dart';
import 'TcpClient.dart';
import 'LibraryPage.dart';
import 'PlaylistsPage.dart';
import 'RecentlyPlayedPage.dart';
import 'FavouritesPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'controllers/ProfilePageController.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final Function(int) onNavigateToPage;

  const ProfilePage({
    super.key, 
    required User user, 
    required this.onNavigateToPage,
  }) : user = user;

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  late ProfilePageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfilePageController(
      user: widget.user,
      emailController: _emailController,
      fullnameController: _fullnameController,
    );
    _controller.loadProfileImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }



  Widget _buildProfilePicture() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: () async {
        try {
          await _controller.pickImage();
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Profile picture updated!",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF8456FF),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error updating profile picture: $e",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.withOpacity(0.65),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            ),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.22,
        height: MediaQuery.of(context).size.width * 0.22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997), 
            width: 3
          ),
          boxShadow: [
            BoxShadow(
              color: (themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997)).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipOval(
              child:
                  widget.user.profileImageUrl != null &&
                          widget.user.profileImageUrl!.isNotEmpty
                      ? Image.file(
                        File(widget.user.profileImageUrl!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 85,
                          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
            ),
            if (_controller.isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997)
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(
                      MediaQuery.of(context).size.width * 0.11,
                    ),
                    bottomRight: Radius.circular(
                      MediaQuery.of(context).size.width * 0.11,
                    ),
                  ),
                ),
                child: Text(
                  widget.user.profileImageUrl != null &&
                          widget.user.profileImageUrl!.isNotEmpty
                      ? "Change photo"
                      : "Add photo",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile picture and username row
        Row(
          children: [
            _buildProfilePicture(),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Username",
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.user.profileImageUrl != null &&
                                  widget.user.profileImageUrl!.isNotEmpty
                              ? widget.user.username
                              : widget.user.username,
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      // Theme toggle button (expanded)
                      Consumer<ThemeProvider>(
                        builder: (context, theme, child) {
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.isDarkMode 
                                      ? Color(0xFF8456FF)
                                      : Color(0xFFfc6997),
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () => theme.toggleTheme(),
                                icon: Icon(
                                  theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                  color: theme.isDarkMode 
                                      ? Color(0xFF8456FF)
                                      : Color(0xFFfc6997),
                                  size: 20,
                                ),
                                tooltip: 'Toggle Theme',
                              ),
                            ),
                          );
                        },
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Email field
        Text(
          "Email",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _emailController,
          style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: themeProvider.isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.isDarkMode ? Colors.white24 : Colors.black12
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997), 
                width: 2
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.isDarkMode ? Colors.white24 : Colors.black12
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        SizedBox(height: 15),

        // Full Name field
        Text(
          "Full Name",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _fullnameController,
          style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: themeProvider.isDarkMode 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.isDarkMode ? Colors.white24 : Colors.black12
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997), 
                width: 2
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.isDarkMode ? Colors.white24 : Colors.black12
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        SizedBox(height: 20),

        // Update Information button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateUserInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: (themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997)).withOpacity(0.3),
            ),
            child: Text("Update Information"),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSquare(String title, IconData icon, VoidCallback onTap) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.22,
        height: MediaQuery.of(context).size.width * 0.22,
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997), 
            width: 2
          ),
          boxShadow: [
            BoxShadow(
              color: (themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997)).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 32, 
              color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997)
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserInfo() async {
    try {
      await _controller.updateUserInfo();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Information updated successfully!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF8456FF),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error updating information: $e",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (_controller.isLoadingProfile) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Color(0xFFf8f5f0),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997)
                ),
                SizedBox(height: 20),
                Text(
                  "Loading profile...",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87, 
                    fontSize: 16
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Color(0xFFf8f5f0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with logo and logout button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              themeProvider.logoPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                                         PopupMenuButton<String>(
                       itemBuilder: (context) => [
                         PopupMenuItem<String>(
                           value: 'contact_us',
                           child: Row(
                             children: [
                               Icon(Icons.email, color: Colors.blue, size: 20),
                               SizedBox(width: 8),
                               Text('Contact Us', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black87)),
                             ],
                           ),
                         ),
                         PopupMenuItem<String>(
                           value: 'refresh_profile',
                           child: Row(
                             children: [
                               Icon(Icons.refresh, color: Colors.green, size: 20),
                               SizedBox(width: 8),
                               Text('Refresh Profile', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black87)),
                             ],
                           ),
                         ),
                         PopupMenuItem<String>(
                           value: 'change_password',
                           child: Row(
                             children: [
                               Icon(Icons.lock, color: Colors.orange, size: 20),
                               SizedBox(width: 8),
                               Text('Change Password', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black87)),
                             ],
                           ),
                         ),
                         PopupMenuItem<String>(
                           value: 'logout',
                           child: Row(
                             children: [
                               Icon(Icons.logout, color: Colors.red, size: 20),
                               SizedBox(width: 8),
                               Text('Log out', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black87)),
                             ],
                           ),
                         ),
                       ],
                      onSelected: (value) async {
                        print('Menu selection: $value'); // Debug print
                        if (value == 'logout') {
                          _controller.logout(context);
                        } else if (value == 'change_password') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordPage(user: widget.user),
                            ),
                          );
                        } else if (value == 'refresh_profile') {
                          try {
                            await _controller.refreshProfileFromServer();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Profile refreshed successfully!",
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Color(0xFF8456FF),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error refreshing profile: $e",
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red.withOpacity(0.65),
                                duration: Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              ),
                            );
                          }
                        } else if (value == 'contact_us') {
                          try {
                            _controller.contactUs();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Could not open email app",
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red.withOpacity(0.65),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        Icons.more_vert,
                        color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997),
                        size: 28,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Profile picture and user info
                _buildUserInfo(),

                SizedBox(height: 40),

                // Action squares
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionSquare("All Songs", Icons.music_note, () {
                      // Navigate to library page with all songs
                      widget.onNavigateToPage(0); // Library page index
                    }),
                    _buildActionSquare("Favorites", Icons.favorite, () {
                      // Navigate to library and show favorites
                      widget.onNavigateToPage(0);
                      // You can add a parameter to show favorites filter
                    }),
                    _buildActionSquare("Recently\nPlayed", Icons.history, () {
                      // Navigate to library and show recently played
                      widget.onNavigateToPage(0);
                      // You can add a parameter to show recently played filter
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
