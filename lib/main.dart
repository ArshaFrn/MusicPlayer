import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // Set status bar icons to light
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light, // white icons
    ),
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
          // Background image
          Positioned.fill(
            child: Image.asset('assets/images/LogInBG.jpg', fit: BoxFit.cover),
          ),
          Center(
            child: Column(
              children: [
                SizedBox(height: 88),
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
                SizedBox(height: 90),
                //Login form
                Container(
                  width: 350,
                  height: 400,
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
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    blurRadius: 16,
                                    color: Color(0xFF8456FF),
                                    // Neon purple glow
                                    offset: Offset(0, 0),
                                  ),
                                  Shadow(
                                    blurRadius: 16,
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
                        top: 80,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 15),
                              TextField(
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
                              ElevatedButton(
                                onPressed: () {},
                                child: Text('Log In',style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF5AF7),
                                  // Neon pink
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
