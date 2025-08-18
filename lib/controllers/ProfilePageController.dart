import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../Model/User.dart';
import '../TcpClient.dart';
import '../main.dart';
import '../ChangePasswordPage.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePageController {
  final User user;
  final TextEditingController emailController;
  final TextEditingController fullnameController;
  final ImagePicker picker;
  
  bool isLoading = false;
  bool isLoadingProfile = true;

  ProfilePageController({
    required this.user,
    required this.emailController,
    required this.fullnameController,
  }) : picker = ImagePicker() {
    emailController.text = user.email;
    fullnameController.text = user.fullname;
  }

  /// Check if profile image is cached locally
  Future<bool> isProfileImageCached() async {
    try {
      if (user.profileImageUrl == null ||
          user.profileImageUrl!.isEmpty) {
        return false;
      }

      final File imageFile = File(user.profileImageUrl!);
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
  Future<String> getProfileImageCachePath() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String profileDir = path.join(appDir.path, 'profile_images');

    // Create directory if it doesn't exist
    final Directory dir = Directory(profileDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return path.join(profileDir, '${user.username}_profile.jpg');
  }

  /// Validate if a cached profile image is valid
  Future<bool> isValidCachedImage(String imagePath) async {
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
  Future<void> clearProfileImageCache() async {
    try {
      final String cachePath = await getProfileImageCachePath();
      final File cacheFile = File(cachePath);

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        print('Profile image cache cleared: $cachePath');
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profileImageUrl');

      // Clear user object
      user.setProfileImageUrl('');
    } catch (e) {
      print('Error clearing profile image cache: $e');
    }
  }

  /// Load profile image with smart caching
  Future<void> loadProfileImage() async {
    try {
      // First, check if we have a cached profile image
      bool isCached = await isProfileImageCached();

      if (isCached) {
        print('Profile image found in cache, using local version');
        isLoadingProfile = false;
        return; // Use existing cached image
      }

      // If not cached, try to load from SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final String? cachedPath = prefs.getString('profileImageUrl');

      if (cachedPath != null && cachedPath.isNotEmpty) {
        // Validate the cached image
        bool isValid = await isValidCachedImage(cachedPath);
        if (isValid) {
          print(
            'Profile image found in SharedPreferences, using cached version',
          );
          user.setProfileImageUrl(cachedPath);
          isLoadingProfile = false;
          return; // Use existing cached image
        } else {
          print('Cached profile image is invalid, clearing cache');
          await clearProfileImageCache();
        }
      }

      // If no valid cached image found, fetch from server
      print('No cached profile image found, fetching from server...');
      await loadProfileFromBackend();
    } catch (e) {
      print('Error loading profile image: $e');
      isLoadingProfile = false;
    }
  }

  Future<void> loadProfileFromBackend() async {
    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.getUserProfile(user.username);

      if (response['status'] == 'getProfileImageSuccess' ||
          response['status'] == 'success') {
        final profileImageBase64 = response['Payload'] ?? '';

        print(
          'Profile image response received. Base64 length: ${profileImageBase64.length}',
        );

        if (profileImageBase64.isNotEmpty) {
          // Decode base64 image and save locally
          await saveProfileImageFromBase64(profileImageBase64);
        } else {
          print('Empty profile image data received');
          // Clear any existing profile image
          user.setProfileImageUrl('');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profileImageUrl', '');
        }
      } else if (response['status'] == 'profileImageNotFound') {
        print('No profile image found for user: ${user.username}');
        // No profile image found, clear any existing image
        user.setProfileImageUrl('');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', '');
      } else {
        print('Error loading profile image: ${response['message']}');
      }
    } catch (e) {
      print('Error loading profile from backend: $e');
    } finally {
      isLoadingProfile = false;
    }
  }

  Future<void> saveProfileImageFromBase64(String base64Image) async {
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
      final String imagePath = await getProfileImageCachePath();
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Update user and SharedPreferences
      user.setProfileImageUrl(imagePath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImageUrl', imagePath);

      print('Profile image saved successfully to: $imagePath');
    } catch (e) {
      print('Error saving profile image: $e');
      // Don't throw the error, just log it and continue
    }
  }

  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Only set isLoggedIn to false, keep other credentials for fingerprint login
    await prefs.setBool('isLoggedIn', false);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LogInPage(title: 'Hertz')),
      );
    }
  }

  void contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'MusicAppShayan@gmail.com',
      query: 'subject=Music App Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw Exception('Could not open email app');
    }
  }

  /// Force refresh profile image from server
  Future<void> refreshProfileFromServer() async {
    try {
      isLoadingProfile = true;

      // Clear existing cache first
      await clearProfileImageCache();

      // Fetch fresh data from server
      await loadProfileFromBackend();
    } catch (e) {
      print('Error refreshing profile: $e');
      throw e;
    } finally {
      isLoadingProfile = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        isLoading = true;

        // Upload image to backend
        final tcpClient = TcpClient(
          serverAddress: '10.0.2.2',
          serverPort: 12345,
        );
        final response = await tcpClient.uploadProfileImage(
          user.username,
          image.path,
        );

        if (response['status'] == 'profileImageUploadSuccess' ||
            response['status'] == 'success') {
          // Clear existing cache to force fresh download
          await clearProfileImageCache();

          // Fetch the updated profile image from server
          await loadProfileFromBackend();

          isLoading = false;
        } else {
          isLoading = false;
          throw Exception(response['message'] ?? "Failed to upload profile picture");
        }
      }
    } catch (e) {
      isLoading = false;
      throw e;
    }
  }

  bool isValidEmail(String email) {
    // Email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> updateUserInfo() async {
    try {
      // Validate email format
      if (!isValidEmail(emailController.text)) {
        throw Exception("Please enter a valid email address");
      }

      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);

      // Check if any changes were made
      bool hasChanges = false;
      Map<String, dynamic> updateData = {};

      if (emailController.text != user.email) {
        updateData['email'] = emailController.text;
        hasChanges = true;
      }

      if (fullnameController.text != user.fullname) {
        updateData['fullName'] = fullnameController.text;
        hasChanges = true;
      }

      if (!hasChanges) {
        throw Exception("No changes to update");
      }

      final response = await tcpClient.updateUserInfo(
        user.username,
        fullName: updateData['fullName'],
        email: updateData['email'],
      );

      if (response['status'] == 'success' ||
          response['status'] == 'userInfoUpdateSuccess') {
        // Update local user object only after successful backend response
        if (updateData.containsKey('email')) {
          user.email = updateData['email'];
        }
        if (updateData.containsKey('fullName')) {
          user.fullname = updateData['fullName'];
        }

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (updateData.containsKey('email')) {
          await prefs.setString('email', updateData['email']);
        }
        if (updateData.containsKey('fullName')) {
          await prefs.setString('fullname', updateData['fullName']);
        }
      } else if (response['status'] == 'emailAlreadyExists' ||
          response['status'] == 'duplicateEmail') {
        // Handle duplicate email error
        throw Exception("Email already exists. Please use a different email address.");
      } else {
        throw Exception(response['message'] ?? 'Update failed');
      }
    } catch (e) {
      throw e;
    }
  }

  void dispose() {
    // Clean up controllers if needed
  }
}
