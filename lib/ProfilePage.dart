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
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
    _fullnameController.text = widget.user.fullname;
    _loadProfileImage();
  }

  /// Check if profile image is cached locally
  Future<bool> _isProfileImageCached() async {
    try {
      if (widget.user.profileImageUrl == null ||
          widget.user.profileImageUrl!.isEmpty) {
        return false;
      }

      final File imageFile = File(widget.user.profileImageUrl!);
      if (await imageFile.exists()) {
        final int fileSize = await imageFile.length();
        return fileSize > 0; // Check if file has content
      }
      return false;
    } catch (e) {
      print('Error checking profile image cache: $e');
      return false;
    }
  }

  /// Get the profile image cache path
  Future<String> _getProfileImageCachePath() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String profileDir = path.join(appDir.path, 'profile_images');

    // Create directory if it doesn't exist
    final Directory dir = Directory(profileDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return path.join(profileDir, '${widget.user.username}_profile.jpg');
  }

  /// Validate if a cached profile image is valid
  Future<bool> _isValidCachedImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return false;
      }

      final int fileSize = await imageFile.length();
      if (fileSize == 0) {
        return false;
      }

      // Try to read the file to ensure it's not corrupted
      final List<int> bytes = await imageFile.readAsBytes();
      return bytes.isNotEmpty;
    } catch (e) {
      print('Error validating cached image: $e');
      return false;
    }
  }

  /// Clear profile image cache
  Future<void> _clearProfileImageCache() async {
    try {
      final String cachePath = await _getProfileImageCachePath();
      final File cacheFile = File(cachePath);

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        print('Profile image cache cleared: $cachePath');
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profileImageUrl');

      // Clear user object
      widget.user.setProfileImageUrl('');

      setState(() {});
    } catch (e) {
      print('Error clearing profile image cache: $e');
    }
  }

  /// Load profile image with smart caching
  Future<void> _loadProfileImage() async {
    try {
      // First, check if we have a cached profile image
      bool isCached = await _isProfileImageCached();

      if (isCached) {
        print('Profile image found in cache, using local version');
        setState(() {
          _isLoadingProfile = false;
        });
        return; // Use existing cached image
      }

      // If not cached, try to load from SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final String? cachedPath = prefs.getString('profileImageUrl');

      if (cachedPath != null && cachedPath.isNotEmpty) {
        // Validate the cached image
        bool isValid = await _isValidCachedImage(cachedPath);
        if (isValid) {
          print(
            'Profile image found in SharedPreferences, using cached version',
          );
          widget.user.setProfileImageUrl(cachedPath);
          setState(() {
            _isLoadingProfile = false;
          });
          return; // Use existing cached image
        } else {
          print('Cached profile image is invalid, clearing cache');
          await _clearProfileImageCache();
        }
      }

      // If no valid cached image found, fetch from server
      print('No cached profile image found, fetching from server...');
      await _loadProfileFromBackend();
    } catch (e) {
      print('Error loading profile image: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadProfileFromBackend() async {
    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.getUserProfile(widget.user.username);

      if (response['status'] == 'getProfileImageSuccess' ||
          response['status'] == 'success') {
        final profileImageBase64 = response['Payload'] ?? '';

        print(
          'Profile image response received. Base64 length: ${profileImageBase64.length}',
        );

        if (profileImageBase64.isNotEmpty) {
          // Decode base64 image and save locally
          await _saveProfileImageFromBase64(profileImageBase64);
        } else {
          print('Empty profile image data received');
          // Clear any existing profile image
          widget.user.setProfileImageUrl('');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profileImageUrl', '');
        }
      } else if (response['status'] == 'profileImageNotFound') {
        print('No profile image found for user: ${widget.user.username}');
        // No profile image found, clear any existing image
        widget.user.setProfileImageUrl('');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', '');
      } else {
        print('Error loading profile image: ${response['message']}');
      }
    } catch (e) {
      print('Error loading profile from backend: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _saveProfileImageFromBase64(String base64Image) async {
    try {
      // Validate base64 string before decoding
      if (base64Image.isEmpty) {
        print('Empty base64 image data received');
        return;
      }

      // Remove any potential whitespace or newlines
      base64Image = base64Image.trim();

      // Check if the base64 string is valid
      if (base64Image.length % 4 != 0) {
        print('Invalid base64 string length: ${base64Image.length}');
        return;
      }

      // Try to decode with error handling
      List<int> imageBytes;
      try {
        imageBytes = base64Decode(base64Image);
      } catch (e) {
        print('Base64 decode error: $e');
        print('Base64 string length: ${base64Image.length}');
        print(
          'Base64 string preview: ${base64Image.substring(0, base64Image.length > 100 ? 100 : base64Image.length)}...',
        );
        return;
      }

      if (imageBytes.isEmpty) {
        print('Decoded image bytes are empty');
        return;
      }

      // Get cache path and save image file
      final String imagePath = await _getProfileImageCachePath();
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Update user and SharedPreferences
      widget.user.setProfileImageUrl(imagePath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImageUrl', imagePath);

      setState(() {});
      print('Profile image saved successfully to: $imagePath');
    } catch (e) {
      print('Error saving profile image: $e');
      // Don't throw the error, just log it and continue
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Only set isLoggedIn to false, keep other credentials for fingerprint login
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LogInPage(title: 'Hertz')),
      );
    }
  }

  void _showMenu() async {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        80,
        0,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'contact_us',
          child: Row(
            children: [
              Icon(
                Icons.email, 
                color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997), 
                size: 20
              ),
              SizedBox(width: 8),
              Text(
                'Contact Us',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'refresh_profile',
          child: Row(
            children: [
              Icon(
                Icons.refresh, 
                color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997), 
                size: 20
              ),
              SizedBox(width: 8),
              Text(
                'Refresh Profile',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_password',
          child: Row(
            children: [
              Icon(
                Icons.lock, 
                color: themeProvider.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997), 
                size: 20
              ),
              SizedBox(width: 8),
              Text(
                'Change Password',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Log out',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (selected == 'logout') {
      _logout();
    } else if (selected == 'change_password') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangePasswordPage(user: widget.user),
        ),
      );
    } else if (selected == 'refresh_profile') {
      _refreshProfileFromServer();
    } else if (selected == 'contact_us') {
      _contactUs();
    }
  }

  void _contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'MusicAppShayan@gmail.com',
      query: 'subject=Music App Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
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

  /// Force refresh profile image from server
  Future<void> _refreshProfileFromServer() async {
    try {
      setState(() {
        _isLoadingProfile = true;
      });

      // Clear existing cache first
      await _clearProfileImageCache();

      // Fetch fresh data from server
      await _loadProfileFromBackend();

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
      print('Error refreshing profile: $e');
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
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
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

        // Upload image to backend
        final tcpClient = TcpClient(
          serverAddress: '10.0.2.2',
          serverPort: 12345,
        );
        final response = await tcpClient.uploadProfileImage(
          widget.user.username,
          image.path,
        );

        if (response['status'] == 'profileImageUploadSuccess' ||
            response['status'] == 'success') {
          // Clear existing cache to force fresh download
          await _clearProfileImageCache();

          // Fetch the updated profile image from server
          await _loadProfileFromBackend();

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
              margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? "Failed to upload profile picture",
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    // Email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Widget _buildProfilePicture() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: _pickImage,
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
            if (_isLoading)
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
      // Validate email format
      if (!_isValidEmail(_emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please enter a valid email address",
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
        return;
      }

      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);

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
            content: Text(
              "No changes to update",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange.withOpacity(0.7),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
          ),
        );
        return;
      }

      final response = await tcpClient.updateUserInfo(
        widget.user.username,
        fullName: updateData['fullName'],
        email: updateData['email'],
      );

      if (response['status'] == 'success' ||
          response['status'] == 'userInfoUpdateSuccess') {
        // Update local user object only after successful backend response
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
      } else if (response['status'] == 'emailAlreadyExists' ||
          response['status'] == 'duplicateEmail') {
        // Handle duplicate email error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Email already exists. Please use a different email address.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
          ),
        );
        // Reset email field to original value
        _emailController.text = widget.user.email;
      } else {
        throw Exception(response['message'] ?? 'Update failed');
      }
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
    
    if (_isLoadingProfile) {
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
                    IconButton(
                      onPressed: _showMenu,
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
