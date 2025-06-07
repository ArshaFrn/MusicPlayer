import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:second/User.dart';
import 'package:second/TcpClient.dart';
import 'SignUpPage.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
