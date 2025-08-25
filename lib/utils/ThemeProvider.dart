import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _logoKey = 'app_logo';
  
  ThemeMode _themeMode = ThemeMode.dark;
  String _logoPath = darkLogoPath;
  bool _isDarkMode = true;
  
  static const Color darkPrimaryColor = Color(0xFF8456FF);
  static const Color darkSecondaryColor = Color(0xFF671BAF);
  static const Color darkBackgroundColor = Colors.black;
  static const Color darkSurfaceColor = Color(0xFF1A1A1A);
  
  static const Color lightPrimaryColor = Color(0xFFfc6997);
  static const Color lightSecondaryColor = Color(0xFFf8f5f0);
  static const Color lightBackgroundColor = Color(0xFFf8f5f0);
  static const Color lightSurfaceColor = Colors.white;
  
  static const String darkLogoPath = 'assets/images/darkLogo.jpg';
  static const String lightLogoPath = 'assets/images/lightLogo.jpg';
  
  static const String darkBackgroundPath = 'assets/images/LogInBG.jpg';
  static const String lightBackgroundPath = 'assets/images/lightBG.jpg';

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  String get logoPath => _logoPath;
  bool get isDarkMode => _isDarkMode;
  bool get isLightMode => _themeMode == ThemeMode.light;

  String get backgroundPath => isDarkMode ? darkBackgroundPath : lightBackgroundPath;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? 'dark';
      final logoString = prefs.getString(_logoKey) ?? 'dark';
      
      _themeMode = themeString == 'light' ? ThemeMode.light : ThemeMode.dark;
      _isDarkMode = _themeMode == ThemeMode.dark;
      _logoPath = logoString == 'light' ? lightLogoPath : darkLogoPath;
      
      notifyListeners();
    } catch (e) {
      print('Error loading theme preferences: $e');
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    
    _themeMode = themeMode;
    _isDarkMode = themeMode == ThemeMode.dark;
    
    if (_isDarkMode) {
      _logoPath = darkLogoPath;
    } else {
      _logoPath = lightLogoPath;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeMode == ThemeMode.light ? 'light' : 'dark');
    } catch (e) {
      print('Error saving theme preference: $e');
    }
    
    notifyListeners();
  }

  Future<void> setLogo(String logoType) async {
    final newLogoPath = logoType == 'light' ? lightLogoPath : darkLogoPath;
    if (_logoPath == newLogoPath) return;
    
    _logoPath = newLogoPath;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_logoKey, logoType);
    } catch (e) {
      print('Error saving logo preference: $e');
    }
    
    notifyListeners();
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkSecondaryColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkSurfaceColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightPrimaryColor,
        secondary: lightSecondaryColor,
        surface: lightSurfaceColor,
        background: lightBackgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: lightSurfaceColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black87),
        titleMedium: TextStyle(color: Colors.black87),
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    );
  }

  void toggleTheme() {
    setTheme(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void toggleLogo() {
    setLogo(_logoPath == darkLogoPath ? 'light' : 'dark');
  }
}
