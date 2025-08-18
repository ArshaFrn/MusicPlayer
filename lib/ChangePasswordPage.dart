import 'package:flutter/material.dart';
import 'Model/User.dart';
import 'TcpClient.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'utils/SnackBarUtils.dart';

class ChangePasswordPage extends StatefulWidget {
  final User user;
  const ChangePasswordPage({super.key, required this.user});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      SnackBarUtils.showErrorSnackBar(context, 'New passwords do not match!');
      return;
    }
    if (newPassword.length < 8) {
      SnackBarUtils.showErrorSnackBar(context, 'Password must be at least 8 characters.');
      return;
    }
    setState(() { _isLoading = true; });
    final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
    final response = await tcpClient.changePassword(
      widget.user.username,
      oldPassword,
      newPassword,
      isForgotten: false,
    );
    setState(() { _isLoading = false; });
    if (response['status'] == 'passwordUpdateSuccess' || response['status'] == 'success') {
      SnackBarUtils.showSuccessSnackBar(context, 'Password updated successfully!');
      Navigator.pop(context);
    } else {
      SnackBarUtils.showErrorSnackBar(context, response['message'] ?? 'Failed to update password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        final isDark = theme.isDarkMode;
        final primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);
        final backgroundColor = isDark ? Colors.black : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final labelColor = isDark ? Colors.white70 : Colors.black54;
        final fillColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.1);
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Change Password', style: TextStyle(color: textColor)),
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            elevation: 0,
          ),
          backgroundColor: backgroundColor,
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Old Password',
                    labelStyle: TextStyle(color: labelColor),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: labelColor),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: labelColor),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Change Password'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}