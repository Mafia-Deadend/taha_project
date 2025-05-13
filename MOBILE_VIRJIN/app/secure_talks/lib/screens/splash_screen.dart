import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0; // Initial opacity for fade-in

  @override
  void initState() {
    super.initState();

    // Start the fade-in animation
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Navigate to the next screen after the fade-out animation
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _opacity = 0.0; // Start fade-out
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(167, 7, 9, 9),
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500), // Duration for fade-in and fade-out
          opacity: _opacity,
          child: const Text(
            "Secure Talks \n 🔐",textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              
              color: Color.fromARGB(255, 106, 255, 0),
              fontWeight: FontWeight.bold,
              fontFamily: 'times new roman',
            ),
          ),
        ),
      ),
    );
  }
}
