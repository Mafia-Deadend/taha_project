import 'package:flutter/material.dart';

class HideTextScreen extends StatelessWidget {
final String token;
  const HideTextScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hide Text in Image Page',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
