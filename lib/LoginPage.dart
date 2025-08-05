import 'package:flutter/material.dart';
import 'package:second/Developer.dart';
import 'package:second/Response.dart';
import 'Model/User.dart';
import 'package:second/TcpClient.dart';
import 'SignUpPage.dart';
import 'HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key, required this.title, this.openForgotPassword = false});

  final String title;
  final bool openForgotPassword;

  @override
  State<LogInPage> createState() => _LogInPage();
}

class _LogInPage extends State<LogInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String _currentStep = 'login'; // 'login', 'email', 'code', 'newPassword'
  String _resetEmail = '';
  String _resetUsername = '';

  bool isUsernameValid(String username) {
    // ! Username must be at least 8 characters long
    if (username.length < 8) {
      return false;
    }
    // ! Username should not contain spaces
    if (username.contains(' ')) {
      return false;
    }
    // ! Username should only contain alphanumeric characters and underLine
    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return validUsernameRegex.hasMatch(username);
  }

  bool isPasswordValid(String password, String username) {
    // ! Password must be at least 8 characters long
    if (password.length < 8) {
      return false;
    }
    // ! Password should not contain the username
    if (username.isNotEmpty && password.contains(username)) {
      return false;
    }
    // ! Password must contain at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return false;
    }
    // ! Password must contain at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return false;
    }
    // ! Password must contain at least one digit
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return false;
    }
    return true;
  }

  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _showForgotPasswordDialog() {
    setState(() {
      _currentStep = 'email';
      _emailController.clear();
    });
  }

  Future<void> _requestResetCode() async {
    if (!isEmailValid(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a valid email address", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.forgetPasswordRequest(_emailController.text);

      if (response['status'] == 'resetCodeSent' || response['status'] == 'success') {
        setState(() {
          _resetEmail = _emailController.text;
          _currentStep = 'code';
          _resetCodeController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reset code sent to your email!", style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF8456FF),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      } else if (response['status'] == 'userNotFound') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No user found with this email address", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Failed to send reset code", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyResetCode() async {
    if (_resetCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter the reset code", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.verifyResetCode(_resetEmail, _resetCodeController.text);

      if (response['status'] == 'resetCodeVerified' || response['status'] == 'success') {
        setState(() {
          _currentStep = 'newPassword';
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Code verified! Enter your new password", style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF8456FF),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      } else if (response['status'] == 'resetCodeInvalid') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid or expired reset code", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Failed to verify code", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
      return;
    }

    if (!isPasswordValid(_newPasswordController.text, '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password must be at least 8 characters with uppercase, lowercase, and number", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.updatePasswordWithReset(_resetUsername, _newPasswordController.text, _resetEmail);

      if (response['status'] == 'passwordUpdateSuccess' || response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Password updated successfully! You can now log in", style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF8456FF),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
        
        // Reset to login screen
        setState(() {
          _currentStep = 'login';
          _emailController.clear();
          _resetCodeController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Failed to update password", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _backToLogin() {
    setState(() {
      _currentStep = 'login';
      _emailController.clear();
      _resetCodeController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  bool isLogInValid(BuildContext context) {
    List<String> errors = [];

    String username = _usernameController.text;
    String password = _passwordController.text;

    // ! Validate Username
    if (username.isEmpty) {
      errors.add("Username is required.");
    } else if (!isUsernameValid(username)) {
      errors.add("Invalid username.");
    }

    // ! Validate Password
    if (password.isEmpty) {
      errors.add("Password is required.");
    } else if (!isPasswordValid(password, username)) {
      errors.add("Invalid password.");
    }

    // ! Show errors in a snack-bar
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errors.join("\n"),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.red.withValues(alpha: 0.65),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        ),
      );
      return false;
    }
    return true;
  }

  void logInProcess(BuildContext context) async {
    if (_usernameController.text == Developer.username &&
        _passwordController.text == Developer.password) {
      print("Developer mode activated!");
      Developer.logIn(context);
      return;
    }

    try {
      print("Processing login...");

      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);

      final username = _usernameController.text;
      final password = _passwordController.text;

      final response = await tcpClient.logIn(username, password);

      if (response['status'] == "logInSuccess") {
        print("Login successful!");

        final username = response['username'] ?? '';
        final email = response['email'] ?? '';
        final fullname = response['fullname'] ?? '';
        final registrationDate =
            response['registrationDate'] ?? DateTime.now().toString();
        final profileImageUrl = response['profileImageUrl'] ?? '';

        User user = User(
          username: username,
          email: email,
          fullname: fullname,
          password: password,
          registrationDate: DateTime.parse(registrationDate),
        );
        user.setProfileImageUrl(profileImageUrl);

        print(user.toString());

        // ! Save user data in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', user.username);
        await prefs.setString('email', user.email);
        await prefs.setString('fullname', user.fullname);
        await prefs.setString('password', user.password);
        await prefs.setString(
          'registrationDate',
          user.registrationDate.toIso8601String(),
        );
        await prefs.setString('profileImageUrl', user.profileImageUrl ?? '');

        print("User logged in: ${user.username}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login successful!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (response['status'] == "incorrectPassword") {
        print('Incorrect password!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Incorrect password or username!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      } else if (response['status'] == "userNotFound") {
        print('User not found!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Incorrect password or username!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      } else {
        print("Login failed: ${response['message'] ?? 'Unknown error'}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? "Login failed!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.withOpacity(0.65),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
          ),
        );
      }
    } catch (e) {
      print("An error occurred during login: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "An error occurred: $e",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.withOpacity(0.65),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.only(left: 20, right: 20, bottom: 35),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Check if we should open forgot password directly
    if (widget.openForgotPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showForgotPasswordDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/LogInBG.jpg', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFFF5AF7),
                            Color(0xFF8456FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        'Hertz',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(
                              blurRadius: 24,
                              color: Color(0xFFFF5AF7),
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 48,
                              color: Color(0xFF8456FF),
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 2,
                              color: Colors.white,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      width: 350,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFF8456FF),
                                    Color(0xFFB388FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                _currentStep == 'login' ? 'LOG IN' :
                                _currentStep == 'email' ? 'FORGOT PASSWORD' :
                                _currentStep == 'code' ? 'ENTER CODE' :
                                'NEW PASSWORD',
                                style: TextStyle(
                                  fontSize: _currentStep == 'login' ? 40 : 32,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 15,
                                      color: Color(0xFF8456FF),
                                      offset: Offset(1, 3),
                                    ),
                                    Shadow(
                                      blurRadius: 15,
                                      color: Color(0xFFB388FF),
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 35),
                            if (_currentStep == 'login') ...[
                              TextField(
                                controller: _usernameController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                  ),
                                  hintText: 'Username',
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                      width: 1.3,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF8456FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Colors.white70,
                                  ),
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                      width: 1.3,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF8456FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Color(0xFFD644FF),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _isLoading ? null : () {
                                  if (isLogInValid(context)) {
                                    logInProcess(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF671BAF),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 15,
                                              color: Color(0xFF8456FF),
                                              offset: Offset(1, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              SizedBox(height: 25),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Not registered on Hertz yet?",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SignUpPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: Color(0xFFD644FF),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (_currentStep == 'email') ...[
                              Text(
                                "Enter your email address to receive a reset code",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _emailController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Colors.white70,
                                  ),
                                  hintText: 'Email Address',
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                      width: 1.3,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF8456FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _backToLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.withOpacity(0.3),
                                        foregroundColor: Colors.white,
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
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _requestResetCode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF671BAF),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('Send Code'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (_currentStep == 'code') ...[
                              Text(
                                "Enter the reset code sent to $_resetEmail",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _resetCodeController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.security,
                                    color: Colors.white70,
                                  ),
                                  hintText: 'Reset Code',
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                      width: 1.3,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF8456FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _backToLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.withOpacity(0.3),
                                        foregroundColor: Colors.white,
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
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _verifyResetCode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF671BAF),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('Verify'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (_currentStep == 'newPassword') ...[
                              Text(
                                "Enter your new password",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _newPasswordController,
                                obscureText: true,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Colors.white70,
                                  ),
                                  hintText: 'New Password',
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                      width: 1.3,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF8456FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Colors.white70,
                                  ),
                                  hintText: 'Confirm Password',
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                      width: 1.3,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF8456FF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _backToLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.withOpacity(0.3),
                                        foregroundColor: Colors.white,
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
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _updatePassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF671BAF),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('Update'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 