import 'package:flutter/material.dart';
import 'package:second/Response.dart';
import 'Model/User.dart';
import 'package:second/TcpClient.dart';
import 'main.dart';
import 'package:second/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';

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
          backgroundColor: Colors.red.withOpacity(0.5),
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
            backgroundColor: Colors.deepOrange.withOpacity(0.75),
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
            backgroundColor: Colors.deepOrange.withOpacity(0.75),
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
            backgroundColor: Colors.red.withOpacity(0.65),
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
          backgroundColor: Colors.red.withOpacity(0.65),
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
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final Color defaultBorderColor =
        theme.isDarkMode ? Colors.white24 : Colors.grey.shade300;
    final Color errorColor = Colors.red;

    if (textFieldName == 'Password') {
      if (_passwordController.text.isEmpty) {
        return defaultBorderColor;
      } else if (isPasswordValid(
        _passwordController.text,
        _usernameController.text,
      )) {
        return defaultBorderColor;
      } else {
        return errorColor;
      }
    }
    if (textFieldName == 'Email') {
      if (_emailController.text.isEmpty) {
        return defaultBorderColor;
      } else if (isEmailValid(_emailController.text)) {
        return defaultBorderColor;
      } else {
        return errorColor;
      }
    }
    if (textFieldName == 'Username') {
      if (_usernameController.text.isEmpty) {
        return defaultBorderColor;
      } else if (isUsernameValid(_usernameController.text)) {
        return defaultBorderColor;
      } else {
        return errorColor;
      }
    }
    if (textFieldName == 'Full Name') {
      if (_fullnameController.text.isEmpty) {
        return defaultBorderColor;
      } else {
        return defaultBorderColor;
      }
    } else {
      return defaultBorderColor;
    }
  }

  Color getFocusedBorderColor(String textFieldName) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final Color primaryColor =
        theme.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997);
    final Color errorColor = Colors.red;

    if (textFieldName == 'Password') {
      if (_passwordController.text.isEmpty) {
        return primaryColor;
      } else if (isPasswordValid(
        _passwordController.text,
        _usernameController.text,
      )) {
        return primaryColor;
      } else {
        return errorColor;
      }
    }
    if (textFieldName == 'Email') {
      if (_emailController.text.isEmpty) {
        return primaryColor;
      } else if (isEmailValid(_emailController.text)) {
        return primaryColor;
      } else {
        return errorColor;
      }
    }
    if (textFieldName == 'Username') {
      if (_usernameController.text.isEmpty) {
        return primaryColor;
      } else if (isUsernameValid(_usernameController.text)) {
        return primaryColor;
      } else {
        return errorColor;
      }
    }
    if (textFieldName == 'Full Name') {
      if (_fullnameController.text.isEmpty) {
        return primaryColor;
      } else {
        return primaryColor;
      }
    } else {
      return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: true);
    final bool isDark = theme.isDarkMode;
    final Color primaryColor = isDark ? Color(0xFF8456FF) : Color(0xFFfc6997);
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color labelColor = isDark ? Colors.white70 : Colors.black54;
    final Color fillColor =
        isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.1);
    final Color borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final Color containerColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.95);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    isDark
                        ? 'assets/images/LogInBG.jpg'
                        : 'assets/images/lightBG.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Theme toggle button (circular) in upper right corner
          Positioned(
            top: 50,
            right: 20,
            child: Consumer<ThemeProvider>(
              builder: (context, theme, child) {
                return Container(
                  decoration: BoxDecoration(
                    color:
                        theme.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color:
                          theme.isDarkMode
                              ? Color(0xFF8456FF)
                              : Color(0xFFfc6997),
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => theme.toggleTheme(),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color:
                              theme.isDarkMode
                                  ? Color(0xFF8456FF)
                                  : Color(0xFFfc6997),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
                        return LinearGradient(
                          colors:
                              isDark
                                  ? [Color(0xFF8456FF), Color(0xFFB388FF)]
                                  : [Color(0xFFfc6997), Color(0xFFf8f5f0)],
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
                        return LinearGradient(
                          colors:
                              isDark
                                  ? [Color(0xFF8456FF), Color(0xFFB388FF)]
                                  : [Color(0xFFfc6997), Color(0xFFf8f5f0)],
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
                        color: containerColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.1)),
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
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.drive_file_rename_outline_sharp,
                                        color: labelColor,
                                      ),
                                      hintText: 'Full Name',
                                      hintStyle: TextStyle(color: labelColor),
                                      filled: true,
                                      fillColor: fillColor,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getBorderColor('Full Name'),
                                          width: 1.3,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getFocusedBorderColor(
                                            'Full Name',
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_fullnameController.text.isNotEmpty &&
                                      _fullnameController.text.isEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        left: 12,
                                      ),
                                      child: Text(
                                        'Full Name is required',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
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
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.person,
                                        color: labelColor,
                                      ),
                                      hintText: 'Username',
                                      hintStyle: TextStyle(color: labelColor),
                                      filled: true,
                                      fillColor: fillColor,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getBorderColor('Username'),
                                          width: 1.3,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getFocusedBorderColor(
                                            'Username',
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_usernameController.text.isNotEmpty &&
                                      !isUsernameValid(
                                        _usernameController.text,
                                      ))
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        left: 12,
                                      ),
                                      child: Text(
                                        'Username must be at least 8 characters, no spaces, only alphanumeric and underscores',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 25),
                                  TextField(
                                    controller: _emailController,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: labelColor,
                                      ),
                                      hintText: 'Email Address',
                                      hintStyle: TextStyle(color: labelColor),
                                      filled: true,
                                      fillColor: fillColor,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getBorderColor('Email'),
                                          width: 1.3,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getFocusedBorderColor('Email'),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_emailController.text.isNotEmpty &&
                                      !isEmailValid(_emailController.text))
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        left: 12,
                                      ),
                                      child: Text(
                                        'Please enter a valid email address',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
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
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: labelColor,
                                      ),
                                      hintText: 'Password',
                                      hintStyle: TextStyle(color: labelColor),
                                      filled: true,
                                      fillColor: fillColor,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getBorderColor('Password'),
                                          width: 1.3,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: getFocusedBorderColor(
                                            'Password',
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_passwordController.text.isNotEmpty &&
                                      !isPasswordValid(
                                        _passwordController.text,
                                        _usernameController.text,
                                      ))
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        left: 12,
                                      ),
                                      child: Text(
                                        _passwordErrorText.isNotEmpty
                                            ? _passwordErrorText
                                            : 'Password must meet all requirements',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
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
                                      backgroundColor: primaryColor,
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
                                            blurRadius: 12,
                                            color: Color(0xFFfc6997),
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
                                          color: labelColor,
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
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
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
