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
  bool _isEditingEmail = false;
  bool _isEditingFullname = false;
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

  Future<void> _updateUserInfo(String field, String value) async {
    try {
      final tcpClient = TcpClient(serverAddress: '192.168.1.34', serverPort: 12345);
      Map<String, dynamic> response;
      if (field == 'email') {
        response = await tcpClient.updateUserInfo(widget.user.username, email: value);
      } else if (field == 'fullname') {
        response = await tcpClient.updateUserInfo(widget.user.username, fullName: value);
      } else {
        throw Exception('Unknown field');
      }
      if (response['status'] == 'success' || response['status'] == 'userInfoUpdateSuccess') {
        if (field == 'email') {
          widget.user.email = value;
        } else if (field == 'fullname') {
          widget.user.fullname = value;
        }
        final prefs = await SharedPreferences.getInstance();
        if (field == 'email') {
          await prefs.setString('email', value);
        } else if (field == 'fullname') {
          await prefs.setString('fullname', value);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$field updated successfully!",
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
      } else {
        throw Exception(response['message'] ?? 'Update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error updating $field: $e",
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
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.width * 0.25,
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
                    bottomLeft: Radius.circular(MediaQuery.of(context).size.width * 0.125),
                    bottomRight: Radius.circular(MediaQuery.of(context).size.width * 0.125),
                  ),
                ),
                child: Text(
                  widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
                      ? "Change photo"
                      : "Add photo",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Username (non-editable)
            Text(
              "Username",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            Text(
              widget.user.username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // Email (editable)
            Text(
              "Email",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            _isEditingEmail
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF8456FF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF8456FF), width: 2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        onPressed: () async {
                          await _updateUserInfo('email', _emailController.text);
                          setState(() {
                            _isEditingEmail = false;
                          });
                        },
                        icon: Icon(Icons.check, color: Color(0xFF8456FF)),
                      ),
                      IconButton(
                        onPressed: () {
                          _emailController.text = widget.user.email;
                          setState(() {
                            _isEditingEmail = false;
                          });
                        },
                        icon: Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.user.email,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditingEmail = true;
                          });
                        },
                        icon: Icon(Icons.edit, color: Color(0xFF8456FF), size: 20),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            
            // Full Name (editable)
            Text(
              "Full Name",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            _isEditingFullname
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fullnameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF8456FF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF8456FF), width: 2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        onPressed: () async {
                          await _updateUserInfo('fullname', _fullnameController.text);
                          setState(() {
                            _isEditingFullname = false;
                          });
                        },
                        icon: Icon(Icons.check, color: Color(0xFF8456FF)),
                      ),
                      IconButton(
                        onPressed: () {
                          _fullnameController.text = widget.user.fullname;
                          setState(() {
                            _isEditingFullname = false;
                          });
                        },
                        icon: Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.user.fullname,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditingFullname = true;
                          });
                        },
                        icon: Icon(Icons.edit, color: Color(0xFF8456FF), size: 20),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSquare(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        height: MediaQuery.of(context).size.width * 0.25,
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
              size: 40,
              color: Color(0xFF8456FF),
            ),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
              SizedBox(height: 30),
              
              // Profile picture and user info
              Row(
                children: [
                  _buildProfilePicture(),
                  _buildUserInfo(),
                ],
              ),
              
              Spacer(),
              
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
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
