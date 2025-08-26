import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:second/Developer.dart';
import 'package:second/Response.dart';
import 'Model/User.dart';
import 'package:second/TcpClient.dart';
import 'SignUpPage.dart';
import 'HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ForgotPasswordPage.dart';
import 'package:second/AdminLoginPage.dart';
import 'package:second/widgets/FingerprintLoginButton.dart';
import 'package:second/utils/ThemeProvider.dart';
import 'package:provider/provider.dart';
import 'utils/SnackBarUtils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ! Set status bar icons to light
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
  );
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Hertz',
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home:
                isLoggedIn ? const HomePage() : const LogInPage(title: 'Hertz'),
          );
        },
      ),
    );
  }
}

class LogInPage extends StatefulWidget {
  const LogInPage({super.key, required this.title});

  final String title;

  @override
  State<LogInPage> createState() => _LogInPage();
}

class _LogInPage extends State<LogInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
      SnackBarUtils.showErrorSnackBar(context, errors.join("\n"));
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

      final tcpClient = TcpClient(serverAddress: '192.168.43.173', serverPort: 12345);

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
        SnackBarUtils.showSuccessSnackBar(context, "Login successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (response['status'] == "incorrectPassword") {
        print('Incorrect password!');
        SnackBarUtils.showErrorSnackBar(
          context,
          "Incorrect password or username!",
        );
      } else if (response['status'] == "userNotFound") {
        print('User not found!');
        SnackBarUtils.showErrorSnackBar(
          context,
          "Incorrect password or username!",
        );
      } else {
        print("Login failed: ${response['message'] ?? 'Unknown error'}");
        SnackBarUtils.showErrorSnackBar(
          context,
          response['message'] ?? "Login failed!",
        );
      }
    } catch (e) {
      print("An error occurred during login: $e");
      SnackBarUtils.showErrorSnackBar(context, "An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(themeProvider.backgroundPath, fit: BoxFit.cover),
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 12, right: 16),
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
                              theme.isDarkMode
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
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
            ),
          ),
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: true,
              child: Center(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors:
                          themeProvider.isDarkMode
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
                      fontSize: 60,
                      fontWeight: FontWeight.w400,
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
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 110),
                  Container(
                    width: 350,
                    height: 450,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
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
                            child: Consumer<ThemeProvider>(
                              builder: (context, theme, child) {
                                return ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors:
                                          theme.isDarkMode
                                              ? [
                                                Color(0xFF8456FF),
                                                Color(0xFFB388FF),
                                              ]
                                              : [
                                                Color(0xFFfc6997),
                                                Color(0xFFf8f5f0),
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
                                          color:
                                              theme.isDarkMode
                                                  ? Color(0xFF8456FF)
                                                  : Color(0xFFfc6997),
                                          offset: Offset(1, 3),
                                        ),
                                        Shadow(
                                          blurRadius: 15,
                                          color:
                                              theme.isDarkMode
                                                  ? Color(0xFFB388FF)
                                                  : Color(0xFFfc6997),
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                                SizedBox(height: 25),
                                TextField(
                                  controller: _usernameController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                    ),
                                    hintText: 'Username',
                                    hintStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.15),
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
                                    hintStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.15),
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
                                ElevatedButton(
                                  onPressed: () {
                                    if (isLogInValid(context)) {
                                      logInProcess(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeProvider.isDarkMode
                                            ? Color(0xFF8456FF)
                                            : Color(0xFFfc6997),
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
                                SizedBox(height: 8),
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
                                          color:
                                              themeProvider.isDarkMode
                                                  ? Color(0xFF8456FF)
                                                  : Color(0xFFfc6997),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color:
                                              themeProvider.isDarkMode
                                                  ? Color(0xFF8456FF)
                                                  : Color(0xFFfc6997),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => AdminLoginPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Admin?",
                                        style: TextStyle(
                                          color:
                                              themeProvider.isDarkMode
                                                  ? Color(0xFF8456FF)
                                                  : Color(0xFFfc6997),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          decoration: TextDecoration.underline,
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
                  SizedBox(height: 15),
                  FingerprintLoginButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
