import 'package:flutter/material.dart';

class ExtractImageScreen extends StatelessWidget {
  const ExtractImageScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Extract Image from Image Page',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
