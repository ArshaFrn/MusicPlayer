import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:second/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FingerprintLoginButton extends StatefulWidget {
  @override
  _FingerprintLoginButtonState createState() => _FingerprintLoginButtonState();
}

class _FingerprintLoginButtonState extends State<FingerprintLoginButton> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAvailable = false;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check biometric availability when dependencies change
    _checkBiometricAvailable();
  }

  Future<void> _checkBiometricAvailable() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      final prefs = await SharedPreferences.getInstance();
      final hasSavedCredentials =
          prefs.getString('username') != null &&
          prefs.getString('password') != null;

      setState(() {
        _isAvailable = isAvailable && isDeviceSupported;
        _hasSavedCredentials = hasSavedCredentials;
      });
    } catch (e) {
      print('Error checking biometric availability: $e');
      setState(() {
        _isAvailable = false;
        _hasSavedCredentials = false;
      });
    }
  }

  Future<void> _authenticate(BuildContext context) async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric authentication is not available.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.orange.shade900,
        ),
      );
      return;
    }

    if (!_hasSavedCredentials) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please log in manually first to enable fingerprint login.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.orange.shade900,
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to log in',
        options: AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (isAuthenticated) {
        await prefs.setBool('isLoggedIn', true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authentication successful!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade900,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authentication failed. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Authentication error: ${e.toString()}',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _authenticate(context),
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Icon(Icons.fingerprint, size: 59, color: Colors.white),
    );
  }
}
