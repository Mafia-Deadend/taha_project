import 'package:flutter/material.dart';

class HideTextScreen extends StatelessWidget {
  const HideTextScreen({super.key});

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
