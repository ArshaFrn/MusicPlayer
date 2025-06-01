import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // ! Set status bar icons to light
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hertz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Hertz'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
                height: 635,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 0),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFFF5AF7),
                            Color(0xFF8456FF),
                          ], // Pink to Purple
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
                              color: Color(0xFFFF5AF7), // Neon pink glow
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 48,
                              color: Color(0xFF8456FF), // Neon purple glow
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
                    //Image.asset('assets/images/logoTPP.png', width: 120, height: 90), //NOT FOR NOW
                    SizedBox(height: 55),
                    Container(
                      width: 350,
                      height: 430,
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
                          Positioned(
                            top: 25,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFF8456FF), // Neon purple
                                      Color(0xFFB388FF), // Lighter purple
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  'LOG IN',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: 3,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 15,
                                        color: Color(0xFF8456FF),
                                        // Neon purple glow
                                        offset: Offset(1, 3),
                                      ),
                                      Shadow(
                                        blurRadius: 15,
                                        color: Color(0xFFB388FF),
                                        // Lighter purple glow
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            top: 65,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 35),
                                  TextField(
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
                                  SizedBox(height: 25),
                                  TextField(
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
                                  SizedBox(height: 25),
                                  ElevatedButton(
                                    onPressed: () {},
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
                                              builder:
                                                  (context) => SignUpPage(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Sign Up",
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

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _passwordErrorText = '';
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
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
          bottom: MediaQuery.of(context).size.height * 0.5,
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
                    SizedBox(height: 40),
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
                            top: 18,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 0),
                                  TextField(
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
                                    onChanged: (value) {
                                      setState(() {});
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
                                    onPressed: () {},
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
                                                  (context) => MyHomePage(
                                                    title: 'Hertz',
                                                  ),
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
