import 'package:flutter/material.dart';
import 'package:second/User.dart';
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

  static void logIn(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(user: user)),
    );
  }

  static void signUp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(user: user)),
    );
  }
}
