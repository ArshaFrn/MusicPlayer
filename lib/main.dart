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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hertz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark, // Dark theme
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Hertz'), // <-- Add this line
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
                const SizedBox(height: 88),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [Color(0xFFFF5AF7), Color(0xFF8456FF)], // Pink to Purple
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: const Text(
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
                    )
                  ),
                ),
                  Image.asset('assets/images/logoTPP.png', width: 120, height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
