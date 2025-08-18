import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ThemeProvider.dart';

class SnackBarUtils {
  static void showSuccessSnackBar(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 1.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        backgroundColor: isDark ? Color(0xFF8456FF) : Color(0xFFfc6997),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 1.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        backgroundColor: isDark ? Colors.red.withOpacity(0.65) : Colors.red.withOpacity(0.8),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 1.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        backgroundColor: isDark ? Color(0xFF8456FF) : Color(0xFFfc6997),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                blurRadius: 1.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        backgroundColor: isDark ? Colors.orange.withOpacity(0.65) : Colors.orange.withOpacity(0.8),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 45),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
    );
  }
}
