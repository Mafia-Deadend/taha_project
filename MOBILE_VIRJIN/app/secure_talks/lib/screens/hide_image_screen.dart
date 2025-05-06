import 'package:flutter/material.dart';

class HideImageScreen extends StatelessWidget {
  const HideImageScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hide Image in Image Page',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
