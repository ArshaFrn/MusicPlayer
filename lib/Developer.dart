import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Model/User.dart';
import 'package:second/HomePage.dart';

class Developer {
  static const String username = "DeveloperMode";
  static const String email = "Developer@gmail.com";
  static const String fullname = "Developer Mode";
  static const String password = "Developer0!!";
  static final DateTime registrationDate = DateTime.now();

  static User user = User(
    username: username,
    email: email,
    fullname: fullname,
    password: password,
    registrationDate: registrationDate,
  );

  static Future<void> logIn(BuildContext context) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('fullname', fullname);
    await prefs.setString('password', password);
    await prefs.setString('registrationDate', registrationDate.toIso8601String());
    await prefs.setString('profileImageUrl', '');

    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  static Future<void> signUp(BuildContext context) async {
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('fullname', fullname);
    await prefs.setString('password', password);
    await prefs.setString('registrationDate', registrationDate.toIso8601String());
    await prefs.setString('profileImageUrl', '');

    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
}