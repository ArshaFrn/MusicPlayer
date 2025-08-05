import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:second/main.dart';
import 'ChangePasswordPage.dart';
import 'Model/User.dart';
import 'TcpClient.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required User user}) : user = user;

  @override
  State<ProfilePage> createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
    _fullnameController.text = widget.user.fullname;
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

  void _showMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width, 80, 0, 0),
      items: [
        PopupMenuItem<String>(
          value: 'change_password',
          child: Text('Change Password'),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Text('Log out'),
        ),
      ],
    );
    if (selected == 'logout') {
      _logout();
    } else if (selected == 'change_password') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChangePasswordPage(user: widget.user)),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Here you would typically upload the image to your server
        // For now, we'll just update the local state
        widget.user.setProfileImageUrl(image.path);
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', image.path);

        setState(() {
          _isLoading = false;
        });

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
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error picking image: $e",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
    }
  }

  Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.22,
        height: MediaQuery.of(context).size.width * 0.22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(0xFF8456FF),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8456FF).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipOval(
              child: widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
                  ? Image.file(
                      File(widget.user.profileImageUrl!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white70,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white70,
                      ),
                    ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8456FF),
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
                    bottomLeft: Radius.circular(MediaQuery.of(context).size.width * 0.11),
                    bottomRight: Radius.circular(MediaQuery.of(context).size.width * 0.11),
                  ),
                ),
                child: Text(
                  widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
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
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.user.username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _emailController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF8456FF), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        SizedBox(height: 15),
        
        // Full Name field
        Text(
          "Full Name",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _fullnameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF8456FF), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
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
              backgroundColor: Color(0xFF8456FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              textStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: Color(0xFF8456FF).withOpacity(0.3),
            ),
            child: Text("Update Information"),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSquare(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.22,
        height: MediaQuery.of(context).size.width * 0.22,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Color(0xFF8456FF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8456FF).withOpacity(0.2),
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
              color: Color(0xFF8456FF),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
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
      final tcpClient = TcpClient(serverAddress: '192.168.1.34', serverPort: 12345);
      
      // Check if any changes were made
      bool hasChanges = false;
      Map<String, dynamic> updateData = {};
      
      if (_emailController.text != widget.user.email) {
        updateData['email'] = _emailController.text;
        hasChanges = true;
      }
      
      if (_fullnameController.text != widget.user.fullname) {
        updateData['fullName'] = _fullnameController.text;
        hasChanges = true;
      }
      
      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No changes to update", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange.withOpacity(0.7),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
        return;
      }
      
      final response = await tcpClient.updateUserInfo(
        widget.user.username,
        fullName: updateData['fullName'],
        email: updateData['email'],
      );
      
      if (response['status'] == 'success' || response['status'] == 'userInfoUpdateSuccess') {
        // Update local user object
        if (updateData.containsKey('email')) {
          widget.user.email = updateData['email'];
        }
        if (updateData.containsKey('fullName')) {
          widget.user.fullname = updateData['fullName'];
        }

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (updateData.containsKey('email')) {
          await prefs.setString('email', updateData['email']);
        }
        if (updateData.containsKey('fullName')) {
          await prefs.setString('fullname', updateData['fullName']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Information updated successfully!", style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF8456FF),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating information: $e", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with logout button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      onPressed: _showMenu,
                      icon: Icon(
                        Icons.more_vert,
                        color: Color(0xFF8456FF),
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
                    _buildActionSquare(
                      "All Songs",
                      Icons.music_note,
                      () {
                        // Navigate to all songs page
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("All Songs feature coming soon!"),
                            backgroundColor: Color(0xFF8456FF),
                          ),
                        );
                      },
                    ),
                    _buildActionSquare(
                      "Favorites",
                      Icons.favorite,
                      () {
                        // Navigate to favorites page
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Favorites feature coming soon!"),
                            backgroundColor: Color(0xFF8456FF),
                          ),
                        );
                      },
                    ),
                    _buildActionSquare(
                      "Recently\nPlayed",
                      Icons.history,
                      () {
                        // Navigate to recently played page
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Recently Played feature coming soon!"),
                            backgroundColor: Color(0xFF8456FF),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
