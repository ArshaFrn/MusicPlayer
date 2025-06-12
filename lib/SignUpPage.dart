import 'package:flutter/material.dart';
import 'package:second/Response.dart';
import 'package:second/User.dart';
import 'package:second/TcpClient.dart';
import 'main.dart';
import 'package:second/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();

  String _passwordErrorText = '';
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });

    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void showPasswordRequirementsSnackBar(BuildContext context) {
    Future.delayed(Duration(milliseconds: 500), () {
      final snackBar = SnackBar(
        content: Text(
          "Password must include:\n- At least 8 characters\n- Uppercase, lowercase, and a digit\n- Should not contain the username",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black54,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        // Allows positioning
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.47,
          left: 10,
          right: 10,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void showUsernameRequirementsSnackBar(BuildContext context) {
    Future.delayed(Duration(milliseconds: 500), () {
      final snackBar = SnackBar(
        content: Text(
          "Username must include:\n- At least 8 characters\n- No spaces\n- Only alphanumeric characters and underscores",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black54,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.455,
          left: 10,
          right: 10,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void passwordErrorController(String errorText) {
    if (errorText.isEmpty) {
      _passwordErrorText = errorText;
    } else {
      _passwordErrorText += "\n$errorText";
    }
  }

  bool isPasswordValid(String password, String username) {
    // ! Password must be at least 8 characters long
    if (password.length < 8) {
      passwordErrorController("Password must be at least 8 characters long");
      return false;
    }
    // ! Password should not contain the username
    if (username.isNotEmpty && password.contains(username)) {
      passwordErrorController("Password should not contain the username");
      return false;
    }
    // ! Password must contain at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      passwordErrorController(
        "Password must contain at least one uppercase letter",
      );
      return false;
    }
    // ! Password must contain at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      passwordErrorController(
        "Password must contain at least one lowercase letter",
      );
      return false;
    }
    // ! Password must contain at least one digit
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      passwordErrorController("Password must contain at least one digit");
      return false;
    }
    return true;
  }

  bool isEmailValid(String email) {
    // ! Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

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

  bool isSignUpValid() {
    List<String> errors = [];

    // ! Validate Full Name
    if (_fullnameController.text.isEmpty) {
      errors.add("Full Name is required.");
    }

    // ! Validate Username
    if (_usernameController.text.isEmpty) {
      errors.add("Username is required.");
    } else if (!isUsernameValid(_usernameController.text)) {
      errors.add("Invalid username.");
    }

    // ! Validate Email
    if (_emailController.text.isEmpty) {
      errors.add("Email is required.");
    } else if (!isEmailValid(_emailController.text)) {
      errors.add("Invalid email address.");
    }

    // ! Validate Password
    if (_passwordController.text.isEmpty) {
      errors.add("Password is required.");
    } else if (!isPasswordValid(
      _passwordController.text,
      _usernameController.text,
    )) {
      errors.add("Invalid password.");
    }

    // ! Show error in a snack-bar
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errors.join("\n"),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.red.withValues(alpha: 0.5),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          margin: EdgeInsets.only(left: 10, right: 10, bottom: 2),
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 7),
        ),
      );
      return false;
    }

    return true;
  }

  void signUpProcess() async {
    try {
      print("Processing sign-up...");

      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);

      final username = _usernameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final fullname = _fullnameController.text;

      final signUpResponse = await tcpClient.signUp(
        fullname,
        username,
        email,
        password,
      );
      if (signUpResponse['status'] == "signUpSuccess") {
        final user = User(
          fullname: fullname,
          username: username,
          email: email,
          password: password,
          registrationDate: DateTime.now(),
        );
        
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

        print("User signed up successfully: ${user.username}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sign-up successful!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (signUpResponse['status'] == "emailAlreadyExist") {
        print("Email already exists!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Email already exists!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.deepOrange.withValues(alpha: 0.75),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
          ),
        );
      } else if (signUpResponse['status'] == "usernameAlreadyExist") {
        print("Username already exists!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Username already exists!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.deepOrange.withValues(alpha: 0.75),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
          ),
        );
      } else {
        print("Sign-up failed: ${signUpResponse['status'] ?? 'Unknown error'}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sign-up failed!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.65),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
          ),
        );
      }
    } catch (e) {
      print("An error occurred during sign-up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "An error occurred: $e",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.withValues(alpha: 0.65),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.only(left: 10, right: 10, bottom: 20),
        ),
      );
    }
  }

  Color getBorderColor(String textFieldName) {
    if (textFieldName == 'Password') {
      if (_passwordController.text.isEmpty) {
        return Colors.white24;
      } else if (isPasswordValid(
        _passwordController.text,
        _usernameController.text,
      )) {
        return Colors.white24;
      } else {
        return Colors.red;
      }
    }
    if (textFieldName == 'Email') {
      if (_emailController.text.isEmpty) {
        return Colors.white24;
      } else if (isEmailValid(_emailController.text)) {
        return Colors.white24;
      } else {
        return Colors.red;
      }
    }
    if (textFieldName == 'Username') {
      if (_usernameController.text.isEmpty) {
        return Colors.white24;
      } else if (isUsernameValid(_usernameController.text)) {
        return Colors.white24;
      } else {
        return Colors.red;
      }
    } else {
      return Colors.white24;
    }
  }

  Color getFocusedBorderColor(String textFieldName) {
    if (textFieldName == 'Password') {
      if (_passwordController.text.isEmpty) {
        return Color(0xFF8456FF);
      } else if (isPasswordValid(
        _passwordController.text,
        _usernameController.text,
      )) {
        return Color(0xFF8456FF);
      } else {
        return Colors.red;
      }
    }
    if (textFieldName == 'Email') {
      if (_emailController.text.isEmpty) {
        return Color(0xFF8456FF);
      } else if (isEmailValid(_emailController.text)) {
        return Color(0xFF8456FF);
      } else {
        return Colors.red;
      }
    }
    if (textFieldName == 'Username') {
      if (_usernameController.text.isEmpty) {
        return Color(0xFF8456FF);
      } else if (isUsernameValid(_usernameController.text)) {
        return Color(0xFF8456FF);
      } else {
        return Colors.red;
      }
    } else {
      return Color(0xFF8456FF);
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
              child: SizedBox(
                height: 673,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // "Welcome to" in neon style
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Color(0xFFFF5AF7), Color(0xFF8456FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        'Welcome to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          letterSpacing: 4,
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
                    SizedBox(height: 3),
                    // * "Hertz" in neon style, centered
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Color(0xFFFF5AF7), Color(0xFF8456FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },

                      child: Text(
                        'Hertz',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 43,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          letterSpacing: 6,
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
                    // ! Image.asset('assets/images/logoTPP.png', width: 120, height: 90), //NOT FOR NOW
                    SizedBox(height: 30),
                    Container(
                      width: 350,
                      height: 480,
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
                      child: Stack(
                        children: [
                          Positioned.fill(
                            top: 14,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 0),
                                  TextField(
                                    controller: _fullnameController,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.drive_file_rename_outline_sharp,
                                        color: Colors.white70,
                                      ),
                                      hintText: 'Full Name',
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
                                  SizedBox(height: 25),
                                  TextField(
                                    controller: _usernameController,
                                    focusNode: _usernameFocusNode,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    onTap: () {
                                      showUsernameRequirementsSnackBar(context);
                                    },
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
                                          color: getBorderColor("Username"),
                                          width: 1.3,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getFocusedBorderColor(
                                            "Username",
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 25),
                                  TextField(
                                    controller: _emailController,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
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
                                          color: getBorderColor("Email"),
                                          width: 1.3,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getFocusedBorderColor("Email"),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 25),
                                  TextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,

                                    obscureText: true,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    onTap: () {
                                      showPasswordRequirementsSnackBar(context);
                                    },
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
                                          color: getBorderColor("Password"),
                                          width: 1.3,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getFocusedBorderColor(
                                            "Password",
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (isSignUpValid()) {
                                        signUpProcess();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF671BAF),
                                      // Deep dark purple
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Sign Up',
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
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account?",
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
                                              builder:
                                                  (context) =>
                                                      LogInPage(title: 'Hertz'),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Log In",
                                          style: TextStyle(
                                            color: Color(0xFFD644FF),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
