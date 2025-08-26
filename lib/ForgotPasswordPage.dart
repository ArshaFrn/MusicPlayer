import 'package:flutter/material.dart';
import 'package:second/TcpClient.dart';
import 'main.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'utils/SnackBarUtils.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String _currentStep = 'email'; // 'email', 'code', 'newPassword'
  String _resetEmail = '';
  String _resetUsername = ''; // To store the username after code verification

  // --- Validation Methods ---
  bool isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    return true;
  }

  bool isEmailValid(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // --- UI Action Methods ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      SnackBarUtils.showErrorSnackBar(context, message);
    } else {
      SnackBarUtils.showInfoSnackBar(context, message);
    }
  }

  Future<void> _requestResetCode() async {
    if (!isEmailValid(_emailController.text)) {
      _showSnackBar("Please enter a valid email address", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tcpClient = TcpClient(serverAddress: '192.168.43.173', serverPort: 12345);
      final response = await tcpClient.forgetPasswordRequest(
        _emailController.text,
      );

      if (response['status'] == 'resetCodeSent' ||
          response['status'] == 'success') {
        setState(() {
          _resetEmail = _emailController.text;
          _currentStep = 'code';
        });
        _showSnackBar("Reset code sent to your email!");
      } else {
        _showSnackBar(
          response['message'] ?? "Failed to send reset code",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyResetCode() async {
    if (_resetCodeController.text.isEmpty) {
      _showSnackBar("Please enter the reset code", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tcpClient = TcpClient(serverAddress: '192.168.43.173', serverPort: 12345);
      final response = await tcpClient.verifyResetCode(
        _resetEmail,
        _resetCodeController.text,
      );

      if (response['status'] == 'resetCodeVerified' ||
          response['status'] == 'success') {
        setState(() {
          // NOTE: Assuming the server returns the username upon successful code verification.
          _resetUsername = response['username'] ?? '';
          _currentStep = 'newPassword';
        });
        _showSnackBar("Code verified! Enter your new password");
      } else {
        _showSnackBar(
          response['message'] ?? "Invalid or expired reset code",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }
    if (!isPasswordValid(_newPasswordController.text)) {
      _showSnackBar(
        "Password must be 8+ chars with uppercase, lowercase, and a number.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tcpClient = TcpClient(serverAddress: '192.168.43.173', serverPort: 12345);
      final response = await tcpClient.updatePasswordWithReset(
        _resetUsername,
        _newPasswordController.text,
        _resetEmail,
      );

      if (response['status'] == 'passwordUpdateSuccess' ||
          response['status'] == 'success') {
        _showSnackBar("Password updated successfully! You can now log in.");
        // Navigate back to the login page on success
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LogInPage(title: "Hertz")),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        _showSnackBar(
          response['message'] ?? "Failed to update password",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        final isDark = theme.isDarkMode;
        final primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);
        final backgroundColor = isDark ? Colors.black : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final labelColor = isDark ? Colors.white70 : Colors.black54;

        // This helper builds the main action button for each step
        Widget buildActionButton(String text, VoidCallback onPressed) {
          return ElevatedButton(
            onPressed: _isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(text),
          );
        }

        // This helper builds the text fields
        Widget buildTextField(
          TextEditingController controller,
          String hintText,
          IconData icon, {
          bool isPassword = false,
        }) {
          return TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: labelColor),
              hintText: hintText,
              hintStyle: TextStyle(color: labelColor),
              filled: true,
              fillColor:
                  isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
              contentPadding: EdgeInsets.symmetric(vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  width: 1.3,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child:
                    isDark
                        ? Image.asset(
                          'assets/images/LogInBG.jpg',
                          fit: BoxFit.cover,
                        )
                        : Container(color: Colors.grey[50]),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Container(
                      width: 350,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- Header Text ---
                          Text(
                            _currentStep == 'email'
                                ? 'FORGOT PASSWORD'
                                : _currentStep == 'code'
                                ? 'ENTER CODE'
                                : 'NEW PASSWORD',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  blurRadius: 15,
                                  color: primaryColor.withOpacity(0.3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          Text(
                            _currentStep == 'email'
                                ? 'Enter your email to receive a reset code.'
                                : _currentStep == 'code'
                                ? 'Enter the code sent to $_resetEmail.'
                                : 'Enter your new password.',
                            style: TextStyle(color: labelColor, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30),

                          // --- Dynamic Form Content ---
                          if (_currentStep == 'email')
                            buildTextField(
                              _emailController,
                              'Email Address',
                              Icons.email,
                            )
                          else if (_currentStep == 'code')
                            buildTextField(
                              _resetCodeController,
                              'Reset Code',
                              Icons.security,
                            )
                          else ...[
                            buildTextField(
                              _newPasswordController,
                              'New Password',
                              Icons.lock,
                              isPassword: true,
                            ),
                            SizedBox(height: 20),
                            buildTextField(
                              _confirmPasswordController,
                              'Confirm Password',
                              Icons.lock,
                              isPassword: true,
                            ),
                          ],
                          SizedBox(height: 30),

                          // --- Action Buttons ---
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  // Always go back
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isDark
                                            ? Colors.grey.withOpacity(0.3)
                                            : Colors.grey.shade300,
                                    foregroundColor:
                                        isDark ? Colors.white : Colors.black87,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text('Back'),
                                ),
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child:
                                    _currentStep == 'email'
                                        ? buildActionButton(
                                          'Send Code',
                                          _requestResetCode,
                                        )
                                        : _currentStep == 'code'
                                        ? buildActionButton(
                                          'Verify',
                                          _verifyResetCode,
                                        )
                                        : buildActionButton(
                                          'Update',
                                          _updatePassword,
                                        ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
