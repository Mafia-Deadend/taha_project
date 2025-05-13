import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(167, 7, 9, 9),
      body: Center(
        child: Text(
          "Secure Talks",
          style: TextStyle(
            fontSize: 32,
            color: Color.fromARGB(255, 106, 255, 0),
            fontWeight: FontWeight.bold,
            fontFamily: 'times new roman',
          ),
        ),
      ),
    );
  }
}
